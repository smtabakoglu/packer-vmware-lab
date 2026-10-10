#!/usr/bin/env bash
# Run from Kali/Linux. Requires packer, VMware Workstation, Python 3, sha256sum.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

iso_path="${1:-${ISO_PATH:-$HOME/Downloads/Server2019.iso}}"
if [[ ! -f "$iso_path" ]]; then
  echo "ISO not found: $iso_path" >&2
  exit 1
fi

if [[ -z "${PKR_VAR_admin_password:-}" ]]; then
  read -r -s -p 'Temporary LAB Administrator password: ' PKR_VAR_admin_password
  printf '\n'
  export PKR_VAR_admin_password
fi

cleanup() {
  rm -f -- Autounattend.xml
  unset PKR_VAR_admin_password
}
trap cleanup EXIT

export PKR_VAR_iso_path
PKR_VAR_iso_path="$(realpath "$iso_path")"
export PKR_VAR_iso_checksum="sha256:$(sha256sum "$iso_path" | cut -d ' ' -f 1)"

python3 scripts/render-unattend.py
packer init .
packer fmt .
packer validate .
packer build -on-error=abort .
