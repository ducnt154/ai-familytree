import 'family_event_kind.dart';

/// Sự kiện gắn với một thành viên trong cây gia phả (offline-first).
class FamilyEvent {
  FamilyEvent({
    required this.id,
    required this.familyTreeId,
    required this.personId,
    required this.eventKind,
    required this.eventDate,
    this.notes,
    required this.reminderEnabled,
    this.reminderDays,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String familyTreeId;
  final String personId;
  final FamilyEventKind eventKind;

  /// Ngày sự kiện (lưu theo UTC date-only quy ước: giờ 12:00 UTC).
  final DateTime eventDate;
  final String? notes;
  final bool reminderEnabled;

  /// Số ngày nhắc trước (1, 3, 7…) khi [reminderEnabled].
  final int? reminderDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle => eventKind.viLabel;

  FamilyEvent copyWith({
    String? id,
    String? familyTreeId,
    String? personId,
    FamilyEventKind? eventKind,
    DateTime? eventDate,
    String? notes,
    bool clearNotes = false,
    bool? reminderEnabled,
    int? reminderDays,
    bool clearReminderDays = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FamilyEvent(
      id: id ?? this.id,
      familyTreeId: familyTreeId ?? this.familyTreeId,
      personId: personId ?? this.personId,
      eventKind: eventKind ?? this.eventKind,
      eventDate: eventDate ?? this.eventDate,
      notes: clearNotes ? null : (notes ?? this.notes),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDays:
          clearReminderDays ? null : (reminderDays ?? this.reminderDays),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
