import 'package:flutter/material.dart';
import 'package:fountaine/constants/routes.dart';
import 'package:fountaine/services/auth/auth_service.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Column(
        children: [
          const Text(
            "We've sent you an email verification. Please open it to verify your account",
          ),
          const Text(
            'If you have not received a verification email yet, press the button below',
          ),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().sendEmailVerification();
            },
            child: const Text('Send email verification'),
          ),
          TextButton(
            onPressed: () async {
              await AuthService.firebase().logout();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(registerRoute, (Route) => false);
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }
}
