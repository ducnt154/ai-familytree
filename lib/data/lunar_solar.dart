import 'package:vnlunar/vnlunar.dart';

/// Chuyển một ngày âm lịch (VN, timezone 7) sang ngày dương lịch (lịch dân sự).
/// Trả về UTC date-only (giờ 12:00 UTC) để đồng bộ với [FamilyEvent.eventDate].
DateTime solarUtcDateFromLunar({
  required int lunarYear,
  required int lunarMonth,
  required int lunarDay,
  bool lunarLeapMonth = false,
}) {
  final r = convertLunar2Solar(
    lunarDay,
    lunarMonth,
    lunarYear,
    lunarLeapMonth,
  );
  final day = r[0];
  final month = r[1];
  final year = r[2];
  if (day <= 0 || month <= 0 || year <= 0) {
    throw ArgumentError(
      'Không đổi được ngày âm $lunarDay/$lunarMonth/$lunarYear (nhuận=$lunarLeapMonth).',
    );
  }
  return DateTime.utc(year, month, day, 12);
}
