# PHÂN TÍCH NGHIỆP VỤ — CSDL QUẢN LÝ BÁN HÀNG (SMARTSALES)

## 1. Bối cảnh
Cửa hàng thiết bị công nghệ (điện thoại, laptop, tablet, phụ kiện) cần CSDL quản lý trọn vòng đời: nhập hàng → bán hàng → thanh toán → bảo hành/đổi trả sau bán, kèm báo cáo doanh thu và lợi nhuận chính xác.

## 2. Actors
| Actor | Mô tả |
|---|---|
| Admin | Quản trị tài khoản, danh mục, giá |
| Quản lý (Manager) | Duyệt đổi trả, điều chỉnh giá/kho, xem báo cáo lợi nhuận |
| Nhân viên bán hàng (Sales) | Tạo đơn, thu tiền, tạo yêu cầu đổi trả/bảo hành |
| Nhân viên kho (Warehouse) | Tạo/xác nhận phiếu nhập, kiểm kê, điều chỉnh kho |
| Kỹ thuật viên (Technician) | Tiếp nhận và xử lý bảo hành theo serial |
| Kế toán (Accountant) | Đối soát thanh toán, hoàn tiền |
| Khách hàng | Đối tượng dữ liệu (mua, đổi trả, bảo hành) |

## 3. Use Cases chính
UC01 Quản lý danh mục/thương hiệu/phiên bản · UC02 Nhập hàng theo phiếu · UC03 Bán hàng (giữ hàng → xác nhận → thanh toán, cho phép split payment) · UC04 Quản lý serial · UC05 Bảo hành theo serial · UC06 Đổi trả + hoàn tiền · UC07 Quản lý giá + lịch sử giá · UC08 Báo cáo doanh thu/lợi nhuận/tồn kho/bán chạy · UC09 Quản lý khách hàng + hạng thành viên · UC10 Quản lý nhân viên + tài khoản.

## 4. Business Rules
- BR01: `available = qty_on_hand − qty_reserved`; không bán/giữ vượt available (kiểm tra trong `sp_create_order_item` với khóa dòng FOR UPDATE + CHECK `qty_reserved ≤ qty_on_hand` + trigger chặn tồn không hợp lệ).
- BR02: Sản phẩm `has_serial=1` quản lý từng `inventory_items.serial_no` (UNIQUE); `has_serial=0` (phụ kiện) chỉ quản lý số lượng trong `inventory_stock`.
- BR03: Đổi trả chỉ khi đơn ở PAID/COMPLETED và trong cửa sổ ngày của danh mục (điện thoại/laptop 30 ngày, âm thanh 15, phụ kiện 7 — lưu ở `categories.return_window_days`).
- BR04: Hoàn tiền (`refunds`) bắt buộc tham chiếu `payments.payment_id` của chính đơn đó; tổng hoàn ≤ số đã trả ở giao dịch gốc (kiểm tra trong `sp_create_refund`).
- BR05: Mọi biến động `qty_on_hand` đều có dòng `stock_ledger` (procedure ghi tay có ref_type nghiệp vụ, trigger ghi ref_type='TRIGGER').
- BR06: Lợi nhuận tính bằng `unit_cost_snapshot` tại thời điểm bán, không dùng giá vốn hiện tại.
- BR07: Doanh thu ghi nhận chỉ gồm đơn PAID/COMPLETED; đơn CANCELLED báo cáo riêng.
- BR08: Không xóa cứng sản phẩm đã phát sinh bán hàng (trigger chặn) — dùng `is_active=0`.
- BR09: Mật khẩu chỉ lưu hash (`user_accounts.password_hash`).

## 5. Luồng chính — Bán hàng (Main Flow)
1. Sales tạo `sales_orders` trạng thái DRAFT. 2. Thêm từng dòng qua `sp_create_order_item`: khóa dòng tồn, kiểm tra available, ghi dòng đơn với giá bán + giá vốn snapshot, tăng `qty_reserved`, ghi ledger RESERVE. 3. Khách thanh toán (có thể nhiều dòng `payments` khác phương thức — split payment). 4. Đơn chuyển PAID → COMPLETED; hàng serial được gán qua `order_item_serials`, serial chuyển SOLD và có ngày hết bảo hành.

## 6. Alternative Flow
- Khách trả 2 phương thức (tiền mặt + ví điện tử) → 2 dòng payments, tổng = tổng đơn (view `v_payment_reconciliation` đối soát).
- Đơn DRAFT bị bỏ → hủy đơn, nhả reserved (ledger RELEASE_RESERVE).
- Nhận hàng thiếu so với phiếu nhập → `received_quantity < quantity`, tồn chỉ tăng theo số thực nhận.

## 7. Exception Flow
- Bán vượt available → procedure rollback, trả message "ERROR: vuot ton kho kha dung", tồn không đổi.
- Đổi trả quá hạn / đơn đã hủy → `sp_confirm_return` từ chối với lý do cụ thể.
- Hoàn tiền gắn sai payment (payment của đơn khác) hoặc vượt số đã trả → `sp_create_refund` từ chối.
- Bảo hành serial hết hạn → `sp_warranty_claim` từ chối; serial không tồn tại → báo lỗi.
- Cập nhật tồn làm reserved > on_hand → trigger `trg_prevent_negative_stock` SIGNAL 45000.
