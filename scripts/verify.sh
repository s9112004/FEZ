#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.local/share}"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
log_dir="$(mktemp -d /tmp/mistfront-checks.XXXXXX)"
run_check() {
  local name="$1"
  shift
  local status=0
  "$@" > "$log_dir/$name.log" 2>&1 || status=$?
  cat "$log_dir/$name.log"
  if (( status != 0 )); then return "$status"; fi
  # Godot import can exit 0 with script errors; never treat that as success.
  if rg -q 'SCRIPT ERROR:|^ERROR:|FAIL:' "$log_dir/$name.log"; then return 1; fi
}
run_check import godot --headless --path . --editor --import
run_check movement godot --headless --path . --script tests/movement_smoke.gd
run_check battle godot --headless --path . --script tests/battle_smoke.gd
run_check presentation godot --headless --path . --script tests/presentation_smoke.gd
run_check input godot --headless --path . --script tests/input_smoke.gd
run_check simulation godot --headless --fixed-fps 60 --path . --script tests/battle_simulation.gd
printf 'Validation logs: %s\n' "$log_dir"
