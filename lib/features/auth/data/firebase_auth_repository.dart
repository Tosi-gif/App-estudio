import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final authResult = await _firebaseAuth.signInWithCredential(credential);
    await _upsertUser(authResult.user);
    return authResult;
  }

  @override
  Future<UserCredential> signInAnonymously() async {
    final authResult = await _firebaseAuth.signInAnonymously();
    await _upsertUser(authResult.user);
    return authResult;
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final authResult = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _upsertUser(authResult.user);
    return authResult;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final authResult = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _upsertUser(authResult.user);
    return authResult;
  }

  @override
  Future<void> sendPhoneCode({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
  }) async {
    final completer = Completer<void>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final authResult = await _firebaseAuth.signInWithCredential(
            credential,
          );
          await _upsertUser(authResult.user);
          if (!completer.isCompleted) completer.complete();
        } catch (error, stackTrace) {
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        }
      },
      verificationFailed: (FirebaseAuthException error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (String verificationId, int? _) {
        onCodeSent(verificationId);
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  @override
  Future<UserCredential> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final authResult = await _firebaseAuth.signInWithCredential(credential);
    await _upsertUser(authResult.user);
    return authResult;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<void> _upsertUser(User? user) async {
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'photoUrl': user.photoURL ?? '',
      'isAnonymous': user.isAnonymous,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
