#!/usr/bin/env python3
"""Optional fine-data regeneration against main. Not run by check.py/draw.py.

Requires a separately requested measurement run and an already imported project.
Never imports assets, checks out branches, or edits game source. Outputs stay in
ignored verification/c6; collect.py does not replace the coarse envelope file.
"""
import os
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[4]
SCRATCH = ROOT / 'game/workshop/verification/c6'

def main():
    # Avoid mixing a current workshop boot with a different main controller.
    changed = subprocess.check_output(['git','diff','main','--','game/workshop'],cwd=ROOT)
    if changed:
        raise SystemExit('Workshop differs from main; reconcile the measurement baseline first.')
    SCRATCH.mkdir(parents=True,exist_ok=True)
    for path,name in [('game/workshop/scripts/service_crane.gd','main_crane.gd'),
                      ('game/workshop/assets/workshop-layout.json','main-layout.json')]:
        (SCRATCH/name).write_bytes(subprocess.check_output(['git','show',f'main:{path}'],cwd=ROOT))
    godot=Path(os.environ.get('C6_GODOT',str(Path.home()/'.cache/gundam-tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot')))
    with (SCRATCH/'probe.log').open('w') as log:
        result=subprocess.run([str(godot),'--headless','--path','game/workshop','--script',
                               '../../design/game/gantry-v2/probe/c5_probe.gd'],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
    if result.returncode:return result.returncode
    return subprocess.run([sys.executable,str(Path(__file__).with_name('collect.py'))],cwd=ROOT).returncode

if __name__=='__main__':raise SystemExit(main())
