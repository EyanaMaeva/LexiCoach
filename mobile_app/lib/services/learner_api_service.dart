import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../const.dart';

class LearnerApiService {
  LearnerApiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<List<dynamic>> getLearningModes() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/learning-modes'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['learning_modes'];
  }

  Future<Map<String, dynamic>> getModeExercises(String slug) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/learning-modes/$slug/exercises'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data'];
  }

  Future<Map<String, dynamic>> getProgress() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/me/progress'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['progress'];
  }

  Future<Map<String, dynamic>?> getAssociationCode() async {
    final data = await getTutorLinkStatus();
    return data['association_code'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>> getTutorLinkStatus() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/me/association-code'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generateAssociationCode() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/me/association-code'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['association_code'];
  }

  Future<Map<String, dynamic>> regenerateAssociationCode() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/me/association-code/regenerate'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['association_code'];
  }

  Future<void> cancelAssociationCode() async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/me/association-code'),
      headers: await _authHeaders(),
    );

    _decodeResponse(response);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: _tokenKey);

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'API Error ${response.statusCode}');
  }
}
