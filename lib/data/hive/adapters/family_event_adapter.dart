import 'package:hive/hive.dart';

import '../../models/family_event.dart';
import '../../models/family_event_kind.dart';
import '../hive_type_ids.dart';

class FamilyEventAdapter extends TypeAdapter<FamilyEvent> {
  @override
  final int typeId = FamilyTreeHiveTypeIds.familyEvent;

  @override
  FamilyEvent read(BinaryReader reader) {
    final id = reader.readString();
    final familyTreeId = reader.readString();
    final personId = reader.readString();
    final kindIdx = reader.readByte();
    final kind = kindIdx >= 0 && kindIdx < FamilyEventKind.values.length
        ? FamilyEventKind.values[kindIdx]
        : FamilyEventKind.other;
    final eventDate = DateTime.parse(reader.readString());
    final notes = reader.readBool() ? reader.readString() : null;
    final reminderEnabled = reader.readBool();
    final reminderDays = reader.readBool() ? reader.readInt32() : null;
    final createdAt = DateTime.parse(reader.readString());
    final updatedAt = DateTime.parse(reader.readString());

    String? customTitle;
    var isLunarDate = false;
    var repeatYearly = false;
    int? lunarYear;
    int? lunarMonth;
    int? lunarDay;
    var lunarLeapMonth = false;

    if (reader.availableBytes > 0) {
      customTitle = reader.readBool() ? reader.readString() : null;
      isLunarDate = reader.readBool();
      repeatYearly = reader.readBool();
      final ly = reader.readInt32();
      final lm = reader.readByte();
      final ld = reader.readByte();
      lunarLeapMonth = reader.readBool();
      if (isLunarDate && ly > 0 && lm > 0 && ld > 0) {
        lunarYear = ly;
        lunarMonth = lm;
        lunarDay = ld;
      }
    }

    return FamilyEvent(
      id: id,
      familyTreeId: familyTreeId,
      personId: personId,
      eventKind: kind,
      customTitle: customTitle,
      eventDate: eventDate,
      isLunarDate: isLunarDate,
      lunarYear: lunarYear,
      lunarMonth: lunarMonth,
      lunarDay: lunarDay,
      lunarLeapMonth: lunarLeapMonth,
      repeatYearly: repeatYearly,
      notes: notes,
      reminderEnabled: reminderEnabled,
      reminderDays: reminderDays,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyEvent obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.familyTreeId)
      ..writeString(obj.personId)
      ..writeByte(obj.eventKind.index)
      ..writeString(obj.eventDate.toIso8601String())
      ..writeBool(obj.notes != null);
    if (obj.notes != null) {
      writer.writeString(obj.notes!);
    }
    writer.writeBool(obj.reminderEnabled);
    writer.writeBool(obj.reminderDays != null);
    if (obj.reminderDays != null) {
      writer.writeInt32(obj.reminderDays!);
    }
    writer
      ..writeString(obj.createdAt.toIso8601String())
      ..writeString(obj.updatedAt.toIso8601String());

    final t = obj.customTitle?.trim();
    writer.writeBool(t != null && t.isNotEmpty);
    if (t != null && t.isNotEmpty) {
      writer.writeString(t);
    }
    writer.writeBool(obj.isLunarDate);
    writer.writeBool(obj.repeatYearly);
    final ly = obj.isLunarDate ? (obj.lunarYear ?? 0) : 0;
    final lm = obj.isLunarDate ? (obj.lunarMonth ?? 0) : 0;
    final ld = obj.isLunarDate ? (obj.lunarDay ?? 0) : 0;
    writer.writeInt32(ly);
    writer.writeByte(lm.clamp(0, 255));
    writer.writeByte(ld.clamp(0, 255));
    writer.writeBool(obj.lunarLeapMonth);
  }
}
