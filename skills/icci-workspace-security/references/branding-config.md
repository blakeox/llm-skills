# ICCI Branding Configuration

## Report Branding Repository (PRIMARY SOURCE)

```
https://github.com/icci/icci-report-branding.git
```

Local clone: `~/Documents/GitHub/icci-report-branding/`

This repository contains everything needed for ICCI-branded report generation:

| Resource | Path |
|----------|------|
| **CSS Design System** | `css/report-theme.css` |
| **Python Generator** | `python/icci_report.py` |
| **Logo (dark bg, base64)** | `assets/icci-logo-gold-b64.txt` |
| **Logo (light bg, base64)** | `assets/icci-logo-b64.txt` |
| **Logo (dark bg, PNG)** | `assets/icci-logo-gold.png` |
| **Logo (light bg, PNG)** | `assets/icci-logo.png` |
| **Brand Identity Guide** | `brand/identity.md` |
| **Layout Rules** | `brand/layout-rules.md` |
| **Usage Guide** | `USAGE.md` |

## How to Use in This Skill

When generating reports:

1. Load CSS from `~/Documents/GitHub/icci-report-branding/css/report-theme.css`
2. Load base64 logos from `~/Documents/GitHub/icci-report-branding/assets/`
3. Either use the `ICCIReport` Python class or build inline HTML using the CSS classes
4. Render with WeasyPrint at `/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3`
5. Follow layout rules in `brand/layout-rules.md` (minimize forced page breaks)

## Website Branding Repository (secondary reference)

```
https://github.com/icci/icci-website-refresh-project.git
```

Local clone: `~/Documents/GitHub/icci-website-refresh-project/`

Use this for web-specific brand assets (site colors, web fonts, HTML templates). The report branding repo above is authoritative for PDF report generation.

## Fallback Brand Values

Use these if the branding repo is unavailable:

| Element | Value |
|---------|-------|
| **Navy (primary)** | #1B2B41 |
| **Navy Light** | #293D57 |
| **Navy Dark** | #0F1A28 |
| **Gold (accent)** | #C9A55A |
| **Gold Light** | #D4B97A |
| **Gold Dark** | #A6832F |
| **Cream** | #F7F5F0 |
| **Cream Dark** | #E9E6E0 |
| **Heading Font** | Georgia, 'Times New Roman', serif |
| **Body Font** | Inter, system-ui, sans-serif |

## Brand Voice for Reports

- Professional, understated, authoritative
- Anti-hype: "No complexity, no surprises"
- Tagline: "Secure. Governed. Operational."
- Veteran-owned MSP, 30+ years, Ann Arbor/Brighton MI
- Contact: 734.995.5570, info@icci.com
