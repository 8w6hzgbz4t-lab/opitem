"""Apply the account-locked developer menu to the preserved Version 73 place."""
from __future__ import annotations

from copy import deepcopy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from build_v72_place import package, sources

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "releases/StealAnOPItem_73_SkylineCleanup.rbxlx"
BASE_SHA = "983dae16779b512fd3e973f0d4038342b189b826bba86bf774f384718228155b"
STAGE = ROOT / "roblox/v74-game"
OUT = ROOT / "releases/StealAnOPItem_74_DeveloperMenu.rbxlx"
REPORT = ROOT / "releases/Version74/preservation-report.json"
CHANGED = {"AdminClient.lua", "AdminConfig.lua", "AdminPolicy.lua", "AdminService.lua", "Server.lua", "PhaseService.lua"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert digest(BASE) == BASE_SHA, "Unexpected Version 73 baseline"
    original = ET.parse(BASE).getroot()
    root = deepcopy(original)
    original_sources = sources(package(original))
    output_sources = sources(package(root))
    staged = {p.relative_to(STAGE).as_posix(): p for p in STAGE.rglob("*.lua")}
    assert staged.keys() == original_sources.keys(), "Existing scripts must be retained"
    changed = []
    for relative, path in sorted(staged.items()):
        old = original_sources[relative].findtext("Properties/ProtectedString[@name='Source']")
        if old != path.read_text():
            changed.append(relative)
    assert set(changed) == CHANGED, "Unexpected changes outside developer controls"
    for relative in changed:
        output_sources[relative].find("Properties/ProtectedString[@name='Source']").text = staged[relative].read_text()
    originals = list(original.iter("Item"))
    updates = list(root.iter("Item"))
    assert len(originals) == len(updates) == 293
    changed_refs = {output_sources[path].get("referent") for path in changed}
    for old, new in zip(originals, updates):
        assert old.attrib == new.attrib
        a, b = deepcopy(old.find("Properties")), deepcopy(new.find("Properties"))
        if old.get("referent") in changed_refs:
            a.find("ProtectedString[@name='Source']").text = ""
            b.find("ProtectedString[@name='Source']").text = ""
        assert ET.tostring(a) == ET.tostring(b), "Unexpected property edit"
        assert [n.get("referent") for n in old.findall("Item")] == [
            n.get("referent") for n in new.findall("Item")
        ], "Original object hierarchy changed"
    expected = deepcopy(original)
    for relative in changed:
        sources(package(expected))[relative].find("Properties/ProtectedString[@name='Source']").text = staged[relative].read_text()
    assert ET.tostring(expected) == ET.tostring(root), "Unexpected XML change"
    OUT.parent.mkdir(exist_ok=True)
    ET.ElementTree(root).write(OUT, encoding="utf-8", xml_declaration=True)
    rebuilt = sources(package(ET.parse(OUT).getroot()))
    for relative, path in staged.items():
        assert rebuilt[relative].findtext("Properties/ProtectedString[@name='Source']") == path.read_text()
    assert digest(BASE) == BASE_SHA
    report = {
        "baseline": BASE.name,
        "baseline_sha256": BASE_SHA,
        "output": OUT.name,
        "output_sha256": digest(OUT),
        "original_objects_preserved": len(originals),
        "total_objects": len(updates),
        "modified_sources": changed,
        "active_sources": len(staged),
        "all_other_sources_properties_and_backups_preserved": True,
        "animated_slifer_geometry_and_client_animation_preserved": True,
        "all_69_item_models_stats_core_and_transaction_sources_preserved": True,
        "all_scenery_and_version_73_removals_preserved": True,
        "developer_username": "Goverment_cheesee",
        "developer_numeric_id_resolved_by_roblox_on_server_start": True,
        "studio_playtest_performed": False,
        "published_to_roblox": False,
        "source_hashes": {name: digest(path) for name, path in sorted(staged.items())},
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Built {OUT.name}: all 293 objects preserved; {len(changed)} developer source updates")
    print(f"SHA256 {report['output_sha256']}")


if __name__ == "__main__":
    main()
