<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LearningMode;
use App\Models\ReadingExercise;
use Illuminate\Http\JsonResponse;

class LearningModeController extends Controller
{
    public function index(): JsonResponse
    {
        $modes = LearningMode::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->map(fn (LearningMode $mode): array => $this->formatMode($mode));

        return response()->json([
            'success' => true,
            'message' => 'Modes d apprentissage recuperes.',
            'data' => [
                'learning_modes' => $modes,
            ],
        ]);
    }

    public function show(string $slug): JsonResponse
    {
        $mode = $this->activeModeFromSlug($slug);

        return response()->json([
            'success' => true,
            'message' => 'Mode d apprentissage recupere.',
            'data' => [
                'learning_mode' => $this->formatMode($mode),
            ],
        ]);
    }

    public function readingExercises(string $slug): JsonResponse
    {
        $mode = $this->activeModeFromSlug($slug);

        abort_unless($mode->slug === LearningMode::SLUG_READING, 404);

        $exercises = ReadingExercise::query()
            ->whereBelongsTo($mode, 'learningMode')
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->map(fn (ReadingExercise $exercise): array => $this->formatReadingExercise($exercise));

        return response()->json([
            'success' => true,
            'message' => 'Exercices du mode reading recuperes.',
            'data' => [
                'learning_mode' => $this->formatMode($mode),
                'exercises' => $exercises,
            ],
        ]);
    }

    private function activeModeFromSlug(string $slug): LearningMode
    {
        return LearningMode::query()
            ->where('slug', $slug)
            ->where('is_active', true)
            ->firstOrFail();
    }

    /**
     * @return array<string, mixed>
     */
    private function formatMode(LearningMode $mode): array
    {
        return [
            'id' => $mode->id,
            'name' => $mode->name,
            'slug' => $mode->slug,
            'description' => $mode->description,
            'is_active' => $mode->is_active,
            'sort_order' => $mode->sort_order,
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function formatReadingExercise(ReadingExercise $exercise): array
    {
        return [
            'id' => $exercise->id,
            'title' => $exercise->title,
            'text' => $exercise->text,
            'language' => $exercise->language,
            'level' => $exercise->level,
        ];
    }
}
