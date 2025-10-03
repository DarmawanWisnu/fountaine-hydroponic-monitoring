import 'package:fountaine/services/auth/auth_user.dart';
import 'package:fountaine/services/auth/auth_provider.dart';
import 'package:fountaine/services/auth/firebase_auth_provider.dart';

class AuthService implements AuthProvider {
  final AuthProvider provider;
  const AuthService(this.provider);

  factory AuthService.firebase() => AuthService(FirebaseAuthProvider());

  @override
  // implement createUser
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) => provider.createUser(email: email, password: password);

  @override
  // implement currentUser
  AuthUser? get currentUser => provider.currentUser;

  @override
  // implement login
  Future<AuthUser> login({required String email, required String password}) =>
      provider.login(email: email, password: password);

  @override
  // implement logout
  Future<void> logout() => provider.logout();

  @override
  // implement sendEmailVerification
  Future<void> sendEmailVerification() => provider.sendEmailVerification();

  @override
  // implement initialize
  Future<void> initialize() => provider.initialize();
}
