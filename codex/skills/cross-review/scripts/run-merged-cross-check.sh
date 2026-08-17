#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Run one-step merged review: Codex primary review + Claude cross-check + Codex adjudicated merge.

Usage:
  run-merged-cross-check.sh [options]

Options:
  --scope <label>              Report scope label (default: derived from diff range)
  --diff-range <range>         Git diff range (default: main...HEAD or master...HEAD)
  --codex-report <path>        Codex primary review report path (optional; default is artifact dir)
  --claude-report <path>       Claude cross-check report path (optional; default is artifact dir)
  --merged-output <path>       Final merged report path (default: review/<scope>_review.md)
  --output <path>              Alias of --merged-output
  --codex-model <model>        Codex model override (optional)
  --claude-model <model>       Claude model alias/name (default: sonnet)
  --max-diff-lines <n>         Max diff lines for Claude prompt (default: 2500)
  --extra-claude-prompt <path> Extra prompt file for Claude phase (optional)
  --sequential                 Run Codex primary first, then Claude with --codex-report
  --skip-codex-primary         Skip Codex primary generation and reuse --codex-report
  -h, --help                   Show help

Example:
  run-merged-cross-check.sh \
    --scope "PR-549" \
    --diff-range "origin/main...HEAD"
EOF
}

default_base_ref() {
  if git rev-parse --verify --quiet main >/dev/null; then
    echo "main"
    return
  fi
  if git rev-parse --verify --quiet master >/dev/null; then
    echo "master"
    return
  fi
  echo "HEAD~1"
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "required command not found: $cmd" >&2
    exit 1
  fi
}

scope=""
diff_range=""
codex_report=""
claude_report=""
merged_output=""
codex_model=""
claude_model="sonnet"
max_diff_lines="2500"
extra_claude_prompt=""
skip_codex_primary="false"
sequential="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)
      [[ $# -ge 2 ]] || { echo "missing value for --scope" >&2; exit 2; }
      scope="$2"
      shift 2
      ;;
    --diff-range)
      [[ $# -ge 2 ]] || { echo "missing value for --diff-range" >&2; exit 2; }
      diff_range="$2"
      shift 2
      ;;
    --codex-report)
      [[ $# -ge 2 ]] || { echo "missing value for --codex-report" >&2; exit 2; }
      codex_report="$2"
      shift 2
      ;;
    --claude-report)
      [[ $# -ge 2 ]] || { echo "missing value for --claude-report" >&2; exit 2; }
      claude_report="$2"
      shift 2
      ;;
    --merged-output|--output)
      [[ $# -ge 2 ]] || { echo "missing value for --merged-output" >&2; exit 2; }
      merged_output="$2"
      shift 2
      ;;
    --codex-model)
      [[ $# -ge 2 ]] || { echo "missing value for --codex-model" >&2; exit 2; }
      codex_model="$2"
      shift 2
      ;;
    --claude-model)
      [[ $# -ge 2 ]] || { echo "missing value for --claude-model" >&2; exit 2; }
      claude_model="$2"
      shift 2
      ;;
    --max-diff-lines)
      [[ $# -ge 2 ]] || { echo "missing value for --max-diff-lines" >&2; exit 2; }
      max_diff_lines="$2"
      shift 2
      ;;
    --extra-claude-prompt)
      [[ $# -ge 2 ]] || { echo "missing value for --extra-claude-prompt" >&2; exit 2; }
      extra_claude_prompt="$2"
      shift 2
      ;;
    --skip-codex-primary)
      skip_codex_primary="true"
      shift
      ;;
    --sequential)
      sequential="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_command git
require_command codex
require_command claude

if [[ -n "$extra_claude_prompt" && ! -f "$extra_claude_prompt" ]]; then
  echo "extra claude prompt file not found: $extra_claude_prompt" >&2
  exit 2
fi

if [[ ! "$max_diff_lines" =~ ^[0-9]+$ ]] || (( max_diff_lines <= 0 )); then
  echo "--max-diff-lines must be a positive integer" >&2
  exit 2
fi

if [[ -z "$diff_range" ]]; then
  base_ref="$(default_base_ref)"
  if [[ "$base_ref" == "HEAD~1" ]]; then
    diff_range="HEAD~1..HEAD"
  else
    diff_range="${base_ref}...HEAD"
  fi
fi

if [[ -z "$scope" ]]; then
  scope="$diff_range"
fi

scope_safe="$(printf '%s' "$scope" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
if [[ -z "$scope_safe" ]]; then
  scope_safe="diff"
fi
timestamp="$(date -u +%Y%m%d-%H%M%S)"

if [[ -z "$merged_output" ]]; then
  merged_output="review/${scope_safe}_review.md"
fi

artifact_dir=""
if [[ -z "$codex_report" || -z "$claude_report" ]]; then
  artifact_dir="review/.cross-check-artifacts/${scope_safe}/${timestamp}"
fi
if [[ -z "$codex_report" ]]; then
  codex_report="${artifact_dir}/codex_primary.md"
fi
if [[ -z "$claude_report" ]]; then
  claude_report="${artifact_dir}/claude_cross_check.md"
fi

mkdir -p "$(dirname "$codex_report")" "$(dirname "$claude_report")" "$(dirname "$merged_output")"

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
run_claude_script="$skill_dir/scripts/run-claude-cross-check.sh"

if [[ ! -x "$run_claude_script" ]]; then
  echo "missing executable script: $run_claude_script" >&2
  exit 1
fi

# Review language is opt-in: REVIEW_LANG=Japanese forces Japanese output.
# When unset, each reviewer answers in whatever language the prompt is in.
lang_line=""
if [[ -n "${REVIEW_LANG:-}" ]]; then
  lang_line="Write all user-facing content in ${REVIEW_LANG}, including section headings."
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
codex_primary_prompt="$tmp_dir/codex_primary_prompt.txt"
codex_merge_prompt="$tmp_dir/codex_merge_prompt.txt"

if [[ "$skip_codex_primary" != "true" ]]; then
  cat >"$codex_primary_prompt" <<EOF
Use \$cross-review:code-review-specialist and run a strict primary code review.
${lang_line}

Review scope:
- Scope label: ${scope}
- Diff range: ${diff_range}

Requirements:
1. Follow the \$cross-review:code-review-specialist contract and lane analysis style.
2. Prioritize bugs/regressions/security/reliability/missing tests.
3. Use concrete file references (\`path:line\`) whenever possible.
4. Output only one complete Markdown report body.
5. Do not ask for confirmation; do not describe file-write steps.
EOF

  codex_primary_cmd=(codex -a never -s workspace-write)
  if [[ -n "$codex_model" ]]; then
    codex_primary_cmd+=(-m "$codex_model")
  fi
  codex_primary_cmd+=(exec -C "$(pwd)" -o "$codex_report" -)
fi

if [[ "$skip_codex_primary" == "true" ]]; then
  if [[ ! -f "$codex_report" ]]; then
    echo "--skip-codex-primary is set but codex report not found: $codex_report" >&2
    exit 2
  fi
fi

claude_cmd_with_codex=(
  "$run_claude_script"
  --scope "$scope"
  --diff-range "$diff_range"
  --codex-report "$codex_report"
  --output "$claude_report"
  --model "$claude_model"
  --max-diff-lines "$max_diff_lines"
)
claude_cmd_without_codex=(
  "$run_claude_script"
  --scope "$scope"
  --diff-range "$diff_range"
  --output "$claude_report"
  --model "$claude_model"
  --max-diff-lines "$max_diff_lines"
)
if [[ -n "$extra_claude_prompt" ]]; then
  claude_cmd_with_codex+=(--extra-prompt "$extra_claude_prompt")
  claude_cmd_without_codex+=(--extra-prompt "$extra_claude_prompt")
fi

# Default path: run Codex primary and Claude cross-check in parallel.
# In this mode Claude runs independently (without --codex-report) to avoid waiting.
if [[ "$skip_codex_primary" != "true" && "$sequential" != "true" ]]; then
  codex_status=0
  claude_status=0

  (
    "${codex_primary_cmd[@]}" <"$codex_primary_prompt" >/dev/null
  ) &
  codex_pid=$!

  (
    "${claude_cmd_without_codex[@]}" >/dev/null
  ) &
  claude_pid=$!

  if wait "$codex_pid"; then
    :
  else
    codex_status=$?
  fi
  if wait "$claude_pid"; then
    :
  else
    claude_status=$?
  fi

  if (( codex_status != 0 )); then
    echo "failed to run Codex primary review phase (parallel mode)" >&2
    exit 1
  fi
  if (( claude_status != 0 )); then
    echo "failed to run Claude cross-check phase (parallel mode)" >&2
    exit 1
  fi
else
  if [[ "$skip_codex_primary" != "true" ]]; then
    if ! "${codex_primary_cmd[@]}" <"$codex_primary_prompt" >/dev/null; then
      echo "failed to run Codex primary review phase" >&2
      exit 1
    fi
  fi

  if ! "${claude_cmd_with_codex[@]}" >/dev/null; then
    echo "failed to run Claude cross-check phase" >&2
    exit 1
  fi
fi

if [[ ! -s "$codex_report" ]]; then
  echo "codex primary report was not generated: $codex_report" >&2
  exit 1
fi
if [[ ! -s "$claude_report" ]]; then
  echo "claude cross-check report was not generated: $claude_report" >&2
  exit 1
fi

cat >"$codex_merge_prompt" <<EOF
Use \$cross-review:code-review-specialist quality bar to adjudicate and merge two review reports.
${lang_line}

Scope:
- Scope label: ${scope}
- Diff range: ${diff_range}

Input reports:
- Codex primary: ${codex_report}
- Claude cross-check: ${claude_report}

Task:
1. Read both reports and validate claims against the actual repository diff/code/tests as needed.
2. Merge duplicate findings and keep strongest evidence.
3. Decide each unique finding as Accepted, Rejected, or Hold.
4. Produce one final merged report in Markdown with these sections:
   - ## Conclusion
   - ## How to read this report
   - ## Merge rules
   - ## Fix first (by priority)
   - ## Accepted findings (detail)
   - ## Decision Log
   - ## Rejected findings
   - ## Held findings
   - ## Test considerations
   - ## Source Reports
5. Keep findings ordered by severity and include file references (\`path:line\`).
6. Output only the final Markdown report content.
EOF

codex_merge_cmd=(codex -a never -s workspace-write)
if [[ -n "$codex_model" ]]; then
  codex_merge_cmd+=(-m "$codex_model")
fi
codex_merge_cmd+=(exec -C "$(pwd)" -o "$merged_output" -)

if ! "${codex_merge_cmd[@]}" <"$codex_merge_prompt" >/dev/null; then
  echo "failed to run Codex merge adjudication phase" >&2
  exit 1
fi
if [[ ! -s "$merged_output" ]]; then
  echo "merged report was not generated: $merged_output" >&2
  exit 1
fi

echo "FINAL_REPORT=${merged_output}"
if [[ -n "$artifact_dir" ]]; then
  echo "ARTIFACTS_DIR=${artifact_dir}"
fi
echo "CODEX_REPORT=${codex_report}"
echo "CLAUDE_REPORT=${claude_report}"
echo "MERGED_REPORT=${merged_output}"
