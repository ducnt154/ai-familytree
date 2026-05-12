# QA Test Plan — Tính năng Sự kiện (AIL-88)

Base on BA spec: `docs/ba/Event_Feature_Specification.md`
Branch: `develop` (commit a468f19)

## Prerequisites

- App built & installed on Android emulator/device
- At least 1 family tree created with 2+ members
- Network: offline (Hive, no API dependency)

## Test Scenarios

### 1. Add Event (AC-ADD)
| ID | Step | Expected |
|---|---|---|
| AC-ADD-01 | Tap FAB "+" on Events tab | Bottom sheet opens with fields: Thành viên, Tên, Mô tả, Ngày, Loại lịch (âm/dương), Lặp lại hàng năm toggle |
| AC-ADD-02 | Tap Lưu with empty fields | Validation error shown, event not saved |
| AC-ADD-03 | Enter title with spaces only | Treated as empty, validation error shown |
| AC-ADD-04 | Fill all fields, tap Lưu | Event appears in list at correct position |
| AC-ADD-05 | Add event with future date | Event shows in "Sắp tới" / top of "Tất cả" |

### 2. Edit Event (AC-EDIT)
| ID | Step | Expected |
|---|---|---|
| AC-EDIT-01 | Tap existing event | Navigate to edit page with pre-filled data |
| AC-EDIT-02 | Change title, date, toggle repeat | All fields editable |
| AC-EDIT-03 | Save changes | Event updates, list refreshes |
| AC-EDIT-04 | Change date from future→past | Event moves to "Đã qua" section |

### 3. Event List (AC-LIST)
| ID | Step | Expected |
|---|---|---|
| AC-LIST-01 | View "Tất cả" tab | Upcoming/today events shown before past events |
| AC-LIST-02 | Verify sort order | Events sorted ascending by next occurrence |
| AC-LIST-03 | Non-repeating past event | Shows at bottom of "Tất cả" list |
| AC-LIST-04 | Change device timezone | Past/upcoming classification updates correctly |

### 4. Edge Cases
| ID | Step | Expected |
|---|---|---|
| EC-01 | Create event with lunar date 30/12 or 29/2 | Converts to solar without crash |
| EC-02 | Create lunar date that doesn't exist in target year | Falls back to last valid day of month |
| EC-03 | Travel across timezone | Events don't jump between past/upcoming incorrectly |
| EC-04 | Create non-repeating event in the past | Stays in "Đã qua", never auto-advances to next year |

### 5. Regression
| ID | Check |
|---|---|
| REG-01 | Navigation: all 5 bottom tabs work, Settings icon opens |
| REG-02 | Home tab: tree CRUD still functional |
| REG-03 | Tree tab: graph renders correctly |
| REG-04 | Add tab: member creation works |
| REG-05 | Search tab: search returns results |
| REG-06 | Theme: colors, spacing, typography consistent with existing app |

## Known Limitations (v1 MVP)
- No local push notification for reminders (UI field exists, no OS scheduling)
- Reminder settings stored but not executed
- No auto-creation of birthday/death events from Person profile
- Lunar day picker uses dropdown (1-30) instead of calendar

## Result

| Area | Pass/Fail | Notes |
|---|---|---|
| AC-ADD | | |
| AC-EDIT | | |
| AC-LIST | | |
| EC | | |
| REG | | |
