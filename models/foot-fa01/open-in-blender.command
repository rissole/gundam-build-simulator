#!/bin/zsh
set -eu
model_dir=${0:A:h}
for blender_path in \
  "/Applications/Blender.app/Contents/MacOS/Blender" \
  "$HOME/.cache/gundam-tools/Blender-4.5.14.app/Contents/MacOS/Blender"
do
  if [[ -x "$blender_path" ]]; then
    exec "$blender_path" "$model_dir/output/foot-fa01.blend"
  fi
done
if command -v blender >/dev/null 2>&1; then
  exec blender "$model_dir/output/foot-fa01.blend"
fi
print "Blender was not found. Open output/foot-fa01.blend in Blender 4.5 or later."
