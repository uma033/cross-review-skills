# Merged Review Output Template

Use this template for the final merged review after Codex adjudicates both reports.
Translate the section headings into the review language when one is requested.

## Conclusion
- Merge verdict: `Recommended | Conditional | Not Recommended`
- Rationale: 1-3 lines
- Accepted count: `Critical=x, High=y, Medium=z, Low=w`
- Rejected count: `n`
- Held count: `m`

## How to read this report
1. Start with `Fix first (by priority)`
2. Then check the evidence in `Accepted findings (detail)`
3. Finally review every decision in `Decision Log`

## Merge rules
1. Accept only findings that can be verified against the code
2. Consolidate duplicate findings
3. Hold or reject findings with insufficient evidence
4. State the reason for every rejection

## Fix first (by priority)
| Priority | ID | Severity | Fix | Primary evidence |
| --- | --- | --- | --- | --- |
| P0 | M-001 | High | <what to fix first> | `path:line` |

## Accepted findings (detail)
1. `[Severity: Critical|High|Medium|Low] <title>`
- Source: `Codex|Claude|Both`
- Location: `path/to/file:line`
- Risk: what breaks
- Evidence: the diff, code, or test that proves it
- Suggested minimal fix: smallest fix that resolves it

## Decision Log
| ID | Source | Decision | Severity | Location | Title | Rationale |
| --- | --- | --- | --- | --- | --- | --- |
| M-001 | Codex/Claude/Both | Accepted/Rejected/Hold | High | `path:line` | <title> | <why> |

## Rejected findings
1. `<title>`
- Source: `Codex|Claude`
- Reason for rejection: factually wrong, not reproducible, negligible impact, etc.

## Held findings
1. `<title>`
- Source: `Codex|Claude`
- Missing information: what is not known
- Follow-up needed: which check would resolve it

## Test considerations
- Tests that need to be added
- Gaps in existing tests

## Source Reports
```text
<codex-report-path>
<claude-report-path>
```
