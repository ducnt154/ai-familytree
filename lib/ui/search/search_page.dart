import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/gender.dart';
import '../../data/models/person.dart';
import '../../data/person_generation.dart';
import '../../providers/family_tree_controller.dart';

/// Tab Search: tìm theo tên + lọc giới tính, thế hệ, còn sống/mất, năm sinh (BRD slice 5).
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

enum _LivingFilter { any, living, deceased }

class _SearchPageState extends State<SearchPage> {
  final _queryCtrl = TextEditingController();
  Gender? _genderFilter;
  bool _onlyUnsetGender = false;
  int? _generationFilter;
  _LivingFilter _living = _LivingFilter.any;
  int? _birthYearMin;
  int? _birthYearMax;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  List<Person> _applyFilters(
    List<Person> persons,
    Map<String, int> generations,
  ) {
    final q = _queryCtrl.text.trim().toLowerCase();
    return persons.where((p) {
      if (q.isNotEmpty && !p.displayName.toLowerCase().contains(q)) {
        return false;
      }
      if (_onlyUnsetGender) {
        if (p.gender != null) return false;
      } else if (_genderFilter != null && p.gender != _genderFilter) {
        return false;
      }
      if (_generationFilter != null) {
        if ((generations[p.id] ?? 0) != _generationFilter) return false;
      }
      switch (_living) {
        case _LivingFilter.living:
          if (p.deathDate != null) return false;
          break;
        case _LivingFilter.deceased:
          if (p.deathDate == null) return false;
          break;
        case _LivingFilter.any:
          break;
      }
      final y = p.birthDate?.year;
      if (_birthYearMin != null && (y == null || y < _birthYearMin!)) {
        return false;
      }
      if (_birthYearMax != null && (y == null || y > _birthYearMax!)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: MediaQuery.of(ctx).padding.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bộ lọc', style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Text('Giới tính',
                        style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tất cả'),
                          selected: !_onlyUnsetGender && _genderFilter == null,
                          onSelected: (_) => setSheet(() {
                            _genderFilter = null;
                            _onlyUnsetGender = false;
                          }),
                        ),
                        ChoiceChip(
                          label: const Text('Chưa nhập'),
                          selected: _onlyUnsetGender,
                          onSelected: (_) => setSheet(() {
                            _onlyUnsetGender = true;
                            _genderFilter = null;
                          }),
                        ),
                        for (final g in Gender.values)
                          ChoiceChip(
                            label: Text(g.viLabel),
                            selected: !_onlyUnsetGender && _genderFilter == g,
                            onSelected: (_) => setSheet(() {
                              _onlyUnsetGender = false;
                              _genderFilter = g;
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Thế hệ', style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Consumer<FamilyTreeController>(
                      builder: (context, ctrl, _) {
                        final genMap = computePersonGenerations(
                          persons: ctrl.persons,
                          relationships: ctrl.relationships,
                        );
                        final maxG =
                            genMap.values.fold<int>(0, (a, b) => a > b ? a : b);
                        final opts = <DropdownMenuItem<int?>>[
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Mọi thế hệ'),
                          ),
                          for (var i = 0; i <= maxG; i++)
                            DropdownMenuItem<int?>(
                              value: i,
                              child: Text('Thế hệ $i'),
                            ),
                        ];
                        return DropdownButtonFormField<int?>(
                          value: _generationFilter,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: opts,
                          onChanged: (v) =>
                              setSheet(() => _generationFilter = v),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Text('Trạng thái',
                        style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<_LivingFilter>(
                      segments: const [
                        ButtonSegment(
                            value: _LivingFilter.any, label: Text('Tất cả')),
                        ButtonSegment(
                            value: _LivingFilter.living,
                            label: Text('Còn sống')),
                        ButtonSegment(
                            value: _LivingFilter.deceased,
                            label: Text('Đã mất')),
                      ],
                      selected: {_living},
                      onSelectionChanged: (s) =>
                          setSheet(() => _living = s.first),
                    ),
                    const SizedBox(height: 20),
                    Text('Năm sinh', style: Theme.of(ctx).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _birthYearMin,
                            decoration: const InputDecoration(
                              labelText: 'Từ',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('—'),
                              ),
                              for (var y = DateTime.now().year; y >= 1850; y--)
                                DropdownMenuItem<int?>(
                                    value: y, child: Text('$y')),
                            ],
                            onChanged: (v) => setSheet(() => _birthYearMin = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: _birthYearMax,
                            decoration: const InputDecoration(
                              labelText: 'Đến',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('—'),
                              ),
                              for (var y = DateTime.now().year; y >= 1850; y--)
                                DropdownMenuItem<int?>(
                                    value: y, child: Text('$y')),
                            ],
                            onChanged: (v) => setSheet(() => _birthYearMax = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        setSheet(() {
                          _genderFilter = null;
                          _onlyUnsetGender = false;
                          _generationFilter = null;
                          _living = _LivingFilter.any;
                          _birthYearMin = null;
                          _birthYearMax = null;
                        });
                      },
                      icon: const Icon(Icons.filter_alt_off_outlined),
                      label: const Text('Xóa bộ lọc'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyTreeController>(
      builder: (context, ctrl, _) {
        if (ctrl.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (ctrl.activeTreeId == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Chưa có cây gia phả — tạo cây ở tab Home trước.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }

        final generations = computePersonGenerations(
          persons: ctrl.persons,
          relationships: ctrl.relationships,
        );
        final filtered = _applyFilters(ctrl.persons, generations);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tìm theo tên…',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        suffixIcon: _queryCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _queryCtrl.clear();
                                  setState(() {});
                                },
                              ),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bộ lọc',
                    onPressed: () => _openFilterSheet(context),
                    icon: Badge(
                      isLabelVisible: _genderFilter != null ||
                          _onlyUnsetGender ||
                          _generationFilter != null ||
                          _living != _LivingFilter.any ||
                          _birthYearMin != null ||
                          _birthYearMax != null,
                      child: const Icon(Icons.tune),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${filtered.length} / ${ctrl.persons.length} thành viên',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Không có kết quả.',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        final g = generations[p.id] ?? 0;
                        return _SearchPersonTile(person: p, generation: g);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchPersonTile extends StatelessWidget {
  const _SearchPersonTile({required this.person, required this.generation});

  final Person person;
  final int generation;

  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.substring(0, 1).toUpperCase();
  }

  static String _formatDate(DateTime d) {
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }

  @override
  Widget build(BuildContext context) {
    final path = person.avatarLocalPath;
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      'Thế hệ $generation',
      if (person.gender != null) person.gender!.viLabel else 'Giới tính: —',
      if (person.birthDate != null) 'Sinh: ${_formatDate(person.birthDate!)}',
      if (person.deathDate != null) 'Mất: ${_formatDate(person.deathDate!)}',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundImage: path != null && File(path).existsSync()
              ? FileImage(File(path))
              : null,
          child: path == null || !File(path).existsSync()
              ? Text(_initial(person.displayName))
              : null,
        ),
        title: Text(person.displayName),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: person.deathDate == null
            ? Icon(Icons.favorite_outline, color: scheme.primary, size: 22)
            : Icon(Icons.close, color: scheme.outline, size: 22),
      ),
    );
  }
}
