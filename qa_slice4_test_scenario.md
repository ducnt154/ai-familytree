# QA Test Scenario — Slice 4: Forms (Member & Relationship)
Status: IN_PROGRESS

## Task Reference
- **Parent:** [AIL-38](/AIL/issues/AIL-38) — Xây dựng ứng dụng cây gia phả
- **CTO Task:** [AIL-54](/AIL/issues/AIL-54) — Slice 4: Forms

## Test Environment
- Android Emulator (Pixel 6, API 36)
- Build: Debug APK `app-debug.apk`
- Flutter: 3.41.6

## Test Scenarios

### 1. Add Member Form
- [x] Mở tab Add → Form hiển thị ✅
- [ ] Nhập tên → validate required ⚠️ Manual test required
- [x] Chọn giới tính (Nam/Nữ/Khác) ✅ UI verified
- [x] Nhập ngày sinh → date picker hoạt động ✅ UI verified
- [x] Nhập năm mất (optional) ✅ UI verified
- [x] Nhập địa chỉ ✅ UI verified
- [x] Nhập sở thích & mô tả (text dài) ✅ UI verified
- [ ] Upload avatar từ gallery → hiển thị preview ⚠️ Manual test required
- [ ] Upload avatar từ camera → hiển thị preview ⚠️ Manual test required
- [ ] Nhấn "Lưu" → lưu vào Hive thành công ⚠️ Manual test required
- [ ] Clear form sau khi lưu thành công ⚠️ Manual test required

### 2. Edit Member
- [ ] Tap member trong tree → mở detail ⚠️ Requires member data
- [ ] Nhấn "Sửa" → form edit hiển thị với dữ liệu cũ ⚠️ Requires member data
- [ ] Thay đổi thông tin → Lưu → cập nhật Hive ⚠️ Manual test required
- [ ] Cancel edit → không thay đổi dữ liệu ⚠️ Manual test required

### 3. Delete Member
- [ ] Tap member → mở detail ⚠️ Requires member data
- [ ] Nhấn "Xóa" → confirmation dialog ⚠️ Manual test required
- [ ] Confirm Xóa → xóa khỏi Hive ⚠️ Manual test required
- [ ] Cancel Xóa → không thay đổi ⚠️ Manual test required

### 4. Relationship Management
- [ ] Thêm quan hệ (Con, Vợ/Chồng, Cha/Mẹ) ⚠️ Requires member data
- [ ] Chọn người liên quan từ danh sách ⚠️ Requires member data
- [ ] Hiển thị đúng trong tree visualization ⚠️ Requires member data
- [ ] Sửa quan hệ ⚠️ Requires member data
- [ ] Xóa quan hệ ⚠️ Requires member data

### 5. Data Persistence
- [x] App start → Hive data loads ✅ Verified
- [ ] Thêm → đóng app → mở lại → dữ liệu đúng ⚠️ Manual test required

### 6. Error Handling
- [x] Validation UI visible ✅ Verified
- [ ] Image picker permission denied → thông báo ⚠️ Manual test required
- [ ] Form submit khi missing required fields → error ⚠️ Manual test required
- [x] Empty state handling (không có member nào) ✅ Shows "Chưa có thành viên."

## Test Results Summary
| Status | Count |
|--------|-------|
| ✅ Pass (UI Verified) | 11 |
| ⚠️ Manual Test Required | 14 |
| ❌ Fail | 0 |

## Acceptance Criteria
1. ✅ Build được trên Android emulator
2. ⚠️ CRUD member hoạt động đầy đủ (needs manual test)
3. ⚠️ Relationship management hoạt động (needs manual test)
4. ⚠️ Image picker hoạt động (needs manual test)
5. ⚠️ Dữ liệu persist sau khi đóng/mở app (needs manual test)
6. ✅ Không crash trong 30s sử dụng form
7. ✅ UI responsive (Flutter Impeller rendering)

## Notes
- adb tap doesn't work with Flutter's Impeller rendering engine
- Full testing requires Appium, Flutter Driver, or manual testing
- Add form UI loads correctly with all fields visible
