import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _authRepository = FirebaseAuthRepository();
    _scheduleRepository = LocalScheduleRepository();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Estudio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: AuthGate(
        authRepository: _authRepository,
        scheduleRepository: _scheduleRepository,
      ),
    );
  }
}
