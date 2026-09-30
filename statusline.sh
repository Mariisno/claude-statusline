#!/bin/bash
# Mari's Claude Code status line 🌸
# Line 1: greeting · project · git branch · model + effort · MAX tag · cat
# Line 2: meters for context, the 5-hour limit and the weekly limit
# Claude Code runs this and shows whatever it prints at the bottom of the window.

input=$(cat)

# Persist a usage snapshot for the claude-usage widget (additivt, skadefritt).
CU_DIR="$HOME/Library/Caches/claude-usage"; mkdir -p "$CU_DIR"
printf '%s' "$input" | jq -c '{rate_limits, context_window, capturedAt: now}' \
  > "$CU_DIR/snapshot.json.tmp" 2>/dev/null && mv "$CU_DIR/snapshot.json.tmp" "$CU_DIR/snapshot.json"

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
project=$(basename "${dir:-~}")

# Greeting that follows the clock
hour=$((10#$(date +%H)))
if   [ "$hour" -ge 6 ]  && [ "$hour" -lt 10 ]; then greeting="God morgen, Mari ☀️"
elif [ "$hour" -ge 10 ] && [ "$hour" -lt 17 ]; then greeting="God dag, Mari 🌤️"
elif [ "$hour" -ge 17 ] && [ "$hour" -lt 23 ]; then greeting="God kveld, Mari 🌙"
else greeting="God natt, Mari ✨"
fi

# Effort level (how deeply Claude thinks), shown next to the model name
effort=$(echo "$input" | jq -r '.effort.level // empty')
# Effort below high is shown in peach, so an accidental downgrade is visible
effort_tag=""
if [ -n "$effort" ]; then
  case "$effort" in high|xhigh|max) effort_tag=" · $effort" ;;
                   *) effort_tag=" · \033[38;5;223m$effort\033[38;5;245m" ;; esac
fi

# Which account: a MAX tag when Claude Code runs on a separate config dir named *max*
account=""
case "${CLAUDE_CONFIG_DIR:-}" in *max*) account="  \033[1;38;5;223mMAX\033[0m" ;; esac

# Usage numbers (shown as meters on line 2):
usage=""
limit_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$limit_used" ]; then
  left=$((100 - limit_used))
  batt="🔋"; [ "$left" -lt 30 ] && batt="🪫"
  usage="$batt ${left}%"
fi
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
[ -n "$ctx_used" ] && usage="$usage  🧠 ${ctx_used}%"

# 🐈 A little cat trots across the line, one step per second.
# The status line redraws while Claude works, so the cat appears to run.
track_len=6
pos=$(( track_len - 1 - ($(date +%s) % track_len) ))  # runs right-to-left, then loops
cat_track=""
for ((i = 0; i < track_len; i++)); do
  if   [ "$i" -eq "$pos" ];        then cat_track+="🐈"
  elif [ "$i" -eq $((pos + 2)) ];  then cat_track+="🐾"
  else cat_track+="  "
  fi
done

# Git branch, with * when there are unsaved (uncommitted) changes
branch=""
if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
  [ -n "$(git -C "$dir" status --porcelain 2>/dev/null | head -1)" ] && branch="$branch*"
  branch="  \033[38;5;183m$branch\033[0m"
fi

# Pastel palette (256-colour, made for dark themes)
PINK=218; BLUE=117; LAVENDER=183; MINT=151; PEACH=223; CORAL=209; DIM=245; FAINT=242

# Pink greeting · blue project · lavender branch · dim model + effort · MAX tag · cat
printf "\033[38;5;${PINK}m%s\033[0m  \033[38;5;${BLUE}m%s\033[0m%b  \033[38;5;${DIM}m%s%b\033[0m%b  %s\n" \
  "$greeting" "$project" "$branch" "$model" "$effort_tag" "$account" "$cat_track"

# ── Line 2: soft dot meters ───────────────────────────────────────────────────
#   ctx  how full this conversation is
#   5h   the 5-hour limit, and time until it resets
#   7d   the weekly limit, and the day and time it resets
# Mint under 50 %, peach from 50 %, coral from 80 % (coral stays clear of the pink greeting).
tone() { if [ "$1" -ge 80 ]; then echo $CORAL; elif [ "$1" -ge 50 ]; then echo $PEACH; else echo $MINT; fi; }
dots() { # dots <percent>  →  ●●●○○○○○○○
  local p=$1 w=10 fill c; c=$(tone "$p")
  fill=$(( (p * w + 50) / 100 )); [ "$fill" -gt "$w" ] && fill=$w
  printf "\033[38;5;%sm" "$c";      for ((i = 0; i < fill; i++)); do printf "●"; done
  printf "\033[38;5;%sm" "$FAINT";  for ((i = fill; i < w; i++)); do printf "○"; done
  printf "\033[0m"
}
meter() { # meter <label> <percent> [extra]
  local c; c=$(tone "$2")
  printf "\033[38;5;%sm%s\033[0m %s \033[38;5;%sm%s%%\033[0m" "$DIM" "$1" "$(dots "$2")" "$c" "$2"
  [ -n "${3:-}" ] && printf " \033[38;5;%sm· %s\033[0m" "$LAVENDER" "$3"
}
until_reset() { # until_reset <epoch>  →  "1h 23m"
  local s=$(( $1 - $(date +%s) )); [ "$s" -lt 0 ] && s=0
  printf "%dh %02dm" $((s / 3600)) $((s % 3600 / 60))
}
reset_day() { # reset_day <epoch>  →  "fre 16:57" (macOS date -r, GNU date -d fallback)
  local days=(man tir ons tor fre lør søn) d t
  d=$(date -r "$1" +%u 2>/dev/null || date -d "@$1" +%u)
  t=$(date -r "$1" +%H:%M 2>/dev/null || date -d "@$1" +%H:%M)
  printf "%s %s" "${days[$((d - 1))]}" "$t"
}
num() { printf '%.0f' "${1:-0}"; }   # percentages can arrive as decimals

parts=()
[ -n "$ctx_used" ] && parts+=("$(meter ctx "$(num "$ctx_used")")")
h5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$h5" ]; then
  r=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  parts+=("$(meter 5h "$(num "$h5")" "${r:+$(until_reset "$r")}")")
fi
d7=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$d7" ]; then
  r=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
  parts+=("$(meter 7d "$(num "$d7")" "${r:+$(reset_day "$r")}")")
fi
if [ ${#parts[@]} -gt 0 ]; then
  out="${parts[0]}"; for m in "${parts[@]:1}"; do out="$out   $m"; done
  printf "%s" "$out"
fi
