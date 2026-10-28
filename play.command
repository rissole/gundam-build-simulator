#!/bin/zsh
set -eu
workshop_root="$(cd -- "$(dirname -- "$0")" && pwd)"
workshop_project="$workshop_root/game/workshop"
# List stages without starting Godot, using the progression defined by the game.
for workshop_arg in "$@"; do
  if [[ "$workshop_arg" == --stage || "$workshop_arg" == --stage= ]]; then
    python3 - "$workshop_project/scripts/build_stages.gd" <<'PYTHON'
import ast
import re
import sys

source = open(sys.argv[1], encoding="utf-8").read()
for name in ("FOOT_STAGES", "STAGES"):
    match = re.search(r"^const " + name + r"\s*=\s*(\[[^\n]*\])", source, re.MULTILINE)
    if not match:
        sys.exit(f"Could not read {name} from build_stages.gd")
    for stage in ast.literal_eval(match.group(1)):
        print(stage)
PYTHON
    exit 0
  fi
done
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
# A pull can add global script classes while leaving an existing cache stale.
# Let the editor scan scripts and incrementally import changed assets before play.
workshop_refresh=true
for workshop_arg in "$@"; do
  [[ "$workshop_arg" == -- ]] && break
  case "$workshop_arg" in
    --editor|-e|--import) workshop_refresh=false ;;
  esac
done
if [[ "$workshop_refresh" == true ]]; then
  "$workshop_godot" --headless --path "$workshop_project" --editor --import
fi
exec "$workshop_godot" --path "$workshop_project" "$@"
