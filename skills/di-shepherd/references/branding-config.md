# ICCI Branding Configuration

## Report Branding Repository (PRIMARY SOURCE)

```
https://github.com/icci/icci-report-branding.git
```

Local clone: `~/Documents/GitHub/icci-report-branding/`

This repository contains everything needed for ICCI-branded report generation:

| Resource | Path |
|----------|------|
| **CSS Design System (tokens)** | `brand/tokens.css` |
| **CSS Design System (base)** | `brand/base.css` |
| **CSS Design System (components)** | `brand/components.css` |
| **Python Generator** | `python/icci_report.py` |
| **CLI Generator** | `generate_report.py` |
| **Logo (dark bg, base64)** | `assets/icci-logo-gold-b64.txt` |
| **Logo (light bg, base64)** | `assets/icci-logo-b64.txt` |
| **Logo (dark bg, PNG)** | `assets/icci-logo-gold.png` |
| **Logo (light bg, PNG)** | `assets/icci-logo.png` |
| **Brand Identity Guide** | `brand/identity.md` |
| **Layout Rules** | `brand/layout-rules.md` |
| **Usage Guide** | `USAGE.md` |

## How to Use in DI-Shepherd

When generating reports:

1. Read `USAGE.md` and `SKILL.md` in the branding repo for full integration instructions
2. Use the `ICCIReport` Python class from `python/icci_report.py` (recommended)
3. Or use the CLI: `python generate_report.py --type security --data findings.yaml`
4. CSS loads from three files: `brand/tokens.css` + `brand/base.css` + `brand/components.css`
5. Render with WeasyPrint at `/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3`
6. Follow layout rules in `brand/layout-rules.md` (minimize forced page breaks, 4-6 max)
7. Logos are always base64-embedded in HTML — never reference external files

## DI-Shepherd Report Types

Use the `security` report type for most DI-Shepherd reports. Map skill concepts to branding components:

| DI-Shepherd Concept | Branding Component |
|--------------------|--------------------|
| Fleet health summary | `stat_grid` with device counts, connectivity %, version drift |
| Threat events | `finding` cards with severity badges |
| Open event alerts | `alert` boxes (critical/warning) |
| Event timeline | `timeline` with event timestamps |
| Tenant breakdown | Tables with navy headers, cream alternating rows |
| Stale device list | Tables with `badge` severity indicators |
| Recommendations | `rec_box` components |
| Executive overview | `stat_grid` + `alert` + `pull_quote` |

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
