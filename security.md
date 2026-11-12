# Lab security notes

- Keep the VM in NAT/host-only mode while learning. Avoid opening ports on a public IP.
- Keep the SSH **private key** on the client. Only transfer its `.pub` file to the guest.
- `add_ssh_public_key.sh` appends a valid public key and uses restrictive `.ssh` and `authorized_keys` permissions. It does not change login authentication policies.
- Do not disable password authentication until key login has worked from a **separate terminal session**. Changing remote SSH policies without an alternative access path can lock you out.
- If you elect to harden SSH later, back up `/etc/ssh/sshd_config`, understand the order of `/etc/ssh/sshd_config.d/*.conf`, validate with `sudo sshd -t`, and only then reload (`sudo systemctl reload ssh`). Consider `PermitRootLogin no` and `PasswordAuthentication no` once your verified key-based access is operational.
- The built-in HTTP demo binds to `127.0.0.1` rather than all VM interfaces, and is not a production web server.
- Do not push generated reports, credentials, private keys, authorized key lists, SSH host keys, or production configurations to GitHub.
- The scripts intentionally do not edit UFW/iptables, disable authentication, or change network routes or Netplan.
- A passing unit test or CI run is **not** evidence that a VM's SSH connectivity was tested.
