"""Check static workspace dependencies without building or changing artifacts.

Rojo paths, literal require/import paths, Python imports and Roblox runtime
namespace references are checked. Shared code is followed transitively.
Dynamic/computed imports still require code review.
"""
from pathlib import Path
import argparse
import ast
import json
import re

ROOT = Path(__file__).resolve().parents[1]


def owner(path, root):
    relative = path.relative_to(root).as_posix()
    if relative.startswith('games/ninja-duel/motion-lab/'):
        return 'motion-lab'
    if relative.startswith('games/ninja-duel/'):
        return 'ninja-duel'
    if relative.startswith('plugins/'):
        return 'plugins'
    if relative.startswith('shared/'):
        return 'shared'
    return None


def references(path, root):
    text = path.read_text()
    targets = set()
    namespaces = set()
    if path.name.endswith('.project.json'):
        def walk(value):
            if isinstance(value, dict):
                if '$path' in value:
                    targets.add((path.parent / value['$path']).resolve())
                for child in value.values():
                    walk(child)
            elif isinstance(value, list):
                for child in value:
                    walk(child)
        walk(json.loads(text))
    else:
        if path.suffix in ('.lua', '.luau'):
            text = re.sub(r'--\[\[.*?\]\]|--[^\n]*', '', text, flags=re.S)
            if re.search(r'\bNinjaDuel\b', text):
                namespaces.add('ninja-duel')
            if re.search(r'\b(?:PresetForge|JointForge|CurveForge|AccessForge|SchemaForge|BrickKitMonetization)\b', text):
                namespaces.add('plugins')
            if re.search(r'\bMotionLab\b', text):
                namespaces.add('motion-lab')
        if path.suffix == '.py':
            for node in ast.walk(ast.parse(text)):
                modules = [a.name for a in node.names] if isinstance(node, ast.Import) else [node.module or ''] if isinstance(node, ast.ImportFrom) else []
                for module in modules:
                    if module == 'plugins' or module.startswith('plugins.'):
                        namespaces.add('plugins')
                    if module in ('games.ninja_duel', 'games.ninja-duel') or module.startswith(('games.ninja_duel.', 'games.ninja-duel.')):
                        namespaces.add('ninja-duel')
                    if 'motion_lab' in module or 'motion-lab' in module:
                        namespaces.add('motion-lab')
        if path.suffix == '.py':
            # Also cover pathlib expressions such as ROOT / 'plugins'.
            for node in ast.walk(ast.parse(text)):
                if isinstance(node, ast.Constant) and isinstance(node.value, str):
                    exact = {'plugins': 'plugins', 'products': 'plugins', 'ninja-duel': 'ninja-duel', 'motion-lab': 'motion-lab'}
                    if node.value in exact:
                        namespaces.add(exact[node.value])
        for token in re.findall(r'[\'"]([^\'"\n]+)[\'"]', text):
            for prefix, destination in (('plugins/', 'plugins'), ('products/', 'plugins'), ('games/ninja-duel/motion-lab/', 'motion-lab'), ('games/ninja-duel/', 'ninja-duel')):
                if prefix in token:
                    namespaces.add(destination)
            if token.startswith(('./', '../', 'shared/', 'plugins/', 'games/')):
                for base in (path.parent, root):
                    candidate = (base / token).resolve()
                    for suffix in ('', '.luau', '.lua', '.py'):
                        target = Path(str(candidate) + suffix)
                        if target.exists():
                            targets.add(target)
    return targets, namespaces


def check(root):
    root = root.resolve()
    files = sorted(p for base in ('games', 'plugins', 'shared')
                   for p in (root / base).rglob('*')
                   if p.is_file() and (p.suffix in ('.luau', '.lua', '.py') or p.name.endswith('.project.json')))
    graph = {p: references(p, root) for p in files}
    errors = set()
    for source in files:
        origin = owner(source, root)
        forbidden = {'plugins', 'motion-lab'} if origin == 'ninja-duel' else {'ninja-duel', 'motion-lab'} if origin == 'plugins' else {'plugins'} if origin == 'motion-lab' else set()
        pending = [source]
        visited = set()
        while pending:
            current = pending.pop()
            if current in visited:
                continue
            visited.add(current)
            targets, namespaces = graph.get(current, (set(), set()))
            for namespace in namespaces & forbidden:
                errors.add(f'{source.relative_to(root)} -> {namespace} (via {current.relative_to(root)})')
            for target in targets:
                if not target.is_relative_to(root):
                    continue
                target_owner = owner(target, root)
                if target_owner in forbidden:
                    errors.add(f'{source.relative_to(root)} -> {target.relative_to(root)}')
                pending.extend(p for p in graph if p == target or (target.is_dir() and p.is_relative_to(target)))
    return sorted(errors), len(files)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    args = parser.parse_args()
    errors, count = check(args.root)
    for error in errors:
        print('FAIL', error)
    print(f'{"FAIL" if errors else "PASS"}: workspace boundaries ({count} code/project files); dynamic imports require review')
    raise SystemExit(bool(errors))
