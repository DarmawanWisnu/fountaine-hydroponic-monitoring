// Service wrapper untuk FirebaseAuth agar logic auth rapi & mudah dites.
import 'package:firebase_auth/firebase_auth.dart';

/// AuthService membungkus [FirebaseAuth] dan menyediakan fungsi yang dipakai UI/Provider.
class AuthService {
  // Instance FirebaseAuth yang diinjeksikan.
  final FirebaseAuth _auth;
  AuthService(this._auth);

  /// Stream perubahan status login (User?).
  /// Dipakai router/provider untuk auto-redirect login/home.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Ambil user saat ini (null kalau belum login).
  User? get currentUser => _auth.currentUser;

  /// Login email & password.
  /// Lempar exception dari FirebaseAuth agar bisa ditangani di UI (snackbar/toast).
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Registrasi email & password.
  /// Biasanya setelah sukses, kirim email verifikasi.
  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Logout user aktif.
  Future<void> signOut() => _auth.signOut();

  /// Kirim email reset password.
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  /// Kirim email verifikasi ke user aktif.
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Reload data user dari server (untuk cek status emailVerified terbaru).
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }
}
