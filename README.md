# CSDL Quản lý Bán hàng — SmartSales (CSDL_QLBH)

Cơ sở dữ liệu quản lý bán hàng cho **cửa hàng thiết bị công nghệ** (MySQL 8): bán hàng, nhập hàng, tồn kho theo serial/số lượng, thanh toán nhiều phương thức (split payment), bảo hành theo serial, đổi trả + hoàn tiền gắn giao dịch gốc, lịch sử giá và báo cáo lợi nhuận.

> Dự án thuộc Nhóm 2 — môn Cơ sở dữ liệu, HUIT. Trọng tâm thiết kế: vòng đời sản phẩm & giao dịch sau bán (xem `docs/BUSINESS_ANALYSIS.md`).

## Đặc điểm thiết kế

1. **Tồn kho khả dụng** `available = qty_on_hand − qty_reserved` — giữ hàng cho đơn đang xử lý, chặn bán vượt bằng procedure (khóa dòng) + CHECK + trigger.
2. **Hai cơ chế tồn**: hàng giá trị cao quản lý từng **serial** (`inventory_items`), phụ kiện quản lý số lượng (`inventory_stock`).
3. **Split payment**: một đơn có nhiều dòng thanh toán khác phương thức; view đối soát đã thu/còn thiếu.
4. **Hoàn tiền có truy vết**: `refunds.payment_id` bắt buộc trỏ về giao dịch thanh toán gốc của đúng đơn đó, tổng hoàn không vượt số đã trả.
5. **Lợi nhuận đúng lịch sử**: chi tiết đơn lưu `unit_cost_snapshot` tại thời điểm bán.
6. **Báo cáo doanh thu rõ ràng**: doanh thu thực thu (PAID/COMPLETED) tách riêng đơn hủy.

## Cấu trúc

```
CSDL_QLBH/
├── database/
│   ├── 01_schema.sql      # 22 bảng, PK/FK/UNIQUE/CHECK/index
│   ├── 02_seed.sql        # Dữ liệu mẫu VN: 10 khách, 5 NV, 4 NCC, 6 hãng, 21 sản phẩm/22 phiên bản, 13 đơn
│   ├── 03_views.sql       # 6 views báo cáo/đối soát
│   ├── 04_procedures.sql  # 5 stored procedures nghiệp vụ
│   ├── 05_triggers.sql    # 5 triggers (ledger, lịch sử giá, chặn tồn/xóa)
│   ├── 06_queries.sql     # 12 truy vấn cơ bản → nâng cao (CTE, window function)
│   └── 07_tests.sql       # Kiểm tra toàn vẹn trên MySQL
├── docs/                  # BUSINESS_ANALYSIS, ARCHITECTURE, ERD (Mermaid), DATA_DICTIONARY
├── tests/test_smartsales.py  # Test quy tắc nghiệp vụ bằng Python (sqlite3)
├── tools/generate_seed_variants.py  # Kiểm tra nhất quán tổng đơn/chi tiết/thanh toán trong seed
├── docker-compose.yml     # MySQL 8 local
├── .env.example
└── TEST_REPORT.md         # Kết quả kiểm thử
```

## Cài đặt

### Cách 1 — Docker
```bash
cp .env.example .env
docker compose up -d
for f in database/0*.sql; do docker exec -i smartsales-mysql mysql -uroot -p"$MYSQL_ROOT_PASSWORD" < "$f"; done
```

### Cách 2 — Dòng lệnh (MySQL 8)
```bash
mysql -u root -p < database/01_schema.sql
mysql -u root -p smartsales < database/02_seed.sql
mysql -u root -p smartsales < database/03_views.sql
mysql -u root -p smartsales < database/04_procedures.sql
mysql -u root -p smartsales < database/05_triggers.sql
mysql -u root -p smartsales < database/06_queries.sql
mysql -u root -p smartsales < database/07_tests.sql
```

### Cách 3 — MySQL Workbench
Mở từng file trong `database/` theo thứ tự 01 → 07 và Execute. File 01 tự tạo database `smartsales`.

## Kiểm thử

```bash
python -m unittest discover -s tests -v     # 15 test quy tắc nghiệp vụ
python tools/generate_seed_variants.py      # kiểm tra nhất quán dữ liệu mẫu
```
Chi tiết kết quả kiểm thử xem trong `TEST_REPORT.md`.

## Truy vấn kiểm tra nhanh

```sql
USE smartsales;
SELECT * FROM v_available_stock;                       -- tồn khả dụng
CALL sp_create_order_item(12, 1, 9999, @msg); SELECT @msg;  -- kỳ vọng: ERROR vuot ton kho kha dung
SELECT * FROM v_revenue_real_vs_cancelled;             -- doanh thu thực thu vs đơn hủy
SELECT * FROM v_payment_reconciliation;                -- đối soát thanh toán
```

## License
MIT License (xem `LICENSE`).
