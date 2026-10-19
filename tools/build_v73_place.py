"""Remove the retired skyline scenery from the preserved Version 72 place."""
from __future__ import annotations

from copy import deepcopy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from build_v72_place import package, sources

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "releases/StealAnOPItem_72_CrossoverArt.rbxlx"
BASE_SHA = "730caf1fe381a48928aac89e5b4df8df7e491aec897356bf2a00002d3064c9c5"
STAGE = ROOT / "roblox/v73-game"
OUT = ROOT / "releases/StealAnOPItem_73_SkylineCleanup.rbxlx"
REPORT = ROOT / "releases/Version73/preservation-report.json"
CHANGED = "DetailedArt/EnhancedScene.lua"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert digest(BASE) == BASE_SHA, "Unexpected Version 72 baseline"
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
    assert changed == [CHANGED], "Only the intended scenery module may change"
    code = staged[CHANGED].read_text()
    assert "local function kaibaTower" not in code and "kaibaTower(root)" not in code
    assert code.count("Slifer.create(root)") == 1, "Keep the animated Slifer"
    assert "wingedDragonOfRa(root)" in code, "Keep the detailed Ra statue"
    output_sources[CHANGED].find("Properties/ProtectedString[@name='Source']").text = code
    originals = list(original.iter("Item"))
    updates = list(root.iter("Item"))
    assert len(originals) == len(updates) == 293
    changed_ref = output_sources[CHANGED].get("referent")
    for old, new in zip(originals, updates):
        assert old.attrib == new.attrib
        a, b = deepcopy(old.find("Properties")), deepcopy(new.find("Properties"))
        if old.get("referent") == changed_ref:
            a.find("ProtectedString[@name='Source']").text = ""
            b.find("ProtectedString[@name='Source']").text = ""
        assert ET.tostring(a) == ET.tostring(b), "Unexpected property edit"
        assert [n.get("referent") for n in old.findall("Item")] == [
            n.get("referent") for n in new.findall("Item")
        ], "Original object hierarchy changed"
    expected = deepcopy(original)
    sources(package(expected))[CHANGED].find("Properties/ProtectedString[@name='Source']").text = code
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
        "all_69_item_models_stats_and_gameplay_preserved": True,
        "studio_playtest_performed": False,
        "published_to_roblox": False,
        "source_hashes": {name: digest(path) for name, path in sorted(staged.items())},
    }
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Built {OUT.name}: all 293 objects preserved; only {CHANGED} changed")
    print(f"SHA256 {report['output_sha256']}")


if __name__ == "__main__":
    main()
