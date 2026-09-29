import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'services/local_notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _notifications = LocalNotificationService.instance;

  bool _practiceReminders = true;
  bool _weakScoreAlerts = true;
  bool _tutorLinkAlerts = true;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _notifications.initialize();
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequestingPermission = true);

    final granted = await _notifications.requestPermission();

    if (!mounted) return;

    setState(() => _isRequestingPermission = false);
    _showSnackBar(
      granted
          ? 'Notifications autorisees.'
          : 'Permission notification refusee.',
    );
  }

  Future<void> _sendTestNotification() async {
    await _notifications.showNotification(
      id: 1000,
      title: 'LexiCoach',
      body: 'This is a local notification test.',
    );
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

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
        children: [
          _HeroCard(
            onRequestPermission: _isRequestingPermission
                ? null
                : _requestPermission,
            onTest: _sendTestNotification,
            isLoading: _isRequestingPermission,
          ),
          const SizedBox(height: 18),
          _NotificationSettingCard(
            icon: Icons.alarm_rounded,
            title: 'Practice reminders',
            subtitle: 'Local reminder to help the learner practice.',
            value: _practiceReminders,
            onChanged: (value) => setState(() => _practiceReminders = value),
            onPreview: _practiceReminders
                ? _notifications.showPracticeReminder
                : null,
          ),
          const SizedBox(height: 14),
          _NotificationSettingCard(
            icon: Icons.trending_down_rounded,
            title: 'Weak score alerts',
            subtitle: 'Preview alert for low learner scores.',
            value: _weakScoreAlerts,
            onChanged: (value) => setState(() => _weakScoreAlerts = value),
            onPreview: _weakScoreAlerts
                ? _notifications.showWeakScoreAlert
                : null,
          ),
          const SizedBox(height: 14),
          _NotificationSettingCard(
            icon: Icons.link_rounded,
            title: 'Tutor link alerts',
            subtitle: 'Preview alert when a tutor link is created.',
            value: _tutorLinkAlerts,
            onChanged: (value) => setState(() => _tutorLinkAlerts = value),
            onPreview: _tutorLinkAlerts
                ? _notifications.showTutorLinkedAlert
                : null,
          ),
          const SizedBox(height: 18),
          const _InfoCard(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.onRequestPermission,
    required this.onTest,
    required this.isLoading,
  });

  final VoidCallback? onRequestPermission;
  final VoidCallback onTest;
  final bool isLoading;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Local notifications',
            style: TextStyle(
              color: AppColors.textDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use this page to request permission and preview the notification types used by LexiCoach.',
            style: TextStyle(
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
                child: ElevatedButton.icon(
                  onPressed: onRequestPermission,
                  icon: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(isLoading ? 'Requesting...' : 'Allow'),
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
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTest,
                  icon: const Icon(Icons.bolt_rounded),
                  label: const Text('Test'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.textFieldBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingCard extends StatelessWidget {
  const _NotificationSettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.onPreview,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
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
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Preview'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        'For now these are local notification previews. Backend-triggered push notifications can be added later with Firebase Cloud Messaging.',
        style: TextStyle(
          color: AppColors.textDark,
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
