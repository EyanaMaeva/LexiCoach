import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'services/learner_api_service.dart';

class ProgressChartPage extends StatefulWidget {
  const ProgressChartPage({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<ProgressChartPage> createState() => _ProgressChartPageState();
}

class _ProgressChartPageState extends State<ProgressChartPage> {
  final _apiService = LearnerApiService();
  late Future<Map<String, dynamic>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _apiService.getProgress();
  }

  void _reload() {
    setState(() {
      _progressFuture = _apiService.getProgress();
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
          'Progress',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progressFuture,
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

          final progress = snapshot.data ?? {};
          final entries = _progressEntries(progress);
          final totalAttempts = entries.fold<int>(
            0,
            (sum, entry) => sum + entry.totalAttempts,
          );
          final averageScore = entries.isEmpty
              ? 0
              : (entries.fold<int>(
                          0,
                          (sum, entry) => sum + entry.averageScore,
                        ) /
                        entries.length)
                    .round();
          final bestScore = entries.fold<int>(
            0,
            (best, entry) => entry.bestScore > best ? entry.bestScore : best,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
            children: [
              const Text(
                'Your learning chart',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scores are grouped by learning mode from the backend.',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Average',
                      value: '$averageScore%',
                      icon: Icons.equalizer_rounded,
                      color: AppColors.logoBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Attempts',
                      value: '$totalAttempts',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.logoTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Best',
                      value: '$bestScore%',
                      icon: Icons.emoji_events_rounded,
                      color: AppColors.logoOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ProgressBarChart(entries: entries),
              const SizedBox(height: 20),
              ...entries.map((entry) => _ModeProgressTile(entry: entry)),
            ],
          );
        },
      ),
    );
  }

  List<_ProgressEntry> _progressEntries(Map<String, dynamic> progress) {
    return progress.entries.map((mapEntry) {
      final value = mapEntry.value as Map<String, dynamic>? ?? {};
      final mode = value['learning_mode'] as Map<String, dynamic>? ?? {};
      final summary = value['summary'] as Map<String, dynamic>? ?? {};

      return _ProgressEntry(
        slug: mapEntry.key,
        name: mode['name']?.toString() ?? _labelFromSlug(mapEntry.key),
        averageScore: _intFrom(summary['average_score']),
        bestScore: _intFrom(summary['best_score']),
        totalAttempts: _intFrom(summary['total_attempts']),
        completedExercises: _intFrom(summary['completed_exercises']),
        latestAttempt: summary['latest_attempt'] as Map<String, dynamic>?,
      );
    }).toList();
  }

  String _labelFromSlug(String slug) {
    return slug
        .split('-')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _ProgressEntry {
  const _ProgressEntry({
    required this.slug,
    required this.name,
    required this.averageScore,
    required this.bestScore,
    required this.totalAttempts,
    required this.completedExercises,
    required this.latestAttempt,
  });

  final String slug;
  final String name;
  final int averageScore;
  final int bestScore;
  final int totalAttempts;
  final int completedExercises;
  final Map<String, dynamic>? latestAttempt;
}

class _ProgressBarChart extends StatelessWidget {
  const _ProgressBarChart({required this.entries});

  final List<_ProgressEntry> entries;

  @override
  Widget build(BuildContext context) {
    final visibleEntries = entries.isEmpty
        ? [
            const _ProgressEntry(
              slug: 'empty',
              name: 'No data',
              averageScore: 0,
              bestScore: 0,
              totalAttempts: 0,
              completedExercises: 0,
              latestAttempt: null,
            ),
          ]
        : entries;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Average score by mode',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 190,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: visibleEntries.map((entry) {
                final color = _colorFor(entry.slug);
                final barHeight =
                    24 + (entry.averageScore.clamp(0, 100) * 1.15);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.averageScore}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: barHeight.toDouble(),
                          width: 34,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _shortLabel(entry.name),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(String slug) {
    switch (slug) {
      case 'reading':
        return AppColors.logoBlue;
      case 'writing':
        return AppColors.logoPurple;
      case 'smart-abstract':
        return AppColors.logoTeal;
      default:
        return AppColors.logoOrange;
    }
  }

  String _shortLabel(String name) {
    if (name.toLowerCase().contains('abstract')) return 'Smart';
    if (name.toLowerCase().contains('writing')) return 'Write';
    if (name.toLowerCase().contains('reading')) return 'Read';
    return name;
  }
}

class _ModeProgressTile extends StatelessWidget {
  const _ModeProgressTile({required this.entry});

  final _ProgressEntry entry;

  @override
  Widget build(BuildContext context) {
    final latestExercise =
        entry.latestAttempt?['exercise'] as Map<String, dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights_rounded, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  latestExercise == null
                      ? 'No attempt yet'
                      : 'Last: ${latestExercise['title'] ?? 'Exercise'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.averageScore}%',
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${entry.totalAttempts} tries',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
              color: AppColors.primary.withValues(alpha: 0.65),
              size: 58,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load progress.',
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
