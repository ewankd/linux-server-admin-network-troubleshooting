# Testing status

Automated checks were run in a Linux container during project creation. These results verify the local scripts but **do not** establish that a separate Ubuntu Server VM, SSH key login, or a hypervisor network was configured.

| Test | Observed result |
|---|---|
| `python3 -m unittest discover -s tests -v` | PASS (Python unit tests and local TCP/HTTP integration tests) |
| `bash -n scripts/*.sh` | PASS (shell syntax) |
| `python3 -m compileall -q src tests` | PASS (Python syntax) |
| Local HTTP server started on loopback, then TCP/HTTP diagnostic run | PASS |
| Same TCP diagnostic after stopping server | Expected FAIL with nonzero exit status (correct detection) |
| `python3 src/health_report.py --output reports/local-test.json` | Valid JSON generated; TCP status checked while local HTTP server was listening |

**Not tested here:** Ubuntu `apt-get` bootstrap, `systemctl` managed SSH daemon, SSH key login from a second computer, host-only/NAT VM networking, and cron execution. Use [validation-checklist.md](validation-checklist.md) to complete those items on an Ubuntu VM. No screenshot or proof of those steps is provided or implied.
