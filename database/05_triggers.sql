-- SmartSales - 05_triggers.sql
USE smartsales;
DELIMITER $$
CREATE TRIGGER trg_variant_price_history AFTER UPDATE ON product_variants FOR EACH ROW
BEGIN IF OLD.sale_price<>NEW.sale_price OR OLD.cost_price<>NEW.cost_price THEN
  INSERT INTO price_history(variant_id,old_cost,new_cost,old_sale,new_sale,reason) VALUES (NEW.variant_id,OLD.cost_price,NEW.cost_price,OLD.sale_price,NEW.sale_price,'Cap nhat qua UPDATE product_variants');
END IF; END$$
CREATE TRIGGER trg_stock_ledger_after_update AFTER UPDATE ON inventory_stock FOR EACH ROW
BEGIN IF OLD.qty_on_hand<>NEW.qty_on_hand THEN
  INSERT INTO stock_ledger(variant_id,movement_type,qty_change,qty_after,ref_type,note) VALUES (NEW.variant_id, IF(NEW.qty_on_hand>OLD.qty_on_hand,'PURCHASE_IN','SALE_OUT'), NEW.qty_on_hand-OLD.qty_on_hand, NEW.qty_on_hand,'TRIGGER','Tu dong ghi ledger khi qty_on_hand thay doi - tranh trung voi procedure thi tat ghi tay o procedure do');
END IF; END$$
CREATE TRIGGER trg_prevent_negative_stock BEFORE UPDATE ON inventory_stock FOR EACH ROW
BEGIN IF NEW.qty_on_hand < 0 OR NEW.qty_reserved < 0 OR NEW.qty_reserved > NEW.qty_on_hand THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Ton kho khong hop le: reserved khong duoc vuot on_hand va khong am';
END IF; END$$
CREATE TRIGGER trg_payment_status_sync AFTER INSERT ON refunds FOR EACH ROW
BEGIN IF NEW.status='COMPLETED' THEN
  UPDATE return_requests SET status='COMPLETED' WHERE return_id=NEW.return_id AND status='APPROVED';
END IF; END$$
CREATE TRIGGER trg_block_delete_sold_product BEFORE DELETE ON products FOR EACH ROW
BEGIN IF EXISTS (SELECT 1 FROM product_variants v JOIN sales_order_items oi ON oi.variant_id=v.variant_id WHERE v.product_id=OLD.product_id) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Khong duoc xoa san pham da phat sinh ban hang - hay tat is_active';
END IF; END$$
DELIMITER ;
-- Luu y thiet ke: trg_stock_ledger_after_update va cac procedure ghi ledger thu cong co the trung 1 dong neu procedure vua UPDATE qty_on_hand vua INSERT ledger.
-- Quy uoc van hanh: procedure nao da ghi ledger thu cong thi ghi ro ref_type, trigger ghi ref_type='TRIGGER'; khi bao cao, loc theo ref_type de tranh dem trung. Xem ARCHITECTURE.md.
