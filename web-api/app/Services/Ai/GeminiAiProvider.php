<?php

namespace App\Services\Ai;

use App\Models\SmartAbstractExercise;
use App\Models\WritingExercise;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class GeminiAiProvider implements AiProvider
{
    /**
     * @return array<string, mixed>
     */
    public function evaluateWriting(WritingExercise $exercise, string $answer): array
    {
        $prompt = <<<PROMPT
You are LexiCoach, an educational writing assistant for a dyslexic learner.
Evaluate the learner answer with kindness and clear language.

Exercise title: {$exercise->title}
Language: {$exercise->language}
Level: {$exercise->level}
Prompt: {$exercise->prompt}
Instructions: {$exercise->instructions}
Minimum words: {$exercise->min_words}

Learner answer:
{$answer}

Return only the JSON object requested by the schema.
PROMPT;

        return $this->generateJson($prompt, $this->writingSchema());
    }

    /**
     * @return array<string, mixed>
     */
    public function evaluateSmartAbstract(SmartAbstractExercise $exercise, string $summary): array
    {
        $prompt = <<<PROMPT
You are LexiCoach, an educational smart summary assistant for a dyslexic learner.
Evaluate whether the learner summary keeps the important ideas from the source text.

Exercise title: {$exercise->title}
Language: {$exercise->language}
Level: {$exercise->level}
Instructions: {$exercise->instructions}
Minimum words: {$exercise->min_words}
Maximum words: {$exercise->max_words}

Source text:
{$exercise->source_text}

Learner summary:
{$summary}

Return only the JSON object requested by the schema.
PROMPT;

        return $this->generateJson($prompt, $this->smartAbstractSchema());
    }

    /**
     * @param  array<string, mixed>  $schema
     * @return array<string, mixed>
     */
    private function generateJson(string $prompt, array $schema): array
    {
        $apiKey = config('ai.gemini.api_key');

        if (! is_string($apiKey) || $apiKey === '') {
            throw new RuntimeException('GEMINI_API_KEY is missing.');
        }

        $baseUrl = rtrim((string) config('ai.gemini.base_url'), '/');
        $model = (string) config('ai.gemini.model');
        $timeout = (int) config('ai.gemini.timeout');

        try {
            $response = Http::timeout($timeout)
                ->acceptJson()
                ->withHeaders(['x-goog-api-key' => $apiKey])
                ->post("{$baseUrl}/models/{$model}:generateContent", [
                    'contents' => [
                        [
                            'parts' => [
                                ['text' => $prompt],
                            ],
                        ],
                    ],
                    'generationConfig' => [
                        'temperature' => 0.2,
                        'responseMimeType' => 'application/json',
                        'responseSchema' => $schema,
                    ],
                ]);
        } catch (ConnectionException $exception) {
            throw new RuntimeException('Gemini is unreachable: '.$exception->getMessage(), previous: $exception);
        }

        if ($response->failed()) {
            throw new RuntimeException('Gemini request failed: '.$response->body());
        }

        $text = data_get($response->json(), 'candidates.0.content.parts.0.text');

        if (! is_string($text) || trim($text) === '') {
            throw new RuntimeException('Gemini returned an empty response.');
        }

        $json = json_decode($text, true);

        if (! is_array($json)) {
            throw new RuntimeException('Gemini returned invalid JSON.');
        }

        return $json;
    }

    /**
     * @return array<string, mixed>
     */
    private function writingSchema(): array
    {
        return [
            'type' => 'OBJECT',
            'properties' => [
                'score' => ['type' => 'INTEGER'],
                'status' => ['type' => 'STRING'],
                'corrected_text' => ['type' => 'STRING'],
                'mistakes' => [
                    'type' => 'ARRAY',
                    'items' => [
                        'type' => 'OBJECT',
                        'properties' => [
                            'type' => ['type' => 'STRING'],
                            'text' => ['type' => 'STRING'],
                            'explanation' => ['type' => 'STRING'],
                        ],
                    ],
                ],
                'suggestions' => [
                    'type' => 'ARRAY',
                    'items' => ['type' => 'STRING'],
                ],
                'feedback' => [
                    'type' => 'OBJECT',
                    'properties' => [
                        'title' => ['type' => 'STRING'],
                        'message' => ['type' => 'STRING'],
                    ],
                ],
            ],
            'required' => ['score', 'status', 'corrected_text', 'mistakes', 'suggestions', 'feedback'],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function smartAbstractSchema(): array
    {
        return [
            'type' => 'OBJECT',
            'properties' => [
                'score' => ['type' => 'INTEGER'],
                'status' => ['type' => 'STRING'],
                'improved_summary' => ['type' => 'STRING'],
                'missing_ideas' => [
                    'type' => 'ARRAY',
                    'items' => ['type' => 'STRING'],
                ],
                'strengths' => [
                    'type' => 'ARRAY',
                    'items' => ['type' => 'STRING'],
                ],
                'feedback' => [
                    'type' => 'OBJECT',
                    'properties' => [
                        'title' => ['type' => 'STRING'],
                        'message' => ['type' => 'STRING'],
                    ],
                ],
            ],
            'required' => ['score', 'status', 'improved_summary', 'missing_ideas', 'strengths', 'feedback'],
        ];
    }
}
