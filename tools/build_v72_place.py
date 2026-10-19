"""Apply reviewed art sources to the user's complete, preserved Version 71 place."""
from __future__ import annotations

import argparse
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
BASE_SHA = "1cad4ecb86a1b76c76b754d0c2f69633682dca3d0452a62f8616e52e1451c7b7"
STAGE = ROOT / "roblox/v72-game"
OUT = ROOT / "releases/StealAnOPItem_72_CrossoverArt.rbxlx"
REPORT = ROOT / "releases/Version72/preservation-report.json"


def name(node):
    return node.findtext("Properties/string[@name='Name']")


def package(root):
    service = next(n for n in root.findall("Item") if n.get("class") == "ServerScriptService")
    return next(n for n in service.findall("Item") if name(n) == "OPItemV2")


def sources(parent, prefix=""):
    result = {}
    for node in parent.findall("Item"):
        path = prefix + name(node)
        source = node.find("Properties/ProtectedString[@name='Source']")
        if source is not None:
            result[path + ".lua"] = node
        else:
            result.update(sources(node, path + "/"))
    return result


def build(base: Path):
    before = base.read_bytes()
    assert hashlib.sha256(before).hexdigest() == BASE_SHA, "Unexpected baseline; use the user's complete Version 71 upload"
    original = ET.fromstring(before)
    root = deepcopy(original)
    active = package(root)
    nodes = sources(active)
    modified = []
    added = []
    staged = {p.relative_to(STAGE).as_posix(): p for p in STAGE.rglob("*.lua")}
    assert nodes.keys() <= staged.keys(), "Staging removed an existing script"
    for relative, path in sorted(staged.items()):
        code = path.read_text()
        if relative in nodes:
            node = nodes[relative]
            source = node.find("Properties/ProtectedString[@name='Source']")
            if (source.text or "") != code:
                source.text = code
                modified.append(relative)
            continue
        parts = Path(relative).with_suffix("").parts
        parent = active
        for part in parts[:-1]:
            parent = next(n for n in parent.findall("Item") if name(n) == part)
        node = ET.SubElement(parent, "Item", {"class": "ModuleScript", "referent": "RBX_V72_" + "_".join(parts)})
        props = ET.SubElement(node, "Properties")
        ET.SubElement(props, "string", name="Name").text = parts[-1]
        ET.SubElement(props, "ProtectedString", name="Source").text = code
        added.append(relative)
    originals = {n.get("referent"): n for n in original.iter("Item")}
    updates = {n.get("referent"): n for n in root.iter("Item")}
    assert len(updates) == sum(1 for _ in root.iter("Item")), "Duplicate referents"
    assert originals.keys() <= updates.keys(), "An original object was removed"
    changed_refs = {nodes[p].get("referent") for p in modified}
    for ref, old in originals.items():
        new = updates[ref]
        assert old.attrib == new.attrib
        a, b = deepcopy(old.find("Properties")), deepcopy(new.find("Properties"))
        if ref in changed_refs:
            a.find("ProtectedString[@name='Source']").text = ""
            b.find("ProtectedString[@name='Source']").text = ""
        assert ET.tostring(a) == ET.tostring(b), "Unintended property edit: " + str(ref)
        assert [n.get("referent") for n in old.findall("Item")] == [
            n.get("referent") for n in new.findall("Item") if n.get("referent") in originals
        ], "Original child order or parent changed"
    for reference in root.iter("Ref"):
        assert reference.text in {None, "null", "nil"} or reference.text in updates, "Dangling reference"
    output_sources = sources(active)
    assert output_sources.keys() == staged.keys()
    for relative, node in output_sources.items():
        assert node.findtext("Properties/ProtectedString[@name='Source']") == staged[relative].read_text()
    for protected in ("Client.lua", "Core.lua", "TransactionCore.lua", "PowerCatalog.lua", "Config.lua", "PhaseConfig.lua", "PhaseService.lua", "Server.lua", "Catalog.lua", "DetailedArt/EnhancedScene.lua", "FreeModels/NintendoItems.lua", "FreeModels/WarriorModels.lua", "MillenniumPuzzle.lua", "DetailedArt/MillenniumPuzzle.lua"):
        old = sources(package(original))[protected]
        assert ET.tostring(old) == ET.tostring(output_sources[protected]), "Protected gameplay/puzzle changed: " + protected
    allowed = {"ExpandedCatalog.lua", "ModelFactory.lua", "FreeModels/Assets.lua", "FreeModels/FreeModels.lua", "ArtChecks.lua", "World.lua"}
    assert set(modified) <= allowed, "Unrelated source changes"
    assert set(added) == {"FreeModels/AllSpark.lua", "FreeModels/MatrixLeadership.lua", "FreeModels/EnergonAxe.lua", "DetailedArt/BasePolish.lua", "DetailedArt/PlazaPolish.lua"}, "Unexpected module additions"
    old_world = sources(package(original))["World.lua"].findtext("Properties/ProtectedString[@name='Source']")
    additions = " require(script.Parent.DetailedArt.BasePolish).build(world)\n require(script.Parent.DetailedArt.PlazaPolish).build(world)\n"
    assert output_sources["World.lua"].findtext("Properties/ProtectedString[@name='Source']").replace(additions, "", 1) == old_world, "World integration must preserve the existing build"
    OUT.parent.mkdir(exist_ok=True)
    ET.ElementTree(root).write(OUT, encoding="utf-8", xml_declaration=True)
    assert base.read_bytes() == before, "Original upload changed"
    report = {
        "baseline": base.name,
        "baseline_sha256": BASE_SHA,
        "output": OUT.name,
        "output_sha256": hashlib.sha256(OUT.read_bytes()).hexdigest(),
        "original_objects_preserved": len(originals),
        "total_objects": len(updates),
        "modified_sources": modified,
        "added_modules": added,
        "original_properties_preserved_except_listed_sources": True,
        "gameplay_code_and_puzzle_preserved": True,
        "previous_66_item_entries_preserved_and_three_added": True,
        "studio_playtest_performed": False,
        "published_to_roblox": False,
    }
    REPORT.parent.mkdir(exist_ok=True)
    REPORT.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("base", type=Path, help="Complete uploaded Version 71 .rbxlx")
    build(parser.parse_args().base)
