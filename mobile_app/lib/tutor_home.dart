import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'landing.dart';
import 'profile_settings_page.dart';
import 'services/auth_module.dart';
import 'services/tutor_api_service.dart';

class TutorHome extends StatefulWidget {
  const TutorHome({super.key, this.userName = 'Tutor'});

  final String userName;

  @override
  State<TutorHome> createState() => _TutorHomeState();
}

class _TutorHomeState extends State<TutorHome> {
  final _authApi = AuthApiService();
  final _tutorApi = TutorApiService();
  final _codeController = TextEditingController();

  late Future<_TutorDashboardData> _dashboardFuture;

  int _currentIndex = 0;
  bool _isLoggingOut = false;
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<_TutorDashboardData> _loadDashboard() async {
    final results = await Future.wait([
      _tutorApi.getDashboard(),
      _tutorApi.getLearners(),
    ]);

    return _TutorDashboardData(
      dashboard: results[0] as Map<String, dynamic>,
      learners: results[1] as List<dynamic>,
    );
  }

  Future<void> _refreshDashboard() async {
    final nextFuture = _loadDashboard();

    setState(() {
      _dashboardFuture = nextFuture;
    });

    await nextFuture;
  }

  Future<void> _linkLearner() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty || _isLinking) return;

    setState(() => _isLinking = true);

    try {
      await _tutorApi.linkLearner(code);
      _codeController.clear();

      if (!mounted) return;

      _showSnackBar('Learner linked successfully.');
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(_friendlyError(error));
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  Future<void> _unlinkLearner(Map<String, dynamic> learner) async {
    final learnerId = _asInt(learner['id']);
    final name = _asString(learner['full_name'], fallback: 'ce learner');

    if (learnerId == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ConfirmUnlinkSheet(learnerName: name);
      },
    );

    if (confirmed != true) return;

    try {
      await _tutorApi.unlinkLearner(learnerId);

      if (!mounted) return;

      _showSnackBar('Learner detached.');
      await _refreshDashboard();
    } catch (error) {
      if (!mounted) return;

      _showSnackBar(_friendlyError(error));
    }
  }

  void _showLearnerProgress(Map<String, dynamic> learner) {
    final learnerId = _asInt(learner['id']);
    final learnerName = _asString(learner['full_name'], fallback: 'Learner');

    if (learnerId == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _LearnerProgressSheet(
          learnerId: learnerId,
          learnerName: learnerName,
          tutorApi: _tutorApi,
          progressFuture: _tutorApi.getLearnerProgress(learnerId),
        );
      },
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() => _isLoggingOut = true);

    try {
      await _authApi.logout();
    } catch (_) {
      await _authApi.clearSession();
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LandingPage()),
      (route) => false,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
    );

    if (!mounted) return;
    await _refreshDashboard();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();

    if (message.isEmpty) {
      return 'Une erreur est survenue.';
    }

    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: SafeArea(
        child: FutureBuilder<_TutorDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return _TutorErrorState(
                message: _friendlyError(snapshot.error!),
                onRetry: () {
                  setState(() {
                    _dashboardFuture = _loadDashboard();
                  });
                },
                onLogout: _isLoggingOut ? null : _logout,
              );
            }

            final data = snapshot.data!;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refreshDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 118),
                children: _pageChildren(data),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _TutorBottomNav(
        currentIndex: _currentIndex,
        onChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  List<Widget> _pageChildren(_TutorDashboardData data) {
    final header = _Header(userName: widget.userName);

    if (_currentIndex == 1) {
      return [
        header,
        const SizedBox(height: 20),
        _TutorEvolutionCard(
          dashboard: data.dashboard,
          isLoading: false,
          onOpenProgress: () {},
        ),
        const SizedBox(height: 16),
        _TutorProgressChartSection(
          progress: _asMap(data.dashboard['progress_by_mode']),
        ),
        const SizedBox(height: 16),
        _AttentionSection(dashboard: data.dashboard),
      ];
    }

    if (_currentIndex == 2) {
      return [
        header,
        const SizedBox(height: 20),
        _LinkLearnerCard(
          controller: _codeController,
          isLoading: _isLinking,
          onSubmit: _linkLearner,
        ),
        const SizedBox(height: 16),
        _LearnersSection(
          learners: data.learners,
          onViewProgress: _showLearnerProgress,
          onUnlink: _unlinkLearner,
        ),
      ];
    }

    if (_currentIndex == 3) {
      return [
        header,
        const SizedBox(height: 20),
        _LearnersSection(
          learners: data.learners,
          onViewProgress: _showLearnerProgress,
          onUnlink: _unlinkLearner,
        ),
      ];
    }

    if (_currentIndex == 4) {
      return [
        _TutorProfileSection(
          userName: widget.userName,
          dashboard: data.dashboard,
          isLoggingOut: _isLoggingOut,
          onOpenSettings: _openSettings,
          onLogout: _logout,
        ),
      ];
    }

    return [
      header,
      const SizedBox(height: 20),
      _TutorEvolutionCard(
        dashboard: data.dashboard,
        isLoading: false,
        onOpenProgress: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      const SizedBox(height: 16),
      _SummarySection(dashboard: data.dashboard),
      const SizedBox(height: 16),
      _LatestAttemptsSection(dashboard: data.dashboard),
    ];
  }
}

class _TutorDashboardData {
  const _TutorDashboardData({required this.dashboard, required this.learners});

  final Map<String, dynamic> dashboard;
  final List<dynamic> learners;
}

class _Header extends StatelessWidget {
  const _Header({required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
            child: const Icon(
              Icons.supervisor_account_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Learner monitoring',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorProfileSection extends StatelessWidget {
  const _TutorProfileSection({
    required this.userName,
    required this.dashboard,
    required this.isLoggingOut,
    required this.onOpenSettings,
    required this.onLogout,
  });

  final String userName;
  final Map<String, dynamic> dashboard;
  final bool isLoggingOut;
  final VoidCallback onOpenSettings;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final reading = _asMap(dashboard['reading']);
    final learners = _asInt(dashboard['total_learners']) ?? 0;
    final activeLearners = _asInt(dashboard['active_learners']) ?? 0;
    final attempts = _asInt(reading['total_attempts']) ?? 0;

    return Column(
      children: [
        const SizedBox(height: 20),
        Center(
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.11),
                  child: const Icon(
                    Icons.supervisor_account_rounded,
                    color: AppColors.primary,
                    size: 54,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const Text(
          'Tutor account',
          style: TextStyle(fontSize: 14, color: AppColors.textLight),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TutorProfileStat(label: 'Learners', value: '$learners'),
            _TutorProfileStat(label: 'Active', value: '$activeLearners'),
            _TutorProfileStat(label: 'Attempts', value: '$attempts'),
          ],
        ),
        const SizedBox(height: 32),
        _TutorProfileMenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: onOpenSettings,
        ),
        _TutorProfileMenuItem(
          icon: Icons.person_outline,
          title: 'Personal Info',
          onTap: onOpenSettings,
        ),
        _TutorProfileMenuItem(
          icon: Icons.notifications_none,
          title: 'Notifications',
          onTap: onOpenSettings,
        ),
        _TutorProfileMenuItem(
          icon: Icons.lock_outline,
          title: 'Security',
          onTap: onOpenSettings,
        ),
        _TutorProfileMenuItem(icon: Icons.help_outline, title: 'Help Center'),
        const SizedBox(height: 20),
        _TutorProfileMenuItem(
          icon: Icons.logout,
          title: isLoggingOut ? 'Logging out...' : 'Log Out',
          isDestructive: true,
          onTap: isLoggingOut ? null : onLogout,
        ),
      ],
    );
  }
}

class _TutorProfileStat extends StatelessWidget {
  const _TutorProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
        ),
      ],
    );
  }
}

class _TutorProfileMenuItem extends StatelessWidget {
  const _TutorProfileMenuItem({
    required this.icon,
    required this.title,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          leading: Icon(
            icon,
            color: isDestructive ? Colors.red : AppColors.primary,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDestructive ? Colors.red : AppColors.textDark,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _TutorEvolutionCard extends StatelessWidget {
  const _TutorEvolutionCard({
    required this.dashboard,
    required this.isLoading,
    required this.onOpenProgress,
  });

  final Map<String, dynamic> dashboard;
  final bool isLoading;
  final VoidCallback onOpenProgress;

  @override
  Widget build(BuildContext context) {
    final reading = _asMap(dashboard['reading']);
    final totalLearners = _asInt(dashboard['total_learners']) ?? 0;
    final activeLearners = _asInt(dashboard['active_learners']) ?? 0;
    final averageScore = _asInt(reading['average_score']) ?? 0;
    final totalAttempts = _asInt(reading['total_attempts']) ?? 0;

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
                              'Learner evolution',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Reading Progress',
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
                                        : '$totalLearners learners, $activeLearners active',
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
                          Container(
                            height: 65,
                            width: 65,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.supervisor_account_rounded,
                              color: Colors.white,
                              size: 34,
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
                      onPressed: onOpenProgress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        '$totalAttempts attempts saved',
                        style: const TextStyle(
                          fontSize: 16,
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

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.dashboard});

  final Map<String, dynamic> dashboard;

  @override
  Widget build(BuildContext context) {
    final reading = _asMap(dashboard['reading']);
    final totalLearners = _asInt(dashboard['total_learners']) ?? 0;
    final activeLearners = _asInt(dashboard['active_learners']) ?? 0;
    final averageScore = _asInt(reading['average_score']) ?? 0;
    final totalAttempts = _asInt(reading['total_attempts']) ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.groups_rounded,
                title: 'Learners',
                value: '$totalLearners',
                caption: '$activeLearners actifs',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.auto_graph_rounded,
                title: 'Average',
                value: '$averageScore%',
                caption: 'reading',
                color: AppColors.logoTeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WideMetricCard(
          icon: Icons.history_edu_rounded,
          title: 'Reading attempts',
          value: '$totalAttempts',
          caption: 'Latest reading exercises completed by linked learners.',
        ),
      ],
    );
  }
}

class _TutorProgressEntry {
  const _TutorProgressEntry({
    required this.slug,
    required this.name,
    required this.averageScore,
    required this.bestScore,
    required this.totalAttempts,
    required this.latestAttempt,
  });

  final String slug;
  final String name;
  final int averageScore;
  final int bestScore;
  final int totalAttempts;
  final Map<String, dynamic>? latestAttempt;
}

class _TutorProgressChartSection extends StatelessWidget {
  const _TutorProgressChartSection({
    required this.progress,
    this.showHeader = true,
  });

  final Map<String, dynamic> progress;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final entries = _entriesFrom(progress);
    final totalAttempts = entries.fold<int>(
      0,
      (sum, entry) => sum + entry.totalAttempts,
    );
    final averageScore = entries.isEmpty
        ? 0
        : (entries.fold<int>(0, (sum, entry) => sum + entry.averageScore) /
                  entries.length)
              .round();
    final bestScore = entries.fold<int>(
      0,
      (best, entry) => entry.bestScore > best ? entry.bestScore : best,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          const Text(
            'Learners progress chart',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scores grouped by learning mode from the backend.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
        ],
        _TutorProgressStatsRow(
          averageScore: averageScore,
          totalAttempts: totalAttempts,
          bestScore: bestScore,
        ),
        const SizedBox(height: 20),
        _TutorProgressBarChart(entries: entries),
        const SizedBox(height: 20),
        ...entries.map((entry) => _TutorModeProgressTile(entry: entry)),
      ],
    );
  }

  List<_TutorProgressEntry> _entriesFrom(Map<String, dynamic> progress) {
    return progress.entries.map((entry) {
      final item = _asMap(entry.value);
      final mode = _asMap(item['learning_mode']);
      final summary = _asMap(item['summary']);
      final latestAttempts = _asList(summary['latest_attempts']);

      return _TutorProgressEntry(
        slug: entry.key,
        name: _asString(mode['name'], fallback: _labelFromSlug(entry.key)),
        averageScore: _asInt(summary['average_score']) ?? 0,
        bestScore: _asInt(summary['best_score']) ?? 0,
        totalAttempts: _asInt(summary['total_attempts']) ?? 0,
        latestAttempt: latestAttempts.isEmpty
            ? null
            : _asMap(_asMap(latestAttempts.first)['attempt']),
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
}

class _TutorProgressStatsRow extends StatelessWidget {
  const _TutorProgressStatsRow({
    required this.averageScore,
    required this.totalAttempts,
    required this.bestScore,
  });

  final int averageScore;
  final int totalAttempts;
  final int bestScore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TutorStatCard(
            label: 'Average',
            value: '$averageScore%',
            icon: Icons.equalizer_rounded,
            color: AppColors.logoBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TutorStatCard(
            label: 'Attempts',
            value: '$totalAttempts',
            icon: Icons.task_alt_rounded,
            color: AppColors.logoTeal,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TutorStatCard(
            label: 'Best',
            value: '$bestScore%',
            icon: Icons.emoji_events_rounded,
            color: AppColors.logoOrange,
          ),
        ),
      ],
    );
  }
}

class _TutorProgressBarChart extends StatelessWidget {
  const _TutorProgressBarChart({required this.entries});

  final List<_TutorProgressEntry> entries;

  @override
  Widget build(BuildContext context) {
    final visibleEntries = entries.isEmpty
        ? [
            const _TutorProgressEntry(
              slug: 'empty',
              name: 'No data',
              averageScore: 0,
              bestScore: 0,
              totalAttempts: 0,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.logoNavy.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
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

class _TutorModeProgressTile extends StatelessWidget {
  const _TutorModeProgressTile({required this.entry});

  final _TutorProgressEntry entry;

  @override
  Widget build(BuildContext context) {
    final latestExercise = _asMap(entry.latestAttempt?['exercise']);
    final latestTitle = _asString(
      latestExercise['title'],
      fallback: 'No attempt yet',
    );

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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  latestTitle == 'No attempt yet'
                      ? latestTitle
                      : 'Last: $latestTitle',
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

class _TutorStatCard extends StatelessWidget {
  const _TutorStatCard({
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
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 10),
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

class _LinkLearnerCard extends StatelessWidget {
  const _LinkLearnerCard({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.link_rounded,
            title: 'Associer un learner',
            subtitle: 'Entre le code genere dans son application.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'LC-123456',
                    filled: true,
                    fillColor: AppColors.textFieldFill,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.textFieldBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.textFieldBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                width: 58,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.35,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttentionSection extends StatelessWidget {
  const _AttentionSection({required this.dashboard});

  final Map<String, dynamic> dashboard;

  @override
  Widget build(BuildContext context) {
    final reading = _asMap(dashboard['reading']);
    final learners = _asList(reading['learners_needing_attention']);

    if (learners.isEmpty) {
      return const _EmptyCard(
        icon: Icons.verified_rounded,
        title: 'Tout va bien',
        message: 'No learner needs special attention.',
      );
    }

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.priority_high_rounded,
            title: 'A surveiller',
            subtitle: 'Learners with no attempts or a low average score.',
          ),
          const SizedBox(height: 14),
          ...learners.map((item) {
            final learner = _asMap(_asMap(item)['learner']);
            final reason = _asString(_asMap(item)['reason']);
            final summary = _asMap(_asMap(item)['summary']);
            final average = _asInt(summary['average_score']) ?? 0;

            return _CompactLearnerTile(
              name: _asString(learner['full_name'], fallback: 'Learner'),
              subtitle: reason == 'no_attempts'
                  ? 'No attempts yet'
                  : 'Average reading: $average%',
              icon: Icons.person_search_rounded,
              color: AppColors.accent,
            );
          }),
        ],
      ),
    );
  }
}

class _LatestAttemptsSection extends StatelessWidget {
  const _LatestAttemptsSection({required this.dashboard});

  final Map<String, dynamic> dashboard;

  @override
  Widget build(BuildContext context) {
    final reading = _asMap(dashboard['reading']);
    final attempts = _asList(reading['latest_attempts']);

    if (attempts.isEmpty) {
      return const _EmptyCard(
        icon: Icons.history_rounded,
        title: 'No attempts yet',
        message: 'Les dernieres activites apparaitront ici.',
      );
    }

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.schedule_rounded,
            title: 'Latest attempts',
            subtitle: 'Activite reading recente.',
          ),
          const SizedBox(height: 14),
          ...attempts.map((item) {
            final data = _asMap(item);
            final learner = _asMap(data['learner']);
            final attempt = _asMap(data['attempt']);
            final exercise = _asMap(attempt['exercise']);
            final score = _asInt(attempt['score']) ?? 0;

            return _AttemptTile(
              learnerName: _asString(learner['full_name'], fallback: 'Learner'),
              exerciseTitle: _asString(
                exercise['title'],
                fallback: 'Reading exercise',
              ),
              score: score,
            );
          }),
        ],
      ),
    );
  }
}

class _LearnersSection extends StatelessWidget {
  const _LearnersSection({
    required this.learners,
    required this.onViewProgress,
    required this.onUnlink,
  });

  final List<dynamic> learners;
  final ValueChanged<Map<String, dynamic>> onViewProgress;
  final ValueChanged<Map<String, dynamic>> onUnlink;

  @override
  Widget build(BuildContext context) {
    if (learners.isEmpty) {
      return const _EmptyCard(
        icon: Icons.person_add_alt_1_rounded,
        title: 'No linked learners',
        message: 'Demande au learner de generer son code puis ajoute-le ici.',
      );
    }

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.people_alt_rounded,
            title: 'Mes learners',
            subtitle: 'Accounts currently linked to this tutor.',
          ),
          const SizedBox(height: 14),
          ...learners.map((item) {
            final learner = _asMap(item);

            return _LearnerTile(
              learner: learner,
              onViewProgress: onViewProgress,
              onUnlink: onUnlink,
            );
          }),
        ],
      ),
    );
  }
}

class _LearnerTile extends StatelessWidget {
  const _LearnerTile({
    required this.learner,
    required this.onViewProgress,
    required this.onUnlink,
  });

  final Map<String, dynamic> learner;
  final ValueChanged<Map<String, dynamic>> onViewProgress;
  final ValueChanged<Map<String, dynamic>> onUnlink;

  @override
  Widget build(BuildContext context) {
    final name = _asString(learner['full_name'], fallback: 'Learner');
    final email = _asString(learner['email'], fallback: 'No email');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => onViewProgress(learner),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.textFieldBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                IconButton(
                  onPressed: () => onUnlink(learner),
                  tooltip: 'Detach',
                  icon: const Icon(
                    Icons.link_off_rounded,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearnerProgressSheet extends StatefulWidget {
  const _LearnerProgressSheet({
    required this.learnerId,
    required this.learnerName,
    required this.tutorApi,
    required this.progressFuture,
  });

  final int learnerId;
  final String learnerName;
  final TutorApiService tutorApi;
  final Future<Map<String, dynamic>> progressFuture;

  @override
  State<_LearnerProgressSheet> createState() => _LearnerProgressSheetState();
}

class _LearnerProgressSheetState extends State<_LearnerProgressSheet> {
  String _selectedModule = 'reading';
  late Future<List<dynamic>> _attemptsFuture = _loadAttempts();

  Future<List<dynamic>> _loadAttempts() {
    return widget.tutorApi.getLearnerAttempts(
      learnerId: widget.learnerId,
      module: _selectedModule,
    );
  }

  void _changeModule(String module) {
    setState(() {
      _selectedModule = module;
      _attemptsFuture = _loadAttempts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(26),
      ),
      child: SafeArea(
        top: false,
        child: FutureBuilder<Map<String, dynamic>>(
          future: widget.progressFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 260,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 260,
                child: Center(
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data ?? {};
            final progress = _asMap(data['progress']);

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.learnerName,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Progress by mode',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (progress.isEmpty)
                    const _EmptyCard(
                      icon: Icons.insights_rounded,
                      title: 'No progress',
                      message: 'This learner has no attempts yet.',
                    )
                  else
                    _TutorProgressChartSection(
                      progress: progress,
                      showHeader: false,
                    ),
                  const SizedBox(height: 18),
                  _ModuleFilter(
                    selected: _selectedModule,
                    onChanged: _changeModule,
                  ),
                  const SizedBox(height: 14),
                  _AttemptsHistory(
                    module: _selectedModule,
                    attemptsFuture: _attemptsFuture,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ModuleFilter extends StatelessWidget {
  const _ModuleFilter({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChipButton(
          label: 'Reading',
          module: 'reading',
          selected: selected,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        _FilterChipButton(
          label: 'Writing',
          module: 'writing',
          selected: selected,
          onChanged: onChanged,
        ),
        const SizedBox(width: 8),
        _FilterChipButton(
          label: 'Smart',
          module: 'smart-abstract',
          selected: selected,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.module,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final String module;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == module;

    return Expanded(
      child: SizedBox(
        height: 42,
        child: OutlinedButton(
          onPressed: () => onChanged(module),
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? AppColors.primary : Colors.white,
            foregroundColor: isSelected ? Colors.white : AppColors.textDark,
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.textFieldBorder,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _AttemptsHistory extends StatelessWidget {
  const _AttemptsHistory({required this.module, required this.attemptsFuture});

  final String module;
  final Future<List<dynamic>> attemptsFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: attemptsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return _EmptyCard(
            icon: Icons.cloud_off_rounded,
            title: 'History unavailable',
            message: snapshot.error.toString(),
          );
        }

        final attempts = snapshot.data ?? [];

        if (attempts.isEmpty) {
          return const _EmptyCard(
            icon: Icons.history_rounded,
            title: 'No attempts',
            message: 'No activity found for this mode.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...attempts.take(12).map((item) {
              return _AttemptHistoryTile(module: module, attempt: _asMap(item));
            }),
          ],
        );
      },
    );
  }
}

class _AttemptHistoryTile extends StatelessWidget {
  const _AttemptHistoryTile({required this.module, required this.attempt});

  final String module;
  final Map<String, dynamic> attempt;

  @override
  Widget build(BuildContext context) {
    final exercise = _asMap(attempt['exercise']);
    final title = _asString(exercise['title'], fallback: 'Exercise');
    final score = _asInt(attempt['score']) ?? 0;
    final status = _asString(attempt['status'], fallback: module);
    final feedback = _asString(attempt['feedback'], fallback: 'No feedback');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Row(
        children: [
          _ScoreBadge(score: score),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$status - $feedback',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftIcon(icon: icon, color: color),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideMetricCard extends StatelessWidget {
  const _WideMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _SoftIcon(icon: icon, color: AppColors.logoPurple),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  caption,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttemptTile extends StatelessWidget {
  const _AttemptTile({
    required this.learnerName,
    required this.exerciseTitle,
    required this.score,
  });

  final String learnerName;
  final String exerciseTitle;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _ScoreBadge(score: score),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exerciseTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  learnerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLearnerTile extends StatelessWidget {
  const _CompactLearnerTile({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SoftIcon(icon: icon, color: color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SoftIcon(icon: icon, color: AppColors.primary, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftIcon extends StatelessWidget {
  const _SoftIcon({required this.icon, required this.color, this.size = 44});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppColors.logoTeal
        : score >= 60
        ? AppColors.accent
        : AppColors.logoPurple;

    return Container(
      height: 48,
      width: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.textFieldBorder.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoNavy.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          _SoftIcon(icon: icon, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.isLoggingOut, required this.onLogout});

  final bool isLoggingOut;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: isLoggingOut ? null : onLogout,
        icon: const Icon(Icons.logout_rounded),
        label: Text(isLoggingOut ? 'Logging out...' : 'Log out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.textFieldBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _TutorBottomNav extends StatelessWidget {
  const _TutorBottomNav({required this.currentIndex, required this.onChanged});

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 96,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 74,
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.textFieldBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TutorNavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: currentIndex == 0,
                      onTap: () => onChanged(0),
                    ),
                  ),
                  Expanded(
                    child: _TutorNavItem(
                      icon: Icons.insights_rounded,
                      label: 'Progress',
                      isSelected: currentIndex == 1,
                      onTap: () => onChanged(1),
                    ),
                  ),
                  const SizedBox(width: 76),
                  Expanded(
                    child: _TutorNavItem(
                      icon: Icons.groups_rounded,
                      label: 'Learners',
                      isSelected: currentIndex == 3,
                      onTap: () => onChanged(3),
                    ),
                  ),
                  Expanded(
                    child: _TutorNavItem(
                      icon: Icons.person_rounded,
                      label: 'Account',
                      isSelected: currentIndex == 4,
                      onTap: () => onChanged(4),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 32,
              child: GestureDetector(
                onTap: () => onChanged(2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: currentIndex == 2 ? 70 : 66,
                  width: currentIndex == 2 ? 70 : 66,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.link_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorNavItem extends StatelessWidget {
  const _TutorNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textLight;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorErrorState extends StatelessWidget {
  const _TutorErrorState({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _SoftIcon(
            icon: Icons.wifi_off_rounded,
            color: AppColors.logoPurple,
            size: 58,
          ),
          const SizedBox(height: 18),
          const Text(
            'Dashboard unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _LogoutButton(isLoggingOut: false, onLogout: onLogout ?? () {}),
        ],
      ),
    );
  }
}

class _ConfirmUnlinkSheet extends StatelessWidget {
  const _ConfirmUnlinkSheet({required this.learnerName});

  final String learnerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detach le learner ?',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$learnerName ne sera plus suivi par ce compte tutor.',
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.textFieldBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    child: const Text('Detach'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;

  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;

  return const [];
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);

  return null;
}

String _asString(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();

  if (text == null || text.isEmpty) {
    return fallback;
  }

  return text;
}
