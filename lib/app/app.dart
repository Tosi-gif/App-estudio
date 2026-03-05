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
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A7C73),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A7C73),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'App Estudio',
      theme: ThemeData(
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF4F8F7),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: lightScheme.onSurface,
          titleTextStyle: TextStyle(
            color: lightScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shadowColor: const Color(0x22000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: lightScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: lightScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: lightScheme.primary, width: 1.4),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: lightScheme.primary,
          foregroundColor: lightScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        scaffoldBackgroundColor: const Color(0xFF0B1113),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: darkScheme.onSurface,
          titleTextStyle: TextStyle(
            color: darkScheme.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          color: const Color(0xFF111A1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF10181C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: darkScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: darkScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: darkScheme.primary, width: 1.4),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: darkScheme.primary,
          foregroundColor: darkScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
