import 'dart:io';

final String _localApiHost = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';

final String baseUrl = 'http://$_localApiHost:8000/api';
final String aiConversationWsUrl =
    'ws://$_localApiHost:8787/ai-conversations/live';
