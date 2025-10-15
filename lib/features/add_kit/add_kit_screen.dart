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
      // asumsi: kitListProvider.notifier memiliki method addKit(Kit)
      await ref.read(kitListProvider.notifier).addKit(Kit(id: id, name: name));

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Sukses'),
          content: const Text('Kit berhasil ditambahkan'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      // kembali ke home
      Navigator.pushReplacementNamed(context, Routes.home);
    } catch (e) {
      // tampilkan error sederhana
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Gagal'),
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
                // back
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
                  'Add Kit!',
                  style: TextStyle(
                    fontSize: 32 * s,
                    fontWeight: FontWeight.w800,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6 * s),
                Text(
                  "Please Add Your Kit To Monitor!",
                  style: TextStyle(fontSize: 14 * s, color: _mutedText),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 28 * s),

                // Kit Name
                Text(
                  'Kit Name',
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
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Hydroponic Monitoring System',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20 * s,
                        vertical: 18 * s,
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama kit harus diisi'
                        : null,
                  ),
                ),

                SizedBox(height: 18 * s),

                // Kit ID
                Text(
                  'Kit ID',
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
                  child: TextFormField(
                    controller: _idCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. SUF-UINJKT-HM-F2000',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20 * s,
                        vertical: 18 * s,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'ID Kit harus diisi';
                      }
                      if (v.trim().length < 5) return 'ID Kit terlalu pendek';
                      return null;
                    },
                  ),
                ),

                SizedBox(height: 28 * s),

                // Save button
                SizedBox(
                  height: 56 * s,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
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
                            'Save',
                            style: TextStyle(
                              fontSize: 18 * s,
                              fontWeight: FontWeight.w700,
                            ),
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
