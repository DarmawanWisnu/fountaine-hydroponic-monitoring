import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../providers/provider/notification_provider.dart';
import '../../domain/telemetry.dart';
import '../../models/nav_args.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final String kitId;
  final DateTime? targetTime;
  const HistoryScreen({super.key, this.kitId = 'devkit-01', this.targetTime});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? selectedDate;
  final ScrollController _scroll = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  DateTime? _pendingTargetTime;

  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF7A7A7A);

  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadData();
      if (widget.targetTime != null) {
        _pendingTargetTime = widget.targetTime;
        selectedDate = DateTime(
          widget.targetTime!.year,
          widget.targetTime!.month,
          widget.targetTime!.day,
        );
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadData() async {
    _entries = await _readEntriesWithTs(widget.kitId);
  }

  /// Baca langsung dari SQLite: ambil ingest_time (ts) + payload_json (Telemetry)
  Future<List<Map<String, dynamic>>> _readEntriesWithTs(String deviceId) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'data.db');
    final db = await openDatabase(path);

    final rows = await db.query(
      'telemetry',
      columns: ['ingest_time', 'payload_json'],
      where: 'device_id = ?',
      whereArgs: [deviceId],
      orderBy: 'ingest_time DESC',
    );
    await db.close();

    return rows.map((r) {
      final ts = (r['ingest_time'] as int?) ?? 0;
      final jsonStr = (r['payload_json'] as String?) ?? '{}';
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final t = Telemetry.fromJson(map);
      return {'t': t, 'ts': ts};
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 375.0;
    final unread = ref.watch(unreadNotificationCountProvider);

    final filtered = selectedDate == null
        ? _entries
        : _entries.where((e) {
            final d1 = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.fromMillisecondsSinceEpoch(e['ts'] as int));
            final d2 = DateFormat('yyyy-MM-dd').format(selectedDate!);
            return d1 == d2;
          }).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingTargetTime != null && filtered.isNotEmpty) {
        _jumpToTarget(_pendingTargetTime!, filtered);
        _pendingTargetTime = null;
      }
    });

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'History',
          style: TextStyle(
            color: _primary,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: _primary),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    _pendingTargetTime = null;
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10 * s,
                        offset: Offset(0, 3 * s),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: _primary,
                            size: 20,
                          ),
                          SizedBox(width: 8 * s),
                          Text(
                            selectedDate == null
                                ? 'Select Date'
                                : DateFormat(
                                    'd MMMM yyyy',
                                  ).format(selectedDate!),
                            style: TextStyle(
                              color: selectedDate == null ? _muted : _primary,
                              fontSize: 15 * s,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 80 * s,
                          color: _muted.withOpacity(0.4),
                        ),
                        SizedBox(height: 12 * s),
                        Text(
                          'No data available for this date.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 15 * s,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final Telemetry t = item['t'] as Telemetry;
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        item['ts'] as int,
                      );
                      final key = _itemKeys.putIfAbsent(
                        date.millisecondsSinceEpoch,
                        () => GlobalKey(),
                      );

                      return Padding(
                        key: key,
                        padding: EdgeInsets.only(bottom: 14 * s),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16 * s),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12 * s,
                                offset: Offset(0, 4 * s),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(16 * s),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      widget.kitId,
                                      style: TextStyle(
                                        color: _primary,
                                        fontSize: 17 * s,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10 * s,
                                        vertical: 4 * s,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          12 * s,
                                        ),
                                      ),
                                      child: Text(
                                        DateFormat('HH:mm:ss').format(date),
                                        style: TextStyle(
                                          color: _primary,
                                          fontSize: 12 * s,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                _dataRow('Water Acidity', '${t.ph} pH', s),
                                _dataRow('TDS', '${t.ppm} ppm', s),
                                _dataRow('Humidity', '${t.humidity} %', s),
                                _dataRow(
                                  'Temperature',
                                  '${t.tempC.toStringAsFixed(1)} °C',
                                  s,
                                ),
                              ],
                            ),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/notifications',
            arguments: const NotificationRouteArgs(initialFilter: 'info'),
          );
        },
        shape: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_rounded, color: Colors.white),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(String label, String value, double s) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4 * s),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _muted,
              fontSize: 14 * s,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _primary,
              fontSize: 14 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToTarget(DateTime target, List<Map<String, dynamic>> filtered) {
    int? keyTs;
    Duration best = const Duration(days: 9999);
    for (final it in filtered) {
      final ts = (it['ts'] as int?) ?? 0;
      final diff = DateTime.fromMillisecondsSinceEpoch(
        ts,
      ).difference(target).abs();
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
