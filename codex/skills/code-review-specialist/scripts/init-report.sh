#!/usr/bin/env bash
set -euo pipefail

# Initialize a Markdown review report file and print its path.
# Usage:
#   init-report.sh
#   init-report.sh <output_path>
#   init-report.sh <output_path> <scope_label>
#   init-report.sh <output_path> <scope_label> <base_ref> <head_ref>

if [[ $# -gt 4 ]]; then
  echo "usage: $0 [output_path] [scope_label] [base_ref] [head_ref]" >&2
  exit 2
fi

timestamp="$(date -u +%Y%m%d-%H%M%S)"
scope_label="${2:-diff}"
base_ref="${3:-N/A}"
head_ref="${4:-N/A}"

scope_safe="$(printf '%s' "$scope_label" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
if [[ -z "$scope_safe" ]]; then
  scope_safe="diff"
fi
default_output_path="REVIEW_${scope_safe}_${timestamp}.md"
output_path="${1:-$default_output_path}"

output_dir="$(dirname "$output_path")"
mkdir -p "$output_dir"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat >"$output_path" <<EOF
# Code Review Report

- Scope: ${scope_label}
- Generated At (UTC): ${generated_at}
- Base Ref: ${base_ref}
- Head Ref: ${head_ref}

## Conclusion (TL;DR)
- Merge verdict: ⚠️ Conditional
- Rationale: <1-2 line summary>
- Blocking count: 0
- Findings count: Critical=0, High=0, Medium=0, Low=0

## Merge Conditions
### Required before merge
1. <must fix item>

### Can follow up after merge
1. <follow-up item>

## Key Findings Summary
| Severity | Title | Location | Action |
| --- | --- | --- | --- |
| Medium | <short title> | \`path/to/file:line\` | <one-line action> |

## Consolidated Findings
1. [Severity: <Critical|High|Medium|Low>] <title>
- Location: \`path/to/file:line\`
- Risk: <impact>
- Evidence: <why this is likely real>
- Suggested direction: <minimal fix direction>

## Test Results
- Command: <command>
- Result: <pass|fail|not-run>
- Notes: <failure summary or reason not run>

## Lane Results

### Security
- Pending

### Correctness/Logic
- Pending

### Reliability/Operability
- Pending

### Data/Migration/Compatibility
- Pending

### Quality/Tests
- Pending

## Engineering Principles
- Reuse before build: Pending
- YAGNI: Pending
- DRY: Pending
- KISS/Simplicity: Pending

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
1. <question or assumption>
EOF

echo "$output_path"
