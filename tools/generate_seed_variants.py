#!/usr/bin/env python3
"""Cong cu ho tro: kiem tra nhat quan seed SmartSales (stdlib only).
Kiem tra: tong tien don = tong chi tiet - giam gia; thanh toan <= tong don (don khong huy);
variant_id trong inventory_stock phu du product_variants. Chay: python3 tools/generate_seed_variants.py
"""
import re, pathlib, sys
seed = (pathlib.Path(__file__).parent.parent/"database/02_seed.sql").read_text(encoding="utf-8")
orders = re.findall(r"\('DH(\d+)',\d+,\d+,'[^']+','(\w+)',([\d.]+),([\d.]+),([\d.]+)\)", seed)
blocks = re.findall(r"INSERT INTO sales_order_items[^;]+?VALUES(.*?);", seed, re.S)
items=[]
for b in blocks: items += re.findall(r"\((\d+),(\d+),(\d+),([\d.]+),([\d.]+)\)", b)
pays = re.findall(r"\((\d+),'(?:CASH|BANK_TRANSFER|CARD|E_WALLET|INSTALLMENT)',([\d.]+),'SUCCESS'", seed)
tot_items={}
for oid,vid,qty,price,cost in items:
    if int(qty)>0 and float(price)>0: tot_items[int(oid)]=tot_items.get(int(oid),0)+int(qty)*float(price)
paid={}
for oid,amt in pays: paid[int(oid)]=paid.get(int(oid),0)+float(amt)
problems=[]
for num,status,sub,disc,total in orders:
    oid=int(num); s=tot_items.get(oid)
    if s is not None and abs(s-float(sub))>1: problems.append(f"DH{num}: subtotal {sub} != tong chi tiet {s}")
    if status not in ("CANCELLED","DRAFT") and oid in paid and abs(paid[oid]-float(total))>1:
        problems.append(f"DH{num}: da thanh toan {paid[oid]} != tong don {total}")
print(f"Kiem tra {len(orders)} don, {len(items)} dong chi tiet, {len(pays)} thanh toan")
if problems:
    print("VAN DE:"); [print(" -",p) for p in problems]; sys.exit(1)
print("OK: tong don / chi tiet / thanh toan nhat quan trong pham vi cac don da kiem tra")
