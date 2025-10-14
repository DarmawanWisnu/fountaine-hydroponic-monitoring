// lib/screens/monitor/monitor_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fountaine/constants/routes.dart';
import '../../providers/kit_provider.dart';

class MonitorScreen extends ConsumerStatefulWidget {
  const MonitorScreen({super.key});
  @override
  ConsumerState<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends ConsumerState<MonitorScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(kitListProvider.notifier).seedDummy();
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
    final s = MediaQuery.of(context).size.width / 375.0;

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

      final size = 74.0 * s;
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14 * s),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 12 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: fraction),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, f, __) => CustomPaint(
                  painter: _ArcPainter(
                    color: primary,
                    fraction: f.clamp(0, 1),
                    strokeFactor: 0.11,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6 * s),

            // nilai + satuan sejajar horizontal (agar tidak overflow vertikal)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  display,
                  style: TextStyle(
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  SizedBox(width: 6 * s),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 11 * s, color: muted),
                  ),
                ],
              ],
            ),

            SizedBox(height: 6 * s),
            Text(
              label,
              style: TextStyle(
                fontSize: 13 * s,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ],
        ),
      );
    }

    final Kit? base = kits.isNotEmpty ? kits.first : null;
    final ph = readSensor(base, 'ph');
    final ppm = readSensor(base, 'ppm');
    final hum = readSensor(base, 'humidity');
    final temp = readSensor(base, 'temperature');

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(18 * s, 12 * s, 18 * s, 6 * s),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20 * s,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.arrow_back,
                          size: 20 * s,
                          color: primary,
                        ),
                        onPressed: () => Navigator.maybePop(context),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 20 * s,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 40 * s),
                  ],
                ),
              ),
            ),

            // Gauges grid (no fixed height, fully responsive)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 18 * s),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16 * s,
                crossAxisSpacing: 16 * s,
                childAspectRatio: 1,
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
            ),

            // Spacing between grid and status
            SliverToBoxAdapter(child: SizedBox(height: 18 * s)),

            // Status block
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Status Kit  :',
                          style: TextStyle(fontSize: 16 * s, color: muted),
                        ),
                        SizedBox(width: 8 * s),
                        Text(
                          kits.isNotEmpty ? 'Online' : '—',
                          style: TextStyle(
                            fontSize: 16 * s,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                        SizedBox(width: 8 * s),
                        if (kits.isNotEmpty)
                          Container(
                            width: 10 * s,
                            height: 10 * s,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6 * s),
                    Text(
                      'Last Update : --',
                      style: TextStyle(fontSize: 13 * s, color: muted),
                    ),
                  ],
                ),
              ),
            ),

            // Spacing between status and list
            SliverToBoxAdapter(child: SizedBox(height: 18 * s)),

            // Title "Your Kits"
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22 * s),
                child: Text(
                  'Your Kits',
                  style: TextStyle(
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 10 * s)),

            // List of kits (sliver list, smooth scrolling)
            if (kits.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 22 * s,
                    vertical: 24 * s,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Belum ada Kit. Tambahkan Kit terlebih dahulu.',
                          style: TextStyle(color: muted),
                        ),
                        SizedBox(height: 10 * s),
                        SizedBox(
                          width: 160 * s,
                          height: 44 * s,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(40 * s),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, Routes.addKit),
                            child: const Text('Add Kit'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18 * s),
                sliver: SliverList.separated(
                  itemCount: kits.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10 * s),
                  itemBuilder: (_, i) => _KitTile(
                    k: kits[i],
                    s: s,
                    primary: primary,
                    muted: muted,
                  ),
                ),
              ),

            // Bottom padding so list nggak kejepit nav bar
            SliverToBoxAdapter(child: SizedBox(height: 14 * s)),
          ],
        ),
      ),
    );
  }
}

class _KitTile extends ConsumerWidget {
  final Kit k;
  final double s;
  final Color primary;
  final Color muted;
  const _KitTile({
    required this.k,
    required this.s,
    required this.primary,
    required this.muted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastText = k.lastUpdated.toLocal().toString().split('.').first;
    final statusDot = k.online ? Colors.greenAccent.shade400 : Colors.grey;

    return Dismissible(
      key: Key(k.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12 * s),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus Kit'),
            content: Text('Yakin ingin menghapus kit "${k.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        try {
          await ref.read(kitListProvider.notifier).removeKit(k.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Kit "${k.name}" dihapus')));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
          }
        }
      },
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, Routes.monitor, arguments: k),
        borderRadius: BorderRadius.circular(12 * s),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8 * s,
                offset: Offset(0, 4 * s),
              ),
            ],
          ),
          padding: EdgeInsets.all(12 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                k.name,
                style: TextStyle(
                  fontSize: 16 * s,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
              SizedBox(height: 8 * s),
              Row(
                children: [
                  Container(
                    width: 10 * s,
                    height: 10 * s,
                    decoration: BoxDecoration(
                      color: statusDot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  Text(
                    k.online ? 'Online' : 'Offline',
                    style: TextStyle(color: muted, fontSize: 13 * s),
                  ),
                  const Spacer(),
                  Text(
                    'Last: $lastText',
                    style: TextStyle(color: muted, fontSize: 12 * s),
                  ),
                ],
              ),
            ],
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
