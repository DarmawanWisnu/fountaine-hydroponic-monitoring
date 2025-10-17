import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fountaine/app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
      _timer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, Routes.login);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF00E676);
    final s = MediaQuery.of(context).size.width / 375.0;
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 🌿 Karakter di bawah
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Image.asset(
                  'assets/images/welcome_no_bg.png',
                  width: screen.width,
                  height: screen.height * 0.58,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),

            // 🌱 Logo dan teks di atas karakter
            Positioned(
              top: screen.height * 0.08,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo daun
                    Image.asset(
                      'assets/images/logo.png',
                      width: 75 * s,
                      height: 75 * s,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 22 * s),

                    // Teks “Fountaine”
                    Text(
                      'Fountaine',
                      style: TextStyle(
                        fontSize: 36 * s,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 22 * s),

                    // Teks “Loading...”
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 20 * s,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
