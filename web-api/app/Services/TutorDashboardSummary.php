<?php

namespace App\Services;

use App\Models\LearningMode;
use App\Models\ReadingExerciseAttempt;
use App\Models\User;
use Illuminate\Support\Collection;

class TutorDashboardSummary
{
    public function __construct(
        private readonly LearningModeProgressSummary $learningModeProgressSummary,
        private readonly ReadingProgressSummary $readingProgressSummary,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function forTutor(User $tutor): array
    {
        $learners = $tutor->learners()
            ->where('role', User::ROLE_LEARNER)
            ->orderBy('name')
            ->get();

        return [
            'total_learners' => $learners->count(),
            'active_learners' => $this->activeLearnersCount($learners),
            'reading' => $this->readingOverview($learners),
            'progress_by_mode' => $this->progressByMode($learners),
        ];
    }

    /**
     * @param  Collection<int, User>  $learners
     */
    private function activeLearnersCount(Collection $learners): int
    {
        if ($learners->isEmpty()) {
            return 0;
        }

        return ReadingExerciseAttempt::query()
            ->whereIn('user_id', $learners->pluck('id')->all())
            ->distinct('user_id')
            ->count('user_id');
    }

    /**
     * @param  Collection<int, User>  $learners
     * @return array<string, mixed>
     */
    private function readingOverview(Collection $learners): array
    {
        $learnerIds = $learners->pluck('id')->all();

        if ($learnerIds === []) {
            return [
                'total_attempts' => 0,
                'average_score' => 0,
                'best_score' => 0,
                'latest_attempts' => [],
                'learners_needing_attention' => [],
            ];
        }

        $attemptsQuery = ReadingExerciseAttempt::query()
            ->whereIn('user_id', $learnerIds);

        $totalAttempts = (clone $attemptsQuery)->count();

        return [
            'total_attempts' => $totalAttempts,
            'average_score' => $totalAttempts > 0 ? (int) round((float) (clone $attemptsQuery)->avg('score')) : 0,
            'best_score' => $totalAttempts > 0 ? (int) (clone $attemptsQuery)->max('score') : 0,
            'latest_attempts' => $this->latestAttempts($learnerIds),
            'learners_needing_attention' => $this->learnersNeedingAttention($learners),
        ];
    }

    /**
     * @param  array<int, int>  $learnerIds
     * @return array<int, array<string, mixed>>
     */
    private function latestAttempts(array $learnerIds): array
    {
        return ReadingExerciseAttempt::query()
            ->with(['readingExercise', 'user'])
            ->whereIn('user_id', $learnerIds)
            ->latest()
            ->limit(5)
            ->get()
            ->map(fn (ReadingExerciseAttempt $attempt): array => [
                'learner' => $this->formatLearner($attempt->user),
                'attempt' => $this->readingProgressSummary->formatAttempt($attempt),
            ])
            ->all();
    }

    /**
     * @param  Collection<int, User>  $learners
     * @return array<int, array<string, mixed>>
     */
    private function learnersNeedingAttention(Collection $learners): array
    {
        return $learners
            ->map(function (User $learner): ?array {
                $summary = $this->readingProgressSummary->forUser($learner);

                if ($summary['total_attempts'] === 0) {
                    return [
                        'learner' => $this->formatLearner($learner),
                        'reason' => 'no_attempts',
                        'summary' => $summary,
                    ];
                }

                if ($summary['average_score'] < 70) {
                    return [
                        'learner' => $this->formatLearner($learner),
                        'reason' => 'low_average_score',
                        'summary' => $summary,
                    ];
                }

                return null;
            })
            ->filter()
            ->values()
            ->take(5)
            ->all();
    }

    /**
     * @param  Collection<int, User>  $learners
     * @return array<string, array<string, mixed>>
     */
    private function progressByMode(Collection $learners): array
    {
        $progress = [];

        foreach ($this->learningModeProgressSummary->activeModes() as $mode) {
            $progress[$mode->slug] = [
                'learning_mode' => $this->learningModeProgressSummary->formatMode($mode),
                'summary' => $mode->slug === LearningMode::SLUG_READING
                    ? $this->aggregateReadingSummary($learners)
                    : $this->emptyAggregateSummary(),
            ];
        }

        return $progress;
    }

    /**
     * @param  Collection<int, User>  $learners
     * @return array<string, mixed>
     */
    private function aggregateReadingSummary(Collection $learners): array
    {
        $overview = $this->readingOverview($learners);

        return [
            'total_attempts' => $overview['total_attempts'],
            'average_score' => $overview['average_score'],
            'best_score' => $overview['best_score'],
            'latest_attempts' => $overview['latest_attempts'],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function emptyAggregateSummary(): array
    {
        return [
            'total_attempts' => 0,
            'average_score' => 0,
            'best_score' => 0,
            'latest_attempts' => [],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function formatLearner(User $learner): array
    {
        return [
            'id' => $learner->id,
            'full_name' => $learner->name,
            'email' => $learner->email,
            'role' => $learner->role,
        ];
    }
}
