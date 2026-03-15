# Report Generation — ICCI-Branded Security Audit PDFs

## Overview

Generate professional, ICCI-branded PDF security assessment reports using the **ICCI Report Branding** repository as the single source of truth for all styling, logos, and components.

## Report Branding Repository

```
~/Documents/GitHub/icci-report-branding/
```

GitHub: `https://github.com/icci/icci-report-branding.git` (PRIVATE)

This repo contains:

| Resource | Path | Description |
|----------|------|-------------|
| **CSS Design System** | `css/report-theme.css` | Complete component library (cover, stats, alerts, tables, timelines, badges, callouts, findings, evidence, recommendations, breach cards, blockquotes, TOC, bar charts) |
| **Python Generator** | `python/icci_report.py` | `ICCIReport` class with component helpers and WeasyPrint rendering |
| **Logos (base64)** | `assets/icci-logo-gold-b64.txt`, `assets/icci-logo-b64.txt` | For PDF embedding |
| **Logos (PNG)** | `assets/icci-logo-gold.png`, `assets/icci-logo.png` | Source files |
| **Brand Identity** | `brand/identity.md` | Colors, typography, voice, full brand guide |
| **Layout Rules** | `brand/layout-rules.md` | Page break strategy, WeasyPrint layout rules |
| **Usage Guide** | `USAGE.md` | Complete integration reference |

## WeasyPrint Setup

```bash
# WeasyPrint Python (Homebrew):
/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3

# Test:
/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3 -c "import weasyprint; print('OK')"
```

## Two Ways to Generate Reports

### Option A: Use the ICCIReport Python Class (Recommended)

```python
import sys, os
sys.path.insert(0, os.path.expanduser("~/Documents/GitHub/icci-report-branding/python"))
from icci_report import ICCIReport

report = ICCIReport(
    title="Security Posture Assessment",
    subtitle="Google Workspace Security Audit",
    client_name="Acme Corp",
    client_domain="acme.com",
    assessment_period="September 4, 2025 — March 4, 2026",
)

report.add_toc([
    ("1. Executive Summary", False),
    ("2. Findings", False),
    ("3. Recommendations", False),
])

# Add sections with raw HTML content
report.add_section("1. Executive Summary", "<p>Your content...</p>")

# Use helper methods for components
report.add_section("2. Findings",
    ICCIReport.stat_grid([
        {"value": "3", "label": "Compromises", "color": "red", "variant": "critical"},
        {"value": "1,247", "label": "Attack Events", "color": "amber", "variant": "warning"},
    ]) +
    ICCIReport.finding("INC-001", "Account Takeover", "<p>Details...</p>", "critical") +
    ICCIReport.alert("Immediate Action Required", "Description...", "critical")
)

report.generate("~/Documents/claude-code/acme.com/report.pdf")
```

### Option B: Inline HTML with CSS (for full control)

```python
# Load resources from branding repo
css = open(os.path.expanduser("~/Documents/GitHub/icci-report-branding/css/report-theme.css")).read()
logo_b64 = open(os.path.expanduser("~/Documents/GitHub/icci-report-branding/assets/icci-logo-gold-b64.txt")).read().strip()

html = f"""<!DOCTYPE html>
<html><head><style>{css}</style></head>
<body>
<div class="cover">
    <img src="data:image/png;base64,{logo_b64}" class="cover-logo" alt="ICCI">
    <h1>Report Title</h1>
    ...
</div>
<!-- Content using CSS classes from report-theme.css -->
</body></html>"""

# Render with WeasyPrint
import sys
sys.path.insert(0, "/opt/homebrew/Cellar/weasyprint/68.1/libexec/lib/python3.13/site-packages")
from weasyprint import HTML
HTML(string=html).write_pdf("output.pdf")
```

## Known Pitfalls (MUST READ)

### NEVER put `</style>` in CSS comments or any file embedded in `<style>`
HTML parsers treat `<style>` content as **raw text** — they scan for `</style>` to close the element and do NOT respect CSS comment boundaries (`/* ... */`). If the CSS file contains a literal `</style>` anywhere (even inside a comment), the HTML parser will close the `<style>` element at that point. Everything after becomes visible text content in the PDF instead of styling.

**The `_load_css()` function in `icci_report.py` has a defensive strip** that removes `</style>` from loaded CSS, but never add HTML closing tags to CSS files.

### Always visually verify the PDF after generation
Before delivering any report, open the PDF and scroll every page. Check for:
- Raw CSS text appearing as page content (indicates the `</style>` bug above)
- Unstyled/plain content (CSS not being applied)
- Blank pages (excessive page breaks)
- Orphaned headings at page bottoms
- Split cards or boxes across pages

### Run the generator with the WeasyPrint Python
Always use `/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3` to run report generators. The `ICCIReport.generate()` method handles path setup internally, but running with the WeasyPrint Python avoids import issues.

## Layout Rules (Critical)

**Read `brand/layout-rules.md` in the branding repo.** Key rules:

1. **Minimize forced page breaks.** Use only 4-6 per report at major transitions. DO NOT page-break before every section — this creates blank/sparse pages.
2. **CSS handles layout automatically** — `break-inside: avoid` keeps blocks together, `break-after: avoid` on headings prevents orphans.
3. **After generating, scroll every page** checking for blanks, orphaned headings, or split boxes.

## Security Audit Report Types

### Executive Security Assessment (Primary Deliverable)
- Cover page with client name, assessment period, classification
- Executive summary with stat grid (compromises, attacks, MFA gaps, blocks)
- Incident details with attack timeline (if compromise confirmed)
- Ongoing attack activity with targeted account tables
- Industry context with breach comparison cards
- MFA coverage gap analysis by domain
- Recommendations (immediate / short-term / ongoing)
- ICCI closing callout

See `references/report-sections.md` for full section-by-section structure.

### MFA Coverage Report (Quick Assessment)
- Coverage table by domain: users, enrolled, enforced, gaps
- High-risk accounts without MFA
- Stat boxes with coverage percentages
- Color-coded badges

### Incident Response Summary (Post-Breach)
- Timeline of compromise events
- Attacker infrastructure table (IPs, ASNs, locations)
- Forensic findings (OAuth, Drive, Gmail)
- Remediation actions taken

## Report Output

Save to `~/Documents/claude-code/{FQDN}/`:
- PDF report (client-facing)
- Technical markdown (ICCI internal reference)

### File Naming Convention

PDF reports use the format: `{Client_Name}_Security_Assessment_{DDMMMYY}.pdf`

- Date suffix uses `DDMMMYY` format, uppercased (e.g., `04MAR26`)
- Generated via: `datetime.now().strftime("%d%b%y").upper()`
- Examples:
  - `MKM_Ventures_Security_Assessment_04MAR26.pdf`
  - `Oxford_Kids_Foundation_Security_Assessment_04MAR26.pdf`
