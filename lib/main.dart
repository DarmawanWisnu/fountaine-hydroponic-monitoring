// lib/main.dart
// Entry point utama aplikasi Fountaine.
// Sudah termasuk: Firebase init, App Check, dotenv, Riverpod ProviderScope,
// AuthGate, Routes table, dan onGenerateRoute.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Konfigurasi Firebase (hasil `flutterfire configure`)
import 'package:fountaine/firebase_options.dart';

// Routes + AuthGate + onGenerateRoute
import 'package:fountaine/app/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ENV (.env harus ada & masuk .gitignore)
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[dotenv] Loaded successfully');
  } catch (e) {
    // kalau .env ga ada, jangan bikin crash
    debugPrint('[dotenv] Warning: failed to load .env → $e');
  }

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // App Check (pakai debug di dev, Play Integrity saat rilis)
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode
        ? AndroidProvider.debug
        : AndroidProvider.playIntegrity,
  );

  runApp(const ProviderScope(child: FountaineApp()));
}

class FountaineApp extends StatelessWidget {
  const FountaineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fountaine',
      debugShowCheckedModeBanner: false,

      // THEME
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF65FFF0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute:
          Routes.notifications, // untuk testing, nanti ganti ke '/' (AuthGate)
      // ROUTING
      // AuthGate akan otomatis arahkan:
      // - LoginScreen (belum login)
      // - VerifyScreen (belum verif email)
      // - HomeScreen (sudah login & verif)
      // home: const AuthGate(),

      // Table routes (tanpa args)
      routes: Routes.routes,

      // Route generator (untuk halaman yang butuh arguments: Monitor/History, dll)
      onGenerateRoute: onGenerateRoute,
    );
  }
}
