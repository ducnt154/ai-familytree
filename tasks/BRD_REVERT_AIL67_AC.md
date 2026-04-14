# BA Scope Confirm: AIL-74 - Revert AIL-67 AC

**Parent:** [AIL-73](/AIL/issues/AIL-73)
**Refs:** [AIL-67](/AIL/issues/AIL-67), [AIL-75](/AIL/issues/AIL-75)
**Project:** App FamilyTree

---

## 1. Yêu cầu cần giữ (Must Keep)

| # | Requirement | Chi tiết |
|---|-------------|----------|
| 1 | **Vertical layout** | Cây gia phả hiển thị theo chiều dọc: đời trên cùng (ông bà cố) ở hàng trên, các đời con cháu xuống hàng thấp hơn tuần tự |
| 2 | **Generation-based positioning** | Hàng 1 = đời 1 (ông bà cố), Hàng 2 = đời 2 (cha/mẹ), Hàng 3 = đời 3 (con), ... |
| 3 | **Zoom in/out** | User có thể phóng to/thu nhỏ để quan sát toàn bộ cây |
| 4 | **Performance** | Đảm bảo hiệu năng render khi dữ liệu nhiều đời |
| 5 | **Scalability** | Hỗ trợ mở rộng dữ liệu nhiều thế hệ |

---

## 2. Thay đổi cần Revert từ AIL-67

| # | Thay đổi từ AIL-67 | Lý do revert |
|---|-------------------|--------------|
| 1 | Layout ngang (horizontal) | Không đúng yêu cầu family tree truyền thống |
| 2 | Không có zoom | Cần zoom để xem cây lớn |
| 3 | Xử lý overflow không phù hợp | Cần cải thiện UX |

**Note:** Revert to vertical layout, add zoom controls.

---

## 3. Acceptance Criteria (QA)

### 3.1. Layout & Display
- [ ] Cây gia phả hiển thị theo chiều dọc (trục Y)
- [ ] Thế hệ cao nhất (ông bà cố) ở hàng trên cùng
- [ ] Thế hệ tiếp theo xuống hàng dưới (không trùng lặp hàng)
- [ ] Không gối đè giữa các thế hệ

### 3.2. Zoom Functionality  
- [ ] Có nút/phím để zoom in
- [ ] Có nút/phím để zoom out
- [ ] Zoom đủ để thấy toàn bộ cây (fit-to-screen option)
- [ ] Zoom mượt, không giật

### 3.3. Performance
- [ ] Render < 2s với cây 50 nodes
- [ ] Render < 5s với cây 100 nodes
- [ ] Không crash khi > 200 nodes

### 3.4. Edge Cases
- [ ] Cây chỉ 1 người hiển thị đúng
- [ ] Cây chỉ có root (không có con) hiển thị đúng
- [ ] Cây nhiều nhánh (anh em) hiển thị đúng

---

## 4. UI Mockup Reference

Xem mockup trong [AIL-67 attachment](/AIL/issues/AIL-67):
- Hình ảnh minh họa layout dọc mong muốn

---

## 5. Dependencies

- [AIL-75](/AIL/issues/AIL-75) - CTO implementation (chờ BA xong)

---

## 6. Next

BA done → CEO promote [AIL-75](/AIL/issues/AIL-75) → CTO implement