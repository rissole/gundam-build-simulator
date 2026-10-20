#!/bin/zsh
set -eu
demo_root="$(cd -- "$(dirname -- "$0")" && pwd)"
exec "$demo_root/play-heel-pad.command" --editor "$@"
