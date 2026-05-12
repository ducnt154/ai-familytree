import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_event.dart';
import '../../data/models/family_event_kind.dart';
import '../../providers/family_tree_controller.dart';
import 'event_edit_page.dart';

/// Danh sách sự kiện theo cây đang mở (offline Hive).
class EventsListPage extends StatefulWidget {
  const EventsListPage({super.key});

  @override
  State<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends State<EventsListPage> {
  int _segment = 0; // 0 tất cả, 1 sắp tới, 2 đã qua
  FamilyEventKind? _kindFilter;

  static int _dateOrdinal(DateTime d) =>
      d.year * 10000 + d.month * 100 + d.day;

  IconData _iconFor(FamilyEventKind k) {
    switch (k) {
      case FamilyEventKind.birthday:
        return Icons.cake_outlined;
      case FamilyEventKind.deathAnniversary:
        return Icons.spa_outlined;
      case FamilyEventKind.weddingAnniversary:
        return Icons.favorite_outline;
      case FamilyEventKind.graduation:
        return Icons.school_outlined;
      case FamilyEventKind.jobAnniversary:
        return Icons.work_outline;
      case FamilyEventKind.other:
        return Icons.event_outlined;
    }
  }

  String _formatDdMmYyyy(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  List<FamilyEvent> _filtered(List<FamilyEvent> all) {
    final now = DateTime.now();
    final todayOrd = _dateOrdinal(now);
    Iterable<FamilyEvent> it = all;
    if (_segment == 1) {
      final end = now.add(const Duration(days: 30));
      it = it.where((e) {
        final o = _dateOrdinal(e.eventDate);
        final endOrd = _dateOrdinal(end);
        return o >= todayOrd && o <= endOrd;
      });
    } else if (_segment == 2) {
      it = it.where((e) => _dateOrdinal(e.eventDate) < todayOrd);
    }
    if (_kindFilter != null) {
      it = it.where((e) => e.eventKind == _kindFilter);
    }
    final list = it.toList();
    list.sort((a, b) {
      final cmp =
          _dateOrdinal(a.eventDate).compareTo(_dateOrdinal(b.eventDate));
      if (cmp != 0) return _segment == 2 ? -cmp : cmp;
      return a.id.compareTo(b.id);
    });
    return list;
  }

  String? _personName(FamilyTreeController ctrl, String personId) {
    for (final p in ctrl.persons) {
      if (p.id == personId) return p.displayName;
    }
    return null;
  }

  Future<void> _confirmDelete(BuildContext context, FamilyEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sự kiện?'),
        content: Text(
          'Xóa vĩnh viễn “${e.displayTitle}” (${_formatDdMmYyyy(e.eventDate)})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<FamilyTreeController>().removeFamilyEvent(e.id);
    if (!context.mounted) return;
    final err = context.read<FamilyTreeController>().lastError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyTreeController>(
      builder: (context, ctrl, _) {
        final scheme = Theme.of(context).colorScheme;
        final tree = ctrl.activeTree;
        if (tree == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Tạo hoặc chọn một cây gia phả (tab Home) để xem sự kiện.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          );
        }
        final items = _filtered(ctrl.events);
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Tất cả')),
                    ButtonSegment(value: 1, label: Text('Sắp tới')),
                    ButtonSegment(value: 2, label: Text('Đã qua')),
                  ],
                  selected: {_segment},
                  onSelectionChanged: (s) =>
                      setState(() => _segment = s.first),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: const Text('Mọi loại'),
                      selected: _kindFilter == null,
                      onSelected: (_) => setState(() => _kindFilter = null),
                    ),
                    for (final k in FamilyEventKind.values)
                      FilterChip(
                        label: Text(k.viLabel),
                        selected: _kindFilter == k,
                        onSelected: (_) => setState(() => _kindFilter = k),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có sự kiện.\nNhấn + để thêm.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = items[i];
                          final name = _personName(ctrl, e.personId) ?? '—';
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Icon(_iconFor(e.eventKind)),
                              ),
                              title: Text(e.displayTitle),
                              subtitle: Text(
                                '${_formatDdMmYyyy(e.eventDate)} · $name'
                                '${e.notes != null && e.notes!.isNotEmpty ? '\n${e.notes}' : ''}'
                                '${e.reminderEnabled ? '\nNhắc: ${e.reminderDays ?? 1} ngày trước' : ''}',
                              ),
                              isThreeLine: true,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => EventEditPage(existing: e),
                                  ),
                                );
                              },
                              onLongPress: () async {
                                await showModalBottomSheet<void>(
                                  context: context,
                                  showDragHandle: true,
                                  builder: (ctx) => SafeArea(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ListTile(
                                          leading:
                                              const Icon(Icons.edit_outlined),
                                          title: const Text('Chỉnh sửa'),
                                          onTap: () async {
                                            Navigator.pop(ctx);
                                            if (!context.mounted) return;
                                            await Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    EventEditPage(existing: e),
                                              ),
                                            );
                                          },
                                        ),
                                        ListTile(
                                          leading: Icon(
                                            Icons.delete_outline,
                                            color: scheme.error,
                                          ),
                                          title: Text(
                                            'Xóa',
                                            style: TextStyle(
                                                color: scheme.error),
                                          ),
                                          onTap: () async {
                                            Navigator.pop(ctx);
                                            if (!context.mounted) return;
                                            await _confirmDelete(context, e);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: ctrl.persons.isEmpty
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EventEditPage(),
                      ),
                    );
                  },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
