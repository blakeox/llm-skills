# ICCI Branding Configuration

## Report Branding Repository (PRIMARY SOURCE)

```
https://github.com/icci/icci-report-branding.git
```

Local clone: `~/Documents/GitHub/icci-report-branding/`

| Resource                           | Path                            |
| ---------------------------------- | ------------------------------- |
| **CSS Design System (tokens)**     | `brand/tokens.css`              |
| **CSS Design System (base)**       | `brand/base.css`                |
| **CSS Design System (components)** | `brand/components.css`          |
| **Python Generator**               | `python/icci_report.py`         |
| **CLI Generator**                  | `generate_report.py`            |
| **Logo (dark bg, base64)**         | `assets/icci-logo-gold-b64.txt` |
| **Logo (light bg, base64)**        | `assets/icci-logo-b64.txt`      |
| **Brand Identity Guide**           | `brand/identity.md`             |
| **Layout Rules**                   | `brand/layout-rules.md`         |
| **Usage Guide**                    | `USAGE.md`                      |

## Brand Voice

- Professional, understated, authoritative
- Anti-hype: "No complexity, no surprises"
- Tagline: "Secure. Governed. Operational."
- Veteran-owned MSP, 30+ years, Ann Arbor/Brighton MI
- Contact: 734.995.5570, info@icci.com

## Fallback Brand Values

Use these if the branding repo is unavailable:

| Element            | Value                             |
| ------------------ | --------------------------------- |
| **Navy (primary)** | #1B2B41                           |
| **Navy Light**     | #293D57                           |
| **Navy Dark**      | #0F1A28                           |
| **Gold (accent)**  | #C9A55A                           |
| **Gold Light**     | #D4B97A                           |
| **Gold Dark**      | #A6832F                           |
| **Cream**          | #F7F5F0                           |
| **Cream Dark**     | #E9E6E0                           |
| **Heading Font**   | Georgia, 'Times New Roman', serif |
| **Body Font**      | Inter, system-ui, sans-serif      |

## HTML Formatting for Tickets

When generating HTML for HappyFox ticket descriptions or emails:

- Heading borders: navy (`#1B2B41`) with gold (`#C9A55A`) accents
- Headings: Georgia serif
- Body: Inter sans-serif
- Table rows: cream (`#F7F5F0`) alternating
- Alert colors: Red (#DC2626), Green (#2D8A4E), Amber (#B45309), Blue (#2563EB)
- Always use `contentType: "text/html"` with `<p>` tags for Gmail drafts (prevents RFC 2822 hard wrapping)
