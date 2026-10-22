#!/bin/zsh
set -eu
workshop_root="$(cd -- "$(dirname -- "$0")" && pwd)"
exec "$workshop_root/play.command" --editor "$@"
