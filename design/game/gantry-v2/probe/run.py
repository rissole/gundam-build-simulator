#!/usr/bin/env python3
"""Reproduce C5 measurements without checking out or editing branch A."""
import os
from pathlib import Path
import subprocess
import sys
ROOT=Path(__file__).resolve().parents[4]
SCRATCH=ROOT/'game/workshop/verification/c5'
SCRATCH.mkdir(parents=True,exist_ok=True)
godot=Path(os.environ.get('C5_GODOT', str(Path.home()/'.cache/gundam-tools/Godot-4.7.2/Godot.app/Contents/MacOS/Godot')))
for path,name in [('game/workshop/scripts/service_crane.gd','branch_crane.gd'),('game/workshop/assets/workshop-layout.json','branch-layout.json')]:
    data=subprocess.check_output(['git','show',f'crane-operator-view:{path}'],cwd=ROOT)
    (SCRATCH/name).write_bytes(data)
with (SCRATCH/'probe.log').open('w') as log:
    result=subprocess.run([str(godot),'--headless','--path','game/workshop','--script','../../design/game/gantry-v2/probe/c5_probe.gd'],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT)
if result.returncode:sys.exit(result.returncode)
subprocess.run([sys.executable,str(Path(__file__).with_name('collect.py'))],cwd=ROOT,check=True)
