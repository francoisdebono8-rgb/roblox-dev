"""Ninja Duel local developer CLI (Codex's tools/dev.py, ported to this tree).

Local tooling only: it never edits gameplay or movesets, never publishes,
commits or pushes, and never downloads anything. From games/ninja-duel:

  python tools/dev.py verify                 Luau syntax, lab catalogue, every headless suite,
                                             then tests/test_build_isolation.py if dist/ is built
  python tools/dev.py build --kind debug     main | debug | qa (build.py runs the suites itself)
  python tools/dev.py release                verify, the three builds, then the isolation test
  python tools/dev.py audit --baseline REV   are the gameplay core files byte-identical to REV?
  python tools/dev.py compare [--out FILE]   active fighters: routes, tool, awakening, techniques
  python tools/dev.py catalogue [--archetype A] [--family F]
  python tools/dev.py report --log FILE [--manifest dist/NinjaDuel-Debug.json] [--out FILE]

Tools: LUAU / LUNE / LUAU_COMPILE, then NINJA_DUEL_TOOLS, the usual shared
folders (/private/tmp/ninja-duel-tools, %LOCALAPPDATA%/ninja-duel-tools), PATH.
"""
from pathlib import Path
import argparse
import ast
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
# Gameplay and presentation sources a tooling pass must leave byte-identical.
CORE = ['Shared/Config', 'Shared/Fighters', 'Shared/Attacks', 'Shared/MoveGraphs', 'Shared/Controls', 'Shared/Rules',
        'Server/Combat', 'Server/Brawler', 'Server/Motor', 'Server/Matches', 'Server/Techniques', 'Server/AI', 'Server/World',
        'Server/Online', 'Server/Tutorial', 'Client/Camera', 'Client/VelmoraMotionEngine', 'Client/Presentation', 'Client/UI',
        'Client/Input', 'Client/Effects']
KINDS = {'main': [], 'debug': ['--debug'], 'qa': ['--qa']}
ARTIFACTS = ('NinjaDuel.rbxlx', 'NinjaDuel-Debug.rbxlx', 'NinjaDuel-QA.rbxlx')
MARKERS = {'[NinjaDuelPerf] ': 'perf', '[NinjaDuelDevQA] RESULT ': 'devQA', '[NinjaDuelChakraQA] RESULT ': 'chakraQA'}


def tool(name):
    variable = name.upper().replace('-', '_')
    folders = [os.environ.get('NINJA_DUEL_TOOLS', ''), '/private/tmp/ninja-duel-tools']
    if os.environ.get('LOCALAPPDATA'):
        folders.append(os.path.join(os.environ['LOCALAPPDATA'], 'ninja-duel-tools'))
    candidates = [os.environ.get(variable, '')]
    for folder in folders:
        if folder:
            candidates += [os.path.join(folder, name), os.path.join(folder, name + '.exe')]
    candidates.append(name)
    for candidate in candidates:
        if candidate and (Path(candidate).is_file() or shutil.which(candidate)):
            return candidate
    raise SystemExit(f'Missing {name}: set {variable} or NINJA_DUEL_TOOLS (nothing is downloaded)')


def suites():
    """The headless suites, read from build.py's TEST_RUNNERS (one list for both)."""
    tree = ast.parse((ROOT / 'build.py').read_text(encoding='utf-8'))
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'TEST_RUNNERS' for t in node.targets):
            return ast.literal_eval(node.value)
    raise SystemExit('TEST_RUNNERS not found in build.py')


def validate_catalogue():
    data = json.loads((ROOT / 'lab/combat-library.json').read_text(encoding='utf-8'))
    ids, archetypes = set(), set(data['archetypes'])
    for entry in data['entries']:
        assert entry['id'] not in ids, entry['id']
        ids.add(entry['id'])
        assert entry['status'] == 'proposal_only' and set(entry['archetypes']) <= archetypes, entry['id']
        for key in ('usage', 'context', 'technicalDifficulty', 'conflictRisk', 'integrationNotes', 'sequence', 'acceptance'):
            assert entry[key], (entry['id'], key)
        assert entry['value']['visual'] and entry['value']['gameplay'], entry['id']
    for variant in data['characterVariants'].values():
        assert set(variant) <= ids, variant
    for template in sorted((ROOT / 'lab/templates').glob('*.json')):
        assert json.loads(template.read_text(encoding='utf-8'))['status'] == 'draft_not_runtime', template.name
    return data


def isolation():
    if not all((ROOT / 'dist' / name).is_file() for name in ARTIFACTS):
        print('SKIP  tests/test_build_isolation.py (build main, debug and qa first)')
        return True
    sys.stdout.flush()
    return subprocess.run([sys.executable, '-I', str(ROOT / 'tests/test_build_isolation.py')], cwd=ROOT).returncode == 0


def verify(with_isolation=True):
    compiler = tool('luau-compile')
    sources = sorted((ROOT / 'src').rglob('*.luau'))
    for source in sources:
        proc = subprocess.run([compiler, str(source)], capture_output=True, text=True)
        if proc.returncode:
            raise SystemExit(f'Luau syntax failure: {source}\n{proc.stderr}')
    print(f'PASS  Luau syntax ({len(sources)} sources)')
    data = validate_catalogue()
    print(f"PASS  lab catalogue ({len(data['entries'])} proposals, inert)")
    engines = {'luau': tool('luau'), 'lune': tool('lune')}
    failed = []
    for engine, spec in suites():
        command = [engines[engine], 'run', spec] if engine == 'lune' else [engines[engine], spec]
        proc = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace')
        lines = (proc.stdout or '').strip().splitlines()
        summary = lines[-1] if lines else ''
        ok = proc.returncode == 0 and re.search(r'\d+ PASS', summary) is not None
        print(f"{'PASS' if ok else 'FAIL'}  {spec}  {summary}")
        if not ok:
            failed.append(spec)
    if with_isolation and not isolation():
        failed.append('tests/test_build_isolation.py')
    if failed:
        raise SystemExit('verify FAILED: ' + ', '.join(failed))
    print('verify: PASS')


def build(kind):
    sys.stdout.flush()
    subprocess.run([sys.executable, '-I', 'build.py', *KINDS[kind]], cwd=ROOT, check=True)


def audit(baseline):
    rows = []
    for name in CORE:
        path = 'src/' + name + '.luau'
        proc = subprocess.run(['git', 'show', f'{baseline}:./{path}'], cwd=ROOT, capture_output=True)
        data = (ROOT / path).read_bytes()
        rows.append({'path': path, 'unchanged': proc.returncode == 0 and data == proc.stdout,
                     'atBaseline': proc.returncode == 0, 'sha256': hashlib.sha256(data).hexdigest()})
    result = {'baseline': baseline, 'allUnchanged': all(r['unchanged'] for r in rows), 'files': rows}
    print(json.dumps(result, indent=2))
    return result


def compare(out):
    proc = subprocess.run([tool('lune'), 'run', 'tools/inspect.luau'], cwd=ROOT, capture_output=True, text=True,
                          encoding='utf-8', errors='replace')
    if proc.returncode:
        raise SystemExit('tools/inspect.luau failed\n' + proc.stderr)
    data = json.loads(proc.stdout)
    graphs, table = data['graphs'], []
    for fighter_id, fighter in sorted(data['fighters'].items()):
        graph = graphs.get(fighter_id, {})
        table.append({'id': fighter_id, 'name': fighter['Name'], 'routes': graph.get('routes', {}), 'heavyAfterOne': graph.get('heavyAfterOne'),
                      'disengage': graph.get('disengage'), 'tool': fighter.get('ToolMastery'), 'awakening': fighter.get('Awakening'),
                      'techniques': [t['Id'] for t in fighter['Techniques']], 'attackOverrides': fighter.get('AttackProfile', {})})
    for row in table:
        print(row['id'], row['name'], json.dumps(row['routes'], ensure_ascii=False))
    if out:
        report = {'source': 'active shared tables (read-only snapshot; regenerate after any data change)', 'comparison': table, 'definitions': data}
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
        print(out)


def read_reports(log, fingerprint):
    """Rows of this exact build only; a run counts once its begin/end rows frame every row."""
    decoder = json.JSONDecoder()
    runs, results, malformed = {}, {'devQA': [], 'chakraQA': []}, 0
    for line in log.read_text(encoding='utf-8', errors='replace').splitlines():
        for marker, target in MARKERS.items():
            if marker not in line:
                continue
            try:
                # Studio's Output may append " - Server - Script:line" after the JSON.
                row, _ = decoder.raw_decode(line.split(marker, 1)[1].lstrip())
            except json.JSONDecodeError:
                malformed += 1
                continue
            if not isinstance(row, dict) or row.get('build') != fingerprint:
                continue
            if target != 'perf':
                results[target].append(row)
                continue
            entry = runs.setdefault(row.get('id'), {'build': fingerprint, 'server': {'stats': {}, 'counters': {}, 'events': []},
                                                     'client': {'stats': {}, 'counters': {}, 'events': []}, 'rows': 0, 'complete': False})
            kind = row.get('kind')
            if kind == 'begin':
                entry['clientPresent'] = row.get('clientPresent')
            elif kind == 'end':
                entry['complete'] = entry['rows'] == row.get('rows')
            elif row.get('side') in ('server', 'client'):
                entry['rows'] += 1
                side = entry[row['side']]
                if kind == 'meta':
                    side.update(seconds=row.get('seconds'), enabled=row.get('enabled'))
                elif kind == 'metric':
                    side['stats'][row['name']] = row['value']
                elif kind == 'counter':
                    side['counters'][row['name']] = row['value']
                elif kind == 'event':
                    side['events'].append(row['value'])
    complete = [r for r in runs.values() if r['complete']]
    if not complete:
        raise SystemExit('No complete report for this exact build fingerprint. In Studio: measurements ON, reproduce, '
                         'Report, then pass that session\'s log. Truncated or foreign rows are not accepted.')
    return {'log': log.name, 'buildFingerprint': fingerprint, 'report': complete[-1],
            'devQA': results['devQA'][-1] if results['devQA'] else None,
            'chakraQA': results['chakraQA'][-1] if results['chakraQA'] else None, 'malformedRows': malformed}


def report(log, manifest_path, out):
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    artifact = manifest_path.with_suffix('.rbxlx')
    if not artifact.is_file() or hashlib.sha256(artifact.read_bytes()).hexdigest() != manifest['sha256']:
        raise SystemExit(f'{artifact.name} differs from its manifest: rebuild, reopen it in Studio, capture again')
    result = read_reports(log, manifest['buildFingerprint'])
    result['artifact'] = artifact.name
    result['artifactSHA256'] = manifest['sha256']
    text = json.dumps(result, indent=2, ensure_ascii=False) + '\n'
    if out:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding='utf-8', newline='\n')
        print(out)
    else:
        sys.stdout.write(text)


def main():
    # Windows consoles default to a legacy code page; reports and catalogue are UTF-8.
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('verify', help='syntax + catalogue + headless suites (+ isolation when dist/ is built)')
    sub.add_parser('release', help='verify, main/debug/qa builds, isolation; no publish, push or commit')
    b = sub.add_parser('build')
    b.add_argument('--kind', choices=sorted(KINDS), default='main')
    a = sub.add_parser('audit')
    a.add_argument('--baseline', required=True, help='git revision to compare the gameplay core files with')
    c = sub.add_parser('compare')
    c.add_argument('--out', type=Path)
    g = sub.add_parser('catalogue')
    g.add_argument('--family')
    g.add_argument('--archetype')
    r = sub.add_parser('report')
    r.add_argument('--log', type=Path, required=True, help='Studio log or saved Output containing [NinjaDuelPerf] rows')
    r.add_argument('--manifest', type=Path, default=ROOT / 'dist/NinjaDuel-Debug.json')
    r.add_argument('--out', type=Path)
    args = parser.parse_args()
    if args.command == 'verify':
        verify()
    elif args.command == 'release':
        verify(with_isolation=False)
        for kind in ('main', 'debug', 'qa'):
            build(kind)
        if not isolation():
            raise SystemExit('release FAILED: tests/test_build_isolation.py')
        print('release: PASS (nothing published, pushed or committed)')
    elif args.command == 'build':
        build(args.kind)
    elif args.command == 'audit':
        sys.exit(0 if audit(args.baseline)['allUnchanged'] else 1)
    elif args.command == 'compare':
        compare(args.out)
    elif args.command == 'catalogue':
        data = validate_catalogue()
        for entry in data['entries']:
            if args.family and entry['family'] != args.family:
                continue
            if args.archetype and args.archetype not in entry['archetypes']:
                continue
            print(f"{entry['id']:24} {entry['title']} | risque {entry['conflictRisk']} | {entry['integrationNotes']}")
    elif args.command == 'report':
        report(args.log, args.manifest, args.out)


if __name__ == '__main__':
    main()
