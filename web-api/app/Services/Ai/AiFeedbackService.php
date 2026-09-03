<?php

namespace App\Services\Ai;

use App\Models\SmartAbstractExercise;
use App\Models\WritingExercise;
use InvalidArgumentException;

class AiFeedbackService
{
    public function __construct(
        private readonly FakeAiProvider $fakeAiProvider,
        private readonly GeminiAiProvider $geminiAiProvider,
    ) {}

    /**
     * @return array<string, mixed>
     */
    public function evaluateWriting(WritingExercise $exercise, string $answer): array
    {
        return $this->normalizeWriting($this->provider()->evaluateWriting($exercise, $answer), $answer);
    }

    /**
     * @return array<string, mixed>
     */
    public function evaluateSmartAbstract(SmartAbstractExercise $exercise, string $summary): array
    {
        return $this->normalizeSmartAbstract($this->provider()->evaluateSmartAbstract($exercise, $summary), $summary);
    }

    private function provider(): AiProvider
    {
        return match (config('ai.provider')) {
            'fake' => $this->fakeAiProvider,
            'gemini' => $this->geminiAiProvider,
            default => throw new InvalidArgumentException('Unsupported AI provider.'),
        };
    }

    /**
     * @param  array<string, mixed>  $result
     * @return array<string, mixed>
     */
    private function normalizeWriting(array $result, string $answer): array
    {
        $score = $this->scoreFrom($result['score'] ?? 0);

        return [
            'score' => $score,
            'status' => $this->statusFrom($result['status'] ?? null, $score),
            'answer' => $answer,
            'corrected_text' => $this->stringFrom($result['corrected_text'] ?? $answer, $answer),
            'mistakes' => $this->arrayFrom($result['mistakes'] ?? []),
            'suggestions' => $this->arrayFrom($result['suggestions'] ?? []),
            'feedback' => $this->feedbackFrom($result['feedback'] ?? null, $score),
            'raw_ai_response' => $result['raw_ai_response'] ?? $result,
        ];
    }

    /**
     * @param  array<string, mixed>  $result
     * @return array<string, mixed>
     */
    private function normalizeSmartAbstract(array $result, string $summary): array
    {
        $score = $this->scoreFrom($result['score'] ?? 0);

        return [
            'score' => $score,
            'status' => $this->statusFrom($result['status'] ?? null, $score),
            'summary' => $summary,
            'improved_summary' => $this->stringFrom($result['improved_summary'] ?? $summary, $summary),
            'missing_ideas' => $this->arrayFrom($result['missing_ideas'] ?? []),
            'strengths' => $this->arrayFrom($result['strengths'] ?? []),
            'feedback' => $this->feedbackFrom($result['feedback'] ?? null, $score),
            'raw_ai_response' => $result['raw_ai_response'] ?? $result,
        ];
    }

    private function scoreFrom(mixed $score): int
    {
        if (! is_numeric($score)) {
            return 0;
        }

        return max(0, min(100, (int) round((float) $score)));
    }

    private function statusFrom(mixed $status, int $score): string
    {
        if (is_string($status) && in_array($status, ['excellent', 'good', 'needs_practice'], true)) {
            return $status;
        }

        if ($score >= 90) {
            return 'excellent';
        }

        if ($score >= 75) {
            return 'good';
        }

        return 'needs_practice';
    }

    private function stringFrom(mixed $value, string $fallback): string
    {
        return is_string($value) && trim($value) !== '' ? $value : $fallback;
    }

    /**
     * @return array<int|string, mixed>
     */
    private function arrayFrom(mixed $value): array
    {
        return is_array($value) ? $value : [];
    }

    /**
     * @return array<string, string>
     */
    private function feedbackFrom(mixed $feedback, int $score): array
    {
        if (
            is_array($feedback)
            && isset($feedback['title'], $feedback['message'])
            && is_string($feedback['title'])
            && is_string($feedback['message'])
        ) {
            return [
                'title' => $feedback['title'],
                'message' => $feedback['message'],
            ];
        }

        return [
            'title' => $score >= 75 ? 'Good work!' : 'Keep practicing.',
            'message' => $score >= 75
                ? 'Your answer is understandable. Improve details and punctuation.'
                : 'Try again with more detail and clearer sentences.',
        ];
    }
}
