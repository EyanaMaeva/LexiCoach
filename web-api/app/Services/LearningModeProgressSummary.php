<?php

namespace App\Services;

use App\Models\LearningMode;
use App\Models\User;

class LearningModeProgressSummary
{
    public function __construct(
        private readonly ReadingProgressSummary $readingProgressSummary,
    ) {}

    /**
     * @return array<string, array<string, mixed>>
     */
    public function forUser(User $user): array
    {
        $progress = [];

        foreach ($this->activeModes() as $mode) {
            $progress[$mode->slug] = [
                'learning_mode' => $this->formatMode($mode),
                'summary' => $mode->slug === LearningMode::SLUG_READING
                    ? $this->readingProgressSummary->forUser($user)
                    : $this->readingProgressSummary->empty(),
            ];
        }

        return $progress;
    }

    /**
     * @return array<int, LearningMode>
     */
    public function activeModes(): array
    {
        return LearningMode::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->all();
    }

    /**
     * @return array<string, mixed>
     */
    public function formatMode(LearningMode $mode): array
    {
        return [
            'id' => $mode->id,
            'name' => $mode->name,
            'slug' => $mode->slug,
        ];
    }
}
