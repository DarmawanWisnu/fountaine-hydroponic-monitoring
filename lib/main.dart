import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fountaine/firebase_options.dart';
import 'package:fountaine/app/routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('[dotenv] Loaded successfully');
  } catch (e) {
    debugPrint('[dotenv] Warning: failed to load .env → $e');
  }

  // Firebase init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      routes: Routes.routes,

      // Route generator (untuk halaman yang butuh arguments: Monitor/History, dll)
      onGenerateRoute: onGenerateRoute,
    );
  }
}
