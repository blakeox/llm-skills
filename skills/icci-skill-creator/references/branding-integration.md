# ICCI Report Branding Integration

How to wire up ICCI branding in a new skill. The branding repo is the single source of truth for all formatted output — PDFs, HTML tickets, email drafts, and internal reports.

## Source of Truth

**Repository:** `~/Documents/GitHub/icci-report-branding/`
**Brand guide:** `brand/identity.md`

Read `brand/identity.md` before generating ANY client-facing or internal formatted output.

## When Branding is Required

| Output Type                  | Branding Required | Notes                                                                   |
| ---------------------------- | ----------------- | ----------------------------------------------------------------------- |
| PDF reports                  | Yes               | Full branding: cover page, headers, footers, colors, fonts              |
| HappyFox ticket descriptions | Yes               | ICCI HTML formatting (section headers, ordered lists, cream tables)     |
| HappyFox staff notes         | Partial           | Plain text with CAPS headers, hyphens for bullets (HappyFox limitation) |
| Client emails                | Yes               | Professional tone, no AI attribution                                    |
| Internal reports (markdown)  | Minimal           | Use ICCI header/footer conventions                                      |
| Script output (terminal)     | No                | Use ICCI script color conventions (RED, ORANGE, REVERSED)               |

## Quick Reference

### Colors (CSS Custom Properties)

```css
--navy: #1b2b41;
--navy-light: #293d57;
--navy-dark: #0f1a28;
--gold: #c9a55a;
--gold-light: #d4b97a;
--gold-dark: #a6832f;
--cream: #f7f5f0;
--cream-dark: #e9e6e0;
```

### Semantic Colors

```css
--red: #dc2626; /* Critical */
--red-light: #fee2e2;
--green: #2d8a4e; /* Success */
--green-light: #d1fae5;
--amber: #b45309; /* Warning */
--amber-light: #fef3c7;
--blue: #2563eb; /* Info */
--blue-light: #dbeafe;
```

### Typography

| Element          | Font                   | Weight | Size               |
| ---------------- | ---------------------- | ------ | ------------------ |
| Headings (h1-h3) | Georgia, serif         | 700    | 22pt / 16pt / 13pt |
| Subheadings (h4) | Inter, sans-serif      | 600    | 11pt               |
| Body             | Inter, sans-serif      | 400    | 10pt               |
| Code/Mono        | Courier New, monospace | 400    | 8.5pt              |

### Logos

| File                            | Usage                          |
| ------------------------------- | ------------------------------ |
| `assets/icci-logo-gold.png`     | Dark backgrounds (cover pages) |
| `assets/icci-logo.png`          | Light backgrounds (headers)    |
| `assets/icci-logo-gold-b64.txt` | Base64 for PDF embedding       |
| `assets/icci-logo-b64.txt`      | Base64 for PDF embedding       |

## PDF Generation

### Tool: WeasyPrint ONLY

```bash
/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3 generate_report.py \
  --type security \
  --data findings.yaml \
  --output report.pdf
```

Never use: reportlab, wkhtmltopdf, Puppeteer, or Prince.

### Two Generation Modes

1. **CLI Pipeline:**

   ```bash
   python generate_report.py --type {security|network|finance|compliance|executive|generic} \
     --data data.yaml --output report.pdf
   ```

2. **Python API:**
   ```python
   from python.icci_report import ICCIReport
   report = ICCIReport(report_type="security")
   report.add_section(...)
   report.generate("output.pdf")
   ```

### Report Types

| Type         | Template                               | Use Case                          |
| ------------ | -------------------------------------- | --------------------------------- |
| `security`   | Findings, risk matrix, recommendations | Security audits, incident reports |
| `network`    | VLAN tables, device inventory          | Network assessments               |
| `finance`    | Invoices, line items                   | Billing documents                 |
| `compliance` | Checklists, gap analysis               | Compliance reviews                |
| `executive`  | KPIs, takeaways                        | Executive summaries               |
| `generic`    | Arbitrary sections                     | Everything else                   |

### Cover Page Design

- Full-bleed navy gradient: `linear-gradient(160deg, #0F1A28 0%, #1B2B41 40%, #293D57 100%)`
- Gold accent bar: `linear-gradient(90deg, #A6832F, #C9A55A, #D4B97A, #C9A55A)` — 6px height
- ICCI gold logo centered, 200px wide
- Classification badge at bottom: gold-dark border, centered, uppercase

### Footer

- Left: `ICCI, LLC — Secure. Governed. Operational.` (gold)
- Center: `CONFIDENTIAL — BUSINESS SENSITIVE` (gray)
- Right: `Page X of Y` (gray)
- Font: Inter 7pt
- First page (cover): no footer

## Wiring Branding into a New Skill

### Step 1: Add branding-config.md Reference

Create `references/branding-config.md` in the new skill:

```markdown
# Branding Configuration

## Source

- Branding repo: `~/Documents/GitHub/icci-report-branding/`
- Brand identity: `brand/identity.md`
- CSS tokens: `brand/tokens.css`
- Templates: `templates/`
- Logos: `assets/`

## Report Output

- Directory: `~/Documents/claude-code/{skill-name}/reports/`
- WeasyPrint: `/opt/homebrew/Cellar/weasyprint/68.1/libexec/bin/python3`
```

### Step 2: Add Branding Rule to Critical Rules

In the new skill's SKILL.md Critical Rules section:

```markdown
N. **ICCI BRANDING** — Read `~/Documents/GitHub/icci-report-branding/brand/identity.md` before generating any formatted output. Use WeasyPrint for PDFs. No AI-attribution signatures. Closing line: `ICCI, LLC — Secure. Governed. Operational.`
```

### Step 3: Reference in Output Workflows

Wherever the skill generates output, reference the branding:

```markdown
### Generating Reports

1. Read `~/Documents/GitHub/icci-report-branding/brand/identity.md` for current brand standards
2. Use the appropriate template from `templates/`
3. Generate PDF with WeasyPrint CLI or Python API
4. Save to `~/Documents/claude-code/{skill-name}/reports/`
```

## Signature Rules

**Never use:**

- "Generated by Claude Code"
- "via Claude Code"
- "via DI-Shepherd / Claude Code"
- Any AI-attribution signature

**When a closing line is needed:**

```
ICCI, LLC — Secure. Governed. Operational.
```

HappyFox attributes notes to staff automatically — no signature needed there.

## Brand Voice (Summary)

- Professional, understated, authoritative
- Technical depth without jargon overload
- Confident but never arrogant
- Data-driven — let the numbers tell the story
- Action-oriented — every finding maps to a recommendation
