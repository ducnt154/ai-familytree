import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/models/gender.dart';
import '../../data/models/person.dart';
import '../../data/models/relationship.dart';
import '../../data/models/relationship_kind.dart';
import '../../providers/family_tree_controller.dart';

/// Tab Add: form thành viên (CRUD + avatar), form quan hệ (thêm/xóa).
class AddMembersPage extends StatelessWidget {
  const AddMembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyTreeController>(
      builder: (context, ctrl, _) {
        if (ctrl.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.activeTreeId == null) {
          return Center(
            child: Text(
              'Chưa có cây gia phả — tạo cây ở tab Home trước.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'Thành viên',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const _MemberFormCard(),
            const SizedBox(height: 20),
            Text(
              'Danh sách (${ctrl.persons.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (ctrl.persons.isEmpty)
              Text(
                'Chưa có thành viên.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ...ctrl.persons.map((p) => _MemberTile(person: p)),
            const SizedBox(height: 24),
            Text(
              'Quan hệ',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const _RelationshipFormCard(),
            const SizedBox(height: 12),
            if (ctrl.relationships.isEmpty)
              Text(
                'Chưa có quan hệ.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ...ctrl.relationships.map((r) => _RelationshipTile(rel: r)),
            if (ctrl.lastError != null) ...[
              const SizedBox(height: 16),
              Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color:
                              Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          ctrl.lastError!,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: ctrl.clearError,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MemberFormCard extends StatefulWidget {
  const _MemberFormCard();

  @override
  State<_MemberFormCard> createState() => _MemberFormCardState();
}

class _MemberFormCardState extends State<_MemberFormCard> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime? _birth;
  DateTime? _death;
  Gender? _gender;
  String? _pickedPath;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _pickedPath = x.path);
  }

  Future<void> _submit(BuildContext context) async {
    final ctrl = context.read<FamilyTreeController>();
    await ctrl.addPerson(
      displayName: _nameCtrl.text,
      gender: _gender,
      birthDate: _birth,
      deathDate: _death,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      pickedAvatarTempPath: _pickedPath,
    );
    if (!context.mounted) return;
    final err = ctrl.lastError;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      _nameCtrl.clear();
      _addressCtrl.clear();
      _notesCtrl.clear();
      setState(() {
        _birth = null;
        _death = null;
        _gender = null;
        _pickedPath = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm thành viên')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên hiển thị *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Gender?>(
              value: _gender,
              decoration: const InputDecoration(
                labelText: 'Giới tính',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<Gender?>(
                    value: null, child: Text('Chưa chọn')),
                ...Gender.values.map(
                  (g) => DropdownMenuItem<Gender?>(
                      value: g, child: Text(g.viLabel)),
                ),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _birth ?? DateTime(1990),
                        firstDate: DateTime(1500),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _birth = d);
                    },
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(
                        _birth == null ? 'Ngày sinh' : _formatDate(_birth!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _death ?? DateTime(2000),
                        firstDate: DateTime(1500),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _death = d);
                    },
                    icon: const Icon(Icons.close),
                    label: Text(
                        _death == null ? 'Ngày mất' : _formatDate(_death!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ (bản đồ)',
                hintText: 'Ví dụ: 123 Đường ABC, Quận 1, TP.HCM',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_pickedPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_pickedPath!),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Icon(Icons.person, size: 40, color: scheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                        _pickedPath == null ? 'Chọn ảnh đại diện' : 'Đổi ảnh'),
                  ),
                ),
                if (_pickedPath != null)
                  IconButton(
                    onPressed: () => setState(() => _pickedPath = null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _submit(context),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Thêm thành viên'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }
}

String _initial(String name) {
  final t = name.trim();
  if (t.isEmpty) return '?';
  return t.substring(0, 1).toUpperCase();
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<FamilyTreeController>();
    final path = person.avatarLocalPath;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundImage: path != null && File(path).existsSync()
              ? FileImage(File(path))
              : null,
          child: path == null || !File(path).existsSync()
              ? Text(_initial(person.displayName))
              : null,
        ),
        title: Text(person.displayName),
        subtitle: Text(
          [
            if (person.gender != null) person.gender!.viLabel,
            if (person.birthDate != null)
              'Sinh: ${_formatDate(person.birthDate!)}',
            if (person.deathDate != null)
              'Mất: ${_formatDate(person.deathDate!)}',
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openEdit(context, person),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xóa thành viên?'),
                    content: Text(
                        'Xóa "${person.displayName}" và mọi quan hệ liên quan?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Xóa')),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await ctrl.removePerson(person.id);
                  if (context.mounted && ctrl.lastError != null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(ctrl.lastError!)));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }

  static Future<void> _openEdit(BuildContext context, Person person) async {
    final nameCtrl = TextEditingController(text: person.displayName);
    final addressCtrl = TextEditingController(text: person.address ?? '');
    final notesCtrl = TextEditingController(text: person.notes ?? '');
    DateTime? birth = person.birthDate;
    DateTime? death = person.deathDate;
    Gender? gender = person.gender;
    String? pickedPath;
    var removeAvatar = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Sửa thành viên'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Tên *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<Gender?>(
                      value: gender,
                      decoration: const InputDecoration(
                        labelText: 'Giới tính',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<Gender?>(
                            value: null, child: Text('Chưa chọn')),
                        ...Gender.values.map(
                          (g) => DropdownMenuItem<Gender?>(
                              value: g, child: Text(g.viLabel)),
                        ),
                      ],
                      onChanged: (v) => setLocal(() => gender = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: birth ?? DateTime(1990),
                                firstDate: DateTime(1500),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) setLocal(() => birth = d);
                            },
                            child: Text(birth == null
                                ? 'Ngày sinh'
                                : _formatDate(birth!)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: ctx,
                                initialDate: death ?? DateTime(2000),
                                firstDate: DateTime(1500),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) setLocal(() => death = d);
                            },
                            child: Text(death == null
                                ? 'Ngày mất'
                                : _formatDate(death!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ (bản đồ)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Ghi chú', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (pickedPath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(pickedPath!),
                                width: 48, height: 48, fit: BoxFit.cover),
                          )
                        else if (person.avatarLocalPath != null &&
                            File(person.avatarLocalPath!).existsSync())
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(person.avatarLocalPath!),
                                width: 48, height: 48, fit: BoxFit.cover),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final x = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery);
                              if (x != null) {
                                setLocal(() {
                                  pickedPath = x.path;
                                  removeAvatar = false;
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Đổi ảnh'),
                          ),
                        ),
                        if (person.avatarLocalPath != null ||
                            pickedPath != null)
                          IconButton(
                            onPressed: () => setLocal(() {
                              pickedPath = null;
                              removeAvatar = true;
                            }),
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Hủy')),
                FilledButton(
                  onPressed: () async {
                    final ctrl = context.read<FamilyTreeController>();
                    final addr = addressCtrl.text.trim();
                    final updated = person.copyWith(
                      displayName: nameCtrl.text.trim(),
                      gender: gender,
                      clearGender: gender == null,
                      birthDate: birth,
                      deathDate: death,
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                      address: addr.isEmpty ? null : addr,
                      clearAddress: addr.isEmpty,
                    );
                    await ctrl.updatePerson(
                      updated,
                      pickedAvatarTempPath: pickedPath,
                      removeAvatar: removeAvatar,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted && ctrl.lastError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ctrl.lastError!)));
                    }
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RelationshipFormCard extends StatefulWidget {
  const _RelationshipFormCard();

  @override
  State<_RelationshipFormCard> createState() => _RelationshipFormCardState();
}

class _RelationshipFormCardState extends State<_RelationshipFormCard> {
  String? _fromId;
  String? _toId;
  RelationshipKind _kind = RelationshipKind.parentChild;

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyTreeController>(
      builder: (context, ctrl, _) {
        final persons = ctrl.persons;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: _fromId != null && persons.any((p) => p.id == _fromId)
                      ? _fromId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Từ (nguồn)',
                    border: OutlineInputBorder(),
                  ),
                  items: persons
                      .map(
                        (p) => DropdownMenuItem(
                            value: p.id, child: Text(p.displayName)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _fromId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _toId != null && persons.any((p) => p.id == _toId)
                      ? _toId
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Đến (đích)',
                    border: OutlineInputBorder(),
                  ),
                  items: persons
                      .map(
                        (p) => DropdownMenuItem(
                            value: p.id, child: Text(p.displayName)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _toId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RelationshipKind>(
                  value: _kind,
                  decoration: const InputDecoration(
                    labelText: 'Loại quan hệ',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: RelationshipKind.parentChild,
                      child: Text('Cha/mẹ → con'),
                    ),
                    DropdownMenuItem(
                      value: RelationshipKind.spouse,
                      child: Text('Vợ/chồng / partner'),
                    ),
                    DropdownMenuItem(
                      value: RelationshipKind.sibling,
                      child: Text('Anh/chị/em'),
                    ),
                    DropdownMenuItem(
                      value: RelationshipKind.other,
                      child: Text('Khác'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _kind = v);
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: persons.length < 2 ||
                          _fromId == null ||
                          _toId == null ||
                          _fromId == _toId
                      ? null
                      : () async {
                          await ctrl.addRelationship(
                            fromPersonId: _fromId!,
                            toPersonId: _toId!,
                            kind: _kind,
                          );
                          if (!context.mounted) return;
                          if (ctrl.lastError != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ctrl.lastError!)));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã thêm quan hệ')),
                            );
                          }
                        },
                  icon: const Icon(Icons.link),
                  label: const Text('Thêm quan hệ'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RelationshipTile extends StatelessWidget {
  const _RelationshipTile({required this.rel});

  final Relationship rel;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.read<FamilyTreeController>();
    final persons = ctrl.persons;
    String nameFor(String id) {
      for (final p in persons) {
        if (p.id == id) return p.displayName;
      }
      return id;
    }

    final fromName = nameFor(rel.fromPersonId);
    final toName = nameFor(rel.toPersonId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('$fromName → $toName'),
        subtitle: Text(_kindLabel(rel.kind)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await ctrl.removeRelationship(rel.id);
            if (context.mounted && ctrl.lastError != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(ctrl.lastError!)));
            }
          },
        ),
      ),
    );
  }

  static String _kindLabel(RelationshipKind k) {
    switch (k) {
      case RelationshipKind.parentChild:
        return 'Cha/mẹ — con';
      case RelationshipKind.spouse:
        return 'Vợ/chồng';
      case RelationshipKind.sibling:
        return 'Anh/chị/em';
      case RelationshipKind.other:
        return 'Khác';
    }
  }
}
