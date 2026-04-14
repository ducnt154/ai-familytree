import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Sao chép ảnh chọn từ [image_picker] vào thư mục app (ổn định cho offline).
class AvatarStorage {
  AvatarStorage._();

  /// Trả về đường dẫn file đích (absolute). Ghi đè nếu đã tồn tại.
  static Future<String> persistPickedFile({
    required String personId,
    required String sourcePath,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(dir.path, 'avatars'));
    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }
    final ext = p.extension(sourcePath);
    final safeExt = ext.isEmpty ? '.jpg' : ext;
    final destPath = p.join(avatarsDir.path, '$personId$safeExt');
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  static Future<void> deleteFileIfExists(String? path) async {
    if (path == null || path.isEmpty) return;
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }
}
