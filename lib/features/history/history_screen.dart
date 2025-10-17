import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider kit (nilai sama persis yang dipakai MonitorScreen)
import '../../providers/provider/kit_provider.dart';

// NOTE: kita gak butuh notification_provider di versi sinkron monitor ini,
// karena history akan dibangun dari snapshot nilai kit yang terus diperbarui.
// import '../../providers/provider/notification_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  // Kit yang ingin ditarget (opsional; kalau kosong akan pakai kit pertama)
  final String kitId;

  // Opsional: waktu target untuk auto-scroll ke item terdekat
  final DateTime? targetTime;

  const HistoryScreen({super.key, this.kitId = 'devkit-01', this.targetTime});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  // ====== UI State ======
  DateTime? selectedDate; // filter hari aktif
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _itemKeys =
      {}; // key per item (untuk ensureVisible)
  DateTime? _pendingTargetTime; // target loncat (dari args)

  // ====== Snapshot Buffer (in-memory) ======
  // Kita bikin buffer local supaya yang ditampilkan history bener-bener
  // nilai yang sama dengan di Monitor (dibaca dari provider 'kits').
  //
  // Setiap ada perubahan lastUpdated pada kit aktif, kita simpan 1 snapshot.
  // Kapasitas buffer dibatasi biar ringan.
  static const int _maxSnapshots = 200;
  DateTime? _lastSeenTs; // untuk deteksi perubahan (lastUpdated terakhir)
  final List<Map<String, dynamic>> _snapshots =
      []; // [{date, kit, id, ph, ppm, humidity, temperature}]

  // Palet warna (samakan dengan Monitor)
  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF7A7A7A);

  @override
  void initState() {
    super.initState();

    // Pastikan loop simulasi nyala kalau data kosong (biar history jalan sendiri).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (ref.read(kitListProvider).isEmpty) {
        await ref.read(kitListProvider.notifier).ensureSimRunning();
      }
    });

    // Sinkron target scroll & filter hari dari constructor (kalau ada)
    if (widget.targetTime != null) {
      _pendingTargetTime = widget.targetTime;
      selectedDate = DateTime(
        widget.targetTime!.year,
        widget.targetTime!.month,
        widget.targetTime!.day,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 375.0;

    // Ambil data kit terkini dari provider (sama dengan MonitorScreen)
    final kits = ref.watch(kitListProvider);

    // Pilih kit aktif: sama logika dengan monitor (fallback ke first)
    final Kit? kit = _pickActiveKit(kits, widget.kitId);

    // Baca nilai sensor dengan helper yang sama bentuknya seperti di Monitor
    final ph = _readSensor(kit, 'ph');
    final ppm = _readSensor(kit, 'ppm');
    final humidity = _readSensor(kit, 'humidity');
    final temperature = _readSensor(kit, 'temperature');

    // === Update snapshot buffer kalau ada perubahan waktu (lastUpdated) ===
    if (kit != null && (kit.lastUpdated != _lastSeenTs)) {
      _lastSeenTs = kit.lastUpdated;

      final snap = {
        'date': kit.lastUpdated,
        'kit': kit.name,
        'id': kit.id,
        'ph': double.tryParse(ph.toStringAsFixed(2)) ?? ph,
        'ppm': ppm.round(),
        'humidity': double.tryParse(humidity.toStringAsFixed(1)) ?? humidity,
        'temperature':
            double.tryParse(temperature.toStringAsFixed(1)) ?? temperature,
      };

      _snapshots.insert(0, snap); // paling baru di atas
      if (_snapshots.length > _maxSnapshots) {
        _snapshots.removeRange(_maxSnapshots, _snapshots.length);
      }
    }

    // Sort desc by date (jaga-jaga)
    _snapshots.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    // Filter by selectedDate (jika ada)
    final List<Map<String, dynamic>> filteredData = selectedDate == null
        ? List<Map<String, dynamic>>.from(_snapshots)
        : _snapshots.where((item) {
            final d1 = DateFormat(
              'yyyy-MM-dd',
            ).format(item['date'] as DateTime);
            final d2 = DateFormat('yyyy-MM-dd').format(selectedDate!);
            return d1 == d2;
          }).toList();

    // Setelah list selesai dirender, kalau ada target → loncat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingTargetTime != null && filteredData.isNotEmpty) {
        _jumpToTarget(_pendingTargetTime!, filteredData);
        _pendingTargetTime = null;
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        // Samain gaya dengan Monitor: judul simple tanpa kitId di judul
        title: const Text(
          'History',
          style: TextStyle(color: _primary, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: _primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Date Picker (filter harian) =====
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
                              // Nama Kit
                              Text(
                                item['kit'] as String,
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 16 * s,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6 * s),

                              // ID Kit
                              Text(
                                item['id'] as String,
                                style: TextStyle(
                                  fontSize: 14 * s,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 6 * s),

                              // Nilai sensor (sinkron monitor)
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

                              // Timestamp
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  DateFormat(
                                    'd MMMM yyyy, HH:mm:ss',
                                  ).format(date),
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

      // ===== FAB Placeholder (nanti buat export/clear, dll) =====
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

  // =======================
  // ---------- Helpers ----
  // =======================

  /// Pilih kit aktif berdasarkan kitId preferensi; kalau gak ada → pakai first.
  Kit? _pickActiveKit(List<Kit> kits, String preferId) {
    if (kits.isEmpty) return null;
    final idx = kits.indexWhere((k) => k.id == preferId);
    return idx == -1 ? kits.first : kits[idx];
  }

  /// Baca nilai sensor dari Kit (mendukung schema fleksibel seperti Monitor)
  double _readSensor(Kit? kit, String key) {
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
    } catch (_) {
      /* swallow */
    }
    return 0;
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
