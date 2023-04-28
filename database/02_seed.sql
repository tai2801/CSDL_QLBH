-- SmartSales - 02_seed.sql - Du lieu mau thuc te Viet Nam (gia VND)
USE smartsales;
INSERT INTO brands (brand_code, brand_name, country) VALUES
('APL','Apple','Hoa Ky'),('SS','Samsung','Han Quoc'),('XM','Xiaomi','Trung Quoc'),
('ASU','ASUS','Dai Loan'),('LG','LG','Han Quoc'),('ANK','Anker','Trung Quoc');
INSERT INTO categories (category_code, category_name, parent_id, return_window_days, warranty_months_default) VALUES
('PHONE','Dien thoai',NULL,30,12),('LAPTOP','Laptop',NULL,30,24),('TABLET','May tinh bang',NULL,30,12),
('AUDIO','Am thanh',NULL,15,12),('ACC','Phu kien',NULL,7,6),('MON','Man hinh',NULL,30,24);
INSERT INTO suppliers (supplier_code, supplier_name, tax_code, contact_name, phone, email, address, payment_term_days) VALUES
('NCC01','Cong ty TNHH Phan phoi FPT Synnex','0101234567','Tran Van Minh','0901234501','lienhe@fpt-synnex.example.vn','TP. Ho Chi Minh',30),
('NCC02','Cong ty Co phan Digiworld','0302345678','Le Thi Hoa','0901234502','contact@digiworld.example.vn','TP. Ho Chi Minh',30),
('NCC03','Cong ty TNHH Tin hoc Mai Hoang','0103456789','Pham Quoc Bao','0901234503','sales@maihoang.example.vn','Ha Noi',15),
('NCC04','Cong ty TNHH PSD Mien Nam','0314567890','Nguyen Thanh Tung','0901234504','info@psd.example.vn','TP. Ho Chi Minh',45);
INSERT INTO employees (employee_code, full_name, phone, email, role, hired_at) VALUES
('NV01','Nguyen Van An','0912000001','an.nguyen@smartsales.example.vn','ADMIN','2022-03-01'),
('NV02','Tran Thi Binh','0912000002','binh.tran@smartsales.example.vn','MANAGER','2022-06-15'),
('NV03','Le Van Cuong','0912000003','cuong.le@smartsales.example.vn','SALES','2022-09-10'),
('NV04','Pham Thi Dung','0912000004','dung.pham@smartsales.example.vn','WAREHOUSE','2023-01-20'),
('NV05','Hoang Van Em','0912000005','em.hoang@smartsales.example.vn','TECHNICIAN','2023-02-01');
INSERT INTO user_accounts (employee_id, username, password_hash) VALUES
(1,'an.admin','$2b$12$eImiTXuWVxfM37uY4JANjQ0000000000000000000000000000001'),
(2,'binh.manager','$2b$12$eImiTXuWVxfM37uY4JANjQ0000000000000000000000000000002'),
(3,'cuong.sales','$2b$12$eImiTXuWVxfM37uY4JANjQ0000000000000000000000000000003');
INSERT INTO customers (customer_code, full_name, phone, email, address, loyalty_points, customer_tier) VALUES
('KH001','Nguyen Minh Tuan','0988001001','tuan.nguyen@example.vn','Quan 1, TP.HCM',320,'GOLD'),
('KH002','Tran Thu Ha','0988001002','ha.tran@example.vn','Quan Binh Thanh, TP.HCM',80,'STANDARD'),
('KH003','Le Quoc Huy','0988001003','huy.le@example.vn','TP. Thu Duc, TP.HCM',540,'VIP'),
('KH004','Pham Ngoc Anh','0988001004','anh.pham@example.vn','Quan 7, TP.HCM',45,'STANDARD'),
('KH005','Vu Dinh Khoa','0988001005','khoa.vu@example.vn','Quan Tan Binh, TP.HCM',150,'SILVER'),
('KH006','Do Thanh Tam','0988001006','tam.do@example.vn','Bien Hoa, Dong Nai',210,'SILVER'),
('KH007','Bui Hoang Nam','0988001007','nam.bui@example.vn','Quan Go Vap, TP.HCM',30,'STANDARD'),
('KH008','Dang Thuy Linh','0988001008','linh.dang@example.vn','Quan 10, TP.HCM',410,'GOLD'),
('KH009','Ngo Van Phuc','0988001009','phuc.ngo@example.vn','Di An, Binh Duong',95,'STANDARD'),
('KH010','Ho Thi Mai','0988001010','mai.ho@example.vn','Quan Phu Nhuan, TP.HCM',620,'VIP');
INSERT INTO products (sku, product_name, brand_id, category_id, has_serial, description) VALUES
('IP14','iPhone 14',1,1,1,'Dien thoai Apple'),('IP14PM','iPhone 14 Pro Max',1,1,1,'Dien thoai Apple cao cap'),
('SGS23','Samsung Galaxy S23',2,1,1,'Dien thoai Samsung'),('XM13','Xiaomi 13',3,1,1,'Dien thoai Xiaomi'),
('MACM2','MacBook Air M2',1,2,1,'Laptop Apple'),('ASVIV','ASUS Vivobook 15',4,2,1,'Laptop ASUS'),
('IPAD10','iPad Gen 10',1,3,1,'May tinh bang Apple'),('TABS8','Samsung Galaxy Tab S8',2,3,1,'May tinh bang Samsung'),
('AIRP','AirPods Pro 2',1,4,1,'Tai nghe Apple'),('BUDS','Samsung Galaxy Buds2 Pro',2,4,1,'Tai nghe Samsung'),
('MON27','LG UltraGear 27 inch',5,6,1,'Man hinh LG'),
('ANKC','Cap sac Anker USB-C 100W',6,5,0,'Phu kien - quan ly so luong'),('ANKP','Sac du phong Anker 20000mAh',6,5,0,'Phu kien'),
('CASE','Op lung iPhone 14',6,5,0,'Phu kien'),('MOUSE','Chuot khong day Logitech',6,5,0,'Phu kien');
-- Bo sung san pham
INSERT INTO products (sku, product_name, brand_id, category_id, has_serial) VALUES
('IP13','iPhone 13',1,1,1),('SGZFLIP','Samsung Galaxy Z Flip 4',2,1,1),('XMNOTE','Xiaomi Redmi Note 12',3,1,1),
('ASROG','ASUS ROG Strix G15',4,2,1),('LGGRAM','LG Gram 16',5,2,1),('ANKHUB','Hub USB-C Anker 7-in-1',6,5,0);
INSERT INTO product_variants (product_id, variant_sku, variant_name, cost_price, sale_price, reorder_point) VALUES
(1,'IP14-128-BLK','128GB - Den',21000000,22990000,3),(1,'IP14-256-BLU','256GB - Xanh',23500000,25990000,3),
(2,'IP14PM-256-PUR','256GB - Tim',26500000,29990000,2),(3,'SGS23-256-GRN','256GB - Xanh',17500000,19990000,3),
(4,'XM13-256-WHT','256GB - Trang',15500000,17990000,3),(5,'MACM2-256-SLV','256GB - Bac',23500000,26490000,2),
(6,'ASVIV-512-GRY','512GB - Xam',13500000,15990000,3),(7,'IPAD10-64-BLU','64GB - Xanh',8500000,9990000,3),
(8,'TABS8-128-GRA','128GB - Graphite',16500000,18990000,2),(9,'AIRP2-WHT','Trang',4800000,5990000,5),
(10,'BUDS2-WHT','Trang',3200000,3990000,5),(11,'MON27-165','27 inch 165Hz',5200000,6490000,2),
(12,'ANKC-100W','1.8m',180000,350000,20),(13,'ANKP-20K','20000mAh',550000,890000,10),
(14,'CASE-IP14','Trong suot',80000,199000,20),(15,'MOUSE-WL','Khong day',280000,499000,10),
(16,'IP13-128-PNK','128GB - Hong',16500000,18990000,3),(17,'ZFLIP4-256-CRM','256GB - Kem',18500000,21990000,2),
(18,'NOTE12-128-BLK','128GB - Den',5200000,6490000,5),(19,'ROG-512','512GB SSD',32000000,37990000,1),
(20,'GRAM16-512','512GB - Trang',24000000,27990000,2),(21,'HUB7-1','7 cong',650000,1090000,10);
INSERT INTO price_history (variant_id, old_cost, new_cost, old_sale, new_sale, changed_by, reason) VALUES
(1,20500000,21000000,21990000,22990000,2,'Dieu chinh gia theo nha phan phoi thang 04/2023'),
(9,15800000,16500000,17990000,18990000,2,'Tang gia nhap Tab S8');
INSERT INTO purchase_orders (po_code, supplier_id, created_by, order_date, expected_date, status, total_cost) VALUES
('PN001',1,4,'2023-04-05','2023-04-08','RECEIVED',250000000),('PN002',2,4,'2023-04-20','2023-04-23','RECEIVED',180000000),
('PN003',3,4,'2023-05-02','2023-05-06','RECEIVED',95000000),('PN004',4,4,'2023-05-12','2023-05-17','CONFIRMED',60000000);
INSERT INTO purchase_order_items (purchase_order_id, variant_id, quantity, unit_cost, received_quantity) VALUES
(1,1,10,21000000,10),(1,3,5,26500000,5),(1,13,50,180000,50),
(2,4,8,17500000,8),(2,9,20,4800000,20),(2,14,30,550000,30),
(3,6,6,13500000,6),(3,12,10,5200000,10),(3,15,40,80000,40);
INSERT INTO inventory_stock (variant_id, qty_on_hand, qty_reserved) VALUES
(1,7,0),(2,4,0),(3,3,0),(4,6,0),(5,5,0),(6,4,0),(7,5,0),(8,6,0),(9,4,0),(10,16,0),
(11,8,0),(12,8,0),(13,45,0),(14,26,0),(15,38,0),(16,9,0),(17,3,0),(18,4,0),(19,6,0),(20,2,0),(21,1,0),(22,12,0);
INSERT INTO inventory_items (variant_id, serial_no, status, purchase_order_id, warranty_expires_at) VALUES
(1,'SN-IP14-0001','SOLD',1,'2024-04-10'),(1,'SN-IP14-0002','SOLD',1,'2024-04-12'),(1,'SN-IP14-0003','IN_STOCK',1,'2024-04-08'),
(3,'SN-IP14PM-0001','SOLD',1,'2025-04-15'),(3,'SN-IP14PM-0002','IN_STOCK',1,'2025-04-08'),
(4,'SN-S23-0001','SOLD',2,'2024-04-22'),(4,'SN-S23-0002','IN_STOCK',2,'2024-04-23'),
(10,'SN-AIRP-0001','SOLD',2,'2024-05-01'),(10,'SN-AIRP-0002','IN_WARRANTY',2,'2024-04-23'),
(6,'SN-ASVIV-0001','SOLD',3,'2025-05-05'),(12,'SN-MON27-0001','IN_STOCK',3,'2025-05-06');
INSERT INTO stock_ledger (variant_id, movement_type, qty_change, qty_after, ref_type, ref_id, actor_id, note) VALUES
(1,'PURCHASE_IN',10,10,'PURCHASE_ORDER',1,4,'Nhap PN001'),(1,'SALE_OUT',-3,7,'SALES_ORDER',1,3,'Ban don DH001/DH002'),
(13,'PURCHASE_IN',50,50,'PURCHASE_ORDER',1,4,'Nhap cap sac'),(13,'SALE_OUT',-5,45,'SALES_ORDER',3,3,'Ban kem don hang');
INSERT INTO sales_orders (order_code, customer_id, sales_employee_id, order_date, status, subtotal, discount_amount, total_amount) VALUES
('DH001',1,3,'2023-04-10 10:15:00','COMPLETED',24189000,0,24189000),
('DH002',2,3,'2023-04-12 14:20:00','COMPLETED',22990000,500000,22490000),
('DH003',3,3,'2023-04-15 09:30:00','COMPLETED',30880000,0,30880000),
('DH004',4,3,'2023-04-22 16:00:00','COMPLETED',19990000,0,19990000),
('DH005',5,3,'2023-05-01 11:10:00','COMPLETED',5990000,0,5990000),
('DH006',6,3,'2023-05-05 13:45:00','COMPLETED',15990000,0,15990000),
('DH007',7,3,'2023-05-08 10:00:00','PAID',998000,0,998000),
('DH008',8,3,'2023-05-10 15:30:00','CONFIRMED',6490000,0,6490000),
('DH009',9,3,'2023-05-11 09:00:00','CANCELLED',22990000,0,22990000),
('DH010',10,3,'2023-05-12 17:20:00','COMPLETED',18990000,1000000,17990000),
('DH011',1,3,'2023-05-14 10:40:00','COMPLETED',899000,0,899000),
('DH012',3,3,'2023-05-16 14:00:00','DRAFT',26490000,0,26490000),
('DH013',2,3,'2023-03-20 10:00:00','COMPLETED',22990000,0,22990000);
INSERT INTO sales_order_items (order_id, variant_id, quantity, unit_price, unit_cost_snapshot) VALUES
(1,1,1,22990000,21000000),(1,13,2,350000,180000),(1,15,1,499000,280000),
(2,1,1,22990000,21000000),(3,3,1,29990000,26500000),(3,14,1,890000,550000),
(4,4,1,19990000,17500000),(5,10,1,5990000,4800000),(6,7,1,15990000,13500000),
(7,16,2,499000,280000),(8,19,1,6490000,5200000),(9,1,1,22990000,21000000),
(10,9,1,18990000,16500000),(11,13,2,350000,180000),(11,15,1,199000,80000);
INSERT INTO sales_order_items (order_id, variant_id, quantity, unit_price, unit_cost_snapshot) VALUES
(12,6,1,26490000,23500000),(13,1,1,22990000,21000000);
INSERT INTO order_item_serials (order_item_id, inventory_item_id)
SELECT oi.order_item_id, ii.inventory_item_id FROM sales_order_items oi JOIN inventory_items ii ON ii.serial_no='SN-IP14-0001' WHERE oi.order_id=1 AND oi.variant_id=1;
UPDATE inventory_items SET sold_order_id=1 WHERE serial_no='SN-IP14-0001';
UPDATE inventory_items SET sold_order_id=2 WHERE serial_no='SN-IP14-0002';
UPDATE inventory_items SET sold_order_id=3 WHERE serial_no='SN-IP14PM-0001';
UPDATE inventory_items SET sold_order_id=4 WHERE serial_no='SN-S23-0001';
UPDATE inventory_items SET sold_order_id=5 WHERE serial_no='SN-AIRP-0001';
UPDATE inventory_items SET sold_order_id=6 WHERE serial_no='SN-ASVIV-0001';
-- Split payment: DH003 tra 2 phuong thuc
INSERT INTO payments (order_id, method, amount, status, transaction_ref) VALUES
(1,'BANK_TRANSFER',24189000,'SUCCESS','VCB-20230410-001'),
(2,'CARD',22490000,'SUCCESS','POS-20230412-002'),
(3,'CASH',10000000,'SUCCESS',NULL),(3,'E_WALLET',20880000,'SUCCESS','MOMO-20230415-003'),
(4,'CARD',19990000,'SUCCESS','POS-20230422-004'),(5,'E_WALLET',5990000,'SUCCESS','ZALOPAY-20230501-005'),
(6,'BANK_TRANSFER',15990000,'SUCCESS','TCB-20230505-006'),(7,'CASH',998000,'SUCCESS',NULL),
(10,'INSTALLMENT',17990000,'SUCCESS','HDSS-20230512-010'),(11,'CASH',899000,'SUCCESS',NULL),
(13,'CARD',22990000,'SUCCESS','POS-20230320-013');
INSERT INTO return_requests (return_code, order_id, customer_id, request_date, status, reason, approved_by, decision_note) VALUES
('DT001',13,2,'2023-04-15 09:00:00','APPROVED','Khach doi y trong 30 ngay - may chua kich hoat',2,'Chap nhan doi tra, cho hoan tien'),
('DT002',1,1,'2023-05-22 10:00:00','REJECTED','Yeu cau sau 42 ngay ke tu ngay mua',2,'Qua han doi tra 30 ngay cua danh muc Dien thoai');
INSERT INTO return_items (return_id, order_item_id, quantity, condition_note, restock)
SELECT 1, oi.order_item_id, 1, 'Nguyen seal, nhap lai kho', 1 FROM sales_order_items oi WHERE oi.order_id=13 AND oi.variant_id=1;
INSERT INTO refunds (return_id, payment_id, amount, method, status, refunded_at)
SELECT 1, p.payment_id, 22990000, 'CARD', 'COMPLETED', '2023-04-15 11:00:00' FROM payments p WHERE p.order_id=13 LIMIT 1;
UPDATE payments SET status='REFUNDED' WHERE order_id=13;
INSERT INTO warranty_claims (warranty_code, inventory_item_id, customer_id, received_by, claim_date, issue_description, status, resolution_note) VALUES
('BH001',(SELECT inventory_item_id FROM inventory_items WHERE serial_no='SN-AIRP-0002'),5,5,'2023-05-12 09:30:00','Tai nghe ben trai khong sac duoc','REPAIRING','Dang kiem tra chan sac'),
('BH002',(SELECT inventory_item_id FROM inventory_items WHERE serial_no='SN-IP14PM-0001'),3,5,'2023-05-15 14:00:00','Man hinh co diem chet','DIAGNOSING',NULL);
