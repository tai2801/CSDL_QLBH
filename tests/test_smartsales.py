"""Test cac quy tac nghiep vu cot loi cua SmartSales bang Python stdlib (sqlite3).
Mo hinh hoa logic trong 04_procedures.sql / 01_schema.sql:
available = on_hand - reserved; doi tra theo cua so ngay cua danh muc;
hoan tien gan payment goc va khong vuot so da tra; stock ledger ghi moi bien dong.
Chay: python -m unittest tests.test_smartsales -v
"""
import sqlite3, unittest
from datetime import date, timedelta

def make_db():
    db = sqlite3.connect(":memory:")
    db.executescript("""
    CREATE TABLE stock(variant_id INTEGER PRIMARY KEY, on_hand INT NOT NULL CHECK(on_hand>=0),
                       reserved INT NOT NULL DEFAULT 0 CHECK(reserved>=0 AND reserved<=on_hand));
    CREATE TABLE ledger(id INTEGER PRIMARY KEY, variant_id INT, type TEXT, qty_change INT, qty_after INT);
    CREATE TABLE orders(id INTEGER PRIMARY KEY, status TEXT, order_date TEXT, total REAL);
    CREATE TABLE payments(id INTEGER PRIMARY KEY, order_id INT, amount REAL, status TEXT);
    CREATE TABLE refunds(id INTEGER PRIMARY KEY, return_id INT, payment_id INT, amount REAL);
    CREATE TABLE returns(id INTEGER PRIMARY KEY, order_id INT, window_days INT);
    """)
    db.execute("INSERT INTO stock VALUES (1, 7, 2)")   # available = 5
    db.execute("INSERT INTO stock VALUES (2, 0, 0)")
    db.execute("INSERT INTO orders VALUES (1,'COMPLETED','2023-04-20',22990000)")
    db.execute("INSERT INTO orders VALUES (2,'CANCELLED','2023-04-20',22990000)")
    db.execute("INSERT INTO payments VALUES (10,1,22990000,'SUCCESS')")
    return db

def available(db, v): 
    r=db.execute("SELECT on_hand-reserved FROM stock WHERE variant_id=?", (v,)).fetchone(); return r[0] if r else None

def create_order_item(db, v, qty):
    if qty<=0: raise ValueError("qty phai > 0")
    if available(db,v) is None or available(db,v) < qty: raise ValueError("vuot ton kho kha dung")
    db.execute("UPDATE stock SET reserved=reserved+? WHERE variant_id=?", (qty,v))
    db.execute("INSERT INTO ledger(variant_id,type,qty_change,qty_after) SELECT ?,'RESERVE',0,on_hand FROM stock WHERE variant_id=?", (v,v))

def confirm_return(db, return_id, today):
    row=db.execute("SELECT r.order_id, r.window_days, o.status, o.order_date FROM returns r JOIN orders o ON o.id=r.order_id WHERE r.id=?", (return_id,)).fetchone()
    if not row: raise ValueError("khong tim thay phieu doi tra")
    _, window, status, odate = row
    if status not in ("PAID","COMPLETED"): raise ValueError("trang thai don khong cho doi tra")
    if (today - date.fromisoformat(odate)).days > window: raise ValueError("qua han doi tra")
    return "APPROVED"

def create_refund(db, return_id, payment_id, amount):
    pay=db.execute("SELECT order_id, amount FROM payments WHERE id=?", (payment_id,)).fetchone()
    ret=db.execute("SELECT order_id FROM returns WHERE id=?", (return_id,)).fetchone()
    if not pay or not ret or pay[0]!=ret[0]: raise ValueError("payment khong thuoc don cua phieu doi tra")
    refunded=db.execute("SELECT COALESCE(SUM(amount),0) FROM refunds WHERE payment_id=?", (payment_id,)).fetchone()[0]
    if refunded+amount > pay[1]: raise ValueError("hoan vuot so da thanh toan o giao dich goc")
    db.execute("INSERT INTO refunds(return_id,payment_id,amount) VALUES (?,?,?)", (return_id,payment_id,amount))

def adjust_stock(db, v, delta):
    db.execute("UPDATE stock SET on_hand=on_hand+? WHERE variant_id=?", (delta,v))
    after=db.execute("SELECT on_hand FROM stock WHERE variant_id=?", (v,)).fetchone()[0]
    if after<0: raise ValueError("ton kho am")
    db.execute("INSERT INTO ledger(variant_id,type,qty_change,qty_after) VALUES (?, 'ADJUSTMENT', ?, ?)", (v,delta,after))

class TestSmartSales(unittest.TestCase):
    def setUp(self): self.db=make_db()
    def test_available_formula(self): self.assertEqual(available(self.db,1),5)
    def test_oversell_blocked(self):
        with self.assertRaises(ValueError): create_order_item(self.db,1,6)
        self.assertEqual(available(self.db,1),5)  # khong thay doi sau khi bi chan
    def test_sell_exact_available_ok(self):
        create_order_item(self.db,1,5); self.assertEqual(available(self.db,1),0)
    def test_sell_zero_stock_blocked(self):
        with self.assertRaises(ValueError): create_order_item(self.db,2,1)
    def test_reserve_writes_ledger(self):
        create_order_item(self.db,1,2); n=self.db.execute("SELECT COUNT(*) FROM ledger WHERE type='RESERVE'").fetchone()[0]; self.assertEqual(n,1)
    def test_return_within_window_ok(self):
        self.db.execute("INSERT INTO returns VALUES (1,1,30)")
        self.assertEqual(confirm_return(self.db,1,date(2023,5,10)),"APPROVED")  # 20 ngay
    def test_return_overdue_rejected(self):
        self.db.execute("INSERT INTO returns VALUES (1,1,30)")
        with self.assertRaises(ValueError): confirm_return(self.db,1,date(2023,5,25))  # 35 ngay
    def test_return_cancelled_order_rejected(self):
        self.db.execute("INSERT INTO returns VALUES (1,2,30)")
        with self.assertRaises(ValueError): confirm_return(self.db,1,date(2023,4,25))
    def test_refund_links_original_payment(self):
        self.db.execute("INSERT INTO returns VALUES (1,1,30)"); create_refund(self.db,1,10,5000000)
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM refunds").fetchone()[0],1)
    def test_refund_wrong_payment_rejected(self):
        self.db.execute("INSERT INTO orders VALUES (3,'COMPLETED','2023-04-20',1000)")
        self.db.execute("INSERT INTO payments VALUES (11,3,1000,'SUCCESS')")
        self.db.execute("INSERT INTO returns VALUES (1,1,30)")
        with self.assertRaises(ValueError): create_refund(self.db,1,11,500)
    def test_refund_exceeding_paid_rejected(self):
        self.db.execute("INSERT INTO returns VALUES (1,1,30)")
        with self.assertRaises(ValueError): create_refund(self.db,1,10,23000000)
    def test_partial_refunds_capped_at_paid(self):
        self.db.execute("INSERT INTO returns VALUES (1,1,30)")
        create_refund(self.db,1,10,20000000)
        with self.assertRaises(ValueError): create_refund(self.db,1,10,3000000)
    def test_adjust_stock_negative_blocked(self):
        with self.assertRaises((ValueError, sqlite3.IntegrityError)): adjust_stock(self.db,2,-1)
    def test_adjust_stock_writes_ledger(self):
        adjust_stock(self.db,1,3)
        row=self.db.execute("SELECT qty_change, qty_after FROM ledger WHERE type='ADJUSTMENT'").fetchone(); self.assertEqual(row,(3,10))
    def test_revenue_excludes_cancelled(self):
        rev=self.db.execute("SELECT COALESCE(SUM(total),0) FROM orders WHERE status IN ('PAID','COMPLETED')").fetchone()[0]
        cancelled=self.db.execute("SELECT COALESCE(SUM(total),0) FROM orders WHERE status='CANCELLED'").fetchone()[0]
        self.assertEqual(rev,22990000); self.assertEqual(cancelled,22990000)

if __name__=="__main__": unittest.main(verbosity=2)
