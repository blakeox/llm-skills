# Reporting Reference

## HappyFox Built-in Reports

Available via MCP (all untested):

- `happyfox_reports_list` — list available reports
- `happyfox_report_get` — get specific report
- `happyfox_report_summary` — summary stats
- `happyfox_report_tabular` — tabular data export
- `happyfox_report_staff_activity` — staff activity metrics
- `happyfox_report_staff_performance` — performance stats
- `happyfox_report_contact_activity` — contact/client activity
- `happyfox_report_response_stats` — response time stats
- `happyfox_report_sla_entries` — SLA tracking

## ICCI-Branded PDF Reports

All reports MUST use the `icci-report-branding` system.

### Setup

```python
import sys, os
sys.path.insert(0, os.path.expanduser("~/Documents/GitHub/icci-report-branding/python"))
from icci_report import ICCIReport
```

### Always Read Branding Repo Fresh

The branding instructions at `~/Documents/GitHub/icci-report-branding/` are the authoritative source. Read the repo's SKILL.md and brand/identity.md before generating any report. Do not rely on cached brand knowledge — colors, fonts, or layout rules may have been updated.

### Report Output Directory

All HappyFox reports go to: `~/Documents/claude-code/happyfox/`

### Common Report Types

1. **Weekly ticket summary** — open/closed counts, category breakdown, staff activity
2. **Client activity report** — tickets per client over time period
3. **SLA compliance report** — response time analysis
4. **Staff performance** — tickets handled, resolution time

### Token-Efficient Report Generation

For reports involving many tickets:

1. Use `scripts/bulk_ticket_search.py` to collect data into a JSON/YAML file
2. Generate the report from the data file using ICCIReport class
3. This keeps raw ticket data OUT of the conversation context
