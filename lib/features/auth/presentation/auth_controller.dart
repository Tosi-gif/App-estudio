import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authRepository);

  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  String? _phoneVerificationId;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPendingPhoneCode =>
      _phoneVerificationId != null && _phoneVerificationId!.isNotEmpty;

  Future<void> signInWithGoogle() async {
    await _runAuthAction(() async {
      await _authRepository.signInWithGoogle();
    });
  }

  Future<void> signInAnonymously() async {
    await _runAuthAction(() async {
      await _authRepository.signInAnonymously();
    });
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(() async {
      await _authRepository.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _runAuthAction(() async {
      await _authRepository.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    });
  }

  Future<void> sendPhoneCode(String phoneNumber) async {
    await _runAuthAction(() async {
      await _authRepository.sendPhoneCode(
        phoneNumber: phoneNumber.trim(),
        onCodeSent: (verificationId) {
          _phoneVerificationId = verificationId;
          _errorMessage = 'Codigo SMS enviado.';
          notifyListeners();
        },
      );
    });
  }

  Future<void> verifyPhoneCode(String smsCode) async {
    final verificationId = _phoneVerificationId;
    if (verificationId == null || verificationId.isEmpty) {
      _errorMessage = 'Primero solicita el codigo por SMS.';
      notifyListeners();
      return;
    }

    await _runAuthAction(() async {
      await _authRepository.verifyPhoneCode(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      _phoneVerificationId = null;
    });
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
    } catch (_) {
      _errorMessage = 'No se pudo iniciar sesion.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Correo invalido.';
      case 'invalid-credential':
        return 'Credenciales invalidas.';
      case 'wrong-password':
        return 'Contrasena incorrecta.';
      case 'user-not-found':
        return 'No existe una cuenta con ese correo.';
      case 'email-already-in-use':
        return 'Ese correo ya esta registrado.';
      case 'weak-password':
        return 'La contrasena es demasiado debil.';
      case 'too-many-requests':
        return 'Demasiados intentos. Prueba de nuevo en unos minutos.';
      case 'invalid-verification-code':
        return 'Codigo SMS invalido.';
      case 'invalid-verification-id':
        return 'La verificacion del telefono no es valida.';
      default:
        return e.message ?? 'No se pudo iniciar sesion.';
    }
  }
}
