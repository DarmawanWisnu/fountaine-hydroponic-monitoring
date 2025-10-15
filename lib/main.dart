// lib/main.dart
// Entry point utama aplikasi Fountaine.
// Udah termasuk Firebase init, Riverpod ProviderScope, AuthGate, dan routes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

// Import file konfigurasi Firebase (hasil flutterfire configure)
import 'package:fountaine/firebase_options.dart';

// Import routes + AuthGate
import 'package:fountaine/app/routes.dart';

// [ENV] Tambahkan dotenv untuk load variabel dari file .env
import 'package:flutter_dotenv/flutter_dotenv.dart';

// [APP CHECK] Import Firebase App Check untuk proteksi Play Integrity
import 'package:firebase_app_check/firebase_app_check.dart';

// [ENV] (hapus import firebase_options_env.dart karena sudah digabung ke firebase_options.dart)

void main() async {
  // Pastikan binding Flutter siap sebelum init Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // [ENV] Muat file .env (pastikan .env sudah ada & di-.gitignore)
  await dotenv.load(fileName: ".env");

  // Inisialisasi Firebase dengan konfigurasi platform spesifik
  // [ENV] Gunakan DefaultFirebaseOptions
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // [APP CHECK] Aktifkan App Check dengan Play Integrity
  // Gunakan ini setelah Firebase.initializeApp() agar token valid

  // === Kalau udah publish ===
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.playIntegrity,
  // );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  // Jalankan aplikasi dengan Riverpod ProviderScope
  runApp(const ProviderScope(child: FountaineApp()));
}

class FountaineApp extends StatelessWidget {
  const FountaineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fountaine',
      debugShowCheckedModeBanner: false,

      // ==== THEME ====
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF65FFF0), // warna utama aplikasi
          brightness: Brightness.light,
        ),
        useMaterial3: true, // aktifin style Material 3
      ),
      initialRoute: Routes.login,

      // ==== ROUTING ====
      // AuthGate akan otomatis arahkan user ke:
      // - LoginScreen kalau belum login
      // - VerifyScreen kalau belum verifikasi email
      // - HomeScreen kalau sudah login & verified
      // home: const AuthGate(),

      // Daftar route manual, biar bisa pakai Navigator.pushNamed()
      routes: Routes.routes,
    );
  }
}
