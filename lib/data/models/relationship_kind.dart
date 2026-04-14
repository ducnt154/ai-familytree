/// Loại quan hệ giữa hai [Person] trong một cây.
enum RelationshipKind {
  /// Quan hệ cha/mẹ — con (hướng: từ cha/mẹ tới con).
  parentChild(0),

  /// Vợ/chồng hoặc partner.
  spouse(1),

  /// Anh/chị/em (cùng thế hệ).
  sibling(2),

  /// Khác / tùy chỉnh sau này.
  other(3);

  const RelationshipKind(this.code);
  final int code;

  static RelationshipKind fromCode(int code) {
    return RelationshipKind.values.firstWhere(
      (e) => e.code == code,
      orElse: () => RelationshipKind.other,
    );
  }
}
