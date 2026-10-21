"""Render the actual shared conveyor/index factory geometry for all 76 items."""
import argparse
from concurrent.futures import ProcessPoolExecutor
import hashlib
import json
from pathlib import Path
from audit_v70_items import render_one,contact_sheet
def render_shared(job):
    item=render_one(job)
    if item=='krabby_patty_formula':
        # Formula surfaces use 160 pixels/stud, unlike the older front renderer's
        # 35-pixel default. Match the actual label sizes instead of oversizing text.
        from export_free_models import front_card
        spec=json.loads(Path(job[0]).read_text())
        for row in spec['textOverlays']:
            row['color']=[round(x*255)for x in row['color']]
            row['size']=(34 if row['part']=='FormulaLabel'else 17)*35/160
            row['align']='Right'
        front_card(spec,Path(job[1]))
    return item
def main():
    p=argparse.ArgumentParser();p.add_argument('--specs',type=Path,default=Path('/tmp/opitem-v78-items'));p.add_argument('--output',type=Path,default=Path('releases/Version78'));a=p.parse_args()
    manifest=json.loads((a.output/'items-manifest.json').read_text());rows=manifest['items'];assert len(rows)==76
    folder=a.output/'previews';folder.mkdir(parents=True,exist_ok=True)
    jobs=[(str(a.specs/(row['id']+'.json')),str(folder/(row['id']+'.png')))for row in rows]
    with ProcessPoolExecutor(max_workers=2)as pool:
        for i,item in enumerate(pool.map(render_shared,jobs),1):
            if i%16==0:print('Rendered',i,'of 76 shared item models',flush=True)
    contact_sheet(rows,folder,a.output/'All76Items.png',columns=8)
    report={'passed':True,'items':76,'source':'Recorded actual ModelFactory output used by conveyor and index',
            'sheet_sha256':hashlib.sha256((a.output/'All76Items.png').read_bytes()).hexdigest(),
            'rendered_model_geometry_hashes':{row['id']:row['geometry_sha256']for row in rows},
            'limitations':'Offline native-geometry previews. Studio lighting, materials and SurfaceGui rendering need live review.'}
    (a.output/'item-preview-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Wrote All76Items.png from every actual shared template')
if __name__=='__main__':main()
