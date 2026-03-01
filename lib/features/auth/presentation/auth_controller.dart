import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authRepository);

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> signInWithGoogle() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'No se pudo iniciar sesion.';
    } catch (_) {
      _errorMessage = 'No se pudo iniciar sesion.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  void clearError() {
    _errorMessage = null;
  }
}
