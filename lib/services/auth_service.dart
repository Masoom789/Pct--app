import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Email/password auth on Firebase. Session is held by Firebase Auth;
/// nothing sensitive is kept in plain text. Login is throttled
/// client-side: 5 failed attempts -> 15 minute lock.
///
/// Firebase is touched LAZILY (getters, not the constructor) so the
/// app can still open its setup screen when no Firebase config exists.
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? storage,
  })  : _authOverride = auth,
        _firestoreOverride = firestore,
        _storage = storage ?? const FlutterSecureStorage();

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  final FlutterSecureStorage _storage;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static const String _lockKey = 'pct_login_lock_until';
  static const String _failsKey = 'pct_login_fails';
  static const int maxFails = 5;
  static const Duration lockDuration = Duration(minutes: 15);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _checkLock() async {
    final raw = await _storage.read(key: _lockKey);
    if (raw == null) return;
    final until = DateTime.tryParse(raw);
    if (until == null) return;
    if (DateTime.now().isBefore(until)) {
      final mins = until.difference(DateTime.now()).inMinutes + 1;
      throw AuthException('Too many failed attempts. Try again in $mins minutes.');
    }
    await _storage.delete(key: _lockKey);
    await _storage.delete(key: _failsKey);
  }

  Future<void> _recordFailure() async {
    final raw = await _storage.read(key: _failsKey);
    final fails = (int.tryParse(raw ?? '0') ?? 0) + 1;
    if (fails >= maxFails) {
      await _storage.write(
        key: _lockKey,
        value: DateTime.now().add(lockDuration).toIso8601String(),
      );
      await _storage.delete(key: _failsKey);
    } else {
      await _storage.write(key: _failsKey, value: fails.toString());
    }
  }

  Future<void> _clearFailures() async {
    await _storage.delete(key: _failsKey);
    await _storage.delete(key: _lockKey);
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'user-disabled':
        return 'This account has been disabled. Contact admin.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please log in instead.';
      case 'weak-password':
        return 'Password must be at least 8 characters';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a few minutes.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<User> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await _firestore.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user.sendEmailVerification();
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyError(e));
    }
  }

  Future<User> signIn({required String email, required String password}) async {
    await _checkLock();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _clearFailures();
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      await _recordFailure();
      throw AuthException(_friendlyError(e));
    }
  }

  Future<void> signOut() async {
    await _clearFailures();
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No user is signed in.');
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyError(e));
    }
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendlyError(e));
    }
  }
}
