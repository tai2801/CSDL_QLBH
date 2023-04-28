-- SmartSales - 06_queries.sql - Tu co ban den nang cao, moi truy van co muc dich
USE smartsales;
-- Q1 CO BAN: Danh sach san pham dang ban kem thuong hieu/danh muc
SELECT p.sku, p.product_name, b.brand_name, c.category_name, v.variant_name, v.sale_price FROM products p JOIN brands b ON b.brand_id=p.brand_id JOIN categories c ON c.category_id=p.category_id JOIN product_variants v ON v.product_id=p.product_id WHERE p.is_active=1 ORDER BY p.product_name;
-- Q2 CO BAN: Khach hang GOLD/VIP
SELECT customer_code, full_name, phone, customer_tier, loyalty_points FROM customers WHERE customer_tier IN ('GOLD','VIP') ORDER BY loyalty_points DESC;
-- Q3 TRUNG BINH: Ton kho kha dung va canh bao sap het
SELECT * FROM v_available_stock WHERE stock_flag='LOW' ORDER BY qty_available;
-- Q4 TRUNG BINH: Doanh thu thuc thu theo thang, tach don huy
SELECT * FROM v_revenue_real_vs_cancelled ORDER BY month_key;
-- Q5 TRUNG BINH: Top san pham ban chay
SELECT * FROM v_top_selling_products LIMIT 10;
-- Q6 TRUNG BINH: Don thanh toan thieu (chua thu du)
SELECT * FROM v_payment_reconciliation WHERE remaining_amount>0 AND status NOT IN ('CANCELLED','DRAFT');
-- Q7 NANG CAO: Loi nhuan gon theo danh muc (dung gia von snapshot, khong dung gia von hien tai)
SELECT c.category_name, SUM(oi.quantity*(oi.unit_price-oi.unit_cost_snapshot)) AS gross_profit, SUM(oi.line_total) AS revenue FROM sales_order_items oi JOIN sales_orders o ON o.order_id=oi.order_id JOIN product_variants v ON v.variant_id=oi.variant_id JOIN products p ON p.product_id=v.product_id JOIN categories c ON c.category_id=p.category_id WHERE o.status IN ('PAID','COMPLETED') GROUP BY c.category_name ORDER BY gross_profit DESC;
-- Q8 NANG CAO: Khach mua lai (repeat customer) va gia tri don trung binh
SELECT c.full_name, COUNT(DISTINCT o.order_id) AS orders, AVG(o.total_amount) AS avg_order_value FROM customers c JOIN sales_orders o ON o.customer_id=c.customer_id WHERE o.status IN ('PAID','COMPLETED') GROUP BY c.full_name HAVING COUNT(DISTINCT o.order_id)>=2 ORDER BY orders DESC;
-- Q9 NANG CAO: Serial da ban nhung chua co phieu bao hanh nao / lich su 1 serial
SELECT i.serial_no, p.product_name, i.status, i.warranty_expires_at, o.order_code FROM inventory_items i JOIN product_variants v ON v.variant_id=i.variant_id JOIN products p ON p.product_id=v.product_id LEFT JOIN sales_orders o ON o.order_id=i.sold_order_id WHERE i.serial_no='SN-IP14-0001';
-- Q10 NANG CAO: Ty le doi tra theo danh muc
SELECT c.category_name, COUNT(DISTINCT r.return_id) AS return_count, COUNT(DISTINCT o.order_id) AS order_count FROM categories c JOIN products p ON p.category_id=c.category_id JOIN product_variants v ON v.product_id=p.product_id JOIN sales_order_items oi ON oi.variant_id=v.variant_id JOIN sales_orders o ON o.order_id=oi.order_id LEFT JOIN return_items ri ON ri.order_item_id=oi.order_item_id LEFT JOIN return_requests r ON r.return_id=ri.return_id GROUP BY c.category_name;
-- Q11 NANG CAO: CTE - xep hang nhan vien theo doanh thu
WITH emp_rev AS (SELECT sales_employee_id, SUM(total_amount) AS rev FROM sales_orders WHERE status IN ('PAID','COMPLETED') GROUP BY sales_employee_id)
SELECT e.full_name, er.rev, RANK() OVER (ORDER BY er.rev DESC) AS rev_rank FROM emp_rev er JOIN employees e ON e.employee_id=er.sales_employee_id;
-- Q12 KIEM TRA TOAN VEN: Thanh toan vuot tong don (phai tra 0 dong)
SELECT o.order_code, o.total_amount, SUM(p.amount) AS paid FROM sales_orders o JOIN payments p ON p.order_id=o.order_id WHERE p.status IN ('SUCCESS','REFUNDED','PARTIALLY_REFUNDED') GROUP BY o.order_code, o.total_amount HAVING paid > o.total_amount + 0.01;
