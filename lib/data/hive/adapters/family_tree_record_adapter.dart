import 'package:hive/hive.dart';

import '../../models/family_tree_record.dart';
import '../hive_type_ids.dart';

class FamilyTreeRecordAdapter extends TypeAdapter<FamilyTreeRecord> {
  @override
  final int typeId = FamilyTreeHiveTypeIds.familyTreeRecord;

  @override
  FamilyTreeRecord read(BinaryReader reader) {
    return FamilyTreeRecord(
      id: reader.readString(),
      name: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, FamilyTreeRecord obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeString(obj.createdAt.toIso8601String())
      ..writeString(obj.updatedAt.toIso8601String());
  }
}
