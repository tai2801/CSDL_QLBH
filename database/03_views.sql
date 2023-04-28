-- SmartSales - 03_views.sql
USE smartsales;
CREATE OR REPLACE VIEW v_available_stock AS
SELECT v.variant_id, v.variant_sku, p.product_name, v.variant_name, s.qty_on_hand, s.qty_reserved,
       (s.qty_on_hand - s.qty_reserved) AS qty_available,
       CASE WHEN (s.qty_on_hand - s.qty_reserved) <= v.reorder_point THEN 'LOW' ELSE 'OK' END AS stock_flag
FROM product_variants v JOIN products p ON p.product_id=v.product_id
LEFT JOIN inventory_stock s ON s.variant_id=v.variant_id;
CREATE OR REPLACE VIEW v_revenue_real_vs_cancelled AS
-- Doanh thu tinh tu sales_orders (1 dong/don) de khong bi nhan len khi JOIN chi tiet;
-- loi nhuan tinh o subquery rieng theo chi tiet don.
SELECT DATE_FORMAT(o.order_date,'%Y-%m') AS month_key,
  SUM(CASE WHEN o.status IN ('PAID','COMPLETED') THEN o.total_amount ELSE 0 END) AS revenue_recognized,
  SUM(CASE WHEN o.status='CANCELLED' THEN o.total_amount ELSE 0 END) AS revenue_cancelled,
  COALESCE(MAX(pr.gross_profit),0) AS gross_profit
FROM sales_orders o
LEFT JOIN (SELECT DATE_FORMAT(o2.order_date,'%Y-%m') AS mk, SUM(oi.quantity*(oi.unit_price-oi.unit_cost_snapshot)) AS gross_profit
           FROM sales_orders o2 JOIN sales_order_items oi ON oi.order_id=o2.order_id
           WHERE o2.status IN ('PAID','COMPLETED') GROUP BY mk) pr ON pr.mk = DATE_FORMAT(o.order_date,'%Y-%m')
GROUP BY month_key;
CREATE OR REPLACE VIEW v_top_selling_products AS
SELECT p.product_name, v.variant_name, SUM(oi.quantity) AS qty_sold, SUM(oi.line_total) AS revenue
FROM sales_order_items oi JOIN sales_orders o ON o.order_id=oi.order_id
JOIN product_variants v ON v.variant_id=oi.variant_id JOIN products p ON p.product_id=v.product_id
WHERE o.status IN ('PAID','COMPLETED') GROUP BY p.product_name, v.variant_name ORDER BY qty_sold DESC;
CREATE OR REPLACE VIEW v_customer_purchase_history AS
SELECT c.customer_id, c.full_name, c.customer_tier, COUNT(DISTINCT o.order_id) AS order_count,
  COALESCE(SUM(CASE WHEN o.status IN ('PAID','COMPLETED') THEN o.total_amount ELSE 0 END),0) AS total_spent,
  MAX(o.order_date) AS last_order_at
FROM customers c LEFT JOIN sales_orders o ON o.customer_id=c.customer_id GROUP BY c.customer_id, c.full_name, c.customer_tier;
CREATE OR REPLACE VIEW v_warranty_open AS
SELECT w.warranty_code, i.serial_no, p.product_name, c.full_name AS customer_name, w.claim_date, w.status, w.issue_description
FROM warranty_claims w JOIN inventory_items i ON i.inventory_item_id=w.inventory_item_id
JOIN product_variants v ON v.variant_id=i.variant_id JOIN products p ON p.product_id=v.product_id
JOIN customers c ON c.customer_id=w.customer_id WHERE w.status NOT IN ('COMPLETED','REJECTED');
CREATE OR REPLACE VIEW v_payment_reconciliation AS
SELECT o.order_code, o.total_amount, COALESCE(SUM(CASE WHEN p.status IN ('SUCCESS','REFUNDED','PARTIALLY_REFUNDED') THEN p.amount ELSE 0 END),0) AS paid_amount,
  o.total_amount - COALESCE(SUM(CASE WHEN p.status IN ('SUCCESS','REFUNDED','PARTIALLY_REFUNDED') THEN p.amount ELSE 0 END),0) AS remaining_amount, o.status
FROM sales_orders o LEFT JOIN payments p ON p.order_id=o.order_id GROUP BY o.order_code, o.total_amount, o.status;
