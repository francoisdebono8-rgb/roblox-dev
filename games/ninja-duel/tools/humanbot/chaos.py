#!/usr/bin/env python3
"""The human robot's hands (OUTILLEUR, 27/11): gestures of a real, clumsy player.

François : « simule des comportements humains partout : clique plusieurs fois pour
choisir des tenues, ouvre et ferme des menus, mouvements illogiques pour un robot,
les clics dans la boutique, les menus, en combat… ».

Each mood writes one list of actions for Roblox Studio MCP's own input tools, which
play in the Play and never on the Mac (DEC-052):
  user_mouse_input    {"action": "moveTo"|"mouseButtonClick"|..., x, y, "wait_time_ms"}
  user_keyboard_input {"action": "keyDown"|"keyUp"|"keyPress"|"wait", "key_code", "wait_time_ms"}
The waits are a human's: never even, sometimes a long hesitation, sometimes a burst.
A seed makes a run come again exactly.

    python3 tools/humanbot/chaos.py MOOD [--seed N] [--scan SCAN.json] [--n N]

Moods (the scan is _G.NDHumanWatch.scan(), the buttons a player can click now):
  frenzy     clicks in a burst on the buttons of the open menu, often the same one twice
             or three times (a double click), tile after tile: the outfits, the shop   (mouse, scan)
  dither     opens and closes: a button, the same again, another, back, the close
             button, a key of the menus in between                                     (mouse, scan)
  everything every visible button once, in a random order, a human's pace            (mouse, scan)
  wander     walks without logic: a key held a little, the opposite at once, jumps
             in the middle of a turn, shift on and off, the double jump spammed        (keyboard)
  roam       runs across the village: W and Shift held long, veers, leaps, a turn back
                                                                                      (keyboard)
  mash       a fight with no plan: clicks in bursts, dodge spam, guard held then
             released mid-combo, numbers of techniques, the menu keys in the middle  (keyboard)
  menukeys   the menu keys pressed in a row and over each other (M, B, Tab, G,
             Backspace, Return, E)                                                  (keyboard)
"""
import json
import random
import sys

MOUSE_MOODS = ("frenzy", "dither", "everything")
KEY_MOODS = ("wander", "roam", "mash", "menukeys")
# The game's keys (Shared/Controls Keyboard, Client/HubMove, the panels).
MOVE = ["W", "A", "S", "D"]
FIGHT = ["Q", "F", "E", "R", "Z", "X", "G", "V", "C", "T", "Y", "B", "One", "Two", "Three", "Four", "Five"]
MENU = ["M", "B", "Tab", "G", "Backspace", "Return", "E", "Escape"]
# Escape is Roblox's own menu (Controls: « the game never receives it »): a human
# presses it anyway, but it opens Studio's menu over the game; it is left out of the
# runs (it would stop the hands, not the game).
SKIP_KEYS = {"Escape"}
# Buttons the hands never press: the dev tools of the capture place, and the ones
# that leave the Play or spend Robux (a purchase prompt would wait for a human).
NEVER = ("ClipAssistPanel", "Freecam", "NinjaDuelDev", "DevVisual", "CombatInspector")
ROBUX_WORDS = ("R$", "ROBUX", "Robux")


def human_wait(rng, quick=False):
    """A human's pause (ms): mostly short, sometimes a burst, sometimes a hesitation."""
    r = rng.random()
    if quick:
        return rng.randint(40, 140) if r < .8 else rng.randint(180, 420)
    if r < .45:
        return rng.randint(60, 220)
    if r < .85:
        return rng.randint(220, 700)
    return rng.randint(900, 2200)


def clickable(scan):
    out = []
    for b in scan.get("buttons", []):
        if any(n in b.get("label", "") for n in NEVER):
            continue
        if any(w in (b.get("label") or "") for w in ROBUX_WORDS):
            continue
        if not b.get("onScreen", True):
            continue
        out.append(b)
    return out


def click(b, wait):
    """A click on a button of the scan, at its x, y (the GUI's coordinates, which are
    user_mouse_input's; an instance path is ambiguous: the HUD's frames are all "Frame")."""
    return [{"action": "moveTo", "x": b["x"], "y": b["y"]},
            {"action": "mouseButtonClick", "mouse_button": "left"},
            {"action": "wait", "wait_time_ms": wait}]


def frenzy(rng, scan, n):
    buttons = clickable(scan)
    in_menu = [b for b in buttons if b.get("menu")] or buttons
    acts = []
    for _ in range(n):
        if not in_menu:
            break
        b = rng.choice(in_menu)
        times = rng.choices([1, 2, 3], weights=[5, 4, 1])[0]
        for k in range(times):
            acts += click(b, human_wait(rng, quick=k < times - 1))
    return acts


def dither(rng, scan, n):
    buttons = clickable(scan)
    acts = []
    for _ in range(n):
        if not buttons:
            break
        b = rng.choice(buttons)
        acts += click(b, human_wait(rng, quick=True))
        if rng.random() < .5:  # the same again at once: open, close
            acts += click(b, human_wait(rng))
        if rng.random() < .3:
            other = rng.choice(buttons)
            acts += click(other, human_wait(rng, quick=True))
    return acts


def everything(rng, scan, n):
    buttons = clickable(scan)
    rng.shuffle(buttons)
    acts = []
    for b in buttons[:n]:
        acts += click(b, human_wait(rng))
    return acts


def key(code, wait):
    return [{"action": "keyPress", "key_code": code}, {"action": "wait", "wait_time_ms": wait}]


def wander(rng, n):
    acts = []
    held = set()
    for _ in range(n):
        r = rng.random()
        if r < .45:
            k = rng.choice(MOVE)
            acts.append({"action": "keyDown", "key_code": k})
            held.add(k)
            acts.append({"action": "wait", "wait_time_ms": rng.randint(80, 900)})
            if rng.random() < .6:  # the opposite at once, the first one still held
                opp = {"W": "S", "S": "W", "A": "D", "D": "A"}[k]
                acts.append({"action": "keyDown", "key_code": opp})
                held.add(opp)
                acts.append({"action": "wait", "wait_time_ms": rng.randint(60, 400)})
            for h in sorted(held):
                if rng.random() < .8:
                    acts.append({"action": "keyUp", "key_code": h})
                    held.discard(h)
        elif r < .7:
            acts += key("Space", rng.randint(60, 200))
            if rng.random() < .6:
                acts += key("Space", human_wait(rng, quick=True))
        elif r < .85:
            acts.append({"action": "keyDown", "key_code": "LeftShift"})
            acts.append({"action": "wait", "wait_time_ms": rng.randint(100, 800)})
            acts.append({"action": "keyUp", "key_code": "LeftShift"})
        else:
            acts.append({"action": "wait", "wait_time_ms": human_wait(rng)})
    for h in sorted(held):
        acts.append({"action": "keyUp", "key_code": h})
    return acts


def roam(rng, n):
    """(27/11, François : « courir un peu partout ») Runs across the village: W held a
    long time with Shift, veering with A or D, leaps (Space twice) over what is in the
    way, a stop, a turn back with S, and again."""
    acts = [{"action": "keyDown", "key_code": "W"}, {"action": "keyDown", "key_code": "LeftShift"}]
    for _ in range(n):
        r = rng.random()
        if r < .4:
            side = rng.choice(["A", "D"])
            acts += [{"action": "keyDown", "key_code": side}, {"action": "wait", "wait_time_ms": rng.randint(250, 1400)},
                     {"action": "keyUp", "key_code": side}]
        elif r < .65:
            acts += key("Space", rng.randint(90, 180)) + key("Space", rng.randint(300, 900))
        elif r < .75:
            acts += [{"action": "keyUp", "key_code": "W"}, {"action": "keyDown", "key_code": "S"},
                     {"action": "wait", "wait_time_ms": rng.randint(400, 1500)}, {"action": "keyUp", "key_code": "S"},
                     {"action": "keyDown", "key_code": "W"}]
        elif r < .82:
            acts += [{"action": "keyUp", "key_code": "LeftShift"}, {"action": "wait", "wait_time_ms": rng.randint(300, 1200)},
                     {"action": "keyDown", "key_code": "LeftShift"}]
        else:
            acts.append({"action": "wait", "wait_time_ms": rng.randint(600, 2500)})
    acts += [{"action": "keyUp", "key_code": "LeftShift"}, {"action": "keyUp", "key_code": "W"}]
    return acts


def mash(rng, n):
    acts = []
    for _ in range(n):
        r = rng.random()
        if r < .3:
            k = rng.choice(MOVE)
            acts += [{"action": "keyDown", "key_code": k}, {"action": "wait", "wait_time_ms": rng.randint(80, 500)},
                     {"action": "keyUp", "key_code": k}]
        elif r < .45:
            acts += [{"action": "keyDown", "key_code": "F"}, {"action": "wait", "wait_time_ms": rng.randint(100, 900)}]
            if rng.random() < .5:
                acts += key(rng.choice(FIGHT), 80)
            acts.append({"action": "keyUp", "key_code": "F"})
        elif r < .9:
            acts += key(rng.choice(FIGHT + ["Space", "Q", "Q"]), human_wait(rng, quick=True))
        else:
            acts += key(rng.choice([m for m in MENU if m not in SKIP_KEYS]), human_wait(rng, quick=True))
    return acts


def mash_clicks(rng, n, x, y):
    """The mouse's half of a fight: bursts of left clicks, a right click now and then."""
    acts = [{"action": "moveTo", "x": x, "y": y}]
    for _ in range(n):
        burst = rng.choices([1, 2, 3, 5], weights=[3, 4, 3, 1])[0]
        for k in range(burst):
            acts.append({"action": "mouseButtonClick", "mouse_button": "left" if rng.random() < .8 else "right"})
            acts.append({"action": "wait", "wait_time_ms": human_wait(rng, quick=k < burst - 1)})
    return acts


def menukeys(rng, n):
    acts = []
    keys = [m for m in MENU if m not in SKIP_KEYS]
    for _ in range(n):
        acts += key(rng.choice(keys), human_wait(rng, quick=rng.random() < .5))
    return acts


def plan(mood, seed=0, scan=None, n=12, at=(667, 330)):
    rng = random.Random(seed)
    scan = scan or {"buttons": []}
    if mood == "frenzy":
        return frenzy(rng, scan, n)
    if mood == "dither":
        return dither(rng, scan, n)
    if mood == "everything":
        return everything(rng, scan, n)
    if mood == "wander":
        return wander(rng, n)
    if mood == "mash":
        return mash(rng, n)
    if mood == "roam":
        return roam(rng, n)
    if mood == "mashclicks":
        return mash_clicks(rng, n, *at)
    if mood == "menukeys":
        return menukeys(rng, n)
    raise SystemExit(f"humeur inconnue : {mood}")


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    mood = args[0]
    seed = int(args[args.index("--seed") + 1]) if "--seed" in args else 0
    n = int(args[args.index("--n") + 1]) if "--n" in args else 12
    scan = None
    if "--scan" in args:
        with open(args[args.index("--scan") + 1], encoding="utf-8") as f:
            scan = json.load(f)
    print(json.dumps(plan(mood, seed, scan, n), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
