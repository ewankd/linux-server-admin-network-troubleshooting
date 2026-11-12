#!/usr/bin/env bash
# Read-only connectivity checks. Return nonzero if required checks fail.
set -uo pipefail

HOST=127.0.0.1
PORT=22
DOMAIN=example.com
OFFLINE=false
HTTP_URL=''
FAILURES=0

usage() {
  cat <<'EOF'
Usage: bash scripts/network_diagnostics.sh [OPTIONS]
  --host HOST          TCP target (default 127.0.0.1)
  --port PORT          TCP port (default 22)
  --domain NAME        DNS lookup target (default example.com)
  --http-url URL       Optional HTTP endpoint to probe (use http://127.0.0.1:8080/)
  --offline            Skip internet default-route and DNS checks
  --help               Show this help
EOF
}
while (($#)); do
  case $1 in
    --host) (($# >= 2)) || { usage >&2; exit 2; }; HOST=$2; shift 2 ;;
    --port) (($# >= 2)) || { usage >&2; exit 2; }; PORT=$2; shift 2 ;;
    --domain) (($# >= 2)) || { usage >&2; exit 2; }; DOMAIN=$2; shift 2 ;;
    --http-url) (($# >= 2)) || { usage >&2; exit 2; }; HTTP_URL=$2; shift 2 ;;
    --offline) OFFLINE=true; shift ;;
    --help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done
if [[ ! $PORT =~ ^[0-9]+$ ]] || ((10#$PORT < 1 || 10#$PORT > 65535)); then
  echo 'Port must be a number between 1 and 65535.' >&2
  exit 2
fi
for cmd in ip python3; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 2; }
done

pass() { printf '[PASS] %s\n' "$1"; }
fail() { printf '[FAIL] %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

printf '== Interface addresses ==\n'
ip -brief address show || fail 'Unable to list interfaces'
printf '\n== IPv4 routes ==\n'
ip -4 route show || fail 'Unable to list routes'

if [[ $OFFLINE != true ]]; then
  if ip -4 route show default | grep -q '^default '; then
    pass 'Default IPv4 route found'
  else
    fail 'No default IPv4 route (use --offline for isolated VM networks)'
  fi
  if command -v timeout >/dev/null 2>&1 && timeout 6 getent ahostsv4 "$DOMAIN" >/dev/null; then
    pass "DNS resolution: $DOMAIN"
  else
    fail "DNS resolution failed/timed out: $DOMAIN"
  fi
else
  echo '[SKIP] External DNS and default-route checks (--offline)'
fi

if python3 - "$HOST" "$PORT" <<'PY'
import socket
import sys
try:
    with socket.create_connection((sys.argv[1], int(sys.argv[2])), timeout=3):
        pass
except OSError:
    sys.exit(1)
PY
then
  pass "TCP connection to $HOST:$PORT"
else
  fail "TCP connection to $HOST:$PORT"
fi

if [[ -n $HTTP_URL ]]; then
  if command -v curl >/dev/null 2>&1 && curl --fail --silent --show-error --max-time 5 --output /dev/null "$HTTP_URL"; then
    pass "HTTP endpoint: $HTTP_URL"
  else
    fail "HTTP endpoint: $HTTP_URL"
  fi
fi
printf '\nFailures: %d\n' "$FAILURES"
(( FAILURES == 0 ))
