---
name: cross-review
description: Use when reviewing a code change or pull request where missed substantive defects are costly and independent Claude + Codex scrutiny is desired before merge or release.
---

# Cross-Review (Claude + Codex)

**Announce at start:** "I'm using the cross-review skill to have Claude and Codex independently review this change, verify substantive findings, and aggregate the results."

Two reviewers inspect the SAME full change independently. The orchestrator deduplicates their findings, verifies each substantive candidate in a fresh narrow context, then decides whether the change has converged.

**Core rules:**
- Every invocation reviews the full `git diff <base>...HEAD`; never switch to delta-only re-review.
- Reviewer output is a candidate, not truth. **Verified finding wins; stricter reviewer or reviewer agreement does not.**
- Verifier-confirmed `CRITICAL` / `HIGH` / `MEDIUM` findings block convergence.
- `LOW` / `NIT` never trigger another review-fix cycle.
- An `uncertain` `CRITICAL` / `HIGH` / `MEDIUM` finding requires human judgment.

## Invocation and base resolution

Invocation: `/cross-review [<PR-number>] [--base <branch>]`, or natural language.

- PR number → review that PR.
- `--base` → highest-precedence base override.
- Intent asks to create/open a PR → run Phase 1 first.
- Otherwise → review current branch.

Base precedence: explicit `--base` > PR `baseRefName` > merge-base with `main`/`master` > `main`.

## Phase 0 — Preconditions

Require a git repo:

```bash
git rev-parse --is-inside-work-tree
```

Resolve the newest Codex companion and probe readiness:

```bash
COMPANION=$(ls -d ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs 2>/dev/null \
  | sort -V | tail -1)
CODEX_SETUP=$(node "$COMPANION" setup --json 2>/dev/null) || CODEX_SETUP=""
printf '%s\n' "$CODEX_SETUP"
```

Codex is ready only when the probe reports `ready: true`. Otherwise continue **Claude-only** and mark the final run degraded; do not abort and do not treat Codex absence as approval.

## Phase 1 — Optional PR creation

Only when the user asked to create/open a PR.

1. Reuse an existing branch PR when present:
   ```bash
   gh pr view --json number,url -q '.number' 2>/dev/null
   ```
2. Stop without auto-fixing if: current branch is base/default, tree is dirty, or no commits are ahead of base.
3. Run the repository's documented tests before creating the PR; stop on failure.
4. Push and create:
   ```bash
   git push -u origin "$(git branch --show-current)"
   gh pr create --base <base> --head "$(git branch --show-current)" \
     --title "<generated from commits>" --body "<generated from commits/diff>"
   ```
5. Keep the branch/worktree checked out and continue locally.

## Phase 2 — Resolve the review target

**PR mode, when the PR is not the current branch:** require a clean tree, record `ORIG_BRANCH`, `gh pr checkout <PR_NUMBER>`, and resolve base from `baseRefName`.

**Local mode:** stay on the current branch. Detect its PR when available:

```bash
gh pr view --json number -q .number 2>/dev/null
```

Both reviewers MUST inspect the same full target:

```bash
git diff <base>...HEAD
REVIEW_HEAD=$(git rev-parse HEAD)
```

If the diff is empty, report `nothing to review` and stop. Never substitute `gh pr diff` or a delta-only diff for either reviewer.

### Deterministic verification

Before LLM review, run non-destructive checks when reliable commands are discoverable from repository instructions, CI, or project manifests. Prefer documented commands over guesses. Typical checks: format-check, lint, typecheck/build, unit tests, relevant integration tests.

Record command + result. Never auto-fix. A failure attributable to this diff is blocking evidence; a proven pre-existing unaffected failure is a caveat; unresolved attribution requires human judgment. `unavailable` is not `pass`.

## Phase 3 — Independent reviews in parallel

Launch both in the same turn; do not let either see the other's output.

### Claude reviewer

Use a fresh read-only Claude `Agent` subagent (`subagent_type: "claude"`, `run_in_background: true`) with `references/claude-reviewer.md`, filling `<repo path>`, `<base>`, and optional `<PR_NUMBER>`.

Claude's role: authoritative PR/issue requirements + concrete defect review. It must emit severity, confidence, category, path:line, claim, and evidence/failure path. Ordinary findings below confidence 80 are excluded.

### Codex reviewer

If Codex is ready:

```bash
node "$COMPANION" review "--base <base> --background"
```

This is the normal native review path, not `adversarial-review`. Codex stays cold to Claude's findings and to orchestrator-paraphrased PR/issue context.

After completion, distinguish: findings / no findings / failed / incomplete / unavailable. If Codex stdout lacks a trustworthy final review, recover the matching tracked result only when unambiguous; otherwise mark it incomplete. **Failed or incomplete is never approval.**

## Phase 4 — Normalize and deduplicate

Wait for both reviews. Normalize substantive findings into candidates with source(s), severity, reviewer confidence if present, category, `path:line`, claim, evidence, and requirement-gap flag.

Admission:
- Claude confidence `>=80` → verify.
- Plausible lower-confidence `CRITICAL` security/data-loss → retain as uncertain candidate.
- Codex findings without numeric confidence → verify; do not invent confidence.
- `LOW` / `NIT` may be reported but are non-blocking.
- Exclude pure style/refactor/mechanical observations without a concrete defect.

Deduplicate by underlying failure, trigger, and affected behavior—not wording. Preserve both sources/evidence. Agreement raises priority only; it does not confirm the finding.

## Phase 5 — Verify substantive candidates

For each substantive candidate, launch a **fresh Claude `Agent` verifier for that candidate only** (`run_in_background: true`), using `references/finding-verifier.md`. Run independent verifier jobs in parallel when practical.

Verifier invariant:

> Validate exactly ONE supplied finding. Never search for or report unrelated defects.

Adjudication:
- `confirmed` + introduced/materially exposed by this diff → confirmed for this change.
- `rejected`, or proven pre-existing and unaffected → rejected.
- insufficient/ambiguous evidence, unavailable runtime condition, or malformed verifier result after one retry → uncertain.

Never upgrade a rejected/uncertain finding because both reviewers raised it.

## Phase 6 — Convergence and report

Apply final states in this order:

1. **`DEGRADED_REVIEW`** — intended reviewer pipeline failed/incomplete/unavailable. Claude-only due to Codex unavailability is explicitly degraded.
2. **`NOT_CONVERGED`** — any confirmed `CRITICAL` / `HIGH` / `MEDIUM`, confirmed blocking requirement gap, or deterministic failure attributed to this diff.
3. **`NEEDS-HUMAN-JUDGMENT`** — no confirmed blocker, but any substantive `CRITICAL` / `HIGH` / `MEDIUM` remains uncertain, including unresolved deterministic-failure attribution.
4. **`CONVERGED`** — no confirmed or uncertain `MEDIUM+` issue remains, no blocking requirement gap remains, required deterministic checks pass or failures are proven pre-existing/unaffected, and the intended review/verification pipeline completed successfully.

`LOW` / `NIT` do not prevent `CONVERGED`. A later full review may legitimately reopen a converged change if it discovers a newly verifier-confirmed `MEDIUM+` defect.

Produce one chat report; do not post to the PR or write a report file:

```text
## Overall verdict
<CONVERGED | NOT_CONVERGED | NEEDS-HUMAN-JUDGMENT | DEGRADED_REVIEW>

## Review target
- Base / Head / PR / full-review mode

## Requirements check
- met / unmet / uncertain; confirmed REQ gaps

## Deterministic verification
- command: pass / fail / unavailable

## Confirmed blocking findings
- SEVERITY | path:line | finding | verifier evidence

## Uncertain substantive findings
- SEVERITY | path:line | finding | uncertainty

## Non-blocking findings
- LOW / NIT only

## Rejected candidates
- meaningful false positives discarded

## Reviewer coverage
- Claude / Codex health; verifier confirmed/rejected/uncertain counts
```

If `NOT_CONVERGED`, name the confirmed blockers to fix. If `NEEDS-HUMAN-JUDGMENT`, name the exact unresolved claims/evidence needed. If `CONVERGED`, state that another review-fix cycle is not required on current evidence.

## Invariants

- Same full `<base>...HEAD` diff for both reviewers, every invocation.
- Claude and Codex finish independently before aggregation.
- Claude reads authoritative PR/issue requirements itself when available.
- Reviewer vote/strictness never overrides verifier evidence.
- Verifier handles one candidate only and never becomes a third reviewer.
- `MEDIUM+` blocks only when confirmed; uncertain `MEDIUM+` requires human judgment.
- `LOW` / `NIT` never trigger another review-fix cycle.
- Failed/incomplete reviewer or verifier output is never approval.
- Review is read-only: no code edits and no PR comments.

## Optional adversarial challenge

Do not include this in the normal review-fix loop. For unusually high-risk architecture/security changes, or when the user explicitly asks to challenge the implementation approach, run one separate Codex `adversarial-review` **after** normal convergence. Any concrete defect it raises must enter the same Phase 5 verifier before reopening the change.
