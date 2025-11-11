import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/provider/notification_provider.dart';
import '../../models/nav_args.dart';

// ===== GLOBAL COLOR CONSTANTS =====
const Color kPrimary = Color(0xFF0E5A2A);
const Color kBg = Color(0xFFF3F9F4);
const Color kChipBg = Color(0xFFE8F2EC);

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});
  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  // default 'info' saat buka langsung
  String? _filter = 'info';
  bool _inited = false;

  String _norm(String? s) => (s ?? '').trim().toLowerCase();

  // ''/all -> null (All), info/warning/urgent valid, lainnya fallback 'info'
  String? _sanitizeFilter(String? raw) {
    final k = _norm(raw);
    if (k.isEmpty || k == 'all') return null; // All
    if (k == 'info' || k == 'warning' || k == 'urgent') return k;
    return 'info';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    final fromArgs = (args is NotificationRouteArgs)
        ? args.initialFilter
        : null;

    _filter = _sanitizeFilter(fromArgs) ?? 'info';
    _inited = true;

    assert(() {
      // ignore: avoid_print
      print('[NotificationScreen] args=$fromArgs -> _filter=$_filter');
      return true;
    }());

    setState(() {});
  }

  IconData _icon(String? levelRaw) {
    switch (_norm(levelRaw)) {
      case 'urgent':
        return Icons.dangerous_outlined;
      case 'warning':
        return Icons.warning_amber_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _accent(String? levelRaw) {
    switch (_norm(levelRaw)) {
      case 'urgent':
        return const Color(0xFFE53935);
      case 'warning':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    // Nilai efektif tersanitasi: dipakai untuk chip & data
    final eff = _sanitizeFilter(_filter);

    // Ambil via provider (robust: null/''/all => All)
    final all = ref.watch(notificationListProvider);
    List<NotificationItem> list = ref.watch(filteredNotificationProvider(eff));

    // 🔒 DOUBLE-GUARD: walau sudah difilter provider, saring ulang lokal
    if (eff != null) {
      final key = _norm(eff);
      list = list.where((n) => _norm(n.level) == key).toList();
    }

    assert(() {
      // ignore: avoid_print
      final first = list.isNotEmpty ? _norm(list.first.level) : '-';
      print(
        '[NotificationScreen] build eff=$eff, first=$first, '
        'counts: info=${all.where((e) => _norm(e.level) == 'info').length}, '
        'warn=${all.where((e) => _norm(e.level) == 'warning').length}, '
        'urg=${all.where((e) => _norm(e.level) == 'urgent').length}',
      );
      return true;
    }());

    int countLevel(String lvl) =>
        all.where((e) => _norm(e.level) == _norm(lvl)).length;

    final notifier = ref.read(notificationListProvider.notifier);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notification',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: .2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: _Glass(
                  borderRadius: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: _FilterChips(
                    value: eff, // chip pakai nilai efektif
                    onChanged: (newKey) =>
                        setState(() => _filter = _sanitizeFilter(newKey)),
                    infoCount: countLevel('info'),
                    warningCount: countLevel('warning'),
                    urgentCount: countLevel('urgent'),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert, color: kPrimary),
                onSelected: (v) async {
                  switch (v) {
                    case 'read':
                      notifier.markAllRead();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('All marked as read')),
                      );
                      break;
                    case 'delete':
                      final ok =
                          await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete all notifications?'),
                              content: const Text(
                                'This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (ok) {
                        notifier.clearAll();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All notifications deleted'),
                          ),
                        );
                      }
                      break;
                  }
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'read', child: Text('Mark all read')),
                  PopupMenuItem(value: 'delete', child: Text('Delete all')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (list.isEmpty)
            _EmptyState(onExploreAll: () => setState(() => _filter = null))
          else
            ...list.map(
              (n) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: const _SwipeBg(),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete notification?'),
                            content: Text(n.message),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) {
                    notifier.delete(n.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification deleted')),
                    );
                  },
                  child: _NotificationCard(
                    title: n.title,
                    message: n.message,
                    meta:
                        '${n.kitName ?? "Unknown Kit"} • ${_ago(n.timestamp)}',
                    icon: _icon(n.level),
                    accent: _accent(n.level),
                    isRead: n.isRead,
                    onTap: () {
                      notifier.markRead(n.id);
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
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===== Subwidgets =====

class _Glass extends StatelessWidget {
  const _Glass({this.child, this.padding, this.borderRadius = 14});
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.55),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(.7)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ====== CHIP KUSTOM (tanpa ChoiceChip) ======
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.value, // null => All
    required this.onChanged,
    required this.infoCount,
    required this.warningCount,
    required this.urgentCount,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final int infoCount;
  final int warningCount;
  final int urgentCount;

  String _cap(int n) => n > 9 ? '9+' : '$n';

  @override
  Widget build(BuildContext context) {
    final items = <({String label, String? key, IconData? icon, int? count})>[
      (label: 'All', key: null, icon: null, count: null),
      (
        label: 'Info',
        key: 'info',
        icon: Icons.campaign_rounded,
        count: infoCount,
      ),
      (
        label: 'Warning',
        key: 'warning',
        icon: Icons.warning_amber_rounded,
        count: warningCount,
      ),
      (
        label: 'Urgent',
        key: 'urgent',
        icon: Icons.dangerous_outlined,
        count: urgentCount,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((it) {
          final selected = value == it.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _ChipBtn(
              label: it.label,
              selected: selected,
              icon: it.icon,
              badge: it.count == null ? null : _cap(it.count!),
              onTap: () => onChanged(it.key), // hanya user tap yang bisa ganti
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({
    required this.label,
    required this.selected,
    this.icon,
    this.badge,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kPrimary : kChipBg,
      shape: StadiumBorder(
        side: BorderSide(
          color: (selected ? Colors.white : kPrimary).withOpacity(.25),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : kPrimary,
                  ),
                ),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : kPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                _CountBadge(value: badge!, selected: selected),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.value, required this.selected});
  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withOpacity(.2) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Colors.white.withOpacity(.5)
              : kPrimary.withOpacity(.25),
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : kPrimary,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExploreAll});
  final VoidCallback onExploreAll;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_rounded, size: 72, color: kPrimary),
            const SizedBox(height: 12),
            const Text(
              "No notifications (for this filter)",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Santai, sistem kamu aman-aman aja kok… untuk sekarang 😏",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withOpacity(.65)),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onExploreAll,
              icon: const Icon(Icons.all_inclusive_rounded),
              label: const Text('Show All'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeBg extends StatelessWidget {
  const _SwipeBg();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade300],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Delete',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 8),
          Icon(Icons.delete_outline, color: Colors.white, size: 24),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.message,
    required this.meta,
    required this.icon,
    required this.accent,
    required this.isRead,
    required this.onTap,
  });

  final String title;
  final String message;
  final String meta;
  final IconData icon;
  final Color accent;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black.withOpacity(.06),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 96,
              decoration: BoxDecoration(
                color: accent.withOpacity(.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconBadge(icon: icon, color: accent),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: kPrimary,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isRead ? 0 : 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: accent.withOpacity(.35),
                                  ),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          message,
                          style: const TextStyle(fontSize: 14.5, height: 1.35),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              meta,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(.55),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(.18), color.withOpacity(.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
