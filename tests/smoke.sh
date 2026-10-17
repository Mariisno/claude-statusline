#!/bin/bash
# Smoke test: feeds statusline.sh the JSON Claude Code sends and checks that it
# prints both lines without errors. HOME points at a temp folder, so the usage
# snapshot never lands in the real ~/Library/Caches. Run: bash tests/smoke.sh
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
failed=0

run() { # run <name> <json> <text the output must contain> [text it must NOT contain]
  local out err
  out=$(printf '%s' "$2" | HOME="$tmp" bash "$root/statusline.sh" 2>"$tmp/err"); err=$(cat "$tmp/err")
  if [ -n "$err" ]; then echo "✗ $1: stderr: $err"; failed=1
  elif [[ "$out" != *"$3"* ]]; then echo "✗ $1: missing «$3» in: $out"; failed=1
  elif [ -n "${4:-}" ] && [[ "$out" == *"$4"* ]]; then echo "✗ $1: should not show «$4» in: $out"; failed=1
  else echo "✓ $1"; fi
}

now=$(date +%s)
full='{"model":{"display_name":"Opus"},"workspace":{"current_dir":"'"$root"'"},"effort":{"level":"high"},
  "context_window":{"used_percentage":40},
  "rate_limits":{"five_hour":{"used_percentage":25,"resets_at":'$((now + 3600))'},
                 "seven_day":{"used_percentage":60,"resets_at":'$((now + 86400))'}}}'
run 'full input' "$full" 'Opus'
run 'empty input' '{}' 'Claude'
run 'low effort' '{"model":{"display_name":"Opus"},"effort":{"level":"medium"}}' 'medium'
run 'decimal percentages' '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":12.5},
  "rate_limits":{"five_hour":{"used_percentage":33.3}}}' 'Opus'
run 'rounds to whole percent' '{"model":{"display_name":"Opus"},"rate_limits":{"five_hour":{"used_percentage":66.6}}}' '67%'
run 'decimal reset times' '{"model":{"display_name":"Opus"},"rate_limits":{"five_hour":{"used_percentage":10,"resets_at":'$((now + 3600)).5'},
  "seven_day":{"used_percentage":20,"resets_at":'$((now + 86400)).5'}}}' '7d'
# My signature is on by default, and one variable turns it off. No account tags, ever.
opus='{"model":{"display_name":"Opus"}}'
run 'signature: name' "$opus" ', Mari'
run 'signature: Sussi' "$opus" '🐈'
STATUSLINE_PERSONAL=0 run 'signature off: no name' "$opus" 'Opus' 'Mari'
STATUSLINE_PERSONAL=0 run 'signature off: no Sussi' "$opus" 'Opus' '🐈'
STATUSLINE_NAME=Ola run 'own name' "$opus" ', Ola' 'Mari'
STATUSLINE_NAME= run 'no name' "$opus" 'Opus' 'Mari'
CLAUDE_CONFIG_DIR="$tmp/.claude-second" run 'no account tag' "$opus" 'Opus' 'SECOND'
for flag in --version --help; do
  out=$(bash "$root/statusline.sh" "$flag" </dev/null 2>&1)
  if [[ "$out" == *"by Mari Svennevik Notland"* ]]; then echo "✓ $flag"; else echo "✗ $flag: $out"; failed=1; fi
done
# A decimal comma locale must not break the rounding (printf %.0f does under nb_NO).
if locale -a 2>/dev/null | grep -qiE "^nb_NO\.utf-?8$"; then
  LC_ALL=nb_NO.UTF-8 run 'Norwegian locale' '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":12.5}}' '13%'
else echo "- Norwegian locale: skipped, nb_NO.UTF-8 is not installed"; fi

exit $failed
