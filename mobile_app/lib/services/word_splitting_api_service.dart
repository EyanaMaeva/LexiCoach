import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../const.dart';

class WordSplittingApiService {
  WordSplittingApiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<Map<String, dynamic>> splitText({
    required String text,
    String language = 'en-US',
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/word-splitting/split'),
      headers: await _authHeaders(),
      body: jsonEncode({'text': text, 'language': language}),
    );

    final data = _decodeResponse(response);
    return data['data']['result'] as Map<String, dynamic>;
  }

  Future<Map<String, String>> _authHeaders() async {
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

    throw Exception(data['message'] ?? 'API Error ${response.statusCode}');
  }
}
