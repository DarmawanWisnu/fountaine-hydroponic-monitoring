// Riverpod providers untuk Firebase Auth:
// - firebaseAuthProvider        : instance FirebaseAuth
// - authServiceProvider         : wrapper AuthService
// - authStateProvider (Stream)  : stream User? (buat AuthGate)
// - authProvider (StateNotifier): expose method signIn/register/signOut dll

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fountaine/services/auth_services.dart';

// Instance FirebaseAuth global
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// Service pembungkus FirebaseAuth
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.read(firebaseAuthProvider);
  return AuthService(auth);
});

// Stream User? untuk AuthGate
final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.read(authServiceProvider);
  return service.authStateChanges();
});

// -------------------- StateNotifier --------------------

class AuthNotifier extends StateNotifier<User?> {
  final AuthService _service;
  late final Stream<User?> _sub;

  AuthNotifier(this._service) : super(_service.currentUser) {
    // Sinkronkan state dengan authStateChanges supaya real-time
    _sub = _service.authStateChanges();
    // ignore: cancel_subscriptions
    _sub.listen((u) => state = u);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _service.signInWithEmailPassword(email, password);
    state = _service.currentUser; // update state setelah login
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _service.registerWithEmailPassword(email, password);
    await _service.sendEmailVerification();
    state = _service.currentUser;
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = null;
  }

  Future<void> sendPasswordReset(String email) =>
      _service.sendPasswordReset(email);

  Future<void> sendEmailVerification() => _service.sendEmailVerification();

  Future<void> reloadUser() async {
    await _service.reloadUser();
    state = _service.currentUser;
  }
}

// Provider StateNotifier: inilah yang dipakai oleh UI (notifier + state User?)
final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final service = ref.read(authServiceProvider);
  return AuthNotifier(service);
});
