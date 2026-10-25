#!/usr/bin/env python3
"""Capture Linux environment without device serials or account identifiers."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[2]


def command(args):
    if not shutil.which(args[0]):
        return {"available": False}
    try:
        result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True,
                                timeout=15, check=False)
        return {"available": True, "exit_code": result.returncode,
                "stdout": result.stdout.strip(), "stderr": result.stderr.strip()}
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"available": True, "error": str(error)}


def read_file(path):
    try:
        return Path(path).read_text().strip()
    except OSError:
        return None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "reports/environment.json")
    args = parser.parse_args()
    godot = os.environ.get("GODOT_BIN", "/home/otavio/Downloads/Apps/Godot_v4.7.2-stable_linux.x86_64")
    record = {
        "captured_utc": datetime.now(timezone.utc).isoformat(),
        "os_release": read_file("/etc/os-release"),
        "kernel": command(["uname", "-srmo"]),
        "session": {key: os.environ.get(key) for key in
                    ("XDG_SESSION_TYPE", "DISPLAY", "WAYLAND_DISPLAY")},
        "hardware": {key: read_file(f"/sys/class/dmi/id/{key}") for key in
                     ("sys_vendor", "product_name", "product_version")},
        "cpu": command(["lscpu"]),
        "memory": read_file("/proc/meminfo"),
        "pci": command(["lspci", "-nnk"]),
        "opengl_probe": command(["glxinfo", "-B"]),
        "godot": command([godot, "--version"]),
        "commit": command(["git", "rev-parse", "HEAD"]),
        "working_tree": command(["git", "status", "--short"]),
        "note": "glxinfo descreve o contexto da sonda, não comprova a GPU do jogo. "
                "Registrar também o renderer no log da execução gráfica da Godot."
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n")
    print(args.output)


if __name__ == "__main__":
    main()
