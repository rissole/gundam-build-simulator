#!/bin/zsh
set -eu
workshop_root="$(cd -- "$(dirname -- "$0")" && pwd)"
workshop_project="$workshop_root/game/workshop"
workshop_godot="${GODOT_BIN:-$HOME/.cache/gundam-tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$workshop_godot" ]]; then
  if command -v godot >/dev/null 2>&1; then
    workshop_godot="$(command -v godot)"
  elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
    workshop_godot=/Applications/Godot.app/Contents/MacOS/Godot
  else
    print "Godot was not found. Set GODOT_BIN to a Godot 4.7 executable."
    exit 1
  fi
fi
if [[ ! -d "$workshop_project/.godot/imported" ]]; then
  "$workshop_godot" --headless --path "$workshop_project" --editor --import
fi
exec "$workshop_godot" --path "$workshop_project" "$@"
