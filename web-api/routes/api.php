<?php

use App\Http\Controllers\Api\ApiDocumentationController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ReadingExerciseController;
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

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/reading-exercises', [ReadingExerciseController::class, 'index']);
    Route::get('/reading-exercises/{readingExercise}', [ReadingExerciseController::class, 'show']);
    Route::post('/reading-exercises/{readingExercise}/evaluate', [ReadingExerciseController::class, 'evaluate']);
});
