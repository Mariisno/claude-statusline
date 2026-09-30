# claude-statusline 🐈

A cozy status line for [Claude Code](https://code.claude.com): a greeting that follows the clock, the current project, a mood emoji that changes daily, model + effort, how much of the 5-hour allowance is left, how full the context is — and a little cat trotting across the line while Claude works.

```
God dag, Mari 🌤️  my-project  🌻  Opus 5.5 · high  🔋 78%  🧠 25%        🐈  🐾    🐾
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
| Model · effort | `.model.display_name` and `.effort.level` from Claude Code |
| 🔋 / 🪫 | share of the 5-hour rate limit left (🪫 under 30%) |
| 🧠 | share of the context window used |
| 🐈 | moves one step per second, so it runs while the line redraws |

It also writes a small usage snapshot to `~/Library/Caches/claude-usage/snapshot.json` for a separate desktop widget. Remove lines 8–11 if you don't need it.
