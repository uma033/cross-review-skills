# Output Template

Default output target: Markdown file.
Use conclusion-first structure so readers can decide quickly.
Translate the section headings below into the review language when one is requested.

```markdown
# Code Review Report

- Scope: <pr-123|diff label>
- Generated At (UTC): <YYYY-MM-DDTHH:MM:SSZ>
- Base Ref: <base ref or N/A>
- Head Ref: <head ref or N/A>

## Conclusion (TL;DR)
- Merge verdict: <✅ Recommended | ⚠️ Conditional | ❌ Not Recommended>
- Rationale: <1-2 line summary>
- Blocking count: <number>
- Findings count: Critical=<n>, High=<n>, Medium=<n>, Low=<n>

## Merge Conditions
### Required before merge
1. <must fix item>
2. <must fix item>

### Can follow up after merge
1. <follow-up item>
2. <follow-up item>

## Key Findings Summary
| Severity | Title | Location | Action |
| --- | --- | --- | --- |
| High | <short title> | `path/to/file:line` | <one-line action> |
| Medium | <short title> | `path/to/file:line` | <one-line action> |

## Consolidated Findings
1. [Severity: High] Short title
- Location: `path/to/file.ext:123`
- Risk: Concrete impact in production or maintenance.
- Evidence: Why this issue is likely real.
- Suggested direction: Minimal fix strategy.

2. [Severity: Medium] Short title
- Location: `path/to/file.ext:88`
- Risk: ...
- Evidence: ...
- Suggested direction: ...

## Test Results
- Command: `<command>`
- Result: `<pass|fail|not-run>`
- Notes: <failure log summary or reason not run>

## Lane Results

### Security
- Key observations...
- Anti-patterns: <hit list or "none found">

### Correctness/Logic
- Key observations...
- Anti-patterns: <hit list or "none found">

### Reliability/Operability
- Key observations...
- Anti-patterns: <hit list or "none found">

### Data/Migration/Compatibility
- Key observations...
- Anti-patterns: <hit list or "none found">

### Quality/Tests
- Key observations...
- Anti-patterns: <hit list or "none found">

## Engineering Principles
- Reuse before build: <pass/fail + short note>
- YAGNI: <pass/fail + short note>
- DRY: <pass/fail + short note>
- KISS/Simplicity: <pass/fail + short note>

## Risk Assessment
| Dimension | Score | Notes |
| --- | --- | --- |
| Correctness/Logic |  |  |
| Security |  |  |
| Reliability/Operability |  |  |
| Data/Migration/Compatibility |  |  |
| Quality/Tests |  |  |

## Checklist
- [ ] Coding principles followed (Reuse/YAGNI/DRY/KISS)
- [ ] No unresolved security concerns
- [ ] No performance/reliability regressions
- [ ] Tests cover changed behavior and failure paths
- [ ] Docs/help/compatibility impacts are addressed

## Open Questions / Assumptions
1. Assumption or question that can change conclusions.
```

Severity rubric:

- Critical: Security breach, data loss, or outage risk with high confidence.
- High: Behavior regression or correctness bug likely to impact users.
- Medium: Moderate risk or latent bug with plausible impact.
- Low: Minor issue, maintainability concern, or non-blocking observation.
