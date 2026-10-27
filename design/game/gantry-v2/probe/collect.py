#!/usr/bin/env python3
"""Keep regenerable fine measurements outside the coarse design package."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT=Path(__file__).resolve().parents[4]
SCRATCH=ROOT/'game/workshop/verification/c6'

def main():
    raw=json.loads((SCRATCH/'runtime.json').read_text())
    log=(SCRATCH/'probe.log').read_text()
    assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log, 'Probe errors invalidate measurements'
    assert len(raw['runs'])==16 and raw['runs'][-1]['stage']=='complete'
    main_layout=subprocess.check_output(['git','show','main:game/workshop/assets/workshop-layout.json'],cwd=ROOT)
    assert main_layout==(SCRATCH/'main-layout.json').read_bytes(), 'Main moved during measurement'
    assert set(r['id'] for r in raw['crane'])==set(json.loads(main_layout)['crane']['tasks'])
    raw['provenance']={'main_commit':subprocess.check_output(['git','rev-parse','main'],cwd=ROOT,text=True).strip(),
        'layout_sha256':hashlib.sha256(main_layout).hexdigest(),
        'method':'Baseline runtime own meshes, rail/backpack poses and main authored crane endpoint geometry; not gameplay acceptance.'}
    output=SCRATCH/'fine-envelopes.json'
    output.write_text(json.dumps(raw,indent=2)+'\n')
    print(f'Fine data: {output}; coarse envelopes intentionally unchanged.')

if __name__=='__main__':main()
