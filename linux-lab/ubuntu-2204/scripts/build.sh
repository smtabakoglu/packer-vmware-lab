#!/usr/bin/env bash
# Local Ubuntu 22.04.2 VMware lab build. Run from Kali/Linux.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
umask 077

iso_path="${1:-${ISO_PATH:-$HOME/Downloads/ubuntu-22.04.2-live-server-amd64.iso}}"
if [[ ! -f "$iso_path" ]]; then
  echo "Ubuntu Server ISO not found: $iso_path" >&2
  exit 1
fi

if [[ -z "${PKR_VAR_ssh_password:-}" ]]; then
  read -r -s -p 'Temporary packer SSH password: ' PKR_VAR_ssh_password
  printf '\n'
  export PKR_VAR_ssh_password
fi
if [[ -z "${PKR_VAR_ssh_password:-}" ]]; then
  echo 'Password cannot be blank.' >&2
  exit 1
fi
# The Packer shutdown command contains a single-quoted password shell literal.
if [[ "$PKR_VAR_ssh_password" == *"'"* ]]; then
  echo "Use a temporary lab password without a single quote (')." >&2
  exit 1
fi

cleanup() {
  rm -f -- http/user-data
  unset PKR_VAR_ssh_password
}
trap cleanup EXIT

export PKR_VAR_iso_path="$(realpath "$iso_path")"
export PKR_VAR_iso_checksum="sha256:$(sha256sum "$iso_path" | awk '{print $1}')"

python3 scripts/render-user-data.py
packer init .
packer fmt .
packer validate .
packer build -timestamp-ui -on-error=abort .
