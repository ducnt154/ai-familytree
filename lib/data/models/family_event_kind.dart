/// Loại sự kiện gắn thành viên (theo spec BA Event).
enum FamilyEventKind {
  birthday,
  deathAnniversary,
  weddingAnniversary,
  graduation,
  jobAnniversary,
  other,
}

extension FamilyEventKindLabels on FamilyEventKind {
  String get viLabel {
    switch (this) {
      case FamilyEventKind.birthday:
        return 'Sinh nhật';
      case FamilyEventKind.deathAnniversary:
        return 'Ngày mất';
      case FamilyEventKind.weddingAnniversary:
        return 'Kỷ niệm cưới';
      case FamilyEventKind.graduation:
        return 'Tốt nghiệp';
      case FamilyEventKind.jobAnniversary:
        return 'Nhận chức';
      case FamilyEventKind.other:
        return 'Khác';
    }
  }
}
