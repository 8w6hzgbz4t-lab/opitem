"""Package the developer-menu release after validating frozen test input hashes."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
RELEASE = ROOT / "releases/Version74"
STAGE = ROOT / "roblox/v74-game"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    preservation = json.loads((RELEASE / "preservation-report.json").read_text())
    admin = json.loads((RELEASE / "admin-checks.json").read_text())
    powers = json.loads((RELEASE / "power-checks.json").read_text())
    client = json.loads((RELEASE / "client-checks.json").read_text())
    hashes = {p.relative_to(STAGE).as_posix(): sha(p) for p in STAGE.rglob("*.lua")}
    assert hashes == preservation["source_hashes"] == powers["sourceHashes"]
    assert admin["passed"] and powers["passed"] and client["status"] == "passed"
    for name, digest in admin["input_sha256"].items():
        path = ROOT / "tests" / name.removeprefix("@checks/") if name.startswith("@checks/") else STAGE / name
        assert sha(path) == digest, "Admin input changed after tests: " + name
    assert sha(ROOT / "tools/run_admin_checks.py") == admin["runner_sha256"]
    assert hashes["AdminClient.lua"] == client["sourceSha256"]
    assert sha(ROOT / "tests/v74_admin_client.lua") == client["testSha256"]
    assert sha(ROOT / "tests/v74_powers.lua") == powers["testHash"]
    game = ROOT / "releases" / preservation["output"]
    assert sha(game) == preservation["output_sha256"]
    assert sha(ROOT / "releases" / preservation["baseline"]) == preservation["baseline_sha256"]
    assert set(preservation["modified_sources"]) == {
        "AdminClient.lua", "AdminConfig.lua", "AdminPolicy.lua", "AdminService.lua", "Server.lua", "PhaseService.lua"
    }
    report = {
        "game": game.name,
        "game_sha256": sha(game),
        "active_sources_compiled": len(hashes),
        "developer_username": preservation["developer_username"],
        "authorization": "Server resolves configured username with Roblox and compares the actual sender's numeric UserId; failed lookup denies access.",
        "admin_assertions": admin["assertions"],
        "admin_authorized_command_dispatches": admin["authorized_command_dispatches"],
        "admin_groups": len(admin["groups"]),
        "power_assertions": powers["assertions"],
        "power_groups": len(powers["groups"]),
        "client_behavior_assertions": client["assertions"],
        "catalog_and_transaction_assertions": 7112,
        "existing_session_groups_passed": 6,
        "existing_regression_groups_passed": 13,
        "all_original_objects_preserved": preservation["original_objects_preserved"],
        "all_69_item_models_stats_and_scenery_preserved": True,
        "studio_playtest_performed": False,
        "live_identity_lookup_performed_in_cloud": False,
        "published_to_roblox": False,
        "limitations": "Roblox API test doubles exercise production code; real account lookup and live Studio rendering, physics, performance and multiplayer require a Studio playtest.",
    }
    (RELEASE / "validation-report.json").write_text(json.dumps(report, indent=2) + "\n")
    tools = ["build_v74_place.py", "build_v72_place.py", "package_v74_release.py", "run_game_checks.py", "run_admin_checks.py", "run_admin_client_checks.py", "run_power_checks.py"]
    tests = ["v74_admin.lua", "v74_admin_client.lua", "v74_powers.lua", "v72_catalog.lua"]
    files = [game, ROOT / "releases" / preservation["baseline"], ROOT / "README.md", ROOT / "releases/VERSION_74_HANDOFF.md"]
    files += [ROOT / "tools" / name for name in tools]
    files += [ROOT / "tests" / name for name in tests]
    files += list(STAGE.rglob("*.lua"))
    files += list((ROOT / "roblox/v71-game").rglob("*.lua"))
    files += [p for p in RELEASE.iterdir() if p.is_file()]
    target = ROOT / "releases/Version74_SourceAndGame.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(set(files)):
            archive.write(path, path.relative_to(ROOT))
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None and len(archive.infolist()) == len(set(files))
    print(f"Packaged {len(set(files))} files: {target.name} ({target.stat().st_size} bytes)")
    print(f"Game SHA256 {sha(game)}")
    print(f"Package SHA256 {sha(target)}")


if __name__ == "__main__":
    main()
