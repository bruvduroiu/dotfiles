#!/usr/bin/env python3
"""
Uber Receipt Scraper

Scrapes Uber Business Dashboard to download PDF receipts and match them
to bank transaction IDs from a CSV file.

Uses a greedy approach: scans the dashboard page by page, matching and
downloading receipts as it goes. Stops early once all transactions are matched.

Usage:
    uber-receipts --csv /path/to/transactions.csv --output ./Uber/
    uber-receipts --csv /path/to/transactions.csv --output ./Uber/ --org-id 3971f24d-e753-54b6-8382-3a403d76c248
"""

import argparse
import csv
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

from playwright.sync_api import TimeoutError as PlaywrightTimeout
from playwright.sync_api import sync_playwright

# Default org ID - can be overridden via CLI
DEFAULT_ORG_ID = "3971f24d-e753-54b6-8382-3a403d76c248"
DASHBOARD_URL = "https://business.uber.com/dashboard/{org_id}/activity?tab=ALL_ACTIVITY"
PROFILE_DIR = os.path.expanduser("~/.local/share/uber-receipts/chromium-profile")

# Currency symbol mapping for amount normalization
CURRENCY_SYMBOLS = {
    "TWD": "NT$",
    "GBP": "\u00a3",
    "USD": "$",
    "EUR": "\u20ac",
    "JPY": "\u00a5",
    "AUD": "A$",
    "CAD": "CA$",
    "SGD": "S$",
    "HKD": "HK$",
    "KRW": "\u20a9",
    "THB": "\u0e3f",
}


def parse_csv_transactions(csv_path):
    """Parse the CSV and extract Uber ride transactions."""
    transactions = []
    with open(csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            desc = row.get("Description", "")
            amount_str = row.get("Target Amount", "").strip()
            time_str = row.get("Time", "").strip()
            tx_id = row.get("Transaction Id", "").strip()
            currency = row.get("Target Currency", "").strip()

            if not amount_str or not time_str or not tx_id:
                continue

            try:
                amount = float(amount_str)
            except ValueError:
                continue

            # Parse ISO 8601 with timezone offset like 2025-08-06T12:44:14+0800
            if re.match(r".*[+-]\d{4}$", time_str):
                time_str = time_str[:-2] + ":" + time_str[-2:]
            try:
                tx_time = datetime.fromisoformat(time_str)
            except ValueError:
                continue

            transactions.append(
                {
                    "time": tx_time,
                    "transaction_id": tx_id,
                    "description": desc,
                    "currency": currency,
                    "amount": amount,
                }
            )

    return transactions


def normalize_uber_amount(amount_text):
    """Parse Uber dashboard amount text like 'NT$378.00' into a float."""
    cleaned = amount_text.strip()
    for symbol in CURRENCY_SYMBOLS.values():
        cleaned = cleaned.replace(symbol, "")
    cleaned = re.sub(r"[^\d.\-]", "", cleaned)
    if not cleaned or cleaned == "-":
        return None
    return float(cleaned)


def detect_uber_currency(amount_text):
    """Detect the currency from Uber's amount display text."""
    for code, symbol in CURRENCY_SYMBOLS.items():
        if symbol in amount_text:
            return code
    return None


def parse_uber_date(date_str, time_str):
    """Parse Uber dashboard date/time '08/12/2025' '18:22:28' into datetime (dd/mm/yyyy)."""
    return datetime.strptime(f"{date_str} {time_str}", "%d/%m/%Y %H:%M:%S")


def find_matches_on_page(page_rides, remaining_txs, max_days_delta):
    """
    Given rides on the current page and remaining unmatched transactions,
    find all matches. Returns list of (tx, ride) tuples and updated remaining list.

    Each ride can only match one transaction (first best match wins).
    """
    matched = []
    still_remaining = []
    used_ride_indices = set()

    for tx in remaining_txs:
        best_match = None
        best_delta = float("inf")
        best_idx = None

        for i, ride in enumerate(page_rides):
            if i in used_ride_indices:
                continue
            if ride["amount"] is None:
                continue
            if abs(ride["amount"] - tx["amount"]) > 0.01:
                continue
            if (
                ride.get("currency")
                and tx["currency"]
                and tx["currency"] != ride["currency"]
            ):
                continue

            ride_dt = ride["datetime"]
            tx_dt = tx["time"].replace(tzinfo=None) if tx["time"].tzinfo else tx["time"]
            delta = abs((tx_dt - ride_dt).total_seconds())

            if delta <= max_days_delta * 86400 and delta < best_delta:
                best_delta = delta
                best_match = ride
                best_idx = i

        if best_match is not None:
            matched.append((tx, best_match))
            used_ride_indices.add(best_idx)
        else:
            still_remaining.append(tx)

    return matched, still_remaining


def _close_detail_panel(page):
    """Close the ride detail side panel if open."""
    try:
        close_btn = page.locator('role=button[name="Close"]')
        if close_btn.count() > 0 and close_btn.first.is_visible():
            close_btn.first.click()
            time.sleep(1)
    except Exception:
        pass


def _find_row_by_text(page, date_text, time_text, amount_text):
    """Re-find a ride row in the grid by matching its visible cell text.
    Returns the row ElementHandle or None."""
    rows = page.query_selector_all("role=grid >> role=row")
    for row in rows:
        cells = row.query_selector_all("role=gridcell")
        if len(cells) < 7:
            continue
        if (
            cells[0].inner_text().strip() == date_text
            and cells[1].inner_text().strip() == time_text
            and cells[6].inner_text().strip() == amount_text
        ):
            return row
    return None


def download_receipt(page, ride, output_dir, transaction_id):
    """
    Click on a ride row, download the receipt from the Transactions section, and save it.
    Re-finds the row element by visible text to avoid stale DOM references.
    Returns True if successful.
    """
    output_path = Path(output_dir) / f"{transaction_id}.pdf"
    if output_path.exists():
        print("    Already exists, skipping")
        return True

    # Re-find the row element by its visible text (avoids stale DOM handles)
    row_element = _find_row_by_text(
        page, ride["date_text"], ride["time_text"], ride["amount_text"]
    )
    if row_element is None:
        print("    ERROR: Could not re-find row in DOM")
        return False

    # Click the row to open detail panel
    row_element.click()
    time.sleep(2)

    try:
        # Wait for the Transactions section to load
        page.wait_for_selector('text="Transactions"', timeout=10000)

        # Wait for loading spinner to disappear (the detail panel shows a
        # progressbar while fetching transaction details)
        try:
            page.wait_for_selector(
                'role=progressbar[name="loading"]', state="detached", timeout=10000
            )
        except PlaywrightTimeout:
            pass  # spinner may already be gone or never appeared
        time.sleep(1)

        # Find the download button (cloud icon) in the transactions list
        # Try multiple selectors in order of specificity
        tx_download_btn = page.locator('role=listitem >> role=button[name="Download"]')

        if tx_download_btn.count() == 0:
            tx_download_btn = page.locator('button:has(img[alt="Download"])')

        if tx_download_btn.count() == 0:
            # Fallback: any button inside a list in the detail panel
            fallback = page.locator('role=list >> role=button')
            if fallback.count() == 0:
                print("    ERROR: No receipt download button found")
                _close_detail_panel(page)
                return False
            tx_download_btn = fallback

        # Click download and capture the file
        with page.expect_download(timeout=30000) as download_info:
            tx_download_btn.first.click()

        download = download_info.value
        os.makedirs(output_dir, exist_ok=True)
        download.save_as(str(output_path))
        print(f"    Saved: {output_path.name}")

    except (PlaywrightTimeout, Exception) as e:
        print(f"    ERROR: Download failed: {e}")
        _close_detail_panel(page)
        return False

    # Close the detail panel
    time.sleep(1)
    _close_detail_panel(page)
    return True


def read_page_rides(page):
    """Read all ride rows from the current page of the activity table.
    Returns list of dicts with ride info (text-based, no stored DOM handles)."""
    rides = []
    rows = page.query_selector_all("role=grid >> role=row")

    for row in rows:
        cells = row.query_selector_all("role=gridcell")
        if len(cells) < 7:
            continue  # header row

        date_text = cells[0].inner_text().strip()
        time_text = cells[1].inner_text().strip()
        amount_text = cells[6].inner_text().strip()

        if amount_text == "-":
            continue

        try:
            ride_dt = parse_uber_date(date_text, time_text)
        except ValueError:
            continue

        amount = normalize_uber_amount(amount_text)
        currency = detect_uber_currency(amount_text)

        rides.append(
            {
                "date_text": date_text,
                "time_text": time_text,
                "datetime": ride_dt,
                "amount": amount,
                "amount_text": amount_text,
                "currency": currency,
            }
        )

    return rides


def click_next_page(page):
    """Click the Right pagination button. Returns True if successful."""
    try:
        pagination = page.locator('role=group[name="button group"]')
        if pagination.count() == 0:
            return False
        right_btn = pagination.locator('role=button[name="Right"]')
        if right_btn.count() > 0 and right_btn.is_enabled() and right_btn.is_visible():
            right_btn.click()
            time.sleep(2)
            page.wait_for_selector(
                "role=grid >> role=row >> role=gridcell", timeout=10000
            )
            time.sleep(1)
            return True
    except Exception as e:
        print(f"  Pagination error: {e}")
    return False


def setup_dashboard(page, org_id, date_start, date_end):
    """Navigate to dashboard and set the date range. Returns True if ready."""
    url = DASHBOARD_URL.format(org_id=org_id)

    if "activity" not in page.url:
        page.goto(url, wait_until="domcontentloaded", timeout=120000)

    # Wait for the date range selector
    page.wait_for_selector(
        '[placeholder="YYYY/MM/DD \u2013 YYYY/MM/DD"]', timeout=30000
    )

    # Set date range
    date_range_str = f"{date_start} \u2013 {date_end}"
    print(f"Setting date range: {date_range_str}")

    date_input = page.get_by_role("textbox", name="Select a date range.")
    date_input.click()
    time.sleep(0.5)
    page.keyboard.press("Control+a")
    date_input.fill(date_range_str)
    time.sleep(1)
    page.keyboard.press("Escape")
    time.sleep(2)

    # Wait for table
    try:
        page.wait_for_selector("role=grid", timeout=15000)
        return True
    except PlaywrightTimeout:
        print("WARNING: No activity grid found.")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Download Uber receipt PDFs and match them to bank transaction IDs"
    )
    parser.add_argument(
        "--csv", required=True, help="Path to bank transactions CSV file"
    )
    parser.add_argument(
        "--output", default="./Uber", help="Output directory for PDFs (default: ./Uber)"
    )
    parser.add_argument("--org-id", default=DEFAULT_ORG_ID, help="Uber Business org ID")
    parser.add_argument(
        "--max-days-delta",
        type=int,
        default=3,
        help="Max days difference for date matching (default: 3)",
    )
    parser.add_argument(
        "--headless", action="store_true", help="Run browser in headless mode"
    )
    args = parser.parse_args()

    # Parse CSV
    all_transactions = parse_csv_transactions(args.csv)
    if not all_transactions:
        print("No Uber transactions found in CSV")
        sys.exit(0)

    print(f"Found {len(all_transactions)} Uber transactions in CSV")

    date_start = "2025/01/01"
    date_end = "2025/12/31"

    os.makedirs(args.output, exist_ok=True)

    # Filter out already-downloaded transactions
    remaining = []
    already_done = 0
    for tx in all_transactions:
        if (Path(args.output) / f"{tx['transaction_id']}.pdf").exists():
            already_done += 1
        else:
            remaining.append(tx)

    print(f"Already downloaded: {already_done}")
    print(f"Remaining to process: {len(remaining)}")

    if not remaining:
        print("All transactions already have receipts downloaded!")
        sys.exit(0)

    playwright = sync_playwright().start()
    browser = None
    total_matched = 0
    total_downloaded = 0
    total_failed = 0

    try:
        os.makedirs(PROFILE_DIR, exist_ok=True)
        browser = playwright.chromium.launch_persistent_context(
            PROFILE_DIR,
            headless=args.headless,
            viewport={"width": 1920, "height": 1080},
            accept_downloads=True,
        )

        # Always use a fresh page to avoid stale state from previous runs
        page = browser.new_page()

        # Navigate and wait for login
        url = DASHBOARD_URL.format(org_id=args.org_id)
        page.goto(url, wait_until="domcontentloaded", timeout=120000)

        print("Waiting for dashboard to load (log in if prompted)...")
        login_prompted = False
        deadline = time.time() + 120
        while time.time() < deadline:
            if "auth.uber.com" in page.url and not login_prompted:
                login_prompted = True
                print("\n" + "=" * 60)
                print("LOGIN REQUIRED")
                print("Please log in to Uber Business in the browser window.")
                print("The script will continue automatically after login.")
                print("=" * 60 + "\n")
                deadline = time.time() + 300

            try:
                date_input = page.query_selector(
                    '[placeholder="YYYY/MM/DD \u2013 YYYY/MM/DD"]'
                )
                if date_input and date_input.is_visible():
                    print("Dashboard ready!")
                    break
            except Exception:
                pass
            time.sleep(2)
        else:
            print("ERROR: Timed out waiting for dashboard")
            sys.exit(1)

        # Set up date range and wait for table
        if not setup_dashboard(page, args.org_id, date_start, date_end):
            print("No activity found for date range")
            sys.exit(1)

        # Greedy page-by-page processing
        page_num = 1
        while remaining:
            print(f"\n--- Page {page_num} ---")

            # Read rides on current page
            page_rides = read_page_rides(page)
            print(f"  Rides on page: {len(page_rides)}")

            if not page_rides:
                print("  No rides found, stopping.")
                break

            # Match remaining transactions against this page's rides
            page_matches, remaining = find_matches_on_page(
                page_rides, remaining, args.max_days_delta
            )

            print(f"  Matched: {len(page_matches)} | Still remaining: {len(remaining)}")

            # Download receipts for matches immediately
            for tx, ride in page_matches:
                total_matched += 1
                print(
                    f"  [{total_matched}] {tx['time'].strftime('%Y-%m-%d')} {tx['currency']} {tx['amount']:.2f} "
                    f"-> Uber {ride['date_text']} {ride['amount_text']}"
                )

                if download_receipt(
                    page, ride, args.output, tx["transaction_id"]
                ):
                    total_downloaded += 1
                else:
                    total_failed += 1

            # If all transactions matched, we're done
            if not remaining:
                print("\nAll transactions matched!")
                break

            # Try next page
            if not click_next_page(page):
                print("\n  No more pages available.")
                break
            page_num += 1

    finally:
        if browser:
            try:
                browser.close()
            except Exception:
                pass
        try:
            playwright.stop()
        except Exception:
            pass

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print(f"  Total CSV transactions: {len(all_transactions)}")
    print(f"  Previously downloaded: {already_done}")
    print(f"  Matched this run: {total_matched}")
    print(f"  Downloaded this run: {total_downloaded}")
    print(f"  Failed: {total_failed}")
    print(f"  Still unmatched: {len(remaining)}")
    print(f"  Total receipts on disk: {already_done + total_downloaded}")
    print(f"  Output: {os.path.abspath(args.output)}/")
    print("=" * 60)

    if remaining:
        print(f"\nUnmatched transactions ({len(remaining)}):")
        for tx in remaining:
            print(
                f"  {tx['time'].strftime('%Y-%m-%d %H:%M')} | {tx['currency']} {tx['amount']:.2f} | {tx['transaction_id']}"
            )


if __name__ == "__main__":
    main()
