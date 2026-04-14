/// Giới tính thành viên (BRD: lọc theo giới tính).
enum Gender {
  male,
  female,
  other,
}

extension GenderLabel on Gender {
  String get viLabel {
    switch (this) {
      case Gender.male:
        return 'Nam';
      case Gender.female:
        return 'Nữ';
      case Gender.other:
        return 'Khác';
    }
  }
}
