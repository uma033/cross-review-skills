#!/usr/bin/env bash
set -euo pipefail

# Print changed files between two refs.
# Usage:
#   changed-files.sh                # diff against merge-base(default_base, HEAD)
#   changed-files.sh <base_ref>     # diff against merge-base(base_ref, HEAD)
#   changed-files.sh <base> <head>  # direct diff range

if ! command -v git >/dev/null 2>&1; then
  echo "git is required" >&2
  exit 1
fi

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

if [[ $# -eq 0 ]]; then
  base_ref="$(default_base_ref)"
  head_ref="HEAD"
elif [[ $# -eq 1 ]]; then
  base_ref="$1"
  head_ref="HEAD"
elif [[ $# -eq 2 ]]; then
  base_ref="$1"
  head_ref="$2"
else
  echo "usage: $0 [base_ref] [head_ref]" >&2
  exit 2
fi

if [[ "$head_ref" == "HEAD" ]]; then
  merge_base="$(git merge-base "$base_ref" HEAD)"
  git diff --name-only "$merge_base" HEAD | sed '/^$/d'
else
  git diff --name-only "$base_ref" "$head_ref" | sed '/^$/d'
fi
