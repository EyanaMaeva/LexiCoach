<?php

namespace Database\Factories;

use App\Models\ReadingExercise;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ReadingExercise>
 */
class ReadingExerciseFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'title' => fake()->sentence(3),
            'text' => fake()->sentence(8),
            'language' => 'en-US',
            'level' => 'beginner',
            'sort_order' => fake()->numberBetween(1, 20),
            'is_active' => true,
        ];
    }
}
