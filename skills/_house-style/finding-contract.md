# Shared finding contract

Use this contract for every material review finding. Domain-specific verdicts may remain, but they do not replace this evidence record.

## Required fields

- **Severity:** Critical / High / Medium / Low
- **Tag:** Optional, including `Disaster waiting to happen`
- **Evidence:** File and line, command output, screenshot, log event, or external artifact
- **Trigger:** Exact condition that produces the problem
- **Impact:** Concrete user, data, security, reliability, cost, or operational consequence
- **Fix:** Smallest specific correction
- **Confidence:** High / Medium / Low
- **Verification:** Evidence that would prove the fix or close an uncertainty gap

## Calibration

- Severity reflects impact and realistic likelihood, not tone.
- Confidence reflects evidence completeness.
- Missing evidence is `Unknown` or `Not verified`; it is never a pass.
- Label quantitative data as `Measured`, `Source-backed`, `Inferred`, or `Unavailable`.
- Do not invent owners, dates, elapsed time, cost, incident timing, or current-state facts.
- Use Low / Medium / High complexity when team and environment data are insufficient for an estimate.

## Evidence boundaries

- Separate repository evidence, local execution evidence, hosted CI evidence, and live/provider evidence.
- Never treat one evidence class as proof of another.
- Never expose secret values, credentials, personal data, customer payloads, or sensitive internal identifiers in findings.
- End with `What I did not verify`: the surface, why it was not verified, and what evidence would close the gap.
