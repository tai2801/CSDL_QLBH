# TEST REPORT — CSDL QUẢN LÝ BÁN HÀNG (SMARTSALES)

Ngày kiểm thử: 18/05/2023  
Môi trường: MySQL 8.0.32 & Python 3.10 trên Windows 10 / MySQL Workbench 8.0.

## 1. Kiểm thử trên MySQL 8.0

Thứ tự nạp script: `01_schema.sql → 02_seed.sql → 03_views.sql → 04_procedures.sql → 05_triggers.sql → 06_queries.sql → 07_tests.sql`.

Kết quả:
- **22 bảng, 6 views, 5 procedures, 5 triggers** được khởi tạo thành công trong `information_schema`.
- `07_tests.sql`: **5/5 PASS** (TEST1 seed counts, TEST2 no negative available, TEST3 refund links original payment, TEST4 cancelled excluded, TEST5 serial unique).
- Dữ liệu mẫu: 10 khách hàng, 21 sản phẩm (22 phiên bản), 13 đơn hàng, 11 giao dịch thanh toán, 11 serial items.
- Kiểm tra Stored Procedures và Triggers:
  - `sp_create_order_item(đơn DRAFT, variant 1, qty 9999)` → `ERROR: vuot ton kho kha dung` (chặn bán vượt tồn — ĐẠT).
  - `sp_create_order_item(..., qty 2)` → `OK`, `qty_reserved` tăng đúng 2.
  - `sp_create_refund(return 1, payment của đơn khác, ...)` → `ERROR: payment khong thuoc don cua phieu doi tra` (ĐẠT).
  - `sp_warranty_claim('SN-KHONG-TON-TAI', ...)` → `ERROR: khong tim thay serial`; với serial `SN-IP14-0003` → `OK` + sinh mã bảo hành.
  - Trigger lịch sử giá: UPDATE `sale_price` của variant 2 → bảng `price_history` tự động ghi nhận thêm dòng lịch sử mới (ĐẠT).

## 2. Các vấn đề phát hiện và đã khắc phục trong quá trình làm đồ án

1. **Cú pháp ràng buộc trong Schema**: cột `unit_cost_snapshot` khi đặt `CHECK` trước `COMMENT` gây lỗi cú pháp MySQL (ERROR 1064). Đã chỉnh lại thứ tự `COMMENT` ngay sau kiểu dữ liệu và đưa `CHECK` xuống mức bảng.
2. **Báo cáo doanh thu trong View**: ở phiên bản đầu, `v_revenue_real_vs_cancelled` JOIN trực tiếp sang `sales_order_items` làm `total_amount` của đơn có nhiều món bị cộng lặp (doanh thu tháng 04/2023 bị đội lên 176.807.000 thay vì 97.549.000). Đã tách phần tính lợi nhuận gộp ra subquery riêng, giữ phép tổng doanh thu trên bảng `sales_orders`. Kết quả sau khi sửa khớp chính xác với tổng các đơn PAID/COMPLETED tháng 04/2023 (DH001 24.189.000 + DH002 22.490.000 + DH003 30.880.000 + DH004 19.990.000 = 97.549.000 VND).

## 3. Kiểm thử tự động quy tắc nghiệp vụ bằng Python

```bash
python -m unittest discover -s tests -v   →  Ran 15 tests — OK (15/15 pass)
python tools/generate_seed_variants.py    →  OK: 13 đơn / 17 dòng chi tiết / 11 thanh toán nhất quán
```
15 test case bao phủ: công thức tính tồn khả dụng, chặn bán vượt tồn (kể cả khi tồn = 0), giữ hàng ghi sổ cái kho (ledger), đổi trả trong hạn/quá hạn/đơn đã hủy, hoàn tiền gắn giao dịch thanh toán gốc + chặn hoàn vượt + hoàn tiền từng phần, chặn điều chỉnh kho âm + ghi ledger, doanh thu loại trừ đơn hủy.
