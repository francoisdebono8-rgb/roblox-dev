#!/usr/bin/env python3
"""Check the persistent Ninja Duel documentation contract; never touches runtime."""
from pathlib import Path
import argparse
import hashlib
import json
import re
from urllib.parse import unquote

GAME = Path(__file__).resolve().parents[1]
REQUIRED = ('VISION', 'CURRENT_STATE', 'MASTER_BACKLOG', 'DECISIONS',
            'EXECUTION_RULES', 'CAPABILITIES_AND_TOOLS', 'SINCE_LAST_CLAUDE')
FIELDS = ('status', 'priority', 'dependencies', 'subsystem', 'character',
          'summary', 'sources', 'validation', 'evidence', 'outcome')
STATUSES = {'OPEN', 'PARTIAL', 'IN_PROGRESS', 'DONE', 'BLOCKED', 'DEFERRED', 'REJECTED'}
ID = r'[A-Z]+(?:-[A-Z]+)*-\d{3}'


def check(game=GAME):
    game = Path(game).resolve()
    errors = []
    active = game / 'docs/active'
    for name in REQUIRED:
        if not (active / (name + '.md')).is_file():
            errors.append('Missing active document: ' + name)
    start = game / 'CLAUDE_START_HERE.md'
    if not start.is_file() or 'Do not depend on prior chat history. The repository is the source of truth.' not in start.read_text():
        errors.append('Missing START or source-of-truth rule')
    backlog = active / 'MASTER_BACKLOG.md'
    text = backlog.read_text() if backlog.is_file() else ''
    records = {}
    for match in re.finditer(r'^## (' + ID + r') — ([^\n]+)\n(.*?)(?=^## |\Z)', text, re.M | re.S):
        key, title, body = match.groups()
        if key in records:
            errors.append('Duplicate backlog ID: ' + key)
        fields = dict(re.findall(r'^- (\w+): (.+)$', body, re.M))
        records[key] = fields
        for field in FIELDS:
            if not fields.get(field):
                errors.append(key + ': missing ' + field)
        if fields.get('status') not in STATUSES:
            errors.append(key + ': invalid status')
        if fields.get('priority') not in {'P0', 'P1', 'P2', 'P3'}:
            errors.append(key + ': invalid priority')
        if fields.get('status') == 'DONE' and fields.get('evidence', '').lower() in {'pending', 'none', 'not_started', ''}:
            errors.append(key + ': DONE requires evidence')
        if fields.get('outcome') == 'IMPROVED' and fields.get('status') != 'DONE':
            errors.append(key + ': IMPROVED outcome requires DONE')
    expected = len(re.findall(r'^## ', text, re.M))
    if not records or expected != len(records):
        errors.append('Every backlog heading needs a unique stable ID and title')
    graph = {}
    for key, fields in records.items():
        raw = fields.get('dependencies', '')
        deps = [] if raw == 'NONE' else [x.strip() for x in raw.split(',')]
        graph[key] = deps
        for dep in deps:
            if dep not in records:
                errors.append(key + ': unknown dependency ' + dep)
    visiting, visited = set(), set()

    def visit(key):
        if key in visiting:
            errors.append('Dependency cycle at ' + key)
            return
        if key in visited or key not in graph:
            return
        visiting.add(key)
        for dep in graph[key]:
            visit(dep)
        visiting.remove(key)
        visited.add(key)
    for key in records:
        visit(key)
    # Validate operational navigation. Historical source links can name unavailable
    # external bases; they remain intact and are audited separately in the report.
    docs = [start, game / 'README.md', game / 'CLAUDE_FINAL_PASS.md', game / 'docs/README.md']
    for folder in ('active', 'combat', 'movement', 'characters', 'systems', 'research', 'tools'):
        docs += list((game / 'docs' / folder).glob('*.md'))
    docs += [game / 'docs/archive/README.md', game / 'docs/current/README.md',
             game / 'docs/reports/SOURCE_COVERAGE.md', game / 'docs/reports/ORCHESTRATION_REFACTOR.md']
    for doc in docs:
        if not doc.exists():
            errors.append('Missing navigation document: ' + str(doc.relative_to(game)))
            continue
        content = re.sub(r'```.*?```', '', doc.read_text(), flags=re.S)
        for target in re.findall(r'\]\(([^)]+)\)', content):
            target = target.strip().strip('<>').split('#', 1)[0]
            if not target or re.match(r'[a-zA-Z][a-zA-Z0-9+.-]*:', target):
                continue
            if not (doc.parent / unquote(target)).exists():
                errors.append(str(doc.relative_to(game)) + ': missing link ' + target)
    coverage_path = game / 'docs/reports/SOURCE_COVERAGE.json'
    try:
        coverage = json.loads(coverage_path.read_text())
        for entry in coverage:
            # Repository-relative paths, inferred from the actual game root.
            source = entry['source']
            parts = Path(source).parts
            if parts[:2] != ('games', 'ninja-duel'):
                errors.append('Coverage outside game: ' + source)
                continue
            path = game.joinpath(*parts[2:])
            if not path.is_file():
                errors.append('Coverage missing source: ' + source)
                continue
            if hashlib.sha256(path.read_bytes()).hexdigest() != entry['sha256']:
                errors.append('Refresh coverage hash/sections: ' + source)
            headings = [(i, line.lstrip('# ').strip()) for i, line in enumerate(path.read_text().splitlines(), 1)
                        if re.match(r'^#{1,6} ', line)]
            indexed = [(s['line'], s['heading']) for s in entry['sections']]
            if headings and headings != indexed:
                errors.append('Incomplete section coverage: ' + source)
            for section in entry['sections']:
                if not section['backlog_ids'] or any(key not in records for key in section['backlog_ids']):
                    errors.append('Coverage unknown/missing backlog ID: ' + source)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        errors.append('Invalid source coverage: ' + str(exc))
    return list(dict.fromkeys(errors)), len(records)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game-root', type=Path, default=GAME)
    args = parser.parse_args()
    errors, count = check(args.game_root)
    for error in errors:
        print('FAIL', error)
    print(f'{"FAIL" if errors else "PASS"}: project docs ({count} backlog items)')
    raise SystemExit(bool(errors))
