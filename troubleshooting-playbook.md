# Network troubleshooting playbook

Use this order: **interface → addressing → route → DNS → TCP → service → firewall → logs**. Execute commands on the *Ubuntu VM* unless otherwise indicated.

| Symptom | Check | Typical interpretation / next action |
|---|---|---|
| No interface address | `ip -brief address` | Confirm VM adapter attached, interface UP, DHCP/static config |
| No path outside VM | `ip -4 route` | No default route may be expected on a host-only VM |
| Cannot reach gateway | `ip route get 1.1.1.1`; `ping -c 2 GATEWAY_IP` | Validate route/adapter. A blocked ICMP response alone does not prove routing failure |
| Names fail, IP works | `getent ahostsv4 example.com`; `resolvectl status` | Suspect DNS config or inaccessible resolver |
| Local SSH port closed | `ss -lnt | grep ':22 '`; `sudo systemctl status ssh` | Check OpenSSH installation and listener status |
| SSH authentication fails | `ssh -vvv -i KEY USER@VM_IP` (run on client) | Check username, public/private key pairing, file permissions, server logs |
| Remote SSH times out | `ip -brief address`; `sudo ufw status`; `ss -lnt` | Check IP/VM forwarding/firewall/service; do not disable firewall indiscriminately |
| SSH service exits | `sudo journalctl -u ssh -n 50 --no-pager`; `sudo sshd -t` | Fix syntax/configuration then restart only after validation |
| HTTP demo inaccessible | `curl -v http://127.0.0.1:8080/` | Start `scripts/start_local_http.sh`; it is loopback-only by design |
| Disk nearly full | `df -h /`; `du -sh ~/...` | Find growth source; avoid deleting unknown system data |

## Lab scenarios to reproduce

### Scenario A: Service not listening

1. With the HTTP demo **stopped**, run:
   `bash scripts/network_diagnostics.sh --offline --host 127.0.0.1 --port 8080 --http-url http://127.0.0.1:8080/`
2. Observe TCP/HTTP failures and nonzero process exit.
3. Start `bash scripts/start_local_http.sh 8080` in a second terminal.
4. Run the same checks again. Expect TCP/HTTP success.
5. Capture **redacted** terminal output for your portfolio.

### Scenario B: DNS missing but local service healthy

1. Run an online check: `bash scripts/network_diagnostics.sh --domain example.com`.
2. Compare with `--offline`; on a host-only VM the offline check may pass while DNS/default-route tests fail.
3. Review `ip -4 route`, `resolvectl status`, and adapter mode. **Do not** modify production DNS settings for a lab exercise.

### Scenario C: Wrong TCP port

1. Run `bash scripts/network_diagnostics.sh --offline --port 22222`.
2. Compare with the expected SSH port 22; inspect `ss -lnt`.
3. Correct the target port rather than changing a healthy SSH service unnecessarily.

## Evidence to keep

Record exact commands, environment (Ubuntu release, hypervisor and network mode), observed output, root cause, and successful fix. Remove usernames, private addresses if sensitive, hostnames, keys, passwords, and tokens before publication.
