import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../const.dart';

class TutorApiService {
  TutorApiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/tutor/dashboard'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['dashboard'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getLearners() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/tutor/learners'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['learners'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> linkLearner(String code) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/tutor/learners/link'),
      headers: await _jsonAuthHeaders(),
      body: jsonEncode({'code': code}),
    );

    final data = _decodeResponse(response);
    return data['data']['learner'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLearnerProgress(int learnerId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/tutor/learners/$learnerId/progress'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getLearnerAttempts({
    required int learnerId,
    required String module,
  }) async {
    final path = switch (module) {
      'writing' => 'writing-attempts',
      'smart-abstract' => 'smart-abstract-attempts',
      _ => 'reading-attempts',
    };

    final response = await _client.get(
      Uri.parse('$baseUrl/tutor/learners/$learnerId/$path'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['attempts'] as List<dynamic>;
  }

  Future<void> unlinkLearner(int learnerId) async {
    final response = await _client.delete(
      Uri.parse('$baseUrl/tutor/learners/$learnerId'),
      headers: await _authHeaders(),
    );

    _decodeResponse(response);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: _tokenKey);

    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<Map<String, String>> _jsonAuthHeaders() async {
    final headers = await _authHeaders();

    return {...headers, 'Content-Type': 'application/json'};
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'API Error ${response.statusCode}');
  }
}
