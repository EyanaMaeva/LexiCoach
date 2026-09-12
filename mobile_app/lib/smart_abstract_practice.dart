import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'services/smart_abstract_api_service.dart';

class SmartAbstractPractice extends StatefulWidget {
  const SmartAbstractPractice({super.key, required this.exerciseId});

  final int exerciseId;

  @override
  State<SmartAbstractPractice> createState() => _SmartAbstractPracticeState();
}

class _SmartAbstractPracticeState extends State<SmartAbstractPractice> {
  final _apiService = SmartAbstractApiService();
  final _summaryController = TextEditingController();

  Map<String, dynamic>? _exercise;
  Map<String, dynamic>? _result;
  bool _isLoading = true;
  bool _isEvaluating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _loadExercise() async {
    try {
      final exercise = await _apiService.getExerciseDetail(widget.exerciseId);
      if (!mounted) return;

      setState(() {
        _exercise = exercise;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _evaluate() async {
    if (_isEvaluating) return;

    final summary = _summaryController.text.trim();

    if (summary.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write your summary first.')),
      );
      return;
    }

    setState(() => _isEvaluating = true);

    try {
      final data = await _apiService.evaluateExercise(
        id: widget.exerciseId,
        summary: summary,
      );
      if (!mounted) return;

      setState(() {
        _result = data['result'];
        _isEvaluating = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isEvaluating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  int _wordCount() {
    final summary = _summaryController.text.trim();

    if (summary.isEmpty) return 0;

    return summary.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _ErrorState(
          message: _errorMessage!,
          onRetry: () {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
            _loadExercise();
          },
        ),
      );
    }

    final minWords = _exercise?['min_words'] ?? 20;
    final maxWords = _exercise?['max_words'] ?? 60;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _exercise?['title'] ?? 'Smart Abstract',
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          _SourceTextCard(exercise: _exercise!),
          const SizedBox(height: 18),
          _SummaryInput(
            controller: _summaryController,
            wordCount: _wordCount(),
            minWords: minWords,
            maxWords: maxWords,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isEvaluating ? null : _evaluate,
              icon: _isEvaluating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(_isEvaluating ? 'Reviewing...' : 'Review Summary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.65,
                ),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _SourceTextCard extends StatelessWidget {
  const _SourceTextCard({required this.exercise});

  final Map<String, dynamic> exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoTeal.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.logoTeal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.article_rounded,
                  color: AppColors.logoTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  exercise['level']?.toString().toUpperCase() ?? 'BEGINNER',
                  style: const TextStyle(
                    color: AppColors.logoTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            exercise['source_text'] ?? '',
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          if ((exercise['instructions'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              exercise['instructions'],
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryInput extends StatelessWidget {
  const _SummaryInput({
    required this.controller,
    required this.wordCount,
    required this.minWords,
    required this.maxWords,
    required this.onChanged,
  });

  final TextEditingController controller;
  final int wordCount;
  final int minWords;
  final int maxWords;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 7,
      maxLines: 11,
      onChanged: (_) => onChanged(),
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Write the main idea here...',
        hintStyle: const TextStyle(color: AppColors.textLight),
        helperText: '$wordCount words - target $minWords-$maxWords words',
        helperStyle: TextStyle(
          color: wordCount >= minWords && wordCount <= maxWords
              ? AppColors.logoTeal
              : AppColors.textLight,
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(22),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.textFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.textFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final feedback = result['feedback'] as Map<String, dynamic>?;
    final missingIdeas = result['missing_ideas'] as List<dynamic>? ?? [];
    final strengths = result['strengths'] as List<dynamic>? ?? [];
    final score = result['score'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.logoBlue.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 58,
                width: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _scoreColor(score).withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$score%',
                  style: TextStyle(
                    color: _scoreColor(score),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback?['title'] ?? 'Feedback',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback?['message'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            title: 'Improved summary',
            icon: Icons.auto_fix_high_rounded,
          ),
          const SizedBox(height: 8),
          Text(
            result['improved_summary'] ?? '',
            style: const TextStyle(
              color: AppColors.textDark,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (strengths.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Strengths',
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 8),
            ...strengths.map(
              (strength) => _BulletText(text: strength.toString()),
            ),
          ],
          if (missingIdeas.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Missing ideas',
              icon: Icons.lightbulb_outline_rounded,
            ),
            const SizedBox(height: 8),
            ...missingIdeas.map((idea) => _BulletText(text: idea.toString())),
          ],
        ],
      ),
    );
  }

  Color _scoreColor(dynamic score) {
    final value = score is num ? score : num.tryParse(score.toString()) ?? 0;

    if (value >= 80) return AppColors.logoTeal;
    if (value >= 50) return AppColors.logoOrange;
    return Colors.redAccent;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            height: 6,
            width: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textLight,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
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
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.logoOrange,
              size: 58,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load this exercise.',
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
