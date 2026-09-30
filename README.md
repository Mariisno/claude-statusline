# claude-statusline 🐈

A cozy two-line status line for [Claude Code](https://code.claude.com). Line 1 has a greeting that follows the clock, the project, the git branch, model + effort, a MAX tag when you run on a second account, and a little cat trotting across the line while Claude works. Line 2 has meters for the context window, the 5-hour limit and the weekly limit.

```
God dag, Mari 🌤️  my-project  main*  Opus 5.5 · high  🐈  🐾
ctx ●●●○○○○○○○ 32%   5h ●●●●●●○○○○ 62% · 1h 23m   7d ●●●●●●○○○○ 55% · fre 16:57
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

Requires `jq`. Both lines fit in an 80-column pane.

For a smooth-running cat and a live countdown, add `"refreshInterval": 1` to the `statusLine` block.

 The greeting is in Norwegian and uses my name. Change the four `greeting=` lines to make it yours.

## What it shows

| Part | Source |
|---|---|
| Greeting | local time: morning, day, evening, night |
| Project | basename of the current directory |
| Branch | current git branch, `*` when there are uncommitted changes |
| Model · effort | `.model.display_name` and `.effort.level` — effort turns peach when it is below `high` |
| MAX | shown when `CLAUDE_CONFIG_DIR` contains `max` (a second Claude account run with its own config dir) |
| 🐈 | moves one step per second, so it runs while the line redraws |
| ctx | `.context_window.used_percentage` |
| 5h · time left | `.rate_limits.five_hour` — used % and time until `resets_at` |
| 7d · reset day | `.rate_limits.seven_day` — used % and the day and time it resets |

Meters are soft pastel dots: mint under 50 %, peach from 50 % and coral from 80 % (kept clear of the pink greeting). Day names are Norwegian (`man tir ons tor fre lør søn`). The rate-limit meters only appear on plans that report limits. Works on macOS and Linux (`date -r` with a GNU `date -d` fallback).

It also writes a small usage snapshot to `~/Library/Caches/claude-usage/snapshot.json` for a separate desktop widget. Remove lines 8–11 if you don't need it.
