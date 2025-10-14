// lib/providers/auth/firebase_auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_services.dart';
import 'auth_user.dart';

class AuthState {
  final AuthUser? user;
  final bool loading;
  final String? error;
  const AuthState({this.user, this.loading = false, this.error});
}

class FirebaseAuthNotifier extends StateNotifier<AuthState> {
  final AuthService _service;
  FirebaseAuthNotifier(this._service) : super(const AuthState()) {
    // listen to auth state changes
    _service.authStateChanges().listen((u) {
      state = AuthState(user: u);
    });
  }

  Future<void> signIn(String email, String password) async {
    state = AuthState(loading: true);
    try {
      final user = await _service.signIn(email: email, password: password);
      state = AuthState(user: user);
    } catch (e) {
      state = AuthState(error: e.toString());
      rethrow;
    }
  }

  Future<void> register(String email, String password) async {
    state = AuthState(loading: true);
    try {
      final user = await _service.register(email: email, password: password);
      state = AuthState(user: user);
    } catch (e) {
      state = AuthState(error: e.toString());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AuthState(user: null);
  }

  Future<void> reload() async {
    try {
      await _service.reloadUser();
      final u = _service.currentUser;
      state = AuthState(user: u);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  AuthUser? get currentUser => _service.currentUser;
}

// provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final firebaseAuthProvider =
    StateNotifierProvider<FirebaseAuthNotifier, AuthState>(
      (ref) => FirebaseAuthNotifier(ref.read(authServiceProvider)),
    );
