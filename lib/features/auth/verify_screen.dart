import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fountaine/app/routes.dart';
import 'package:fountaine/providers/provider/auth_provider.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF555555);

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  bool _isWorking = false;
  bool _showTips = false;

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openMailApp() async {
    final uri = Uri.parse('https://mail.google.com/');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _showSnack('Gagal membuka email. Coba buka manual ya.');
    } catch (e) {
      _showSnack('Gagal membuka email. Error: $e');
    }
  }

  Future<void> _copyEmail(String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    _showSnack('Email disalin ke clipboard');
  }

  Future<void> _resend() async {
    setState(() => _isWorking = true);
    try {
      await ref.read(authProvider.notifier).sendEmailVerification();
      _showSnack('Email verifikasi dikirim ulang. Cek inbox/spam ya.');
    } catch (e) {
      _showSnack('Gagal kirim verifikasi: $e');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isWorking = true);
    try {
      await ref.read(authProvider.notifier).reloadUser();
      final user = ref.read(authProvider);
      if (user != null && user.emailVerified) {
        if (!mounted) return;
        _showSnack('Verifikasi terdeteksi. Selamat!');
        Navigator.pushReplacementNamed(context, Routes.home);
        return;
      }
      _showSnack('Belum terverifikasi. Coba lagi beberapa detik nanti.');
    } catch (e) {
      _showSnack('Gagal memuat status: $e');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isWorking = true);
    try {
      await ref.read(authProvider.notifier).signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
    } catch (e) {
      _showSnack('Gagal keluar: $e');
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 375.0;
    final user = ref.watch(authProvider); // User? dari StateNotifier
    final email = user?.email ?? '—';

    return Scaffold(
      backgroundColor: VerifyScreen._bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: back & logout
              Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: Padding(
                        padding: EdgeInsets.all(8 * s),
                        child: Icon(
                          Icons.arrow_back,
                          color: VerifyScreen._primary,
                          size: 20 * s,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isWorking ? null : _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Banner (logo + title)
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: 22 * s,
                  horizontal: 16 * s,
                ),
                decoration: BoxDecoration(
                  color: VerifyScreen._primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // icon box
                    Container(
                      padding: EdgeInsets.all(10 * s),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset(
                        'assets/images/app_name.png',
                        height: 36 * s,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fountaine',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Email Verification',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Title
              Center(
                child: Text(
                  'Welcome to Fountaine',
                  style: TextStyle(
                    fontSize: 20 * s,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Description + user email
              Center(
                child: Text(
                  'Terima kasih sudah mendaftar.\n'
                  'Silakan verifikasi alamat email berikut:\n$email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * s,
                    color: VerifyScreen._muted,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Action chips
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.copy, size: 18),
                    label: const Text('Salin Email'),
                    onPressed: email == '—' ? null : () => _copyEmail(email),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.mail_outline, size: 18),
                    label: const Text('Buka Email'),
                    onPressed: _isWorking ? null : _openMailApp,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Tombol utama: Kirim Ulang & Muat Ulang
              SizedBox(
                height: 52 * s,
                child: ElevatedButton.icon(
                  onPressed: _isWorking ? null : _resend,
                  icon: const Icon(Icons.send_outlined, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VerifyScreen._primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14 * s),
                    ),
                    elevation: 6,
                  ),
                  label: _isWorking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Kirim Ulang Email Verifikasi',
                          style: TextStyle(
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _isWorking ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang Status'),
              ),

              const SizedBox(height: 16),

              // Tips expandable
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * s,
                    vertical: 12 * s,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _showTips = !_showTips),
                        child: Row(
                          children: [
                            Icon(
                              _showTips ? Icons.expand_less : Icons.expand_more,
                              color: VerifyScreen._muted,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Butuh bantuan?',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (_showTips) ...[
                        const SizedBox(height: 8),
                        Text(
                          '• Cek folder Spam/Promotions.\n'
                          '• Tunggu 1–2 menit lalu tekan "Muat Ulang Status".\n'
                          '• Pastikan email benar.\n'
                          '• Coba "Kirim Ulang Email Verifikasi".',
                          style: TextStyle(
                            fontSize: 13 * s,
                            color: VerifyScreen._muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Back to Login
              Center(
                child: TextButton(
                  onPressed: _isWorking
                      ? null
                      : () => Navigator.pushReplacementNamed(
                          context,
                          Routes.login,
                        ),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                      color: VerifyScreen._primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
