# KIẾN TRÚC — CSDL QUẢN LÝ BÁN HÀNG (SMARTSALES)

## Tổng quan
Đồ án môn **Cơ sở dữ liệu**: trọng tâm là thiết kế schema MySQL 8 chuẩn hóa kèm hệ thống views, stored procedures, triggers, dữ liệu mẫu và kịch bản kiểm thử. Các quy tắc nghiệp vụ cốt lõi được đặt ngay tại tầng CSDL để đảm bảo tính toàn vẹn dữ liệu.

## Tầng dữ liệu
- **Danh mục**: brands, categories (tự tham chiếu parent_id; chứa chính sách đổi trả/bảo hành mặc định), products, product_variants, price_history.
- **Đối tác/người dùng**: suppliers, customers, employees, user_accounts.
- **Nhập–kho**: purchase_orders, purchase_order_items, inventory_stock (số lượng + reserved), inventory_items (serial), stock_ledger (sổ cái kho, chỉ ghi thêm).
- **Bán–sau bán**: sales_orders, sales_order_items (generated column line_total + cost snapshot), order_item_serials, payments, return_requests, return_items, refunds, warranty_claims.

## Quyết định thiết kế
1. **Tách product / variant**: 1 sản phẩm (iPhone 14) có nhiều phiên bản (128GB/256GB) — giá và tồn nằm ở variant, tránh lặp thông tin sản phẩm.
2. **Hai cơ chế tồn song song**: serial-level cho hàng `has_serial=1`, quantity-level cho phụ kiện; `inventory_stock` quản lý số lượng tổng cho cả hai (serial dùng để truy xuất và bảo hành).
3. **Reserved thay vì trừ ngay**: giữ hàng khi đơn ở trạng thái DRAFT/CONFIRMED, `available = on_hand − reserved` giúp tránh 2 đơn cùng lấy một sản phẩm cuối cùng.
4. **Sổ cái kho (Stock Ledger)**: procedure ghi ledger với `ref_type` theo nghiệp vụ (PURCHASE_ORDER/SALES_ORDER/MANUAL); trigger `trg_stock_ledger_after_update` ghi `ref_type='TRIGGER'` khi cập nhật trực tiếp bảng tồn kho.
5. **Hoàn tiền theo giao dịch gốc**: bảng `refunds` liên kết giữa yêu cầu đổi trả (`return_requests`) và giao dịch thanh toán gốc (`payments`) để đối soát và chặn hoàn vượt số tiền khách đã thanh toán.

## Bảo mật & toàn vẹn
Sử dụng đầy đủ PK/FK/UNIQUE/CHECK trên các bảng; ENUM cho trạng thái; mật khẩu chỉ lưu chuỗi băm (hash); tiền tệ dùng kiểu `DECIMAL(15,2)`; procedure nghiệp vụ sử dụng transaction kết hợp khóa dòng (`FOR UPDATE`).

## Hướng dẫn chạy
Xem chi tiết tại `README.md` và kết quả kiểm thử trong `TEST_REPORT.md`.
