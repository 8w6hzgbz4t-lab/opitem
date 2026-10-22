"""Build V83 while preserving every original instance, property and backup."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from build_v72_place import package,sources,name
ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'releases/StealAnOPItem_82_MusicConnected.rbxlx'
BASE_SHA='6ec75ff8f854692e05cf77ed516cbb11a6b457e756e0493b2591ad00f4da97fe'
STAGE=ROOT/'roblox/v83-game';OUT=ROOT/'releases/StealAnOPItem_83_SellAndWorkbenches.rbxlx'
REPORT=ROOT/'releases/Version83/preservation-report.json'
CHANGED={'Client.lua','PhaseClient.lua','PhaseService.lua','Server.lua'}
ADDED={'BaseWorkbench.lua','ItemPromptClient.lua'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
    assert sha(BASE)==BASE_SHA
    original=ET.parse(BASE).getroot();root=deepcopy(original)
    before=sources(package(original));active=package(root);current=sources(active)
    staged={p.relative_to(STAGE).as_posix():p for p in STAGE.rglob('*.lua')}
    assert staged.keys()==before.keys()|ADDED and len(staged)==109
    changed=set()
    for relative,path in sorted(staged.items()):
        if relative in current:
            source=current[relative].find("Properties/ProtectedString[@name='Source']")
            if source.text!=path.read_text():
                assert relative in CHANGED,'Unreviewed source change '+relative
                source.text=path.read_text();changed.add(relative)
        else:
            assert relative in ADDED
            item=ET.SubElement(active,'Item',{'class':'ModuleScript','referent':'RBX_V83_'+Path(relative).stem})
            props=ET.SubElement(item,'Properties')
            ET.SubElement(props,'string',name='Name').text=Path(relative).stem
            ET.SubElement(props,'ProtectedString',name='Source').text=path.read_text()
    assert changed==CHANGED
    player_nodes=[n for n in root.iter('Item')if n.get('class')=='Players'];assert len(player_nodes)==1
    player_limit=player_nodes[0].find("Properties/int[@name='MaxPlayersInternal']");assert player_limit.text=='12'
    player_limit.text='8'
    old={n.get('referent'):n for n in original.iter('Item')};new={n.get('referent'):n for n in root.iter('Item')}
    assert len(old)==313 and len(new)==315==sum(1 for _ in root.iter('Item'))
    edited={current[p].get('referent')for p in changed}
    for ref,a in old.items():
        b=new[ref];assert a.attrib==b.attrib
        pa,pb=deepcopy(a.find('Properties')),deepcopy(b.find('Properties'))
        if a.get('class')=='Players':
            assert pa.find("int[@name='MaxPlayersInternal']").text=='12' and pb.find("int[@name='MaxPlayersInternal']").text=='8'
            pa.find("int[@name='MaxPlayersInternal']").text='8'
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
            'active_sources':109,'original_objects_preserved':313,'total_objects':315,
            'modified_sources':sorted(changed),'added_modules':sorted(ADDED),
            'approved_property_changes':[{'class':'Players','property':'MaxPlayersInternal','before':12,'after':8}],
            'all_other_original_properties_hierarchy_and_backups_preserved':True,
            'all_76_collectible_models_catalog_names_and_stats_preserved':True,
            'source_hashes':{relative:sha(path)for relative,path in sorted(staged.items())},
            'studio_playtest_performed':False,'published_to_roblox':False}
    REPORT.parent.mkdir(parents=True,exist_ok=True);REPORT.write_text(json.dumps(report,indent=2)+'\n')
    print('Built '+OUT.name+'; 313 original objects retained; owner Sell and workbenches; 8-player limit; 109 sources')
    print('SHA256 '+sha(OUT))
if __name__=='__main__':main()
