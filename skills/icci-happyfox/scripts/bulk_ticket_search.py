#!/usr/bin/env python3
"""
Bulk ticket operations for HappyFox — runs outside Claude context to save tokens.

Usage (called by Claude via Bash tool):
    python3 scripts/bulk_ticket_search.py --action search --query "keyword" --output /tmp/results.json
    python3 scripts/bulk_ticket_search.py --action summary --output /tmp/summary.json

This script is a FRAMEWORK — add new actions as needed.
The MCP tools are used by Claude directly; this script handles
large-data operations that would waste context tokens.
"""

import argparse
import json
import sys
from datetime import datetime


def main():
    parser = argparse.ArgumentParser(description="HappyFox bulk operations (token-efficient)")
    parser.add_argument("--action", required=True, choices=["search", "summary", "export"],
                        help="Operation to perform")
    parser.add_argument("--input", help="Input JSON file (from MCP tool output)")
    parser.add_argument("--query", help="Search query string")
    parser.add_argument("--output", required=True, help="Output file path")
    parser.add_argument("--format", default="json", choices=["json", "csv", "yaml"],
                        help="Output format")

    args = parser.parse_args()

    if args.action == "search":
        # Placeholder — Claude feeds MCP results into --input, this script filters/aggregates
        if not args.input:
            print("ERROR: --input required for search action", file=sys.stderr)
            sys.exit(1)
        with open(args.input) as f:
            data = json.load(f)
        # Filter by query if provided
        if args.query:
            q = args.query.lower()
            filtered = [t for t in data if q in t.get("subject", "").lower()
                        or q in t.get("description", "").lower()]
        else:
            filtered = data
        with open(args.output, "w") as f:
            json.dump(filtered, f, indent=2)
        print(f"Found {len(filtered)} matching tickets -> {args.output}")

    elif args.action == "summary":
        if not args.input:
            print("ERROR: --input required for summary action", file=sys.stderr)
            sys.exit(1)
        with open(args.input) as f:
            data = json.load(f)
        summary = {
            "generated": datetime.now().isoformat(),
            "total_tickets": len(data),
            "by_status": {},
            "by_category": {},
            "by_priority": {},
            "by_assignee": {},
        }
        for t in data:
            for key, field in [("by_status", "status"), ("by_category", "category"),
                               ("by_priority", "priority"), ("by_assignee", "assignee")]:
                val = t.get(field, "Unknown")
                summary[key][val] = summary[key].get(val, 0) + 1
        with open(args.output, "w") as f:
            json.dump(summary, f, indent=2)
        print(f"Summary of {len(data)} tickets -> {args.output}")

    elif args.action == "export":
        # Future: export tickets to CSV/YAML for report generation
        print("Export action not yet implemented", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
