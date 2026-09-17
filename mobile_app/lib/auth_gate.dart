import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'landing.dart';
import 'main_screen.dart';
import 'services/auth_module.dart';
import 'tutor_home.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authApi = AuthApiService();

  late final Future<Widget> _startScreenFuture = _resolveStartScreen();

  Future<Widget> _resolveStartScreen() async {
    final hasSavedSession = await _authApi.hasSavedSession();

    if (!hasSavedSession) {
      return const LandingPage();
    }

    try {
      final response = await _authApi.me();
      final user = response['data']?['user'];
      final role = user?['role'] as String? ?? 'learner';

      final fullName = user?['full_name']?.toString() ?? 'User';

      if (role == 'learner') {
        return MainScreen(userName: _firstNameFrom(fullName));
      }

      if (role == 'tutor') {
        return TutorHome(userName: _firstNameFrom(fullName));
      }

      await _authApi.clearSession();
      return const LandingPage();
    } catch (_) {
      await _authApi.clearSession();
      return const LandingPage();
    }
  }

  String _firstNameFrom(String fullName) {
    final trimmedName = fullName.trim();

    if (trimmedName.isEmpty) {
      return 'User';
    }

    return trimmedName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        }

        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      },
    );
  }
}
