# Claude reviewer prompt

Read-only review. Do not modify files.

In `<repo path>`, run `git diff <base>...HEAD`. That full diff is the code under review.

If `<PR_NUMBER>` is set, FIRST read the authoritative PR with:

```bash
gh pr view <PR_NUMBER> --json title,body,url
gh pr view <PR_NUMBER> --comments
```

If the PR body or relevant commit message references an issue (for example `#123`), also read that issue with `gh issue view <N>`. Treat explicit PR/issue acceptance or completion criteria as requirements. Quote the criteria relied on; do not rely on an orchestrator summary.

Review the full diff for concrete defects introduced by this change affecting:
- requirements / acceptance criteria
- correctness
- security
- data integrity
- compatibility
- material performance

Inspect surrounding code, callers, tests, and history as needed to validate suspected defects.

Do NOT report style/naming preferences, speculative improvements, refactoring without a concrete defect, generic maintainability concerns, purely mechanical formatter/linter/typechecker/compiler issues, missing tests without a concrete uncovered defect, or pre-existing defects not materially worsened/newly exposed by this diff.

For each finding assign confidence 0-100. Do not emit ordinary findings below 80. A plausible `CRITICAL` security/data-loss issue below 80 may be emitted only if its uncertainty is explicit in the evidence.

Return exactly:

1. verdict line: `approve` | `approve-with-nits` | `request-changes`
2. zero or more severity-ranked finding lines:
   `SEVERITY | CONFIDENCE | CATEGORY | path:line | one-sentence finding | concrete evidence/failure path`

Prefix requirement-gap categories with `REQ-`, e.g. `REQ-CORRECTNESS`.

If no substantive finding survives the confidence filter, return `NO_FINDINGS` after the verdict.
