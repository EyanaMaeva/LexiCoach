<?php

namespace App\Services\Ai;

use App\Models\SmartAbstractExercise;
use App\Models\WritingExercise;
use Illuminate\Support\Str;

class FakeAiProvider implements AiProvider
{
    /**
     * @return array<string, mixed>
     */
    public function evaluateWriting(WritingExercise $exercise, string $answer): array
    {
        $wordCount = str_word_count($answer);
        $score = $wordCount >= $exercise->min_words ? 82 : 58;

        return [
            'score' => $score,
            'status' => $this->statusFromScore($score),
            'corrected_text' => $answer,
            'mistakes' => $wordCount >= $exercise->min_words ? [] : [
                [
                    'type' => 'too_short',
                    'text' => null,
                    'explanation' => 'The answer is too short for this exercise.',
                ],
            ],
            'suggestions' => [
                'Add one clear example.',
                'Check punctuation before submitting.',
            ],
            'feedback' => [
                'title' => $score >= 75 ? 'Good work!' : 'Keep practicing.',
                'message' => $score >= 75
                    ? 'Your answer is understandable. Improve details and punctuation.'
                    : 'Write a longer answer and make one clear sentence for each idea.',
            ],
            'raw_ai_response' => [
                'provider' => 'fake',
                'note' => 'Deterministic local response used when no AI key is configured.',
            ],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function evaluateSmartAbstract(SmartAbstractExercise $exercise, string $summary): array
    {
        $wordCount = str_word_count($summary);
        $containsKeyword = Str::contains(
            Str::lower($summary),
            collect(explode(' ', Str::lower($exercise->source_text)))
                ->filter(fn (string $word): bool => mb_strlen($word) > 5)
                ->take(3)
                ->all(),
        );
        $score = $wordCount >= $exercise->min_words && $containsKeyword ? 84 : 62;

        return [
            'score' => $score,
            'status' => $this->statusFromScore($score),
            'improved_summary' => $summary,
            'missing_ideas' => $score >= 75 ? [] : [
                'Add the most important idea from the source text.',
            ],
            'strengths' => [
                'The summary is readable.',
            ],
            'feedback' => [
                'title' => $score >= 75 ? 'Good summary!' : 'Try again.',
                'message' => $score >= 75
                    ? 'The summary keeps the main idea. Make it even more precise.'
                    : 'The summary needs more key information from the text.',
            ],
            'raw_ai_response' => [
                'provider' => 'fake',
                'note' => 'Deterministic local response used when no AI key is configured.',
            ],
        ];
    }

    private function statusFromScore(int $score): string
    {
        if ($score >= 90) {
            return 'excellent';
        }

        if ($score >= 75) {
            return 'good';
        }

        return 'needs_practice';
    }
}
