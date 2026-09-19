import 'package:flutter/material.dart';

import 'ai_conversation_page.dart';
import 'app_colors.dart';
import 'reading_exercises_list.dart';
import 'services/learner_api_service.dart';
import 'smart_abstract_exercises_list.dart';
import 'writing_exercises_list.dart';

class LearningModesPage extends StatefulWidget {
  const LearningModesPage({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<LearningModesPage> createState() => _LearningModesPageState();
}

class _LearningModesPageState extends State<LearningModesPage> {
  final _apiService = LearnerApiService();
  late Future<List<dynamic>> _modesFuture;

  @override
  void initState() {
    super.initState();
    _modesFuture = _apiService.getLearningModes();
  }

  void _reload() {
    setState(() {
      _modesFuture = _apiService.getLearningModes();
    });
  }

  void _openMode(dynamic mode) {
    final slug = mode['slug']?.toString() ?? '';

    Widget? page;
    if (slug == 'reading') {
      page = const ReadingExercisesList();
    } else if (slug == 'writing') {
      page = const WritingExercisesList();
    } else if (slug == 'smart-abstract') {
      page = const SmartAbstractExercisesList();
    } else if (slug == 'ai-conversation') {
      page = const AiConversationPage();
    }

    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This mode is coming soon.')),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
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
          'Learning Modes',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _modesFuture,
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

          final modes = snapshot.data ?? [];
          final hasAiConversation = modes.any(
            (mode) => mode['slug']?.toString() == 'ai-conversation',
          );

          if (modes.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
              children: [
                const Text(
                  'Choose how you want to practice',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The app loads these modules from the backend, then opens the right exercise list.',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _ModeCard(
                  mode: const {
                    'name': 'AI Conversation',
                    'slug': 'ai-conversation',
                    'description':
                        'Practice short voice sessions with the app timer.',
                  },
                  onTap: () => _openMode(const {'slug': 'ai-conversation'}),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
            children: [
              const Text(
                'Choose how you want to practice',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The app loads these modules from the backend, then opens the right exercise list.',
                style: TextStyle(
                  color: AppColors.textLight,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              if (!hasAiConversation)
                _ModeCard(
                  mode: const {
                    'name': 'AI Conversation',
                    'slug': 'ai-conversation',
                    'description':
                        'Practice short voice sessions with the app timer.',
                  },
                  onTap: () => _openMode(const {'slug': 'ai-conversation'}),
                ),
              ...modes.map(
                (mode) => _ModeCard(mode: mode, onTap: () => _openMode(mode)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.onTap});

  final dynamic mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slug = mode['slug']?.toString() ?? '';
    final style = _styleFor(slug);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.textFieldBorder),
        boxShadow: [
          BoxShadow(
            color: style.color.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: style.color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(style.icon, color: style.color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode['name'] ?? 'Learning mode',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mode['description'] ?? 'Practice with LexiCoach.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
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

  _ModeStyle _styleFor(String slug) {
    switch (slug) {
      case 'reading':
        return const _ModeStyle(Icons.menu_book_rounded, AppColors.logoBlue);
      case 'writing':
        return const _ModeStyle(Icons.edit_note_rounded, AppColors.logoPurple);
      case 'smart-abstract':
        return const _ModeStyle(Icons.summarize_rounded, AppColors.logoTeal);
      case 'ai-conversation':
        return const _ModeStyle(
          Icons.record_voice_over_rounded,
          AppColors.primary,
        );
      default:
        return const _ModeStyle(
          Icons.auto_awesome_rounded,
          AppColors.logoOrange,
        );
    }
  }
}

class _ModeStyle {
  const _ModeStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
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
              'Unable to load learning modes.',
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
