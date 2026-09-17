import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'services/learner_api_service.dart';

class TutorLinkPage extends StatefulWidget {
  const TutorLinkPage({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  State<TutorLinkPage> createState() => _TutorLinkPageState();
}

class _TutorLinkPageState extends State<TutorLinkPage> {
  final _apiService = LearnerApiService();

  Map<String, dynamic>? _associationCode;
  List<dynamic> _linkedTutors = const [];
  bool _isLoading = true;
  bool _isWorking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    try {
      final status = await _apiService.getTutorLinkStatus();
      final tutors = status['linked_tutors'];
      if (!mounted) return;

      setState(() {
        _associationCode = status['association_code'] as Map<String, dynamic>?;
        _linkedTutors = tutors is List ? tutors : const [];
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

  Future<void> _generateCode() async {
    if (_isWorking) return;

    setState(() => _isWorking = true);

    try {
      final associationCode = await _apiService.generateAssociationCode();
      if (!mounted) return;

      setState(() {
        _associationCode = associationCode;
        _isWorking = false;
        _errorMessage = null;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _regenerateCode() async {
    if (_isWorking) return;

    setState(() => _isWorking = true);

    try {
      final associationCode = await _apiService.regenerateAssociationCode();
      if (!mounted) return;

      setState(() {
        _associationCode = associationCode;
        _isWorking = false;
        _errorMessage = null;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _cancelCode() async {
    if (_isWorking) return;

    setState(() => _isWorking = true);

    try {
      await _apiService.cancelAssociationCode();
      if (!mounted) return;

      setState(() {
        _associationCode = null;
        _isWorking = false;
        _errorMessage = null;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _copyCode() async {
    final code = _associationCode?['code']?.toString();
    if (code == null || code.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code copied.')));
  }

  void _showError(Object error) {
    if (!mounted) return;

    setState(() => _isWorking = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));
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
          'Tutor Link',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? _ErrorState(message: _errorMessage!, onRetry: _loadCode)
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadCode,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 88),
                children: [
                  const Text(
                    'Link with a tutor',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate a code and share it with your tutor. The tutor uses it to follow your progress.',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_linkedTutors.isNotEmpty) ...[
                    _LinkedTutorsCard(tutors: _linkedTutors),
                    const SizedBox(height: 18),
                  ],
                  _CodeCard(
                    associationCode: _associationCode,
                    hasLinkedTutors: _linkedTutors.isNotEmpty,
                    isWorking: _isWorking,
                    onGenerate: _generateCode,
                    onRegenerate: _regenerateCode,
                    onCancel: _cancelCode,
                    onCopy: _copyCode,
                  ),
                  const SizedBox(height: 18),
                  const _HowItWorksCard(),
                ],
              ),
            ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({
    required this.associationCode,
    required this.hasLinkedTutors,
    required this.isWorking,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onCancel,
    required this.onCopy,
  });

  final Map<String, dynamic>? associationCode;
  final bool hasLinkedTutors;
  final bool isWorking;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final VoidCallback onCancel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final code = associationCode?['code']?.toString();
    final expiresAt = associationCode?['expires_at']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.textFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: AppColors.logoBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.supervisor_account_rounded,
              color: AppColors.logoBlue,
              size: 30,
            ),
          ),
          const SizedBox(height: 22),
          if (code == null || code.isEmpty) ...[
            Text(
              hasLinkedTutors ? 'No pending code' : 'No active code',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasLinkedTutors
                  ? 'Your tutor is already linked. Generate a new code only if another tutor needs access.'
                  : 'Create a code when a tutor is ready to connect with this learner account.',
              style: const TextStyle(
                color: AppColors.textLight,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: isWorking ? 'Generating...' : 'Generate Code',
              icon: Icons.add_rounded,
              onPressed: isWorking ? null : onGenerate,
            ),
          ] else ...[
            const Text(
              'Your tutor code',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              code,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Expires at $expiresAt',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _PrimaryButton(
                    label: 'Copy',
                    icon: Icons.copy_rounded,
                    onPressed: isWorking ? null : onCopy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryButton(
                    label: 'New',
                    icon: Icons.refresh_rounded,
                    onPressed: isWorking ? null : onRegenerate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DangerButton(
              label: isWorking ? 'Cancelling...' : 'Cancel Code',
              icon: Icons.close_rounded,
              onPressed: isWorking ? null : onCancel,
            ),
          ],
        ],
      ),
    );
  }
}

class _LinkedTutorsCard extends StatelessWidget {
  const _LinkedTutorsCard({required this.tutors});

  final List<dynamic> tutors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textFieldBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active tutor',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'This learner account is linked.',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...tutors.map((tutor) {
            final tutorMap = tutor is Map ? tutor : const {};
            final name = tutorMap['full_name']?.toString() ?? 'Tutor';
            final email = tutorMap['email']?.toString() ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.textFieldBorder),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.logoBlue,
                      child: Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Linked',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.pin_rounded,
            title: 'Generate',
            text: 'The learner creates one active code.',
          ),
          SizedBox(height: 14),
          _InfoRow(
            icon: Icons.ios_share_rounded,
            title: 'Share',
            text: 'Send the code to the tutor outside the app.',
          ),
          SizedBox(height: 14),
          _InfoRow(
            icon: Icons.verified_user_rounded,
            title: 'Tutor links',
            text: 'The tutor enters the code in the tutor space.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.textLight,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
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

class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
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
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.logoOrange,
              size: 58,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load tutor link.',
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
