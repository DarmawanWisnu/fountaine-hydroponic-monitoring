import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountaine/app/routes.dart';

void main() {
  runApp(const ProviderScope(child: FountaineApp()));
}

class FountaineApp extends StatelessWidget {
  const FountaineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fountaine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF65FFF0), // warna utama
          brightness: Brightness.light,
        ),
        useMaterial3: true, // aktifin style Material 3
      ),
      initialRoute: Routes.login,
      routes: Routes.routes,
    );
  }
}
