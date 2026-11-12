# Linux Server Administration & Network Troubleshooting

A reproducible, **single-Ubuntu-VM learning lab** for Linux administration, SSH public-key access, service inspection, network troubleshooting, and Bash/Python automation. Created as a portfolio project relevant to lab technician / infrastructure student roles.

> **Scope and evidence:** The code and automated unit tests can be verified without an Ubuntu VM. Installation, remote SSH authentication, firewall behavior, and VM-specific connectivity **must be validated on a real Ubuntu VM** before describing them as completed hands-on lab results. See [Validation checklist](docs/validation-checklist.md).

## What the project demonstrates

| Component | What you can show to a reviewer |
|---|---|
| Ubuntu bootstrap | Repeatable package installation and SSH service startup |
| SSH key management | Public-key-based authorized access for an existing Linux user |
| Local web service | A loopback-only TCP/HTTP service for safe service tests |
| Network diagnostics | Interface, route, DNS, TCP, and optional HTTP health checks |
| Python health reporting | Structured JSON with disk, load, interface, route, SSH, and TCP status |
| Automation | Example scheduled report via cron (opt-in, not installed automatically) |
| Reliability | Offline tests and CI for Python, script syntax, and safe failure behavior |

## Architecture

```text
Host laptop
   |
   | SSH to guest (host-only adapter, or NAT port forwarding)
   v
Ubuntu 22.04 / 24.04 LTS virtual machine
   |-- ssh service          :22       (remote login)
   |-- Python HTTP service  :8080     (127.0.0.1 only)
   |-- diagnostic Bash CLI           (routing / DNS / TCP / HTTP)
   +-- Python health reporter        (JSON, no privilege required)
```

**Prerequisites:** VirtualBox, VMware, or another hypervisor; Ubuntu Server 22.04 or 24.04 LTS installed in a VM; a normal user with sudo access; network connectivity for APT (unless Ubuntu packages are preinstalled). Reserve roughly 2 GB RAM and 15 GB disk for the VM. A host-only interface is a safe default for host-to-guest SSH; a NAT adapter provides outbound package updates. See [VM setup](docs/vm-setup.md).

## Quick start on an Ubuntu VM

Clone or copy this repository into the VM (the example folder name is `linux-server-admin-network-troubleshooting`):

```bash
sudo bash scripts/bootstrap_ubuntu.sh
sudo systemctl is-active ssh
python3 src/health_report.py --output reports/health.json
bash scripts/network_diagnostics.sh --offline
```

The last command tests localhost TCP port 22, and `--offline` omits internet-dependent route/DNS checks. To test internet connectivity, run the same script **without** `--offline`.

To demonstrate a second local network service, in **Terminal 1**:

```bash
bash scripts/start_local_http.sh 8080
```

Then, in **Terminal 2**:

```bash
bash scripts/network_diagnostics.sh --offline --host 127.0.0.1 --port 8080 \
  --http-url http://127.0.0.1:8080/
```

The HTTP demo is intentionally bound to `127.0.0.1`. It is **not reachable from the host laptop or internet** without deliberately changing the configuration. To stop, press Ctrl-C in Terminal 1.

## SSH key-based access (optional, but recommended)

First, create a public/private key pair **on the client laptop**, not on the server, if you do not already have one:

```bash
ssh-keygen -t ed25519 -C "ubuntu-lab" -f ~/.ssh/ubuntu_lab
```

Copy **only the public** `ubuntu_lab.pub` file into the VM using a safe transfer method (e.g. `scp` or VM shared folder), then on the Ubuntu VM:

```bash
sudo bash scripts/add_ssh_public_key.sh \
  --user YOUR_UBUNTU_USERNAME \
  --public-key-file /path/to/ubuntu_lab.pub
```

Test from the client, adjusting VM IP and forwarding port as appropriate:

```bash
ssh -i ~/.ssh/ubuntu_lab YOUR_UBUNTU_USERNAME@VM_IP
```

**Do not disable SSH password authentication until you have verified a separate working key-based SSH session.** The bootstrap script does not change password authentication or firewall rules; see [Security notes](docs/security.md).

## Run tests

```bash
python3 -m unittest discover -s tests -v
bash -n scripts/*.sh
```

Unit tests mock system calls and cover report generation, TCP success/failure, error handling, output validation, and permissions. Integration tests also start a local-only HTTP service and check successful and failed network diagnostics. CI runs these checks. Passing CI is **not** evidence that SSH/VM integration has been tested.

## Example health report

```bash
python3 src/health_report.py --tcp-host 127.0.0.1 --tcp-port 22 \
  --output reports/health.json
cat reports/health.json
```

Reports are intentionally ignored by Git because they can contain interface addresses, hostnames, and other machine information. Never commit private keys, `authorized_keys`, or sensitive logs.

## Project files

```text
scripts/bootstrap_ubuntu.sh       Install required Ubuntu utilities
scripts/add_ssh_public_key.sh     Append a verified SSH public key
scripts/network_diagnostics.sh    Network troubleshooting CLI
scripts/start_local_http.sh       Run a local-only HTTP test service
src/health_report.py              Read-only JSON health report
site/index.html                   Local service demo page
docs/vm-setup.md                  VM networking and SSH instructions
docs/troubleshooting-playbook.md  Symptom → command → interpretation
docs/security.md                  Hardening and safety guidance
docs/automation.md                Opt-in cron automation
docs/validation-checklist.md      Test plan and evidence collection
tests/test_health_report.py       Mock-based Python tests
tests/test_network_diagnostics.py Local HTTP/TCP integration tests
docs/test-results.md              Actual automated test status
.github/workflows/tests.yml       GitHub Actions CI
```

## Portfolio / CV wording (only after VM validation)

> Built an Ubuntu server administration lab featuring SSH key-based access, network diagnostics (TCP, DNS, routing), and a local HTTP service. Automated host health reporting with Bash/Python and documented troubleshooting workflows and test results.

**Important:** This project is a lab, not a production infrastructure management system. Do not describe an untested feature as implemented or validated. Follow the validation checklist and add screenshots/command output **after** performing real VM tests.

## License

MIT License (see `LICENSE`).
