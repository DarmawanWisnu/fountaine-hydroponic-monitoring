// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountaine/constants/routes.dart';
import 'package:fountaine/utils/validators.dart';
import 'package:fountaine/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true; // toggle lihat/tutup password

  static const Color _bgColor = Color(0xFFF6FBF6);
  static const Color _primaryColor = Color(0xFF154B2E);
  static const Color _mutedText = Color(0xFF6B6B6B);

  void _show(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _doRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    final location = _locationCtrl.text.trim();

    setState(() => _loading = true);
    await Future.delayed(
      const Duration(milliseconds: 400),
    ); // simulasi jaringan

    try {
      await ref
          .read(authProvider.notifier)
          .register(name: name, email: email, password: pw, location: location);

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.verify);
    } catch (e) {
      _show('Gagal', e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 28 * s),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20 * s,
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: _primaryColor,
                        size: 20 * s,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                ),

                SizedBox(height: 24 * s),

                // Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32 * s,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6 * s),
                Text(
                  "Let's Create Account Together",
                  style: TextStyle(fontSize: 14 * s, color: _mutedText),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 28 * s),

                // Name
                Text(
                  'Your Name',
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(height: 8 * s),
                _roundedField(
                  controller: _nameCtrl,
                  hint: 'Full name',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama tidak boleh kosong'
                      : null,
                ),

                SizedBox(height: 18 * s),

                // Email
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(height: 8 * s),
                _roundedField(
                  controller: _emailCtrl,
                  hint: 'example@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => Validators.email(v),
                ),

                SizedBox(height: 18 * s),

                // Password (dengan icon mata)
                Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(height: 8 * s),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28 * s),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pwCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20 * s,
                              vertical: 18 * s,
                            ),
                          ),
                          validator: (v) => Validators.password(v),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 12 * s),
                        child: IconButton(
                          splashRadius: 22 * s,
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: _primaryColor,
                            size: 22 * s,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18 * s),

                // Location
                Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                SizedBox(height: 8 * s),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28 * s),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationCtrl,
                          decoration: InputDecoration(
                            hintText: 'Your city',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20 * s,
                              vertical: 18 * s,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Lokasi tidak boleh kosong'
                              : null,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 12 * s),
                        child: Icon(
                          Icons.location_on,
                          color: _primaryColor,
                          size: 22 * s,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 22 * s),

                // Sign Up button
                SizedBox(
                  height: 56 * s,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _doRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40 * s),
                      ),
                      elevation: 4,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18 * s,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: 16 * s),

                // Google Sign-in (dummy)
                SizedBox(
                  height: 56 * s,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: implement Google register / sign-in
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40 * s),
                      ),
                      side: BorderSide(color: Colors.transparent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/google_logo.png',
                          height: 20 * s,
                        ),
                        SizedBox(width: 10 * s),
                        Text(
                          'Sign in with google',
                          style: TextStyle(
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 28 * s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // helper field widget
  Widget _roundedField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
