import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provider/kit_provider.dart';
import '../../providers/provider/notification_provider.dart';

class MonitorScreen extends ConsumerStatefulWidget {
  final String kitId;
  const MonitorScreen({super.key, this.kitId = 'devkit-01'});

  @override
  ConsumerState<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends ConsumerState<MonitorScreen> {
  Timer? _timer;
  String? _selectedKitId;
  DateTime? _lastAlertAt;

  bool _manual = true;

  ProviderSubscription<List<Kit>>? _kitListener;

  @override
  void initState() {
    super.initState();
    _selectedKitId = widget.kitId.isEmpty ? null : widget.kitId;

    // ====== FIX: listener pindah ke sini ======
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kitListener = ref.listenManual<List<Kit>>(kitListProvider, (prev, next) {
        if (!mounted) return;
        setState(() {});
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final notifier = ref.read(kitListProvider.notifier);
        notifier.listenFromMqtt(widget.kitId);

        final ks = ref.read(kitListProvider);
        if (ks.isNotEmpty && _selectedKitId == null) {
          _selectedKitId = ks.first.id;
          if (mounted) setState(() {});
        }

        _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
          final kits = ref.read(kitListProvider);
          final k = _getSelectedKit(kits);
          _checkThresholdAndNotify(k);
        });
      } catch (e) {
        print("Error init dashboard: $e");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();

    // ====== FIX: amanin cleanup ======
    _kitListener?.close();
    _kitListener = null;

    super.dispose();
  }

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
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  bool _recent(DateTime? last) =>
      last != null && DateTime.now().difference(last).inMinutes <= 5;

  bool _isOnline(Kit? k) => (k?.online ?? false) && _recent(k?.lastUpdated);

  @override
  Widget build(BuildContext context) {
    final kits = ref.watch(kitListProvider);

    const bg = Color(0xFFF6FBF6);
    const primary = Color(0xFF154B2E);
    const muted = Color(0xFF7A7A7A);

    final size = MediaQuery.of(context).size;
    final s = size.width / 375.0;

    double readSensor(Kit? kit, String key) {
      final t = kit?.telemetry;
      if (t == null) return 0;
      switch (key) {
        case 'ph':
          return t.ph;
        case 'ppm':
          return t.ppm;
        case 'humidity':
          return t.humidity;
        case 'temperature':
          return t.tempC;
        default:
          return 0;
      }
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
              color: Colors.black.withOpacity(0.03),
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
                builder: (_, f, __) => CustomPaint(
                  painter: _ArcPainter(
                    color: primary,
                    fraction: f,
                    strokeFactor: 0.12,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6 * s),
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
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: primary, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: primary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16 * s, 10 * s, 16 * s, 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ====== GAUGES ======
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

              // ====== YOUR KIT ======
              Text(
                'Your Kit',
                style: TextStyle(
                  fontSize: 18 * s,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              SizedBox(height: 10 * s),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18 * s),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
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
                  ],
                ),
              ),

              SizedBox(height: 16 * s),

              // ====== MODE AUTO / MANUAL + TOMBOL ======
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
                    side: const BorderSide(color: primary, width: 1.4),
                    fillColor: MaterialStateProperty.resolveWith(
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
                    side: const BorderSide(color: primary, width: 1.4),
                    fillColor: MaterialStateProperty.resolveWith(
                      (_) => _manual ? const Color(0xFF00E676) : Colors.white,
                    ),
                    checkColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),

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
                          _modernControls(primary: primary, scale: s),
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

  void _checkThresholdAndNotify(Kit? k) {
    if (k == null) return;
    final t = k.telemetry;
    if (t == null) return;

    const phMin = 5.8, phMax = 6.8;
    const ppmMax = 900.0;
    final now = DateTime.now();
    String? level, title, msg;

    if (t.ppm > ppmMax) {
      level = 'urgent';
      title = 'Urgent';
      msg = 'TDS ${t.ppm.toStringAsFixed(0)} ppm terlalu tinggi!';
    } else if (t.ph < phMin || t.ph > phMax) {
      level = 'warning';
      title = 'Warning';
      msg = 'pH ${t.ph.toStringAsFixed(2)} di luar rentang optimal.';
    }

    if (level != null &&
        (_lastAlertAt == null ||
            now.difference(_lastAlertAt!).inSeconds >= 8)) {
      _lastAlertAt = now;
      final n = NotificationItem(
        id: now.millisecondsSinceEpoch.toString(),
        level: level,
        title: title!,
        message: msg!,
        timestamp: now,
        kitName: k.name,
      );
      ref.read(notificationListProvider.notifier).add(n);
    }
  }

  // ======= Modern Controls =======
  Widget _modernControls({required Color primary, required double scale}) {
    final s = scale;
    final screenW = MediaQuery.of(context).size.width;
    final itemW = (screenW - (16 * s * 2) - (12 * s)) / 2;

    return Wrap(
      spacing: 12 * s,
      runSpacing: 12 * s,
      children: [
        _modernControlBtn(
          width: itemW,
          icon: Icons.trending_up_rounded,
          label: 'pH Up',
          primary: primary,
          scale: s,
          onTap: () {
            HapticFeedback.selectionClick();
            _showSnack('pH Up sent');
          },
        ),
        _modernControlBtn(
          width: itemW,
          icon: Icons.trending_down_rounded,
          label: 'pH Down',
          primary: primary,
          scale: s,
          onTap: () {
            HapticFeedback.selectionClick();
            _showSnack('pH Down sent');
          },
        ),
        _modernControlBtn(
          width: itemW,
          icon: Icons.water_drop_outlined,
          label: 'Pump A',
          primary: primary,
          scale: s,
          onTap: () {
            HapticFeedback.lightImpact();
            _showSnack('Pump A sent');
          },
        ),
        _modernControlBtn(
          width: itemW,
          icon: Icons.water_drop,
          label: 'Pump B',
          primary: primary,
          scale: s,
          onTap: () {
            HapticFeedback.lightImpact();
            _showSnack('Pump B sent');
          },
        ),
        _modernControlBtn(
          width: screenW - (16 * s * 2),
          icon: Icons.refresh_rounded,
          label: 'Refill',
          primary: primary,
          scale: s,
          isEmphasis: true,
          onTap: () {
            HapticFeedback.mediumImpact();
            _showSnack('Refill sent');
          },
        ),
      ],
    );
  }

  Widget _modernControlBtn({
    required double width,
    required IconData icon,
    required String label,
    required Color primary,
    required double scale,
    bool isEmphasis = false,
    VoidCallback? onTap,
  }) {
    final s = scale;

    return SizedBox(
      width: width,
      height: 54 * s,
      child: _GlassButton(
        onTap: onTap,
        radius: 18 * s,
        padding: EdgeInsets.symmetric(horizontal: 14 * s),
        gradient: isEmphasis
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E6C45), Color(0xFF154B2E)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF3F7F4)],
              ),
        borderColor: isEmphasis ? Colors.transparent : const Color(0xFFE6EEE8),
        shadowColor: Colors.black.withOpacity(0.05),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20 * s,
              color: isEmphasis ? Colors.white : primary,
            ),
            SizedBox(width: 10 * s),
            Text(
              label,
              style: TextStyle(
                fontSize: 14 * s,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: isEmphasis ? Colors.white : primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }
}

// ===== Arc painter untuk gauge =====
class _ArcPainter extends CustomPainter {
  final Color color;
  final double fraction;
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
    canvas.drawArc(rect, 0, 3.1415926 * 2, false, bg);
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

// ===== Small glassy button =====
class _GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final EdgeInsets padding;
  final Gradient gradient;
  final Color borderColor;
  final Color shadowColor;

  const _GlassButton({
    required this.child,
    required this.onTap,
    required this.radius,
    required this.padding,
    required this.gradient,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: widget.borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: widget.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.radius),
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            child: Padding(
              padding: widget.padding,
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
