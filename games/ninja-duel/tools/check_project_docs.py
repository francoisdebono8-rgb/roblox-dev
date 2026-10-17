#!/usr/bin/env python3
"""Check the persistent Ninja Duel documentation contract; never touches runtime."""
from pathlib import Path
import argparse
import os
import hashlib
import json
import re
from urllib.parse import unquote

GAME = Path(__file__).resolve().parents[1]
REQUIRED = ('VISION', 'CURRENT_STATE', 'MASTER_BACKLOG', 'DECISIONS',
            'EXECUTION_RULES', 'ENGINEERING_REVIEW', 'SINCE_LAST_CLAUDE')
FIELDS = ('status', 'priority', 'dependencies', 'subsystem', 'character',
          'summary', 'sources', 'validation', 'evidence', 'outcome')
STATUSES = {'OPEN', 'PARTIAL', 'IN_PROGRESS', 'DONE', 'BLOCKED', 'DEFERRED', 'REJECTED'}
ID = r'[A-Z]+(?:-[A-Z]+)*-\d{3}'
BRANCH_POLICY = (
    'Verify the current HEAD and authoritative Ninja Duel branch before working.',
    'Do not assume main or any historical branch is current.',
)
PLACEHOLDERS = {'', 'none', 'pending', 'tbd', 'todo', 'not_started'}


def check_start_policy(content):
    errors = []
    if not all(rule in content for rule in BRANCH_POLICY):
        errors.append('START requires HEAD/authoritative branch verification; no historical default')
    for line in content.splitlines():
        # An establishment record is allowed; an imperative fixing future work
        # to a literal branch is not. The policy deliberately names no branch.
        directive = re.search(r'\b(always|toujours|checkout|git\s+switch|select|sélectionn\w*)\b', line, re.I)
        literal = re.search(r'`(?:main|master|[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+)`|(?:branch|branche)\s+`[^`]+`|(?:branch|branche)\s+(?:main|master|[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+)', line, re.I)
        if directive and literal:
            errors.append('START must not prescribe a fixed future work branch')
    return errors


def check(game=GAME):
    game = Path(game).resolve()
    errors = []
    active = game / 'docs/active'
    for name in REQUIRED:
        if not (active / (name + '.md')).is_file():
            errors.append('Missing active document: ' + name)
    start = game / 'CLAUDE_START_HERE.md'
    if not start.is_file() or 'Do not depend on prior chat history. The repository is the source of truth.' not in start.read_text(encoding='utf-8'):
        errors.append('Missing START or source-of-truth rule')
    if start.is_file():
        errors.extend(check_start_policy(start.read_text(encoding='utf-8')))
    backlog = active / 'MASTER_BACKLOG.md'
    text = backlog.read_text(encoding='utf-8') if backlog.is_file() else ''
    records = {}
    for match in re.finditer(r'^## (' + ID + r') — ([^\n]+)\n(.*?)(?=^## |\Z)', text, re.M | re.S):
        key, title, body = match.groups()
        if key in records:
            errors.append('Duplicate backlog ID: ' + key)
        fields = dict(re.findall(r'^- (\w+): (.+)$', body, re.M))
        records[key] = fields
        justification = fields.get('justification', '').strip()
        has_justification = justification.lower() not in PLACEHOLDERS
        has_source = bool(re.search(r'\[[^\]]+\]\([^)]+\)', fields.get('sources', '')))
        if not has_source and not has_justification:
            errors.append(key + ': requires a source link or explicit justification')
        for field in FIELDS:
            if field == 'sources' and has_justification:
                continue
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
    # Check the whole game documentation, including moved historical links.
    actual = {p.stem for p in active.glob('*.md')}
    if actual != set(REQUIRED):
        errors.append('Active owners must be exactly the seven canonical documents')
    review = active / 'ENGINEERING_REVIEW.md'
    if review.is_file():
        headings = re.findall(r'^## (.+)$', review.read_text(encoding='utf-8'), re.M)
        if headings != ['BLOCKERS', 'REGRESSIONS', 'ARCHITECTURE RISKS',
                        'PLAYER-FACING FAILURES', 'NEXT 3 PRIORITIES', 'DO NOT TOUCH']:
            errors.append('ENGINEERING_REVIEW requires exactly six ordered sections')
        if len(review.read_text(encoding='utf-8').splitlines()) > 60:
            errors.append('ENGINEERING_REVIEW must stay short (maximum 60 lines)')
    docs = sorted(game.rglob('*.md'))
    for doc in docs:
        if not doc.exists():
            errors.append('Missing navigation document: ' + str(doc.relative_to(game)))
            continue
        content = re.sub(r'```.*?```', '', doc.read_text(encoding='utf-8'), flags=re.S)
        for target in re.findall(r'\]\(([^)]+)\)', content):
            target = target.strip().strip('<>').split('#', 1)[0]
            if not target or re.match(r'[a-zA-Z][a-zA-Z0-9+.-]*:', target):
                continue
            # normpath folds '..' so deep checkouts stay under the Windows path limit.
            if not Path(os.path.normpath(doc.parent / unquote(target))).exists():
                errors.append(str(doc.relative_to(game)) + ': missing link ' + target)
    coverage_path = game / 'docs/archive/reports/SOURCE_COVERAGE.json'
    try:
        coverage = json.loads(coverage_path.read_text(encoding='utf-8'))
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
            headings = [(i, line.lstrip('# ').strip()) for i, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1)
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


def self_test(game=GAME):
    """Replay a fresh-session contract and five regressions without editing files."""
    from unittest.mock import patch
    game = Path(game).resolve()
    errors, count = check(game)
    if errors:
        raise AssertionError(errors)
    start = game / 'CLAUDE_START_HERE.md'
    backlog = game / 'docs/active/MASTER_BACKLOG.md'
    start_text, backlog_text = start.read_text(encoding='utf-8'), backlog.read_text(encoding='utf-8')
    original_read, original_is_file = Path.read_text, Path.is_file
    first = re.search(r'^## ' + ID + r' — [^\n]+\n.*?(?=^## |\Z)',
                      backlog_text, re.M | re.S).group()
    cases = [
        ('fixed future branch', {start: start_text + '\nAlways work on branch `future/permanent`.\n'},
         None, 'fixed future work branch'),
        ('missing active file', {}, game / 'docs/active/VISION.md', 'Missing active document'),
        ('missing ticket provenance', {backlog: re.sub(r'^- sources: .+$', '- sources: NONE',
                                                     backlog_text, count=1, flags=re.M)},
         None, 'requires a source link or explicit justification'),
        ('broken active link', {start: start_text.replace('docs/active/VISION.md',
                                                        'docs/active/MISSING.md')},
         None, 'missing link'),
        ('duplicate ID', {backlog: backlog_text + '\n' + first}, None, 'Duplicate backlog ID'),
        ('invalid review sections',
         {game / 'docs/active/ENGINEERING_REVIEW.md': '## HISTORY\n'},
         None, 'exactly six ordered sections'),
        ('oversized review',
         {game / 'docs/active/ENGINEERING_REVIEW.md':
          (game / 'docs/active/ENGINEERING_REVIEW.md').read_text(encoding='utf-8') + '\n' * 61},
         None, 'must stay short'),
    ]
    for label, replacements, missing, expected in cases:
        def read(path, *args, **kwargs):
            return replacements[path] if path in replacements else original_read(path, *args, **kwargs)
        def is_file(path):
            return False if path == missing else original_is_file(path)
        with patch.object(Path, 'read_text', read), patch.object(Path, 'is_file', is_file):
            failures, _ = check(game)
        if not any(expected in failure for failure in failures):
            raise AssertionError((label, failures))
        print('PASS resumption regression:', label)
    # A future branch of establishment remains valid: no named branch is
    # required by the checker, and a real branch switch changes no docs paths.
    alternate = start_text.replace('codex/ninja-claude-technical-prep', 'future/authoritative')
    with patch.object(Path, 'read_text', lambda path, *args, **kwargs:
                      alternate if path == start else original_read(path, *args, **kwargs)):
        failures, _ = check(game)
    if failures:
        raise AssertionError(failures)
    print('PASS resumption: alternate branch accepted; required files, provenance, links and IDs valid')
    return count


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game-root', type=Path, default=GAME)
    parser.add_argument('--self-test', action='store_true', help='Run the fresh-session regression smoke without writing files')
    args = parser.parse_args()
    if args.self_test:
        self_test(args.game_root)
    errors, count = check(args.game_root)
    for error in errors:
        print('FAIL', error)
    print(f'{"FAIL" if errors else "PASS"}: project docs ({count} backlog items)')
    raise SystemExit(bool(errors))
