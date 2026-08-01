# Accessibility audit output

## Coverage ledger

For keyboard, screen reader, contrast, semantics, forms, dynamic content, and alternative content, state evidence as Observed / Measured / Static / None and status as Pass / Fail / Not verified.

Use `Conforming for tested scope`, `Violations found`, or `Incomplete evidence`. Never issue a full conformance pass when a required modality was not tested.

## Findings

For each material barrier include the WCAG criterion, evidence, affected users, exact behavior, and specific fix under the shared finding contract.

## Modality results

Report tested keyboard paths, screen-reader structure and announcements, measured contrast, semantic HTML, form behavior, and missing alternatives. Do not fabricate results for unavailable devices or assistive technologies.

## Remediation order

1. Access-blocking barriers
2. Broken but partially usable experiences
3. Missing inclusive interaction features
4. Remaining conformance gaps

State technical constraints that affect implementation, then end with `What I did not test`.
