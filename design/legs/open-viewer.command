#!/bin/zsh
# Finder launches .command files in an arbitrary cwd.
set -eu
cd -- "${0:A:h}"
port=$(python3 - <<'PY'
import socket
with socket.socket() as sock:
    sock.bind(('127.0.0.1', 0))
    print(sock.getsockname()[1])
PY
)
print "Starting LG-01 server on port $port…"
python3 -u -m http.server "$port" --bind 127.0.0.1 --directory viewer &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT
trap 'exit 0' INT TERM HUP
# Wait for the server before opening a tab. Fail cleanly if it cannot bind.
python3 - "$port" "$server_pid" <<'PY'
import os, sys, time, urllib.request
url = f'http://127.0.0.1:{sys.argv[1]}/'
# HTTPServer resolves its server name before listening. macOS DNS can be slow
# even on loopback; wait for readiness while still detecting a dead child.
deadline = time.monotonic() + 90
while time.monotonic() < deadline:
    try:
        os.kill(int(sys.argv[2]), 0)
    except ProcessLookupError:
        raise SystemExit('Viewer server exited before it could start')
    try:
        with urllib.request.urlopen(url, timeout=.3) as response:
            if response.status == 200:
                break
    except OSError:
        time.sleep(.1)
else:
    raise SystemExit('Viewer server did not start')
print(f'LG-01 viewer: {url}', flush=True)
PY
open "http://127.0.0.1:$port/"
print 'Serving LG-01. Close this Terminal window or press Ctrl-C to stop.'
wait "$server_pid"
