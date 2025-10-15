import 'package:flutter/material.dart';
import 'package:fountaine/features/add_kit/add_kit_screen.dart';
import 'package:fountaine/features/auth/login_screen.dart';
import 'package:fountaine/features/auth/register_screen.dart';
import 'package:fountaine/features/auth/verify_screen.dart';
import 'package:fountaine/features/history/history_screen.dart';
import 'package:fountaine/features/home/home_screen.dart';
import 'package:fountaine/features/monitor/monitor_screen.dart';
import 'package:fountaine/features/settings/settings_screen.dart';
import 'package:fountaine/features/auth/forgot_password_screen.dart';
import 'package:fountaine/features/profile/profile_screen.dart';
import 'package:fountaine/features/notifications/notification_screen.dart';

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
  static const notifications = '/notifications';

  static final routes = <String, WidgetBuilder>{
    // splash: (c) => const SplashScreen(),
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
