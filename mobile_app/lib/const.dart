import 'package:flutter/foundation.dart';

/// API URLs can be overridden for a physical device or production build:
///
/// flutter run --dart-define=API_BASE_URL=https://lexicoach.mrsergio.dev/api \
///   --dart-define=AI_CONVERSATION_WS_URL=wss://realtime.example.com/ai-conversations/live
///
/// For a physical device using a backend on the development machine, replace
/// the host with that machine's LAN address, for example:
/// http://192.168.1.42:8000/api
const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
const _aiConversationWsUrlOverride = String.fromEnvironment(
  'AI_CONVERSATION_WS_URL',
);

String get _localApiHost {
  if (kIsWeb) {
    return 'localhost';
  }

  switch (defaultTargetPlatform) {
    // Android emulators expose the host computer through this special address.
    case TargetPlatform.android:
      return '10.0.2.2';
    // iOS simulators can reach the host computer directly via loopback.
    case TargetPlatform.iOS:
      return '127.0.0.1';
    default:
      return '127.0.0.1';
  }
}

final String baseUrl = _apiBaseUrlOverride.isNotEmpty
    ? _apiBaseUrlOverride
    : 'https://lexicoach.mrsergio.dev/api';

/// Same host as [baseUrl] but without the `/api` suffix, for web pages
/// served by the backend (e.g. payment success/cancel redirect pages).
final String webBaseUrl = baseUrl.endsWith('/api')
    ? baseUrl.substring(0, baseUrl.length - '/api'.length)
    : baseUrl;

final String aiConversationWsUrl = _aiConversationWsUrlOverride.isNotEmpty
    ? _aiConversationWsUrlOverride
    : 'ws://$_localApiHost:8787/ai-conversations/live';
