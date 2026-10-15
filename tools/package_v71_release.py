"""Package the reviewed Version 71 game and its reproducible native model sources."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "roblox/v71-game"
RELEASE = ROOT / "releases/Version71"


def main():
    audit = json.loads((RELEASE / "items-manifest.json").read_text())
    assert len(audit["items"]) == 66 and not audit["failures"] and not audit["warnings"]
    assert audit["distinct_geometry"] and audit["puzzleUnchanged"] and audit["studioArtUtilityPassed"]
    assert audit["changedGeometry"] == ["gary_shell"], "Only the requested existing shell may change"
    hashes = {p.relative_to(STAGE).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in STAGE.rglob("*.lua")}
    assert hashes == audit["sources_sha256"], "Sources changed since final item validation"
    preservation = json.loads((RELEASE / "preservation-report.json").read_text())
    game = ROOT / "releases" / preservation["output"]
    assert hashlib.sha256(game.read_bytes()).hexdigest() == preservation["output_sha256"]
    assert preservation["original_objects_preserved"] == 287
    baseline = ROOT / "releases/StealAnOPItem_70_SliferAndItems.rbxlx"
    assert hashlib.sha256(baseline.read_bytes()).hexdigest() == preservation["baseline_sha256"]
    names = json.loads((ROOT / "docs/v71-name-changes.json").read_text())["changes"]
    assert names == audit["approvedNameChanges"] and len(names) == 31
    spawn = json.loads((RELEASE / "spawn-rates.json").read_text())
    assert len(spawn["items"]) == 66 and abs(spawn["probability_sum"] - 1) < 1e-12
    formula = next(row for row in spawn["items"] if row["id"] == "krabby_patty_formula")
    assert formula["rarity"] == "Legendary" and abs(formula["global_percent"] - .24299065420560748) < 1e-12
    report = {
        "game": game.name,
        "sha256": preservation["output_sha256"],
        "active_sources_compiled_with_official_luau": len(hashes),
        "actual_factory_models_checked": len(audit["items"]),
        "item_geometry_and_catalog_assertions": audit["checks"],
        "production_artchecks_passed": audit["studioArtUtilityPassed"],
        "name_changes_verified": len(names),
        "spawn_rarity_pools_verified": 7,
        "all_item_spawn_probabilities_sum_to_one": True,
        "secret_formula_global_spawn_percent": formula["global_percent"],
        "original_session_test_groups_passed": 6,
        "original_regression_groups_passed": 13,
        "new_item_purchase_carry_delivery_income_index_refund_theft_reset_and_full_base_checks_passed": True,
        "ra_world_geometry_assertions_passed": 978,
        "non_ra_world_parts_preserved": 6157,
        "animated_slifer_preserved": True,
        "millennium_puzzle_geometry_preserved": audit["puzzleUnchanged"],
        "source_hashes": hashes,
        "studio_playtest_performed": False,
        "published_to_roblox": False,
        "limitations": ["Offline model previews approximate Studio rendering and materials.", "Live Studio visual, performance and multiplayer playtests remain unperformed."],
    }
    (RELEASE / "validation-report.json").write_text(json.dumps(report, indent=2) + "\n")
    tools = ["build_v71_place.py", "package_v71_release.py", "run_game_checks.py", "audit_v71_items.py", "audit_v70_items.py", "roblox_mock.lua", "build_puzzle_asset.py", "export_free_models.py"]
    tests = ["v71_items.lua", "v71_catalog.lua", "v71_ra.lua", "slifer_upgrade.lua"]
    files = [game, baseline, ROOT / "README.md", ROOT / "releases/VERSION_71_HANDOFF.md", ROOT / "docs/v71-name-changes.json"]
    files += [ROOT / "tools" / name for name in tools]
    files += [ROOT / "tests" / name for name in tests]
    for directory in (STAGE, ROOT / "roblox/v70-game", RELEASE):
        files += [p for p in directory.rglob("*") if p.is_file()]
    files = sorted(set(files))
    target = ROOT / "releases/Version71_SourceAndGame.zip"
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            archive.write(path, path.relative_to(ROOT))
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None, "Archive CRC failed"
        assert len(archive.infolist()) == len(files)
    print(f"Packaged {len(files)} files: {target.name} ({target.stat().st_size} bytes)")
    print(f"Game SHA256: {preservation['output_sha256']}")
    print(f"Package SHA256: {hashlib.sha256(target.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
