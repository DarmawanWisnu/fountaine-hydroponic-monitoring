import 'package:flutter/material.dart';
import 'package:fountaine/screens/add_kit/add_kit_screen.dart';
import 'package:fountaine/screens/auth/login_screen.dart';
import 'package:fountaine/screens/auth/register_screen.dart';
import 'package:fountaine/screens/auth/verify_screen.dart';
import 'package:fountaine/screens/history/history_screen.dart';
import 'package:fountaine/screens/home/home_screen.dart';
import 'package:fountaine/screens/monitor/monitor_screen.dart';
import 'package:fountaine/screens/settings/settings_screen.dart';
import 'package:fountaine/screens/auth/forgot_password_screen.dart';
import 'package:fountaine/screens/profile/profile_screen.dart';
import 'package:fountaine/screens/splash_screen.dart';
// import 'package:fountaine/screens/auth/error_screen.dart';

class Routes {
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
  // static const error = '/error';

  static final routes = <String, WidgetBuilder>{
    // splash: (c) => const SplashScreen(),
    login: (c) => const LoginScreen(),
    register: (c) => const RegisterScreen(),
    verify: (c) => const VerifyScreen(),
    home: (c) => const HomeScreen(),
    monitor: (c) => const MonitorScreen(),
    history: (c) => const HistoryScreen(),
    addKit: (c) => const AddKitScreen(),
    settings: (c) => const SettingsScreen(),
    forgotPassword: (c) => const ForgotPasswordScreen(),
    profile: (c) => const ProfileScreen(),
  };
}
