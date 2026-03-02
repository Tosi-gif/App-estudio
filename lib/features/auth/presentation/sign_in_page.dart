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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();

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
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                    'Inicia sesion con Google, Email, Telefono o Anonimo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electronico',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contrasena'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _controller.isLoading
                              ? null
                              : () => _controller.signInWithEmailAndPassword(
                                    email: _emailController.text,
                                    password: _passwordController.text,
                                  ),
                          child: const Text('Entrar con email'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _controller.isLoading
                              ? null
                              : () =>
                                    _controller.createUserWithEmailAndPassword(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    ),
                          child: const Text('Registrarme'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefono (+34...)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _controller.isLoading
                              ? null
                              : () => _controller.sendPhoneCode(
                                    _phoneController.text,
                                  ),
                          child: const Text('Enviar SMS'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _smsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Codigo SMS',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _controller.isLoading ||
                                  !_controller.hasPendingPhoneCode
                              ? null
                              : () => _controller.verifyPhoneCode(
                                    _smsController.text,
                                  ),
                          child: const Text('Verificar telefono'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _controller.isLoading
                          ? null
                          : _controller.signInAnonymously,
                      icon: const Icon(Icons.person_outline),
                      label: Text(
                        _controller.isLoading
                            ? 'Conectando...'
                            : 'Continuar como anonimo',
                      ),
                    ),
                  ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
