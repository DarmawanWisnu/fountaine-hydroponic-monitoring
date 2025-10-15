import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers (sinkron dummy dari kit + notif)
import '../../providers/provider/kit_provider.dart';
import '../../providers/provider/notification_provider.dart';

// Argumen route satu-satunya
import '../../models/nav_args.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? selectedDate; // tanggal filter aktif
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {}; // key tiap item utk ensureVisible
  DateTime? _pendingTargetTime; // target loncat (dari args)

  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF7A7A7A);

  @override
  void initState() {
    super.initState();
    // Ambil args setelah frame terpasang
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final raw = ModalRoute.of(context)?.settings.arguments;
      final args = raw is HistoryRouteArgs ? raw : null; // aman: satu tipe saja
      if (args?.targetTime != null) {
        _pendingTargetTime = args!.targetTime;
        setState(() {
          selectedDate = DateTime(
            args.targetTime!.year,
            args.targetTime!.month,
            args.targetTime!.day,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 375.0;

    // Data dari providers
    final kits = ref.watch(kitListProvider);
    final notifs = ref.watch(notificationListProvider);

    // Bangun history dummy sinkron (PPM/PH pas dengan notifikasi)
    final history = _buildHistoryFromProviders(
      kits,
      notifs,
    )..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Filter by selectedDate (jika ada)
    final filteredData = selectedDate == null
        ? history
        : history.where((item) {
            final d1 = DateFormat(
              'yyyy-MM-dd',
            ).format(item['date'] as DateTime);
            final d2 = DateFormat('yyyy-MM-dd').format(selectedDate!);
            return d1 == d2;
          }).toList();

    // Setelah list dirender, kalau ada target, loncat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingTargetTime != null) {
        _jumpToTarget(_pendingTargetTime!, filteredData);
        _pendingTargetTime = null;
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Header =====
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20 * s,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_back,
                        color: _primary,
                        size: 20 * s,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'History',
                        style: TextStyle(
                          fontSize: 20 * s,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 40 * s),
                ],
              ),

              SizedBox(height: 16 * s),

              // ===== Date Picker =====
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2024, 1, 1),
                    lastDate: DateTime(2026, 12, 31),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                    _pendingTargetTime = null; // reset target
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18 * s,
                    vertical: 14 * s,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18 * s),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? 'Select Date'
                            : DateFormat('d MMMM yyyy').format(selectedDate!),
                        style: TextStyle(
                          color: selectedDate == null ? _muted : _primary,
                          fontSize: 15 * s,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _primary,
                        size: 22 * s,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 18 * s),

              // ===== List / Empty =====
              if (filteredData.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No data available for this date.',
                      style: TextStyle(color: _muted, fontSize: 15 * s),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final date = item['date'] as DateTime;
                      final formattedDate = DateFormat(
                        'd MMMM yyyy, HH:mm:ss',
                      ).format(date);

                      final key = _itemKeys.putIfAbsent(
                        date.millisecondsSinceEpoch,
                        () => GlobalKey(),
                      );

                      return Padding(
                        key: key,
                        padding: EdgeInsets.only(bottom: 14 * s),
                        child: Container(
                          padding: EdgeInsets.all(16 * s),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16 * s),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['kit'] as String,
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 16 * s,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6 * s),
                              Text(
                                item['id'] as String,
                                style: TextStyle(
                                  fontSize: 14 * s,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 6 * s),
                              Text(
                                'Water Acidity : ${item['ph']} pH',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14 * s,
                                ),
                              ),
                              Text(
                                'Total Dissolved Solids (TDS) : ${item['ppm']} PPM',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14 * s,
                                ),
                              ),
                              Text(
                                'Humidity : ${item['humidity']}%',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14 * s,
                                ),
                              ),
                              Text(
                                'Temperature : ${item['temperature']}° C',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14 * s,
                                ),
                              ),
                              SizedBox(height: 8 * s),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 12 * s,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),

      // ===== FAB Placeholder =====
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add new history feature coming soon'),
            ),
          );
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Generate history dummy dari providers:
  /// - Entry khusus di timestamp notifikasi agar nilai sensor "menjelaskan" notif.
  /// - Tambah snapshot sebelum/sesudah agar timeline terasa alami.
  List<Map<String, dynamic>> _buildHistoryFromProviders(
    List<Kit> kits,
    List<NotificationItem> notifs,
  ) {
    final List<Map<String, dynamic>> items = [];

    Map<String, dynamic> _baselineForKit(Kit? k) => {
      'kit': k?.name ?? 'Unknown Kit',
      'id': k?.id ?? 'UNKNOWN-ID',
      'ph': (k?.ph ?? 6.7).toStringAsFixed(1),
      'ppm': (k?.ppm ?? 300).round(),
      'humidity': (k?.humidity ?? 75).round(),
      'temperature': (k?.temperature ?? 28).round(),
    };

    Kit _fallback() => Kit(
      id: 'SUF-UINJKT-HM-F2000',
      name: 'Hydroponic System',
      ph: 6.7,
      ppm: 300,
      humidity: 75,
      temperature: 28,
    );

    Kit _findKitByName(String? name) {
      if (name == null) return kits.isNotEmpty ? kits.first : _fallback();
      for (final k in kits) {
        if (k.name == name) return k;
      }
      return kits.isNotEmpty ? kits.first : _fallback();
    }

    for (final n in notifs) {
      final kit = _findKitByName(n.kitName);
      final base = _baselineForKit(kit);

      // Sesuaikan nilai agar match pesan notifikasi
      final msg = n.message.toLowerCase();
      if (n.level == 'urgent' && msg.contains('tds reached 850')) {
        base['ppm'] = 850;
      }
      if (n.level == 'warning' && msg.contains('ph dropped to 5.8')) {
        base['ph'] = 5.8.toStringAsFixed(1);
      }
      if (n.level == 'warning' && msg.contains('ppm dropped to 100')) {
        base['ppm'] = 100;
      }

      items.add({'date': n.timestamp, ...base});
      items.add({
        'date': n.timestamp.subtract(const Duration(minutes: 20)),
        ..._baselineForKit(kit),
      });
      items.add({
        'date': n.timestamp.add(const Duration(minutes: 15)),
        ..._baselineForKit(kit),
      });
    }

    if (items.isEmpty) {
      final k = kits.isNotEmpty ? kits.first : _fallback();
      final base = _baselineForKit(k);
      items.add({
        'date': DateTime.now().subtract(const Duration(hours: 3)),
        ...base,
      });
      items.add({
        'date': DateTime.now().subtract(const Duration(hours: 1)),
        ...base,
      });
    }

    return items;
  }

  /// Loncat ke item dengan timestamp paling dekat ke [target]
  void _jumpToTarget(DateTime target, List<Map<String, dynamic>> filtered) {
    int? keyTs;
    Duration best = const Duration(days: 9999);

    for (final it in filtered) {
      final ts = (it['date'] as DateTime).millisecondsSinceEpoch;
      final diff = (it['date'] as DateTime).difference(target).abs();
      if (diff < best) {
        best = diff;
        keyTs = ts;
      }
    }
    if (keyTs == null) return;

    final ctx = _itemKeys[keyTs]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }
}
