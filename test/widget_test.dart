import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_estudio/features/auth/data/auth_repository.dart';
import 'package:app_estudio/features/auth/presentation/sign_in_page.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> authStateChanges() => const Stream<User?>.empty();

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential> signInWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInAnonymously() {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
  }) async {}

  @override
  Future<UserCredential> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('Sign-in page renders expected UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SignInPage(authRepository: _FakeAuthRepository())),
    );

    expect(find.text('Bienvenido a App Estudio'), findsOneWidget);
    expect(
      find.text('Inicia sesion con Google, Email, Telefono o Anonimo.'),
      findsOneWidget,
    );
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
