# Claude Code Cross-Check Output Template

Use this structure for consistent cross-check reports.
Translate the section headings into the review language when one is requested.

## Conclusion
- Merge verdict: `Recommended | Conditional | Not Recommended`
- Rationale: 1-3 lines
- Key risk count: `Critical=x, High=y, Medium=z, Low=w`

## Comparison with the Codex review
### Newly detected
- Important findings the Codex review did not cover

### Confirmed
- Codex findings this review also considers valid

### Disagreements
- Findings where the two verdicts differ
- Name the diff location that supports this verdict

## Findings Index
| ID | Severity | Location | Title | DecisionHint |
| --- | --- | --- | --- | --- |
| CL-001 | High | `path:line` | <title> | Adopt/Discuss/Reject |

## Findings
1. `[ID: CL-001][Severity: Critical|High|Medium|Low] <title>`
- Location: `path/to/file:line`
- Risk: what breaks
- Evidence: the diff that proves it
- Suggested minimal fix: smallest fix that resolves it

## Test considerations
- Missing test cases
- Additional tests worth prioritizing

## Uncertainty and follow-up
- Insufficient diff, truncation, external dependencies, etc.
- Additional information needed
