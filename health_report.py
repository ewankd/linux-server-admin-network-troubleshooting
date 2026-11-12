#!/usr/bin/env python3
"""Generate a read-only Ubuntu server health report; Python standard library only."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess


def run_command(args, timeout=5):
    """Return command output or a structured, non-fatal error."""
    try:
        completed = subprocess.run(
            args, check=False, capture_output=True, text=True, timeout=timeout
        )
    except (FileNotFoundError, PermissionError, subprocess.TimeoutExpired) as exc:
        return {"ok": False, "output": "", "error": str(exc)}
    output = completed.stdout.strip()
    return {
        "ok": completed.returncode == 0,
        "output": output,
        "error": completed.stderr.strip() if completed.returncode else None,
    }


def tcp_probe(host, port, timeout=2):
    """Test a TCP connection; no credentials or payload are sent."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return {"reachable": True, "error": None}
    except (OSError, ValueError) as exc:
        return {"reachable": False, "error": str(exc)}


def collect_report(host="127.0.0.1", port=22, timeout=2):
    disk = shutil.disk_usage("/")
    try:
        load_1m, load_5m, load_15m = os.getloadavg()
        load = {"1m": load_1m, "5m": load_5m, "15m": load_15m}
    except OSError:
        load = None

    return {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "hostname": socket.gethostname(),
        "load_average": load,
        "disk_root": {
            "total_bytes": disk.total,
            "used_bytes": disk.used,
            "free_bytes": disk.free,
            "used_percent": round(100 * disk.used / disk.total, 2) if disk.total else 0,
        },
        "interfaces": run_command(["ip", "-brief", "address", "show"]),
        "default_ipv4_route": run_command(["ip", "-4", "route", "show", "default"]),
        "ssh_service": run_command(["systemctl", "is-active", "ssh"]),
        "tcp_probe": {
            "host": host,
            "port": port,
            **tcp_probe(host, port, timeout=timeout),
        },
    }


def write_report(report, path):
    """Write report only to the explicitly specified destination."""
    destination = Path(path).expanduser()
    destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    temp = destination.with_name(destination.name + ".tmp")
    with temp.open("w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")
    os.chmod(temp, 0o600)
    temp.replace(destination)
    return destination


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tcp-host", default="127.0.0.1", help="TCP target host")
    parser.add_argument("--tcp-port", type=int, default=22, help="TCP target port (1-65535)")
    parser.add_argument("--timeout", type=float, default=2, help="TCP timeout in seconds")
    parser.add_argument("--output", help="Optional JSON output file (private; ignored by Git)")
    args = parser.parse_args(argv)
    if not 1 <= args.tcp_port <= 65535:
        parser.error("--tcp-port must be between 1 and 65535")
    if not 0 < args.timeout <= 30:
        parser.error("--timeout must be > 0 and <= 30")

    report = collect_report(args.tcp_host, args.tcp_port, args.timeout)
    if args.output:
        print(f"Health report saved to {write_report(report, args.output)}")
    else:
        print(json.dumps(report, indent=2, sort_keys=True))
    return 0  # Report generation succeeds even when a monitored service is down.


if __name__ == "__main__":
    raise SystemExit(main())
