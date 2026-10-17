#!/bin/bash
# Smoke test: feeds statusline.sh the JSON Claude Code sends and checks that it
# prints both lines without errors. HOME points at a temp folder, so the usage
# snapshot never lands in the real ~/Library/Caches. Run: bash tests/smoke.sh
set -u
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
failed=0

run() { # run <name> <json> <text the output must contain>
  local out err
  out=$(printf '%s' "$2" | HOME="$tmp" bash "$root/statusline.sh" 2>"$tmp/err"); err=$(cat "$tmp/err")
  if [ -n "$err" ]; then echo "✗ $1: stderr: $err"; failed=1
  elif [[ "$out" != *"$3"* ]]; then echo "✗ $1: missing «$3» in: $out"; failed=1
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

exit $failed
