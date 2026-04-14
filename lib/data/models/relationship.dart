import 'relationship_kind.dart';

/// Cạnh giữa hai người trong một cây (có hướng tùy [RelationshipKind]).
class Relationship {
  Relationship({
    required this.id,
    required this.familyTreeId,
    required this.fromPersonId,
    required this.toPersonId,
    required this.kind,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String familyTreeId;
  final String fromPersonId;
  final String toPersonId;
  final RelationshipKind kind;
  final DateTime createdAt;
  final DateTime updatedAt;

  Relationship copyWith({
    String? id,
    String? familyTreeId,
    String? fromPersonId,
    String? toPersonId,
    RelationshipKind? kind,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Relationship(
      id: id ?? this.id,
      familyTreeId: familyTreeId ?? this.familyTreeId,
      fromPersonId: fromPersonId ?? this.fromPersonId,
      toPersonId: toPersonId ?? this.toPersonId,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
