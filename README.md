# claude-statusline 🐈

A cozy two-line status line for [Claude Code](https://code.claude.com). Line 1 has a greeting that follows the clock, the project, the git branch, a mood emoji that changes daily, model + effort, and a little cat trotting across the line while Claude works. Line 2 has meters for the context window, the 5-hour limit and the weekly limit.

```
God dag, Mari 🌤️  my-project  ⎇ main*  🌻  Opus 5.5 · high        🐈  🐾    🐾
Ctx ███░░░░░░░ 32%  |  5h (1h 23m) ██████░░░░ 62%  |  7d (fri 16:57) ██████░░░░ 55%
```

## Install

1. Copy `statusline.sh` to `~/.claude/statusline.sh` and make it executable (`chmod +x`).
2. Add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

Requires `jq`. The greeting is in Norwegian and uses my name. Change the four `greeting=` lines to make it yours.

## What it shows

| Part | Source |
|---|---|
| Greeting | local time: morning, day, evening, night |
| Project | basename of the current directory |
| Mood | one of seven emoji, rotating by day of year |
| ⎇ branch | current git branch, `*` when there are uncommitted changes |
| Model · effort | `.model.display_name` and `.effort.level` from Claude Code |
| 🐈 | moves one step per second, so it runs while the line redraws |
| Ctx | `.context_window.used_percentage` |
| 5h (time left) | `.rate_limits.five_hour` — used % and time until `resets_at` |
| 7d (reset day) | `.rate_limits.seven_day` — used % and the day and time it resets |

Meters are green under 50 %, amber from 50 % and red from 80 %. The rate-limit meters only appear on plans that report limits. Works on macOS and Linux (`date -r` with a GNU `date -d` fallback).

It also writes a small usage snapshot to `~/Library/Caches/claude-usage/snapshot.json` for a separate desktop widget. Remove lines 8–11 if you don't need it.
