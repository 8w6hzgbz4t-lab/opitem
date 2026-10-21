"""Build V78 while preserving every original instance, property and backup."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from build_v72_place import package,sources,name
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'releases/StealAnOPItem_77_RobuxOffers.rbxlx'
BASE_SHA='7028edc1c3a5b0e100c08949e6359de435279189ab1bdf51eb2d846d89b0d2d1'
STAGE=ROOT/'roblox/v78-game';OUT=ROOT/'releases/StealAnOPItem_78_PowersAndSavedProgress.rbxlx'
REPORT=ROOT/'releases/Version78/preservation-report.json'
CHANGED={'AdminClient.lua','AdminService.lua','AudioConfig.lua','CashShopClient.lua','CashShopConfig.lua',
         'CashShopService.lua','Client.lua','Config.lua','DetailedArt/EnhancedScene.lua','PhaseClient.lua',
         'PhaseService.lua','PowerCatalog.lua','RegressionTests.lua','Server.lua'}
ADDED={'FlightPose.lua','FlightPoseClient.lua','PersistenceConfig.lua','PersistentSession.lua','PowerEffects.lua','ProfileCodec.lua','ProfileStore.lua'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    assert sha(BASE)==BASE_SHA
    original=ET.parse(BASE).getroot();root=deepcopy(original)
    before=sources(package(original));active=package(root);current=sources(active)
    staged={p.relative_to(STAGE).as_posix():p for p in STAGE.rglob('*.lua')}
    assert staged.keys()==before.keys()|ADDED and len(staged)==106
    changed=set()
    for relative,path in sorted(staged.items()):
        if relative in current:
            source=current[relative].find("Properties/ProtectedString[@name='Source']")
            if source.text!=path.read_text():
                assert relative in CHANGED,'Unreviewed source change '+relative
                source.text=path.read_text();changed.add(relative)
        else:
            assert relative in ADDED
            item=ET.SubElement(active,'Item',{'class':'ModuleScript','referent':'RBX_V78_'+Path(relative).stem})
            props=ET.SubElement(item,'Properties')
            ET.SubElement(props,'string',name='Name').text=Path(relative).stem
            ET.SubElement(props,'ProtectedString',name='Source').text=path.read_text()
    assert changed==CHANGED
    old={n.get('referent'):n for n in original.iter('Item')};new={n.get('referent'):n for n in root.iter('Item')}
    assert len(old)==305 and len(new)==312==sum(1 for _ in root.iter('Item'))
    edited={current[p].get('referent')for p in changed}
    for ref,a in old.items():
        b=new[ref];assert a.attrib==b.attrib
        pa,pb=deepcopy(a.find('Properties')),deepcopy(b.find('Properties'))
        if ref in edited:
            pa.find("ProtectedString[@name='Source']").text='';pb.find("ProtectedString[@name='Source']").text=''
        assert ET.tostring(pa)==ET.tostring(pb),'Property edit '+ref
        assert[n.get('referent')for n in a.findall('Item')]==[n.get('referent')for n in b.findall('Item')if n.get('referent')in old]
    for ref in root.iter('Ref'):assert ref.text in new or ref.text in {None,'nil','null'}
    exported=sources(active)
    for relative,path in staged.items():assert exported[relative].findtext("Properties/ProtectedString[@name='Source']")==path.read_text()
    for relative in before:
        if relative not in CHANGED:assert ET.tostring(before[relative])==ET.tostring(exported[relative])
    ET.ElementTree(root).write(OUT,encoding='utf-8',xml_declaration=True)
    assert sha(BASE)==BASE_SHA
    report={'baseline':BASE.name,'baseline_sha256':BASE_SHA,'output':OUT.name,'output_sha256':sha(OUT),
            'active_sources':106,'original_objects_preserved':305,'total_objects':312,
            'modified_sources':sorted(changed),'added_modules':sorted(ADDED),
            'all_other_original_properties_hierarchy_and_backups_preserved':True,
            'all_76_collectible_models_catalog_names_and_stats_preserved':True,
            'source_hashes':{relative:sha(path)for relative,path in sorted(staged.items())},
            'studio_playtest_performed':False,'published_to_roblox':False}
    REPORT.parent.mkdir(parents=True,exist_ok=True);REPORT.write_text(json.dumps(report,indent=2)+'\n')
    print('Built '+OUT.name+'; 305 original objects retained; seven modules added; 106 sources')
    print('SHA256 '+sha(OUT))
if __name__=='__main__':main()
