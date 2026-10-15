"""Export real native model geometry, Roblox files, OBJ/MTL, and previews."""
from concurrent.futures import ProcessPoolExecutor
from copy import deepcopy
import html
import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageOps
from build_puzzle_asset import export_xml,faces,preview,value

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'releases/FreeRobloxModels'
SPECS=Path('/tmp/opitem-native-models')

def surface_text(path,spec):
    tree=ET.parse(path)
    model=tree.getroot().find('Item')
    by_name={n.findtext("Properties/string[@name='Name']"):n for n in model.findall('Item')}
    for index,definition in enumerate(spec.get('textOverlays',[])):
        parent=by_name.get(definition['part'])
        if parent is None:continue
        gui=ET.SubElement(parent,'Item',{'class':'SurfaceGui','referent':f'RBXNativeGui{index}'})
        props=ET.SubElement(gui,'Properties')
        value(props,'string','Name','NativeText'+str(index+1));value(props,'token','Face',5)
        value(props,'token','SizingMode',1);value(props,'float','PixelsPerStud',35)
        value(props,'float','LightInfluence',.15);value(props,'float','MaxDistance',300)
        value(props,'bool','AlwaysOnTop','false')
        label=ET.SubElement(gui,'Item',{'class':'TextLabel','referent':f'RBXNativeText{index}'})
        props=ET.SubElement(label,'Properties')
        value(props,'string','Name','Caption');value(props,'string','Text',definition['text'])
        value(props,'float','BackgroundTransparency',1);value(props,'token','Font',19)
        value(props,'float','TextSize',definition['size']);value(props,'bool','TextScaled','false')
        value(props,'bool','TextWrapped','true')
        value(props,'token','TextXAlignment',{'Left':0,'Right':1,'Center':2}[definition['align']])
        value(props,'token','TextYAlignment',1)
        rgb=definition['color'];value(props,'Color3uint8','TextColor3',(255<<24)|(rgb[0]<<16)|(rgb[1]<<8)|rgb[2])
        for property_name,components in {'Position':(0,12,0,6),'Size':(1,-24,1,-12)}.items():
            dimension=ET.SubElement(props,'UDim2',name=property_name)
            for key,component in zip(('XS','XO','YS','YO'),components):ET.SubElement(dimension,key).text=str(component)
    tree.write(path,encoding='utf-8',xml_declaration=True)

def obj_export(spec,key):
    folder=OUT/'obj';folder.mkdir(exist_ok=True)
    materials={};groups={}
    for part in spec['parts']:
        if part['transparency']>=1:continue
        signature=(tuple(round(v,4) for v in part['color']),part['material'],round(part['transparency'],3))
        if signature not in materials:materials[signature]='mat_'+str(len(materials))
        groups.setdefault(signature,[]).extend(faces(part))
    obj=[f'# Native Roblox geometry: {spec["name"]}',f'mtllib {key}.mtl']
    mtl=[];offset=1
    for signature,polygons in groups.items():
        name=materials[signature];color,material,transparency=signature
        obj.extend(['g '+name,'usemtl '+name])
        mtl.extend(['newmtl '+name,'Kd '+' '.join(map(str,color)),'Ka 0.03 0.03 0.03',f'd {1-transparency}',f'Ns {150 if material=="Metal" else 30}'])
        if material=='Neon':mtl.append('Ke '+' '.join(map(str,color)))
        mtl.append('')
        for polygon in polygons:
            for point in polygon:obj.append('v '+' '.join(f'{v:.7g}' for v in point))
            for i in range(1,len(polygon)-1):obj.append(f'f {offset} {offset+i} {offset+i+1}')
            offset+=len(polygon)
    (folder/(key+'.obj')).write_text('\n'.join(obj)+'\n')
    (folder/(key+'.mtl')).write_text('\n'.join(mtl)+'\n')

def front_card(spec,target):
    polygons=[]
    for part in spec['parts']:
        if part['transparency']>=1:continue
        for face in faces(part):
            normal=np.cross(face[1]-face[0],face[2]-face[0]);length=np.linalg.norm(normal)
            if length<1e-9 or abs(normal[2])/length<.03:continue
            shade=.78+.22*abs(normal[2])/length
            color=tuple(int(max(0,min(255,c*shade*255))) for c in part['color'])
            polygons.append((float(face[:,2].mean()),face,color))
    points=np.concatenate([p[1] for p in polygons]);lo,hi=points.min(axis=0),points.max(axis=0)
    scale=min(800/(hi[0]-lo[0]),1100/(hi[1]-lo[1]))
    size=(900,1200);canvas=Image.new('RGB',size,'#171321');draw=ImageDraw.Draw(canvas)
    xmid=(lo[0]+hi[0])/2;ymid=(lo[1]+hi[1])/2
    def xy(x,y):return (size[0]/2+(x-xmid)*scale,size[1]/2-(y-ymid)*scale)
    for _,polygon,color in sorted(polygons,key=lambda p:p[0],reverse=True):
        draw.polygon([xy(p[0],p[1]) for p in polygon],fill=color)
    by_name={p['name']:p for p in spec['parts']}
    for d in spec.get('textOverlays',[]):
        part=by_name.get(d['part'])
        if not part:continue
        x,y=part['cf'][:2];w,h=part['size'][:2]
        left,top=xy(x-w/2,y+h/2);right,bottom=xy(x+w/2,y-h/2)
        padding=12*scale/35;available=right-left-padding*2
        font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',max(10,round(d['size']*scale/35)))
        lines=[]
        for paragraph in d['text'].split('\n'):
            words=paragraph.split();line=''
            for word in words:
                candidate=(line+' '+word).strip()
                if line and draw.textlength(candidate,font=font)>available:lines.append(line);line=word
                else:line=candidate
            lines.append(line)
        lineheight=font.size*1.25;ty=(top+bottom-lineheight*len(lines))/2
        for line in lines:
            tx=left+padding if d['align']=='Left' else right-padding-draw.textlength(line,font=font)
            draw.text((tx,ty),line,font=font,fill=tuple(d['color']));ty+=lineheight
    canvas.save(target)

def render_one(row):
    spec=json.loads((SPECS/(row['key']+'.json')).read_text())
    target=OUT/'previews'/(row['key']+'.png')
    if row['key'] in ('mtg_black_lotus_card','mirror_force_card'):front_card(spec,target)
    else:preview(spec,target,elev=18 if row['role']=='item' else 16)
    return row['key']

def contact(rows,target,columns=4):
    tilew,tileh=330,410
    canvas=Image.new('RGB',(columns*tilew,((len(rows)+columns-1)//columns)*tileh),'#171321')
    draw=ImageDraw.Draw(canvas);font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',17)
    for index,row in enumerate(rows):
        x,y=(index%columns)*tilew,(index//columns)*tileh
        img=ImageOps.contain(Image.open(OUT/'previews'/(row['key']+'.png')).convert('RGB'),(tilew-10,tileh-60))
        canvas.paste(img,(x+(tilew-img.width)//2,y))
        label='Painting frame - reference needed' if row.get('reference_required') else row['name']
        words=label.split();lines=['']
        for word in words:
            if len(lines[-1])+len(word)>29:lines.append(word)
            else:lines[-1]=(lines[-1]+' '+word).strip()
        for n,line in enumerate(lines[:2]):draw.text((x+12,y+tileh-54+n*21),line,font=font,fill='#f6e8ce')
    canvas.save(target)

def galleries(rows):
    root=ET.Element('roblox',version='4')
    folder=ET.SubElement(root,'Item',{'class':'Folder','referent':'RBX_FreeNativeGallery'})
    props=ET.SubElement(folder,'Properties');value(props,'string','Name','FreeNativeModelGallery')
    for index,row in enumerate(rows):
        model=deepcopy(ET.parse(OUT/'models'/(row['key']+'.rbxmx')).getroot().find('Item'))
        spec=json.loads((SPECS/(row['key']+'.json')).read_text())
        scale=min(1,8/max(spec['bounds']['size']))
        move=((index%6-2.5)*12,6,(index//6)*14)
        for node in model.iter('Item'):node.attrib['referent']=row['key']+'_'+node.attrib['referent']
        for ref in model.iter('Ref'):
            if ref.text not in ('null','nil',None):ref.text=row['key']+'_'+ref.text
        for cf in model.iter('CoordinateFrame'):
            if cf.attrib.get('name')=='CFrame':
                for axis,delta in zip(('X','Y','Z'),move):cf.find(axis).text=str(float(cf.find(axis).text)*scale+delta)
        for size in model.iter('Vector3'):
            if size.attrib.get('name')=='size':
                for component in size:component.text=str(float(component.text)*scale)
        for size in model.iter('float'):
            if size.attrib.get('name')=='TextSize':size.text=str(max(6,float(size.text)*scale))
        folder.append(model)
    ET.ElementTree(root).write(OUT/'FreeNativeModelGallery.rbxmx',encoding='utf-8',xml_declaration=True)
    place=ET.Element('roblox',version='4')
    world=ET.SubElement(place,'Item',{'class':'Workspace','referent':'RBX_FreeGalleryWorkspace'})
    props=ET.SubElement(world,'Properties');value(props,'string','Name','Workspace');world.append(deepcopy(folder))
    value(props,'Ref','CurrentCamera','RBX_FreeGalleryCamera')
    camera=ET.SubElement(world,'Item',{'class':'Camera','referent':'RBX_FreeGalleryCamera'})
    camera_props=ET.SubElement(camera,'Properties');value(camera_props,'string','Name','Camera');value(camera_props,'float','FieldOfView',60)
    eye=np.array([66.,75.,120.]);target=np.array([0.,6.,35.]);forward=target-eye;forward/=np.linalg.norm(forward)
    right=np.cross(forward,np.array([0.,1.,0.]));right/=np.linalg.norm(right);up=np.cross(right,forward)
    rotation=np.column_stack((right,up,-forward))
    cf=ET.SubElement(camera_props,'CoordinateFrame',name='CFrame')
    for key,number in zip(('X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'),[*eye,*rotation.flatten()]):ET.SubElement(cf,key).text=str(number)
    ET.ElementTree(place).write(OUT/'FreeNativeModelGallery.rbxlx',encoding='utf-8',xml_declaration=True)

def builders():
    root=ET.Element('roblox',version='4');folder=ET.SubElement(root,'Item',{'class':'Folder','referent':'RBX_FreeNativeBuilders'})
    props=ET.SubElement(folder,'Properties');value(props,'string','Name','FreeModels')
    for path in sorted((ROOT/'roblox/free_models').glob('*.lua')):
        node=ET.SubElement(folder,'Item',{'class':'ModuleScript','referent':'RBX_FreeBuilder_'+path.stem})
        props=ET.SubElement(node,'Properties');value(props,'string','Name',path.stem);value(props,'ProtectedString','Source',path.read_text())
    ET.ElementTree(root).write(OUT/'FreeNativeBuilders.rbxmx',encoding='utf-8',xml_declaration=True)

def main():
    for folder in (OUT,OUT/'models',OUT/'previews'):folder.mkdir(exist_ok=True)
    SPECS.mkdir(exist_ok=True)
    subprocess.run(['texlua','tools/record_free_models.lua',str(SPECS)],cwd=ROOT,check=True)
    rows=json.loads((ROOT/'docs/free-model-catalog.json').read_text())
    rows.append(dict(key='hooh_complete',name='Ho-Oh Complete Bird',role='decoration',reference_required=False))
    manifest=[]
    for row in rows:
        spec=json.loads((SPECS/(row['key']+'.json')).read_text())
        target=OUT/'models'/(row['key']+'.rbxmx');export_xml(spec,target);surface_text(target,spec)
        obj_export(spec,row['key'])
        manifest.append({**row,'parts':len(spec['parts']),'size':spec['bounds']['size'],'status':'frame_ready_reference_needed' if row['reference_required'] else 'built'})
    with ProcessPoolExecutor(max_workers=3) as pool:
        for key in pool.map(render_one,rows):print('Rendered '+key,flush=True)
    item_rows=[r for r in rows if r['role']=='item']
    scene_rows=[r for r in rows if r['role']!='item' and not r['key'].startswith('hooh_wing') and r['key'] not in ('hooh_body','hooh_tail')]
    contact(item_rows,OUT/'NewItems.png');contact(scene_rows,OUT/'NewDecorations.png',4)
    galleries(rows);builders()
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    cards=[]
    for row in rows:
        key=row['key'];status='Frame awaiting reference image' if row['reference_required'] else 'Complete native geometry'
        cards.append(f'<article><a href="previews/{key}.png"><img src="previews/{key}.png"></a><h2>{html.escape(row["name"])}</h2><p>{status}</p><a href="models/{key}.rbxmx">Roblox model</a> · <a href="obj/{key}.obj">OBJ</a></article>')
    (OUT/'gallery.html').write_text('<!doctype html><meta charset="utf-8"><title>Free Roblox models</title><style>body{background:#171321;color:#f6e8ce;font:16px system-ui;margin:24px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:20px}article{background:#241c32;padding:14px;border-radius:12px}img{width:100%;height:300px;object-fit:contain}h2{font-size:18px}a{color:#ddbbff}</style><h1>Free native Roblox models</h1><p>Actual model geometry. No paid AI or API. Studio lighting differs from these offline previews.</p><main>'+''.join(cards)+'</main>')
    print(f'PASS: {len(rows)} actual model exports, OBJ/MTL files, previews, galleries and complete builder modules')

if __name__=='__main__':main()
