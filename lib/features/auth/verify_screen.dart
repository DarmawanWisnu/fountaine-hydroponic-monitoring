import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fountaine/app/routes.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF555555);

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final String dummyEmail = 'aizen.emu@gmail.com';
  final String dummyVerifyLink =
      'https://skripsi-wisnu.firebaseapp.com/__/auth/action?mode=verifyEmail&oobCode=06Oy62fw4rCEoolpeC4rIMoVfiVfGZE0sExVNt-siBLAAAAGZeinfjA&apiKey=AlzaSyBhmdAmWirVhs8Btw_UTZDUuLgZl2CDUII&lang=en';

  bool _showFullLink = false;
  bool _isLaunching = false;

  Future<void> _launchEmailLink(String url) async {
    setState(() => _isLaunching = true);
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        _showSnack('Gagal membuka link. Coba salin link dulu.');
      }
    } catch (e) {
      _showSnack('Gagal membuka link. Error: $e');
    } finally {
      if (mounted) setState(() => _isLaunching = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Link disalin ke clipboard');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _shorten(String url) {
    if (_showFullLink || url.length <= 80) return url;
    return '${url.substring(0, 72)}...';
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: VerifyScreen._bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: back button
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Fountaine',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
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

              // Description
              Center(
                child: Text(
                  'Thank you for signing up. Please verify your email address, $dummyEmail, by clicking the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * s,
                    color: VerifyScreen._muted,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                height: 52 * s,
                child: ElevatedButton(
                  onPressed: _isLaunching
                      ? null
                      : () => _launchEmailLink(dummyVerifyLink),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VerifyScreen._primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14 * s),
                    ),
                    elevation: 6,
                  ),
                  child: _isLaunching
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 10 * s),
                            Text(
                              'Verify your email',
                              style: TextStyle(
                                fontSize: 16 * s,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Link box
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
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _shorten(dummyVerifyLink),
                              style: TextStyle(
                                fontSize: 13 * s,
                                color: Colors.blue[800],
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: _showFullLink ? null : 2,
                              onTap: () => _launchEmailLink(dummyVerifyLink),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    _copyToClipboard(dummyVerifyLink),
                                icon: Icon(
                                  Icons.copy,
                                  size: 20 * s,
                                  color: VerifyScreen._muted,
                                ),
                                tooltip: 'Salin link',
                              ),
                              IconButton(
                                onPressed: () => setState(
                                  () => _showFullLink = !_showFullLink,
                                ),
                                icon: Icon(
                                  _showFullLink
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 20 * s,
                                  color: VerifyScreen._muted,
                                ),
                                tooltip: _showFullLink
                                    ? 'Sembunyikan'
                                    : 'Tampilkan penuh',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Follow this link to verify your email address.',
                          style: TextStyle(
                            fontSize: 12 * s,
                            color: VerifyScreen._muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Support text
              Center(
                child: Text(
                  'If you are having any issues with your account, please don’t hesitate to contact Customer Services.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13 * s,
                    color: VerifyScreen._muted,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Footer signature
              Center(
                child: Column(
                  children: [
                    Text(
                      'Thanks!',
                      style: TextStyle(
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w600,
                        color: VerifyScreen._muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Fountaine',
                      style: TextStyle(
                        fontSize: 16 * s,
                        fontWeight: FontWeight.w800,
                        color: VerifyScreen._primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your Fountaine-app team',
                      style: TextStyle(
                        fontSize: 13 * s,
                        color: VerifyScreen._muted,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Back to login
              Center(
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, Routes.login),
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
