import 'package:flutter/material.dart';

import 'app_settings.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/presentation/auth_gate.dart';
import '../features/schedule/data/local_schedule_repository.dart';
import '../features/schedule/data/schedule_repository.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthRepository _authRepository;
  late final ScheduleRepository _scheduleRepository;
  AppSettings _settings = AppSettings.defaults;

  @override
  void initState() {
    super.initState();
    _authRepository = FirebaseAuthRepository();
    _scheduleRepository = LocalScheduleRepository();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await AppSettings.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
    });
  }

  Future<void> _updateSettings(AppSettings value) async {
    await value.save();
    if (!mounted) return;
    setState(() {
      _settings = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Estudio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _settings.themeMode,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(_settings.textScaleFactor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AuthGate(
        authRepository: _authRepository,
        scheduleRepository: _scheduleRepository,
        settings: _settings,
        onSettingsChanged: _updateSettings,
      ),
    );
  }
}
