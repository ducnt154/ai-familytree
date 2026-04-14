# FamilyTree (Flutter)

Ứng dụng cây gia phả Android — shell Material 3, bottom navigation (Home, Tree, Add, Search, Settings); theme seed xanh lá.

## Yêu cầu

- [Flutter SDK](https://docs.flutter.dev/get-started/install) stable (3.24+ khuyến nghị).
- **Android (QA / build APK):** Android SDK + **cmdline-tools** đặt tại `$ANDROID_HOME/cmdline-tools/latest` (xem [command-line tools](https://developer.android.com/studio#command-line-tools-only)). Sau khi cài: `flutter doctor` và `flutter doctor --android-licenses` cho đến khi không còn lỗi blocking. Emulator hoặc thiết bị thật với USB debugging.

## Lần đầu (máy chỉ có mã nguồn)

Nếu chưa có thư mục nền tảng `android/` / `ios/`:

```bash
cd /Users/TinhKiem3/Documents/paperclip-ailab/familytree
flutter create . --project-name familytree
```

Lệnh trên bổ sung file nền tảng mặc định; không ghi đè `lib/`.

## Chạy nhanh

```bash
cd /Users/TinhKiem3/Documents/paperclip-ailab/familytree
flutter pub get
flutter run
```

## Kiểm thử

```bash
flutter test
```

## Epic

- [AIL-38](/AIL/issues/AIL-38) — App FamilyTree
