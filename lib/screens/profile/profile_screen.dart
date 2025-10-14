// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountaine/constants/routes.dart';
import 'package:fountaine/providers/auth_provider.dart';
import 'package:fountaine/providers/kit_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider); // User? (bisa null)
    final kits = ref.watch(kitListProvider); // List<Kit>

    // fallback jika belum ada user
    final name = user?.name ?? 'Profile';
    final email = user?.email ?? 'user@example.com';
    final kitName = kits.isNotEmpty ? kits.first.name : 'Your Kit Name';
    final kitId = kits.isNotEmpty ? kits.first.id : 'SUF-XXXX-XXXX';

    final s = MediaQuery.of(context).size.width / 375.0;

    Future<void> seedDummy() async {
      // fungsi debug untuk menambahkan data dummy langsung dari UI
      try {
        // hanya register jika belum ada user
        if (user == null) {
          await ref
              .read(authProvider.notifier)
              .register(
                name: 'Wisnu Darmawan',
                email: 'aizen.emu@gmail.com',
                password: 'password123',
                location: 'Tangerang, Banten',
              );
        }

        // tambahkan kit dummy jika belum ada
        if (kits.isEmpty) {
          await ref
              .read(kitListProvider.notifier)
              .addKit(
                Kit(
                  id: 'SUF-UINJKT-HM-F2000',
                  name: 'Hydrophonic Monitoring System',
                ),
              );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dummy data seeded ✅')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Seed failed: $e')));
        }
      }
    }

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
                        'Profile',
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

              SizedBox(height: 32 * s),

              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48 * s,
                  backgroundColor: _primary,
                  child: Icon(Icons.person, size: 48 * s, color: Colors.white),
                ),
              ),

              SizedBox(height: 12 * s),

              Center(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ),

              SizedBox(height: 24 * s),

              // Info Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20 * s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18 * s),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('User ID', email, s),
                    Divider(height: 22 * s, thickness: 0.8, color: _bg),
                    _infoRow('Kit Name', kitName, s),
                    Divider(height: 22 * s, thickness: 0.8, color: _bg),
                    _infoRow('Kit ID', kitId, s),
                  ],
                ),
              ),

              const Spacer(),

              // Edit Profile
              SizedBox(
                width: double.infinity,
                height: 52 * s,
                child: ElevatedButton(
                  onPressed: () {
                    // jika mau, bisa arahkan ke screen edit (belum dibuat)
                    Navigator.pushNamed(
                      context,
                      Routes.settings,
                    ); // placeholder
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * s),
                    ),
                  ),
                  child: Text(
                    'Edit Profile',
                    style: TextStyle(
                      fontSize: 16 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 12 * s),

              // Logout button
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.login,
                      (r) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _primary.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14 * s),
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
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // debug seed button (kecil, cuma buat testing)
              Center(
                child: TextButton(
                  onPressed: seedDummy,
                  child: const Text(
                    'Seed dummy data (debug)',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ),

              SizedBox(height: 8 * s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14 * s, color: _muted),
        ),
        SizedBox(height: 6 * s),
        Text(
          value,
          style: TextStyle(
            fontSize: 16 * s,
            fontWeight: FontWeight.w700,
            color: _primary,
          ),
        ),
      ],
    );
  }
}
