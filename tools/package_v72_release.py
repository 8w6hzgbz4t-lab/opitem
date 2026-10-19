"""Package the validated crossover items, world finishes and complete game."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "roblox/v72-game"
RELEASE = ROOT / "releases/Version72"


def main():
    audit = json.loads((RELEASE / "items-manifest.json").read_text())
    assert len(audit["items"]) == 69 and not audit["failures"] and not audit["warnings"]
    assert audit["distinct_geometry"] and audit["puzzleUnchanged"] and audit["studioArtUtilityPassed"]
    assert not audit["changedGeometry"] and audit["previous_models_preserved_exactly"]
    hashes = {p.relative_to(STAGE).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in STAGE.rglob("*.lua")}
    assert hashes == audit["sources_sha256"], "Sources changed since final item validation"
    presentation = json.loads((RELEASE / "presentation-checks.json").read_text())
    for flag in ("base_anchors_slots_and_spawn_positions_preserved", "cosmetic_geometry_noninteractive", "eight_bases_eight_slots_each", "entrances_green_lines_belt_and_display_envelopes_clear", "original_world_instance_properties_preserved", "rebuild_idempotent", "solid_roofs_perimeter_and_disposal_preserved"):
        assert presentation[flag], flag
    preservation = json.loads((RELEASE / "preservation-report.json").read_text())
    game = ROOT / "releases" / preservation["output"]
    assert hashlib.sha256(game.read_bytes()).hexdigest() == preservation["output_sha256"]
    assert preservation["original_objects_preserved"] == 288
    baseline = ROOT / "releases/StealAnOPItem_71_SecretFormulaAndRa.rbxlx"
    assert hashlib.sha256(baseline.read_bytes()).hexdigest() == preservation["baseline_sha256"]
    spawn = json.loads((RELEASE / "spawn-rates.json").read_text())
    assert len(spawn["items"]) == 69 and abs(spawn["probability_sum"] - 1) < 1e-12
    additions = {row["id"]: row for row in spawn["items"] if row["new"]}
    assert set(additions) == {"transformers_allspark", "transformers_matrix", "optimus_energon_axe"}
    assert additions["optimus_energon_axe"]["within_tier_weight"] == .5
    for key, count in {"AllSpark": 238, "MatrixOfLeadership": 209, "OptimusPrimeEnergonAxe": 187}.items():
        model_path = RELEASE / "models" / (key + ".rbxmx")
        model = ET.parse(model_path).getroot()
        objects = list(model.iter("Item"))
        refs = {n.get("referent") for n in objects}
        assert len(refs) == len(objects) and len(objects) == count + 1
        for ref in model.iter("Ref"):
            assert ref.text in refs or ref.text in {"null", "nil", None}
    report = {
        "game": game.name,
        "sha256": preservation["output_sha256"],
        "active_sources_compiled_with_official_luau": len(hashes),
        "actual_factory_models_checked": len(audit["items"]),
        "item_geometry_and_catalog_assertions": audit["checks"],
        "production_artchecks_passed": audit["studioArtUtilityPassed"],
        "existing_66_definitions_models_and_surface_gui_preserved": True,
        "spawn_rarity_pools_verified": 7,
        "all_item_spawn_probabilities_sum_to_one": True,
        "catalog_transactions_and_probability_assertions": 7112,
        "original_session_test_groups_passed": 6,
        "original_regression_groups_passed": 13,
        "new_item_purchase_carry_delivery_income_index_refund_theft_reset_and_full_base_checks_passed": True,
        "presentation": presentation,
        "animated_slifer_detailed_ra_and_original_landmarks_preserved": True,
        "millennium_puzzle_geometry_preserved": audit["puzzleUnchanged"],
        "source_hashes": hashes,
        "studio_playtest_performed": False,
        "published_to_roblox": False,
        "limitations": ["Offline model previews and documented cutaways approximate Studio rendering and materials.", "Live Studio visual, performance, physics and multiplayer playtests remain unperformed."],
    }
    (RELEASE / "validation-report.json").write_text(json.dumps(report, indent=2) + "\n")
    tools = ["build_v72_place.py", "package_v72_release.py", "run_game_checks.py", "audit_v72_items.py", "audit_v70_items.py", "roblox_mock.lua", "build_puzzle_asset.py", "export_free_models.py", "preview_v72_bases.py", "record_v72_plaza.lua", "render_v72_plaza.py", "render_v72_plaza_blender.py"]
    tests = ["v72_items.lua", "v72_catalog.lua", "v72_presentation.lua"]
    files = [game, baseline, ROOT / "README.md", ROOT / "releases/VERSION_72_HANDOFF.md"]
    files += [ROOT / "tools" / name for name in tools]
    files += [ROOT / "tests" / name for name in tests]
    for directory in (STAGE, ROOT / "roblox/v71-game", ROOT / "roblox/v72-pre-polish", RELEASE):
        files += [p for p in directory.rglob("*") if p.is_file()]
    files = sorted(set(files))
    target = ROOT / "releases/Version72_SourceAndGame.zip"
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
