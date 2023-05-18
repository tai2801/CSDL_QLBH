# DATA DICTIONARY — SMARTSALES (22 bảng)

Quy ước: PK = khóa chính, FK = khóa ngoại, UQ = unique, tiền = DECIMAL(15,2) VND.

| Bảng | Cột chính (kiểu) | Khóa/ràng buộc | Ý nghĩa |
|---|---|---|---|
| brands | brand_id INT PK, brand_code VARCHAR(20) UQ, brand_name VARCHAR(120) UQ, country, website, is_active | UQ code+name | Thương hiệu (Apple, Samsung…) |
| categories | category_id PK, category_code UQ, category_name, parent_id FK→categories, return_window_days INT (mặc định 30), warranty_months_default | CHECK window 0–365 | Danh mục + chính sách đổi trả/bảo hành mặc định |
| suppliers | supplier_id PK, supplier_code UQ, supplier_name, tax_code UQ, contact_name, phone, email, address, payment_term_days | CHECK email dạng %@% | Nhà cung cấp |
| products | product_id PK, sku UQ, product_name, brand_id FK, category_id FK, has_serial (1=theo serial, 0=số lượng), description, is_active | Index name, (brand,category) | Sản phẩm (model) |
| product_variants | variant_id PK, product_id FK, variant_sku UQ, variant_name, cost_price, sale_price, reorder_point, is_active | CHECK giá ≥ 0 | Phiên bản bán thực tế — nơi giữ giá & tồn |
| price_history | price_history_id BIGINT PK, variant_id FK, old/new_cost, old/new_sale, changed_by FK→employees, reason, changed_at | Index (variant, time) | Lịch sử giá (ghi tay + trigger) |
| customers | customer_id PK, customer_code UQ, full_name, phone UQ, email UQ, address, loyalty_points, customer_tier ENUM | CHECK điểm ≥ 0 | Khách hàng + hạng thành viên |
| employees | employee_id PK, employee_code UQ, full_name, phone, email UQ, role ENUM(ADMIN/MANAGER/SALES/WAREHOUSE/TECHNICIAN/ACCOUNTANT), hired_at, is_active | — | Nhân viên |
| user_accounts | account_id PK, employee_id FK UQ (1-1), username UQ, password_hash (chỉ hash), last_login_at, is_locked | — | Tài khoản đăng nhập |
| purchase_orders | purchase_order_id PK, po_code UQ, supplier_id FK, created_by FK, order_date, expected_date, status ENUM(DRAFT/CONFIRMED/RECEIVED/CANCELLED), total_cost | CHECK expected ≥ order | Phiếu nhập hàng |
| purchase_order_items | po_item_id PK, purchase_order_id FK, variant_id FK, quantity, unit_cost, received_quantity | UQ (po, variant); CHECK received ≤ quantity | Chi tiết nhập |
| inventory_stock | variant_id PK/FK, qty_on_hand, qty_reserved, updated_at | CHECK on_hand ≥ 0, reserved ≥ 0, reserved ≤ on_hand | Tồn số lượng; available = on_hand − reserved |
| inventory_items | inventory_item_id PK, variant_id FK, serial_no UQ, status ENUM(IN_STOCK/RESERVED/SOLD/IN_WARRANTY/RETURNED/DEFECTIVE/SCRAPPED), purchase_order_id FK, sold_order_id FK, warranty_expires_at | Index (variant, status) | Từng máy vật lý theo serial |
| stock_ledger | ledger_id BIGINT PK, variant_id FK, movement_type ENUM, qty_change, qty_after, ref_type, ref_id, serial_no, actor_id FK, note, created_at | Index (variant, time) | Sổ cái kho append-only |
| sales_orders | order_id PK, order_code UQ, customer_id FK, sales_employee_id FK, order_date, status ENUM(DRAFT/CONFIRMED/PAID/COMPLETED/CANCELLED), subtotal, discount_amount, total_amount | CHECK tiền ≥ 0; Index (date,status) | Đơn hàng |
| sales_order_items | order_item_id PK, order_id FK, variant_id FK, quantity, unit_price, unit_cost_snapshot, line_total (GENERATED = qty×price) | UQ (order, variant); CHECK qty > 0 | Chi tiết đơn + giá vốn snapshot |
| order_item_serials | (order_item_id, inventory_item_id) PK, inventory_item_id UQ | FK cả hai phía | Gán serial cụ thể vào dòng đơn |
| payments | payment_id PK, order_id FK, method ENUM(CASH/BANK_TRANSFER/CARD/E_WALLET/INSTALLMENT), amount, status ENUM, transaction_ref UQ, paid_at | CHECK amount > 0 | Thanh toán — 1 đơn nhiều dòng (split) |
| return_requests | return_id PK, return_code UQ, order_id FK, customer_id FK, request_date, status ENUM(PENDING/APPROVED/REJECTED/COMPLETED/CANCELLED), reason, approved_by FK, decision_note | — | Phiếu đổi trả |
| return_items | return_item_id PK, return_id FK, order_item_id FK, quantity, condition_note, restock | UQ (return, order_item) | Hàng được trả |
| refunds | refund_id PK, return_id FK, payment_id FK (giao dịch gốc — bắt buộc), amount, method, status ENUM, refunded_at | CHECK amount > 0 | Hoàn tiền gắn payment gốc |
| warranty_claims | warranty_id PK, warranty_code UQ, inventory_item_id FK, customer_id FK, received_by FK, claim_date, issue_description, status ENUM(RECEIVED/DIAGNOSING/REPAIRING/COMPLETED/REJECTED/REPLACED), resolution_note, completed_at | — | Phiếu bảo hành theo serial |

## Views (6)
`v_available_stock` (tồn khả dụng + cờ LOW) · `v_revenue_real_vs_cancelled` (doanh thu thực thu vs hủy + lợi nhuận theo tháng) · `v_top_selling_products` · `v_customer_purchase_history` · `v_warranty_open` (phiếu bảo hành đang mở) · `v_payment_reconciliation` (đối soát đã thu/còn thiếu theo đơn).

## Procedures (5)
`sp_create_order_item` (thêm dòng đơn, chặn vượt tồn) · `sp_confirm_return` (duyệt đổi trả: trạng thái + hạn) · `sp_create_refund` (hoàn tiền gắn payment gốc, chặn hoàn vượt) · `sp_warranty_claim` (tạo phiếu BH theo serial, chặn hết hạn) · `sp_adjust_stock` (điều chỉnh kho + ledger).

## Triggers (5)
`trg_variant_price_history` · `trg_stock_ledger_after_update` · `trg_prevent_negative_stock` · `trg_payment_status_sync` · `trg_block_delete_sold_product`.
