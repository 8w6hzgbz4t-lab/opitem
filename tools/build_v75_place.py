"""Apply the reviewed V75 sources to the complete preserved Version 74 place."""
from __future__ import annotations

from copy import deepcopy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from build_v72_place import package, sources, name

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'releases/StealAnOPItem_74_DeveloperMenu.rbxlx'
BASE_SHA = 'ccc38fb77676fbbd51268cfe24fbbeb87b728a5160d5c9cfa1b0047e6980169f'
STAGE = ROOT / 'roblox/v75-game'
OUT = ROOT / 'releases/StealAnOPItem_75_DragonsAndDevTools.rbxlx'
REPORT = ROOT / 'releases/Version75/preservation-report.json'
MODIFIED = {'AdminClient.lua','AdminConfig.lua','AdminService.lua','BaseEntrance.lua','Client.lua',
            'ExpandedCatalog.lua','FreeModels/Assets.lua','FreeModels/FreeModels.lua','ModelFactory.lua',
            'PhaseClient.lua','PhaseService.lua','Server.lua','TransactionCore.lua'}
ADDED = {'DetailedArt/UpperFloor.lua','DeveloperArtifacts.lua','DeveloperEffects.lua','DeveloperPowers.lua',
         'FreeModels/DragonCollectibles.lua','FreeModels/PopCultureItems.lua'}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert sha(BASE) == BASE_SHA, 'Unexpected Version 74 baseline'
    original = ET.parse(BASE).getroot()
    root = deepcopy(original)
    active = package(root)
    before = sources(package(original))
    current = sources(active)
    staged = {p.relative_to(STAGE).as_posix(): p for p in STAGE.rglob('*.lua')}
    assert staged.keys() == before.keys() | ADDED and len(staged) == 93
    changed = set()
    for relative, path in sorted(staged.items()):
        code = path.read_text()
        if relative in current:
            source = current[relative].find("Properties/ProtectedString[@name='Source']")
            if (source.text or '') != code:
                changed.add(relative)
                source.text = code
        else:
            parts = Path(relative).with_suffix('').parts
            parent = active
            for part in parts[:-1]:
                parent = next(n for n in parent.findall('Item') if name(n) == part)
            item = ET.SubElement(parent, 'Item', {'class':'ModuleScript','referent':'RBX_V75_'+'_'.join(parts)})
            props = ET.SubElement(item,'Properties')
            ET.SubElement(props,'string',name='Name').text = parts[-1]
            ET.SubElement(props,'ProtectedString',name='Source').text = code
    assert changed == MODIFIED, 'Unexpected existing source edit'
    originals = {n.get('referent'): n for n in original.iter('Item')}
    updates = {n.get('referent'): n for n in root.iter('Item')}
    assert len(originals) == 293 and len(updates) == 299
    assert len(updates) == sum(1 for _ in root.iter('Item')), 'Duplicate reference'
    changed_refs = {current[p].get('referent') for p in changed}
    for ref, old in originals.items():
        new = updates[ref]
        assert old.attrib == new.attrib
        a,b = deepcopy(old.find('Properties')),deepcopy(new.find('Properties'))
        if ref in changed_refs:
            a.find("ProtectedString[@name='Source']").text = ''
            b.find("ProtectedString[@name='Source']").text = ''
        assert ET.tostring(a) == ET.tostring(b), 'Unexpected property edit: '+ref
        assert [n.get('referent') for n in old.findall('Item')] == [n.get('referent') for n in new.findall('Item') if n.get('referent') in originals]
    for reference in root.iter('Ref'):
        assert reference.text in updates or reference.text in {None,'null','nil'}, 'Dangling reference'
    output_sources = sources(active)
    for relative, path in staged.items():
        assert output_sources[relative].findtext("Properties/ProtectedString[@name='Source']") == path.read_text()
    for protected in ('AdminPolicy.lua','Core.lua','PowerCatalog.lua','Tests.lua','RegressionTests.lua','Catalog.lua',
                      'MillenniumPuzzle.lua','DetailedArt/SliferArt.lua','DetailedArt/EnhancedScene.lua','World.lua'):
        assert ET.tostring(before[protected]) == ET.tostring(output_sources[protected]), 'Protected source changed: '+protected
    ET.ElementTree(root).write(OUT,encoding='utf-8',xml_declaration=True)
    assert sha(BASE) == BASE_SHA
    report = {
        'baseline':BASE.name,'baseline_sha256':BASE_SHA,'output':OUT.name,'output_sha256':sha(OUT),
        'original_objects_preserved':len(originals),'total_objects':len(updates),'active_sources':len(staged),
        'modified_sources':sorted(changed),'added_modules':sorted(ADDED),
        'all_other_original_properties_hierarchy_and_backups_preserved':True,
        'developer_account_and_numeric_authorization_policy_preserved':True,
        'all_69_previous_item_models_definitions_and_puzzle_preserved':True,
        'version_73_skyline_removals_and_animated_slifer_preserved':True,
        'source_hashes':{relative:sha(path) for relative,path in sorted(staged.items())},
        'studio_playtest_performed':False,'published_to_roblox':False,
    }
    REPORT.parent.mkdir(parents=True,exist_ok=True)
    REPORT.write_text(json.dumps(report,indent=2)+'\n')
    print(f'Built {OUT.name}: 293 original objects retained, six modules added, 93 active sources')
    print('SHA256 '+sha(OUT))


if __name__=='__main__':main()
