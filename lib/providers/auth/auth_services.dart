// lib/providers/auth/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'auth_user.dart';
import 'auth_exceptions.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  AuthUser? _toAuthUser(fb.User? u) {
    if (u == null) return null;
    return AuthUser(uid: u.uid, email: u.email, emailVerified: u.emailVerified);
  }

  // current user
  AuthUser? get currentUser => _toAuthUser(_auth.currentUser);

  // stream of auth state changes
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(_toAuthUser);
  }

  // sign in
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAuthUser(cred.user);
    } on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw UserNotFoundAuthException('Email atau Password salah');
        case 'wrong-password':
          throw WrongPasswordAuthException('Email atau Password salah');
        case 'invalid-email':
          throw InvalidEmailAuthException('Format email tidak valid');
        default:
          throw GenericAuthException(e.message ?? 'Gagal login');
      }
    } catch (e) {
      throw GenericAuthException(e.toString());
    }
  }

  // register
  Future<AuthUser?> register({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final u = cred.user;
      await u?.sendEmailVerification();
      return _toAuthUser(u);
    } on fb.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw WeakPasswordAuthException('Password terlalu lemah');
        case 'email-already-in-use':
          throw EmailAlreadyInUseAuthException('Email sudah digunakan');
        case 'invalid-email':
          throw InvalidEmailAuthException('Format email tidak valid');
        default:
          throw GenericAuthException(e.message ?? 'Gagal register');
      }
    } catch (e) {
      throw GenericAuthException(e.toString());
    }
  }

  // sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // reload user
  Future<void> reloadUser() async {
    final u = _auth.currentUser;
    if (u == null) throw UserNotLoggedInAuthException();
    await u.reload();
  }
}
