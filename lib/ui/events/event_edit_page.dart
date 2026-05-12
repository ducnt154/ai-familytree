import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vnlunar/vnlunar.dart';

import '../../data/lunar_solar.dart';
import '../../data/models/family_event.dart';
import '../../data/models/family_event_kind.dart';
import '../../providers/family_tree_controller.dart';

/// Form thêm/sửa sự kiện (MVP offline) — dùng trong [EventEditPage] hoặc bottom sheet.
class EventEditBody extends StatefulWidget {
  const EventEditBody({
    super.key,
    this.existing,
    required this.onCancel,
    required this.onSaved,
    this.showSheetHeader = false,
  });

  final FamilyEvent? existing;
  final VoidCallback onCancel;
  final VoidCallback onSaved;
  final bool showSheetHeader;

  @override
  State<EventEditBody> createState() => _EventEditBodyState();
}

class _EventEditBodyState extends State<EventEditBody> {
  String? _personId;
  FamilyEventKind _kind = FamilyEventKind.birthday;
  final _title = TextEditingController();
  final _notes = TextEditingController();
  bool _lunarMode = false;
  bool _lunarLeap = false;
  bool _repeatYearly = false;
  DateTime? _solarUtc;
  late int _lunarY;
  late int _lunarM;
  late int _lunarD;
  bool _reminder = false;
  int _reminderDays = 1;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    if (e != null) {
      _personId = e.personId;
      _kind = e.eventKind;
      if (e.customTitle != null) _title.text = e.customTitle!;
      _notes.text = e.notes ?? '';
      _lunarMode = e.isLunarDate;
      _lunarLeap = e.lunarLeapMonth;
      _repeatYearly = e.repeatYearly;
      _solarUtc = e.eventDate;
      _lunarY = e.lunarYear ?? e.eventDate.year;
      _lunarM = e.lunarMonth ?? 1;
      _lunarD = e.lunarDay ?? 1;
      _reminder = e.reminderEnabled;
      _reminderDays = e.reminderDays ?? 1;
    } else {
      _solarUtc = DateTime.utc(now.year, now.month, now.day, 12);
      final l = Lunar.fromSolar(Solar(now));
      _lunarY = l.year;
      _lunarM = l.month;
      _lunarD = l.day;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_personId == null && widget.existing == null) {
      final people = context.read<FamilyTreeController>().persons;
      if (people.isNotEmpty) {
        _personId = people.first.id;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickSolar() async {
    final base = _solarUtc ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(base.year, base.month, base.day),
      firstDate: DateTime(1800),
      lastDate: DateTime(DateTime.now().year + 50),
    );
    if (picked != null) {
      setState(() {
        _solarUtc = DateTime.utc(picked.year, picked.month, picked.day, 12);
      });
    }
  }

  Future<void> _save() async {
    final ctrl = context.read<FamilyTreeController>();
    final people = ctrl.persons;
    String? resolvedPersonId() {
      final id = _personId;
      if (id != null && people.any((p) => p.id == id)) return id;
      return people.isNotEmpty ? people.first.id : null;
    }

    final pid = resolvedPersonId();
    if (pid == null || pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn thành viên.')),
      );
      return;
    }

    late final DateTime solarUtc;
    if (_lunarMode) {
      try {
        solarUtc = solarUtcDateFromLunar(
          lunarYear: _lunarY,
          lunarMonth: _lunarM,
          lunarDay: _lunarD,
          lunarLeapMonth: _lunarLeap,
        );
      } on ArgumentError {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ngày âm không hợp lệ (kiểm tra tháng nhuận / số ngày).',
            ),
          ),
        );
        return;
      }
    } else {
      final d = _solarUtc;
      if (d == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chọn ngày dương lịch.')),
        );
        return;
      }
      solarUtc = d;
    }

    await ctrl.saveFamilyEvent(
      existing: widget.existing,
      personId: pid,
      kind: _kind,
      customTitle: _title.text,
      eventDate: solarUtc,
      isLunarDate: _lunarMode,
      lunarYear: _lunarMode ? _lunarY : null,
      lunarMonth: _lunarMode ? _lunarM : null,
      lunarDay: _lunarMode ? _lunarD : null,
      lunarLeapMonth: _lunarMode && _lunarLeap,
      repeatYearly: _repeatYearly,
      notes: _notes.text,
      reminderEnabled: _reminder,
      reminderDays: _reminder ? _reminderDays : null,
    );
    if (!mounted) return;
    final err = ctrl.lastError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    widget.onSaved();
  }

  String _solarLabel() {
    final d = _solarUtc;
    if (d == null) return 'Chưa chọn';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyTreeController>(
      builder: (context, ctrl, _) {
        final people = ctrl.persons;
        String? resolvedPersonId() {
          final id = _personId;
          if (id != null && people.any((p) => p.id == id)) return id;
          return people.isNotEmpty ? people.first.id : null;
        }

        final pid = resolvedPersonId();
        final years = List<int>.generate(201, (i) => 1800 + i);
        final months = List<int>.generate(12, (i) => i + 1);
        final days = List<int>.generate(30, (i) => i + 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showSheetHeader) ...[
              Text(
                widget.existing == null ? 'Thêm sự kiện' : 'Sửa sự kiện',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
            ],
            if (people.isEmpty)
              Text(
                'Chưa có thành viên — thêm thành viên ở tab Add trước.',
                style: Theme.of(context).textTheme.bodyLarge,
              )
            else ...[
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Tên sự kiện (tuỳ chọn)',
                  hintText: 'Để trống sẽ dùng tên loại',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: pid,
                decoration: const InputDecoration(
                  labelText: 'Thành viên',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final p in people)
                    DropdownMenuItem(value: p.id, child: Text(p.displayName)),
                ],
                onChanged: (v) => setState(() => _personId = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FamilyEventKind>(
                value: _kind,
                decoration: const InputDecoration(
                  labelText: 'Loại sự kiện',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final k in FamilyEventKind.values)
                    DropdownMenuItem(
                      value: k,
                      child: Text(k.viLabel),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _kind = v);
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Dương lịch')),
                  ButtonSegment(value: true, label: Text('Âm lịch')),
                ],
                selected: {_lunarMode},
                onSelectionChanged: (s) {
                  setState(() {
                    _lunarMode = s.first;
                    if (_lunarMode) {
                      final base = _solarUtc ?? DateTime.now();
                      final l = Lunar.fromSolar(Solar(base));
                      _lunarY = l.year;
                      _lunarM = l.month;
                      _lunarD = l.day;
                      _lunarLeap = l.leapMonth ?? false;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              if (!_lunarMode)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày (dương lịch)'),
                  subtitle: Text(_solarLabel()),
                  trailing: FilledButton.tonal(
                    onPressed: _pickSolar,
                    child: const Text('Chọn'),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _lunarD,
                        decoration: const InputDecoration(
                          labelText: 'Ngày',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final d in days)
                            DropdownMenuItem(value: d, child: Text('$d')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _lunarD = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _lunarM,
                        decoration: const InputDecoration(
                          labelText: 'Tháng',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final m in months)
                            DropdownMenuItem(value: m, child: Text('$m')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _lunarM = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _lunarY,
                        decoration: const InputDecoration(
                          labelText: 'Năm âm',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final y in years)
                            DropdownMenuItem(value: y, child: Text('$y')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _lunarY = v);
                        },
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tháng nhuận'),
                  value: _lunarLeap,
                  onChanged: (v) => setState(() => _lunarLeap = v ?? false),
                ),
              ],
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lặp lại hàng năm'),
                subtitle: const Text(
                  'Danh sách sort theo lần gần nhất tới; tab Đã qua chỉ hiện sự kiện một lần.',
                ),
                value: _repeatYearly,
                onChanged: (v) => setState(() => _repeatYearly = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Mô tả / ghi chú (tuỳ chọn)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bật nhắc nhở'),
                subtitle: const Text(
                  'Lên lịch thông báo cục bộ: child issue / bước sau.',
                ),
                value: _reminder,
                onChanged: (v) => setState(() => _reminder = v),
              ),
              if (_reminder) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: {1, 3, 7}.contains(_reminderDays) ? _reminderDays : 1,
                  decoration: const InputDecoration(
                    labelText: 'Nhắc trước',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 ngày')),
                    DropdownMenuItem(value: 3, child: Text('3 ngày')),
                    DropdownMenuItem(value: 7, child: Text('1 tuần (7 ngày)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _reminderDays = v);
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: people.isEmpty ? null : _save,
                      child: const Text('Lưu'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Trang full-screen sửa sự kiện.
class EventEditPage extends StatelessWidget {
  const EventEditPage({super.key, this.existing});

  final FamilyEvent? existing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(existing == null ? 'Thêm sự kiện' : 'Sửa sự kiện'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: EventEditBody(
          existing: existing,
          onCancel: () => Navigator.of(context).pop(),
          onSaved: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
