// lib/screens/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountaine/constants/routes.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF7A7A7A);

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog first
              try {
                await ref.read(authProvider.notifier).logout();
              } catch (e) {
                // ignore errors so app won't crash if something weird
              }
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (r) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _primary,
                ),
              ),
            ),
            if (showArrow)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: _primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _primary,
                ),
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 18, color: _primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20 * s,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_back,
                        color: _primary,
                        size: 20 * s,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20 * s,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 40 * s),
                ],
              ),

              SizedBox(height: 24 * s),

              // Account Settings
              Text(
                'Account Setting',
                style: TextStyle(
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              SizedBox(height: 12 * s),

              // NAVIGATE to real ProfileScreen (reads auth_provider)
              _buildTile(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () => Navigator.pushNamed(context, Routes.profile),
              ),

              _buildTile(
                icon: Icons.language,
                label: 'Change language',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon')),
                  );
                },
              ),
              _buildTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feature coming soon')),
                  );
                },
              ),

              SizedBox(height: 24 * s),

              // Legal Section
              Text(
                'Legal',
                style: TextStyle(
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              SizedBox(height: 12 * s),

              _buildLinkTile(
                icon: Icons.article_outlined,
                label: 'Terms and Condition',
                onTap: () {},
              ),
              _buildLinkTile(
                icon: Icons.security_outlined,
                label: 'Privacy policy',
                onTap: () {},
              ),
              _buildLinkTile(
                icon: Icons.info_outline,
                label: 'Help',
                onTap: () {},
              ),

              const Spacer(),

              // Logout Button
              Center(
                child: OutlinedButton(
                  onPressed: () => _confirmLogout(context, ref),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _primary.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 60 * s,
                      vertical: 14 * s,
                    ),
                  ),
                  child: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16 * s,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12 * s),

              // App Version
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 13 * s, color: _muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
