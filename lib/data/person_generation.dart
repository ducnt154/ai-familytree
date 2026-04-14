import 'models/person.dart';
import 'models/relationship.dart';
import 'models/relationship_kind.dart';

/// Tính chỉ số thế hệ (0 = gốc) theo cạnh cha/mẹ → con.
///
/// Dùng đường đi ngắn nhất theo hướng từ người không có cha/mẹ trong đồ thị.
Map<String, int> computePersonGenerations({
  required List<Person> persons,
  required List<Relationship> relationships,
}) {
  if (persons.isEmpty) return {};
  final byId = {for (final p in persons) p.id: p};
  final childIds = <String>{};

  for (final r in relationships) {
    if (r.kind != RelationshipKind.parentChild) continue;
    if (!byId.containsKey(r.fromPersonId) || !byId.containsKey(r.toPersonId)) {
      continue;
    }
    childIds.add(r.toPersonId);
  }

  var roots = persons
      .map((p) => p.id)
      .where((id) => !childIds.contains(id))
      .toList()
    ..sort();
  if (roots.isEmpty) {
    roots = persons.map((p) => p.id).toList()..sort();
  }

  const inf = 1 << 30;
  final gen = {for (final p in persons) p.id: inf};
  for (final r in roots) {
    gen[r] = 0;
  }

  var changed = true;
  var guard = 0;
  while (changed && guard < persons.length + relationships.length + 8) {
    guard++;
    changed = false;
    for (final r in relationships) {
      if (r.kind != RelationshipKind.parentChild) continue;
      if (!gen.containsKey(r.fromPersonId) || !gen.containsKey(r.toPersonId)) {
        continue;
      }
      final parentG = gen[r.fromPersonId]!;
      if (parentG >= inf) continue;
      final next = parentG + 1;
      if (next < gen[r.toPersonId]!) {
        gen[r.toPersonId] = next;
        changed = true;
      }
    }
  }

  for (final id in gen.keys) {
    if (gen[id]! >= inf) {
      gen[id] = 0;
    }
  }
  return gen;
}
