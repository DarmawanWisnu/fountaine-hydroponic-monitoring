// lib/screens/monitor/monitor_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/kit_provider.dart';

class MonitorScreen extends ConsumerStatefulWidget {
  const MonitorScreen({super.key});
  @override
  ConsumerState<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends ConsumerState<MonitorScreen> {
  Timer? _timer;

  // default: Manual ON (sesuai screenshot kamu)
  bool _manual = true;

  // pilihan kit saat ini (pakai id biar stabil saat list berubah)
  String? _selectedKitId;

  // ---- Helpers level class (BIAR GAK ERROR) ----
  Kit? _getSelectedKit(List<Kit> kits) {
    if (kits.isEmpty) return null;
    if (_selectedKitId == null) return kits.first;
    final idx = kits.indexWhere((k) => k.id == _selectedKitId);
    return idx == -1 ? kits.first : kits[idx];
  }

  String _formatLast(DateTime? dt) {
    if (dt == null) return '--';
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  bool _recent(DateTime? last) =>
      last != null && DateTime.now().difference(last).inMinutes <= 5;

  bool _isOnline(Kit? k) => (k?.online ?? false) && _recent(k?.lastUpdated);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(kitListProvider.notifier).seedDummy();
        // set default pilihan setelah seed kalau belum ada
        final ks = ref.read(kitListProvider);
        if (ks.isNotEmpty && _selectedKitId == null) {
          _selectedKitId = ks.first.id;
          setState(() {});
        }
        await ref.read(kitListProvider.notifier).simulateSensorUpdate();
      } catch (_) {}
      _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
        try {
          await ref.read(kitListProvider.notifier).simulateSensorUpdate();
        } catch (_) {}
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kits = ref.watch(kitListProvider);

    const bg = Color(0xFFF6FBF6);
    const primary = Color(0xFF154B2E);
    const muted = Color(0xFF7A7A7A);

    final size = MediaQuery.of(context).size;
    final s = size.width / 375.0;

    double readSensor(Kit? kit, String key) {
      if (kit == null) return 0;
      try {
        final dyn = kit as dynamic;
        if (dyn.sensors != null && dyn.sensors[key] != null) {
          final v = dyn.sensors[key];
          if (v is num) return v.toDouble();
          if (v is String) return double.tryParse(v) ?? 0;
        }
        if (key == 'ph' && dyn.ph != null) return (dyn.ph as num).toDouble();
        if (key == 'ppm' && dyn.ppm != null) return (dyn.ppm as num).toDouble();
        if (key == 'humidity' && dyn.humidity != null) {
          return (dyn.humidity as num).toDouble();
        }
        if (key == 'temperature' && dyn.temperature != null) {
          return (dyn.temperature as num).toDouble();
        }
      } catch (_) {}
      return 0;
    }

    double frac(String key, double v) {
      switch (key) {
        case 'ph':
          return (v / 14).clamp(0.0, 1.0);
        case 'ppm':
          return (v / 3000).clamp(0.0, 1.0);
        case 'humidity':
          return (v / 100).clamp(0.0, 1.0);
        case 'temperature':
          return ((v + 10) / 60).clamp(0.0, 1.0);
        default:
          return 0;
      }
    }

    Widget gauge({
      required String label,
      required double value,
      required String unit,
      required double fraction,
    }) {
      String display;
      if (label == 'pH') {
        display = value.toStringAsFixed(2);
      } else if (label == 'PPM') {
        display = value.toStringAsFixed(0);
      } else {
        display = value.toStringAsFixed(1);
      }

      final box = 75.0 * s;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16 * s),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8 * s,
              offset: Offset(0, 4 * s),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(12 * s, 12 * s, 12 * s, 10 * s),
        child: Column(
          children: [
            SizedBox(
              width: box,
              height: box,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, f, _) => CustomPaint(
                  painter: _ArcPainter(
                    color: primary,
                    fraction: f,
                    strokeFactor: 0.12,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6 * s),
            // Value + unit sebaris: 6.7 pH
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  display,
                  style: TextStyle(
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
                if (unit.isNotEmpty) const SizedBox(width: 4),
                if (unit.isNotEmpty)
                  Text(
                    unit,
                    style: TextStyle(fontSize: 12 * s, color: muted),
                  ),
              ],
            ),
            SizedBox(height: 6 * s),
            Text(
              label,
              style: TextStyle(
                fontSize: 13 * s,
                fontWeight: FontWeight.w700,
                color: primary,
              ),
            ),
          ],
        ),
      );
    }

    final Kit? base = _getSelectedKit(kits);
    final ph = readSensor(base, 'ph');
    final ppm = readSensor(base, 'ppm');
    final hum = readSensor(base, 'humidity');
    final temp = readSensor(base, 'temperature');
    final lastText = _formatLast(base?.lastUpdated);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 16 * s),
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
                        color: primary,
                        size: 20 * s,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 21 * s,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 40 * s),
                ],
              ),

              SizedBox(height: 12 * s),

              // Gauges
              GridView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: size.width >= 420 ? 3 : 2,
                  crossAxisSpacing: 14 * s,
                  mainAxisSpacing: 14 * s,
                  childAspectRatio: 1.02,
                ),
                children: [
                  gauge(
                    label: 'pH',
                    value: ph,
                    unit: 'pH',
                    fraction: frac('ph', ph),
                  ),
                  gauge(
                    label: 'PPM',
                    value: ppm,
                    unit: 'ppm',
                    fraction: frac('ppm', ppm),
                  ),
                  gauge(
                    label: 'Humidity',
                    value: hum,
                    unit: '%',
                    fraction: frac('humidity', hum),
                  ),
                  gauge(
                    label: 'Temperature',
                    value: temp,
                    unit: '°C',
                    fraction: frac('temperature', temp),
                  ),
                ],
              ),

              SizedBox(height: 18 * s),

              // Your Kit section
              Text(
                'Your Kit',
                style: TextStyle(
                  fontSize: 18 * s,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              SizedBox(height: 10 * s),

              // Card + picker bottom sheet
              InkWell(
                onTap: kits.length <= 1
                    ? null
                    : () async {
                        final picked = await showModalBottomSheet<Kit>(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20 * s),
                            ),
                          ),
                          builder: (ctx) {
                            return SafeArea(
                              child: ListView.separated(
                                padding: EdgeInsets.symmetric(vertical: 8 * s),
                                itemCount: kits.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final k = kits[i];
                                  final isSel = k.id == _selectedKitId;
                                  final onlineDot =
                                      (k.online) && _recent(k.lastUpdated);
                                  return ListTile(
                                    leading: Icon(
                                      isSel
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                    ),
                                    title: Text(
                                      k.name,
                                      style: TextStyle(
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Last: ${_formatLast(k.lastUpdated)}',
                                    ),
                                    trailing: Container(
                                      width: 10 * s,
                                      height: 10 * s,
                                      decoration: BoxDecoration(
                                        color: onlineDot
                                            ? Colors.greenAccent.shade400
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    onTap: () => Navigator.pop(ctx, k),
                                  );
                                },
                              ),
                            );
                          },
                        );

                        if (picked != null && picked.id != _selectedKitId) {
                          setState(() {
                            _selectedKitId = picked.id;
                            // TODO: trigger fetch sensor by kit if diperlukan
                            // ref.read(kitListProvider.notifier).loadSensorsFor(picked.id);
                          });
                        }
                      },
                borderRadius: BorderRadius.circular(18 * s),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18 * s),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8 * s,
                        offset: Offset(0, 4 * s),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14 * s,
                    vertical: 12 * s,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10 * s,
                        height: 10 * s,
                        decoration: BoxDecoration(
                          color: _isOnline(base)
                              ? Colors.greenAccent.shade400
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              base?.name ?? '—',
                              style: TextStyle(
                                fontSize: 15 * s,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                            SizedBox(height: 2 * s),
                            Text(
                              'Last: $lastText',
                              style: TextStyle(fontSize: 12 * s, color: muted),
                            ),
                          ],
                        ),
                      ),
                      if (kits.length > 1)
                        Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16 * s),

              // Mode row
              Row(
                children: [
                  Text(
                    'Mode :  ',
                    style: TextStyle(
                      fontSize: 16 * s,
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '[Auto ]',
                    style: TextStyle(
                      fontSize: 16 * s,
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6 * s),
                  Checkbox(
                    value: !_manual,
                    onChanged: (v) => setState(() => _manual = !(v ?? false)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(color: primary, width: 1.4),
                    fillColor: WidgetStateProperty.resolveWith(
                      (_) => !_manual ? const Color(0xFF00E676) : Colors.white,
                    ),
                    checkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  SizedBox(width: 12 * s),
                  Text(
                    '[Manual ]',
                    style: TextStyle(
                      fontSize: 16 * s,
                      color: primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6 * s),
                  Checkbox(
                    value: _manual,
                    onChanged: (v) => setState(() => _manual = (v ?? false)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    side: BorderSide(color: primary, width: 1.4),
                    fillColor: WidgetStateProperty.resolveWith(
                      (_) => _manual ? const Color(0xFF00E676) : Colors.white,
                    ),
                    checkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),

              // Manual Controls (show/hide)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _manual
                    ? Column(
                        key: const ValueKey('manual'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 6 * s),
                          Row(
                            children: [
                              Text(
                                'Manual Controls  :',
                                style: TextStyle(
                                  fontSize: 16 * s,
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10 * s),

                          // Buttons grid responsive
                          Wrap(
                            spacing: 12 * s,
                            runSpacing: 12 * s,
                            children: [
                              _controlBtn('pH Up', primary, s),
                              _controlBtn('pH Down', primary, s),
                              _controlBtn('Pump A', primary, s),
                              _controlBtn('Pump B', primary, s),
                              _controlBtn('Refill', primary, s, wide: true),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controlBtn(
    String text,
    Color primary,
    double s, {
    bool wide = false,
  }) {
    // width adaptif: 48% layar utk dua kolom; tombol refill bisa lebar penuh.
    final screenW = MediaQuery.of(context).size.width;
    final maxW = wide
        ? screenW - (16 * s * 2)
        : (screenW - (16 * s * 2) - (12 * s)) / 2;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: 140 * s,
        maxWidth: maxW,
        minHeight: 48 * s,
      ),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          elevation: 3,
          backgroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24 * s),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14 * s,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  final double fraction; // 0..1
  final double strokeFactor;
  _ArcPainter({
    required this.color,
    required this.fraction,
    this.strokeFactor = 0.12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * strokeFactor;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFF0F0F0);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // background full circle (light)
    canvas.drawArc(rect, 0, 3.1415926 * 2, false, bg);

    // top arc
    final start = 3.1415926 * 0.75;
    final sweepMax = 3.1415926 * 0.9;
    canvas.drawArc(rect, start, sweepMax * fraction.clamp(0, 1), false, fg);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.fraction != fraction ||
      old.color != color ||
      old.strokeFactor != strokeFactor;
}
