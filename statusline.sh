#!/bin/bash
# Mari's Claude Code status line 🌸
# Shows: greeting · project · daily mood · model + effort · usage
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

# Usage:
#   🔋 how much of the 5-hour plan allowance is LEFT (🪫 when under 30%)
#   🧠 how full this conversation's memory (context) is
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

# Soft pink greeting · soft blue project · dim grey practical info (for dark themes)
printf "\033[38;5;218m%s\033[0m  \033[38;5;117m%s\033[0m  %s  \033[38;5;245m%s\033[0m  %s" \
  "$greeting" "$project" "$mood" "$model  $usage" "$cat_track"
