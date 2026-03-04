import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/app_settings.dart';
import '../../schedule/data/schedule_repository.dart';
import '../../schedule/presentation/home_page.dart';
import '../data/auth_repository.dart';
import 'sign_in_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authRepository,
    required this.scheduleRepository,
    required this.settings,
    required this.onSettingsChanged,
  });

  final AuthRepository authRepository;
  final ScheduleRepository scheduleRepository;
  final AppSettings settings;
  final ValueChanged<AppSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return SignInPage(authRepository: authRepository);
        }

        return HomePage(
          user: user,
          authRepository: authRepository,
          scheduleRepository: scheduleRepository,
          settings: settings,
          onSettingsChanged: onSettingsChanged,
        );
      },
    );
  }
}
