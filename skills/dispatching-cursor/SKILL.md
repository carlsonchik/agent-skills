---
description: Как запускать Cursor CLI (cursor-agent) как headless-субагента — проверено 14.09.2026
---
---
name: dispatching-cursor
description: Dispatch the Cursor CLI (cursor-agent) as a stateless headless subagent on a machine where the user has a Cursor subscription. Load when the user wants Cursor's models (Codex 5.3, Claude Opus 5, Composer) to do work on their behalf, when the Cursor subscription should be used instead of API credits, or when you need to check whether cursor-agent is usable at all.
---

# Dispatch Cursor CLI as a subagent

`cursor-agent` is the headless-capable Cursor CLI. It authenticates against the
user's **Cursor subscription**, so prompts spend their plan rather than API
credits. Like Claude Code and Codex it has **zero memory** — give it full
context in the prompt (see [[skills/dispatching-coding-agents]] for the prompt
template; that bundled skill covers Claude Code and Codex, not Cursor).

Verify the binary first: `command -v cursor-agent` (often
`~/.local/bin/cursor-agent`).

## Login

Check with `cursor-agent --list-models`. If it prints
`Authentication required. Run 'agent login'`, the user must run
`cursor-agent login` themselves — it opens a browser.

## Region block — check before promising anything

In some regions every request fails with:

```
Error: [permission_denied] Cursor is not available in your region.
```

This is a server-side check, not a local misconfiguration. Observed on
2026-09-14: it appeared on one run and the same commands succeeded minutes
later, so **retry once before declaring Cursor unusable for this user**.
Login succeeding proves nothing — the browser login can pass while API calls
are refused. Do not attempt to bypass it; report it plainly.

## Headless invocation

```bash
cd /path/to/repo && cursor-agent -p "YOUR PROMPT" --output-format text --trust
```

`--trust` is required in headless mode: without it (or `-f`/`--yolo`) the run
stops with "Workspace Trust Required" and the prompt never reaches the model.
Use a scratch directory for probes so you never hand it the user's real repo
by accident.

| Flag | Purpose |
|------|---------|
| `-p`, `--print` | Non-interactive; prints and exits |
| `--trust` | Trust the workspace (needed for headless) |
| `-f`, `--force`, `--yolo` | Also auto-approve commands — only when the user asked |
| `--output-format` | `text`, `json`, `stream-json` |
| `-m`, `--model` | e.g. `composer-2.5`, `gpt-5.3-codex-high`, `claude-opus-5-thinking-high` |
| `--mode plan\|ask` | Read-only planning / Q&A |
| `--workspace <path>` | Working directory without `cd` |
| `-w, --worktree [name]` | Isolated git worktree under `~/.cursor/worktrees/` |
| `--continue`, `--resume [chatId]` | Resume a previous session |

`--list-models` shows what the subscription currently exposes — check it
instead of guessing model names.

## Practical notes

- Default to `run_in_background: true` on the Bash call; a trivial turn took
  ~20s, real work takes minutes. Set a generous command timeout.
- Run it in parallel with your own work, then verify its output yourself — it
  cannot see your memory or the user's preferences unless the prompt says so.
- Cursor **cannot** be connected as a model provider for Letta (not in the
  supported provider list). The only route for a Cursor subscription is
  dispatching it as a subagent like this.
