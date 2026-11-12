#!/usr/bin/env bash
# Local-only HTTP service for network service diagnostics. Foreground; Ctrl-C stops it.
set -Eeuo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$(cd -- "$SCRIPT_DIR/../site" && pwd)"
PORT="${1:-8080}"
if [[ ! $PORT =~ ^[0-9]+$ ]] || ((10#$PORT < 1024 || 10#$PORT > 65535)); then
  echo 'Specify an unprivileged port between 1024 and 65535.' >&2
  exit 2
fi
printf 'Serving %s at http://127.0.0.1:%s/ (local VM access only).\n' "$SITE_DIR" "$PORT"
exec python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$SITE_DIR"
