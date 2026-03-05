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
  bool _obscurePassword = true;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF061216), Color(0xFF102028)]
                : const [Color(0xFFEAF8F5), Color(0xFFDBEEE9)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Container(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: colorScheme.onPrimaryContainer,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Bienvenido a App Estudio',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Inicia sesion con correo y contrasena o con tu cuenta de Google.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Correo electronico',
                              prefixIcon: Icon(Icons.alternate_email),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contrasena',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Mostrar contrasena'
                                    : 'Ocultar contrasena',
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
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
                                      : () => _controller.createUserWithEmailAndPassword(
                                            email: _emailController.text,
                                            password: _passwordController.text,
                                          ),
                                  child: const Text('Registrarme'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'o',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const Expanded(child: Divider()),
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
                        ],
                      ),
                    ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
