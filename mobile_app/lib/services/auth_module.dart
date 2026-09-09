import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../const.dart';

class AuthApiService {
  AuthApiService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Map<String, String> get _jsonHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'device_name': 'flutter-app',
      }),
    );

    final data = _decodeResponse(response);
    await _saveTokenFromResponse(data);

    return data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_name': 'flutter-app',
      }),
    );

    final data = _decodeResponse(response);
    await _saveTokenFromResponse(data);

    return data;
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _authHeaders(),
    );

    return _decodeResponse(response);
  }

  Future<void> logout() async {
    final response = await _client.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: await _authHeaders(),
    );

    _decodeResponse(response);
    await _storage.delete(key: _tokenKey);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.read(key: _tokenKey);

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _saveTokenFromResponse(Map<String, dynamic> data) async {
    final token = data['data']?['token']?['access_token'] as String?;

    if (token != null) {
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw Exception(data['message'] ?? 'Erreur API');
  }
}
