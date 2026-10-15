#!/usr/bin/env python3
"""Validate the actual free native geometry pack, without Roblox or paid APIs.

texlua runs geometry/catalog/flight tests using the existing Roblox geometry
mock. The optional official Luau CLI additionally compiles every pack source
verbatim; no production syntax is rewritten by this runner.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]


def lua_string(value: str) -> str:
    delimiter = "="
    while f"]{delimiter}]" in value:
        delimiter += "="
    return f"string.sub([{delimiter}[x{value}]{delimiter}], 2)"


def compile_sources(luau: str) -> None:
    sources = sorted((ROOT / "roblox/free_models").glob("*.lua"))
    assert sources, "No native pack sources found"
    lines = ["local failures={}", "local total=0"]
    for path in sources:
        label = path.relative_to(ROOT).as_posix()
        lines.extend([
            "do",
            f"local chunk,err=loadstring({lua_string(path.read_text())},{lua_string('@'+label)})",
            f"if not chunk then table.insert(failures,{lua_string(label+': ')}..tostring(err)) end",
            "total=total+1",
            "end",
        ])
    lines.extend([
        'for _,message in ipairs(failures) do print("SYNTAX FAIL "..message) end',
        'assert(#failures==0,"Native pack Luau compilation failed")',
        'print(string.format("PASS: official Luau compiled %d native pack sources",total))',
    ])
    with tempfile.TemporaryDirectory(prefix="opitem-native-check-") as temporary:
        harness = Path(temporary) / "compile.luau"
        harness.write_text("\n".join(lines))
        subprocess.run([luau, str(harness)], cwd=ROOT, check=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luau", help="Official Luau CLI path for verbatim compilation")
    args = parser.parse_args()
    texlua = shutil.which("texlua")
    if not texlua:
        parser.error("texlua is required for offline geometry checks")
    luau = args.luau or shutil.which("luau")
    if luau:
        compile_sources(luau)
    else:
        print("SKIP: official Luau compilation (pass --luau PATH to enable)", flush=True)
    subprocess.run([texlua, "tests/free_models.lua"], cwd=ROOT, check=True)
    print("Offline checks do not simulate Roblox rendering, physics, or multiplayer.", flush=True)


if __name__ == "__main__":
    main()
