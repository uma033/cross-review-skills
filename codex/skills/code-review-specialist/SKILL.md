---
name: code-review-specialist
description: Specialized code review for pull requests, commits, and diffs. Use when the user asks to review code, identify bugs or regressions, assess security/performance/reliability risks, find missing tests, or validate engineering principles such as YAGNI, DRY, and reuse-before-build. Use GitHub CLI (gh) for PR-oriented git operations whenever possible. Run review lanes in parallel by perspective (security, correctness/logic, reliability/operability, data/migration/compatibility, quality/tests) when tool capability allows. Detect representative anti-patterns per lane and produce a Markdown report file by default, with findings ordered by severity and concrete file/line references. Do not use for implementing new features unless review is explicitly requested.
---

# Code Review Specialist

## Overview

Perform focused code review that prioritizes risk discovery over solution design.
Run perspective-specific review lanes in parallel when possible, then consolidate.
By default, write a Markdown review report to a file and return its path.

## Review Contract

- Write all user-facing responses and report content in the review language: the value of
  the `REVIEW_LANG` environment variable when it is set (for example `REVIEW_LANG=Japanese`),
  otherwise the language the user is writing in. Translate report section headings to match.
- Start with an executive conclusion section before detailed analysis.
- State merge recommendation explicitly: `Recommended` / `Conditional` / `Not Recommended`.
- List blocking issues and merge conditions in short bullet points at the top.
- Start with findings; sort by severity: Critical, High, Medium, Low.
- Include exact file references for each finding (for example `src/app.ts:42`).
- Explain impact, trigger condition, and why it is a real risk.
- Distinguish confirmed issues from assumptions; label assumptions explicitly.
- Always check for missing tests and mention coverage gaps.
- Evaluate engineering principles: reuse-before-build, YAGNI, DRY, KISS, simplicity.
- Detect lane-specific anti-patterns via `references/lane-anti-patterns.md`.
- If no findings are discovered, state that explicitly and note residual risks.
- Create a report file unless the user explicitly asks for chat-only output.
- If report path is not provided, initialize one with `scripts/init-report.sh`.

## Workflow

1. Determine review scope.
- Prefer diff-based review. If scope is unclear, infer from modified files and commit messages.
- Use `scripts/changed-files.sh` when repository context is needed.
- Accept PR references (for example `#123` or PR URL) as scope labels.
- For PR review, collect PR metadata and diff first. For local review, focus on `origin/main..HEAD` and staged diff.
- For PR-oriented operations, prefer `gh` commands first. Fall back to plain `git` only when `gh` is unavailable.
- Follow `references/git-gh-workflow.md` for command patterns.

2. Initialize report file.
- Use `scripts/init-report.sh` with optional path and scope label.
- Keep lane notes in the report under lane-specific sections.

3. Build minimal context.
- Read changed code and immediate callers/callees as needed.
- Avoid broad codebase traversal unless the change impacts shared contracts.
- Run relevant tests when feasible and capture pass/fail status for the report.

4. Execute lane analysis in parallel when possible.
- Use lanes from `references/review-lanes.md`.
- Use best-practice checks from `references/coding-principles.md`.
- Run these lanes in parallel:
- `Security`
- `Correctness/Logic`
- `Reliability/Operability`
- `Data/Migration/Compatibility`
- `Quality/Tests`
- If parallel tools are not available, execute the same lanes sequentially.
- Follow `references/core-checklist.md`.
- Prioritize correctness and regressions first, then security/reliability/performance.
- Confirm whether tests prove changed behavior, not only happy-path execution.
- For each lane, record representative anti-pattern hits or explicit "none found".

5. Consolidate and write output.
- Use `references/output-template.md`.
- Write sections in this order: conclusion -> merge conditions -> key findings -> details.
- Merge lane findings, deduplicate overlaps, and keep strongest evidence.
- Sort consolidated findings by severity.
- Save final report to the chosen file path.
- Include risk assessment by dimension and a checklist.
- Include concrete next actions.
- Keep claims precise and evidence-backed.
- Suggest concrete fix direction only when it improves actionability.

## Scope Boundaries

- In scope: PR review, commit review, patch review, design-risk review for changed code.
- Out of scope: full rewrite proposals, greenfield implementation, style-only nitpicking without risk impact.

## References

- Use `references/core-checklist.md` for systematic risk checks.
- Use `references/coding-principles.md` for YAGNI/DRY/reuse checks.
- Use `references/git-gh-workflow.md` for PR metadata, diff, and checkout operations with `gh`.
- Use `references/lane-anti-patterns.md` for anti-pattern detection.
- Use `references/review-lanes.md` for lane-specific parallel review guidance.
- Use `references/output-template.md` for consistent findings format.
- Extend references with stack-specific checklists when recurring patterns appear.

## Iteration Guidance

- After each review task, record misses and false positives.
- Update checklist items before adding large instruction blocks.
- Keep `SKILL.md` concise; move detailed, stack-specific knowledge into `references/`.
