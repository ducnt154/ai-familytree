/// Lỗi lưu trữ cục bộ (Hive / offline). Dùng để hiển thị thông báo thân thiện thay vì stack trace.
class StorageException implements Exception {
  StorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'StorageException: $message';
}
