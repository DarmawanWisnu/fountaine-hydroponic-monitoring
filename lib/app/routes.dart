import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:fountaine/providers/provider/auth_provider.dart';

/// ---------------------------------------------------------------------------
///  ARGUMENTS CLASS
/// ---------------------------------------------------------------------------
class MonitorArgs {
  final String kitId;
  final bool simulated;
  const MonitorArgs({required this.kitId, this.simulated = false});
}

class HistoryArgs {
  final String kitId;
  const HistoryArgs({required this.kitId});
}

/// ---------------------------------------------------------------------------
///  AUTH GATE
/// ---------------------------------------------------------------------------
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }
        if (!(user.emailVerified)) {
          return const VerifyScreen();
        }
        return const HomeScreen();
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Terjadi kesalahan: $e'))),
    );
  }
}

/// ---------------------------------------------------------------------------
///  ROUTE NAME & TABLE
/// ---------------------------------------------------------------------------
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
    login: (c) => const LoginScreen(),
    register: (c) => const RegisterScreen(),
    verify: (c) => const VerifyScreen(),
    home: (c) => const HomeScreen(),
    // monitor: (c) => const MonitorScreen(),
    notifications: (c) => const NotificationScreen(),
    // history: (c) => const HistoryScreen(),
    addKit: (c) => const AddKitScreen(),
    settings: (c) => const SettingsScreen(),
    forgotPassword: (c) => const ForgotPasswordScreen(),
    profile: (c) => const ProfileScreen(),
  };
}

/// ---------------------------------------------------------------------------
///  ON GENERATE ROUTE
/// ---------------------------------------------------------------------------
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case Routes.monitor:
      final args = settings.arguments is MonitorArgs
          ? settings.arguments as MonitorArgs
          : const MonitorArgs(kitId: 'devkit-01'); //
      return MaterialPageRoute(
        builder: (_) =>
            MonitorScreen(kitId: args.kitId, simulated: args.simulated),
        settings: settings,
      );

    case Routes.history:
      final args = settings.arguments is HistoryArgs
          ? settings.arguments as HistoryArgs
          : const HistoryArgs(kitId: 'devkit-01');
      return MaterialPageRoute(
        builder: (_) => HistoryScreen(kitId: args.kitId),
        settings: settings,
      );

    default:
      final builder = Routes.routes[settings.name];
      if (builder != null) {
        return MaterialPageRoute(builder: builder, settings: settings);
      }
      return MaterialPageRoute(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('Route tidak dikenal'))),
        settings: settings,
      );
  }
}
