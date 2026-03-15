# Report Generation — ICCI-Branded PDF Reports

## Overview

Generate professional, ICCI-branded PDF reports for clients using WeasyPrint. Reports should look like they come from a top-10 MSP with embedded ICCI marketing.

## WeasyPrint Setup

```bash
# WeasyPrint is installed via Homebrew
# Must use Homebrew's bundled Python:
/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3

# Test:
/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3 -c "import weasyprint; print('OK')"
```

## Branding Source

Check `references/branding-config.md` for the current branding repository. Pull latest before generating reports:

```bash
cd ~/Documents/GitHub/icci-website-refresh-project && git pull
```

If unavailable, use fallback values from branding-config.md.

## Report Template Pattern

Generate PDF directly from inline HTML in Python (no separate HTML template file). Embed the ICCI logo as base64.

### Python Report Generator Pattern

```python
#!/usr/bin/env python3
"""ICCI Report Generator"""
import base64
from pathlib import Path

# Load logo
logo_path = Path(__file__).parent.parent / "assets" / "icci-logo-gold.png"
logo_b64 = base64.b64encode(logo_path.read_bytes()).decode()

# CSS using ICCI brand
CSS = """
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

@page {
    size: letter;
    margin: 0.75in;
    @bottom-center {
        content: "ICCI, LLC — Secure. Governed. Operational.";
        font-family: Georgia, serif;
        font-size: 8pt;
        color: #C9A55A;
    }
    @bottom-right {
        content: "Page " counter(page) " of " counter(pages);
        font-family: Inter, sans-serif;
        font-size: 8pt;
        color: #666;
    }
}

body {
    font-family: Inter, system-ui, sans-serif;
    font-size: 10pt;
    line-height: 1.5;
    color: #1B2B41;
}

h1, h2, h3, h4, h5, h6 {
    font-family: Georgia, 'Times New Roman', serif;
    color: #1B2B41;
    margin-top: 1.2em;
}

h1 { font-size: 22pt; border-bottom: 3px solid #C9A55A; padding-bottom: 8px; }
h2 { font-size: 16pt; border-bottom: 1px solid #C9A55A; padding-bottom: 4px; }
h3 { font-size: 13pt; color: #C9A55A; }

.header {
    background: linear-gradient(135deg, #0F1A28, #1B2B41, #293D57);
    color: #F7F5F0;
    padding: 30px;
    margin: -0.75in -0.75in 30px -0.75in;
    text-align: center;
}

.header img { height: 60px; margin-bottom: 15px; }
.header h1 { color: #C9A55A; border: none; font-size: 24pt; margin: 0; }
.header .subtitle { color: #F7F5F0; font-size: 12pt; margin-top: 8px; }
.header .meta { color: #D4B97A; font-size: 9pt; margin-top: 15px; }

.gold-bar {
    height: 3px;
    background: linear-gradient(90deg, transparent, #C9A55A, transparent);
    margin: 20px 0;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin: 15px 0;
    font-size: 9pt;
}

th {
    background: #1B2B41;
    color: #F7F5F0;
    padding: 8px 10px;
    text-align: left;
    font-family: Georgia, serif;
    font-size: 9pt;
}

td {
    padding: 6px 10px;
    border-bottom: 1px solid #E9E6E0;
}

tr:nth-child(even) { background: #F7F5F0; }

.stat-box {
    display: inline-block;
    width: 22%;
    text-align: center;
    padding: 15px;
    margin: 5px 1%;
    background: #F7F5F0;
    border-left: 3px solid #C9A55A;
}

.stat-box .number {
    font-size: 28pt;
    font-family: Georgia, serif;
    color: #C9A55A;
    font-weight: bold;
}

.stat-box .label {
    font-size: 8pt;
    color: #666;
    text-transform: uppercase;
    letter-spacing: 1px;
}

.finding-critical { border-left: 4px solid #DC2626; padding-left: 12px; margin: 10px 0; }
.finding-warning { border-left: 4px solid #F59E0B; padding-left: 12px; margin: 10px 0; }
.finding-good { border-left: 4px solid #10B981; padding-left: 12px; margin: 10px 0; }

.footer-cta {
    background: #F7F5F0;
    border: 1px solid #C9A55A;
    padding: 20px;
    margin-top: 30px;
    text-align: center;
}

.footer-cta h3 { color: #1B2B41; margin-top: 0; }
.footer-cta .phone { font-size: 16pt; color: #C9A55A; font-family: Georgia, serif; }
"""

# HTML structure
def generate_report_html(title, subtitle, date, content_html):
    return f"""<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><style>{CSS}</style></head>
<body>
<div class="header">
    <img src="data:image/png;base64,{logo_b64}" alt="ICCI">
    <h1>{title}</h1>
    <div class="subtitle">{subtitle}</div>
    <div class="meta">Report Date: {date} | ICCI, LLC — Ann Arbor / Brighton, MI | 734.995.5570</div>
</div>
{content_html}
<div class="footer-cta">
    <h3>Questions about this report?</h3>
    <p>Contact your ICCI account team</p>
    <div class="phone">734.995.5570</div>
    <p>info@icci.com | helpdesk.icci.com</p>
</div>
</body>
</html>"""

# Generate PDF
def save_pdf(html, output_path):
    import weasyprint
    weasyprint.HTML(string=html).write_pdf(output_path)
    print(f"PDF saved: {output_path}")
```

## Layout Rules

- **Page 1 is the title page only.** Header, executive summary, and stat boxes go on page 1. The Table of Contents MUST start on page 2 with a `page-break-before: always` before it. Never let the TOC bleed onto the title page.
- Each major section (h2) should start on a new page.
- Findings boxes (`finding-critical`, `finding-warning`, etc.) should have `page-break-inside: avoid`.

## Report Types

### User Directory Report
- All users with names, emails, OUs, admin status, last login
- Summary stats: total users, admins, suspended, never logged in

### MFA Coverage Report
- Enrollment status per user and per OU
- Coverage percentages with color coding (green >90%, yellow >70%, red <70%)
- Recommendations for unprotected accounts

### License Utilization Report
- Licenses assigned vs available
- Cost per user analysis
- Optimization recommendations

### Chrome Device Fleet Report
- Device inventory with serial numbers, OUs, OS versions, last sync
- Stale device detection (not synced in 30+ days)
- Deprovisioning recommendations

### School Year Readiness Report
- Student account status
- Course enrollment summary
- Device assignment status
- Guardian invitation status

## Report Output

Save to `~/Documents/claude-code/{FQDN}/`:
- PDF report (client-facing)
- Technical markdown (ICCI internal reference)
