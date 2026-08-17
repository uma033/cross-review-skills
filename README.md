# Cross Review Skills

Independent Claude + Codex code review of the same diff. The same workflow is packaged twice, once for each host, so you invoke `cross-review` from whichever CLI you are already in.

Each host has its own plugin, published through that host's own marketplace manifest, so Codex
only ever sees the Codex plugin and Claude Code only ever sees the Claude one. Both are named
`cross-review`.

| Host | Manifest read | Skills | Invoke |
| --- | --- | --- | --- |
| Codex | `.agents/plugins/marketplace.json` → `./codex` | `cross-review`, `code-review-specialist` | `$cross-review:cross-review` |
| Claude Code | `.claude-plugin/marketplace.json` → `./claude` | `cross-review` | `/cross-review:cross-review` |

`code-review-specialist` is the severity-first review standard the Codex workflow builds on; it
installs with the same plugin.

Differences beyond the orchestrator: the Codex version writes Markdown reports under `review/`; the Claude version reports in chat only and runs a per-finding verifier subagent before deciding `CONVERGED` / `NOT_CONVERGED` / `NEEDS-HUMAN-JUDGMENT` / `DEGRADED_REVIEW`.

## Requirements

- Git, Bash
- Codex CLI, installed and authenticated
- Claude Code CLI, installed and authenticated
- For the Claude Code plugin: the `openai-codex` plugin, which supplies the Codex companion the
  skill calls

The Codex workflow shells out to the `claude` CLI directly, so it needs both CLIs. The Claude
workflow reaches Codex through the `openai-codex` companion instead; when that companion is
missing or not ready, it falls back to a Claude-only review and reports the run as
`DEGRADED_REVIEW` rather than failing.

## Install: Codex

```bash
codex plugin marketplace add uma033/cross-review-skills
codex plugin add cross-review@cross-review-skills
```

Restart the Codex desktop app, or start a new thread in the CLI, to pick up the skills. If you
added the marketplace before a release, refresh its snapshot first:

```bash
codex plugin marketplace upgrade cross-review-skills
```

Invoke with `$cross-review:cross-review`, or ask for a Codex+Claude review in natural
language. The final report is written under `review/`, with the individual Codex and Claude
reports under `review/.cross-check-artifacts/`.

### Output language

Codex reports are in English by default. Export `REVIEW_LANG` to get another language; report
section headings are translated along with the prose.

```bash
export REVIEW_LANG=Japanese
```

The Claude workflow has no equivalent switch: it reports in chat and follows the language of
the conversation.

## Install: Claude Code

```bash
/plugin marketplace add uma033/cross-review-skills
/plugin install cross-review@cross-review-skills
```

Invoke with `/cross-review:cross-review [<PR-number>] [--base <branch>]`, or ask for a
cross-review in natural language. The bare `/cross-review` also works unless another command
already claims that name.

## Security notes

- Review the scripts before installation; skills can execute local commands.
- Both CLIs receive repository context. Do not review diffs containing plaintext secrets.
- In the Codex workflow, Claude Code is invoked without tools and receives a bounded diff as untrusted input.
- Neither workflow edits code, comments on PRs, merges, or deploys. Output is a Markdown report or a chat report.
- One exception to "reads only": when you explicitly ask the Claude workflow to open a PR, it pushes the current branch and runs `gh pr create` before reviewing. It never does this as part of a plain review.

## Repository layout

```text
.claude-plugin/marketplace.json   # catalog Claude Code reads: lists ./claude only
.agents/plugins/marketplace.json  # catalog Codex reads: lists ./codex only
claude/                           # Claude Code plugin root
├── .claude-plugin/plugin.json
└── skills/cross-review/
codex/                            # Codex plugin root
├── .codex-plugin/plugin.json
└── skills/
    ├── cross-review/
    └── code-review-specialist/
```

## License

MIT. See [LICENSE](LICENSE).
