// lib/app/routes.dart
// Router + AuthGate (Riverpod) yang auto-redirect Login / Verify / Home.
// Pakai di MaterialApp: `home: const AuthGate(),` dan `routes: Routes.routes`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// === FEATURES (SESUAI PATH) ===
import 'package:fountaine/features/add_kit/add_kit_screen.dart';
import 'package:fountaine/features/auth/login_screen.dart';
import 'package:fountaine/features/auth/register_screen.dart';
import 'package:fountaine/features/auth/verify_screen.dart';
import 'package:fountaine/features/auth/forgot_password_screen.dart';
import 'package:fountaine/features/history/history_screen.dart';
import 'package:fountaine/features/home/home_screen.dart';
import 'package:fountaine/features/monitor/monitor_screen.dart';
import 'package:fountaine/features/settings/settings_screen.dart';
import 'package:fountaine/features/profile/profile_screen.dart';
import 'package:fountaine/features/notifications/notification_screen.dart';

// === PROVIDER AUTH (SESUAI PATH PUNYAMU) ===
// Pastikan ini meng-ekspos `authStateProvider` (StreamProvider<User?>)
import 'package:fountaine/providers/provider/auth_provider.dart';

/// AuthGate memutuskan tampilan awal berdasarkan status auth:
/// - user == null                    -> LoginScreen
/// - user != null && !emailVerified  -> VerifyScreen
/// - user != null && emailVerified   -> HomeScreen
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // Saat stream mengembalikan User? (bisa null)
      data: (user) {
        if (user == null) {
          // Belum login -> ke Login
          return const LoginScreen();
        }
        if (!(user.emailVerified)) {
          // Sudah login tapi belum verifikasi -> ke Verify
          return const VerifyScreen();
        }
        // Sudah login & verified -> ke Home
        return const HomeScreen();
      },

      // Saat stream loading -> tampilkan splash kecil
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),

      // Saat error -> tampilkan pesan sederhana
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Terjadi kesalahan: $e'))),
    );
  }
}

/// Kumpulan named routes agar gampang `Navigator.pushNamed(...)`
class Routes {
  // Nama route konsisten dengan yang kamu pakai di project
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const verify = '/verify';
  static const home = '/home';
  static const monitor = '/monitor';
  static const history = '/history';
  static const addKit = '/addkit';
  static const settings = '/settings';
  static const forgotPassword = '/forgot_password';
  static const profile = '/profile';
  static const notifications = '/notifications';

  /// Map builder routes. Kamu bebas tambah/ubah kalau perlu.
  static final routes = <String, WidgetBuilder>{
    // splash: (c) => const SplashScreen(), // aktifkan kalau kamu punya
    login: (c) => const LoginScreen(),
    register: (c) => const RegisterScreen(),
    verify: (c) => const VerifyScreen(),
    home: (c) => const HomeScreen(),
    monitor: (c) => const MonitorScreen(),
    notifications: (c) => const NotificationScreen(),
    history: (c) => const HistoryScreen(),
    addKit: (c) => const AddKitScreen(),
    settings: (c) => const SettingsScreen(),
    forgotPassword: (c) => const ForgotPasswordScreen(),
    profile: (c) => const ProfileScreen(),
  };
}
