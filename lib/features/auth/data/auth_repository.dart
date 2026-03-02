import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInAnonymously();
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
  });
  Future<UserCredential> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  });
  Future<void> signOut();
}
