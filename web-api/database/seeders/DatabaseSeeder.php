<?php

namespace Database\Seeders;

use App\Models\LearningMode;
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
            'name' => 'Marie Learner',
            'email' => 'learner@example.com',
            'password' => 'password123',
            'role' => User::ROLE_LEARNER,
        ]);

        User::factory()->tutor()->create([
            'name' => 'Paul Tutor',
            'email' => 'tutor@example.com',
            'password' => 'password123',
        ]);

        User::factory()->admin()->create([
            'name' => 'Admin LexiCoach',
            'email' => 'admin@example.com',
            'password' => 'password123',
        ]);

        $readingMode = LearningMode::query()->create([
            'name' => 'Reading Practice',
            'slug' => LearningMode::SLUG_READING,
            'description' => 'Read a sentence aloud, compare your transcript and improve fluency.',
            'sort_order' => 1,
        ]);

        LearningMode::query()->create([
            'name' => 'Writing Assistant',
            'slug' => LearningMode::SLUG_WRITING,
            'description' => 'Write a text and receive spelling, grammar and clarity feedback.',
            'sort_order' => 2,
        ]);

        LearningMode::query()->create([
            'name' => 'Vocal Dictation',
            'slug' => LearningMode::SLUG_DICTATION,
            'description' => 'Listen to a sentence, repeat it and check the transcript.',
            'sort_order' => 3,
        ]);

        LearningMode::query()->create([
            'name' => 'Word Splitting',
            'slug' => LearningMode::SLUG_WORD_SPLITTING,
            'description' => 'Split difficult words into smaller readable parts.',
            'sort_order' => 4,
        ]);

        LearningMode::query()->create([
            'name' => 'Smart Abstract',
            'slug' => LearningMode::SLUG_SMART_ABSTRACT,
            'description' => 'Summarize long text into simpler ideas.',
            'sort_order' => 5,
        ]);

        ReadingExercise::query()->create([
            'learning_mode_id' => $readingMode->id,
            'title' => 'Museum visit',
            'text' => 'The children visited the beautiful museum yesterday.',
            'language' => 'en-US',
            'level' => 'beginner',
            'sort_order' => 1,
        ]);

        ReadingExercise::query()->create([
            'learning_mode_id' => $readingMode->id,
            'title' => 'Garden story',
            'text' => 'The little boy is playing in the garden.',
            'language' => 'en-US',
            'level' => 'beginner',
            'sort_order' => 2,
        ]);
    }
}
