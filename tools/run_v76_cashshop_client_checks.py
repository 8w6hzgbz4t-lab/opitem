"""Execute the prepared cash shop LocalScript with an offline GUI adapter."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import tempfile
from run_game_checks import lua_string

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--root',type=Path,default=Path('roblox/v76-game'))
    p.add_argument('--report',type=Path,default=Path('releases/Version76/cashshop-client-checks.json'))
    a=p.parse_args()
    source=(a.root/'CashShopClient.lua').read_text()
    test=Path('tests/v76_cashshop_client.lua').read_text()
    with tempfile.TemporaryDirectory(prefix='v76-shop-') as d:
        script=Path(d)/'check.luau';script.write_text('local SOURCE='+lua_string(source)+'\n'+test)
        r=subprocess.run(['/workspace/.cache/opitem-tools/luau',str(script)],text=True,capture_output=True)
    print(r.stdout,end='');print(r.stderr,end='')
    count=re.search(r'CashShopClient v76 passed (\d+) assertions',r.stdout)
    geometry=subprocess.run(['texlua','tests/v76_cashshop_bench.lua',str(a.root)],text=True,capture_output=True)
    print(geometry.stdout,end='');print(geometry.stderr,end='')
    bench=re.search(r'CashShopBench v76 passed (\d+) assertions; (\d+) parts',geometry.stdout)
    report={'passed':r.returncode==0 and count is not None and geometry.returncode==0 and bench is not None,'assertions':int(count.group(1)) if count else 0,'benchAssertions':int(bench.group(1)) if bench else 0,'benchParts':int(bench.group(2)) if bench else 0,'sourceSha256':hashlib.sha256(source.encode()).hexdigest(),'testSha256':hashlib.sha256(test.encode()).hexdigest(),'benchSourceSha256':hashlib.sha256((a.root/'CashShopBench.lua').read_bytes()).hexdigest(),'benchTestSha256':hashlib.sha256(Path('tests/v76_cashshop_bench.lua').read_bytes()).hexdigest(),'limitations':'Offline GUI/event adapter and recorded real bench geometry. Live Roblox rendering and network not exercised.'}
    a.report.parent.mkdir(parents=True,exist_ok=True);a.report.write_text(json.dumps(report,indent=2)+'\n')
    return 0 if report['passed'] else r.returncode or 1
if __name__=='__main__':raise SystemExit(main())
