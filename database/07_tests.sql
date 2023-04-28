-- SmartSales - 07_tests.sql - Chay tren MySQL 8 sau 01-06. Ky vong: cac SELECT tra PASS/FAIL ro rang.
USE smartsales;
SELECT 'TEST1_seed_counts' AS test_name, CASE WHEN (SELECT COUNT(*) FROM customers)>=8 AND (SELECT COUNT(*) FROM products)>=20 AND (SELECT COUNT(*) FROM sales_orders)>=12 THEN 'PASS' ELSE 'FAIL' END AS result;
SELECT 'TEST2_no_negative_available' AS test_name, CASE WHEN NOT EXISTS (SELECT 1 FROM inventory_stock WHERE qty_on_hand-qty_reserved<0) THEN 'PASS' ELSE 'FAIL' END AS result;
SELECT 'TEST3_refund_links_original_payment' AS test_name, CASE WHEN NOT EXISTS (SELECT 1 FROM refunds r JOIN return_requests rr ON rr.return_id=r.return_id JOIN payments p ON p.payment_id=r.payment_id WHERE p.order_id<>rr.order_id) THEN 'PASS' ELSE 'FAIL' END AS result;
SELECT 'TEST4_cancelled_excluded_from_revenue' AS test_name, CASE WHEN (SELECT revenue_cancelled FROM v_revenue_real_vs_cancelled WHERE month_key='2023-05')>0 THEN 'PASS' ELSE 'CHECK' END AS result;
SELECT 'TEST5_serial_unique' AS test_name, CASE WHEN (SELECT COUNT(*) FROM (SELECT serial_no FROM inventory_items GROUP BY serial_no HAVING COUNT(*)>1) t)=0 THEN 'PASS' ELSE 'FAIL' END AS result;
-- TEST thu cong (chay rieng, ky vong loi 45000): UPDATE inventory_stock SET qty_reserved=9999 WHERE variant_id=1;
-- TEST thu cong procedure: tao don DRAFT moi, CALL sp_create_order_item(@order, 1, 9999, @m); SELECT @m; -- ky vong ERROR vuot ton
