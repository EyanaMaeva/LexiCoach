<?php

namespace App\Services;

use App\Models\LearningMode;
use App\Models\ReadingExercise;
use App\Models\ReadingExerciseAttempt;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class AdminDashboardSummary
{
    /**
     * @return array<string, mixed>
     */
    public function get(): array
    {
        $totalAttempts = ReadingExerciseAttempt::query()->count();

        return [
            'users' => [
                'total' => User::query()->count(),
                'learners' => User::query()->where('role', User::ROLE_LEARNER)->count(),
                'tutors' => User::query()->where('role', User::ROLE_TUTOR)->count(),
                'admins' => User::query()->where('role', User::ROLE_ADMIN)->count(),
                'recent' => User::query()
                    ->latest()
                    ->limit(5)
                    ->get()
                    ->map(fn (User $user): array => $this->formatUser($user))
                    ->all(),
            ],
            'learning' => [
                'modes' => LearningMode::query()->where('is_active', true)->count(),
                'reading_exercises' => ReadingExercise::query()->count(),
                'reading_attempts' => $totalAttempts,
                'average_reading_score' => $totalAttempts > 0
                    ? (int) round((float) ReadingExerciseAttempt::query()->avg('score'))
                    : 0,
                'best_reading_score' => $totalAttempts > 0
                    ? (int) ReadingExerciseAttempt::query()->max('score')
                    : 0,
            ],
            'tutor_view' => [
                'linked_pairs' => DB::table('tutor_learners')->count(),
                'tutors_with_learners' => DB::table('tutor_learners')
                    ->distinct('tutor_id')
                    ->count('tutor_id'),
            ],
            'recent_attempts' => ReadingExerciseAttempt::query()
                ->with(['readingExercise', 'user'])
                ->latest()
                ->limit(5)
                ->get()
                ->map(fn (ReadingExerciseAttempt $attempt): array => $this->formatAttempt($attempt))
                ->all(),
        ];
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
            'role' => $user->role,
            'created_at' => $user->created_at,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function formatAttempt(ReadingExerciseAttempt $attempt): array
    {
        return [
            'id' => $attempt->id,
            'learner' => $this->formatUser($attempt->user),
            'exercise' => [
                'id' => $attempt->readingExercise->id,
                'title' => $attempt->readingExercise->title,
                'language' => $attempt->readingExercise->language,
            ],
            'score' => $attempt->score,
            'status' => $attempt->status,
            'created_at' => $attempt->created_at,
        ];
    }
}
