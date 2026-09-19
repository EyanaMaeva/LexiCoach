import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../const.dart';

class AiConversationApiService {
  AiConversationApiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<String?> authToken() => _storage.read(key: _tokenKey);

  Future<Map<String, dynamic>> startSession() async {
    debugPrint('AI conversation API startSession request');

    final response = await _client.post(
      Uri.parse('$baseUrl/ai-conversations'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    debugPrint(
      'AI conversation API startSession status=${response.statusCode} data=${jsonEncode(data['data'])}',
    );

    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startRealtimeSession({
    String topicName = 'Conversation libre',
  }) async {
    debugPrint('AI conversation API startRealtimeSession request');

    final response = await _client.post(
      Uri.parse('$baseUrl/realtime/sessions'),
      headers: await _jsonAuthHeaders(),
      body: jsonEncode({
        'topic_name': topicName,
        'topic_id': null,
        'bonus_minutes': 0,
      }),
    );

    final data = _decodeResponse(response);
    debugPrint(
      'AI conversation API startRealtimeSession status=${response.statusCode} data=${jsonEncode(data['data'])}',
    );

    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> endRealtimeSession(int sessionId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/realtime/sessions/$sessionId/end'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> storeMessage({
    required int sessionId,
    required String role,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    final body = <String, dynamic>{'role': role, 'content': content};
    if (metadata != null) {
      body['metadata'] = metadata;
    }

    final response = await _client.post(
      Uri.parse('$baseUrl/ai-conversations/$sessionId/messages'),
      headers: await _jsonAuthHeaders(),
      body: jsonEncode(body),
    );

    final data = _decodeResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendTurn({
    required int sessionId,
    required String message,
  }) async {
    debugPrint(
      'AI conversation API sendTurn sessionId=$sessionId transcript="$message"',
    );

    final response = await _client.post(
      Uri.parse('$baseUrl/ai-conversations/$sessionId/turn'),
      headers: await _jsonAuthHeaders(),
      body: jsonEncode({'message': message}),
    );

    final data = _decodeResponse(response);
    final payload = data['data'] as Map<String, dynamic>;
    final coach = payload['coach'] as Map<String, dynamic>?;
    debugPrint(
      'AI conversation API sendTurn status=${response.statusCode} '
      'intent=${coach?['intent']} fallback=${coach?['fallback_used']} '
      'reason=${coach?['fallback_reason']} reply="${coach?['reply']}"',
    );

    return payload;
  }

  Future<Map<String, dynamic>> endSession(int sessionId) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/ai-conversations/$sessionId/end'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> expireSession(int sessionId) async {
    final response = await _client.patch(
      Uri.parse('$baseUrl/ai-conversations/$sessionId/expire'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> assessSession(int sessionId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/ai-conversations/$sessionId/assess'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: _tokenKey);

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, String>> _jsonAuthHeaders() async {
    final token = await _storage.read(key: _tokenKey);

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        throw Exception(firstError.first);
      }
    }

    throw Exception(data['message'] ?? 'API Error ${response.statusCode}');
  }
}
