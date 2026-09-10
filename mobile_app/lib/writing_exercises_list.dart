import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'services/writing_api_service.dart';
import 'writing_practice.dart';

class WritingExercisesList extends StatefulWidget {
  const WritingExercisesList({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<WritingExercisesList> createState() => _WritingExercisesListState();
}

class _WritingExercisesListState extends State<WritingExercisesList> {
  final _apiService = WritingApiService();
  late Future<List<dynamic>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _apiService.getExercises();
  }

  void _reload() {
    setState(() {
      _exercisesFuture = _apiService.getExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Writing Assistant',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }

          final exercises = snapshot.data ?? [];

          if (exercises.isEmpty) {
            return const Center(
              child: Text(
                'No writing exercises available yet.',
                style: TextStyle(color: AppColors.textLight),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            children: [
              const Text(
                'Choose a prompt',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Write your answer and let the assistant give you a score, corrections and suggestions.',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ...exercises.map(
                (exercise) => _WritingExerciseCard(exercise: exercise),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WritingExerciseCard extends StatelessWidget {
  const _WritingExerciseCard({required this.exercise});

  final dynamic exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoPurple.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            final id = exercise['id'];
            if (id == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WritingPractice(exerciseId: id as int),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.logoPurple.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.logoPurple,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['title'] ?? 'Untitled',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise['prompt'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _SmallPill(text: exercise['level'] ?? 'beginner'),
                          const SizedBox(width: 8),
                          _SmallPill(
                            text: '${exercise['min_words'] ?? 20}+ words',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textLight,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallPill extends StatelessWidget {
  const _SmallPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.logoBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text.toString().toUpperCase(),
        style: const TextStyle(
          color: AppColors.logoBlue,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppColors.logoPurple.withValues(alpha: 0.65),
              size: 58,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load writing exercises.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
