import 'package:hive/hive.dart';

import '../../models/gender.dart';
import '../../models/person.dart';
import '../hive_type_ids.dart';

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = FamilyTreeHiveTypeIds.person;

  @override
  Person read(BinaryReader reader) {
    final birthDate =
        reader.readBool() ? DateTime.parse(reader.readString()) : null;
    final deathDate =
        reader.readBool() ? DateTime.parse(reader.readString()) : null;
    final notes = reader.readBool() ? reader.readString() : null;
    final id = reader.readString();
    final familyTreeId = reader.readString();
    final displayName = reader.readString();
    final createdAt = DateTime.parse(reader.readString());
    final updatedAt = DateTime.parse(reader.readString());
    Gender? gender;
    if (reader.availableBytes > 0) {
      final hasGender = reader.readBool();
      if (hasGender && reader.availableBytes > 0) {
        final idx = reader.readByte();
        if (idx >= 0 && idx < Gender.values.length) {
          gender = Gender.values[idx];
        }
      }
    }
    String? address;
    if (reader.availableBytes > 0) {
      final hasAddress = reader.readBool();
      if (hasAddress && reader.availableBytes > 0) {
        address = reader.readString();
      }
    }
    return Person(
      id: id,
      familyTreeId: familyTreeId,
      displayName: displayName,
      gender: gender,
      birthDate: birthDate,
      deathDate: deathDate,
      notes: notes,
      address: address,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer.writeBool(obj.birthDate != null);
    if (obj.birthDate != null) {
      writer.writeString(obj.birthDate!.toIso8601String());
    }
    writer.writeBool(obj.deathDate != null);
    if (obj.deathDate != null) {
      writer.writeString(obj.deathDate!.toIso8601String());
    }
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) {
      writer.writeString(obj.notes!);
    }
    writer
      ..writeString(obj.id)
      ..writeString(obj.familyTreeId)
      ..writeString(obj.displayName)
      ..writeString(obj.createdAt.toIso8601String())
      ..writeString(obj.updatedAt.toIso8601String());
    writer.writeBool(obj.gender != null);
    if (obj.gender != null) {
      writer.writeByte(obj.gender!.index);
    }
    writer.writeBool(obj.address != null);
    if (obj.address != null) {
      writer.writeString(obj.address!);
    }
  }
}
