import 'package:flutter/material.dart';

import '../data/auth_repository.dart';
import 'auth_controller.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController(widget.authRepository);
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final message = _controller.errorMessage;
    if (!mounted || message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    _controller.clearError();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bienvenido a App Estudio',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Inicia sesion con Google para crear tu registro.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _controller.isLoading
                          ? null
                          : _controller.signInWithGoogle,
                      icon: const Icon(Icons.login),
                      label: Text(
                        _controller.isLoading
                            ? 'Conectando...'
                            : 'Continuar con Google',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
