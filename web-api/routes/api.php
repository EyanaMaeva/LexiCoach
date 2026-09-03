<?php

use App\Http\Controllers\Api\AdminDashboardController;
use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\ApiDocumentationController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\GlobalProgressController;
use App\Http\Controllers\Api\LearnerAssociationCodeController;
use App\Http\Controllers\Api\LearningModeController;
use App\Http\Controllers\Api\ReadingExerciseController;
use App\Http\Controllers\Api\ReadingProgressController;
use App\Http\Controllers\Api\TutorDashboardController;
use App\Http\Controllers\Api\TutorLearnerController;
use Illuminate\Support\Facades\Route;

Route::get('/docs', ApiDocumentationController::class);

Route::prefix('auth')->group(function (): void {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::middleware(['auth:sanctum', 'role:learner'])->group(function (): void {
    Route::get('/learning-modes', [LearningModeController::class, 'index']);
    Route::get('/learning-modes/{slug}', [LearningModeController::class, 'show']);
    Route::get('/learning-modes/{slug}/exercises', [LearningModeController::class, 'readingExercises']);
    Route::get('/reading-exercises', [ReadingExerciseController::class, 'index']);
    Route::get('/reading-exercises/{readingExercise}', [ReadingExerciseController::class, 'show']);
    Route::post('/reading-exercises/{readingExercise}/evaluate', [ReadingExerciseController::class, 'evaluate']);
    Route::get('/me/reading-attempts', [ReadingProgressController::class, 'attempts']);
    Route::get('/me/reading-progress', [ReadingProgressController::class, 'progress']);
    Route::get('/me/progress', GlobalProgressController::class);
    Route::get('/me/association-code', [LearnerAssociationCodeController::class, 'show']);
    Route::post('/me/association-code', [LearnerAssociationCodeController::class, 'store']);
    Route::post('/me/association-code/regenerate', [LearnerAssociationCodeController::class, 'regenerate']);
    Route::delete('/me/association-code', [LearnerAssociationCodeController::class, 'destroy']);
});

Route::middleware(['auth:sanctum', 'role:tutor'])->group(function (): void {
    Route::get('/tutor/dashboard', TutorDashboardController::class);
    Route::get('/tutor/learners', [TutorLearnerController::class, 'index']);
    Route::post('/tutor/learners/link', [TutorLearnerController::class, 'link']);
    Route::get('/tutor/learners/{learner}/progress', [TutorLearnerController::class, 'progress']);
    Route::get('/tutor/learners/{learner}/reading-attempts', [TutorLearnerController::class, 'readingAttempts']);
    Route::delete('/tutor/learners/{learner}', [TutorLearnerController::class, 'unlink']);
});

Route::middleware(['auth:sanctum', 'role:admin'])->group(function (): void {
    Route::get('/admin/dashboard', AdminDashboardController::class);
    Route::get('/admin/users', [AdminUserController::class, 'index']);
    Route::get('/admin/users/{user}', [AdminUserController::class, 'show']);
    Route::patch('/admin/users/{user}/role', [AdminUserController::class, 'updateRole']);
});
