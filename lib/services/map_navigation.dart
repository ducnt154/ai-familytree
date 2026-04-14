import 'package:url_launcher/url_launcher.dart';

/// Mở Google Maps (trình duyệt / app hệ thống) theo chuỗi địa chỉ hoặc truy vấn.
Future<bool> openGoogleMapsExternal(String query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(trimmed)}',
  );
  const mode = LaunchMode.externalApplication;
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: mode);
  }
  return launchUrl(uri, mode: mode);
}
