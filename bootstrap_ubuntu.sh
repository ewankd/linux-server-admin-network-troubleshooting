#!/usr/bin/env bash
# Install the minimum packages needed for the lab. Ubuntu 22.04/24.04.
set -Eeuo pipefail

if [[ $EUID -ne 0 ]]; then
  printf 'ERROR: Run with sudo: sudo bash scripts/bootstrap_ubuntu.sh\n' >&2
  exit 2
fi
if ! command -v apt-get >/dev/null 2>&1; then
  printf 'ERROR: This installer requires Ubuntu/Debian apt-get.\n' >&2
  exit 2
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  openssh-server python3 curl iproute2 iputils-ping dnsutils traceroute

# Ubuntu's OpenSSH service is named "ssh" rather than "sshd".
if command -v systemctl >/dev/null 2>&1; then
  systemctl enable --now ssh
  systemctl --no-pager --full status ssh || true
else
  printf 'NOTE: systemd is unavailable; verify that SSH is running manually.\n'
fi
cat <<'EOF'

Installed lab dependencies. No firewall rules, SSH passwords, or user accounts were changed.
NEXT: Configure a public key and verify a NEW SSH session before considering hardening.
EOF
