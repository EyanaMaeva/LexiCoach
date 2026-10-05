import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../const.dart';

class SmartAbstractApiService {
  SmartAbstractApiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<List<dynamic>> getExercises() async {
    final response = await _client.get(
      Uri.parse('$baseUrl/smart-abstract-exercises'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['exercises'];
  }

  Future<Map<String, dynamic>> getExerciseDetail(int id) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/smart-abstract-exercises/$id'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['exercise'];
  }

  Future<Map<String, dynamic>> evaluateExercise({
    required int id,
    required String documentText,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/smart-abstract-exercises/$id/evaluate'),
      headers: await _authHeaders(),
      body: jsonEncode({'document_text': documentText}),
    );

    final data = _decodeResponse(response);
    return data['data'];
  }

  /// Crée une session de paiement Mercy Pay (100 FCFA) pour débloquer une
  /// évaluation de cet exercice. Retourne `{payment: {...}, checkout_url}`.
  Future<Map<String, dynamic>> createCheckout(int id) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/smart-abstract-exercises/$id/checkout'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data'];
  }

  /// Consulte le statut d'un paiement (pending/completed/failed) par son id
  /// local, pour faire du polling après ouverture de la page de paiement.
  Future<Map<String, dynamic>> getPaymentStatus(int paymentId) async {
    final response = await _client.get(
      Uri.parse('$baseUrl/smart-abstract-payments/$paymentId'),
      headers: await _authHeaders(),
    );

    final data = _decodeResponse(response);
    return data['data']['payment'];
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
