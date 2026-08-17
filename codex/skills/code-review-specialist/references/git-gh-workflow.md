# Git And GH Workflow

Prefer `gh` for PR-oriented operations. Use `git` for local branch operations.

## PR Context Collection (Prefer GH)

- `gh pr view <pr-url-or-number> --json number,title,author,labels,headRefName,baseRefName,headRefOid,body`
- `gh pr diff <pr-url-or-number>`
- `gh pr checkout <pr-url-or-number>` when reproduction or local test execution is required.

## PR Review Commenting (Optional)

- Get head commit SHA:
- `gh api repos/<owner>/<repo>/pulls/<pr-number> --jq .head.sha`
- Post inline comment:
- `gh api repos/<owner>/<repo>/pulls/<pr-number>/comments --method POST --field body="<comment>" --field commit_id="<sha>" --field path="path/to/file" --field line=<line> --field side="RIGHT"`

## Local Diff Collection (Git)

- `git branch --show-current`
- `git status -sb`
- `git log --oneline origin/main..HEAD`
- `git diff origin/main..HEAD`
- `git diff --staged`

## Fallback Policy

- If `gh` is available and target is a PR, use `gh` first.
- If `gh` is unavailable, document fallback and use `git` + remote refs.
- Keep review scope deterministic; avoid mixing unstaged edits unless requested.

