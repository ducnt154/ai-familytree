import 'package:hive/hive.dart';

import '../../models/relationship.dart';
import '../../models/relationship_kind.dart';
import '../hive_type_ids.dart';

class RelationshipAdapter extends TypeAdapter<Relationship> {
  @override
  final int typeId = FamilyTreeHiveTypeIds.relationship;

  @override
  Relationship read(BinaryReader reader) {
    return Relationship(
      id: reader.readString(),
      familyTreeId: reader.readString(),
      fromPersonId: reader.readString(),
      toPersonId: reader.readString(),
      kind: RelationshipKind.fromCode(reader.readInt()),
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, Relationship obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.familyTreeId)
      ..writeString(obj.fromPersonId)
      ..writeString(obj.toPersonId)
      ..writeInt(obj.kind.code)
      ..writeString(obj.createdAt.toIso8601String())
      ..writeString(obj.updatedAt.toIso8601String());
  }
}
