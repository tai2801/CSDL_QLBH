# ERD — SMARTSALES DATABASE

```mermaid
erDiagram
  BRANDS ||--o{ PRODUCTS : "co"
  CATEGORIES ||--o{ PRODUCTS : "thuoc"
  CATEGORIES ||--o{ CATEGORIES : "cha-con"
  PRODUCTS ||--o{ PRODUCT_VARIANTS : "phien ban"
  PRODUCT_VARIANTS ||--o{ PRICE_HISTORY : "lich su gia"
  PRODUCT_VARIANTS ||--|| INVENTORY_STOCK : "ton so luong"
  PRODUCT_VARIANTS ||--o{ INVENTORY_ITEMS : "serial"
  PRODUCT_VARIANTS ||--o{ STOCK_LEDGER : "so cai kho"
  SUPPLIERS ||--o{ PURCHASE_ORDERS : "cung cap"
  PURCHASE_ORDERS ||--o{ PURCHASE_ORDER_ITEMS : "chi tiet nhap"
  PRODUCT_VARIANTS ||--o{ PURCHASE_ORDER_ITEMS : "nhap"
  EMPLOYEES ||--|| USER_ACCOUNTS : "tai khoan"
  CUSTOMERS ||--o{ SALES_ORDERS : "mua"
  EMPLOYEES ||--o{ SALES_ORDERS : "ban"
  SALES_ORDERS ||--o{ SALES_ORDER_ITEMS : "chi tiet"
  PRODUCT_VARIANTS ||--o{ SALES_ORDER_ITEMS : "duoc ban"
  SALES_ORDER_ITEMS ||--o{ ORDER_ITEM_SERIALS : "gan serial"
  INVENTORY_ITEMS ||--o{ ORDER_ITEM_SERIALS : "da ban"
  SALES_ORDERS ||--o{ PAYMENTS : "thanh toan split"
  SALES_ORDERS ||--o{ RETURN_REQUESTS : "doi tra"
  RETURN_REQUESTS ||--o{ RETURN_ITEMS : "hang tra"
  SALES_ORDER_ITEMS ||--o{ RETURN_ITEMS : "dong bi tra"
  RETURN_REQUESTS ||--o{ REFUNDS : "hoan tien"
  PAYMENTS ||--o{ REFUNDS : "giao dich goc"
  INVENTORY_ITEMS ||--o{ WARRANTY_CLAIMS : "bao hanh theo serial"
  CUSTOMERS ||--o{ WARRANTY_CLAIMS : "yeu cau"
```

## Chú thích
- Quan hệ quan trọng nhất cho nghiệp vụ sau bán: `REFUNDS → PAYMENTS` (hoàn tiền luôn truy được về giao dịch gốc) và `WARRANTY_CLAIMS → INVENTORY_ITEMS` (bảo hành theo serial cụ thể, không theo model chung chung).
- `STOCK_LEDGER` là bảng chỉ-ghi-thêm (append-only) truy vết mọi biến động tồn.
- Khi cần bản nộp in: vẽ lại bằng dbdiagram.io/Draw.io theo quan hệ trên + Data Dictionary.
