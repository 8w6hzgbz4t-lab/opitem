#!/usr/bin/env python3
"""Compile active Luau sources and execute the place's real session test suite.

The Luau CLI does not provide Roblox's `script` or Instance-based `require`.
This runner supplies only ModuleScript path references and a module cache; it
does not rewrite Lua syntax, stub the session logic, or execute game startup.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import subprocess
import tempfile


PROTECTED_MODULES = (
    "Core.lua",
    "TransactionCore.lua",
    "PowerCatalog.lua",
    "Tests.lua",
)


def lua_string(value: str) -> str:
    """Encode source verbatim, even if it contains Lua long-string delimiters."""
    delimiter = "="
    while f"]{delimiter}]" in value:
        delimiter += "="
    # Lua discards a newline directly following an opening long bracket.
    # Prefix a harmless character, then remove it at runtime to retain source.
    return f"string.sub([{delimiter}[x{value}]{delimiter}], 2)"


def build_harness(
    root: Path,
    syntax_roots: list[Path],
    checks: list[Path],
    baseline: Path | None,
) -> str:
    sources: dict[str, str] = {}
    module_paths: dict[str, str] = {}
    for path in sorted(root.rglob("*.lua")):
        relative = path.relative_to(root).as_posix()
        sources[relative] = path.read_text(encoding="utf-8")
        module_paths[relative] = relative[:-4]
    if "Tests.lua" not in sources:
        raise ValueError(f"No actual Tests.lua suite found in {root}")

    for index, extra_root in enumerate(syntax_roots):
        for path in sorted(extra_root.rglob("*.lua")):
            # Extra roots are syntax-only: do not expose fake Roblox parents.
            key = f"@extra{index}/{path.relative_to(extra_root).as_posix()}"
            sources[key] = path.read_text(encoding="utf-8")

    check_keys = []
    for index, check in enumerate(checks):
        key = f"@checks/{index}/{check.name}"
        sources[key] = check.read_text(encoding="utf-8")
        check_keys.append(key)

    if checks and baseline:
        for name in ("Catalog.lua", "ExpandedCatalog.lua"):
            key = f"@baseline/{name}"
            sources[key] = (baseline / name).read_text(encoding="utf-8")
            module_paths[key] = f"__Baseline/{name[:-4]}"

    lines = ["local sources = {}", "local modulePaths = {}", "local checkKeys = {}"]
    for name, source in sources.items():
        lines.append(f"sources[{lua_string(name)}] = {lua_string(source)}")
    for name, module_path in module_paths.items():
        lines.append(f"modulePaths[{lua_string(name)}] = {lua_string(module_path)}")
    for key in check_keys:
        lines.append(f"table.insert(checkKeys, {lua_string(key)})")

    lines.append(
        r'''
local compiled, failures = {}, {}
local names = {}
for name in pairs(sources) do table.insert(names, name) end
table.sort(names)
for _, name in ipairs(names) do
    local chunk, err = loadstring(sources[name], "@" .. name)
    if chunk then
        compiled[name] = chunk
    else
        table.insert(failures, "SYNTAX FAIL " .. name .. ": " .. tostring(err))
    end
end
print(string.format("SYNTAX %d/%d files compiled", #names - #failures, #names))

local packageRoot = {Name = "OPItemV2"}
local nodes = {}
for _, name in ipairs(names) do
    if modulePaths[name] then
        local current = packageRoot
        local parts = string.split(modulePaths[name], "/")
        for index, part in ipairs(parts) do
            if not current[part] then
                current[part] = {Name = part, Parent = current}
            end
            current = current[part]
            if index == #parts then
                current.__modulePath = name
                nodes[name] = current
            end
        end
    end
end

local cache, loading = {}, {}
local globals = getfenv()
-- Art metadata modules bind constructors/constants at load time. These values
-- allow supports()/Items checks, without creating or simulating any geometry.
-- Geometry is independently exercised by tools/record_art.lua in the Lua mock.
local metadataGlobals = {
    Vector3 = {new = function(x, y, z) return {X=x or 0, Y=y or 0, Z=z or 0} end},
    CFrame = {
        new = function(...) return {...} end,
        Angles = function(...) return {...} end,
    },
    Color3 = {
        fromRGB = function(r,g,b) return {R=r/255,G=g/255,B=b/255} end,
        new = function(r,g,b) return {R=r,G=g,B=b} end,
    },
    Enum = setmetatable({}, {__index=function(self, category)
        local values=setmetatable({}, {__index=function(_, key) return category.."."..key end})
        rawset(self, category, values)
        return values
    end}),
}
local function environment(node)
    return setmetatable({script=node}, {__index=function(_, key)
        if metadataGlobals[key] ~= nil then return metadataGlobals[key] end
        return globals[key]
    end})
end
local function moduleRequire(module)
    assert(type(module) == "table" and module.__modulePath,
        "Tests requested an unsupported require target")
    local name = module.__modulePath
    if cache[name] ~= nil then return cache[name] end
    assert(not loading[name], "Circular module require: " .. name)
    local chunk = compiled[name]
    assert(chunk, "Module did not compile: " .. name)
    loading[name] = true
    local env=environment(nodes[name]);env.require=moduleRequire
    setfenv(chunk, env)
    local ok, result = pcall(chunk)
    loading[name] = nil
    assert(ok, "Module failed: " .. name .. ": " .. tostring(result))
    assert(result ~= nil, "Module returned nil: " .. name)
    cache[name] = result
    return result
end

local ok, result = pcall(function()
    local suite = moduleRequire(packageRoot.Tests)
    assert(type(suite) == "function", "Actual Tests.lua did not return a suite")
    return suite(packageRoot)
end)
if not ok then
    table.insert(failures, "SESSION FAIL " .. tostring(result))
else
    local expected = {"delivery", "refunds", "auctions", "theft", "powers", "exodia"}
    for _, name in ipairs(expected) do
        assert(type(result[name]) == "string" and #result[name] > 0,
            "Actual suite did not report group: " .. name)
        print("SESSION PASS " .. name .. ": " .. result[name])
    end
    print(string.format("SESSION %d actual repository test groups passed", #expected))
end
for _, name in ipairs(checkKeys) do
    local ok, result = pcall(function()
        local chunk=assert(compiled[name], "Check did not compile: "..name)
        local env=environment({Parent=packageRoot});env.require=moduleRequire
        setfenv(chunk,env)
        local check=chunk()
        assert(type(check)=="function", "Check must return a function: "..name)
        return check(packageRoot,moduleRequire,packageRoot.__Baseline)
    end)
    if ok then
        print("UPGRADE PASS "..name..": "..tostring(result))
    else
        table.insert(failures,"UPGRADE FAIL "..name..": "..tostring(result))
    end
end
if #failures > 0 then error(table.concat(failures, "\n"), 0) end
'''
    )
    return "\n".join(lines)


def run_root(
    luau: Path,
    root: Path,
    syntax_roots: list[Path],
    checks: list[Path] | None = None,
    baseline: Path | None = None,
) -> bool:
    print(f"CHECK ROOT {root}", flush=True)
    try:
        harness = build_harness(root, syntax_roots, checks or [], baseline)
    except (OSError, ValueError) as error:
        print(f"HARNESS FAIL {error}", flush=True)
        return False
    with tempfile.TemporaryDirectory(prefix="opitem-game-checks-") as task_dir:
        harness_path = Path(task_dir) / "checks.lua"
        harness_path.write_text(harness, encoding="utf-8")
        completed = subprocess.run(
            [str(luau), str(harness_path)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            check=False,
        )
    print(completed.stdout.rstrip(), flush=True)
    print(f"LUAU EXIT {completed.returncode}", flush=True)
    return completed.returncode == 0


def check_preservation(baseline: Path, root: Path) -> bool:
    passed = True
    for name in PROTECTED_MODULES:
        try:
            original = hashlib.sha256((baseline / name).read_bytes()).digest()
            current = hashlib.sha256((root / name).read_bytes()).digest()
        except OSError as error:
            print(f"PRESERVATION FAIL {name}: {error}", flush=True)
            passed = False
            continue
        if original != current:
            print(f"PRESERVATION FAIL {name}: source changed", flush=True)
            passed = False
        else:
            print(f"PRESERVATION PASS {name}", flush=True)
    return passed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("roblox/game"))
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--luau", type=Path, required=True)
    parser.add_argument(
        "--syntax-root", type=Path, action="append", default=[],
        help="Additional directory containing Luau files to compile only",
    )
    parser.add_argument(
        "--check", type=Path, action="append", default=[],
        help="Additional native Luau check returning function(package, require, baseline)",
    )
    args = parser.parse_args()
    root = args.root.resolve()
    luau = args.luau.resolve()
    syntax_roots = [path.resolve() for path in args.syntax_root]
    checks = [path.resolve() for path in args.check]
    baseline = args.baseline.resolve() if args.baseline else None
    passed = True
    if args.baseline:
        passed = run_root(luau, baseline, []) and passed
        passed = check_preservation(baseline, root) and passed
    passed = run_root(luau, root, syntax_roots, checks, baseline) and passed
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
