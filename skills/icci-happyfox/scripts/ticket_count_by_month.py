#!/usr/bin/env python3
"""
Count HappyFox tickets by creation month — runs outside Claude context to save tokens.

Usage (called by Claude via Agent subagent):
    1. Agent pages through ticket_filter(size=100, page=N) collecting all tickets
    2. Agent writes raw JSON array to --input file
    3. This script counts by created_at month and outputs a summary

    python3 scripts/ticket_count_by_month.py --input /tmp/all_tickets.json --output /tmp/counts.json
    python3 scripts/ticket_count_by_month.py --input /tmp/all_tickets.json --output /tmp/counts.json --months 2025-11,2025-12,2026-01

Why this exists:
    - ticket_filter sorts by updated_at, NOT created_at — so you can't stop paginating
      when you hit a date boundary. You must fetch ALL tickets.
    - ticket_filter has no date-range parameter (see FR-009 in mcp-feature-requests.md)
    - Pulling hundreds of full ticket records into Claude's context wastes tokens.
    - This script processes the raw data outside context and returns only the summary.

Input format:
    JSON array of ticket objects. Each must have a "created_at" field (ISO 8601 string).
    The MCP's ticket_filter returns objects with created_at in "YYYY-MM-DDTHH:MM:SS" format.

Output format (JSON):
    {
        "generated": "2026-03-12T10:30:00",
        "total_tickets": 850,
        "months_requested": ["2025-11", "2025-12", "2026-01"],
        "counts_by_month": {
            "2025-11": 83,
            "2025-12": 96,
            "2026-01": 111
        },
        "all_months": {
            "2024-06": 12,
            "2024-07": 45,
            ...
        }
    }
"""

import argparse
import json
import sys
from collections import Counter
from datetime import datetime


def extract_month(created_at: str) -> str:
    """Extract YYYY-MM from a created_at timestamp."""
    # Handle various ISO 8601 formats
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
        try:
            dt = datetime.strptime(created_at.split("+")[0].split("Z")[0], fmt)
            return dt.strftime("%Y-%m")
        except ValueError:
            continue
    return "unknown"


def main():
    parser = argparse.ArgumentParser(description="Count HappyFox tickets by creation month")
    parser.add_argument("--input", required=True, help="Input JSON file with ticket array")
    parser.add_argument("--output", required=True, help="Output JSON file for counts")
    parser.add_argument("--months", help="Comma-separated YYYY-MM months to highlight (optional)")

    args = parser.parse_args()

    with open(args.input) as f:
        tickets = json.load(f)

    if not isinstance(tickets, list):
        print("ERROR: Input must be a JSON array of ticket objects", file=sys.stderr)
        sys.exit(1)

    # Count by month
    month_counter = Counter()
    missing_date = 0
    for ticket in tickets:
        created_at = ticket.get("created_at") or ticket.get("created") or ""
        if not created_at:
            missing_date += 1
            continue
        month = extract_month(created_at)
        month_counter[month] += 1

    # Build output
    all_months = dict(sorted(month_counter.items()))
    result = {
        "generated": datetime.now().isoformat(),
        "total_tickets": len(tickets),
        "tickets_missing_date": missing_date,
        "all_months": all_months,
    }

    # If specific months requested, extract those
    if args.months:
        requested = [m.strip() for m in args.months.split(",")]
        result["months_requested"] = requested
        result["counts_by_month"] = {m: month_counter.get(m, 0) for m in requested}

    with open(args.output, "w") as f:
        json.dump(result, f, indent=2)

    # Print summary to stdout for Claude to read
    print(f"Processed {len(tickets)} tickets ({missing_date} missing dates)")
    if args.months:
        for m in [m.strip() for m in args.months.split(",")]:
            print(f"  {m}: {month_counter.get(m, 0)} tickets")
    else:
        for m, count in sorted(month_counter.items()):
            print(f"  {m}: {count} tickets")
    print(f"Full results -> {args.output}")


if __name__ == "__main__":
    main()
