# Opt-in automated health reports

The Python program can run unattended because it uses the standard library and has no interactive prompts.

Run once on the Ubuntu VM:

```bash
mkdir -p "$HOME/linux-server-admin-network-troubleshooting/reports"
python3 "$HOME/linux-server-admin-network-troubleshooting/src/health_report.py" \
  --output "$HOME/linux-server-admin-network-troubleshooting/reports/health.json"
```

If and only if the repo is in that location, schedule the same read-only task every six hours with `crontab -e`. **Replace `YOUR_USER` with your actual Linux username**:

```cron
0 */6 * * * /usr/bin/python3 /home/YOUR_USER/linux-server-admin-network-troubleshooting/src/health_report.py --output /home/YOUR_USER/linux-server-admin-network-troubleshooting/reports/health.json
```

Confirm with `crontab -l` and examine the generated file after the first run. A single file is overwritten each run rather than generating unlimited logs. Remove the line to disable scheduling. The setup script **never edits crontab automatically**.

Privacy: `reports/` is Git-ignored. Keep this file private; it contains host and network information.
