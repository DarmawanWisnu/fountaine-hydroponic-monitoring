import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountaine/app/routes.dart';
import '../../providers/provider/kit_provider.dart';

class AddKitScreen extends ConsumerStatefulWidget {
  const AddKitScreen({super.key});

  @override
  ConsumerState<AddKitScreen> createState() => _AddKitScreenState();
}

class _AddKitScreenState extends ConsumerState<AddKitScreen> {
  final _idCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  static const Color _bgColor = Color(0xFFF6FBF6);
  static const Color _primaryColor = Color(0xFF154B2E);
  static const Color _mutedText = Color(0xFF6B6B6B);

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _idCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    setState(() => _loading = true);

    try {
      await ref.read(kitListProvider.notifier).addKit(Kit(id: id, name: name));

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Sukses 🎉'),
          content: const Text('Kit berhasil ditambahkan'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      Navigator.pushReplacementNamed(context, Routes.home);
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Gagal 😣'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                // back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.maybePop(context),
                      child: Padding(
                        padding: EdgeInsets.all(10 * s),
                        child: Icon(
                          Icons.arrow_back,
                          color: _primaryColor,
                          size: 20 * s,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30 * s),

                // Title
                Text(
                  'Add Kit',
                  style: TextStyle(
                    fontSize: 32 * s,
                    fontWeight: FontWeight.w900,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6 * s),
                Text(
                  "Add your hydroponic kit to start monitoring.",
                  style: TextStyle(fontSize: 14 * s, color: _mutedText),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 36 * s),

                // Input field reusable
                _modernField(
                  s: s,
                  label: "Kit Name",
                  hint: "e.g. Hydroponic Monitoring System",
                  controller: _nameCtrl,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama kit wajib diisi'
                      : null,
                ),
                SizedBox(height: 20 * s),
                _modernField(
                  s: s,
                  label: "Kit ID",
                  hint: "e.g. SUF-UINJKT-HM-F2000",
                  controller: _idCtrl,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'ID Kit wajib diisi';
                    }
                    if (v.trim().length < 5) return 'ID Kit terlalu pendek';
                    return null;
                  },
                ),

                SizedBox(height: 36 * s),

                // Save button modern
                _modernSaveButton(
                  s: s,
                  label: 'Save Kit',
                  loading: _loading,
                  onTap: _loading ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernField({
    required double s,
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15 * s,
            fontWeight: FontWeight.w700,
            color: _primaryColor,
          ),
        ),
        SizedBox(height: 8 * s),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10 * s,
                offset: Offset(0, 4 * s),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _mutedText.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18 * s,
                vertical: 16 * s,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernSaveButton({
    required double s,
    required String label,
    required bool loading,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 56 * s,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16 * s),
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
            child: loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Text(
                        "Saving...",
                        style: TextStyle(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, color: Colors.white),
                      SizedBox(width: 8 * s),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w800,
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
}
