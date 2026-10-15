"""Export recorded generated-world geometry and an offline cutaway overview."""
from pathlib import Path
import json
import os
import subprocess

import numpy as np
from build_puzzle_asset import export_xml, faces, preview
from PIL import Image,ImageDraw,ImageFont,ImageOps

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'releases/DetailedArt'

def overview(spec, output=None, title='Steal An OP Item — version 63'):
    os.environ.setdefault('MPLCONFIGDIR','/tmp/opitem-matplotlib')
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    from mpl_toolkits.mplot3d.art3d import Poly3DCollection
    polygons,colors=[],[]
    light=np.array([-.3,-.7,1.]);light/=np.linalg.norm(light)
    for part in spec['parts']:
        # Remove the enclosing dome surface for this overview only.
        if part['transparency']>=1 or part['name'].startswith(('DomainPanel','DomainBackstop')):
            continue
        for face in faces(part):
            normal=np.cross(face[1]-face[0],face[2]-face[0]);length=np.linalg.norm(normal)
            shade=.72+.28*max(0,np.dot(normal/length,light)) if length>1e-10 else .8
            polygons.append(face[:,[0,2,1]])
            colors.append(np.clip(np.array(part['color'])*shade,0,1))
    fig=plt.figure(figsize=(15,10),facecolor='#171321')
    ax=fig.add_subplot(111,projection='3d',facecolor='#171321')
    ax.add_collection3d(Poly3DCollection(polygons,facecolors=colors,linewidths=0,zsort='average'))
    ax.set_xlim(-175,175);ax.set_ylim(-185,185);ax.set_zlim(-10,155)
    ax.set_box_aspect((350,370,165));ax.view_init(elev=28,azim=-62);ax.set_axis_off()
    fig.text(.04,.95,title,color='#f6e8ce',fontsize=23)
    fig.text(.04,.91,'Generated geometry overview • dome surface removed for visibility • Studio lighting will differ',color='#b8a7ce',fontsize=12)
    fig.subplots_adjust(left=0,right=1,bottom=0,top=.9)
    fig.savefig(output or OUT/'WorldOverview.png',dpi=120,facecolor=fig.get_facecolor());plt.close(fig)

def main():
    OUT.mkdir(exist_ok=True)
    subprocess.run(['texlua','tests/world_integration.lua'],cwd=ROOT,check=True)
    subprocess.run(['texlua','tools/record_extra_decor.lua'],cwd=ROOT,check=True)
    spec=json.loads(Path('/tmp/opitem-full-world.json').read_text())
    export_xml(spec,OUT/'GeneratedWorldSnapshot.rbxmx')
    overview(spec)
    for name in ('CrimsonDragon','Shenron','MirrorForce','Racetrack'):
        path=Path('/tmp')/f'opitem-{name}.json'
        geometry=json.loads(path.read_text())
        export_xml(geometry,OUT/f'{name}.rbxmx')
        preview(geometry,OUT/f'{name}.png',elev=25 if name=='Racetrack' else 12)
    raised=json.loads(Path('/tmp/opitem-RaisedTrackWithWalls.json').read_text())
    preview(raised,OUT/'RaisedTrackWithWalls.png',elev=26,azim=-62,figsize=(13,7))
    names=('CrimsonDragon','Shenron','MirrorForce','Racetrack')
    canvas=Image.new('RGB',(2000,665),'#171321');draw=ImageDraw.Draw(canvas)
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',20)
    for i,name in enumerate(names):
        img=ImageOps.contain(Image.open(OUT/f'{name}.png').convert('RGB'),(500,620))
        canvas.paste(img,(i*500+(500-img.width)//2,35))
        draw.text((i*500+16,12),name,font=font,fill='#f6e8ce')
    canvas.save(OUT/'NewScenery.png')
    print(f'PASS: exported {len(spec["parts"])}-part generated-world snapshot, overview and four scenic models/previews')

if __name__=='__main__':main()
