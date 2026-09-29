import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'services/auth_module.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final _authApi = AuthApiService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _practiceReminders = true;
  bool _weakScoreAlerts = true;
  bool _codeLinkedAlerts = true;
  bool _slowSpeech = true;
  int _fontSize = 16;
  String _preferredLanguage = 'en';
  String _learningLevel = 'beginner';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);

    try {
      final response = await _authApi.me();
      final user = response['data']?['user'] as Map<String, dynamic>? ?? {};
      final preferences = user['preferences'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        _nameController.text = user['full_name']?.toString() ?? 'User';
        _emailController.text = user['email']?.toString() ?? '';
        _preferredLanguage =
            preferences['preferred_language']?.toString() ?? 'en';
        _learningLevel =
            preferences['learning_level']?.toString() ?? 'beginner';
        _fontSize = _intFrom(preferences['dyslexia_font_size'], 16);
        _slowSpeech = preferences['dyslexia_slow_speech'] == true;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar(error.toString());
    }
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;

    setState(() => _isSavingProfile = true);

    try {
      final response = await _authApi.updateProfile(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        preferredLanguage: _preferredLanguage,
        learningLevel: _learningLevel,
        dyslexiaFontSize: _fontSize,
        dyslexiaSlowSpeech: _slowSpeech,
      );
      final user = response['data']?['user'] as Map<String, dynamic>? ?? {};

      if (!mounted) return;

      setState(() {
        _nameController.text =
            user['full_name']?.toString() ?? _nameController.text;
        _emailController.text =
            user['email']?.toString() ?? _emailController.text;
        _isSavingProfile = false;
      });
      _showSnackBar('Profil mis a jour.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingProfile = false);
      _showSnackBar(error.toString());
    }
  }

  Future<void> _savePassword() async {
    if (_isSavingPassword) return;

    setState(() => _isSavingPassword = true);

    try {
      await _authApi.updatePassword(
        currentPassword: _currentPasswordController.text,
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _isSavingPassword = false);
      _showSnackBar('Mot de passe mis a jour.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSavingPassword = false);
      _showSnackBar(error.toString());
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  int _intFrom(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
          'Réglages',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
              children: [
                _SettingsCard(
                  title: 'Personal info',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _SoftTextField(
                      controller: _nameController,
                      label: 'Full name',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    _SoftTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _SoftDropdown(
                      label: 'Preferred language',
                      value: _preferredLanguage,
                      items: const {
                        'en': 'English',
                        'fr': 'French',
                        'es': 'Spanish',
                      },
                      onChanged: (value) {
                        setState(() => _preferredLanguage = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    _SoftDropdown(
                      label: 'Learning level',
                      value: _learningLevel,
                      items: const {
                        'beginner': 'Beginner',
                        'intermediate': 'Intermediate',
                        'advanced': 'Advanced',
                      },
                      onChanged: (value) {
                        setState(() => _learningLevel = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      label: _isSavingProfile ? 'Saving...' : 'Save profile',
                      icon: Icons.check_rounded,
                      onPressed: _isSavingProfile ? null : _saveProfile,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: 'Dyslexia preferences',
                  icon: Icons.tune_rounded,
                  children: [
                    _SwitchRow(
                      title: 'Slow voice',
                      subtitle: 'Use slower speech for audio learning.',
                      value: _slowSpeech,
                      onChanged: (value) => setState(() => _slowSpeech = value),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Text size: $_fontSize',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Slider(
                      value: _fontSize.toDouble(),
                      min: 14,
                      max: 26,
                      divisions: 12,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() => _fontSize = value.round());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: 'Notifications',
                  icon: Icons.notifications_none_rounded,
                  children: [
                    _SwitchRow(
                      title: 'Practice reminders',
                      subtitle: 'Remind the learner to practice.',
                      value: _practiceReminders,
                      onChanged: (value) {
                        setState(() => _practiceReminders = value);
                      },
                    ),
                    _SwitchRow(
                      title: 'Weak score alerts',
                      subtitle: 'Notify when a learner has a weak attempt.',
                      value: _weakScoreAlerts,
                      onChanged: (value) {
                        setState(() => _weakScoreAlerts = value);
                      },
                    ),
                    _SwitchRow(
                      title: 'Tutor link alerts',
                      subtitle: 'Notify when a tutor link is created.',
                      value: _codeLinkedAlerts,
                      onChanged: (value) {
                        setState(() => _codeLinkedAlerts = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  title: 'Security',
                  icon: Icons.lock_outline_rounded,
                  children: [
                    _SoftTextField(
                      controller: _currentPasswordController,
                      label: 'Current password',
                      icon: Icons.lock_clock_outlined,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    _SoftTextField(
                      controller: _newPasswordController,
                      label: 'New password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    _SoftTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm new password',
                      icon: Icons.lock_reset_rounded,
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    _PrimaryButton(
                      label: _isSavingPassword
                          ? 'Saving...'
                          : 'Update password',
                      icon: Icons.password_rounded,
                      onPressed: _isSavingPassword ? null : _savePassword,
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SoftTextField extends StatelessWidget {
  const _SoftTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.textFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.textFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _SoftDropdown extends StatelessWidget {
  const _SoftDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: items.containsKey(value) ? value : items.keys.first,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.textFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.textFieldBorder),
        ),
      ),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: value,
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        onChanged: onChanged,
      ),
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
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
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
    );
  }
}
