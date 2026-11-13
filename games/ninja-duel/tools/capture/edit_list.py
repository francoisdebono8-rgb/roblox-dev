#!/usr/bin/env python3
"""Pick the best shot of each scene from several F4 takes of the same program.

One replay program (NDDirector P.run) rendered once per camera map gives one F4
take per map (workspace.NDShot names the map). Each take's summary (the
`[NinjaDuelClip] {...}` line of Output, or Report:Invoke("rec","stop") /
Report:Invoke()['last']) lists its scenes with their clean share. This script
reads those summaries and writes the edit list: for every scene, in the
program's order, the take whose shot of that scene has the most clean time
(ties: fewer errors, then the first take given).

    python3 edit_list.py take_T1.json take_T2.json take_T3.json > edit.json

A summary file may hold the JSON object alone or the whole Output line.
Times: `t0`/`t1` are seconds from the take's REC (the rush, once REC is aligned
with the frame counter), `st0`/`st1` the replay clock (NDClock) when set.
"""
import json
import sys
from pathlib import Path


def load(path):
    text = Path(path).read_text(encoding='utf-8').strip()
    if '[NinjaDuelClip]' in text:
        text = text.split('[NinjaDuelClip]', 1)[1].strip()
    data = json.loads(text)
    return data.get('last', data) if isinstance(data, dict) else data


def edit_list(takes):
    order, options = [], {}
    for index, (name, take) in enumerate(takes):
        for scene in take.get('scenes') or []:
            key = scene.get('scene')
            if not key:
                continue
            if key not in options:
                order.append(key)
                options[key] = []
            options[key].append((index, name, take, scene))
    cuts = []
    for key in order:
        def score(option):
            index, _, _, scene = option
            length = max(0.0, scene['t1'] - scene['t0'])
            return (-scene.get('cleanShare', 0) * length, scene.get('errors', 0), index)
        index, name, take, scene = min(options[key], key=score)
        cuts.append({
            'scene': key,
            'shot': scene.get('shot'),
            'take': take.get('label'),
            'file': name,
            't0': scene['t0'], 't1': scene['t1'],
            'st0': scene.get('st0'), 'st1': scene.get('st1'),
            'cleanShare': scene.get('cleanShare'),
            'clean': scene.get('clean'),
            'errors': scene.get('errors'),
            # what a viewer sees in that shot (F4's timeline, 13/11 evening)
            'timeline': scene.get('timeline') or [],
            'others': [{'shot': s.get('shot'), 'take': t.get('label'), 'cleanShare': s.get('cleanShare'), 'errors': s.get('errors')}
                       for i, _, t, s in options[key] if i != index],
        })
    return {'scenes': cuts, 'warnings': [c['scene'] for c in cuts if (c['cleanShare'] or 0) < 0.6]}


def main(argv):
    if len(argv) < 2:
        sys.exit(__doc__)
    takes = [(path, load(path)) for path in argv[1:]]
    json.dump(edit_list(takes), sys.stdout, ensure_ascii=False, indent=1)
    sys.stdout.write('\n')


if __name__ == '__main__':
    main(sys.argv)
