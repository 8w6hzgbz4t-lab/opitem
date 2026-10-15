"""Integrate complete free native models into a preserved copy of version 63."""
from pathlib import Path
import hashlib
import shutil
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
BASE=ROOT/'releases/StealAnOPItem_63_DetailedArt.rbxlx'
OUT=ROOT/'releases/StealAnOPItem_64_FreeModels.rbxlx'
STAGE=ROOT/'roblox/v64-game'
BASE_SHA='666cb824abab2aaf340a423a1c2d9b2e64d731fbb3eef4feb4f79bf65f11d18a'

def name(node):return node.findtext("Properties/string[@name='Name']")
def source(node):return node.find("Properties/ProtectedString[@name='Source']")
def patch(value,old,new):
    assert value.count(old)==1,f'Expected one patch target: {old[:70]}'
    return value.replace(old,new)
def module(parent,label,code,ref):
    node=ET.SubElement(parent,'Item',{'class':'ModuleScript','referent':ref})
    props=ET.SubElement(node,'Properties')
    ET.SubElement(props,'string',name='Name').text=label
    ET.SubElement(props,'ProtectedString',name='Source').text=code
    return node

def main():
    assert hashlib.sha256(BASE.read_bytes()).hexdigest()==BASE_SHA,'Version 63 must remain unchanged'
    tree=ET.parse(BASE);root=tree.getroot()
    service=next(n for n in root.findall('Item') if n.attrib['class']=='ServerScriptService')
    package=next(n for n in service.findall('Item') if name(n)=='OPItemV2')
    nodes={name(n):n for n in package.findall('Item')}
    modified=set()
    code=source(nodes['Catalog']).text
    old='for _,d in ipairs(require(script.Parent.ExpandedCatalog)) do table.insert(C.Items,d) end'
    source(nodes['Catalog']).text=patch(code,old,old+'\nfor _,d in ipairs(require(script.Parent.FreeCatalog)) do table.insert(C.Items,d) end')
    modified.add(nodes['Catalog'].attrib['referent'])
    code=source(nodes['Server']).text
    old='local Factory=require(script.Parent.ModelFactory)'
    code=patch(code,old,old+'\nrequire(script.Parent.FreeModels.FactoryIntegration).install(Factory)')
    old='script.Parent.ExpandedCatalog:Clone().Parent=net'
    code=patch(code,old,old+'\nscript.Parent.FreeCatalog:Clone().Parent=net\nscript.Parent.FreeModels.HoOhFlight:Clone().Parent=net')
    source(nodes['Server']).text=code;modified.add(nodes['Server'].attrib['referent'])
    code=source(nodes['World']).text
    old='require(script.Parent.DetailedArt.WorldArt).addDecorations(world)'
    source(nodes['World']).text=patch(code,old,old+'\n require(script.Parent.FreeModels.FreeWorld).decorate(world)')
    modified.add(nodes['World'].attrib['referent'])
    art=next(n for n in package.findall('Item') if name(n)=='DetailedArt')
    art_world=next(n for n in art.findall('Item') if name(n)=='WorldArt')
    code=source(art_world).text
    old='return L.create(parent,{model="bellTower",name="SunlitBellPagoda",scale=1.7,cframe=C(44,0,113)})'
    source(art_world).text=patch(code,old,'return require(script.Parent.Parent.FreeModels.FreeWorld).tower(parent)')
    modified.add(art_world.attrib['referent'])
    code=source(nodes['Client']).text
    old="local net=RS:WaitForChild('OPItemNet')"
    code=patch(code,old,old+"\nlocal HoOhFlight=require(net:WaitForChild('HoOhFlight'))")
    old='local serverNow=workspace:GetServerTimeNow()'
    code=patch(code,old,old+'''
 local native=world:FindFirstChild('NativeFreeArt')
 local bird=native and native:FindFirstChild('HoOh')
 local origin=bird and bird:GetAttribute('FlightOrigin')
 if bird and typeof(origin)=='CFrame' then
  HoOhFlight.pose(bird,origin,serverNow-(bird:GetAttribute('FlightEpoch') or serverNow))
 end''')
    source(nodes['Client']).text=code;modified.add(nodes['Client'].attrib['referent'])
    module(package,'FreeCatalog',(ROOT/'roblox/free_models/CatalogAdditions.lua').read_text(),'RBX_FreeCatalog_64')
    folder=ET.SubElement(package,'Item',{'class':'Folder','referent':'RBX_FreeModels_Folder_64'})
    props=ET.SubElement(folder,'Properties');ET.SubElement(props,'string',name='Name').text='FreeModels'
    files=sorted((ROOT/'roblox/free_models').glob('*.lua'))
    for path in files:module(folder,path.stem,path.read_text(),'RBX_FreeModels_64_'+path.stem)
    tree.write(OUT,encoding='utf-8',xml_declaration=True)
    STAGE.mkdir(exist_ok=True)
    def stage(parent,directory):
        directory.mkdir(exist_ok=True)
        for child in parent.findall('Item'):
            value=source(child)
            if value is not None:(directory/(name(child)+'.lua')).write_text(value.text or '')
            elif child.findall('Item'):stage(child,directory/name(child))
    stage(package,STAGE)
    original={n.attrib['referent']:n for n in ET.parse(BASE).iter('Item')}
    updated={n.attrib['referent']:n for n in ET.parse(OUT).iter('Item')}
    assert original.keys()<=updated.keys()
    changed=set()
    for ref,old in original.items():
        new=updated[ref]
        assert old.attrib==new.attrib
        a,b=old.find('Properties'),new.find('Properties')
        assert len(a)==len(b)
        for before,after in zip(a,b):
            if ET.tostring(before)!=ET.tostring(after):
                assert before.tag=='ProtectedString' and before.attrib.get('name')=='Source' and ref in modified
                changed.add(ref)
    assert changed==modified
    assert hashlib.sha256(BASE.read_bytes()).hexdigest()==BASE_SHA
    print(f'Built {OUT.name}: preserved {len(original)} original v63 objects; {len(modified)} visual/catalog integration sources changed; added {len(files)} free native modules.')

if __name__=='__main__':main()
