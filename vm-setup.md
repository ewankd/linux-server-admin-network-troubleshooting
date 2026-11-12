# Ubuntu VM setup

## Hypervisor and networking

1. Download the Ubuntu **Server** 22.04 or 24.04 LTS ISO from ubuntu.com and create a VM with about 2 GB RAM and 15 GB disk.
2. Install Ubuntu Server, create a non-root user with sudo access, and install system updates.
3. For safe lab isolation, add a **host-only adapter** so your laptop can connect to the VM; optionally use a **separate NAT adapter** for outbound `apt-get` and DNS. Do not use bridged networking unless you understand the exposure.
4. Run `ip -brief address` and `ip -4 route`. Record your VM's host-only IP for later SSH testing. Do not publish private network details in the repository.
5. Run `sudo bash scripts/bootstrap_ubuntu.sh`, then `sudo systemctl is-active ssh`.
6. From the host, test SSH to the guest's host-only IP. If you instead use NAT port forwarding, map a *host loopback* port such as `127.0.0.1:2222` to guest TCP port 22 and use `ssh -p 2222 ...@127.0.0.1`.
7. Install an SSH **public** key, and verify a new login session before considering stronger SSH authentication settings.
8. Run diagnostics and health reporter; compare observed behavior against the [validation checklist](validation-checklist.md).

## Network modes at a glance

| Mode | Outbound internet | Laptop → VM | Exposure |
|---|---|---|---|
| NAT | Usually yes | Requires configured port forwarding | Generally isolated without forwarding |
| Host-only | Usually no | Yes (correct IP and guest firewall) | Isolated to host network |
| Bridged | Depends on LAN | Usually yes | VM is visible on local LAN; avoid initially |

If you run the HTTP demo service it only listens on loopback inside the VM, regardless of VM adapter configuration. For an external TCP service demonstration, use SSH over the host-only interface rather than exposing a web server.

## Expected behavior

- `systemctl is-active ssh` should return `active` when OpenSSH Server is installed and running.
- `bash scripts/network_diagnostics.sh --offline` should PASS TCP `127.0.0.1:22` if SSH is listening.
- Without `--offline`, DNS and a default route are required; they may fail if the VM is deliberately host-only.
- `python3 src/health_report.py` prints a JSON report. `ssh_service` may read `inactive` on a system without a running SSH daemon.

Always diagnose based on observations, not assumptions about your hypervisor's addressing or firewall.
