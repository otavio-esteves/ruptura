#!/usr/bin/env python3
"""Godot local validation. Run once at a time against this workspace."""

import argparse
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_GODOT = "/home/otavio/Downloads/Apps/Godot_v4.7.2-stable_linux.x86_64"


def run(command, timeout=120):
    result = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, check=False, timeout=timeout)
    print(result.stdout, end="", flush=True)
    if result.returncode or re.search(r"(?:SCRIPT ERROR:|ERROR:|Parse Error:)", result.stdout):
        raise SystemExit(result.returncode or 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("import", "check", "export-linux"))
    parser.add_argument("--output", type=Path, default=ROOT / "builds/linux/ruptura.x86_64")
    args = parser.parse_args()
    godot = os.environ.get("GODOT_BIN", DEFAULT_GODOT)
    try:
        version = subprocess.check_output([godot, "--version"], text=True, timeout=15).strip()
        if not version.startswith("4.7.2.stable."):
            raise SystemExit(f"Engine incorreta: {version}; esperado 4.7.2.stable.")
        if not (ROOT / "project.godot").is_file():
            raise SystemExit("project.godot ainda não foi integrado.")
        command = [godot, "--headless", "--path", str(ROOT)]
        if args.action in ("import", "check"):
            run(command + ["--editor", "--import"])
        if args.action == "check":
            run(command + ["--quit-after", "120", "--", "--auto-arena"])
            run(command + ["--script", "res://tests/player_smoke.gd"])
            run(command + ["--script", "res://tests/main_smoke.gd"])
        elif args.action == "export-linux":
            # The engine reports absent/mismatched templates; never download implicitly.
            args.output.parent.mkdir(parents=True, exist_ok=True)
            run(command + ["--export-release", "Linux", str(args.output.resolve())], timeout=180)
            args.output.chmod(args.output.stat().st_mode | 0o111)
    except (OSError, subprocess.SubprocessError) as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main()
