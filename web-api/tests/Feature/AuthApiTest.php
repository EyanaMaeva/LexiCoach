<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_receive_a_sanctum_token(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'full_name' => 'Marie Dupont',
            'email' => 'marie@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'device_name' => 'test-client',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.full_name', 'Marie Dupont')
            ->assertJsonPath('data.user.email', 'marie@example.com')
            ->assertJsonPath('data.token.type', 'Bearer')
            ->assertJsonStructure([
                'data' => [
                    'token' => [
                        'access_token',
                    ],
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'name' => 'Marie Dupont',
            'email' => 'marie@example.com',
        ]);
    }

    public function test_user_can_login_and_receive_a_sanctum_token(): void
    {
        User::factory()->create([
            'name' => 'Marie Dupont',
            'email' => 'marie@example.com',
            'password' => 'password123',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'marie@example.com',
            'password' => 'password123',
            'device_name' => 'test-client',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.full_name', 'Marie Dupont')
            ->assertJsonPath('data.token.type', 'Bearer')
            ->assertJsonStructure([
                'data' => [
                    'token' => [
                        'access_token',
                    ],
                ],
            ]);
    }

    public function test_invalid_login_returns_validation_error(): void
    {
        User::factory()->create([
            'email' => 'marie@example.com',
            'password' => 'password123',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'marie@example.com',
            'password' => 'wrong-password',
        ]);

        $response
            ->assertUnauthorized()
            ->assertJsonValidationErrors(['email']);
    }

    public function test_authenticated_user_can_get_profile(): void
    {
        $user = User::factory()->create([
            'name' => 'Marie Dupont',
            'email' => 'marie@example.com',
        ]);

        $token = $user->createToken('test-client')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/auth/me')
            ->assertOk()
            ->assertJsonPath('data.user.email', 'marie@example.com');
    }

    public function test_authenticated_user_can_logout_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-client')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/auth/logout')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_protected_routes_require_a_token(): void
    {
        $this->getJson('/api/auth/me')->assertUnauthorized();
        $this->postJson('/api/auth/logout')->assertUnauthorized();
    }

    public function test_api_documentation_page_shows_auth_endpoints_and_json_examples(): void
    {
        $this->get('/api/docs')
            ->assertOk()
            ->assertSeeText('Documentation API')
            ->assertSeeText('/api/auth/register')
            ->assertSeeText('/api/auth/login')
            ->assertSeeText('/api/auth/me')
            ->assertSeeText('/api/auth/logout')
            ->assertSeeText('"success": true')
            ->assertSeeText('"access_token": "1|exempleDeTokenSanctum"')
            ->assertSeeText('Scenarios et role du frontend')
            ->assertSeeText('Scenario 6 - Evaluation de la lecture')
            ->assertSeeText('Exemples Flutter')
            ->assertSeeText('Copier la doc en .md')
            ->assertSee('# Documentation API')
            ->assertSee('## Exemples Flutter')
            ->assertSeeText("const String baseUrl = 'http://10.0.2.2:8000/api';")
            ->assertSeeText('class AuthApiService');
    }
}
