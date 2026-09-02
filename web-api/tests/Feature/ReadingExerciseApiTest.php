<?php

namespace Tests\Feature;

use App\Models\ReadingExercise;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReadingExerciseApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_user_can_list_active_reading_exercises(): void
    {
        $user = User::factory()->create();

        ReadingExercise::factory()->create([
            'title' => 'Museum visit',
            'text' => 'The children visited the beautiful museum yesterday.',
            'sort_order' => 2,
        ]);

        ReadingExercise::factory()->create([
            'title' => 'Inactive exercise',
            'is_active' => false,
            'sort_order' => 1,
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/reading-exercises')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data.exercises')
            ->assertJsonPath('data.exercises.0.title', 'Museum visit');
    }

    public function test_authenticated_user_can_get_one_reading_exercise(): void
    {
        $user = User::factory()->create();
        $exercise = ReadingExercise::factory()->create([
            'title' => 'Garden story',
            'text' => 'The little boy is playing in the garden.',
        ]);

        Sanctum::actingAs($user);

        $this->getJson("/api/reading-exercises/{$exercise->id}")
            ->assertOk()
            ->assertJsonPath('data.exercise.title', 'Garden story')
            ->assertJsonPath('data.exercise.language', 'en-US');
    }

    public function test_reading_exercise_evaluation_returns_perfect_score_when_transcript_matches(): void
    {
        $user = User::factory()->create();
        $exercise = ReadingExercise::factory()->create([
            'text' => 'The little boy is playing in the garden.',
        ]);

        Sanctum::actingAs($user);

        $this->postJson("/api/reading-exercises/{$exercise->id}/evaluate", [
            'transcript' => 'The little boy is playing in the garden.',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.result.score', 100)
            ->assertJsonPath('data.result.status', 'excellent')
            ->assertJsonPath('data.result.is_correct', true)
            ->assertJsonPath('data.result.feedback.title', 'Excellent!')
            ->assertJsonPath('data.result.words.0.status', 'correct');
    }

    public function test_reading_exercise_evaluation_detects_missing_and_incorrect_words(): void
    {
        $user = User::factory()->create();
        $exercise = ReadingExercise::factory()->create([
            'text' => 'The little boy is playing in the garden.',
        ]);

        Sanctum::actingAs($user);

        $response = $this->postJson("/api/reading-exercises/{$exercise->id}/evaluate", [
            'transcript' => 'The little boy playing on garden.',
        ])
            ->assertOk()
            ->assertJsonPath('data.result.is_correct', false);

        $statuses = collect($response->json('data.result.words'))->pluck('status')->all();

        $this->assertContains('missing', $statuses);
        $this->assertContains('incorrect', $statuses);
    }

    public function test_reading_exercise_evaluation_requires_a_transcript(): void
    {
        $user = User::factory()->create();
        $exercise = ReadingExercise::factory()->create();

        Sanctum::actingAs($user);

        $this->postJson("/api/reading-exercises/{$exercise->id}/evaluate", [])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['transcript']);
    }

    public function test_reading_exercise_routes_require_authentication(): void
    {
        $exercise = ReadingExercise::factory()->create();

        $this->getJson('/api/reading-exercises')->assertUnauthorized();
        $this->getJson("/api/reading-exercises/{$exercise->id}")->assertUnauthorized();
        $this->postJson("/api/reading-exercises/{$exercise->id}/evaluate", [
            'transcript' => 'Hello',
        ])->assertUnauthorized();
    }
}
