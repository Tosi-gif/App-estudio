import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    } on GoogleSignInException catch (e) {
      _errorMessage = _mapGoogleSignInError(e);
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

  String _mapGoogleSignInError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Inicio de sesion cancelado.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Error de configuracion de Google Sign-In. Revisa SHA-1/SHA-256 y google-services.json.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'No se pudo conectar con el proveedor de Google en este dispositivo.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'No se pudo mostrar la pantalla de Google Sign-In.';
      default:
        final details = error.description?.trim();
        if (details != null && details.isNotEmpty) {
          return 'Error de Google Sign-In: $details';
        }
        return 'No se pudo iniciar sesion con Google.';
    }
  }
}
