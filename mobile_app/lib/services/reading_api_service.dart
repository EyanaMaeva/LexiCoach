import 'dart:convert';
 import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../const.dart';

class ReadingApiService {
  ReadingApiService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: _tokenKey);
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/reading-exercises
  Future<List<dynamic>> getExercises() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/reading-exercises'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['exercises'];
  }

  /// GET /api/reading-exercises/{id}
  Future<Map<String, dynamic>> getExerciseDetail(int id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/reading-exercises/$id'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['exercise'];
  }

  /// POST /api/reading-exercises/{id}/evaluate
  Future<Map<String, dynamic>> evaluateExercise(int id, String transcript) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/reading-exercises/$id/evaluate'),
      headers: await _authHeaders(),
      body: jsonEncode({'transcript': transcript}),
    );

    final data = _decodeResponse(response);
    return data['data'];
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'API Error ${response.statusCode}');
  }
}
