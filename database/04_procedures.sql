-- SmartSales - 04_procedures.sql
USE smartsales;
DELIMITER $$
CREATE PROCEDURE sp_create_order_item(IN p_order_id INT UNSIGNED, IN p_variant_id INT UNSIGNED, IN p_qty INT, OUT p_message VARCHAR(255))
main: BEGIN
  DECLARE v_avail INT DEFAULT 0; DECLARE v_price DECIMAL(15,2); DECLARE v_cost DECIMAL(15,2); DECLARE v_status VARCHAR(20);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SET p_message='ERROR: giao dich da rollback'; END;
  START TRANSACTION;
  SELECT status INTO v_status FROM sales_orders WHERE order_id=p_order_id FOR UPDATE;
  IF v_status IS NULL THEN SET p_message='ERROR: khong tim thay don hang'; ROLLBACK; LEAVE main; END IF;
  IF v_status NOT IN ('DRAFT','CONFIRMED') THEN SET p_message='ERROR: don khong o trang thai cho phep them hang'; ROLLBACK; LEAVE main; END IF;
  SELECT (qty_on_hand-qty_reserved) INTO v_avail FROM inventory_stock WHERE variant_id=p_variant_id FOR UPDATE;
  IF v_avail IS NULL OR v_avail < p_qty THEN SET p_message='ERROR: vuot ton kho kha dung'; ROLLBACK; LEAVE main; END IF;
  SELECT sale_price, cost_price INTO v_price, v_cost FROM product_variants WHERE variant_id=p_variant_id;
  INSERT INTO sales_order_items(order_id, variant_id, quantity, unit_price, unit_cost_snapshot) VALUES (p_order_id, p_variant_id, p_qty, v_price, v_cost)
    ON DUPLICATE KEY UPDATE quantity=quantity+VALUES(quantity);
  UPDATE inventory_stock SET qty_reserved=qty_reserved+p_qty WHERE variant_id=p_variant_id;
  INSERT INTO stock_ledger(variant_id,movement_type,qty_change,qty_after,ref_type,ref_id,note)
    SELECT p_variant_id,'RESERVE',0,qty_on_hand,'SALES_ORDER',p_order_id,'Giu hang cho don' FROM inventory_stock WHERE variant_id=p_variant_id;
  COMMIT; SET p_message='OK';
END$$
CREATE PROCEDURE sp_confirm_return(IN p_return_id INT UNSIGNED, IN p_approver INT UNSIGNED, OUT p_message VARCHAR(255))
main: BEGIN
  DECLARE v_order_status VARCHAR(20); DECLARE v_order_date DATETIME; DECLARE v_window INT DEFAULT 30; DECLARE v_cat_days INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SET p_message='ERROR: rollback'; END;
  START TRANSACTION;
  SELECT o.status, o.order_date INTO v_order_status, v_order_date FROM return_requests r JOIN sales_orders o ON o.order_id=r.order_id WHERE r.return_id=p_return_id FOR UPDATE;
  IF v_order_status NOT IN ('PAID','COMPLETED') THEN SET p_message='ERROR: trang thai don khong cho doi tra'; ROLLBACK; LEAVE main; END IF;
  SELECT MIN(c.return_window_days) INTO v_cat_days FROM return_items ri JOIN sales_order_items oi ON oi.order_item_id=ri.order_item_id
    JOIN product_variants v ON v.variant_id=oi.variant_id JOIN products pr ON pr.product_id=v.product_id JOIN categories c ON c.category_id=pr.category_id
    WHERE ri.return_id=p_return_id;
  SET v_window = COALESCE(v_cat_days,30);
  IF DATEDIFF(NOW(), v_order_date) > v_window THEN SET p_message='ERROR: qua han doi tra'; ROLLBACK; LEAVE main; END IF;
  UPDATE return_requests SET status='APPROVED', approved_by=p_approver WHERE return_id=p_return_id;
  COMMIT; SET p_message='OK: da duyet doi tra - buoc tiep theo tao refund gan payment goc qua sp_create_refund';
END$$
CREATE PROCEDURE sp_create_refund(IN p_return_id INT UNSIGNED, IN p_payment_id INT UNSIGNED, IN p_amount DECIMAL(15,2), OUT p_message VARCHAR(255))
main: BEGIN
  DECLARE v_pay_order INT UNSIGNED; DECLARE v_ret_order INT UNSIGNED; DECLARE v_paid DECIMAL(15,2); DECLARE v_refunded DECIMAL(15,2);
  SELECT order_id, amount INTO v_pay_order, v_paid FROM payments WHERE payment_id=p_payment_id;
  SELECT order_id INTO v_ret_order FROM return_requests WHERE return_id=p_return_id;
  IF v_pay_order IS NULL OR v_pay_order <> v_ret_order THEN SET p_message='ERROR: payment khong thuoc don cua phieu doi tra'; LEAVE main; END IF;
  SELECT COALESCE(SUM(amount),0) INTO v_refunded FROM refunds WHERE payment_id=p_payment_id AND status<>'FAILED';
  IF v_refunded + p_amount > v_paid THEN SET p_message='ERROR: so tien hoan vuot so tien da thanh toan o giao dich goc'; LEAVE main; END IF;
  INSERT INTO refunds(return_id,payment_id,amount,method,status,refunded_at)
    SELECT p_return_id,p_payment_id,p_amount,method,'COMPLETED',NOW() FROM payments WHERE payment_id=p_payment_id;
  UPDATE payments SET status = IF(v_refunded+p_amount>=v_paid,'REFUNDED','PARTIALLY_REFUNDED') WHERE payment_id=p_payment_id;
  SET p_message='OK';
END$$
CREATE PROCEDURE sp_warranty_claim(IN p_serial VARCHAR(80), IN p_customer INT UNSIGNED, IN p_receiver INT UNSIGNED, IN p_issue VARCHAR(500), OUT p_code VARCHAR(25), OUT p_message VARCHAR(255))
main: BEGIN
  DECLARE v_item INT UNSIGNED; DECLARE v_exp DATE; DECLARE v_status VARCHAR(20);
  SELECT inventory_item_id, warranty_expires_at, status INTO v_item, v_exp, v_status FROM inventory_items WHERE serial_no=p_serial;
  IF v_item IS NULL THEN SET p_message='ERROR: khong tim thay serial'; LEAVE main; END IF;
  IF v_exp IS NOT NULL AND v_exp < CURDATE() THEN SET p_message='ERROR: da het han bao hanh'; LEAVE main; END IF;
  SET p_code = CONCAT('BH', DATE_FORMAT(NOW(),'%Y%m%d%H%i%s'));
  INSERT INTO warranty_claims(warranty_code,inventory_item_id,customer_id,received_by,issue_description) VALUES (p_code,v_item,p_customer,p_receiver,p_issue);
  UPDATE inventory_items SET status='IN_WARRANTY' WHERE inventory_item_id=v_item;
  SET p_message='OK';
END$$
CREATE PROCEDURE sp_adjust_stock(IN p_variant INT UNSIGNED, IN p_delta INT, IN p_actor INT UNSIGNED, IN p_note VARCHAR(255), OUT p_message VARCHAR(255))
main: BEGIN
  DECLARE v_after INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; SET p_message='ERROR: rollback'; END;
  START TRANSACTION;
  UPDATE inventory_stock SET qty_on_hand=qty_on_hand+p_delta WHERE variant_id=p_variant;
  SELECT qty_on_hand INTO v_after FROM inventory_stock WHERE variant_id=p_variant;
  IF v_after < 0 THEN ROLLBACK; SET p_message='ERROR: ton kho am'; LEAVE main; END IF;
  INSERT INTO stock_ledger(variant_id,movement_type,qty_change,qty_after,ref_type,actor_id,note) VALUES (p_variant,'ADJUSTMENT',p_delta,v_after,'MANUAL',p_actor,p_note);
  COMMIT; SET p_message='OK';
END$$
DELIMITER ;
