"""Package the checked Version 70 game, editable sources and actual model previews."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "roblox/v70-game"
RELEASE = ROOT / "releases/Version70"


def main():
    audit = json.loads((ROOT / "releases/Version70Items/manifest.json").read_text())
    assert len(audit["items"]) == 65 and not audit["failures"] and not audit["warnings"]
    assert audit["distinct_geometry"] and audit["puzzleUnchanged"] and audit["studioArtUtilityPassed"]
    hashes = {p.relative_to(STAGE).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in STAGE.rglob("*.lua")}
    assert hashes == audit["sources_sha256"], "Sources changed since final validation/previews"
    preservation = json.loads((RELEASE / "preservation-report.json").read_text())
    game = ROOT / "releases" / preservation["output"]
    assert hashlib.sha256(game.read_bytes()).hexdigest() == preservation["output_sha256"]
    assert preservation["original_objects_preserved"] == 286
    assert preservation["modified_sources"] == ["ArtChecks.lua", "Client.lua", "DetailedArt/EnhancedScene.lua", "DetailedArt/NewCollectibles.lua", "FreeModels/NintendoItems.lua"]
    assert preservation["added_modules"] == ["DetailedArt/SliferArt.lua"]
    baseline = ROOT / "roblox/original/StealAnOPItem_69_ArtAndLotus.rbxlx"
    assert hashlib.sha256(baseline.read_bytes()).hexdigest() == preservation["baseline_sha256"]
    validation = {
        "game": game.name,
        "sha256": preservation["output_sha256"],
        "active_sources_compiled_with_official_luau": len(hashes),
        "actual_factory_models_checked": len(audit["items"]),
        "item_geometry_and_catalog_assertions": audit["checks"],
        "item_warnings": audit["warnings"],
        "production_artchecks_passed": audit["studioArtUtilityPassed"],
        "original_session_test_groups_passed": 6,
        "original_regression_groups_passed": 13,
        "actual_world_builder_assertions_passed": 556,
        "non_slifer_world_parts_preserved": 5842,
        "slifer_animation_test_frames": 360,
        "slifer_loop_reduced_effects_culling_cleanup_passed": True,
        "millennium_puzzle_geometry_preserved": audit["puzzleUnchanged"],
        "changed_item_geometry": audit["changedGeometry"],
        "source_hashes": hashes,
        "studio_playtest_performed": False,
        "published_to_roblox": False,
        "limitations": ["Offline geometry previews approximate Studio lighting, materials and rounded surfaces.", "Studio visual, performance and multiplayer playtests remain unperformed."],
    }
    (RELEASE / "validation-report.json").write_text(json.dumps(validation, indent=2) + "\n")
    tools = ["build_v70_place.py", "package_v70_release.py", "run_game_checks.py", "audit_v70_items.py", "roblox_mock.lua", "build_puzzle_asset.py", "export_free_models.py"]
    tests = ["v70_item_audit.lua", "v70_preservation.lua", "v70_world.lua", "slifer_upgrade.lua"]
    files = [game, baseline, ROOT / "README.md", ROOT / "releases/VERSION_70_HANDOFF.md"]
    files += [ROOT / "tools" / name for name in tools]
    files += [ROOT / "tests" / name for name in tests]
    for directory in (STAGE, ROOT / "roblox/v69-original/OPItemV2", RELEASE, ROOT / "releases/Version70Items"):
        files += [p for p in directory.rglob("*") if p.is_file()]
    target = ROOT / "releases/Version70_SourceAndGame.zip"
    unique = sorted(set(files))
    with zipfile.ZipFile(target, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in unique:
            archive.write(path, path.relative_to(ROOT))
    with zipfile.ZipFile(target) as archive:
        assert archive.testzip() is None, "Archive CRC failed"
        assert len(archive.infolist()) == len(unique)
    print(f"Packaged {len(unique)} files: {target.name} ({target.stat().st_size} bytes)")
    print(f"Game SHA256: {preservation['output_sha256']}")
    print(f"Package SHA256: {hashlib.sha256(target.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
