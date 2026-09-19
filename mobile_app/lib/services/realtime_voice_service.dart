import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

typedef RealtimeJson = Map<String, dynamic>;

class RealtimeVoiceService {
  RealtimeVoiceService({
    AudioRecorder? recorder,
    this.onUserSpeechStarted,
    this.onUserSpeechStopped,
    this.onUserTranscript,
    this.onAssistantAudioStarted,
    this.onAssistantAudioChunk,
    this.onAssistantAudioStreamDone,
    this.onAssistantAudioStopped,
    this.onAssistantTranscript,
    this.onConnected,
    this.onDisconnected,
    this.onError,
    this.onLog,
  }) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  WebSocket? _socket;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription? _socketSub;

  bool _connected = false;
  bool _assistantSpeaking = false;
  bool _responseInProgress = false;
  bool _disposed = false;

  DateTime? _micMutedUntil;
  DateTime? _lastSpeechStartedAt;
  DateTime? _lastSpeechStoppedAt;
  DateTime? _lastUserTranscriptAt;

  int _sentMicChunks = 0;
  int _blockedMicChunks = 0;
  int _assistantAudioChunks = 0;
  String _userBuffer = '';
  int _sampleRate = 24000;

  final VoidCallback? onUserSpeechStarted;
  final VoidCallback? onUserSpeechStopped;
  final ValueChanged<String>? onUserTranscript;
  final VoidCallback? onAssistantAudioStarted;
  final ValueChanged<Uint8List>? onAssistantAudioChunk;
  final VoidCallback? onAssistantAudioStreamDone;
  final VoidCallback? onAssistantAudioStopped;
  final ValueChanged<String>? onAssistantTranscript;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final ValueChanged<Object>? onError;
  final ValueChanged<String>? onLog;

  bool get connected => _connected;
  bool get assistantSpeaking => _assistantSpeaking;
  bool get responseInProgress => _responseInProgress;
  int get sentMicChunks => _sentMicChunks;
  int get blockedMicChunks => _blockedMicChunks;

  Future<void> start({
    required String websocketUrl,
    Map<String, dynamic>? sessionConfig,
    Map<String, dynamic>? headers,
    int sampleRate = 24000,
    bool createInitialResponse = true,
    bool sendSessionUpdate = false,
  }) async {
    if (_connected) return;

    _disposed = false;
    _sampleRate = sampleRate;

    final socket = await WebSocket.connect(websocketUrl, headers: headers);
    _socket = socket;
    _connected = true;
    onConnected?.call();
    _log('websocket connected');

    _socketSub = socket.listen(
      _handleServerMessage,
      onDone: () {
        _connected = false;
        _log('websocket disconnected');
        onDisconnected?.call();
      },
      onError: (Object error) {
        _connected = false;
        _log('websocket error=$error');
        onError?.call(error);
      },
    );

    if (sendSessionUpdate) {
      _sendSessionUpdate(sessionConfig);
    }
    await _startMicStream();

    if (createInitialResponse) {
      createAssistantResponse();
    }
  }

  Future<void> stop() async {
    _disposed = true;
    _connected = false;
    _assistantSpeaking = false;
    _responseInProgress = false;
    _micMutedUntil = null;

    await _micSub?.cancel();
    _micSub = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    await _socketSub?.cancel();
    _socketSub = null;

    await _socket?.close();
    _socket = null;

    _log(
      'service stopped sent=$_sentMicChunks blocked=$_blockedMicChunks assistantChunks=$_assistantAudioChunks',
    );
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }

  void notifyNativePlaybackIdle() {
    if (!_assistantSpeaking && !_responseInProgress) return;

    _releaseAssistantPlayback('native playback idle');
  }

  void createAssistantResponse() {
    if (!_connected) return;
    if (_responseInProgress || _assistantSpeaking) {
      _log(
        'response.create skipped responseInProgress=$_responseInProgress assistantSpeaking=$_assistantSpeaking',
      );
      return;
    }

    _responseInProgress = true;
    _assistantSpeaking = true;
    _send({'type': 'input_audio_buffer.clear'});
    _send({'type': 'response.create'});
    _log('response.create sent after USER transcript');
  }

  Future<void> _startMicStream() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('Microphone permission is required.');
    }

    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      ),
    );

    _log('mic stream started sampleRate=$_sampleRate');

    _micSub = stream.listen(
      (chunk) {
        if (!_connected || chunk.isEmpty) return;

        if (_isMicUploadMuted()) {
          _blockedMicChunks++;
          if (_blockedMicChunks == 1 || _blockedMicChunks % 50 == 0) {
            _log(
              'mic chunk blocked while assistantSpeaking count=$_blockedMicChunks responseInProgress=$_responseInProgress',
            );
          }
          return;
        }

        _sentMicChunks++;
        if (_sentMicChunks == 1 || _sentMicChunks % 50 == 0) {
          _log('mic chunk sent count=$_sentMicChunks');
        }

        _send({
          'type': 'input_audio_buffer.append',
          'audio': base64Encode(chunk),
        });
      },
      onError: (Object error) {
        _log('mic stream error=$error');
        onError?.call(error);
      },
    );
  }

  bool _isMicUploadMuted() {
    if (_assistantSpeaking || _responseInProgress) return true;

    final mutedUntil = _micMutedUntil;
    if (mutedUntil == null) return false;

    if (DateTime.now().isBefore(mutedUntil)) return true;

    _micMutedUntil = null;
    return false;
  }

  void _handleServerMessage(dynamic raw) {
    if (_disposed) return;

    final event = _decodeEvent(raw);
    if (event == null) return;

    final type = event['type']?.toString();
    if (type == null) return;

    switch (type) {
      case 'input_audio_buffer.speech_started':
        _handleSpeechStarted();
        break;
      case 'input_audio_buffer.speech_stopped':
        _handleSpeechStopped();
        break;
      case 'conversation.item.input_audio_transcription.delta':
        _appendUserTranscriptDelta(event);
        break;
      case 'conversation.item.input_audio_transcription.completed':
        _handleUserTranscriptCompleted(event);
        break;
      case 'response.created':
        _responseInProgress = true;
        _log('response.created');
        break;
      case 'response.audio.delta':
      case 'response.output_audio.delta':
        _handleAssistantAudioDelta(event);
        break;
      case 'response.audio.done':
      case 'response.output_audio.done':
        _log('assistant audio stream done chunks=$_assistantAudioChunks');
        onAssistantAudioStreamDone?.call();
        break;
      case 'response.output_audio_transcript.delta':
        _appendAssistantTranscriptDelta(event);
        break;
      case 'response.output_audio_transcript.done':
        _handleAssistantTranscriptDone(event);
        break;
      case 'response.done':
        _handleResponseDone();
        break;
      case 'error':
        _log('server error=${jsonEncode(event)}');
        onError?.call(event);
        break;
      default:
        break;
    }
  }

  RealtimeJson? _decodeEvent(dynamic raw) {
    try {
      if (raw is String) {
        return jsonDecode(raw) as RealtimeJson;
      }

      if (raw is List<int>) {
        return jsonDecode(utf8.decode(raw)) as RealtimeJson;
      }
    } catch (error) {
      _log('failed to decode realtime event error=$error');
    }

    return null;
  }

  void _handleSpeechStarted() {
    if (_assistantSpeaking || _responseInProgress) {
      _log('ignored speech_started during assistant playback');
      _send({'type': 'input_audio_buffer.clear'});
      return;
    }

    _lastSpeechStartedAt = DateTime.now();
    _log('user speech_started assistantSpeaking=$_assistantSpeaking');
    onUserSpeechStarted?.call();
  }

  void _handleSpeechStopped() {
    if (_assistantSpeaking || _responseInProgress) {
      _log('ignored speech_stopped during assistant playback');
      return;
    }

    _lastSpeechStoppedAt = DateTime.now();
    _log('user speech_stopped assistantSpeaking=$_assistantSpeaking');
    final startedAt = _lastSpeechStartedAt;
    if (startedAt != null) {
      final speechDuration = _lastSpeechStoppedAt!
          .difference(startedAt)
          .inMilliseconds;
      _log('latency speechStartedToStopped=${speechDuration}ms');
    }
    onUserSpeechStopped?.call();
  }

  void _appendUserTranscriptDelta(RealtimeJson event) {
    final delta = event['delta']?.toString();
    if (delta == null || delta.isEmpty) return;

    if (_assistantSpeaking || _responseInProgress) return;
    _userBuffer += delta;
  }

  void _handleUserTranscriptCompleted(RealtimeJson event) {
    final text = (event['transcript'] as String? ?? _userBuffer).trim();
    _userBuffer = '';

    if (text.isEmpty) return;

    if (_assistantSpeaking || _responseInProgress) {
      _log('ignored USER transcript while assistant/response active');
      return;
    }

    final rejectionReason = _userTranscriptRejectionReason(text, event);
    if (rejectionReason != null) {
      _log('ignored USER transcript reason=$rejectionReason');
      return;
    }

    _lastUserTranscriptAt = DateTime.now();
    _log('USER transcript="$text"');

    final stoppedAt = _lastSpeechStoppedAt;
    if (stoppedAt != null) {
      final latency = _lastUserTranscriptAt!
          .difference(stoppedAt)
          .inMilliseconds;
      _log('latency speechStoppedToTranscript=${latency}ms');
    }

    onUserTranscript?.call(text);
    createAssistantResponse();
  }

  String? _userTranscriptRejectionReason(String text, RealtimeJson event) {
    if (text.length < 2) return 'too_short';

    final lastTranscriptAt = _lastUserTranscriptAt;
    if (lastTranscriptAt != null &&
        DateTime.now().difference(lastTranscriptAt).inMilliseconds < 450) {
      return 'duplicate_too_close';
    }

    return null;
  }

  void _handleAssistantAudioDelta(RealtimeJson event) {
    final encoded = event['delta']?.toString();
    if (encoded == null || encoded.isEmpty) return;

    final chunk = base64Decode(encoded);

    if (_assistantAudioChunks == 0) {
      _assistantSpeaking = true;
      _responseInProgress = true;
      onAssistantAudioStarted?.call();
      _log('assistant audio started');
    }

    _assistantAudioChunks++;
    onAssistantAudioChunk?.call(chunk);
  }

  void _appendAssistantTranscriptDelta(RealtimeJson event) {
    final delta = event['delta']?.toString();
    if (delta == null || delta.isEmpty) return;
    _log('ASSISTANT transcript delta="$delta"');
  }

  void _handleAssistantTranscriptDone(RealtimeJson event) {
    final transcript = event['transcript']?.toString().trim();
    if (transcript == null || transcript.isEmpty) return;
    _log('ASSISTANT transcript="$transcript"');
    onAssistantTranscript?.call(transcript);
  }

  void _handleResponseDone() {
    _log(
      'response.done assistantSpeaking=$_assistantSpeaking chunks=$_assistantAudioChunks',
    );

    if (!_assistantSpeaking || _assistantAudioChunks == 0) {
      _releaseAssistantPlayback('response.done without audio playback');
    }
  }

  void _releaseAssistantPlayback(String reason) {
    _assistantSpeaking = false;
    _responseInProgress = false;
    _assistantAudioChunks = 0;
    _micMutedUntil = DateTime.now().add(const Duration(milliseconds: 650));

    _send({'type': 'input_audio_buffer.clear'});
    _log('assistant playback released reason="$reason"');
    onAssistantAudioStopped?.call();
  }

  void _sendSessionUpdate(Map<String, dynamic>? overrideConfig) {
    final session = <String, dynamic>{
      'turn_detection': {
        'type': 'semantic_vad',
        'eagerness': 'high',
        'create_response': false,
        'interrupt_response': false,
      },
      'input_audio_format': {'type': 'audio/pcm', 'rate': _sampleRate},
      'input_audio_transcription': {'model': 'whisper-1'},
      ...?overrideConfig,
    };

    _send({'type': 'session.update', 'session': session});
  }

  void _send(RealtimeJson event) {
    final socket = _socket;
    if (socket == null || !_connected) return;

    socket.add(jsonEncode(event));
  }

  void _log(String message) {
    debugPrint('[RealtimeVoiceService] $message');
    onLog?.call(message);
  }
}
