-- SmartSales Database - 01_schema.sql - MySQL 8.0+
-- Thiet ke boi Nhom 2 - HUIT.
CREATE DATABASE IF NOT EXISTS smartsales CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE smartsales;

CREATE TABLE brands (
  brand_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  brand_code VARCHAR(20) NOT NULL UNIQUE,
  brand_name VARCHAR(120) NOT NULL UNIQUE,
  country VARCHAR(80), website VARCHAR(255), is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE categories (
  category_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_code VARCHAR(20) NOT NULL UNIQUE,
  category_name VARCHAR(120) NOT NULL,
  parent_id INT UNSIGNED NULL,
  return_window_days INT NOT NULL DEFAULT 30 CHECK (return_window_days BETWEEN 0 AND 365),
  warranty_months_default INT NOT NULL DEFAULT 12 CHECK (warranty_months_default BETWEEN 0 AND 120),
  CONSTRAINT fk_cat_parent FOREIGN KEY (parent_id) REFERENCES categories(category_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE suppliers (
  supplier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  supplier_code VARCHAR(20) NOT NULL UNIQUE,
  supplier_name VARCHAR(200) NOT NULL,
  tax_code VARCHAR(20) UNIQUE, contact_name VARCHAR(120), phone VARCHAR(20), email VARCHAR(150),
  address VARCHAR(255), payment_term_days INT NOT NULL DEFAULT 30 CHECK (payment_term_days>=0),
  is_active TINYINT(1) NOT NULL DEFAULT 1, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (email IS NULL OR email LIKE '%@%')
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(40) NOT NULL UNIQUE,
  product_name VARCHAR(200) NOT NULL,
  brand_id INT UNSIGNED NOT NULL, category_id INT UNSIGNED NOT NULL,
  has_serial TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1=quan ly tung serial, 0=quan ly so luong (phu kien)',
  description TEXT, is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_prod_brand FOREIGN KEY (brand_id) REFERENCES brands(brand_id),
  CONSTRAINT fk_prod_cat FOREIGN KEY (category_id) REFERENCES categories(category_id),
  INDEX idx_prod_name (product_name), INDEX idx_prod_brand_cat (brand_id, category_id)
) ENGINE=InnoDB;

CREATE TABLE product_variants (
  variant_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id INT UNSIGNED NOT NULL,
  variant_sku VARCHAR(50) NOT NULL UNIQUE,
  variant_name VARCHAR(200) NOT NULL COMMENT 'VD: 256GB - Den',
  cost_price DECIMAL(15,2) NOT NULL CHECK (cost_price>=0),
  sale_price DECIMAL(15,2) NOT NULL CHECK (sale_price>=0),
  reorder_point INT NOT NULL DEFAULT 5 CHECK (reorder_point>=0),
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  CONSTRAINT fk_var_prod FOREIGN KEY (product_id) REFERENCES products(product_id),
  CHECK (sale_price >= 0)
) ENGINE=InnoDB;

CREATE TABLE price_history (
  price_history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  variant_id INT UNSIGNED NOT NULL,
  old_cost DECIMAL(15,2), new_cost DECIMAL(15,2), old_sale DECIMAL(15,2), new_sale DECIMAL(15,2),
  changed_by INT UNSIGNED NULL, reason VARCHAR(255), changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ph_var FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
  INDEX idx_ph_var_time (variant_id, changed_at)
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_code VARCHAR(20) NOT NULL UNIQUE,
  full_name VARCHAR(150) NOT NULL, phone VARCHAR(20) NOT NULL UNIQUE, email VARCHAR(150) UNIQUE,
  address VARCHAR(255), loyalty_points INT NOT NULL DEFAULT 0 CHECK (loyalty_points>=0),
  customer_tier ENUM('STANDARD','SILVER','GOLD','VIP') NOT NULL DEFAULT 'STANDARD',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK (email IS NULL OR email LIKE '%@%'), INDEX idx_cust_name (full_name)
) ENGINE=InnoDB;

CREATE TABLE employees (
  employee_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_code VARCHAR(20) NOT NULL UNIQUE,
  full_name VARCHAR(150) NOT NULL, phone VARCHAR(20), email VARCHAR(150) UNIQUE,
  role ENUM('ADMIN','MANAGER','SALES','WAREHOUSE','TECHNICIAN','ACCOUNTANT') NOT NULL,
  hired_at DATE, is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE user_accounts (
  account_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  employee_id INT UNSIGNED NOT NULL UNIQUE,
  username VARCHAR(60) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL COMMENT 'Chi luu hash bcrypt/argon2, khong luu mat khau that',
  last_login_at DATETIME NULL, is_locked TINYINT(1) NOT NULL DEFAULT 0,
  CONSTRAINT fk_acc_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
) ENGINE=InnoDB;

-- Gan FK changed_by sau khi employees ton tai
ALTER TABLE price_history ADD CONSTRAINT fk_ph_emp FOREIGN KEY (changed_by) REFERENCES employees(employee_id) ON DELETE SET NULL;

CREATE TABLE purchase_orders (
  purchase_order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  po_code VARCHAR(25) NOT NULL UNIQUE,
  supplier_id INT UNSIGNED NOT NULL, created_by INT UNSIGNED NOT NULL,
  order_date DATE NOT NULL, expected_date DATE NULL,
  status ENUM('DRAFT','CONFIRMED','RECEIVED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  total_cost DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (total_cost>=0), note VARCHAR(255),
  CONSTRAINT fk_po_sup FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
  CONSTRAINT fk_po_emp FOREIGN KEY (created_by) REFERENCES employees(employee_id),
  CHECK (expected_date IS NULL OR expected_date >= order_date)
) ENGINE=InnoDB;

CREATE TABLE purchase_order_items (
  po_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  purchase_order_id INT UNSIGNED NOT NULL, variant_id INT UNSIGNED NOT NULL,
  quantity INT NOT NULL CHECK (quantity>0), unit_cost DECIMAL(15,2) NOT NULL CHECK (unit_cost>=0),
  received_quantity INT NOT NULL DEFAULT 0 CHECK (received_quantity>=0),
  CONSTRAINT fk_poi_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(purchase_order_id) ON DELETE CASCADE,
  CONSTRAINT fk_poi_var FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
  UNIQUE KEY uq_poi (purchase_order_id, variant_id), CHECK (received_quantity <= quantity)
) ENGINE=InnoDB;

CREATE TABLE inventory_stock (
  variant_id INT UNSIGNED PRIMARY KEY,
  qty_on_hand INT NOT NULL DEFAULT 0 CHECK (qty_on_hand>=0),
  qty_reserved INT NOT NULL DEFAULT 0 CHECK (qty_reserved>=0),
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_stock_var FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
  CHECK (qty_reserved <= qty_on_hand)
) ENGINE=InnoDB;

CREATE TABLE inventory_items (
  inventory_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  variant_id INT UNSIGNED NOT NULL,
  serial_no VARCHAR(80) NOT NULL UNIQUE,
  status ENUM('IN_STOCK','RESERVED','SOLD','IN_WARRANTY','RETURNED','DEFECTIVE','SCRAPPED') NOT NULL DEFAULT 'IN_STOCK',
  purchase_order_id INT UNSIGNED NULL, sold_order_id INT UNSIGNED NULL,
  warranty_expires_at DATE NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_item_var FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
  CONSTRAINT fk_item_po FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(purchase_order_id) ON DELETE SET NULL,
  INDEX idx_item_status (variant_id, status)
) ENGINE=InnoDB;

CREATE TABLE stock_ledger (
  ledger_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  variant_id INT UNSIGNED NOT NULL,
  movement_type ENUM('PURCHASE_IN','SALE_OUT','RESERVE','RELEASE_RESERVE','RETURN_IN','WARRANTY_OUT','ADJUSTMENT','SCRAP') NOT NULL,
  qty_change INT NOT NULL, qty_after INT NOT NULL,
  ref_type VARCHAR(30), ref_id INT UNSIGNED NULL, serial_no VARCHAR(80) NULL,
  actor_id INT UNSIGNED NULL, note VARCHAR(255), created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_ledger_var FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
  CONSTRAINT fk_ledger_emp FOREIGN KEY (actor_id) REFERENCES employees(employee_id) ON DELETE SET NULL,
  INDEX idx_ledger_var_time (variant_id, created_at)
) ENGINE=InnoDB;

CREATE TABLE sales_orders (
  order_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_code VARCHAR(25) NOT NULL UNIQUE,
  customer_id INT UNSIGNED NOT NULL, sales_employee_id INT UNSIGNED NOT NULL,
  order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('DRAFT','CONFIRMED','PAID','COMPLETED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  subtotal DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (subtotal>=0),
  discount_amount DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (discount_amount>=0),
  total_amount DECIMAL(15,2) NOT NULL DEFAULT 0 CHECK (total_amount>=0),
  note VARCHAR(255),
  CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_ord_emp FOREIGN KEY (sales_employee_id) REFERENCES employees(employee_id),
  INDEX idx_ord_date_status (order_date, status), INDEX idx_ord_cust (customer_id)
) ENGINE=InnoDB;

CREATE TABLE sales_order_items (
  order_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL, variant_id INT UNSIGNED NOT NULL,
  quantity INT NOT NULL CHECK (quantity>0),
  unit_price DECIMAL(15,2) NOT NULL CHECK (unit_price>=0),
  unit_cost_snapshot DECIMAL(15,2) NOT NULL DEFAULT 0 COMMENT 'Gia von tai thoi diem ban de tinh loi nhuan dung',
  line_total DECIMAL(15,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  CONSTRAINT fk_oi_ord FOREIGN KEY (order_id) REFERENCES sales_orders(order_id) ON DELETE CASCADE,
  CONSTRAINT fk_oi_var FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id),
  UNIQUE KEY uq_oi (order_id, variant_id), CHECK (unit_cost_snapshot>=0)
) ENGINE=InnoDB;

CREATE TABLE order_item_serials (
  order_item_id INT UNSIGNED NOT NULL, inventory_item_id INT UNSIGNED NOT NULL,
  PRIMARY KEY (order_item_id, inventory_item_id),
  CONSTRAINT fk_ois_item FOREIGN KEY (order_item_id) REFERENCES sales_order_items(order_item_id) ON DELETE CASCADE,
  CONSTRAINT fk_ois_inv FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(inventory_item_id),
  UNIQUE KEY uq_ois_inv (inventory_item_id)
) ENGINE=InnoDB;

ALTER TABLE inventory_items ADD CONSTRAINT fk_item_order FOREIGN KEY (sold_order_id) REFERENCES sales_orders(order_id) ON DELETE SET NULL;

CREATE TABLE payments (
  payment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  order_id INT UNSIGNED NOT NULL,
  method ENUM('CASH','BANK_TRANSFER','CARD','E_WALLET','INSTALLMENT') NOT NULL,
  amount DECIMAL(15,2) NOT NULL CHECK (amount>0),
  status ENUM('PENDING','SUCCESS','FAILED','REFUNDED','PARTIALLY_REFUNDED') NOT NULL DEFAULT 'SUCCESS',
  transaction_ref VARCHAR(100) UNIQUE, paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pay_ord FOREIGN KEY (order_id) REFERENCES sales_orders(order_id),
  INDEX idx_pay_order (order_id)
) ENGINE=InnoDB;

CREATE TABLE return_requests (
  return_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  return_code VARCHAR(25) NOT NULL UNIQUE,
  order_id INT UNSIGNED NOT NULL, customer_id INT UNSIGNED NOT NULL,
  request_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('PENDING','APPROVED','REJECTED','COMPLETED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  reason VARCHAR(500) NOT NULL, approved_by INT UNSIGNED NULL, decision_note VARCHAR(255),
  CONSTRAINT fk_ret_ord FOREIGN KEY (order_id) REFERENCES sales_orders(order_id),
  CONSTRAINT fk_ret_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_ret_emp FOREIGN KEY (approved_by) REFERENCES employees(employee_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE return_items (
  return_item_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  return_id INT UNSIGNED NOT NULL, order_item_id INT UNSIGNED NOT NULL,
  quantity INT NOT NULL CHECK (quantity>0), condition_note VARCHAR(255),
  restock TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1=nhap lai kho ban duoc, 0=hong/chuyen bao hanh',
  CONSTRAINT fk_ri_ret FOREIGN KEY (return_id) REFERENCES return_requests(return_id) ON DELETE CASCADE,
  CONSTRAINT fk_ri_oi FOREIGN KEY (order_item_id) REFERENCES sales_order_items(order_item_id),
  UNIQUE KEY uq_ri (return_id, order_item_id)
) ENGINE=InnoDB;

CREATE TABLE refunds (
  refund_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  return_id INT UNSIGNED NOT NULL, payment_id INT UNSIGNED NOT NULL COMMENT 'Bat buoc gan giao dich thanh toan goc',
  amount DECIMAL(15,2) NOT NULL CHECK (amount>0), method ENUM('CASH','BANK_TRANSFER','CARD','E_WALLET','INSTALLMENT') NOT NULL,
  status ENUM('PENDING','COMPLETED','FAILED') NOT NULL DEFAULT 'PENDING',
  refunded_at DATETIME NULL,
  CONSTRAINT fk_ref_ret FOREIGN KEY (return_id) REFERENCES return_requests(return_id),
  CONSTRAINT fk_ref_pay FOREIGN KEY (payment_id) REFERENCES payments(payment_id),
  INDEX idx_refund_pay (payment_id)
) ENGINE=InnoDB;

CREATE TABLE warranty_claims (
  warranty_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  warranty_code VARCHAR(25) NOT NULL UNIQUE,
  inventory_item_id INT UNSIGNED NOT NULL COMMENT 'Bao hanh theo serial cu the',
  customer_id INT UNSIGNED NOT NULL, received_by INT UNSIGNED NOT NULL,
  claim_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  issue_description VARCHAR(500) NOT NULL,
  status ENUM('RECEIVED','DIAGNOSING','REPAIRING','COMPLETED','REJECTED','REPLACED') NOT NULL DEFAULT 'RECEIVED',
  resolution_note VARCHAR(500), completed_at DATETIME NULL,
  CONSTRAINT fk_war_item FOREIGN KEY (inventory_item_id) REFERENCES inventory_items(inventory_item_id),
  CONSTRAINT fk_war_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_war_emp FOREIGN KEY (received_by) REFERENCES employees(employee_id)
) ENGINE=InnoDB;
