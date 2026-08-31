<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'full_name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        $user = User::create([
            'name' => $validated['full_name'],
            'email' => $validated['email'],
            'password' => $validated['password'],
        ]);

        $token = $user->createToken($validated['device_name'] ?? 'api-client')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Inscription reussie.',
            'data' => [
                'user' => $this->formatUser($user),
                'token' => $this->formatToken($token),
            ],
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
            'device_name' => ['nullable', 'string', 'max:255'],
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Les identifiants sont incorrects.'],
            ])->status(401);
        }

        $token = $user->createToken($validated['device_name'] ?? 'api-client')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Connexion reussie.',
            'data' => [
                'user' => $this->formatUser($user),
                'token' => $this->formatToken($token),
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Utilisateur authentifie.',
            'data' => [
                'user' => $this->formatUser($request->user()),
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'success' => true,
            'message' => 'Deconnexion reussie.',
            'data' => null,
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'full_name' => $user->name,
            'email' => $user->email,
            'email_verified_at' => $user->email_verified_at,
            'created_at' => $user->created_at,
        ];
    }

    /**
     * @return array<string, string|null>
     */
    private function formatToken(string $plainTextToken): array
    {
        return [
            'type' => 'Bearer',
            'access_token' => $plainTextToken,
            'expires_at' => null,
        ];
    }
}
