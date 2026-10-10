#!/usr/bin/env python3
"""Generate ignored cloud-init user-data with a salted SHA-512 password hash."""
import os
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
template = root / "http" / "user-data.template"
output = root / "http" / "user-data"

password = os.environ.get("PKR_VAR_ssh_password", "")
if not password:
    raise SystemExit("PKR_VAR_ssh_password must be set")

result = subprocess.run(
    ["openssl", "passwd", "-6", "-stdin"],
    input=password + "\n",
    text=True,
    capture_output=True,
    check=True,
)
password_hash = result.stdout.strip()
if not password_hash.startswith("$6$"):
    raise SystemExit("OpenSSL did not return a SHA-512 crypt hash")

body = template.read_text(encoding="utf-8")
placeholder = "__SHA512_PASSWORD_HASH__"
if body.count(placeholder) != 1:
    raise SystemExit("Expected exactly one hash placeholder")

fd = os.open(output, os.O_CREAT | os.O_WRONLY | os.O_TRUNC, 0o600)
try:
    os.fchmod(fd, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(body.replace(placeholder, password_hash))
except BaseException:
    output.unlink(missing_ok=True)
    raise
print("Generated ignored http/user-data with a SHA-512 password hash")
