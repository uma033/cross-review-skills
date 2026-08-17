---
name: cross-review
description: One-step dual-review workflow that combines a Codex primary review run with $cross-review:code-review-specialist standards, a Claude Code cross-check, and a final Codex adjudicated merged report. Use when the user asks for Codex+Claude comparison, finding selection, disagreement resolution, or one final merge-ready review report.
---

# Cross Review (Codex-orchestrated)

## Overview

Run Codex primary review and Claude secondary review against the same diff scope.
Produce three artifacts: Codex report, Claude report, and a Codex-adjudicated merged report.
Codex primary and merge adjudication phases are executed with a `$cross-review:code-review-specialist` quality bar.

## Preconditions

- Ensure `claude` command is installed and authenticated.
- Ensure `codex` command is installed and authenticated.
- Run commands from the target Git repository root.

The sibling `$cross-review:code-review-specialist` skill ships in the same plugin, so one
install covers both.

## Quick Start

Run one command for full pipeline:

```bash
SKILL_DIR="${CODEX_HOME:-$HOME/.codex}/plugins/cache/cross-review-skills/cross-review/local/skills/cross-review"
"$SKILL_DIR/scripts/run-merged-cross-check.sh" \
  --scope "PR-549" \
  --diff-range "origin/main...HEAD"
```

## Output Language

Reports are written in English by default. Set `REVIEW_LANG` to force another language;
the scripts pass it to both reviewers and to the merge phase, and section headings are
translated along with the prose.

```bash
REVIEW_LANG=Japanese "$SKILL_DIR/scripts/run-merged-cross-check.sh" --scope "PR-549"
```

## Workflow

1. Determine review scope.
- Prefer explicit `--diff-range` when reviewing PRs or release branches.
- Use default range for local branch checks when no PR context exists.

2. Start Codex primary review and Claude cross-check.
- Default (`run-merged-cross-check.sh`) runs both in parallel to reduce wall-clock time.
- In parallel mode, Claude runs independently without `--codex-report` (Codex report is not ready yet).
- Use `--sequential` when you explicitly want the old order (Codex first, then Claude with `--codex-report`).
- Use `$cross-review:code-review-specialist` equivalent workflow and enforce severity-first findings.

3. Run Codex merge adjudication.
- Use `$cross-review:code-review-specialist` quality bar to accept/reject/hold findings.
- Follow `references/merged-output-template.md`.

4. Adjudicate findings in Codex.
- Evaluate each Codex and Claude finding against the actual diff/code/tests.
- Mark each finding as `Accepted`, `Rejected`, or `Hold` in decision log.
- Merge duplicates and keep one canonical finding.
- Assign `Source` as `Codex`, `Claude`, or `Both`.

5. Finalize merged output.
- Keep only accepted findings in the final risk summary.
- Document rejected items with clear rejection reasons.
- Document hold items with required follow-up checks.

## Merge Rules

- Do not auto-accept Claude-only findings without evidence in diff/code/tests.
- Do not keep duplicate findings as separate entries.
- If certainty is low due to truncated diff, keep finding as `Hold` unless impact is critical.
- Ensure merged report stays actionable: severity, location, risk, fix direction.

## Fallback Rules

- If `claude` CLI is unavailable or unauthenticated, continue with Codex-only review and report that Claude cross-check was skipped.
- If command execution fails, keep partial artifacts and report the failing command/exit code.
- If Codex and Claude conflict and evidence is insufficient, mark as `Hold` and request targeted verification.

## Scripts

- `scripts/run-merged-cross-check.sh`
- One-step orchestration:
  - Default: Codex primary + Claude cross-check (parallel) -> Codex merged adjudication.
  - Optional: `--sequential` for Codex primary -> Claude cross-check -> Codex merged adjudication.
- Default outputs:
  - Final report (primary to read): `review/<scope>_review.md`
  - Intermediate artifacts: `review/.cross-check-artifacts/<scope>/<ts>/codex_primary.md`, `review/.cross-check-artifacts/<scope>/<ts>/claude_cross_check.md`
