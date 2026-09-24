import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

typedef GeminiLiveJson = Map<String, dynamic>;

class GeminiLiveVoiceService {
  GeminiLiveVoiceService({
    AudioRecorder? recorder,
    this.onConnected,
    this.onDisconnected,
    this.onReady,
    this.onUserSpeechStarted,
    this.onUserSpeechStopped,
    this.onUserTranscript,
    this.onAssistantStarted,
    this.onAssistantText,
    this.onAssistantCompleted,
    this.onError,
    this.onLog,
  }) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  WebSocket? _socket;
  StreamSubscription<Uint8List>? _micSub;
  StreamSubscription? _socketSub;

  bool _connected = false;
  bool _ready = false;
  bool _userTurnActive = false;
  bool _assistantSpeaking = false;
  bool _disposed = false;
  int _sampleRate = 16000;
  int _sentMicChunks = 0;
  int _blockedMicChunks = 0;
  String _assistantBuffer = '';
  String _lastAssistantText = '';

  DateTime? _speechStartedAt;
  DateTime? _speechStoppedAt;

  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  final VoidCallback? onReady;
  final VoidCallback? onUserSpeechStarted;
  final VoidCallback? onUserSpeechStopped;
  final ValueChanged<String>? onUserTranscript;
  final VoidCallback? onAssistantStarted;
  final ValueChanged<String>? onAssistantText;
  final ValueChanged<String>? onAssistantCompleted;
  final ValueChanged<Object>? onError;
  final ValueChanged<String>? onLog;

  bool get connected => _connected;
  bool get ready => _ready;
  bool get userTurnActive => _userTurnActive;
  bool get assistantSpeaking => _assistantSpeaking;

  Future<void> start({
    required String websocketUrl,
    required String token,
    required String model,
    required String systemInstruction,
    String responseModality = 'AUDIO',
    int sampleRate = 16000,
  }) async {
    if (_connected) return;

    _disposed = false;
    _sampleRate = sampleRate;
    _sentMicChunks = 0;
    _blockedMicChunks = 0;
    _assistantBuffer = '';
    _lastAssistantText = '';

    final uri = _uriWithAuth(websocketUrl: websocketUrl, token: token);

    final socket = await WebSocket.connect(uri.toString());
    _socket = socket;
    _connected = true;
    onConnected?.call();
    _log('gemini live websocket connected url=$uri');

    _socketSub = socket.listen(
      _handleServerMessage,
      onDone: () {
        _connected = false;
        _ready = false;
        _userTurnActive = false;
        _assistantSpeaking = false;
        _log('gemini live websocket disconnected');
        onDisconnected?.call();
      },
      onError: (Object error) {
        _connected = false;
        _ready = false;
        _log('gemini live websocket error=$error');
        onError?.call(error);
      },
    );

    _sendSetup(
      model: model,
      systemInstruction: systemInstruction,
      responseModality: responseModality,
    );
    await _startMicStream();
  }

  Future<void> stop() async {
    _disposed = true;
    _connected = false;
    _ready = false;
    _userTurnActive = false;
    _assistantSpeaking = false;

    await _micSub?.cancel();
    _micSub = null;

    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }

    await _socketSub?.cancel();
    _socketSub = null;

    await _socket?.close();
    _socket = null;

    _log('gemini live stopped sent=$_sentMicChunks blocked=$_blockedMicChunks');
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
  }

  void beginUserTurn() {
    if (!_connected || !_ready || _assistantSpeaking) return;
    if (_userTurnActive) return;

    _assistantBuffer = '';
    _userTurnActive = true;
    _speechStartedAt = DateTime.now();
    _speechStoppedAt = null;
    _send({
      'realtimeInput': {'activityStart': {}},
    });
    _log('user activity_start');
    onUserSpeechStarted?.call();
  }

  void endUserTurn() {
    if (!_connected || !_userTurnActive) return;

    _userTurnActive = false;
    _speechStoppedAt = DateTime.now();
    _send({
      'realtimeInput': {'activityEnd': {}},
    });
    _log('user activity_end');

    final startedAt = _speechStartedAt;
    if (startedAt != null) {
      _log(
        'latency speechStartedToStopped=${_speechStoppedAt!.difference(startedAt).inMilliseconds}ms',
      );
    }

    onUserSpeechStopped?.call();
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

    _log('gemini live mic stream started sampleRate=$_sampleRate');

    _micSub = stream.listen(
      (chunk) {
        if (!_connected || chunk.isEmpty) return;

        if (!_userTurnActive || _assistantSpeaking) {
          _blockedMicChunks++;
          if (_blockedMicChunks == 1 || _blockedMicChunks % 50 == 0) {
            _log(
              'gemini live mic chunk blocked count=$_blockedMicChunks assistantSpeaking=$_assistantSpeaking userTurnActive=$_userTurnActive',
            );
          }
          return;
        }

        _sentMicChunks++;
        if (_sentMicChunks == 1 || _sentMicChunks % 50 == 0) {
          _log('gemini live mic chunk sent count=$_sentMicChunks');
        }

        _send({
          'realtimeInput': {
            'audio': {
              'data': base64Encode(chunk),
              'mimeType': 'audio/pcm;rate=$_sampleRate',
            },
          },
        });
      },
      onError: (Object error) {
        _log('gemini live mic stream error=$error');
        onError?.call(error);
      },
    );
  }

  void _handleServerMessage(dynamic raw) {
    if (_disposed) return;

    final event = _decodeEvent(raw);
    if (event == null) return;

    if (event.containsKey('setupComplete')) {
      _ready = true;
      _log('gemini live setupComplete');
      onReady?.call();
      return;
    }

    if (event.containsKey('serverContent')) {
      _handleGeminiEvent(_normalizeDirectGeminiEvent(event));
      return;
    }

    if (event.containsKey('goAway')) {
      _log('gemini live goAway ${jsonEncode(event['goAway'])}');
      return;
    }

    if (event.containsKey('toolCall') ||
        event.containsKey('toolCallCancellation')) {
      _log('gemini live ignored tool event=${jsonEncode(event)}');
      return;
    }

    if (event.containsKey('error')) {
      _log('gemini live server error=${jsonEncode(event)}');
      onError?.call(event['error']);
      return;
    }

    _log('gemini live ignored event=${jsonEncode(event)}');
  }

  void _handleGeminiEvent(GeminiLiveJson event) {
    final inputTranscript = event['input_transcription_final']
        ?.toString()
        .trim();
    if (inputTranscript != null && inputTranscript.isNotEmpty) {
      _log('USER transcript="$inputTranscript"');

      final stoppedAt = _speechStoppedAt;
      if (stoppedAt != null) {
        _log(
          'latency speechStoppedToTranscript=${DateTime.now().difference(stoppedAt).inMilliseconds}ms',
        );
      }

      onUserTranscript?.call(inputTranscript);
    }

    final interimInput = event['input_transcription_interim']
        ?.toString()
        .trim();
    if (interimInput != null && interimInput.isNotEmpty) {
      _log('USER transcript interim="$interimInput"');
    }

    final assistantText = _assistantTextFrom(event);
    if (assistantText.isNotEmpty && assistantText != _lastAssistantText) {
      _lastAssistantText = assistantText;
      _assistantBuffer = assistantText;

      if (!_assistantSpeaking) {
        _assistantSpeaking = true;
        _log('assistant response started');
        onAssistantStarted?.call();
      }

      _log('assistant text="$assistantText"');
      onAssistantText?.call(assistantText);
    }

    final turnComplete = event['turn_complete'] == true;
    if (turnComplete) {
      final finalText = _assistantBuffer.trim();
      _assistantSpeaking = false;
      _assistantBuffer = '';
      _lastAssistantText = '';
      _log('assistant turn_complete final="$finalText"');

      if (finalText.isNotEmpty) {
        onAssistantCompleted?.call(finalText);
      }
    }
  }

  String _assistantTextFrom(GeminiLiveJson event) {
    final outputTranscript = event['output_transcription_final']?.toString();
    if (outputTranscript != null && outputTranscript.trim().isNotEmpty) {
      return outputTranscript.trim();
    }

    final outputInterim = event['output_transcription_interim']?.toString();
    if (outputInterim != null && outputInterim.trim().isNotEmpty) {
      return outputInterim.trim();
    }

    final text = event['text']?.toString();
    if (text != null && text.trim().isNotEmpty) {
      return text.trim();
    }

    return '';
  }

  GeminiLiveJson? _decodeEvent(dynamic raw) {
    try {
      if (raw is String) {
        return jsonDecode(raw) as GeminiLiveJson;
      }

      if (raw is List<int>) {
        return jsonDecode(utf8.decode(raw)) as GeminiLiveJson;
      }
    } catch (error) {
      _log('gemini live failed to decode event error=$error');
    }

    return null;
  }

  Uri _uriWithAuth({required String websocketUrl, required String token}) {
    final uri = Uri.parse(websocketUrl);
    final queryParameters = Map<String, String>.from(uri.queryParameters)
      ..['access_token'] = token;

    return uri.replace(queryParameters: queryParameters);
  }

  void _sendSetup({
    required String model,
    required String systemInstruction,
    required String responseModality,
  }) {
    final modelName = model.startsWith('models/') ? model : 'models/$model';
    final normalizedModality = responseModality.trim().toUpperCase() == 'TEXT'
        ? 'AUDIO'
        : responseModality.trim().toUpperCase();

    _send({
      'setup': {
        'model': modelName,
        'generationConfig': {
          'responseModalities': [normalizedModality],
        },
        'realtimeInputConfig': {
          'automaticActivityDetection': {'disabled': true},
        },
        'inputAudioTranscription': {},
        'outputAudioTranscription': {},
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
      },
    });
    _log(
      'gemini live setup sent model=$modelName modality=$normalizedModality',
    );
  }

  GeminiLiveJson _normalizeDirectGeminiEvent(GeminiLiveJson event) {
    final content = event['serverContent'] as Map<String, dynamic>? ?? {};
    final modelTurn = content['modelTurn'] as Map<String, dynamic>?;
    final parts = modelTurn?['parts'] as List<dynamic>? ?? [];
    final textParts = parts
        .whereType<Map<String, dynamic>>()
        .map((part) => part['text'])
        .whereType<String>()
        .where((text) => text.isNotEmpty)
        .join();

    return {
      'text': textParts,
      'input_transcription_final': _transcriptionText(
        content['inputTranscription'],
      ),
      'input_transcription_interim': _transcriptionText(
        content['interimInputTranscription'],
      ),
      'output_transcription_final': _transcriptionText(
        content['outputTranscription'],
      ),
      'output_transcription_interim': _transcriptionText(
        content['interimOutputTranscription'],
      ),
      'turn_complete': content['turnComplete'] == true,
      'generation_complete': content['generationComplete'] == true,
      'interrupted': content['interrupted'] == true,
    };
  }

  String? _transcriptionText(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['text']?.toString();
    }

    return null;
  }

  void _send(GeminiLiveJson event) {
    final socket = _socket;
    if (socket == null || !_connected) return;

    socket.add(jsonEncode(event));
  }

  void _log(String message) {
    debugPrint('[GeminiLiveVoiceService] $message');
    onLog?.call(message);
  }
}
