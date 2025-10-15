import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountaine/app/routes.dart';
import 'package:fountaine/providers/provider/auth_provider.dart';
import 'package:fountaine/utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // --- Controller input ---
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();

  // --- Form key untuk validasi ---
  final _formKey = GlobalKey<FormState>();

  // --- State UI ---
  bool _loading = false; // disable tombol saat submit
  bool _obscure = true; // toggle visibilitas password

  // --- Palet warna ---
  static const Color _bgColor = Color(0xFFF6FBF6);
  static const Color _primaryColor = Color(0xFF154B2E);
  static const Color _mutedText = Color(0xFF6B6B6B);

  // Submit: validasi -> panggil AuthProvider -> ke Home
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final pass = _pwCtrl.text;

    try {
      // Pakai notifier dari authProvider
      final auth = ref.read(authProvider.notifier);
      await auth.signIn(email: email, password: pass);

      if (!mounted) return;

      // Sukses login -> ke Home.
      Navigator.pushReplacementNamed(context, Routes.home);
    } catch (e) {
      // Error singkat
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang sesuai tema
      backgroundColor: _bgColor,

      // SafeArea + scroll agar aman saat keyboard muncul
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),

          // Form dengan validator
          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Tombol Back =====
                Align(
                  alignment: Alignment.centerLeft,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: _primaryColor),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ===== Judul Halaman =====
                const Text(
                  'Hello Again!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Welcome Back You've Been Missed!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: _mutedText),
                ),

                const SizedBox(height: 36),

                // ===== Label Email =====
                const Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 8),

                // ===== Field Email + Validator =====
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'example@email.com',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                    validator: (v) => Validators.email(v),
                    onFieldSubmitted: (_) => _loading ? null : _submit(),
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Label Password =====
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 8),

                // ===== Field Password + Toggle Eye + Validator =====
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pwCtrl,
                          obscureText: _obscure,
                          decoration: const InputDecoration(
                            hintText: 'Enter your password',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          validator: (v) => Validators.password(v),
                          onFieldSubmitted: (_) => _loading ? null : _submit(),
                        ),
                      ),
                      // Icon toggle show/hide password
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          splashRadius: 22,
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            color: _primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ===== Link Lupa Password =====
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, Routes.forgotPassword),
                    child: Text(
                      'Recovery Password',
                      style: TextStyle(fontSize: 13, color: _mutedText),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ===== Tombol Sign In dengan animasi hover/press =====
                _HoverScaleButton(
                  height: 56,
                  radius: 40,
                  backgroundColor: _primaryColor,
                  shadowColor: const Color(0x33154B2E), // soft green shadow
                  pressedScale: 0.985,
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // ===== Tombol Google =====
                _HoverScaleButton(
                  height: 56,
                  radius: 40,
                  backgroundColor: Colors.white,
                  borderColor: Colors.transparent,
                  shadowColor: const Color(0x1A000000), // subtle shadow
                  pressedScale: 0.985,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pastikan asset ini ada di pubspec.yaml
                      Image.asset('assets/images/google_logo.png', height: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    // TODO: Implement Google Sign-In (google_sign_in + FirebaseAuth credential)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Sign-In belum diimplementasi'),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ===== Footer ke Register =====
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don’t Have An Account? ",
                      style: TextStyle(fontSize: 13, color: _mutedText),
                      children: [
                        TextSpan(
                          text: "Sign Up For Free",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primaryColor,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, Routes.register);
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable button: animasi hover (web/desktop) + press (mobile) + shadow.
/// Dipakai untuk tombol Sign In & Google agar konsisten dan enak dilihat.
class _HoverScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double height;
  final double radius;
  final Color backgroundColor;
  final Color? borderColor;
  final Color shadowColor;
  final double pressedScale;

  const _HoverScaleButton({
    required this.child,
    required this.onPressed,
    required this.height,
    required this.radius,
    required this.backgroundColor,
    required this.shadowColor,
    this.borderColor,
    this.pressedScale = 0.98,
  });

  @override
  State<_HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<_HoverScaleButton> {
  bool _hovered = false;
  bool _pressed = false;

  double get _scale => _pressed ? widget.pressedScale : (_hovered ? 1.01 : 1.0);
  double get _elevation => _pressed ? 2 : (_hovered ? 8 : 4);

  @override
  Widget build(BuildContext context) {
    final border = widget.borderColor ?? Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.onPressed == null
                  ? widget.backgroundColor.withOpacity(0.6)
                  : widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: border),
              boxShadow: [
                BoxShadow(
                  color: widget.shadowColor,
                  blurRadius: _elevation + 6,
                  spreadRadius: 0,
                  offset: Offset(0, _elevation),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: widget.onPressed == null ? Colors.white70 : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
