import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provider/notification_provider.dart';
import '../../models/nav_args.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});
  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  String? _filter; // null = All

  /// Menentukan ikon berdasarkan level notifikasi.
  IconData _icon(String level) {
    switch (level) {
      case 'urgent':
        return Icons.dangerous_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(filteredNotificationProvider(_filter));
    final notifier = ref.read(notificationListProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F9F4),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0E5A2A),
          ),
          onPressed: () => Navigator.maybePop(context),
        ),

        // Judul halaman.
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Color(0xFF0E5A2A),
            fontWeight: FontWeight.w800,
          ),
        ),

        // Aksi kanan: ikon lonceng -> route ke History.
        actions: [
          IconButton(
            tooltip: 'Open History',
            icon: const Icon(
              Icons.notifications_rounded,
              color: Color(0xFF0E5A2A),
            ),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/history',
                arguments: const HistoryRouteArgs(),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      // ===== FAB: tandai semua notifikasi sebagai sudah dibaca =====
      floatingActionButton: FloatingActionButton.extended(
        onPressed: notifier.markAllRead,
        backgroundColor: const Color(0xFF0E5A2A),
        icon: const Icon(Icons.done_all_rounded),
        label: const Text('Mark all read'),
      ),

      // ===== Body: daftar notifikasi + filter chip =====
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),

        children: [
          // FilterChip baris horizontal: All/Info/Warning/Urgent
          _FilterChips(
            value: _filter,
            onChanged: (v) => setState(() => _filter = v),
          ),

          const SizedBox(height: 8),

          // Kartu-kartu notifikasi
          for (final n in list)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: InkWell(
                // InkWell: area tap pada kartu.
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  // 1) Tandai sebagai dibaca
                  notifier.markRead(n.id);

                  // 2) Buka halaman History di momen notifikasi itu
                  Navigator.pushNamed(
                    context,
                    '/history',
                    arguments: HistoryRouteArgs(
                      targetTime: n.timestamp,
                      kitName: n.kitName,
                      reason: n.message,
                    ),
                  );
                },

                // ===== Card notifikasi =====
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withOpacity(0.06),
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  // Isi kartu: ikon + teks + badge unread
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ikon sesuai level
                      Icon(
                        _icon(n.level),
                        size: 28,
                        color: const Color(0xFF0E5A2A),
                      ),
                      const SizedBox(width: 14),

                      // Teks utama (judul, pesan, meta)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Judul level (Urgent/Warning/Info)
                            Text(
                              n.title,
                              style: const TextStyle(
                                color: Color(0xFF0E5A2A),
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Pesan notifikasi
                            Text(
                              n.message,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Metadata: nama kit + relative time
                            Text(
                              '${n.kitName ?? "Unknown Kit"} • ${_ago(n.timestamp)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withOpacity(.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Titik hijau kecil sebagai indikator unread (disembunyikan jika read)
                      AnimatedOpacity(
                        opacity: n.isRead ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0E5A2A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Format waktu relatif: 3m ago, 2h ago, dst.
  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

/// Deretan ChoiceChip untuk mem-filter daftar notifikasi berdasarkan level.
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('All', null),
      ('Info', 'info'),
      ('Warning', 'warning'),
      ('Urgent', 'urgent'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((it) {
          final selected = value == it.$2;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(it.$1),
              selected: selected,
              onSelected: (_) => onChanged(it.$2),
              selectedColor: const Color(0xFF0E5A2A),
              labelStyle: TextStyle(
                color: selected ? Colors.white : const Color(0xFF0E5A2A),
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: const Color(0xFFE6F1E9),
              shape: StadiumBorder(
                side: BorderSide(
                  color: const Color(0xFF0E5A2A).withOpacity(.3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
