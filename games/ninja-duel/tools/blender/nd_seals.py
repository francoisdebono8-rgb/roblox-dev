"""Hand seals and the weave every seal jutsu opens with (04/11).

The four seals of the game's second page of jutsu (Shared/SealJutsu: 1 TIGER,
2 SNAKE, 3 RAM, 4 RAT). Both hands meet at the chest; the arms differ enough
per seal that two of them in a row read as a sequence at game distance (the
hands themselves are blocks: the shape is told by the elbows, the height and
the twist of the forearms). Poses are the engine's control vocabulary
(nd_anim): they merge onto a fighter's stance.

weave(shot, start, signs, base, beat) keys the seals of a jutsu on a Shot,
one every `beat` frames, the body settling a little lower on each (the
chakra gathered), and returns the frame of the last one.
"""
from nd_shot import merge

# index (Shared/SealJutsu.Names) -> name
NAMES = {1: "tiger", 2: "snake", 3: "ram", 4: "rat"}

BASE = {"la": {"raise": 64, "out": -36, "twist": 34, "elbow": 112, "wrist": 10},
        "ra": {"raise": 64, "out": -36, "twist": 34, "elbow": 112, "wrist": 10},
        "torso": {"pitch": 6}, "head": {"pitch": 10}}
VARIANTS = {
    # index and middle fingers up, the hands pressed together: tall, at the chin
    "tiger": {"la": {"raise": 74, "elbow": 102, "wrist": 14}, "ra": {"raise": 74, "elbow": 102, "wrist": 14}},
    # fingers interlaced, the hands clasped and turned: one forearm rolled over
    "snake": {"la": {"raise": 60, "twist": 62, "elbow": 118}, "ra": {"raise": 58, "twist": 8, "elbow": 118, "wrist": -6}},
    # the tiger's sister held lower, the right hand over the left
    "ram": {"la": {"raise": 56, "elbow": 122}, "ra": {"raise": 78, "elbow": 98, "twist": 50}},
    # the left hand closed on the right's two fingers: the right stands higher
    "rat": {"la": {"raise": 52, "out": -30, "twist": 40, "elbow": 124, "wrist": 0}, "ra": {"raise": 82, "out": -34, "twist": 22, "elbow": 94, "wrist": 26}},
}


def seal(n):
    """The pose of seal n (1-4) or of its name."""
    name = NAMES.get(n, n)
    return merge(BASE, VARIANTS[name])


def weave(shot, start, signs, base, beat=5, sink=.06):
    """Key the seals on `shot` from frame `start`: each arrives with a small
    snap ("impact") after a pass through the previous one; the hips go down a
    little each time. Returns the frame of the last seal."""
    frame = start
    y = (base.get("root") or {}).get("y", 0)
    for i, n in enumerate(signs):
        frame = start + beat * (i + 1)
        pose = merge(base, merge(seal(n), {"root": {"y": y - sink * (i + 1)}}))
        shot.key(frame, pose, "impact")
    return frame
