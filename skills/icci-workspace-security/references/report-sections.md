# Executive Report Structure

## Target Audience
Business owners and executive leadership. Non-technical. Need to understand the risk and approve action (MFA deployment, security spend).

## Report Sections

### Cover Page
- ICCI logo (gold version on navy background)
- Title: "Security Posture Assessment"
- Subtitle: "Credential Attack Analysis & MFA Implementation Brief"
- Prepared for: {Client Name} Executive Leadership
- Prepared by: ICCI LLC -- Managed IT Services
- Assessment Period: {start} -- {end}
- Report Date: {date}
- Classification: CONFIDENTIAL -- BUSINESS SENSITIVE

### Section 1: Executive Summary
- Opening paragraph: what we did and why
- Alert box: confirmed incident (if any) -- red background, bold
- Stat grid (4 cards): Confirmed Compromises, External Attack Events, % Without MFA, Attacks Blocked by MFA
- Key Findings: numbered list, 3-5 items, bold lead-ins
- "The Bottom Line" callout: navy background, gold heading, 2-3 sentence conclusion

### Section 2: The Incident (if compromise confirmed)
- Attack Timeline: visual timeline with color-coded dots (gold=normal, red=critical, green=success)
- Attacker Infrastructure table: IP, Owner, Location, ASN, Activity
- Forensic Analysis Summary: two-column layout (OAuth findings | Email & Drive findings)
- Assessment box: what the attacker did/didn't do, what this means

### Section 3: Ongoing Attack Activity
- Attack Events by Domain: stat grid
- Most Targeted Accounts: table with Account, Domain, Attack Events, Attack Sources, MFA Status (with colored badges)
- Front Desk alert box (if applicable): red, calling out shared account risk
- Global Attack Infrastructure: two-column table of providers by country

### Section 4: Industry Context
- Opening: connect client's situation to industry trends
- Industry Statistics alert box: % of hotels/businesses attacked, average breach cost
- Breach comparison cards (2-3): MGM, Caesars, Choice Hotels, or sector-appropriate examples
  - Each card: How it started, What happened, Financial impact (red text)
- "The Pattern Is Clear" callout: navy background, connecting industry to client

### Section 5: MFA Coverage Gap
- Coverage table by domain: Total Users, With MFA, Without MFA, Coverage %
- Proof box (green): where MFA stopped the attacker in their environment
- Front Desk Account Problem: bullet list of why shared accounts are high risk
- Operational Reality box: how to deploy MFA on shared workstations

### Section 6: Additional Findings
- Third-party OAuth grants needing review
- User activity patterns (explain away false positives)
- Other security observations

### Section 7: Recommendations
- Immediate Priority (2 weeks): numbered, alert box for #1 (MFA)
- Short-Term (30 days): numbered items
- Ongoing: numbered items

### Section 8: Conclusion
- 2-3 paragraphs summarizing the case
- Blockquote: powerful closing statement connecting industry breaches to client
- ICCI Recommendation callout: navy box, gold heading
- ICCI logo footer + contact info

## Design System

### Colors

Aligned with ICCI website theme (`references/branding-config.md`) and icci-gam-pfm reports.

| Name | Hex | Usage |
|---|---|---|
| Navy | #1B2B41 | Primary text, headers, backgrounds |
| Navy Light | #293D57 | Secondary backgrounds |
| Navy Dark | #0F1A28 | Cover page background, header gradients |
| Gold | #C9A55A | Accents, headings, borders |
| Gold Light | #D4B97A | Hover states, meta text |
| Gold Dark | #A6832F | Active states |
| Cream | #F7F5F0 | Card backgrounds, alternating rows |
| Cream Dark | #E9E6E0 | Borders |
| Red | #DC2626 | Critical alerts, attack counts |
| Green | #2D8A4E | Success indicators, MFA present |
| Amber | #B45309 | Warnings, partial coverage |
| Blue | #2563EB | Info boxes |

### Typography
- **Headings**: Georgia, 'Times New Roman', serif
- **Body**: 'Inter', system-ui, sans-serif (load from Google Fonts)
- **Section numbers**: 32px circle, navy bg, gold text

### Components
- **Alert boxes**: 4 variants (critical/warning/success/info), left border + background
- **Stat cards**: 4-column grid, large number + small label
- **Timeline**: vertical line with colored dots
- **Tables**: navy header, alternating cream rows, highlight-row for critical
- **Callout boxes**: navy bg, gold top border, cream text
- **Badges**: inline colored chips (red/green/amber)
- **Breach cards**: cream bg, red left border

### Print Optimization
- `@page { size: letter; margin: 0.75in; }` (matches icci-gam-pfm reports)
- Cover page uses named `@page cover` with 0 margin
- Page footer: "ICCI, LLC — Secure. Governed. Operational." (gold, Georgia 8pt) + page numbers
- `break-before: page` for major sections (Executive Summary, Industry Context, Recommendations, Conclusion)
- `break-inside: avoid` for tables, alert boxes, callout boxes, breach cards
- Remove unnecessary page breaks between flowing sections to avoid blank space
- See `references/report-generation.md` for the full CSS implementation
