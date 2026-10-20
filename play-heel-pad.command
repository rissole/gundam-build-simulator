#!/bin/zsh
set -eu
demo_root="$(cd -- "$(dirname -- "$0")" && pwd)"
demo_project="$demo_root/game/heel-pad-demo"
demo_godot="${GODOT_BIN:-$HOME/.cache/gundam-tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot}"
if [[ ! -x "$demo_godot" ]]; then
  if command -v godot >/dev/null 2>&1; then
    demo_godot="$(command -v godot)"
  elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
    demo_godot=/Applications/Godot.app/Contents/MacOS/Godot
  else
    print "Godot was not found. Set GODOT_BIN to a Godot 4.7 executable."
    exit 1
  fi
fi
if [[ ! -d "$demo_project/.godot/imported" ]]; then
  "$demo_godot" --headless --path "$demo_project" --editor --import
fi
exec "$demo_godot" --path "$demo_project" "$@"
