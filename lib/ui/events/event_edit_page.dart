import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/family_event.dart';
import '../../data/models/family_event_kind.dart';
import '../../providers/family_tree_controller.dart';

/// Form thêm/sửa sự kiện (MVP offline).
class EventEditPage extends StatefulWidget {
  const EventEditPage({super.key, this.existing});

  final FamilyEvent? existing;

  @override
  State<EventEditPage> createState() => _EventEditPageState();
}

class _EventEditPageState extends State<EventEditPage> {
  String? _personId;
  FamilyEventKind _kind = FamilyEventKind.birthday;
  DateTime? _date;
  final _notes = TextEditingController();
  bool _reminder = false;
  int _reminderDays = 1;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _personId = e.personId;
      _kind = e.eventKind;
      _date = e.eventDate;
      if (e.notes != null) _notes.text = e.notes!;
      _reminder = e.reminderEnabled;
      _reminderDays = e.reminderDays ?? 1;
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
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _date ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(initial.year, initial.month, initial.day),
      firstDate: DateTime(1800),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime.utc(picked.year, picked.month, picked.day);
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
    final d = _date;
    if (pid == null || pid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn thành viên.')),
      );
      return;
    }
    if (d == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn ngày sự kiện.')),
      );
      return;
    }
    await ctrl.saveFamilyEvent(
      existing: widget.existing,
      personId: pid,
      kind: _kind,
      eventDate: d,
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
    Navigator.of(context).pop();
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
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.existing == null ? 'Thêm sự kiện' : 'Sửa sự kiện'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (people.isEmpty)
                Text(
                  'Chưa có thành viên — thêm thành viên ở tab Add trước.',
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              else ...[
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ngày sự kiện'),
                  subtitle: Text(
                    _date == null
                        ? 'Chưa chọn'
                        : '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}',
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: _pickDate,
                    child: const Text('Chọn'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notes,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (tuỳ chọn)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bật nhắc nhở'),
                  subtitle: const Text(
                    'Lên lịch thông báo cục bộ sẽ bổ sung ở bước sau (MVP lưu cấu hình).',
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
                        onPressed: () => Navigator.of(context).pop(),
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
          ),
        );
      },
    );
  }
}
