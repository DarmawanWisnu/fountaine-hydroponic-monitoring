import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fountaine/app/routes.dart';
import 'package:fountaine/providers/provider/auth_provider.dart';
import 'package:fountaine/providers/provider/kit_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final kits = ref.watch(kitListProvider);

    // --- Mapping field Firebase User ---
    final email = user?.email ?? '-';
    final uid = user?.uid ?? '-';
    final inferredName =
        (user?.displayName != null && user!.displayName!.trim().isNotEmpty)
        ? user.displayName!.trim()
        : (email != '-' ? email.split('@').first : 'Profile');
    final name = inferredName;

    // --- Ambil kit info ---
    final kitName = kits.isNotEmpty ? kits.first.name : 'Your Kit Name';
    final kitId = kits.isNotEmpty ? kits.first.id : 'SUF-XXXX-XXXX';

    final s = MediaQuery.of(context).size.width / 375.0;

    Future<void> seedDummy() async {
      if (!kDebugMode) return;
      try {
        if (kits.isEmpty) {
          await ref
              .read(kitListProvider.notifier)
              .addKit(
                Kit(
                  id: 'SUF-UINJKT-HM-F2000',
                  name: 'Hydroponic Monitoring System',
                ),
              );
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dummy kit ditambahkan ✅')),
          );
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              Row(
                children: [
                  _pillIconButton(
                    s: s,
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
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

              SizedBox(height: 24 * s),

              // ===== Avatar + name =====
              Center(
                child: Column(
                  children: [
                    // ring avatar modern
                    Container(
                      padding: EdgeInsets.all(3 * s),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E6C45), Color(0xFF154B2E)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16 * s,
                            offset: Offset(0, 8 * s),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46 * s,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 42 * s,
                          backgroundColor: _primary,
                          child: Icon(
                            Icons.person,
                            size: 46 * s,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * s),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 18 * s,
                        fontWeight: FontWeight.w800,
                        color: _primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (email != '-')
                      Padding(
                        padding: EdgeInsets.only(top: 4 * s),
                        child: Text(
                          email,
                          style: TextStyle(
                            fontSize: 13 * s,
                            color: _muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              SizedBox(height: 22 * s),

              // ===== Quick kit badge =====
              _kitBadge(kitName, s),

              SizedBox(height: 14 * s),

              // ===== Info Card =====
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18 * s),
                  border: Border.all(color: const Color(0xFFE8EEE9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 12 * s,
                      offset: Offset(0, 6 * s),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoTile(
                      s: s,
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: uid,
                    ),
                    _divider(s),
                    _infoTile(
                      s: s,
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                    ),
                    _divider(s),
                    _infoTile(
                      s: s,
                      icon: Icons.view_in_ar_outlined,
                      label: 'Kit Name',
                      value: kitName,
                    ),
                    _divider(s),
                    _infoTile(
                      s: s,
                      icon: Icons.qr_code_2_outlined,
                      label: 'Kit ID',
                      value: kitId,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24 * s),

              // ===== Actions =====
              _primaryButton(
                s: s,
                label: 'Edit Profile',
                onTap: () => Navigator.pushNamed(context, Routes.settings),
              ),
              SizedBox(height: 12 * s),
              _ghostButton(
                s: s,
                label: 'Logout',
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      Routes.login,
                      (r) => false,
                    );
                  }
                },
              ),

              const SizedBox(height: 10),

              if (kDebugMode)
                Center(
                  child: TextButton(
                    onPressed: seedDummy,
                    child: const Text(
                      'Seed dummy kit (debug)',
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

  // ---------- widgets kecil ----------

  Widget _divider(double s) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 16 * s),
    child: Divider(height: 1, color: const Color(0xFFF0F4F1)),
  );

  Widget _pillIconButton({
    required double s,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22 * s),
      child: InkWell(
        borderRadius: BorderRadius.circular(22 * s),
        onTap: onTap,
        child: Container(
          height: 40 * s,
          width: 40 * s,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10 * s,
                offset: Offset(0, 6 * s),
              ),
            ],
          ),
          child: Icon(icon, color: _primary, size: 20 * s),
        ),
      ),
    );
  }

  Widget _kitBadge(String kitName, double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(color: const Color(0xFFE8EEE9)),
      ),
      child: Row(
        children: [
          Container(
            height: 10 * s,
            width: 10 * s,
            decoration: BoxDecoration(
              color: Colors.greenAccent.shade400,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Text(
              kitName,
              style: TextStyle(
                color: _primary,
                fontWeight: FontWeight.w700,
                fontSize: 14 * s,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FFF3),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFF00C853)),
            ),
            child: Text(
              'ACTIVE',
              style: TextStyle(
                color: const Color(0xFF00A84A),
                fontSize: 11 * s,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required double s,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
      child: Row(
        children: [
          Container(
            height: 40 * s,
            width: 40 * s,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F4),
              borderRadius: BorderRadius.circular(12 * s),
            ),
            child: Icon(icon, color: _primary, size: 22 * s),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12 * s, color: _muted),
                ),
                SizedBox(height: 4 * s),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w800,
                    color: _primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Edit Profile & Logout buttons
  Widget _primaryButton({
    required double s,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56 * s,
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * s),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E6C45), Color(0xFF154B2E)],
            ),
            borderRadius: BorderRadius.circular(16 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16 * s,
                offset: Offset(0, 6 * s),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_rounded, color: Colors.white),
                SizedBox(width: 10 * s),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghostButton({
    required double s,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50 * s,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: _primary.withOpacity(0.18)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14 * s),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16 * s,
            fontWeight: FontWeight.w800,
            color: _primary,
          ),
        ),
      ),
    );
  }
}
