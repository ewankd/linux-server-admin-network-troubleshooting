# Validation checklist

**Status: VM integration tests NOT YET RUN.** The items below are instructions for manual verification on a real Ubuntu VM, not claims of completed work.

## Environment to record

- [ ] Ubuntu release (`lsb_release -a` or `cat /etc/os-release`)
- [ ] Hypervisor (VirtualBox / VMware / other)
- [ ] VM adapters (NAT / host-only) and host/guest addressing model
- [ ] Date, environment, and script commit ID

## Functional checks

- [ ] `sudo bash scripts/bootstrap_ubuntu.sh` installs packages without errors
- [ ] `systemctl is-active ssh` returns `active`
- [ ] `ss -lnt` shows SSH listening on expected port
- [ ] Valid `.pub` key is added to an existing Linux user
- [ ] A **new** SSH session authenticates with that key from the client
- [ ] Re-running key script does not duplicate the entry
- [ ] `bash scripts/network_diagnostics.sh --offline` succeeds with local SSH
- [ ] `bash scripts/network_diagnostics.sh` reports default route and DNS as expected for chosen VM mode
- [ ] Local HTTP demo responds to `curl http://127.0.0.1:8080/`
- [ ] A stopped HTTP demo yields a failed network diagnostic with nonzero exit
- [ ] `python3 src/health_report.py --output reports/health.json` creates valid JSON
- [ ] Optional cron entry produces a fresh report at scheduled time, if installed
- [ ] `python3 -m unittest discover -s tests -v` passes on Ubuntu

## What to capture

For each meaningful scenario, save a **redacted** command and result screenshot or terminal transcript. Note exact failure and the correction. Do not upload private keys, IPs you consider sensitive, usernames, or logs containing secrets.

**Only after completing these checks** update README/CV claims with observed results and any actual metrics.
