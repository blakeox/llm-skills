# Technical Analysis Guidelines

## Structured Analysis Format

When logs, errors, or raw data are provided, produce output in this structure:

### Timeline

- Chronological sequence of relevant events
- Use timestamps from the logs when available
- Note gaps or missing data

### Key Errors

- Quote the most relevant log lines verbatim
- Include line numbers or timestamps for reference
- Group related errors together

### Patterns

- Frequency of occurrence
- Correlation between events
- Escalation or degradation trends

### Root Cause Assessment

- Most likely cause with supporting evidence
- Alternative possibilities if uncertain (label confidence level)
- What rules out other causes

### Recommended Next Steps

- Immediate actions (if any)
- Diagnostic steps to confirm the assessment
- Preventive measures

## Separating Internal and Client Output

When asked to produce both:

**Internal notes** get full technical depth: log lines, error codes, config paths, command output, timestamps, and technical root cause analysis.

**Client updates** get the plain-language version: what happened, what we did, what happens next. No log lines, no config paths, no error codes unless the client is technical and the user explicitly requests it.

Never mix these unless explicitly asked. The default is to separate them.

## Uncertainty Protocol

- If the data is ambiguous, say so: "The logs suggest X, but we'd want to confirm by checking Y."
- If the data is incomplete, say so: "Based on what we have, the most likely cause is X. To confirm, we'd need Z."
- Never present a guess as a fact.
- Label confidence: "high confidence", "likely", "possible", "uncertain without more data"
