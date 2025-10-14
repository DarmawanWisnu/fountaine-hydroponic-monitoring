import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isSending = false;

  // simple email validator
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
    final email = v.trim();
    final regex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!regex.hasMatch(email)) return 'Format email tidak valid';
    return null;
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    // simulate network call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSending = false);

    // show success dialog/snackbar
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Berhasil'),
        content: Text(
          'Link reset password telah dikirim ke ${_emailCtrl.text.trim()}.'
          '\nCek inbox atau folder spam ya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Oke'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isValid = _validateEmail(_emailCtrl.text) == null;

    return Scaffold(
      // nice transparent appbar with back button
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Forgot Password'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe8f5ff), Color(0xFFf7fbff)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: Column(
                children: [
                  // header card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 6,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 22,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(
                                0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_open,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Lupa Password?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Masukkan email yang terdaftar. Kami akan mengirimkan link untuk mereset passwordmu.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // form card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        onChanged: () => setState(() {}),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: InputDecoration(
                                hintText: 'contoh: kamu@domain.com',
                                prefixIcon: const Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                              ),
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),

                            // subtle helper text
                            const Text(
                              'Kami akan mengirimkan instruksi reset password ke email tersebut. Link berlaku 24 jam.',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 18),

                            // action button
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    (_isSending ||
                                        _validateEmail(_emailCtrl.text) != null)
                                    ? null
                                    : _sendResetLink,
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isSending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Icon(Icons.send_outlined, size: 18),
                                          SizedBox(width: 10),
                                          Text('Kirim Link Reset'),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // secondary action
                            TextButton(
                              onPressed: _isSending
                                  ? null
                                  : () {
                                      // contoh: kembali ke login
                                      Navigator.of(context).pop();
                                    },
                              child: const Text('Kembali ke Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // extra tips area
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Jika tidak menerima email, cek folder Spam atau gunakan fitur "Kirim Ulang" setelah beberapa menit.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
