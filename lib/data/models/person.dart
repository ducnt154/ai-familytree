import 'gender.dart';

/// Thành viên trong một [FamilyTreeRecord].
class Person {
  Person({
    required this.id,
    required this.familyTreeId,
    required this.displayName,
    this.gender,
    this.birthDate,
    this.deathDate,
    this.notes,
    this.address,
    this.avatarLocalPath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String familyTreeId;
  final String displayName;

  /// `null` = chưa khai báo (bản ghi cũ hoặc bỏ trống).
  final Gender? gender;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? notes;

  /// Địa chỉ tự do (dùng tìm bản đồ / Google Maps).
  final String? address;

  /// Đường dẫn file ảnh trên máy (app documents); không nằm trong Hive [PersonAdapter].
  final String? avatarLocalPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  Person copyWith({
    String? id,
    String? familyTreeId,
    String? displayName,
    Gender? gender,
    bool clearGender = false,
    DateTime? birthDate,
    DateTime? deathDate,
    String? notes,
    String? address,
    bool clearAddress = false,
    String? avatarLocalPath,
    bool clearAvatar = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Person(
      id: id ?? this.id,
      familyTreeId: familyTreeId ?? this.familyTreeId,
      displayName: displayName ?? this.displayName,
      gender: clearGender ? null : (gender ?? this.gender),
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      notes: notes ?? this.notes,
      address: clearAddress ? null : (address ?? this.address),
      avatarLocalPath:
          clearAvatar ? null : (avatarLocalPath ?? this.avatarLocalPath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
