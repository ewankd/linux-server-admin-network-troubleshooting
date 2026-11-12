#!/usr/bin/env bash
# Safely append an existing SSH public key to a local Ubuntu account.
set -Eeuo pipefail

usage() {
  echo "Usage: $0 --user USERNAME --public-key-file /path/to/key.pub" >&2
  exit 2
}

USER_NAME=''
KEY_FILE=''
while (($#)); do
  case "$1" in
    --user) (($# >= 2)) || usage; USER_NAME=$2; shift 2 ;;
    --public-key-file) (($# >= 2)) || usage; KEY_FILE=$2; shift 2 ;;
    *) usage ;;
  esac
done
[[ -n $USER_NAME && -f $KEY_FILE ]] || usage
id "$USER_NAME" >/dev/null 2>&1 || { echo "Unknown user: $USER_NAME" >&2; exit 2; }
if [[ $EUID -ne 0 && $(id -un) != "$USER_NAME" ]]; then
  echo "Use sudo to modify a different user's account." >&2
  exit 2
fi
command -v ssh-keygen >/dev/null 2>&1 || { echo 'Install openssh-client.' >&2; exit 2; }
mapfile -t keys < "$KEY_FILE"
if ((${#keys[@]} != 1)) || [[ -z ${keys[0]} ]]; then
  echo 'Provide exactly one nonempty OpenSSH public key line.' >&2
  exit 2
fi
ssh-keygen -lf "$KEY_FILE" >/dev/null || { echo 'Invalid SSH public key.' >&2; exit 2; }
key=${keys[0]}
home_dir=$(getent passwd "$USER_NAME" | cut -d: -f6)
[[ -n $home_dir && -d $home_dir ]] || { echo 'User home directory missing.' >&2; exit 2; }
ssh_dir="$home_dir/.ssh"
[[ ! -L $ssh_dir ]] || { echo 'Refusing symlinked .ssh directory.' >&2; exit 2; }
auth_keys="$ssh_dir/authorized_keys"
if [[ $EUID -eq 0 ]]; then
  group_name=$(id -gn "$USER_NAME")
  install -d -m 700 -o "$USER_NAME" -g "$group_name" "$ssh_dir"
else
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"
fi
# Fail if the target is a symlink; do not follow a malicious redirection.
[[ ! -L $auth_keys ]] || { echo 'Refusing symlinked authorized_keys file.' >&2; exit 2; }
touch "$auth_keys"
if ! grep -Fqx -- "$key" "$auth_keys"; then
  printf '%s\n' "$key" >> "$auth_keys"
  echo 'Added public key.'
else
  echo 'Public key already present (no change).'
fi
chmod 600 "$auth_keys"
if [[ $EUID -eq 0 ]]; then
  chown "$USER_NAME:$(id -gn "$USER_NAME")" "$auth_keys"
fi
echo "Verify a separate SSH login as '$USER_NAME' before changing authentication settings."
