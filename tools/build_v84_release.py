"""Build the display-only earnings fix; preserve V83 gameplay and place objects."""
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import xml.etree.ElementTree as ET

from build_v72_place import package, sources
from run_game_checks import lua_string

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'releases/StealAnOPItem_83_SellAndWorkbenches.rbxlx'
BASE_SHA = '85878dd2e91db6c3778ab2f6267e76154c2a65fc7ca2f9ec12dcb21e394bbe7c'
STAGE = ROOT / 'roblox/v84-game'
OUT = ROOT / 'releases/StealAnOPItem_84_CleanEarnings.rbxlx'
RELEASE = ROOT / 'releases/Version84'
OLD = "    b.bank.Text='$'..state.bank..' READY\\nCOLLECT / DELIVER'"
NEW = "    b.bank.Text=string.format('$%.0f READY\\nCOLLECT / DELIVER',math.floor(state.bank))"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    assert sha(BASE) == BASE_SHA
    baseline_sources = {p.relative_to(ROOT / 'roblox/v83-game').as_posix(): p
                        for p in (ROOT / 'roblox/v83-game').rglob('*.lua')}
    staged = {p.relative_to(STAGE).as_posix(): p for p in STAGE.rglob('*.lua')}
    assert staged.keys() == baseline_sources.keys() and len(staged) == 109
    baseline_server = baseline_sources['Server.lua'].read_text()
    assert baseline_server.count(OLD) == 1
    assert staged['Server.lua'].read_text() == baseline_server.replace(OLD, NEW, 1)
    assert {k for k in staged if sha(staged[k]) != sha(baseline_sources[k])} == {'Server.lua'}

    original = ET.parse(BASE).getroot()
    root = deepcopy(original)
    before, current = sources(package(original)), sources(package(root))
    assert current.keys() == staged.keys()
    for key, path in staged.items():
        assert before[key].findtext("Properties/ProtectedString[@name='Source']") == baseline_sources[key].read_text()
        current[key].find("Properties/ProtectedString[@name='Source']").text = path.read_text()
    old = {n.get('referent'): n for n in original.iter('Item')}
    new = {n.get('referent'): n for n in root.iter('Item')}
    assert old.keys() == new.keys() and len(new) == 315 == sum(1 for _ in root.iter('Item'))
    edited = current['Server.lua'].get('referent')
    for ref, a in old.items():
        b = new[ref]
        assert a.attrib == b.attrib
        pa, pb = deepcopy(a.find('Properties')), deepcopy(b.find('Properties'))
        if ref == edited:
            pa.find("ProtectedString[@name='Source']").text = ''
            pb.find("ProtectedString[@name='Source']").text = ''
        assert ET.tostring(pa) == ET.tostring(pb), ref
        assert [n.get('referent') for n in a.findall('Item')] == [n.get('referent') for n in b.findall('Item')]
    for ref in root.iter('Ref'):
        assert ref.text in new or ref.text in {None, 'nil', 'null'}
    ET.ElementTree(root).write(OUT, encoding='utf-8', xml_declaration=True)
    for key, node in sources(package(ET.parse(OUT).getroot())).items():
        assert node.findtext("Properties/ProtectedString[@name='Source']") == staged[key].read_text()
    assert sha(BASE) == BASE_SHA

    # Reproduce the reported number and accumulated fractional earnings using
    # the exact production display statement; the balance must not be mutated.
    harness = 'local display=assert(loadstring(' + lua_string('return function(b,state)\n' + NEW + '\nend') + '))()\n'
    harness += r'''
local values={0,.999999999999,1306.3000000000002,2000000000}
local expected={0,0,1306,2000000000}
local accumulated=0;for _=1,7 do accumulated+=3.15 end
values[#values+1]=accumulated;expected[#expected+1]=22
for i,value in ipairs(values)do
 local b={bank={}};local state={bank=value}
 display(b,state)
 assert(b.bank.Text=='$'..expected[i]..' READY\nCOLLECT / DELIVER','Incorrect available earnings label')
 assert(state.bank==value,'Displaying earnings changed the saved balance')
 print(string.format('BANK DISPLAY %.17g -> %s; balance retained',value,b.bank.Text:gsub('\n',' / ')))
end
'''
    with tempfile.TemporaryDirectory(prefix='opitem-v84-display-') as task:
        script = Path(task) / 'display.luau'
        script.write_text(harness)
        result = subprocess.run(['/workspace/.cache/opitem-tools/luau', str(script)], text=True, capture_output=True)
    print(result.stdout, end='')
    assert result.returncode == 0, result.stderr
    report = {
        'baseline': BASE.name, 'baseline_sha256': BASE_SHA,
        'output': OUT.name, 'output_sha256': sha(OUT),
        'active_sources': len(staged), 'source_hashes': {k: sha(p) for k, p in sorted(staged.items())},
        'modified_sources': ['Server.lua'], 'added_modules': [],
        'original_objects_preserved': len(old), 'total_objects': len(new),
        'only_change': 'Base collection sign displays whole dollars instead of raw floating-point text',
        'all_other_original_properties_hierarchy_and_backups_preserved': True,
        'all_76_collectible_models_catalog_names_stats_and_spawn_weights_preserved': True,
        'saved_fractional_earnings_and_collection_logic_unchanged': True,
        'product_ids_audio_id_checkout_flags_unchanged': True,
        'display_smoke_examples': result.stdout.splitlines(),
        'display_smoke_source': harness,
        'display_smoke_runtime': 'Official Luau CLI executing the verbatim production sign statement',
        'studio_playtest_performed': False, 'published_to_roblox': False,
    }
    RELEASE.mkdir(parents=True, exist_ok=True)
    (RELEASE / 'preservation-report.json').write_text(json.dumps(report, indent=2) + '\n')
    print('Built ' + OUT.name + '; only one display statement changed; all 315 objects retained')
    print('SHA256 ' + sha(OUT))


if __name__ == '__main__':
    main()
