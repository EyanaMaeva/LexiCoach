# Module d'authentification API

Ce document explique le module d'authentification backend de LexiCoach. Il est volontairement simple pour aider une debutante a comprendre les notions et a consommer l'API depuis un frontend ou une app mobile.

## Objectif

Le backend permet de faire:

- une inscription avec `full_name`, `email`, `password`, `password_confirmation`
- une connexion avec `email`, `password`
- la recuperation de l'utilisateur connecte
- la deconnexion
- une page de documentation API accessible depuis une route backend

Le frontend n'a pas ete modifie.

## Routes disponibles

Base URL locale:

```text
http://localhost:8000/api
```

Documentation API:

```http
GET /api/docs
```

Inscription:

```http
POST /api/auth/register
```

Connexion:

```http
POST /api/auth/login
```

Utilisateur connecte:

```http
GET /api/auth/me
Authorization: Bearer {access_token}
```

Deconnexion:

```http
POST /api/auth/logout
Authorization: Bearer {access_token}
```

## Notions importantes

### Authentication

L'authentication permet de verifier l'identite d'un utilisateur. Exemple: l'utilisateur donne son email et son mot de passe. Le backend verifie si ces informations correspondent a un compte existant.

### User

`User` represente un utilisateur en base de donnees. Dans Laravel, le modele se trouve ici:

```text
app/Models/User.php
```

Dans ce projet, la table `users` a deja les colonnes principales:

- `name`
- `email`
- `password`

L'API utilise le nom `full_name` pour le frontend, mais en base Laravel stocke cette valeur dans la colonne `name`.

### Hash du password

Il ne faut jamais stocker un mot de passe en clair. Laravel transforme le mot de passe en version securisee avec un hash.

Dans ce projet, le modele `User` contient:

```php
'password' => 'hashed',
```

Cela veut dire que Laravel hash automatiquement le password quand on cree l'utilisateur.

### Token

Un token est une chaine de caracteres generee apres une inscription ou une connexion. Le frontend garde ce token et l'envoie dans les prochaines requetes protegees.

Exemple:

```http
Authorization: Bearer 1|exempleDeTokenSanctum
```

### Laravel Sanctum

Sanctum est le package Laravel utilise pour gerer les tokens API. Il est adapte pour les APIs simples, les apps mobiles et les SPAs.

Installation de Sanctum si ce n'est pas encore fait:

```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

Dans ce projet, Sanctum est deja installe et la migration `personal_access_tokens` existe deja.

### HasApiTokens

Pour qu'un utilisateur puisse creer des tokens Sanctum, le modele `User` doit utiliser le trait `HasApiTokens`.

Dans `app/Models/User.php`:

```php
use Laravel\Sanctum\HasApiTokens;
```

Puis dans la classe:

```php
use HasApiTokens, HasFactory, Notifiable;
```

Sans `HasApiTokens`, cette ligne ne peut pas fonctionner:

```php
$user->createToken('api-client')->plainTextToken;
```

### Middleware auth:sanctum

Un middleware est une verification executee avant d'entrer dans une route.

`auth:sanctum` verifie que la requete contient un token valide.

Exemple:

```php
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
});
```

Si le token est absent ou invalide, Laravel retourne:

```json
{
    "message": "Unauthenticated."
}
```

## Consommer l'API

### 1. Inscription

Requete:

```http
POST /api/auth/register
Accept: application/json
Content-Type: application/json
```

Body:

```json
{
    "full_name": "Marie Dupont",
    "email": "marie@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "device_name": "flutter-app"
}
```

Reponse succes:

```json
{
    "success": true,
    "message": "Inscription reussie.",
    "data": {
        "user": {
            "id": 1,
            "full_name": "Marie Dupont",
            "email": "marie@example.com",
            "email_verified_at": null,
            "created_at": "2026-08-31T10:00:00.000000Z"
        },
        "token": {
            "type": "Bearer",
            "access_token": "1|exempleDeTokenSanctum",
            "expires_at": null
        }
    }
}
```

### 2. Connexion

Requete:

```http
POST /api/auth/login
Accept: application/json
Content-Type: application/json
```

Body:

```json
{
    "email": "marie@example.com",
    "password": "password123",
    "device_name": "flutter-app"
}
```

Reponse succes:

```json
{
    "success": true,
    "message": "Connexion reussie.",
    "data": {
        "user": {
            "id": 1,
            "full_name": "Marie Dupont",
            "email": "marie@example.com",
            "email_verified_at": null,
            "created_at": "2026-08-31T10:00:00.000000Z"
        },
        "token": {
            "type": "Bearer",
            "access_token": "1|exempleDeTokenSanctum",
            "expires_at": null
        }
    }
}
```

Identifiants incorrects:

```json
{
    "message": "Les identifiants sont incorrects.",
    "errors": {
        "email": [
            "Les identifiants sont incorrects."
        ]
    }
}
```

### 3. Recuperer l'utilisateur connecte

Requete:

```http
GET /api/auth/me
Accept: application/json
Authorization: Bearer 1|exempleDeTokenSanctum
```

Reponse succes:

```json
{
    "success": true,
    "message": "Utilisateur authentifie.",
    "data": {
        "user": {
            "id": 1,
            "full_name": "Marie Dupont",
            "email": "marie@example.com",
            "email_verified_at": null,
            "created_at": "2026-08-31T10:00:00.000000Z"
        }
    }
}
```

### 4. Deconnexion

Requete:

```http
POST /api/auth/logout
Accept: application/json
Authorization: Bearer 1|exempleDeTokenSanctum
```

Reponse succes:

```json
{
    "success": true,
    "message": "Deconnexion reussie.",
    "data": null
}
```

## Erreurs de validation

Si une information obligatoire manque ou n'est pas valide, Laravel retourne un status `422`.

Exemple:

```json
{
    "message": "The password field confirmation does not match.",
    "errors": {
        "password": [
            "The password field confirmation does not match."
        ]
    }
}
```

## Tester rapidement avec curl

Inscription:

```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"full_name":"Marie Dupont","email":"marie@example.com","password":"password123","password_confirmation":"password123","device_name":"curl"}'
```

Connexion:

```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{"email":"marie@example.com","password":"password123","device_name":"curl"}'
```

Utilisateur connecte:

```bash
curl http://localhost:8000/api/auth/me \
  -H "Accept: application/json" \
  -H "Authorization: Bearer TON_TOKEN_ICI"
```

Deconnexion:

```bash
curl -X POST http://localhost:8000/api/auth/logout \
  -H "Accept: application/json" \
  -H "Authorization: Bearer TON_TOKEN_ICI"
```

## Exemples Flutter

La page `/api/docs` contient aussi des exemples Flutter complets. Cette section resume les points importants.

### Packages a installer

```bash
flutter pub add http flutter_secure_storage
```

`http` sert a envoyer les requetes vers Laravel. `flutter_secure_storage` sert a sauvegarder le token de maniere plus securisee qu'une simple variable.

### Choisir la bonne baseUrl

```dart
// Android emulator
const String baseUrl = 'http://10.0.2.2:8000/api';

// iOS simulator
const String baseUrl = 'http://localhost:8000/api';

// Telephone physique sur le meme Wi-Fi que ton ordinateur
const String baseUrl = 'http://192.168.1.20:8000/api';
```

Pour un telephone physique, il faut remplacer `192.168.1.20` par l'adresse IP locale de l'ordinateur qui lance Laravel.

### Exemple simple de login Flutter

```dart
final response = await http.post(
  Uri.parse('$baseUrl/auth/login'),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'email': 'marie@example.com',
    'password': 'password123',
    'device_name': 'flutter-app',
  }),
);

final data = jsonDecode(response.body);
final token = data['data']['token']['access_token'];
```

### Exemple de requete protegee Flutter

```dart
final response = await http.get(
  Uri.parse('$baseUrl/auth/me'),
  headers: {
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  },
);
```

La notion importante est celle-ci: apres login ou inscription, Flutter recupere `data.token.access_token`, puis l'envoie dans le header `Authorization` pour toutes les routes protegees.

## Google Auth

Google Auth n'a pas ete implemente dans cette premiere version pour garder le module simple.

La logique a comprendre:

1. Le frontend recupere un token Google.
2. Le backend verifie ce token avec Google.
3. Le backend cree ou retrouve l'utilisateur.
4. Le backend retourne un token Sanctum comme pour le login normal.

Package Laravel souvent utilise pour ca:

```bash
composer require laravel/socialite
```

Ce sera une evolution possible du module.
