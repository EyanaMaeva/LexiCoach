<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Contracts\View\View;

class ApiDocumentationController extends Controller
{
    public function __invoke(): View
    {
        return view('docs.api', [
            'documentation' => [
                'title' => 'Documentation API',
                'version' => '1.0',
                'base_url' => url('/api'),
                'authentication_type' => 'Bearer Token avec Laravel Sanctum',
                'important_headers' => [
                    'Accept' => 'application/json',
                    'Authorization' => 'Bearer {access_token}',
                ],
                'modules' => [
                    [
                        'name' => 'Authentification',
                        'slug' => 'authentification',
                        'description' => 'Module pour inscription, connexion, recuperation du profil connecte et deconnexion.',
                        'endpoints' => [
                            [
                                'name' => 'Inscription',
                                'method' => 'POST',
                                'path' => '/api/auth/register',
                                'protected' => false,
                                'description' => 'Cree un compte utilisateur et retourne directement un token Sanctum.',
                                'headers' => [
                                    'Accept' => 'application/json',
                                    'Content-Type' => 'application/json',
                                ],
                                'request_body' => [
                                    'full_name' => 'Marie Dupont',
                                    'email' => 'marie@example.com',
                                    'password' => 'password123',
                                    'password_confirmation' => 'password123',
                                    'device_name' => 'flutter-app',
                                ],
                                'responses' => [
                                    [
                                        'status' => 201,
                                        'title' => 'Succes',
                                        'body' => [
                                            'success' => true,
                                            'message' => 'Inscription reussie.',
                                            'data' => [
                                                'user' => [
                                                    'id' => 1,
                                                    'full_name' => 'Marie Dupont',
                                                    'email' => 'marie@example.com',
                                                    'email_verified_at' => null,
                                                    'created_at' => '2026-08-31T10:00:00.000000Z',
                                                ],
                                                'token' => [
                                                    'type' => 'Bearer',
                                                    'access_token' => '1|exempleDeTokenSanctum',
                                                    'expires_at' => null,
                                                ],
                                            ],
                                        ],
                                    ],
                                    [
                                        'status' => 422,
                                        'title' => 'Erreur de validation',
                                        'body' => [
                                            'message' => 'The email has already been taken. (and 1 more error)',
                                            'errors' => [
                                                'email' => ['The email has already been taken.'],
                                                'password' => ['The password field confirmation does not match.'],
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                            [
                                'name' => 'Connexion',
                                'method' => 'POST',
                                'path' => '/api/auth/login',
                                'protected' => false,
                                'description' => 'Connecte un utilisateur avec email et password puis retourne un token Sanctum.',
                                'headers' => [
                                    'Accept' => 'application/json',
                                    'Content-Type' => 'application/json',
                                ],
                                'request_body' => [
                                    'email' => 'marie@example.com',
                                    'password' => 'password123',
                                    'device_name' => 'flutter-app',
                                ],
                                'responses' => [
                                    [
                                        'status' => 200,
                                        'title' => 'Succes',
                                        'body' => [
                                            'success' => true,
                                            'message' => 'Connexion reussie.',
                                            'data' => [
                                                'user' => [
                                                    'id' => 1,
                                                    'full_name' => 'Marie Dupont',
                                                    'email' => 'marie@example.com',
                                                    'email_verified_at' => null,
                                                    'created_at' => '2026-08-31T10:00:00.000000Z',
                                                ],
                                                'token' => [
                                                    'type' => 'Bearer',
                                                    'access_token' => '1|exempleDeTokenSanctum',
                                                    'expires_at' => null,
                                                ],
                                            ],
                                        ],
                                    ],
                                    [
                                        'status' => 401,
                                        'title' => 'Identifiants incorrects',
                                        'body' => [
                                            'message' => 'Les identifiants sont incorrects.',
                                            'errors' => [
                                                'email' => ['Les identifiants sont incorrects.'],
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                            [
                                'name' => 'Utilisateur connecte',
                                'method' => 'GET',
                                'path' => '/api/auth/me',
                                'protected' => true,
                                'description' => 'Retourne les informations de l utilisateur connecte grace au token.',
                                'headers' => [
                                    'Accept' => 'application/json',
                                    'Authorization' => 'Bearer 1|exempleDeTokenSanctum',
                                ],
                                'request_body' => null,
                                'responses' => [
                                    [
                                        'status' => 200,
                                        'title' => 'Succes',
                                        'body' => [
                                            'success' => true,
                                            'message' => 'Utilisateur authentifie.',
                                            'data' => [
                                                'user' => [
                                                    'id' => 1,
                                                    'full_name' => 'Marie Dupont',
                                                    'email' => 'marie@example.com',
                                                    'email_verified_at' => null,
                                                    'created_at' => '2026-08-31T10:00:00.000000Z',
                                                ],
                                            ],
                                        ],
                                    ],
                                    [
                                        'status' => 401,
                                        'title' => 'Token absent ou invalide',
                                        'body' => [
                                            'message' => 'Unauthenticated.',
                                        ],
                                    ],
                                ],
                            ],
                            [
                                'name' => 'Deconnexion',
                                'method' => 'POST',
                                'path' => '/api/auth/logout',
                                'protected' => true,
                                'description' => 'Supprime le token actuel. Apres cette requete, ce token ne fonctionne plus.',
                                'headers' => [
                                    'Accept' => 'application/json',
                                    'Authorization' => 'Bearer 1|exempleDeTokenSanctum',
                                ],
                                'request_body' => null,
                                'responses' => [
                                    [
                                        'status' => 200,
                                        'title' => 'Succes',
                                        'body' => [
                                            'success' => true,
                                            'message' => 'Deconnexion reussie.',
                                            'data' => null,
                                        ],
                                    ],
                                    [
                                        'status' => 401,
                                        'title' => 'Token absent ou invalide',
                                        'body' => [
                                            'message' => 'Unauthenticated.',
                                        ],
                                    ],
                                ],
                            ],
                        ],
                    ],
                ],
                'frontend_steps' => [
                    'Appeler POST /api/auth/register ou POST /api/auth/login.',
                    'Recuperer data.token.access_token dans la reponse.',
                    'Sauvegarder le token cote frontend de maniere securisee.',
                    'Envoyer Authorization: Bearer {access_token} pour les routes protegees.',
                    'Appeler POST /api/auth/logout pour supprimer le token actuel.',
                ],
                'flutter_examples' => [
                    [
                        'title' => 'Packages Flutter a ajouter',
                        'language' => 'bash',
                        'code' => <<<'CODE'
flutter pub add http flutter_secure_storage
CODE,
                    ],
                    [
                        'title' => 'Choisir la bonne baseUrl',
                        'language' => 'dart',
                        'code' => <<<'CODE'
// Android emulator
const String baseUrl = 'http://10.0.2.2:8000/api';

// iOS simulator
const String baseUrl = 'http://localhost:8000/api';

// Telephone physique sur le meme Wi-Fi que ton ordinateur
// Remplace 192.168.1.20 par l'adresse IP locale de ton ordinateur.
const String baseUrl = 'http://192.168.1.20:8000/api';
CODE,
                    ],
                    [
                        'title' => 'Service Flutter complet pour consommer le module auth',
                        'language' => 'dart',
                        'code' => <<<'CODE'
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthApiService {
  AuthApiService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  static const String baseUrl = 'http://10.0.2.2:8000/api';
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
CODE,
                    ],
                    [
                        'title' => 'Exemple d appel depuis une page Flutter',
                        'language' => 'dart',
                        'code' => <<<'CODE'
final authApi = AuthApiService();

try {
  final response = await authApi.login(
    email: 'marie@example.com',
    password: 'password123',
  );

  final user = response['data']['user'];
  print('Connecte: ${user['full_name']}');
} catch (error) {
  print('Erreur de connexion: $error');
}
CODE,
                    ],
                ],
            ],
        ]);
    }
}
