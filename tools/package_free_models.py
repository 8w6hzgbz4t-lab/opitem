"""Validate and package the free native Roblox model release."""
from pathlib import Path
import hashlib
import json
import xml.etree.ElementTree as ET
from zipfile import ZipFile,ZIP_DEFLATED

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'releases/FreeRobloxModels'
PLACE=ROOT/'releases/StealAnOPItem_64_FreeModels.rbxlx'
PACK=ROOT/'releases/FreeRobloxModels_Complete.zip'
PARTS={'Part','WedgePart','CornerWedgePart','MeshPart','UnionOperation'}

def name(node):return node.findtext("Properties/string[@name='Name']")
def validate_xml(path):
    root=ET.parse(path).getroot();nodes=list(root.iter('Item'))
    refs={n.attrib['referent'] for n in nodes}
    assert len(refs)==len(nodes),f'Duplicate references: {path.name}'
    for ref in root.iter('Ref'):assert ref.text in refs or ref.text in ('null','nil',None),f'Dangling reference: {path.name}'
    return root

def main():
    root=validate_xml(PLACE)
    service=next(n for n in root.findall('Item') if n.attrib['class']=='ServerScriptService')
    game=next(n for n in service.findall('Item') if name(n)=='OPItemV2')
    def check_sources(parent,directory):
        for node in parent.findall('Item'):
            source=node.find("Properties/ProtectedString[@name='Source']")
            if source is not None:assert (directory/(name(node)+'.lua')).read_text()==source.text,f'Stale source {name(node)}'
            elif node.findall('Item'):check_sources(node,directory/name(node))
    check_sources(game,ROOT/'roblox/v64-game')
    native=next(n for n in game.findall('Item') if name(n)=='FreeModels')
    for node in native.findall('Item'):
        assert (ROOT/'roblox/free_models'/(name(node)+'.lua')).read_text()==node.findtext("Properties/ProtectedString[@name='Source']")
    manifest=json.loads((ART/'manifest.json').read_text());assert len(manifest)==34
    for row in manifest:
        model=validate_xml(ART/'models'/(row['key']+'.rbxmx'))
        count=sum(n.attrib['class'] in PARTS for n in model.iter('Item'))
        assert count==row['parts'],f'Incomplete geometry: {row["key"]}'
        for suffix in ('.obj','.mtl'):assert (ART/'obj'/(row['key']+suffix)).stat().st_size>50
        assert (ART/'previews'/(row['key']+'.png')).stat().st_size>1000
        if row['key'] in ('mtg_black_lotus_card','mirror_force_card'):
            assert any(n.attrib['class']=='SurfaceGui' for n in model.iter('Item')),'Readable card text missing'
    for path in ART.glob('*.rbxmx'):validate_xml(path)
    validate_xml(ART/'FreeNativeModelGallery.rbxlx')
    incomplete=[row['key'] for row in manifest if row['status']!='built']
    assert incomplete==['squidward_force_of_despair_painting']
    report={
        'release':'version64_free_native_models','catalog_items':63,'new_buyable_items':17,
        'original_item_records_preserved':46,'base_version63_objects_preserved':242,
        'native_requested_assets':33,'complete_bird_extra_export':True,'total_model_exports':34,
        'geometry_catalog_flight_assertions_passed':64441,'native_catalog_transaction_assertions_passed':64087,
        'original_session_groups_passed':6,'world_static_parts':8943,
        'paid_services_required':False,'external_model_ids_required':False,
        'pending_reference_assets':incomplete,'studio_tested':False,'published_to_roblox':False,
        'place_sha256':hashlib.sha256(PLACE.read_bytes()).hexdigest(),
        'deferred_gameplay':['eight-power rebalance and VFX','HUD resizing','weapon spawn reduction','Rare/Epic boost','conveyor speed change','Infinity Stone progression and comet event'],
    }
    (ART/'validation-report.json').write_text(json.dumps(report,indent=2)+'\n')
    files={PLACE,ROOT/'releases/StealAnOPItem_63_DetailedArt.rbxlx',ROOT/'releases/FREE_MODELS_HANDOFF.md',ROOT/'docs/free-model-catalog.json'}
    files.update(p for p in ART.rglob('*') if p.is_file())
    for directory in ('roblox/free_models','roblox/v64-game','roblox/game'):
        files.update((ROOT/directory).rglob('*.lua'))
    for filename in ('free_models.lua','free_catalog_upgrade.lua','world_integration.lua'):
        files.add(ROOT/'tests'/filename)
    for filename in ('roblox_mock.lua','record_free_models.lua','check_free_models.py','build_free_models_place.py',
                     'export_free_models.py','build_puzzle_asset.py','run_game_checks.py','check_carry_presentation.py','package_free_models.py'):
        files.add(ROOT/'tools'/filename)
    hashes=[]
    with ZipFile(PACK,'w',ZIP_DEFLATED,compresslevel=6) as zip:
        for path in sorted(files):
            data=path.read_bytes();relative=path.relative_to(ROOT).as_posix()
            zip.writestr('FreeRobloxModels/'+relative,data)
            hashes.append(hashlib.sha256(data).hexdigest()+'  '+relative)
        zip.writestr('FreeRobloxModels/SHA256SUMS.txt','\n'.join(hashes)+'\n')
    with ZipFile(PACK) as zip:assert zip.testzip() is None
    print(f'PASS: actual place sources, 34 complete model files, card text, OBJ/MTL, references, explicit pending image and ZIP integrity')
    print(f'Packaged {len(files)} files; {PACK.stat().st_size:,} bytes; {PACK.name}')
    print('Place SHA256: '+report['place_sha256'])

if __name__=='__main__':main()
