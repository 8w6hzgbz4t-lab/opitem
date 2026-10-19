#!/usr/bin/env python3
"""Render a real generated base from its entrance, using a documented cutaway."""
from __future__ import annotations

import argparse
import copy
import json
import os
from pathlib import Path

import numpy as np

from build_puzzle_asset import faces


def local_base(spec: dict) -> list[dict]:
    """Base 1 is at (-84, 0, -57), facing the arena with a pi Y rotation."""
    result = []
    rotation = np.diag([-1., 1., -1.])
    for source in spec['parts']:
        part = copy.deepcopy(source)
        cf = np.asarray(part['cf'], dtype=float)
        center = rotation @ (cf[:3] - [-84., 0., -57.])
        if abs(center[0]) > 26 or abs(center[2]) > 26 or not (-.1 <= center[1] < 19):
            continue
        if part['transparency'] > .8 or part['name']=='ProtectionField':
            continue
        # Remove opaque overhead geometry and the upper wall extension only in
        # this exported illustration. Every wall/roof stays solid in the game.
        if ('Roof' in part['name'] or 'Cornice' in part['name']
                or part['name'].startswith(('SolidSideWall', 'SolidBackWall', 'CornerPier'))
                or center[1] > 13):
            continue
        part['cf'] = list(center) + list((rotation @ cf[3:].reshape(3, 3)).reshape(-1))
        result.append(part)
    return result


def render(spec: dict, ax) -> int:
    from PIL import Image
    parts=local_base(spec)
    view=np.asarray([.271,.707,-.664]);view/=np.linalg.norm(view)
    right=np.cross(view,[0.,1.,0.]);right/=np.linalg.norm(right)
    up=np.cross(right,view)
    light=np.asarray([-.3,.9,-.6]);light/=np.linalg.norm(light)
    polygons=[]
    for part in parts:
        for face in faces(part):
            normal=np.cross(face[1]-face[0],face[2]-face[0])
            length=np.linalg.norm(normal)
            if length<1e-10 or np.dot(normal/length,view)<0:
                continue
            shade=.8+.2*max(0.,np.dot(normal/length,light))
            color=np.clip((np.asarray(part['color'])*shade+.018)*255,0,255)
            points=np.column_stack((face@right,face@up,face@view))
            polygons.append((points,color))
    all_points=np.concatenate([face for face,_ in polygons])
    low=all_points[:,:2].min(axis=0);high=all_points[:,:2].max(axis=0)
    width,height=1500,1200
    scale=min((width-100)/(high[0]-low[0]),(height-100)/(high[1]-low[1]))
    center=(high+low)*.5
    pixels=np.full((height,width,3),(21,27,42),dtype=np.uint8)
    depth=np.full((height,width),-np.inf)
    for face,color in polygons:
        face=face.copy()
        face[:,0]=(face[:,0]-center[0])*scale+width*.5
        face[:,1]=height*.5-(face[:,1]-center[1])*scale
        for index in range(1,len(face)-1):
            triangle=face[[0,index,index+1]]
            x0,y0,z0=triangle[0];x1,y1,z1=triangle[1];x2,y2,z2=triangle[2]
            denominator=(y1-y2)*(x0-x2)+(x2-x1)*(y0-y2)
            if abs(denominator)<1e-8:
                continue
            xmin=max(0,int(np.floor(triangle[:,0].min())))
            xmax=min(width-1,int(np.ceil(triangle[:,0].max())))
            ymin=max(0,int(np.floor(triangle[:,1].min())))
            ymax=min(height-1,int(np.ceil(triangle[:,1].max())))
            if xmax<xmin or ymax<ymin:
                continue
            xx,yy=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
            a=((y1-y2)*(xx-x2)+(x2-x1)*(yy-y2))/denominator
            b=((y2-y0)*(xx-x2)+(x0-x2)*(yy-y2))/denominator
            c=1-a-b
            z=a*z0+b*z1+c*z2
            target=depth[ymin:ymax+1,xmin:xmax+1]
            mask=(a>=-1e-8)&(b>=-1e-8)&(c>=-1e-8)&(z>=target-1e-8)
            target[mask]=z[mask]
            pixels[ymin:ymax+1,xmin:xmax+1][mask]=color.astype(np.uint8)
    ax.imshow(Image.fromarray(pixels));ax.set_axis_off()
    return len(parts)


def main() -> None:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--before',type=Path,default=Path('/tmp/opitem-v72-base-before.json'))
    parser.add_argument('--after',type=Path,default=Path('/tmp/opitem-v72-base-after.json'))
    parser.add_argument('--output',type=Path,default=Path('releases/Version72/BasePresentation.png'))
    args=parser.parse_args()
    os.environ.setdefault('MPLCONFIGDIR','/tmp/opitem-matplotlib')
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig=plt.figure(figsize=(19,10),facecolor='#151b2a')
    counts=[]
    for index,(path,title) in enumerate(((args.before,'BEFORE'),(args.after,'RELIC VAULT FINISH'))):
        ax=fig.add_subplot(1,2,index+1,facecolor='#151b2a')
        counts.append(render(json.loads(path.read_text()),ax))
        ax.set_title(title,color='#ddbc7b',fontsize=18,pad=0)
    fig.text(.05,.94,'Version 72  /  Relic vault presentation',color='#f5eddb',fontsize=25)
    fig.text(.05,.895,'Actual entrance geometry. Roof, upper walls and protection field hidden only in this cutaway.',
             color='#afbacb',fontsize=13)
    fig.text(.05,.06,'Eight functional display slots per base • Original entrance, protection line, collection pad and workstation retained',
             color='#afbacb',fontsize=13)
    fig.text(.05,.025,'Offline geometry preview; Studio lighting and SurfaceGui lettering will differ.',color='#7f91a8',fontsize=11)
    fig.subplots_adjust(left=0,right=1,bottom=.12,top=.86,wspace=-.05)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    fig.savefig(args.output,dpi=140,facecolor=fig.get_facecolor());plt.close(fig)
    print(f'PASS: actual entrance views rendered ({counts[0]} / {counts[1]} parts) to {args.output}')


if __name__=='__main__':
    main()
