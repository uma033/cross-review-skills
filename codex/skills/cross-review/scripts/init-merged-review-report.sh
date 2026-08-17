#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Initialize a merged review report skeleton.

Usage:
  init-merged-review-report.sh --scope <label> --diff-range <range> --codex-report <path> --claude-report <path> [--output <path>]
USAGE
}

scope=""
diff_range=""
codex_report=""
claude_report=""
output_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      scope="$2"; shift 2 ;;
    --diff-range)
      diff_range="$2"; shift 2 ;;
    --codex-report)
      codex_report="$2"; shift 2 ;;
    --claude-report)
      claude_report="$2"; shift 2 ;;
    --output)
      output_path="$2"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

if [[ -z "$scope" || -z "$diff_range" || -z "$codex_report" || -z "$claude_report" ]]; then
  echo "required options are missing" >&2
  usage >&2
  exit 2
fi

if [[ -z "$output_path" ]]; then
  timestamp="$(date -u +%Y%m%d-%H%M%S)"
  scope_safe="$(printf '%s' "$scope" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  if [[ -z "$scope_safe" ]]; then
    scope_safe="diff"
  fi
  output_path="review/MERGED_REVIEW_${scope_safe}_${timestamp}.md"
fi

mkdir -p "$(dirname "$output_path")"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat >"$output_path" <<REPORT
# Merged Review Report (Codex + Claude)

- Scope: ${scope}
- Diff Range: ${diff_range}
- Generated At (UTC): ${generated_at}
- Codex Report: ${codex_report}
- Claude Report: ${claude_report}

## Conclusion
- Merge verdict: \`Recommended | Conditional | Not Recommended\`
- Rationale: <1-3 lines>
- Accepted count: \`Critical=0, High=0, Medium=0, Low=0\`
- Rejected count: \`0\`
- Held count: \`0\`

## How to read this report
1. Start with \`Fix first (by priority)\`
2. Then check the evidence in \`Accepted findings (detail)\`
3. Finally review every decision in \`Decision Log\`

## Merge rules
1. Accept only findings that can be verified against the diff, code, or tests.
2. Consolidate duplicate findings and keep the highest severity.
3. Classify findings with insufficient evidence as Hold or Rejected.
4. Always state the reason for a rejection.

## Fix first (by priority)
| Priority | ID | Severity | Fix | Primary evidence |
| --- | --- | --- | --- | --- |
| P0 | M-001 | High | <what to fix first> | \`path:line\` |

## Accepted findings (detail)
1. [Severity: <Critical|High|Medium|Low>] <title>
- Source: \`Codex|Claude|Both\`
- Location: \`path/to/file:line\`
- Risk: <impact>
- Evidence: <diff/code/test evidence>
- Fix direction: <minimal fix>

## Decision Log
| ID | Source | Decision | Severity | Location | Title | Rationale |
| --- | --- | --- | --- | --- | --- | --- |
| M-001 | Codex/Claude/Both | Accepted/Rejected/Hold | High | \`path:line\` | <title> | <why> |

## Rejected findings
1. <title>
- Source: \`Codex|Claude\`
- Reason for rejection: <why rejected>

## Held findings
1. <title>
- Source: \`Codex|Claude\`
- Missing information: <what is missing>
- How to verify: <how to verify>

## Test considerations
- Tests that need to be added
- Priority

## Source Reports
\`\`\`text
${codex_report}
${claude_report}
\`\`\`
REPORT

echo "$output_path"
