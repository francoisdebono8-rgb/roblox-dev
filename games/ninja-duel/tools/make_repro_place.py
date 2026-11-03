"""Repro places of the gameplay audit (03/11): one place per bug found by playing.

ND-Bug-<id>.rbxlx is the built Debug place whose server Main also sets the
workspace attribute NinjaDuelRepro = <id>; Server/Repro.luau (debug-only)
stages the bug's situation on join and shows what to look at.

  python3 tools/make_repro_place.py B01 B02 [--out DIR]   (default: dist/repro)

Build the Debug place first (tools/dev.py release); the case ids must exist in
Repro.cases, and the place must carry Repro (it is checked here).
"""
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEBUG_LINE = 'workspace:SetAttribute("NinjaDuelDebug",true)\n'


def cases():
    text = (ROOT / 'src/Server/Repro.luau').read_text(encoding='utf-8')
    return set(re.findall(r'^\t(B\d+)=\{', text, re.M))


def make(case, place, out):
    if place.count(DEBUG_LINE) != 1:
        raise SystemExit('The Debug place should set NinjaDuelDebug exactly once')
    if 'Repro.cases' not in place:
        raise SystemExit('This Debug place has no Server/Repro: rebuild it')
    line = f'workspace:SetAttribute("NinjaDuelRepro","{case}")\n'
    path = out / f'ND-Bug-{case}.rbxlx'
    path.write_bytes(place.replace(DEBUG_LINE, DEBUG_LINE + line).encode('utf-8'))
    return path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('ids', nargs='+')
    parser.add_argument('--out', type=Path, default=ROOT / 'dist/repro')
    args = parser.parse_args()
    known = cases()
    unknown = [i for i in args.ids if i not in known]
    if unknown:
        raise SystemExit(f'Unknown cases {unknown}; Repro.cases has {sorted(known)}')
    place = (ROOT / 'dist/NinjaDuel-Debug.rbxlx').read_bytes().decode('utf-8')
    args.out.mkdir(parents=True, exist_ok=True)
    for case in args.ids:
        print(make(case, place, args.out))


if __name__ == '__main__':
    main()
