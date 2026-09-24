import 'package:flutter/services.dart';

class PcmAudioPlayer {
  PcmAudioPlayer() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  static const MethodChannel _channel = MethodChannel(
    'com.example.lexicoach/pcm_player',
  );

  VoidCallback? onPlaybackIdle;

  Future<void> configure({required int sampleRate, int channels = 1}) {
    return _channel.invokeMethod('configure', {
      'sampleRate': sampleRate,
      'channels': channels,
    });
  }

  Future<void> playChunk(Uint8List bytes) {
    return _channel.invokeMethod('playChunk', bytes);
  }

  Future<void> markStreamEnd() {
    return _channel.invokeMethod('markStreamEnd');
  }

  Future<void> stop() {
    return _channel.invokeMethod('stop');
  }

  Future<void> dispose() async {
    await stop();
    _channel.setMethodCallHandler(null);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'playbackIdle') {
      onPlaybackIdle?.call();
    }
  }
}
