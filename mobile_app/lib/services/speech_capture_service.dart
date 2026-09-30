import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechCaptureService {
  SpeechCaptureService({
    stt.SpeechToText? speech,
    this.onListeningChanged,
    this.onTranscript,
    this.onCompleted,
    this.onError,
    this.onLog,
  }) : _speech = speech ?? _sharedSpeech;

  static final stt.SpeechToText _sharedSpeech = stt.SpeechToText();

  final stt.SpeechToText _speech;
  final ValueChanged<bool>? onListeningChanged;
  final ValueChanged<String>? onTranscript;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onError;
  final ValueChanged<String>? onLog;

  Timer? _watchdog;
  Timer? _completionDelay;
  bool _available = false;
  bool _listening = false;
  bool _recovering = false;
  bool _completionSent = false;
  bool _sawDoneStatus = false;
  String _bestTranscript = '';
  String _lastPartialTranscript = '';
  DateTime? _speechStartedAt;
  DateTime? _speechStoppedAt;

  bool get available => _available;
  bool get listening => _listening;
  String get transcript => _bestTranscript;

  Future<String?> systemLocaleId() async {
    final locale = await _speech.systemLocale();
    return locale?.localeId;
  }

  Future<bool> initialize() async {
    _speech.errorListener = _handleError;
    _speech.statusListener = _handleStatus;

    if (_speech.isAvailable) {
      _available = true;
      return true;
    }

    _available = await _speech.initialize(
      onError: _handleError,
      onStatus: _handleStatus,
    );

    _log('speech initialized available=$_available');
    return _available;
  }

  Future<void> start({
    required String localeId,
    Duration listenFor = const Duration(seconds: 45),
    Duration pauseFor = const Duration(seconds: 4),
    stt.ListenMode listenMode = stt.ListenMode.confirmation,
  }) async {
    if (_listening) return;

    final ready = _available || await initialize();
    if (!ready) {
      onError?.call('Microphone not available. Check permissions.');
      return;
    }

    _watchdog?.cancel();
    _completionDelay?.cancel();
    _completionSent = false;
    _sawDoneStatus = false;
    _bestTranscript = '';
    _lastPartialTranscript = '';
    _speechStartedAt = null;
    _speechStoppedAt = null;

    if (_speech.isListening) {
      await _speech.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }

    _listening = true;
    _speechStartedAt = DateTime.now();
    onListeningChanged?.call(true);
    _log('speech capture started locale=$localeId');

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          listenMode: listenMode,
          onDevice: false,
          cancelOnError: false,
          partialResults: true,
          listenFor: listenFor,
          pauseFor: pauseFor,
          localeId: localeId,
        ),
        onResult: (result) {
          final words = result.recognizedWords.trim();
          if (words.isEmpty) return;

          _watchdog?.cancel();
          _lastPartialTranscript = words;
          if (words.length >= _bestTranscript.length) {
            _bestTranscript = words;
          }

          _log('speech partial="$_bestTranscript" final=${result.finalResult}');
          onTranscript?.call(_bestTranscript);

          if (result.finalResult) {
            _speechStoppedAt ??= DateTime.now();
            _finishAfterGuard();
          }
        },
      );

      _watchdog = Timer(const Duration(seconds: 7), () {
        if (!_listening || _bestTranscript.isNotEmpty) return;
        _log('speech watchdog timeout without transcript');
        stop(forceComplete: false);
        onError?.call(
          "The microphone is not responding. Try again, or test on a real device.",
        );
      });
    } catch (error) {
      _listening = false;
      onListeningChanged?.call(false);
      onError?.call('Microphone error: $error');
    }
  }

  Future<void> stop({bool forceComplete = true}) async {
    _watchdog?.cancel();
    _completionDelay?.cancel();

    if (_speech.isListening) {
      await _speech.stop();
    }

    _listening = false;
    _speechStoppedAt = DateTime.now();
    onListeningChanged?.call(false);

    if (forceComplete) {
      _completeIfPossible();
    }
  }

  Future<void> cancel() async {
    _watchdog?.cancel();
    _completionDelay?.cancel();
    _listening = false;
    await _speech.cancel();
    onListeningChanged?.call(false);
  }

  void dispose() {
    _watchdog?.cancel();
    _completionDelay?.cancel();
    _speech.cancel();
  }

  void _handleStatus(String status) {
    _log('speech status=$status listening=$_listening');

    if ((status == 'done' || status == 'notListening') && _listening) {
      _sawDoneStatus = true;
      _listening = false;
      _speechStoppedAt = DateTime.now();
      onListeningChanged?.call(false);
      _finishAfterGuard();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    _log(
      'speech error=${error.errorMsg} permanent=${error.permanent} best="$_bestTranscript"',
    );

    _watchdog?.cancel();
    _listening = false;
    onListeningChanged?.call(false);

    final retryable =
        error.errorMsg == 'error_speech_recognizer_connection_interrupted' ||
        error.errorMsg == 'error_client' ||
        error.errorMsg.startsWith('error_unknown');

    if (_bestTranscript.isNotEmpty) {
      _completeIfPossible();
      return;
    }

    if (_sawDoneStatus && error.errorMsg.startsWith('error_unknown')) {
      onError?.call(
        'No speech was captured. Try again, speak after the listening indicator appears, or test on a real device.',
      );
      return;
    }

    if (retryable) {
      _recover();
    }

    onError?.call(
      retryable
          ? "Speech recognition was interrupted. Try again."
          : 'Speech error: ${error.errorMsg}',
    );
  }

  void _finishAfterGuard() {
    _completionDelay?.cancel();
    _completionDelay = Timer(const Duration(milliseconds: 450), () {
      _completeIfPossible();
    });
  }

  void _completeIfPossible() {
    if (_completionSent) return;

    final transcript =
        (_bestTranscript.isNotEmpty ? _bestTranscript : _lastPartialTranscript)
            .trim();
    if (transcript.isEmpty) return;

    _completionSent = true;
    _listening = false;
    onListeningChanged?.call(false);

    final stoppedAt = _speechStoppedAt;
    final startedAt = _speechStartedAt;
    if (startedAt != null && stoppedAt != null) {
      _log(
        'speech duration=${stoppedAt.difference(startedAt).inMilliseconds}ms',
      );
    }

    if (stoppedAt != null) {
      _log(
        'speech completed latency=${DateTime.now().difference(stoppedAt).inMilliseconds}ms transcript="$transcript"',
      );
    } else {
      _log('speech completed transcript="$transcript"');
    }

    onCompleted?.call(transcript);
  }

  Future<void> _recover() async {
    if (_recovering) return;
    _recovering = true;

    try {
      await _speech.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      _available = await _speech.initialize(
        onError: _handleError,
        onStatus: _handleStatus,
      );
      _log('speech recovered available=$_available');
    } catch (error) {
      _available = false;
      _log('speech recover failed error=$error');
    } finally {
      _recovering = false;
    }
  }

  void _log(String message) {
    debugPrint('[SpeechCaptureService] $message');
    onLog?.call(message);
  }
}
