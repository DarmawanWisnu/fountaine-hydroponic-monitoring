import 'package:flutter/material.dart';
import 'package:fountaine/constants/routes.dart';

enum AuthErrorType {
  wrongEmail,
  wrongPassword,
  invalidEmail,
  weakPassword,
  unknown,
}

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  final String? assetPath; // path gambar/ilustrasi
  const ErrorScreen({super.key, required this.errorMessage, this.assetPath});

  // mapping dari teks error ke type
  AuthErrorType _mapErrorToType(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('wrong email') || lower.contains('user-not-found')) {
      return AuthErrorType.wrongEmail;
    }
    if (lower.contains('wrong password') ||
        lower.contains('invalid-password')) {
      return AuthErrorType.wrongPassword;
    }
    if (lower.contains('invalid email') || lower.contains('invalid-email')) {
      return AuthErrorType.invalidEmail;
    }
    if (lower.contains('weak password') || lower.contains('weak-password')) {
      return AuthErrorType.weakPassword;
    }
    // fallback: coba deteksi 'password must' dll
    if (lower.contains('must at least') || lower.contains('at least')) {
      return AuthErrorType.weakPassword;
    }
    return AuthErrorType.unknown;
  }

  // Judul singkat yang tampil di UI
  String _titleFor(AuthErrorType t) {
    switch (t) {
      case AuthErrorType.wrongEmail:
        return 'Wrong Email !';
      case AuthErrorType.wrongPassword:
        return 'Wrong Password !';
      case AuthErrorType.invalidEmail:
        return 'Invalid Email !';
      case AuthErrorType.weakPassword:
        return 'Weak Password !';
      case AuthErrorType.unknown:
      default:
        return 'Something went wrong';
    }
  }

  // Deskripsi singkat (optional)
  String _subtitleFor(AuthErrorType t) {
    switch (t) {
      case AuthErrorType.weakPassword:
        return 'Password must at least 6 character';
      default:
        return ''; // kosong supaya nggak tampil kalau ga perlu
    }
  }

  // Tentukan target route saat tombol ditekan
  String _targetRouteFor(AuthErrorType t) {
    // mapping sesuai permintaan:
    // wrong email, wrong password -> sign in
    // invalid email, weak password -> sign up
    switch (t) {
      case AuthErrorType.wrongEmail:
      case AuthErrorType.wrongPassword:
        return Routes.login;
      case AuthErrorType.invalidEmail:
      case AuthErrorType.weakPassword:
        return Routes.register;
      case AuthErrorType.unknown:
      default:
        return Routes.login; // default fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _mapErrorToType(errorMessage);
    final title = _titleFor(type);
    final subtitle = _subtitleFor(type);
    final targetRoute = _targetRouteFor(type);

    final sizeFactor = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 18),
              // back button (bulat)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Icon(Icons.arrow_back)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // ilustrasi
              SizedBox(
                height: 200 * sizeFactor,
                child: Center(
                  child: assetPath != null
                      ? Image.asset(assetPath!, fit: BoxFit.contain)
                      : Image.asset(
                          'assets/images/error_illustration.png',
                          fit: BoxFit.contain,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              // title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              // Try again button
              SizedBox(
                width: double.infinity,
                height: 78 * sizeFactor,
                child: ElevatedButton(
                  onPressed: () {
                    // pindah ke route yang sesuai
                    // gunakan pushReplacement supaya user ga balik ke error screen lagi
                    Navigator.pushReplacementNamed(context, targetRoute);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F4D2E), // hijau gelap
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Try again',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              // debug / message
              const SizedBox(height: 12),
              Text(
                // tampilkan pesan error asli
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
