import '../lunar_solar.dart';
import 'family_event_kind.dart';

/// Sự kiện gắn với một thành viên trong cây gia phả (offline-first).
class FamilyEvent {
  FamilyEvent({
    required this.id,
    required this.familyTreeId,
    required this.personId,
    required this.eventKind,
    this.customTitle,
    required this.eventDate,
    this.isLunarDate = false,
    this.lunarYear,
    this.lunarMonth,
    this.lunarDay,
    this.lunarLeapMonth = false,
    this.repeatYearly = false,
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

  /// Tên hiển thị tuỳ chọn; nếu trống dùng nhãn loại ([eventKind]).
  final String? customTitle;

  /// Ngày dương đã quy đổi (UTC date-only, giờ 12:00 UTC) — dùng sort & lịch dương.
  final DateTime eventDate;

  /// Nguồn nhập là âm lịch; [lunarYear]/[lunarMonth]/[lunarDay] mô tả ngày gốc.
  final bool isLunarDate;
  final int? lunarYear;
  final int? lunarMonth;
  final int? lunarDay;
  final bool lunarLeapMonth;

  /// Lặp hàng năm (sinh nhật / giỗ…): sort theo lần xảy ra **tiếp theo** kể từ [anchor].
  final bool repeatYearly;

  final String? notes;
  final bool reminderEnabled;

  /// Số ngày nhắc trước (1, 3, 7…) khi [reminderEnabled].
  final int? reminderDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayTitle {
    final t = customTitle?.trim();
    if (t != null && t.isNotEmpty) return t;
    return eventKind.viLabel;
  }

  /// Ordinal yyyyMMdd (lịch dân sự) của lần xảy ra tiếp theo để sort / lọc.
  int nextOccurrenceOrdinal(DateTime anchorLocal) {
    final todayOrd = _dateOrdinal(anchorLocal);
    if (!repeatYearly) {
      return _dateOrdinalUtc(eventDate);
    }
    if (isLunarDate && lunarMonth != null && lunarDay != null) {
      final startY = (lunarYear ?? anchorLocal.year) - 1;
      for (var y = startY; y < startY + 200; y++) {
        try {
          final solar = solarUtcDateFromLunar(
            lunarYear: y,
            lunarMonth: lunarMonth!,
            lunarDay: lunarDay!,
            lunarLeapMonth: lunarLeapMonth,
          );
          final o = _dateOrdinalUtc(solar);
          if (o >= todayOrd) return o;
        } catch (_) {
          continue;
        }
      }
      return _dateOrdinalUtc(eventDate);
    }
    final m = eventDate.month;
    final d = eventDate.day;
    var y = anchorLocal.year;
    var cand = DateTime(y, m, d);
    if (_dateOrdinal(cand) < todayOrd) {
      y++;
      cand = DateTime(y, m, d);
    }
    return _dateOrdinal(cand);
  }

  static int _dateOrdinal(DateTime d) =>
      d.year * 10000 + d.month * 100 + d.day;

  static int _dateOrdinalUtc(DateTime utc) =>
      utc.year * 10000 + utc.month * 100 + utc.day;

  FamilyEvent copyWith({
    String? id,
    String? familyTreeId,
    String? personId,
    FamilyEventKind? eventKind,
    String? customTitle,
    bool clearCustomTitle = false,
    DateTime? eventDate,
    bool? isLunarDate,
    int? lunarYear,
    int? lunarMonth,
    int? lunarDay,
    bool? lunarLeapMonth,
    bool? repeatYearly,
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
      customTitle:
          clearCustomTitle ? null : (customTitle ?? this.customTitle),
      eventDate: eventDate ?? this.eventDate,
      isLunarDate: isLunarDate ?? this.isLunarDate,
      lunarYear: lunarYear ?? this.lunarYear,
      lunarMonth: lunarMonth ?? this.lunarMonth,
      lunarDay: lunarDay ?? this.lunarDay,
      lunarLeapMonth: lunarLeapMonth ?? this.lunarLeapMonth,
      repeatYearly: repeatYearly ?? this.repeatYearly,
      notes: clearNotes ? null : (notes ?? this.notes),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDays:
          clearReminderDays ? null : (reminderDays ?? this.reminderDays),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
