#!/usr/bin/env python3
"""Audit the actual place item factory and render reproducible geometry previews."""
from __future__ import annotations

import argparse
from concurrent.futures import ProcessPoolExecutor
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile

from PIL import Image, ImageDraw, ImageFont, ImageOps

from build_puzzle_asset import preview
from run_game_checks import lua_string

ROOT = Path(__file__).resolve().parents[1]


def compile_sources(source_root: Path, luau: str) -> None:
    sources = sorted(source_root.rglob('*.lua'))
    lines = ['local count=0']
    for path in sources:
        lines.append(f'assert(loadstring({lua_string(path.read_text())},{lua_string(str(path))})); count=count+1')
    lines.append('print(string.format("PASS: official Luau compiled %d actual staged sources",count))')
    with tempfile.TemporaryDirectory(prefix='opitem-v70-syntax-') as temporary:
        harness = Path(temporary)/'compile.luau'
        harness.write_text('\n'.join(lines))
        subprocess.run([luau, str(harness)], cwd=ROOT, check=True)


def render_one(job: tuple[str,str]) -> str:
    spec_path, target = map(Path, job)
    spec = json.loads(spec_path.read_text())
    elevation=30 if spec.get('id')=='black_lotus' else 16 if spec.get('id')=='item44' else 12
    preview(spec, target, elev=elevation, azim=-12 if spec.get('id')=='item44' else -68, figsize=(4,5))
    if spec.get('textOverlays'):
        # The 3D geometry renderer cannot draw SurfaceGui objects. Keep its view,
        # and use an actual front projection with recorded text for the contact sheet.
        from export_free_models import front_card
        target.replace(target.with_stem(target.stem+'-3d'))
        for definition in spec['textOverlays']:
            definition['color']=[round(value*255) for value in definition['color']]
            definition['size']=18
            definition['align']='Center'
        front_card(spec,target)
    return spec_path.stem


def contact_sheet(rows: list[dict], folder: Path, target: Path, columns: int = 5) -> None:
    tile_width,tile_height=280,365
    canvas=Image.new('RGB',(columns*tile_width,((len(rows)+columns-1)//columns)*tile_height),'#171321')
    draw=ImageDraw.Draw(canvas)
    font=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',15)
    small=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',12)
    for index,row in enumerate(rows):
        x,y=(index%columns)*tile_width,(index//columns)*tile_height
        picture=ImageOps.contain(Image.open(folder/(row['id']+'.png')).convert('RGB'),(tile_width,tile_height-63))
        canvas.paste(picture,(x+(tile_width-picture.width)//2,y))
        words=row['name'].split();lines=['']
        for word in words:
            if len(lines[-1])+len(word)>29:lines.append(word)
            else:lines[-1]=(lines[-1]+' '+word).strip()
        for line_number,line in enumerate(lines[:2]):
            draw.text((x+10,y+tile_height-61+line_number*18),line,font=font,fill='#f6e8ce')
        draw.text((x+10,y+tile_height-21),f"{row['id']} | {row['visible_parts']} visible parts",font=small,fill='#b4bdd0')
    canvas.save(target)


def main() -> None:
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root',type=Path,default=ROOT/'roblox/v70-game')
    parser.add_argument('--baseline',type=Path,default=ROOT/'roblox/v69-original/OPItemV2')
    parser.add_argument('--specs',type=Path,default=Path('/tmp/opitem-v70-items'))
    parser.add_argument('--output',type=Path,default=ROOT/'releases/Version70Items')
    parser.add_argument('--luau',default='/workspace/.cache/opitem-tools/luau')
    parser.add_argument('--skip-previews',action='store_true')
    parser.add_argument('--workers',type=int,default=4)
    args=parser.parse_args()
    args.specs.mkdir(parents=True,exist_ok=True)
    args.output.mkdir(parents=True,exist_ok=True)
    compile_sources(args.root,args.luau)
    subprocess.run(['texlua','tests/v70_item_audit.lua',str(args.root),str(args.specs),str(args.baseline)],cwd=ROOT,check=True)
    report=json.loads((args.specs/'audit.json').read_text())
    # Two differently named entries must not silently be the same visible model.
    signatures={}
    for row in report['items']:
        spec=json.loads((args.specs/(row['id']+'.json')).read_text())
        geometry=[{key:part[key] for key in ('class','size','cf','color','material','shape','transparency')}
                  for part in spec['parts'] if part['transparency']<1]
        signature=hashlib.sha256(json.dumps(geometry,sort_keys=True).encode()).hexdigest()
        if signature in signatures:
            raise AssertionError(f"Duplicate visible geometry: {signatures[signature]} / {row['id']}")
        signatures[signature]=row['id']
        row['geometry_sha256']=signature
    report['distinct_geometry']=True
    report['limitations']=['Offline geometry previews approximate Roblox rendering.','Studio multiplayer, physics and performance were not simulated.']
    report['sources_sha256']={str(path.relative_to(args.root)):hashlib.sha256(path.read_bytes()).hexdigest()
                              for path in sorted(args.root.rglob('*.lua'))}
    (args.output/'manifest.json').write_text(json.dumps(report,indent=2)+'\n')
    if not args.skip_previews:
        previews=args.output/'previews';previews.mkdir(exist_ok=True)
        jobs=[(str(args.specs/(row['id']+'.json')),str(previews/(row['id']+'.png'))) for row in report['items']]
        with ProcessPoolExecutor(max_workers=args.workers) as executor:
            for index,key in enumerate(executor.map(render_one,jobs),1):
                if index%10==0 or index==len(jobs):print(f'Previewed {index}/{len(jobs)}: {key}',flush=True)
        contact_sheet(report['items'],previews,args.output/'All65Items.png')
        contact_sheet([row for row in report['items'] if row['new']],previews,args.output/'New19Items.png')
        focus={'item08','item43','item44','item45','item46','black_lotus','death_note'}
        contact_sheet([row for row in report['items'] if row['id'] in focus],previews,args.output/'RecentItemsAndPuzzle.png',4)
    print(f"PASS: {len(report['items'])} distinct collectible models; {report['checks']} geometry/catalog checks; exact Puzzle preserved")
    print(f'Wrote {args.output}')


if __name__=='__main__':
    main()
