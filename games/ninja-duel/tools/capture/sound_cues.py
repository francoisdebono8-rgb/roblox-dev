#!/usr/bin/env python3
"""Place the replay's sounds on a slow render's rush (13/11, request 8 of the CM).

A slow render (NDDirector, P.slow = 0.25) is silent: the edit speeds the rush up
x4 and lays the sounds back from the replay's sound log. This script gives, for
every recorded sound, the moment(s) of the rush where the replay reaches it,
and the same moment once the rush is sped up.

    python3 sound_cues.py frames.json sounds.json [--slow 0.25] > cues.json

frames.json: the F4 frame log of the take, the pages of
    Report:Invoke("frames",{from=1,count=600}) (one page, a list of pages, or a
    plain list of frames); each frame has `w` (seconds from REC), `st` (the
    replay clock, NDClock), `scene` and `black`.
sounds.json: NDReplay.soundLog() (seconds from the start of the recording).
--slow: the render speed (the take summary's `slow`); 1 = real time.

A sound is placed in every scene that plays its instant (a scene played twice,
after a frozen frame, gives two places: keep the one of the cut you use).
"""
import json
import sys
from pathlib import Path


def frames_of(data):
    if isinstance(data, dict):
        return data.get('frames') or []
    out = []
    for x in data:
        if isinstance(x, dict) and 'frames' in x:
            out.extend(x['frames'])
        else:
            out.append(x)
    return out


def cues(frames, sounds, slow):
    cues = []
    prev = None
    for f in frames:
        if f.get('black') or f.get('st') is None:
            prev = None
            continue
        if prev is not None and prev.get('scene') == f.get('scene') and f['st'] > prev['st']:
            a, b = prev['st'], f['st']
            for s in sounds:
                if a < s['t'] <= b:
                    # where between the two frames the sound falls
                    k = (s['t'] - a) / (b - a)
                    rush = prev['w'] + k * (f['w'] - prev['w'])
                    cues.append({'id': s.get('id'), 'name': s.get('name'), 'volume': s.get('volume'), 'speed': s.get('speed'),
                                 'replay': s['t'], 'scene': f.get('scene'), 'shot': f.get('shot'),
                                 'rush': round(rush, 3), 'final': round(rush * slow, 3)})
        prev = f
    cues.sort(key=lambda c: c['rush'])
    return cues


def main(argv):
    args = [a for a in argv[1:]]
    slow = 1.0
    if '--slow' in args:
        i = args.index('--slow')
        slow = float(args[i + 1])
        del args[i:i + 2]
    if len(args) != 2:
        sys.exit(__doc__)
    frames = frames_of(json.loads(Path(args[0]).read_text(encoding='utf-8')))
    sounds = json.loads(Path(args[1]).read_text(encoding='utf-8'))
    json.dump({'slow': slow, 'cues': cues(frames, sounds, slow)}, sys.stdout, ensure_ascii=False, indent=1)
    sys.stdout.write('\n')


if __name__ == '__main__':
    main(sys.argv)
