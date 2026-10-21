"""Build V76 while retaining every original place object, property and backup."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from build_v72_place import package, sources, name

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'releases/StealAnOPItem_75_DragonsAndDevTools.rbxlx'
BASE_SHA='9320c4d6e7145a96f56f9321df6f2b0f5abbb9fd1b685c7a48053128f7b777f3'
STAGE=ROOT/'roblox/v76-game'
OUT=ROOT/'releases/StealAnOPItem_76_ConveyorClash.rbxlx'
REPORT=ROOT/'releases/Version76/preservation-report.json'
ALLOWED={'AdminClient.lua','AdminConfig.lua','AdminService.lua','Client.lua','PhaseClient.lua',
         'PhaseService.lua','Server.lua','TransactionCore.lua','Tests.lua','RegressionTests.lua',
         'DetailedArt/Architecture.lua','DetailedArt/EnhancedScene.lua','DetailedArt/LandmarkArt.lua','DeveloperPowers.lua',
         'StudioIntegrationTests.lua'}
ADDED={'AudioClient.lua','AudioConfig.lua','CashShopBench.lua','CashShopClient.lua',
       'CashShopConfig.lua','CashShopService.lua'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main():
    assert sha(BASE)==BASE_SHA,'Baseline changed'
    original=ET.parse(BASE).getroot();root=deepcopy(original)
    before=sources(package(original));active=package(root);current=sources(active)
    staged={p.relative_to(STAGE).as_posix():p for p in STAGE.rglob('*.lua')}
    assert staged.keys()==before.keys()|ADDED
    changed=set()
    for relative,path in sorted(staged.items()):
        code=path.read_text()
        if relative in current:
            source=current[relative].find("Properties/ProtectedString[@name='Source']")
            if (source.text or '')!=code:
                assert relative in ALLOWED,'Unreviewed edit: '+relative
                source.text=code;changed.add(relative)
        else:
            parts=Path(relative).with_suffix('').parts;parent=active
            for part in parts[:-1]:parent=next(n for n in parent.findall('Item') if name(n)==part)
            kind='LocalScript' if relative=='CashShopClient.lua' else 'ModuleScript'
            item=ET.SubElement(parent,'Item',{'class':kind,'referent':'RBX_V76_'+'_'.join(parts)})
            props=ET.SubElement(item,'Properties')
            ET.SubElement(props,'string',name='Name').text=parts[-1]
            ET.SubElement(props,'ProtectedString',name='Source').text=code
    originals={n.get('referent'):n for n in original.iter('Item')}
    updates={n.get('referent'):n for n in root.iter('Item')}
    assert len(originals)==299 and len(updates)==305==sum(1 for _ in root.iter('Item'))
    edited_refs={current[p].get('referent') for p in changed}
    for ref,old in originals.items():
        new=updates[ref];assert old.attrib==new.attrib
        a,b=deepcopy(old.find('Properties')),deepcopy(new.find('Properties'))
        if ref in edited_refs:
            a.find("ProtectedString[@name='Source']").text=''
            b.find("ProtectedString[@name='Source']").text=''
        assert ET.tostring(a)==ET.tostring(b),'Property changed: '+ref
        assert [n.get('referent') for n in old.findall('Item')]==[n.get('referent') for n in new.findall('Item') if n.get('referent') in originals]
    for ref in root.iter('Ref'):assert ref.text in updates or ref.text in {None,'null','nil'}
    exported=sources(active)
    for rel,path in staged.items():assert exported[rel].findtext("Properties/ProtectedString[@name='Source']")==path.read_text()
    for rel in ('AdminPolicy.lua','Core.lua','Catalog.lua','ExpandedCatalog.lua','ModelFactory.lua',
                'MillenniumPuzzle.lua','PowerCatalog.lua','DetailedArt/SliferArt.lua','World.lua'):
        assert ET.tostring(before[rel])==ET.tostring(exported[rel]),'Protected source changed: '+rel
    OUT.parent.mkdir(parents=True,exist_ok=True)
    ET.ElementTree(root).write(OUT,encoding='utf-8',xml_declaration=True)
    assert sha(BASE)==BASE_SHA
    report={'baseline':BASE.name,'baseline_sha256':BASE_SHA,'output':OUT.name,'output_sha256':sha(OUT),
            'original_objects_preserved':299,'total_objects':305,'active_sources':len(staged),
            'modified_sources':sorted(changed),'added_modules':sorted(ADDED),
            'all_other_original_properties_hierarchy_and_backups_preserved':True,
            'developer_account_numeric_policy_catalog_all_models_and_animated_slifer_preserved':True,
            'source_hashes':{rel:sha(path) for rel,path in sorted(staged.items())},
            'studio_playtest_performed':False,'published_to_roblox':False}
    REPORT.parent.mkdir(parents=True,exist_ok=True);REPORT.write_text(json.dumps(report,indent=2)+'\n')
    print(f'Built {OUT.name}: 299 original objects retained, {len(staged)} active sources')
    print('SHA256 '+sha(OUT))
if __name__=='__main__':main()
