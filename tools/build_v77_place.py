"""Apply only the reviewed shop preview and copy changes to the complete V76 place."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET
from build_v72_place import package,sources

ROOT=Path(__file__).resolve().parents[1]
STAGE=ROOT/'roblox/v77-game'
BASE=ROOT/'releases/StealAnOPItem_76_ConveyorClash.rbxlx'
BASE_SHA='cc46e18e5f77a4f531f71cd9453e523f2e2e329aefe8251ab1c7d04eaca8735a'
OUT=ROOT/'releases/StealAnOPItem_77_RobuxOffers.rbxlx'
REPORT=ROOT/'releases/Version77/preservation-report.json'
ALLOWED={'CashShopConfig.lua','CashShopService.lua','CashShopClient.lua','CashShopBench.lua','Server.lua','PowerCatalog.lua'}
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def main():
    assert sha(BASE)==BASE_SHA
    old=ET.parse(BASE).getroot();root=deepcopy(old)
    before=sources(package(old));active=sources(package(root))
    staged={p.relative_to(STAGE).as_posix():p for p in STAGE.rglob('*.lua')}
    assert staged.keys()==before.keys() and len(staged)==99
    changed=[]
    for relative,path in sorted(staged.items()):
        source=active[relative].find("Properties/ProtectedString[@name='Source']")
        if source.text!=path.read_text():
            assert relative in ALLOWED,'Unreviewed change '+relative
            changed.append(relative);source.text=path.read_text()
    assert set(changed)==ALLOWED
    # Blank precisely the reviewed sources, then compare the entire place XML.
    clean_old,clean_new=deepcopy(old),deepcopy(root)
    for tree in (clean_old,clean_new):
        nodes=sources(package(tree))
        for relative in changed:nodes[relative].find("Properties/ProtectedString[@name='Source']").text=''
    assert ET.tostring(clean_old)==ET.tostring(clean_new),'Unexpected object/property/hierarchy change'
    assert sum(1 for _ in root.iter('Item'))==305
    old_power=before['PowerCatalog.lua'].findtext("Properties/ProtectedString[@name='Source']")
    new_power=active['PowerCatalog.lua'].findtext("Properties/ProtectedString[@name='Source']")
    assert old_power.replace('Marked blue zone slows entrants temporarily. Does not drop loot.',
                            'Marked blue zone briefly slows entrants and knocks carried loot loose. Shields and immunity can block the hit.')==new_power
    ET.ElementTree(root).write(OUT,encoding='utf-8',xml_declaration=True)
    report={'baseline':BASE.name,'baseline_sha256':BASE_SHA,'output':OUT.name,'output_sha256':sha(OUT),
            'active_sources':99,'original_objects_preserved':305,'total_objects':305,
            'modified_sources':changed,'all_other_source_properties_hierarchy_and_backups_preserved':True,
            'all_76_collectible_models_and_stats_preserved':True,'developer_authorization_and_perks_unchanged':True,
            'only_power_change_is_slow_field_description':True,
            'source_hashes':{relative:sha(path) for relative,path in sorted(staged.items())},
            'studio_playtest_performed':False,'published_to_roblox':False}
    REPORT.parent.mkdir(parents=True,exist_ok=True);REPORT.write_text(json.dumps(report,indent=2)+'\n')
    assert sha(BASE)==BASE_SHA
    print('Built '+OUT.name+'; all 305 original objects preserved; 99 sources')
    print('SHA256 '+sha(OUT))
if __name__=='__main__':main()
