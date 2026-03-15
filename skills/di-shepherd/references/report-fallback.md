# Report Fallback Format

Use this ONLY if the `icci-report-branding` repo at `~/Documents/GitHub/icci-report-branding/` is unavailable (not cloned, not accessible).

## Fallback PDF Generation

Generate a clean HTML document and render with WeasyPrint using these inline styles:

```css
@page {
  size: letter;
  margin: 0.75in 0.75in 1in 0.75in;
  @bottom-left { content: "ICCI, LLC — Secure. Governed. Operational."; font-size: 7pt; color: #C9A55A; }
  @bottom-center { content: "CONFIDENTIAL — BUSINESS SENSITIVE"; font-size: 7pt; color: #999; }
  @bottom-right { content: "Page " counter(page) " of " counter(pages); font-size: 7pt; color: #999; }
}

body { font-family: Inter, system-ui, sans-serif; font-size: 10pt; color: #1a1a1a; }
h1, h2, h3 { font-family: Georgia, serif; color: #1B2B41; }
h1 { font-size: 22pt; }
h2 { font-size: 16pt; border-bottom: 2px solid #C9A55A; padding-bottom: 4pt; }
h3 { font-size: 13pt; }
table { width: 100%; border-collapse: collapse; }
th { background: #1B2B41; color: white; padding: 6pt 8pt; text-align: left; }
td { padding: 6pt 8pt; border-bottom: 1px solid #E2E8F0; }
tr:nth-child(even) { background: #F7F5F0; }
```

## Fallback Report Structure

1. Title page: Report title, client name, date, "CONFIDENTIAL — BUSINESS SENSITIVE"
2. Executive summary paragraph
3. Content sections with tables and lists
4. Recommendations
5. Closing: "ICCI, LLC | Veteran-owned MSP | 30+ years | 734.995.5570 | info@icci.com"

## When to Use This

- The branding repo has not been cloned locally
- `git pull` on the branding repo fails
- The `ICCIReport` class cannot be imported

Always inform the user: "Using fallback report format — the icci-report-branding repo was not available. Clone it with: `gh repo clone icci/icci-report-branding ~/Documents/GitHub/icci-report-branding`"
