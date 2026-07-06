#!/usr/bin/env python3
"""Refresh Cur Price (col E) in portfolio-tracker.ods from Alpha Vantage.

Usage:
  export ALPHAVANTAGE_API_KEY=xxxx   # provided by sops via fish shellInit
  portfolio-update-prices            # updates ~/Documents/Finance/portfolio-tracker.ods

Flags:
  --file PATH   ODS to update (default ~/Documents/Finance/portfolio-tracker.ods)
  --dry         no network; write a sentinel price to prove the write path
  --sleep N     seconds between API calls (default 15; free tier = 5/min, 25/day)
"""
import os
import sys
import time
import argparse

from odf.opendocument import load
from odf.table import Table, TableRow, TableCell
from odf.text import P
from odf import teletype

AV_URL = "https://www.alphavantage.co/query"
COL_SYMBOL = 0   # A
COL_PRICE = 4    # E
SKIP_SYMBOLS = {"TOTAL", "SYMBOL"}   # header / totals rows are never quotes


def fetch_price(symbol, apikey, session):
    r = session.get(AV_URL, params={
        "function": "GLOBAL_QUOTE", "symbol": symbol, "apikey": apikey,
    }, timeout=15)
    r.raise_for_status()
    data = r.json()
    # AV signals throttle/invalid-key with Note / Information / empty quote
    if "Note" in data or "Information" in data:
        raise RuntimeError(data.get("Note") or data.get("Information"))
    q = data.get("Global Quote") or {}
    px = q.get("05. price")
    if not px:
        raise RuntimeError(f"no price in response for {symbol}: {data}")
    return float(px)


def set_price_cell(row, price):
    """Replace col-E cell in place, preserving its style."""
    cells = row.getElementsByType(TableCell)
    old = cells[COL_PRICE]
    style = old.getAttribute("stylename")
    new = TableCell(valuetype="float", value=str(price))
    if style:
        new.setAttribute("stylename", style)
    new.addElement(P(text=f"{price:.2f}"))
    row.insertBefore(new, old)
    row.removeChild(old)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", default=os.path.expanduser("~/Documents/Finance/portfolio-tracker.ods"))
    ap.add_argument("--dry", action="store_true")
    ap.add_argument("--sleep", type=float, default=15.0)
    args = ap.parse_args()

    apikey = os.environ.get("ALPHAVANTAGE_API_KEY")
    if not args.dry and not apikey:
        sys.exit("ERROR: set ALPHAVANTAGE_API_KEY in the environment (never hardcode it).")

    doc = load(args.file)
    table = doc.getElementsByType(Table)[0]        # first sheet = Portfolio
    rows = table.getElementsByType(TableRow)

    session = None
    if not args.dry:
        import requests
        session = requests.Session()

    updated, failed, attempts = 0, 0, 0
    for row in rows[1:]:                      # skip header row
        cells = row.getElementsByType(TableCell)
        if len(cells) <= COL_PRICE:
            continue
        symbol = teletype.extractText(cells[COL_SYMBOL]).strip()
        if not symbol or symbol.upper() in SKIP_SYMBOLS:
            continue
        try:
            if args.dry:
                price = 123.45
            else:
                if attempts:                 # space BEFORE every call after the first
                    time.sleep(args.sleep)
                attempts += 1
                price = fetch_price(symbol, apikey, session)
            set_price_cell(row, price)
            print(f"  {symbol:8s} -> {price:.2f}")
            updated += 1
        except Exception as e:  # keep going; one bad symbol shouldn't abort
            print(f"  {symbol:8s} FAILED: {e}")
            failed += 1

    doc.save(args.file)
    print(f"done: {updated} updated, {failed} failed -> {args.file}")
    if updated:
        print("Open in LibreOffice; dependent formulas (P/L, weights, rebalance) recalc automatically.")


if __name__ == "__main__":
    main()
