<?php

namespace Database\Seeders;

use App\Models\ReadingExercise;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);

        ReadingExercise::query()->create([
            'title' => 'Museum visit',
            'text' => 'The children visited the beautiful museum yesterday.',
            'language' => 'en-US',
            'level' => 'beginner',
            'sort_order' => 1,
        ]);

        ReadingExercise::query()->create([
            'title' => 'Garden story',
            'text' => 'The little boy is playing in the garden.',
            'language' => 'en-US',
            'level' => 'beginner',
            'sort_order' => 2,
        ]);
    }
}
