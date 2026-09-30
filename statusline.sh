#!/bin/bash
# Mari's Claude Code status line 🌸
# Line 1: greeting · project · git branch · daily mood · model + effort · cat
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

# A little mood that changes once a day
moods=(🌸 🌷 🦋 🍀 🌈 ⭐ 🌻)
day_of_year=$((10#$(date +%j)))
mood=${moods[$((day_of_year % ${#moods[@]}))]}

# Effort level (how deeply Claude thinks), shown next to the model name
effort=$(echo "$input" | jq -r '.effort.level // empty')
[ -n "$effort" ] && model="$model · $effort"

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
track_len=10
pos=$(( track_len - 1 - ($(date +%s) % track_len) ))  # runs right-to-left, then loops
cat_track=""
for ((i = 0; i < track_len; i++)); do
  if   [ "$i" -eq "$pos" ];        then cat_track+="🐈"
  elif [ "$i" -eq $((pos + 2)) ];  then cat_track+="🐾"
  elif [ "$i" -eq $((pos + 5)) ];  then cat_track+="🐾"
  else cat_track+="  "
  fi
done

# Git branch, with * when there are unsaved (uncommitted) changes
branch=""
if [ -n "$dir" ] && git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$dir" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
  [ -n "$(git -C "$dir" status --porcelain 2>/dev/null | head -1)" ] && branch="$branch*"
  branch="  \033[38;5;183m⎇ $branch\033[0m"
fi

# Soft pink greeting · soft blue project · dim grey practical info (for dark themes)
printf "\033[38;5;218m%s\033[0m  \033[38;5;117m%s\033[0m%b  %s  \033[38;5;245m%s\033[0m  %s\n" \
  "$greeting" "$project" "$branch" "$mood" "$model" "$cat_track"

# ── Line 2: meters ────────────────────────────────────────────────────────────
#   Ctx  how full this conversation is
#   5h   the 5-hour limit, with time until it resets
#   7d   the weekly limit, with the day and time it resets
# Green under 50 %, amber 50–79 %, red from 80 %.
bar() { # bar <percent>  →  10-cell bar, filled part coloured, empty part dotted
  local p=$1 w=10 fill c
  fill=$(( (p * w + 50) / 100 )); [ "$fill" -gt "$w" ] && fill=$w
  if   [ "$p" -ge 80 ]; then c=203
  elif [ "$p" -ge 50 ]; then c=179
  else c=114; fi
  printf "\033[38;5;%sm" "$c"; for ((i = 0; i < fill; i++)); do printf "█"; done
  printf "\033[38;5;240m";     for ((i = fill; i < w; i++)); do printf "░"; done
  printf "\033[0m"
}
until_reset() { # until_reset <epoch>  →  "1h 23m"
  local s=$(( $1 - $(date +%s) )); [ "$s" -lt 0 ] && s=0
  printf "%dh %02dm" $((s / 3600)) $((s % 3600 / 60))
}
reset_day() { # reset_day <epoch>  →  "fri 16:57" (macOS date -r, GNU date -d fallback)
  { date -r "$1" "+%a %H:%M" 2>/dev/null || date -d "@$1" "+%a %H:%M"; } | tr '[:upper:]' '[:lower:]'
}
num() { printf '%.0f' "${1:-0}"; }   # percentages can arrive as decimals

meters=()
if [ -n "$ctx_used" ]; then
  p=$(num "$ctx_used"); meters+=("Ctx $(bar "$p") ${p}%")
fi
h5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$h5" ]; then
  p=$(num "$h5"); r=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  t=""; [ -n "$r" ] && t=" \033[38;5;183m($(until_reset "$r"))\033[0m"
  meters+=("5h$t $(bar "$p") ${p}%")
fi
d7=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
if [ -n "$d7" ]; then
  p=$(num "$d7"); r=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
  t=""; [ -n "$r" ] && t=" \033[38;5;183m($(reset_day "$r"))\033[0m"
  meters+=("7d$t $(bar "$p") ${p}%")
fi
if [ ${#meters[@]} -gt 0 ]; then
  out="${meters[0]}"; for m in "${meters[@]:1}"; do out="$out  \033[38;5;240m|\033[0m  $m"; done
  printf "%b" "$out"
fi
