#!/usr/bin/env bash
set -euo pipefail
root_dir="$(cd "$(dirname "$0")/.." && pwd)"
core_version="$(arduino-cli core list | while read -r id version rest; do
  if [[ "$id" == "SiliconLabs:silabs" ]]; then printf '%s' "$version"; fi
done)"
if [[ "$core_version" != "4.0.0" ]]; then
  echo "Install SiliconLabs:silabs@4.0.0 as described in firmware/mg24-neokey/README.md." >&2
  exit 1
fi
extra=(--build-path "$root_dir/build-mg24")
if [[ -n "${MG24_CTAGS_PATH:-}" ]]; then
  if [[ ! -x "$MG24_CTAGS_PATH/ctags" ]]; then
    echo "MG24_CTAGS_PATH must contain an executable named ctags." >&2
    exit 1
  fi
  extra+=(--build-property "runtime.tools.ctags.path=$MG24_CTAGS_PATH")
fi
arduino-cli compile --fqbn SiliconLabs:silabs:xiao_mg24:protocol_stack=ble_silabs \
  "${extra[@]}" \
  "$root_dir/firmware/mg24-neokey/neokey_ble"
