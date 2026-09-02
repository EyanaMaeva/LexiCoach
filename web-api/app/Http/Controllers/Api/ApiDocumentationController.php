<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Contracts\View\View;

class ApiDocumentationController extends Controller
{
    public function __invoke(): View
    {
        $documentation = [
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
                [
                    'name' => 'Reading exercises',
                    'slug' => 'reading-exercises',
                    'description' => 'Module pour recuperer des exercices de lecture et evaluer le texte reconnu par le micro cote Flutter.',
                    'endpoints' => [
                        [
                            'name' => 'Liste des exercices',
                            'method' => 'GET',
                            'path' => '/api/reading-exercises',
                            'protected' => true,
                            'description' => 'Retourne les exercices actifs. Flutter affiche ensuite le text, la langue et le niveau.',
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
                                        'message' => 'Exercices de lecture recuperes.',
                                        'data' => [
                                            'exercises' => [
                                                [
                                                    'id' => 1,
                                                    'title' => 'Museum visit',
                                                    'text' => 'The children visited the beautiful museum yesterday.',
                                                    'language' => 'en-US',
                                                    'level' => 'beginner',
                                                ],
                                            ],
                                        ],
                                    ],
                                ],
                            ],
                        ],
                        [
                            'name' => 'Detail d un exercice',
                            'method' => 'GET',
                            'path' => '/api/reading-exercises/{readingExercise}',
                            'protected' => true,
                            'description' => 'Retourne un seul exercice. Le champ language aide Flutter a choisir la voix TTS et la langue STT.',
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
                                        'message' => 'Exercice de lecture recupere.',
                                        'data' => [
                                            'exercise' => [
                                                'id' => 1,
                                                'title' => 'Museum visit',
                                                'text' => 'The children visited the beautiful museum yesterday.',
                                                'language' => 'en-US',
                                                'level' => 'beginner',
                                            ],
                                        ],
                                    ],
                                ],
                                [
                                    'status' => 404,
                                    'title' => 'Exercice absent ou inactif',
                                    'body' => [
                                        'message' => 'Not Found',
                                    ],
                                ],
                            ],
                        ],
                        [
                            'name' => 'Evaluer une lecture',
                            'method' => 'POST',
                            'path' => '/api/reading-exercises/{readingExercise}/evaluate',
                            'protected' => true,
                            'description' => 'Compare le transcript envoye par Flutter avec le text officiel stocke en base.',
                            'headers' => [
                                'Accept' => 'application/json',
                                'Content-Type' => 'application/json',
                                'Authorization' => 'Bearer 1|exempleDeTokenSanctum',
                            ],
                            'request_body' => [
                                'transcript' => 'The children visited beautiful museum yesterday.',
                            ],
                            'responses' => [
                                [
                                    'status' => 200,
                                    'title' => 'Succes',
                                    'body' => [
                                        'success' => true,
                                        'message' => 'Lecture evaluee.',
                                        'data' => [
                                            'exercise' => [
                                                'id' => 1,
                                                'title' => 'Museum visit',
                                                'text' => 'The children visited the beautiful museum yesterday.',
                                                'language' => 'en-US',
                                                'level' => 'beginner',
                                            ],
                                            'result' => [
                                                'score' => 86,
                                                'status' => 'good',
                                                'is_correct' => false,
                                                'transcript' => 'The children visited beautiful museum yesterday.',
                                                'words' => [
                                                    [
                                                        'expected' => 'The',
                                                        'actual' => 'The',
                                                        'status' => 'correct',
                                                    ],
                                                    [
                                                        'expected' => 'children',
                                                        'actual' => 'children',
                                                        'status' => 'correct',
                                                    ],
                                                    [
                                                        'expected' => 'visited',
                                                        'actual' => 'visited',
                                                        'status' => 'correct',
                                                    ],
                                                    [
                                                        'expected' => 'the',
                                                        'actual' => null,
                                                        'status' => 'missing',
                                                    ],
                                                ],
                                                'feedback' => [
                                                    'title' => 'Good job!',
                                                    'message' => 'You read most of the sentence correctly. Try again and focus on the highlighted words.',
                                                ],
                                            ],
                                        ],
                                    ],
                                ],
                                [
                                    'status' => 422,
                                    'title' => 'Transcript manquant',
                                    'body' => [
                                        'message' => 'The transcript field is required.',
                                        'errors' => [
                                            'transcript' => ['The transcript field is required.'],
                                        ],
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
                'Pour Reading Practice, utiliser flutter_tts pour lire le text et speech_to_text pour obtenir le transcript.',
                'Envoyer seulement le transcript au backend. Le backend compare avec le text officiel de l exercice.',
                'Appeler POST /api/auth/logout pour supprimer le token actuel.',
            ],
            'feature_guides' => [
                [
                    'title' => 'Scenario 1 - Inscription',
                    'goal' => 'Permettre a une nouvelle utilisatrice de creer son compte et d entrer dans l application.',
                    'user_story' => 'L utilisatrice remplit son nom, son email, son mot de passe et confirme son mot de passe. Elle appuie sur Sign up.',
                    'frontend_tasks' => [
                        'Verifier que les champs ne sont pas vides avant d appeler l API.',
                        'Verifier que password et password_confirmation sont identiques.',
                        'Afficher un loader pendant l appel API pour eviter les doubles clics.',
                        'Sauvegarder data.token.access_token si l inscription reussit.',
                        'Rediriger vers le dashboard ou vers Practice Exercises apres le succes.',
                    ],
                    'api_flow' => [
                        'POST /api/auth/register',
                        'Le backend cree le User.',
                        'Le backend retourne le user et un token Sanctum.',
                    ],
                    'display_rules' => [
                        'Si success vaut true, afficher un message de succes court.',
                        'Si Laravel retourne 422, afficher les erreurs sous les champs concernes.',
                        'Ne jamais afficher le password dans l interface ou dans les logs.',
                    ],
                ],
                [
                    'title' => 'Scenario 2 - Connexion',
                    'goal' => 'Permettre a une utilisatrice existante de recuperer son token et d acceder aux routes protegees.',
                    'user_story' => 'L utilisatrice entre son email et son mot de passe, puis appuie sur Login.',
                    'frontend_tasks' => [
                        'Envoyer email, password et device_name au backend.',
                        'Sauvegarder le token dans flutter_secure_storage.',
                        'Garder le user connecte en memoire pour afficher son nom dans l app.',
                        'Ajouter Authorization: Bearer {token} sur toutes les routes protegees.',
                    ],
                    'api_flow' => [
                        'POST /api/auth/login',
                        'Le backend verifie email et password.',
                        'Le backend retourne le user et un token si les identifiants sont bons.',
                    ],
                    'display_rules' => [
                        'Si la reponse est 401, afficher que les identifiants sont incorrects.',
                        'Si la reponse est 422, afficher les erreurs de validation.',
                        'Ne pas rediriger tant que le token n est pas sauvegarde.',
                    ],
                ],
                [
                    'title' => 'Scenario 3 - Ouvrir Reading Practice',
                    'goal' => 'Afficher a l utilisatrice une phrase officielle a lire.',
                    'user_story' => 'L utilisatrice clique sur Practice Exercises, choisit Reading, puis voit une phrase a lire.',
                    'frontend_tasks' => [
                        'Verifier que le token existe avant de charger la page.',
                        'Appeler GET /api/reading-exercises pour recuperer les exercices disponibles.',
                        'Afficher le premier exercice ou laisser l utilisatrice en choisir un.',
                        'Garder exercise.id, exercise.text et exercise.language dans l etat de la page.',
                    ],
                    'api_flow' => [
                        'GET /api/reading-exercises',
                        'Optionnel: GET /api/reading-exercises/{readingExercise} pour recharger un exercice precis.',
                    ],
                    'display_rules' => [
                        'Afficher un loader pendant le chargement.',
                        'Afficher le texte de exercise.text exactement comme le backend le retourne.',
                        'Si la reponse est 401, renvoyer vers l ecran de login.',
                    ],
                ],
                [
                    'title' => 'Scenario 4 - Bouton Listen avec TTS',
                    'goal' => 'Permettre a l utilisatrice d ecouter la bonne lecture avant de parler.',
                    'user_story' => 'L utilisatrice appuie sur Listen. Le telephone lit la phrase avec une voix claire.',
                    'frontend_tasks' => [
                        'Utiliser le package flutter_tts cote Flutter.',
                        'Utiliser exercise.language pour choisir la langue, par exemple en-US.',
                        'Lire exercise.text avec flutterTts.speak(exercise.text).',
                        'Ajouter une option Slow si besoin avec une vitesse plus basse.',
                    ],
                    'api_flow' => [
                        'Aucun appel backend n est necessaire pour le TTS dans le MVP.',
                        'Le backend fournit seulement le texte et la langue de l exercice.',
                    ],
                    'display_rules' => [
                        'Desactiver temporairement le bouton Listen pendant la lecture audio.',
                        'Prevoir un bouton Stop si la lecture est longue.',
                        'Ne pas envoyer le texte au backend pour le faire lire dans cette version.',
                    ],
                ],
                [
                    'title' => 'Scenario 5 - Bouton Micro avec STT',
                    'goal' => 'Transformer ce que l utilisatrice dit en texte reconnu.',
                    'user_story' => 'L utilisatrice appuie sur le micro, lit la phrase a voix haute, puis l app affiche ce qu elle a dit.',
                    'frontend_tasks' => [
                        'Demander la permission microphone avant de commencer.',
                        'Utiliser le package speech_to_text cote Flutter.',
                        'Utiliser exercise.language comme locale de reconnaissance vocale.',
                        'Afficher le transcript en direct si le package le permet.',
                        'Garder le dernier transcript reconnu dans l etat de la page.',
                    ],
                    'api_flow' => [
                        'Aucun audio n est envoye au backend dans le MVP.',
                        'Le backend recevra seulement le transcript final.',
                    ],
                    'display_rules' => [
                        'Afficher Listening pendant que le micro ecoute.',
                        'Afficher un message clair si la permission micro est refusee.',
                        'Ne pas appeler evaluate tant que transcript est vide.',
                    ],
                ],
                [
                    'title' => 'Scenario 6 - Evaluation de la lecture',
                    'goal' => 'Comparer le transcript avec le texte officiel et afficher un feedback utile.',
                    'user_story' => 'Apres avoir parle, l utilisatrice appuie sur Check ou l app lance l evaluation automatiquement.',
                    'frontend_tasks' => [
                        'Envoyer seulement transcript au backend.',
                        'Ne pas envoyer expected_text depuis Flutter, car le backend est la source de verite.',
                        'Lire data.result.score pour afficher le pourcentage.',
                        'Lire data.result.words pour colorer les mots corrects, manquants, incorrects ou en trop.',
                        'Lire data.result.feedback.title et message pour afficher le feedback.',
                    ],
                    'api_flow' => [
                        'POST /api/reading-exercises/{readingExercise}/evaluate',
                        'Le backend recupere exercise.text en base.',
                        'Le backend compare exercise.text avec transcript.',
                        'Le backend retourne score, status, is_correct, words et feedback.',
                    ],
                    'display_rules' => [
                        'Si is_correct vaut true, afficher une felicitation.',
                        'Si status vaut good, encourager a reessayer les mots surlignes.',
                        'Si status vaut needs_practice, proposer Listen puis Try again.',
                        'Si la reponse est 422, verifier que transcript n est pas vide.',
                    ],
                ],
            ],
            'flutter_examples' => [
                [
                    'title' => 'Packages Flutter a ajouter',
                    'language' => 'bash',
                    'code' => <<<'CODE'
flutter pub add http flutter_secure_storage

# Pour le module Reading Practice cote mobile
flutter pub add flutter_tts speech_to_text
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
                [
                    'title' => 'Evaluer une lecture depuis Flutter',
                    'language' => 'dart',
                    'code' => <<<'CODE'
final response = await client.post(
  Uri.parse('$baseUrl/reading-exercises/1/evaluate'),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'transcript': 'The children visited beautiful museum yesterday.',
  }),
);

final data = jsonDecode(response.body) as Map<String, dynamic>;
final result = data['data']['result'];

print('Score: ${result['score']}');
print('Feedback: ${result['feedback']['message']}');
CODE,
                ],
            ],
        ];

        return view('docs.api', [
            'documentation' => $documentation,
            'markdownDocumentation' => $this->toMarkdown($documentation),
        ]);
    }

    /**
     * @param  array<string, mixed>  $documentation
     */
    private function toMarkdown(array $documentation): string
    {
        $lines = [
            '# '.$documentation['title'],
            '',
            '- Version: '.$documentation['version'],
            '- Base URL: `'.$documentation['base_url'].'`',
            '- Authentication: '.$documentation['authentication_type'],
            '',
            '## Headers importants',
            '',
            $this->codeBlock('json', $documentation['important_headers']),
            '',
            '## Etapes cote frontend',
            '',
        ];

        foreach ($documentation['frontend_steps'] as $index => $step) {
            $lines[] = ($index + 1).'. '.$step;
        }

        $lines[] = '';
        $lines[] = '## Scenarios et role du frontend';
        $lines[] = '';

        foreach ($documentation['feature_guides'] as $guide) {
            $lines[] = '### '.$guide['title'];
            $lines[] = '';
            $lines[] = '**Objectif:** '.$guide['goal'];
            $lines[] = '';
            $lines[] = '**Scenario utilisateur:** '.$guide['user_story'];
            $lines[] = '';
            $lines[] = '#### Ce que le frontend doit faire';
            $lines[] = '';

            foreach ($guide['frontend_tasks'] as $task) {
                $lines[] = '- '.$task;
            }

            $lines[] = '';
            $lines[] = '#### Parcours API';
            $lines[] = '';

            foreach ($guide['api_flow'] as $step) {
                $lines[] = '- '.$step;
            }

            $lines[] = '';
            $lines[] = '#### Regles d affichage';
            $lines[] = '';

            foreach ($guide['display_rules'] as $rule) {
                $lines[] = '- '.$rule;
            }

            $lines[] = '';
        }

        foreach ($documentation['modules'] as $module) {
            $lines[] = '## '.$module['name'];
            $lines[] = '';
            $lines[] = $module['description'];
            $lines[] = '';

            foreach ($module['endpoints'] as $endpoint) {
                $lines[] = '### '.$endpoint['name'];
                $lines[] = '';
                $lines[] = '- Method: `'.$endpoint['method'].'`';
                $lines[] = '- Path: `'.$endpoint['path'].'`';
                $lines[] = '- Protected: '.($endpoint['protected'] ? 'oui, token requis' : 'non, route publique');
                $lines[] = '';
                $lines[] = $endpoint['description'];
                $lines[] = '';
                $lines[] = '#### Headers';
                $lines[] = '';
                $lines[] = $this->codeBlock('json', $endpoint['headers']);
                $lines[] = '';
                $lines[] = '#### Body a envoyer';
                $lines[] = '';
                $lines[] = $endpoint['request_body'] === null
                    ? 'Aucun body'
                    : $this->codeBlock('json', $endpoint['request_body']);
                $lines[] = '';

                foreach ($endpoint['responses'] as $response) {
                    $lines[] = '#### Reponse '.$response['status'].' - '.$response['title'];
                    $lines[] = '';
                    $lines[] = $this->codeBlock('json', $response['body']);
                    $lines[] = '';
                }
            }
        }

        $lines[] = '## Exemples Flutter';
        $lines[] = '';
        $lines[] = 'Ces exemples montrent comment une app Flutter peut appeler le backend, recuperer le token Sanctum et l utiliser sur les routes protegees.';
        $lines[] = '';

        foreach ($documentation['flutter_examples'] as $example) {
            $lines[] = '### '.$example['title'];
            $lines[] = '';
            $lines[] = $this->codeBlock($example['language'], $example['code']);
            $lines[] = '';
        }

        return trim(implode("\n", $lines))."\n";
    }

    /**
     * @param  array<string, mixed>|string|null  $content
     */
    private function codeBlock(string $language, array|string|null $content): string
    {
        if (is_array($content)) {
            $content = json_encode($content, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
        }

        return "```{$language}\n{$content}\n```";
    }
}
