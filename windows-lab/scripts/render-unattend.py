#!/usr/bin/env python3
"""Render the intentionally untracked answer file for the Windows Packer lab."""
import os
from pathlib import Path
from xml.sax.saxutils import escape
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parent.parent
password = os.environ.get("PKR_VAR_admin_password", "")
if not password:
    raise SystemExit("Set PKR_VAR_admin_password in your shell (do not commit it).")

template = (root / "Autounattend.xml.template").read_text(encoding="utf-8")
if template.count("@@ADMIN_PASSWORD@@") != 2:
    raise SystemExit("Unexpected password placeholder count in template")

rendered = template.replace("@@ADMIN_PASSWORD@@", escape(password))
ET.fromstring(rendered)
output = root / "Autounattend.xml"
fd = os.open(output, os.O_CREAT | os.O_WRONLY | os.O_TRUNC, 0o600)
with os.fdopen(fd, "w", encoding="utf-8") as f:
    f.write(rendered)
os.chmod(output, 0o600)
print("Generated untracked Autounattend.xml (mode 0600)")
