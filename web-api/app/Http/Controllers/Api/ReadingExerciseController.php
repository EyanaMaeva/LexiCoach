<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\EvaluateReadingExerciseRequest;
use App\Models\ReadingExercise;
use App\Services\ReadingEvaluator;
use Illuminate\Http\JsonResponse;

class ReadingExerciseController extends Controller
{
    public function __construct(
        private readonly ReadingEvaluator $readingEvaluator,
    ) {}

    public function index(): JsonResponse
    {
        $exercises = ReadingExercise::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('id')
            ->get()
            ->map(fn (ReadingExercise $exercise): array => $this->formatExercise($exercise));

        return response()->json([
            'success' => true,
            'message' => 'Exercices de lecture recuperes.',
            'data' => [
                'exercises' => $exercises,
            ],
        ]);
    }

    public function show(ReadingExercise $readingExercise): JsonResponse
    {
        abort_unless($readingExercise->is_active, 404);

        return response()->json([
            'success' => true,
            'message' => 'Exercice de lecture recupere.',
            'data' => [
                'exercise' => $this->formatExercise($readingExercise),
            ],
        ]);
    }

    public function evaluate(
        ReadingExercise $readingExercise,
        EvaluateReadingExerciseRequest $request,
    ): JsonResponse {
        abort_unless($readingExercise->is_active, 404);

        $result = $this->readingEvaluator->evaluate(
            expectedText: $readingExercise->text,
            transcript: $request->validated('transcript'),
        );

        return response()->json([
            'success' => true,
            'message' => 'Lecture evaluee.',
            'data' => [
                'exercise' => $this->formatExercise($readingExercise),
                'result' => $result,
            ],
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function formatExercise(ReadingExercise $exercise): array
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
