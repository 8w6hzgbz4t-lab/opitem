#!/usr/bin/env python3
"""Run the actual developer-menu LocalScript with a small offline GUI/event adapter.

This exercises the shipped source verbatim. It does not simulate Studio rendering,
network transport or Roblox physics; it checks UI requests, authorization gates,
input cleanup, metadata selection and exact-command confirmation behavior.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

from run_game_checks import lua_string


def main() -> int:
    repository = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=repository / "roblox/v74-game")
    parser.add_argument("--luau", type=Path, help="Path to the official Luau CLI")
    parser.add_argument("--report", type=Path, help="Optional JSON verification report")
    args = parser.parse_args()
    source_path = args.root.resolve() / "AdminClient.lua"
    test_path = repository / "tests/v74_admin_client.lua"
    source_bytes = source_path.read_bytes()
    test_bytes = test_path.read_bytes()
    executable = args.luau
    if executable is None:
        installed = shutil.which("luau")
        executable = Path(installed) if installed else repository.parent / ".cache/opitem-tools/luau"
    if not executable.is_file():
        parser.error("Official Luau CLI not found. Supply --luau /path/to/luau.")
    harness = (
        "-- Source is embedded without rewriting the production LocalScript.\n"
        "local SOURCE = " + lua_string(source_bytes.decode("utf-8")) + "\n"
        + test_bytes.decode("utf-8")
    )
    with tempfile.TemporaryDirectory(prefix="opitem-admin-client-") as directory:
        harness_path = Path(directory) / "admin-client-checks.lua"
        harness_path.write_text(harness, encoding="utf-8")
        result = subprocess.run(
            [str(executable.resolve()), str(harness_path)],
            text=True, capture_output=True, check=False,
        )
    if result.stdout:
        print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, end="")
    match = re.search(r"AdminClient UI behavior passed (\d+) assertions", result.stdout)
    passed = result.returncode == 0 and match is not None
    report = {
        "schemaVersion": 1,
        "status": "passed" if passed else "failed",
        "source": str(source_path),
        "sourceSha256": hashlib.sha256(source_bytes).hexdigest(),
        "testSha256": hashlib.sha256(test_bytes).hexdigest(),
        "assertions": int(match.group(1)) if match else 0,
        "runtime": "official Luau CLI; offline GUI/event adapter",
        "limitations": "Studio rendering, network transport and physics are not exercised.",
    }
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    return 0 if passed else (result.returncode or 1)


if __name__ == "__main__":
    raise SystemExit(main())
