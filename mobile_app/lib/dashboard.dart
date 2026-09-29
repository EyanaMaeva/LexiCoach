import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'app_colors.dart';
import 'ai_conversation_page.dart';
import 'learning_modes_page.dart';
import 'notifications_page.dart';
import 'progress_chart_page.dart';
import 'reading_exercises_list.dart';
import 'services/learner_api_service.dart';
import 'smart_abstract_exercises_list.dart';
import 'writing_exercises_list.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({
    super.key,
    this.userName = 'User',
    this.onOpenLearningModes,
    this.onOpenReading,
    this.onOpenProgress,
  });

  final String userName;
  final VoidCallback? onOpenLearningModes;
  final VoidCallback? onOpenReading;
  final VoidCallback? onOpenProgress;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _apiService = LearnerApiService();
  late Future<Map<String, dynamic>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _apiService.getProgress();
  }

  Future<void> _reloadProgress() async {
    final progressFuture = _apiService.getProgress();

    setState(() {
      _progressFuture = progressFuture;
    });

    try {
      await progressFuture;
    } catch (_) {}
  }

  void _openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 122),
        child: _RobotCoachButton(
          onTap: () => _openPage(const AiConversationPage()),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _reloadProgress,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 88),
            children: [
              _Header(
                userName: widget.userName,
                onOpenNotifications: () => _openPage(const NotificationsPage()),
              ),
              const SizedBox(height: 26),
              FutureBuilder<Map<String, dynamic>>(
                future: _progressFuture,
                builder: (context, snapshot) {
                  final progress = snapshot.data ?? {};
                  final entries = _entriesFrom(progress);
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;

                  if (snapshot.hasError) {
                    return _ProgressErrorCard(
                      message: snapshot.error.toString(),
                      onRetry: _reloadProgress,
                    );
                  }

                  return Column(
                    children: [
                      _TodayCard(
                        isLoading: isLoading,
                        averageScore: _averageScore(entries),
                        totalAttempts: _totalAttempts(entries),
                        onStart:
                            widget.onOpenLearningModes ??
                            () => _openPage(const LearningModesPage()),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Learning modules',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed:
                        widget.onOpenLearningModes ??
                        () => _openPage(const LearningModesPage()),
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.12,
                children: [
                  _ModuleCard(
                    title: 'Reading',
                    subtitle: 'Read aloud',
                    icon: Icons.menu_book_rounded,
                    color: AppColors.logoBlue,
                    onTap:
                        widget.onOpenReading ??
                        () => _openPage(const ReadingExercisesList()),
                  ),
                  _ModuleCard(
                    title: 'Writing',
                    subtitle: 'Improve text',
                    icon: Icons.edit_note_rounded,
                    color: AppColors.logoPurple,
                    onTap: () => _openPage(const WritingExercisesList()),
                  ),
                  _ModuleCard(
                    title: 'Smart Abstract',
                    subtitle: 'Summarize',
                    icon: Icons.summarize_rounded,
                    color: AppColors.logoTeal,
                    onTap: () => _openPage(const SmartAbstractExercisesList()),
                  ),
                  _ModuleCard(
                    title: 'Progress',
                    subtitle: 'Bar chart',
                    icon: Icons.bar_chart_rounded,
                    color: AppColors.logoOrange,
                    onTap:
                        widget.onOpenProgress ??
                        () => _openPage(const ProgressChartPage()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ProgressEntry> _entriesFrom(Map<String, dynamic> progress) {
    return progress.entries.map((entry) {
      final value = entry.value as Map<String, dynamic>? ?? {};
      final mode = value['learning_mode'] as Map<String, dynamic>? ?? {};
      final summary = value['summary'] as Map<String, dynamic>? ?? {};

      return _ProgressEntry(
        name: mode['name']?.toString() ?? entry.key,
        averageScore: _intFrom(summary['average_score']),
        totalAttempts: _intFrom(summary['total_attempts']),
      );
    }).toList();
  }

  int _averageScore(List<_ProgressEntry> entries) {
    if (entries.isEmpty) return 0;

    return (entries.fold<int>(0, (sum, entry) => sum + entry.averageScore) /
            entries.length)
        .round();
  }

  int _totalAttempts(List<_ProgressEntry> entries) {
    return entries.fold<int>(0, (sum, entry) => sum + entry.totalAttempts);
  }

  int _intFrom(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _RobotCoachButton extends StatelessWidget {
  const _RobotCoachButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'AI Conversation',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 86,
          width: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.18),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Lottie.asset(
              'assets/lotties/RobotSaludando.json',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressEntry {
  const _ProgressEntry({
    required this.name,
    required this.averageScore,
    required this.totalAttempts,
  });

  final String name;
  final int averageScore;
  final int totalAttempts;
}

class _Header extends StatelessWidget {
  const _Header({required this.userName, required this.onOpenNotifications});

  final String userName;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Hello, $userName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Lottie.asset(
                    'assets/lotties/hand wave.json',
                    width: 36,
                    height: 36,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a module and keep practicing.',
                style: TextStyle(fontSize: 15, color: AppColors.textLight),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onOpenNotifications,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textFieldBorder),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.isLoading,
    required this.averageScore,
    required this.totalAttempts,
    required this.onStart,
  });

  final bool isLoading;
  final int averageScore;
  final int totalAttempts;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF9FA8DA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Continue Learning',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Reading Practice',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    isLoading
                                        ? 'Loading progress...'
                                        : '$totalAttempts attempts saved',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isLoading ? '...' : '$averageScore%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 85,
                            width: 85,
                            child: CircularProgressIndicator(
                              value: isLoading ? null : averageScore / 100,
                              strokeWidth: 10,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.20,
                              ),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'assets/images/landing_img.jpeg',
                              height: 65,
                              width: 65,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: isLoading ? null : averageScore / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Start Learning',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.textFieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressErrorCard extends StatelessWidget {
  const _ProgressErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppColors.logoOrange),
          const SizedBox(height: 10),
          const Text(
            'Progress unavailable',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
