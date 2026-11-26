#!/usr/bin/env python3
"""Konoha's fabric generated for a ninja's run (23/11, François after playing step 3: « la carte
n'est vraiment pas complète et peu cohérente », « la course ninja, le double saut, le mur, ce
n'est pas du tout ninja feel », « tout doit être dans cet esprit »; « applique la méthode de
l'ANIMATEUR et adapte-la à une génération de village ; on n'est pas obligé de prendre la vraie
composition de Konoha, en gardant des éléments reconnaissables »).

The ANIMATEUR's method (tools/blender/syph_author.py, SyphoDev without Blender), turned to a
village:
  1. RULES from the references and from the body's real numbers (tools/syphodev/
     konoha_profile.json: run 36, jump 56, leap 54, wall run 36 studs up, gravity 140), written
     here with their reason;
  2. GENERATE many candidates (seeds and rhythms) under those rules;
  3. SCORE each one out of 10 with measures, not looks (`score`: the rooftop run, the flow of
     its jumps, the way up, the empty space, the streets, the skyline);
  4. a CONTACT SHEET looked at once (`sheet`: the plan before / after, the run drawn on it);
  5. KEEP only what beats the plan in the game: a candidate under the current plan's score is
     not written.

What stays (the recognizable Konoha and what the game already uses, tools/blender/
konoha_layout.py, the ANIMATEUR's): the Hokage Rock and its faces to the north, the round
residence at its foot, the great gate to the south and the main street between them, Ichiraku,
the exam hall in the middle, the Hyuga and Uchiha compounds, the Naka river and its shrine,
Training Ground Three, the streets, every open place a duel or a master uses. What is generated:
the houses between them (the fabric), the bridges over the lanes, the race on the roofs.

    python3 tools/village/konoha_village.py search [N]     the best of N candidates, its sheet
    python3 tools/village/konoha_village.py write SEED     writes src/Shared/KonohaLayout.luau
    python3 tools/village/konoha_village.py score [FILE]   the score of a plan (JSON) or the game's
"""
import json
import math
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, os.pardir, os.pardir))
sys.path.insert(0, os.path.join(GAME, "tools", "blender"))
import konoha_layout as K  # noqa: E402  the fixed Konoha: districts, streets, open places, landmarks

OUT = os.path.join(GAME, "work", "village")

# ---------------------------------------------------------------------------------------- rules
# The body (base studs: the plan is drawn before HubMap.Scale 1.3; the game's numbers are world).
S = K.SCALE
PROFILE = json.load(open(os.path.join(GAME, "tools", "syphodev", "konoha_profile.json")))
G = PROFILE["gravity"]["value"] / S                    # 107.7 base studs/s²
RUN = PROFILE["sprintSpeed"]["value"] / S              # 27.7
JUMP_UP = (56 ** 2 / (2 * PROFILE["gravity"]["value"])) / S            # 8.6: one jump's rise
LEAP_UP = JUMP_UP + (54 ** 2 / (2 * PROFILE["gravity"]["value"])) / S  # 16.6 with the second jump
CLIMB = PROFILE["abilities"]["wallClimb"]["maxRise"] / S               # 27.8: the run up a wall

# A jump between two roofs (gap across, rise up), in base studs. The reach is the body's own:
# a sprint (RUN) for the time of one jump to the landing height (the second jump's time too, for
# a leap), and only MARGIN of it is asked, since nobody takes off from the very edge.
#   FLOW   taken at a run without thinking (one jump): a stride's gap, a step up. This is the
#          ninja's rhythm on the roofs (« sauter de toit en toit »): most links must be these.
#   LEAP   asks for the second jump: a lane's width, a storey up.
MARGIN = 0.6
V1 = (56 / S)                       # the jump's speed up (base studs/s)
V2 = (54 / S)                       # the second jump's


def reach(rise, double=False):
    """How far across (base studs) a sprinting jump lands `rise` studs higher (MARGIN of it)."""
    up = V1 / G + (V2 / G if double else 0)
    apex = JUMP_UP + (LEAP_UP - JUMP_UP if double else 0)
    if rise > apex - .5:
        return 0.0
    return MARGIN * RUN * (up + math.sqrt(2 * (apex - rise) / G))


FLOW_GAP, FLOW_RISE = reach(0), 5.0           # 13.3 flat; 11 for a step of 5
LEAP_GAP, LEAP_RISE = reach(0, True), 12.0    # 22.3 flat
DROP_OK = 16.0           # a drop he lands without a stop
ALLEY = (6.5, 9.5)       # a back alley: a ninja crosses it in one bound, a walker walks it
ROW_GAP = (0.8, 2.6)     # houses of one row: side by side, their roofs one surface to run on
STEP_MAX = 7.0           # the skyline: two neighbours of a row differ by a step at most
CRACK = (1.0, 3.0)       # (23/11, the OUTILLEUR's bot stuck between the hospital and a tower, 1.9
                         # apart) beside a landmark a house is flush (under CRACK[0]: nobody falls
                         # in) or a lane away (over CRACK[1], 3.9 studs in the game: walked
                         # through): never a crack between, a body wedges in it
LAMP_CLEAR = 3.5         # (23/11, the bot's one roof missed: a machiya behind a street lamp 2.7
                         # from its wall) a lamp before a wall to run up stands this far from it,
                         # or before the gap between two houses

# The models (tools/blender/konoha_houses.py), their own size, and how far a lot may stretch
# one (Server/Hub fits the model to its lot: DressScale): a little, or it shows.
STRETCH = (0.9, 1.15)
HEIGHT_FIT = (0.85, 1.2)
MODELS = {k: dict(w=v[5][0], d=v[5][1], h=v[1]) for k, v in K.HOUSES.items()}

# Each district's character: its models and the band of its roofs (a quarter reads as one).
CHARACTER = {
    # (23/11, François: « la ville est aléatoire, rien n'est cohérent » ; « un mix entre le vrai et
    # le généré », « tu peux te baser sur plusieurs villages existants ») An Edo town's streets:
    # Tsumago and Kyoto's rows of two-storey timber houses with deep eaves along the main streets,
    # Ouchi-juku's houses set back in their gardens in the residences, and Konoha's tall plaster
    # blocks with their round tanks only round the civic heart (the Hokage's quarter).
    "Market": dict(mix=[("shop_house", 3), ("machiya", 2)], band=(12, 16)),
    "Main": dict(mix=[("shop_house", 3), ("machiya", 1)], band=(12, 16)),
    "TeaStreet": dict(mix=[("machiya", 3), ("shop_house", 2)], band=(12, 15)),
    "Centre": dict(mix=[("machiya", 3), ("shop_house", 2), ("tank_house", 1)], band=(12, 18)),
    "Alleys": dict(mix=[("machiya", 3), ("small_house", 2)], band=(8, 15)),
    "Residences": dict(mix=[("small_house", 3), ("machiya", 2), ("clan_house", 1)], band=(7, 14)),
    "Civic": dict(mix=[("tank_house", 3), ("apartment", 2)], band=(16, 23)),
    "Uchiha": dict(mix=[("clan_house", 3), ("machiya", 1)], band=(8, 13)),
    "Hyuga": dict(mix=[("clan_house", 1)], band=(8, 11)),
}
# (23/11) How dense a district is: back rows behind its street rows (the rest of the block is
# its gardens and trees), and whether the holes the rows leave get a house or a garden.
DENSE = {"Market": 3, "Main": 3, "TeaStreet": 2, "Centre": 3, "Alleys": 2, "Civic": 2, "Residences": 1, "Uchiha": 1, "Hyuga": 0}
# A row keeps its model and walks its skyline gently (Tsumago's eaves run on): a step of
# ROW_STEP between neighbours, the bigger FLOW steps only where an alley cuts the row.
ROW_STEP = (0.3, 1.6)
TOWERS_MAX = 4           # the ANIMATEUR's towers: a few watchtowers, not one per block
NO_FABRIC = {"Rock", "Training", None}


def rect_of(x, z, w, d, yaw):
    return K.rect_of(x, z, w, d, yaw)


def gap_between(a, b):
    """The horizontal gap between two rectangles (0 when they touch or overlap)."""
    dx = max(0.0, max(a[0], b[0]) - min(a[2], b[2]))
    dz = max(0.0, max(a[1], b[1]) - min(a[3], b[3]))
    return math.hypot(dx, dz)


def door_strip(x, z, w, d, yaw, depth=6.0):
    """The strip before a house's door: its way out (an alley's width deep, 60% of its front)."""
    fx, fz = {0: (0, 1), 180: (0, -1), 90: (1, 0), 270: (-1, 0)}[int(yaw) % 360]
    cx, cz = x + fx * (d / 2 + depth / 2 + .2), z + fz * (d / 2 + depth / 2 + .2)
    sx, sz = (w * 0.3, depth / 2) if fx == 0 else (depth / 2, w * 0.3)
    return (cx - sx, cz - sz, cx + sx, cz + sz)


def street_distance(x, z):
    best = 1e18
    for s in K.STREETS:
        r = K.street_rect(s)
        nx, nz = min(max(x, r[0]), r[2]), min(max(z, r[1]), r[3])
        best = min(best, math.hypot(nx - x, nz - z))
    return best


# ------------------------------------------------------------------------------------ generator
class Village(K.Plan):
    """K.Plan's fixed Konoha (its landmarks, streets, open places), its fabric generated."""

    def __init__(self, seed, alley_chance=0.28, back_rows=True, bridges=True, infill=True):
        super().__init__(seed=1000 + seed)
        self.seed = seed
        self.alley_chance = alley_chance
        self.back_rows = back_rows
        self.with_bridges = bridges
        self.with_infill = infill
        self.bridges = []      # dict(x0, z0, x1, z1, top, width)
        self.fills = []        # dict(x0, z0, x1, z1, top): a crack beside a landmark walled up
        self.doors = []        # the strip before each door: kept clear (a way out)
        self.decks = [dict(x=x, z=z, w=w, d=d, top=t) for x, z, w, d, t in K.ROOF_DECKS]
        # (23/11, the OUTILLEUR's prover: the Uchiha and Hyuga compound walls ran through 12
        # houses) a wall is kept clear like a street: no house stands on it
        for _, wx, wz, ww, wd, _h in K.WALLS:
            self.blocked.append((wx - ww / 2 - ROW_GAP[0], wz - wd / 2 - ROW_GAP[0], wx + ww / 2 + ROW_GAP[0], wz + wd / 2 + ROW_GAP[0]))

    # -- one house: the model, its lot near the model's own size, its height fitted to the row
    def lot(self, model, prev_h, band, trend=0):
        """(w, d, h). In a row the skyline walks: a step of 1 to 4 studs from the neighbour, the
        same way for a few houses (a rise, a fall), never more than a FLOW step: the next roof
        is always taken at a run."""
        m = MODELS[model]
        rng = self.rng
        w = round(m["w"] * rng.uniform(*STRETCH), 1)
        d = round(m["d"] * rng.uniform(0.95, 1.08), 1)
        lo, hi = self.h_range(model, band)
        if prev_h is None:
            h = rng.uniform(lo, hi)
        else:
            h = min(max(prev_h + (trend or rng.choice((-1, 1))) * rng.uniform(*ROW_STEP), lo), hi)
        return w, d, round(h, 1)

    @staticmethod
    def h_range(model, band):
        m = MODELS[model]
        lo, hi = m["h"] * HEIGHT_FIT[0], m["h"] * HEIGHT_FIT[1]
        lo, hi = max(lo, band[0] - 2), min(hi, band[1] + 2)
        return (lo, hi) if lo <= hi else (m["h"], m["h"])

    def pick_model(self, district, prev_h):
        """A model of the district whose height can follow the neighbour's at a run."""
        ch = CHARACTER.get(district, dict(mix=[("small_house", 1)], band=(7, 21)))
        options = []
        for model, n in ch["mix"]:
            lo, hi = self.h_range(model, ch["band"])
            if prev_h is None or (lo - FLOW_RISE + 1 <= prev_h <= hi + FLOW_RISE - 1):
                options += [model] * n
        if not options:
            return None
        return self.rng.choice(options)

    def place(self, model, x, z, w, d, h, yaw, gap):
        """A house on its lot, if the lot is free and its door keeps a way out: the strip
        before its door (an alley's width) stays clear, and it stands in no other's."""
        x, z = round(x, 1), round(z, 1)   # the rect of what is written (the game reads tenths)
        r = rect_of(x, z, w, d, yaw)
        if not self.free(r, gap):
            return None
        # (23/11) never over a spot the game uses (a master, a spawn, the proctor, a street duel)
        if not hasattr(self, "_spots"):
            pts = self.keep_points()
            self._spots = pts + [(px / K.SCALE, pz / K.SCALE) for px, pz in pts]
        if any(r[0] - 2.5 < px < r[2] + 2.5 and r[1] - 2.5 < pz < r[3] + 2.5 for px, pz in self._spots):
            return None
        if any(K.overlap(r, st) for st in self.doors):
            return None
        strip = door_strip(x, z, w, d, yaw)
        if any(K.overlap(strip, b["rect"]) for b in self.buildings):
            return None
        self.doors.append(strip)
        self.buildings.append(dict(id=f"H{len(self.buildings) + 1}", model=model, x=round(x, 1), z=round(z, 1),
                                   w=w, d=d, h=h, yaw=yaw, district=K.district_at(x, z), rect=r, landmark=False))
        return self.buildings[-1]

    # -- the holes the rows left: houses facing their nearest street, back to back with the rows
    def infill(self):
        rng = self.rng
        pts = []
        for x in range(-284, 285, 3):
            for z in range(-194, 212, 3):
                dist = K.district_at(x, z)
                if dist in NO_FABRIC or blocked_cell(x, z):
                    continue
                pts.append((x, z, dist))
        # from the streets inward, so a hole is filled from its open side
        pts.sort(key=lambda p: street_distance(p[0], p[1]) + rng.uniform(0, 2))
        for x, z, dist in pts:
            # (23/11) the dense quarters only; elsewhere the holes are gardens (greenery)
            if DENSE.get(dist, 1) < 3:
                continue
            pr = (x - .5, z - .5, x + .5, z + .5)
            if any(K.overlap(pr, b["rect"], 2) for b in self.buildings):
                continue
            to = nearest_street_dir(x, z)
            if abs(to[0]) > abs(to[1]):
                yaw = 90 if to[0] > 0 else 270
            else:
                yaw = 0 if to[1] > 0 else 180
            near = min((b for b in self.buildings if not b["landmark"]),
                       key=lambda b: gap_between(pr, b["rect"]), default=None)
            prev_h = near["h"] if near is not None and gap_between(pr, near["rect"]) < FLOW_GAP else None
            band = CHARACTER.get(dist, dict(band=(7, 21)))["band"]
            mix = [m for m, _ in CHARACTER.get(dist, dict(mix=[("small_house", 1)]))["mix"]]
            mix.sort(key=lambda m: -MODELS[m]["w"] * MODELS[m]["d"])
            for model in mix:
                lo, hi = self.h_range(model, band)
                if prev_h is not None and not (lo - FLOW_RISE + 1 <= prev_h <= hi + FLOW_RISE - 1):
                    continue
                w, d, h = self.lot(model, prev_h, band)
                for shrink in (1.0, 0.85):
                    ww, dd = round(w * shrink, 1), round(d * shrink, 1)
                    if ww < MODELS[model]["w"] * 0.8:
                        continue
                    # the lot's corner at the point, its door toward the street
                    fx, fz = {0: (0, 1), 180: (0, -1), 90: (1, 0), 270: (-1, 0)}[yaw]
                    ex, ez = (ww, dd) if yaw in (0, 180) else (dd, ww)
                    cx = x if fx == 0 else x - fx * ex / 2
                    cz = z if fz == 0 else z - fz * ez / 2
                    b = self.place(model, cx, cz, ww, dd, h, yaw, gap=ROW_GAP[0])
                    if b:
                        b["infill"] = True
                        break
                else:
                    continue
                break

    # -- the rows along every street, facing it; rows behind, across back alleys
    def frontage(self):
        rng = self.rng
        streets = list(K.STREETS)
        rng.shuffle(streets)
        self.fronts = []
        for s in streets:
            (x0, z0), (x1, z1), wd = s[2], s[3], s[4]
            along_x = z0 == z1
            length = abs(x1 - x0) if along_x else abs(z1 - z0)
            for side in (-1, 1):
                t, prev_h, trend = 2.0, None, rng.choice((-1, 1))
                run_model, run_district = None, None
                while t < length - 2:
                    px = min(x0, x1) + t if along_x else x0
                    pz = z0 if along_x else min(z0, z1) + t
                    probe = (px + (0 if along_x else side * (wd / 2 + 9)), pz + (side * (wd / 2 + 9) if along_x else 0))
                    district = K.district_at(*probe)
                    if district in NO_FABRIC:
                        t += 4
                        prev_h = None
                        continue
                    band = CHARACTER.get(district, dict(band=(7, 21)))["band"]
                    b = None
                    # the model the row wants (the row's own, while it lasts); a narrower lot of
                    # it, then another model, before a gap
                    if run_model is not None and run_district != district:
                        run_model = None
                    for attempt in range(4):
                        model = run_model if (run_model and attempt < 2) else self.pick_model(district, prev_h if attempt < 3 else None)
                        if not model:
                            continue
                        w, d, h = self.lot(model, prev_h if attempt < 3 else None, band, trend)
                        if attempt == 1:
                            w = round(MODELS[model]["w"] * STRETCH[0], 1)
                        off = wd / 2 + 1.5 + d / 2
                        if along_x:
                            hx, hz, yaw = px + w / 2, z0 + side * off, (0 if side < 0 else 180)
                        else:
                            hx, hz, yaw = x0 + side * off, pz + w / 2, (90 if side < 0 else 270)
                        b = self.place(model, hx, hz, w, d, h, yaw, gap=ROW_GAP[0])
                        if b:
                            break
                    if b:
                        b["street"] = s[0]
                        b["side"] = side
                        b["inward"] = (0, side) if along_x else (side, 0)
                        self.fronts.append(b)
                        if prev_h is not None and rng.random() < .3:
                            trend = -trend
                        lo, hi = self.h_range(b["model"], band)
                        if h >= hi - .5:
                            trend = -1
                        elif h <= lo + .5:
                            trend = 1
                        prev_h = h
                        run_model, run_district = b["model"], district
                        gap = rng.uniform(*ALLEY) if rng.random() < self.alley_chance else rng.uniform(*ROW_GAP)
                        if gap >= ALLEY[0] and rng.random() < .5:
                            run_model = None      # across an alley the next row may change
                        t += w + gap
                    else:
                        t += 2.0
                        prev_h = None
                        run_model = None

    def back(self, rows=5):
        """Behind each house of a street, across a back alley, a house facing that alley; the
        rows go on inward until they meet the rows of the street behind (a perimeter block)."""
        if not self.back_rows:
            return
        rng = self.rng
        for f in list(self.fronts):
            nx, nz = f["inward"]
            district = f["district"]
            if district in NO_FABRIC:
                continue
            band = CHARACTER.get(district, dict(band=(7, 21)))["band"]
            for _row in range(min(rows, DENSE.get(district, 1))):
                b = None
                for attempt in range(3):
                    model = f["model"] if attempt == 0 and f["model"] in dict(CHARACTER.get(district, dict(mix=[]))["mix"]) else self.pick_model(district, f["h"])
                    if not model:
                        break
                    w, d, h = self.lot(model, f["h"], band)
                    if attempt == 2:
                        d = round(MODELS[model]["d"] * 0.9, 1)
                    alley = rng.uniform(*ALLEY) if attempt == 0 else ALLEY[0]
                    dist = f["d"] / 2 + alley + d / 2
                    x, z = f["x"] + nx * dist, f["z"] + nz * dist
                    yaw = f["yaw"]  # its door on the alley, looking at the back of the row in front
                    b = self.place(model, x, z, w, d, h, yaw, gap=ROW_GAP[0])
                    if b:
                        break
                if not b:
                    break
                b["inward"] = (nx, nz)
                b["back"] = True
                f = b

    # -- bridges: a plank walkway roof to roof over a lane (the anime's Konoha has them over its
    #    back streets), where two houses face each other across it at nearly one height
    def bridge_pass(self, every=44):
        if not self.with_bridges:
            return
        for s in K.STREETS:
            (x0, z0), (x1, z1), wd = s[2], s[3], s[4]
            if wd > 16:
                continue
            along_x = z0 == z1
            row = [b for b in self.buildings if b.get("street") == s[0] and b["h"] >= 10]
            west = [b for b in row if b.get("side") == -1]
            east = [b for b in row if b.get("side") == 1]
            pairs = []
            for a in west:
                for b in east:
                    ra, rb = a["rect"], b["rect"]
                    lo, hi = (max(ra[0], rb[0]), min(ra[2], rb[2])) if along_x else (max(ra[1], rb[1]), min(ra[3], rb[3]))
                    if hi - lo >= 5 and abs(a["h"] - b["h"]) <= 4:
                        pairs.append(((lo + hi) / 2, a, b))
            pairs.sort(key=lambda t: t[0])
            last = -1e9
            for c, a, b in pairs:
                if c - last < every:
                    continue
                ra, rb = a["rect"], b["rect"]
                ta, tb = a["h"] + 1, b["h"] + 1
                if along_x:   # the lane runs along X: the bridge crosses it along Z
                    br = dict(x0=c, z0=ra[3] - 1, top0=ta, x1=c, z1=rb[1] + 1, top1=tb, width=3.0)
                else:
                    br = dict(x0=ra[2] - 1, z0=c, top0=ta, x1=rb[0] + 1, z1=c, top1=tb, width=3.0)
                if self.bridge_clear(br):
                    self.bridges.append(br)
                    last = c

    def bridge_clear(self, br):
        """Not over an open place (a duel, a square: the sky stays open over a fight)."""
        mx, mz = (br["x0"] + br["x1"]) / 2, (br["z0"] + br["z1"]) / 2
        for o in K.OPEN:
            if o[0] == "circle" and math.hypot(mx - o[1], mz - o[2]) < o[3] + 6:
                return False
            if o[0] == "rect" and o[1] - 6 <= mx <= o[3] + 6 and o[2] - 6 <= mz <= o[4] + 6:
                return False
        return True

    def landmark_clear(self):
        """Beside a landmark a house is flush or a lane away (CRACK). One in between is stretched up to
        the landmark, or narrowed away from it to a lane, whichever moves its wall least within
        the model's size (the infill's 0.8 to STRETCH) and touches no other lot; neither
        possible, the crack is walled up (`fills`, Server/Hub's Fill) and the house stays."""
        marks = [m for m in self.buildings if m["landmark"]]

        def bad(r):
            return any(CRACK[0] < gap_between(r, m["rect"]) < CRACK[1] for m in marks)

        def fits(b, r):
            ex, ez = r[2] - r[0], r[3] - r[1]
            w, d = (ex, ez) if int(b["yaw"]) % 180 == 0 else (ez, ex)
            mw, md = MODELS[b["model"]]["w"], MODELS[b["model"]]["d"]
            return .8 * mw <= w <= STRETCH[1] * mw and .8 * md <= d <= STRETCH[1] * md

        def options(r, m):
            out = []
            lo = m["rect"]
            # toward the landmark (flush) or away from it (a lane), on each axis
            if r[2] <= lo[0]:
                out += [(r[0], r[1], lo[0] - CRACK[0] + .2, r[3]), (r[0], r[1], lo[0] - CRACK[1] - .1, r[3])]
            if r[0] >= lo[2]:
                out += [(lo[2] + CRACK[0] - .2, r[1], r[2], r[3]), (lo[2] + CRACK[1] + .1, r[1], r[2], r[3])]
            if r[3] <= lo[1]:
                out += [(r[0], r[1], r[2], lo[1] - CRACK[0] + .2), (r[0], r[1], r[2], lo[1] - CRACK[1] - .1)]
            if r[1] >= lo[3]:
                out += [(r[0], lo[3] + CRACK[0] - .2, r[2], r[3]), (r[0], lo[3] + CRACK[1] + .1, r[2], r[3])]
            return out

        keep, fixed, gone, filled = [], 0, 0, 0
        for b in self.buildings:
            if b["landmark"] or not bad(b["rect"]):
                keep.append(b)
                continue
            r0 = b["rect"]
            others = [o["rect"] for o in self.buildings if o is not b]
            best = None
            for m in marks:
                if not (CRACK[0] < gap_between(r0, m["rect"]) < CRACK[1]):
                    continue
                for r in options(r0, m):
                    if r[2] - r[0] < 4 or r[3] - r[1] < 4 or bad(r) or not fits(b, r):
                        continue
                    if any(K.overlap(r, o, ROW_GAP[0] - .05) for o in others if not any(o is mm["rect"] for mm in marks)):
                        continue
                    if any(K.overlap(r, mm["rect"]) for mm in marks):
                        continue
                    # never stretched onto a street or an open place
                    if any(K.overlap(r, bl) for bl in self.blocked):
                        continue
                    if any((o[0] == "circle" and K.rect_circle(r, o[1], o[2], o[3])) or (o[0] == "rect" and K.overlap(r, o[1:5])) for o in K.OPEN):
                        continue
                    cost = sum(abs(r[i] - r0[i]) for i in range(4))
                    if best is None or cost < best[0]:
                        best = (cost, r)
            if best is None:
                # held by its neighbours: the crack is walled up (a plaster infill between the
                # two, the lower's height: Server/Hub's Fill), the house stays
                for m in marks:
                    if CRACK[0] < gap_between(r0, m["rect"]) < CRACK[1]:
                        self.fills.append(self.fill_between(r0, b["h"], m))
                keep.append(b)
                filled += 1
                continue
            r = best[1]
            ex, ez = r[2] - r[0], r[3] - r[1]
            b["x"], b["z"] = round((r[0] + r[2]) / 2, 1), round((r[1] + r[3]) / 2, 1)
            b["w"], b["d"] = (round(ex, 1), round(ez, 1)) if int(b["yaw"]) % 180 == 0 else (round(ez, 1), round(ex, 1))
            b["rect"] = rect_of(b["x"], b["z"], b["w"], b["d"], b["yaw"])
            fixed += 1
            if bad(b["rect"]):
                gone += 1
                continue
            keep.append(b)
        self.buildings = keep
        self.cracks = dict(fixed=fixed, filled=filled, removed=gone)
        return self.cracks

    @staticmethod
    def fill_between(r, h, m):
        """The block that walls up the crack between a house's rect `r` (height h) and a
        landmark: the space between them on the axes they face across, as high as the lower."""
        lo = m["rect"]
        x0, x1 = (r[2], lo[0]) if r[2] <= lo[0] else (lo[2], r[0]) if r[0] >= lo[2] else (max(r[0], lo[0]), min(r[2], lo[2]))
        z0, z1 = (r[3], lo[1]) if r[3] <= lo[1] else (lo[3], r[1]) if r[1] >= lo[3] else (max(r[1], lo[1]), min(r[3], lo[3]))
        return dict(x0=round(x0, 1), z0=round(z0, 1), x1=round(x1, 1), z1=round(z1, 1), top=round(min(h, m["h"]), 1))

    def lamps_clear(self):
        """A lamp right before the middle of a house's wall (the wall a ninja runs at): slid along
        its street, up to 14 (half the widest house), to stand LAMP_CLEAR from every wall or at the
        seam between two houses (1.5 from a wall's end), 8 from any other lamp; none on its
        stretch, it goes."""
        def exact(b):   # the rect as the game builds it (rect_of rounds to a tenth)
            ex, ez = (b["w"], b["d"]) if int(b["yaw"]) % 180 == 0 else (b["d"], b["w"])
            return (b["x"] - ex / 2, b["z"] - ez / 2, b["x"] + ex / 2, b["z"] + ez / 2)
        houses = [exact(b) for b in self.buildings if not b["landmark"]]
        moved, stuck = 0, []

        def clear(x, z, along_x=None):
            for r in houses:
                if gap_between((x - .3, z - .3, x + .3, z + .3), r) >= LAMP_CLEAR:
                    continue
                # the wall it stands before: the face it is out from (x when it is beyond an end
                # in z, the X-long front), its place along that face
                dx = max(0.0, max(x - .3, r[0]) - min(x + .3, r[2]))
                dz = max(0.0, max(z - .3, r[1]) - min(z + .3, r[3]))
                a, lo, hi = (x, r[0], r[2]) if dz >= dx else (z, r[1], r[3])
                if lo + 1.4 < a < hi - 1.4:     # (1.5 in the game plan's test: a margin)
                    return False
            return True
        for p in self.props:
            if p["kind"] != "lamp":
                continue
            street = next((st for st in K.STREETS if K.overlap((p["x"], p["z"], p["x"], p["z"]), K.street_rect(st))), None)
            if street is None:
                continue
            r = K.street_rect(street)
            along_x = street[2][1] == street[3][1]
            if clear(p["x"], p["z"], along_x):
                continue
            others = [(o["x"], o["z"]) for o in self.props if o["kind"] == "lamp" and o is not p]
            for k in range(1, 15):
                for step in (k, -k):
                    x, z = (p["x"] + step, p["z"]) if along_x else (p["x"], p["z"] + step)
                    if not (r[0] + 1 <= x <= r[2] - 1 and r[1] + 1 <= z <= r[3] - 1 and clear(x, z, along_x)):
                        continue
                    if any((x - ox) ** 2 + (z - oz) ** 2 < 8 ** 2 for ox, oz in others):
                        continue
                    p["x"], p["z"] = round(x, 1), round(z, 1)
                    moved += 1
                    break
                else:
                    continue
                break
            else:
                stuck.append(p)
        # one that finds no seam on its stretch goes: a lamp less, not a wall barred
        self.props = [p for p in self.props if not any(p is q for q in stuck)]
        self.lamps_moved, self.lamps_dropped = moved, len(stuck)
        return moved

    def props_pass(self):
        super().props_pass()
        # (the old pass's backyards: a crate in every gap a scattered house left) the rows
        # have alleys, not gaps: their crates stay out of the run
        self.props = [p for p in self.props if not (p["kind"] in ("crate", "barrel") and self.in_alley(p))]

    def in_alley(self, p):
        r = (p["x"] - 1.5, p["z"] - 1.5, p["x"] + 1.5, p["z"] + 1.5)
        return sum(1 for b in self.buildings if not b["landmark"] and gap_between(r, b["rect"]) < 2) >= 2

    def smooth(self, passes=6):
        """The skyline relaxed: a house more than a FLOW step from its neighbours (rows that met
        at a corner, back to back) takes their middle height, within what its model allows."""
        houses = [b for b in self.buildings if not b["landmark"]]
        near = {id(b): [o for o in houses if o is not b and gap_between(b["rect"], o["rect"]) <= FLOW_GAP] for b in houses}
        for _ in range(passes):
            moved = 0
            for b in houses:
                ns = near[id(b)]
                if not ns or max(abs(o["h"] - b["h"]) for o in ns) <= FLOW_RISE:
                    continue
                hs = sorted(o["h"] for o in ns)
                mid = hs[len(hs) // 2]
                lo, hi = self.h_range(b["model"], CHARACTER.get(b["district"], dict(band=(7, 21)))["band"])
                h = round(min(max(mid, lo), hi), 1)
                if h != b["h"]:
                    b["h"] = h
                    moved += 1
            if not moved:
                break

    def keep_points(self):
        """The ANIMATEUR's variety pass leaves alone what the game uses on or by a roof: HubMap's
        spots, and here THE ROOFTOPS (its post and decks), where the race starts and ends. (The
        race itself is drawn after, on these roofs: Shared/Solo's own rings no longer count.)"""
        pts = []
        try:
            import re
            hm = open(os.path.join(GAME, "src", "Shared", "HubMap.luau")).read()
            pts += [(float(a), float(c)) for a, b, c in re.findall(r"at=Vector3\.new\((-?[\d.]+),(-?[\d.]+),(-?[\d.]+)\)", hm)]
        except OSError:
            pass
        post = next(p for p in K.POIS if p[0] == "Rooftops")
        pts.append((post[2], post[3]))
        pts += [(d["x"], d["z"]) for d in self.decks]
        return pts

    def variety(self):
        """(22/11, the ANIMATEUR, François: « la différence entre les bâtiments n'est pas assez
        forte, le village est trop lisse ») K.Plan.variety_pass on this fabric: some lots become
        towers that break the skyline (vantage points: a leap up from the roofs beside them),
        pocket gardens fill the gaps. A garden never stands before a door (its way out)."""
        before = len(self.props)
        was = {id(b): (b["model"], b["h"]) for b in self.buildings}
        self.variety_pass()
        # (23/11) a few watchtowers only, in the busy quarters; the other lots keep their house
        towers = [b for b in self.buildings if b["model"] == "tower_house" and was.get(id(b), ("tower_house",))[0] != "tower_house"]
        towers.sort(key=lambda b: (b.get("district") not in ("Market", "Centre", "Civic"), b["x"], b["z"]))
        for b in towers[TOWERS_MAX:]:
            b["model"], b["h"] = was[id(b)]
        added = self.props[before:]
        kept = [p for p in added if not any(K.overlap((p["x"] - 2, p["z"] - 2, p["x"] + 2, p["z"] + 2), st) for st in self.doors)]
        self.props = self.props[:before] + kept

    def greenery(self, every=7.0, most=160):
        """(23/11, « un village ninja », the Leaf) Trees in the quiet quarters' gardens, in the
        holes the rows leave: never on a street, a doorstep or against a wall."""
        rng = self.rng
        pts = [(x, z) for x in range(-282, 283, int(every)) for z in range(-192, 210, int(every))]
        rng.shuffle(pts)
        n = 0
        for x, z in pts:
            if n >= most:
                break
            if K.district_at(x, z) not in ("Residences", "Alleys", "Uchiha", "TeaStreet", "Centre", "Hyuga"):
                continue
            if blocked_cell(x, z) or not self.free_prop(x, z):
                continue
            r = (x - 1, z - 1, x + 1, z + 1)
            if any(gap_between(r, b["rect"]) < 3.5 for b in self.buildings):
                continue
            if any(K.overlap(r, st, 1) for st in self.doors) or self.near_prop(x, z, 6):
                continue
            self.prop("tree", x + rng.uniform(-1.5, 1.5), z + rng.uniform(-1.5, 1.5), rng.uniform(0, 360), round(rng.uniform(12, 18), 1))
            n += 1
        self.trees = n
        return n

    def generate(self):
        self.frontage()
        self.back()
        if self.with_infill:
            self.infill()
        self.landmark_clear()
        self.smooth()
        self.props_pass()
        self.variety()
        self.greenery()
        self.lamps_clear()
        self.bridge_pass()
        self.race = race_route(self)
        # after the race: its rings and its route stay the seed's
        self.landmark_links()
        return self

    # -- (26/11, passe 3, DEC-055: « des routes sur les toits de bout en bout, porte -> salle de
    #    l'Examen sans toucher le sol ») The tournament's landmarks are reached over the roofs:
    #    the exam hall's wings, from the nearest row's roof across the street before it (a
    #    longer walkway than a lane's: measured in Studio, the hall stood 25.5 base studs from
    #    the roofs, past the second jump's 22.3).
    LINKS = ("ExamHallWest", "ExamHallEast")
    LINK_REACH = 28.0      # base studs, roof edge to roof edge
    LINK_RISE = 6.0        # at most this much higher at the landmark's end
    LINK_OVERLAP = 3.5     # facing each other at least this wide

    def landmark_links(self):
        """Each landmark of LINKS gets one walkway from the nearest roof it cannot be jumped to
        from (farther than the second jump, LEAP_GAP), within LINK_REACH, facing it at least
        LINK_OVERLAP wide, never over an open place."""
        if not self.with_bridges:
            return
        for lid in self.LINKS:
            mark = next((b for b in self.buildings if b.get("id") == lid), None)
            if not mark:
                continue
            rm = mark["rect"]
            options = []
            for b in self.buildings:
                if b.get("landmark") or b["h"] < 10 or abs(mark["h"] - b["h"]) > self.LINK_RISE:
                    continue
                rb = b["rect"]
                tb, tm = b["h"] + 1, mark["h"] + 1
                for along_z in (True, False):
                    lo, hi = (max(rb[0], rm[0]), min(rb[2], rm[2])) if along_z else (max(rb[1], rm[1]), min(rb[3], rm[3]))
                    if hi - lo < self.LINK_OVERLAP:
                        continue
                    c, width = (lo + hi) / 2, min(3.0, hi - lo - .5)
                    lo_b, hi_b, lo_m, hi_m = (rb[1], rb[3], rm[1], rm[3]) if along_z else (rb[0], rb[2], rm[0], rm[2])
                    if hi_b <= lo_m:
                        gap, pb, pm = lo_m - hi_b, hi_b - 1, lo_m + 1
                    elif hi_m <= lo_b:
                        gap, pb, pm = lo_b - hi_m, lo_b + 1, hi_m - 1
                    else:
                        continue
                    if not (LEAP_GAP < gap <= self.LINK_REACH):
                        continue
                    if along_z:
                        br = dict(x0=c, z0=pb, top0=tb, x1=c, z1=pm, top1=tm, width=width)
                    else:
                        br = dict(x0=pb, z0=c, top0=tb, x1=pm, z1=c, top1=tm, width=width)
                    options.append((gap, br))
            options.sort(key=lambda t: t[0])
            for gap, br in options:
                if self.bridge_clear(br):
                    br["link"] = lid
                    self.bridges.append(br)
                    break


def current_plan():
    """The plan the game had before (tools/blender/konoha_layout.py's own fabric, seed 19): the
    bar a candidate must beat."""
    p = K.Plan()
    p.frontage()
    p.backfill()
    p.props_pass()
    p.bridges = []
    p.decks = [dict(x=x, z=z, w=w, d=d, top=t) for x, z, w, d, t in K.ROOF_DECKS]
    p.race = None
    return p


# ---------------------------------------------------------------------------------------- roofs
def roofs_of(plan):
    """Every top a ninja runs on: {rect, top}. A house's roof is its wall top + 1."""
    out = []
    for b in plan.buildings:
        if b["landmark"] and b["model"] in ("torii", "memorial_stone", "academy_tree", "pier", "great_gate"):
            continue
        out.append(dict(rect=b["rect"], top=b["h"] + 1, b=b, kind="landmark" if b["landmark"] else "house"))
    for d in plan.decks:
        out.append(dict(rect=rect_of(d["x"], d["z"], d["w"], d["d"], 0), top=d["top"], kind="deck"))
    for br in getattr(plan, "bridges", []):
        x0, x1 = sorted((br["x0"], br["x1"]))
        z0, z1 = sorted((br["z0"], br["z1"]))
        hw = br["width"] / 2
        r = (x0 - (hw if x0 == x1 else 0), z0 - (hw if z0 == z1 else 0), x1 + (hw if x0 == x1 else 0), z1 + (hw if z0 == z1 else 0))
        out.append(dict(rect=r, top=max(br["top0"], br["top1"]), kind="bridge"))
    return out


def links(roofs):
    """The jumps between roofs: (i, j, kind) for i→j, kind 'flow' or 'leap'."""
    out = []
    n = len(roofs)
    # a coarse grid: only the roofs near each other are compared
    cell = 24.0
    grid = {}
    for i, r in enumerate(roofs):
        x0, z0, x1, z1 = r["rect"]
        for gx in range(int(math.floor(x0 / cell)), int(math.floor(x1 / cell)) + 1):
            for gz in range(int(math.floor(z0 / cell)), int(math.floor(z1 / cell)) + 1):
                grid.setdefault((gx, gz), []).append(i)
    seen = set()
    for (gx, gz), members in grid.items():
        near = set()
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                near.update(grid.get((gx + dx, gz + dz), ()))
        for i in members:
            for j in near:
                if i == j or (i, j) in seen:
                    continue
                seen.add((i, j))
                a, b = roofs[i], roofs[j]
                g = gap_between(a["rect"], b["rect"])
                rise = b["top"] - a["top"]
                if rise < -DROP_OK * 2:
                    continue
                if rise <= FLOW_RISE and rise >= -DROP_OK and g <= reach(rise):
                    out.append((i, j, "flow"))
                elif rise <= LEAP_RISE and g <= reach(rise, True):
                    out.append((i, j, "leap"))
    return out


def components(n, edges, kinds=("flow", "leap")):
    """The groups of roofs a run can go round both ways (an edge both ways)."""
    adj = {i: set() for i in range(n)}
    have = {(i, j) for i, j, k in edges if k in kinds}
    for i, j in have:
        if (j, i) in have:
            adj[i].add(j)
            adj[j].add(i)
    seen, comps = set(), []
    for i in range(n):
        if i in seen:
            continue
        stack, comp = [i], []
        seen.add(i)
        while stack:
            k = stack.pop()
            comp.append(k)
            for m in adj[k]:
                if m not in seen:
                    seen.add(m)
                    stack.append(m)
        comps.append(comp)
    comps.sort(key=len, reverse=True)
    return comps, adj


def centre(r):
    x0, z0, x1, z1 = r["rect"]
    return ((x0 + x1) / 2, (z0 + z1) / 2)


def longest_run(roofs, comp, adj):
    """The longest of the shortest runs across one group (two sweeps): its length and its roofs."""
    if len(comp) < 2:
        return 0.0, comp

    def far(start):
        import heapq
        dist, prev = {start: 0.0}, {start: None}
        q = [(0.0, start)]
        while q:
            dd, k = heapq.heappop(q)
            if dd > dist[k]:
                continue
            ck = centre(roofs[k])
            for m in adj[k]:
                cm = centre(roofs[m])
                nd = dd + math.hypot(ck[0] - cm[0], ck[1] - cm[1])
                if nd < dist.get(m, 1e18):
                    dist[m], prev[m] = nd, k
                    heapq.heappush(q, (nd, m))
        end = max(dist, key=dist.get)
        path, k = [], end
        while k is not None:
            path.append(k)
            k = prev[k]
        return dist[end], path[::-1]

    _, path = far(comp[0])
    length, path = far(path[-1])
    return length, path


# ---------------------------------------------------------------------------------------- score
def blocked_cell(x, z):
    """A cell of the village that is meant to be empty: a street, an open place, the river."""
    for s in K.STREETS:
        r = K.street_rect(s)
        if r[0] <= x <= r[2] and r[1] <= z <= r[3]:
            return True
    for o in K.OPEN:
        if o[0] == "circle" and (x - o[1]) ** 2 + (z - o[2]) ** 2 <= o[3] ** 2:
            return True
        if o[0] == "rect" and o[1] <= x <= o[3] and o[2] <= z <= o[4]:
            return True
    return False


def nearest_street_dir(x, z):
    """The unit direction from (x, z) to the nearest street or open place."""
    best, out = 1e18, (0.0, 1.0)
    rects = [K.street_rect(s) for s in K.STREETS] + [o[1:5] for o in K.OPEN if o[0] == "rect"]
    for r in rects:
        nx, nz = min(max(x, r[0]), r[2]), min(max(z, r[1]), r[3])
        d = math.hypot(nx - x, nz - z)
        if 0 < d < best:
            best, out = d, ((nx - x) / d, (nz - z) / d)
    for o in K.OPEN:
        if o[0] == "circle":
            d = math.hypot(o[1] - x, o[2] - z) - o[3]
            if 0 < d < best:
                c = math.hypot(o[1] - x, o[2] - z)
                best, out = d, ((o[1] - x) / c, (o[2] - z) / c)
    return out


def score(plan):
    """Out of 10, with what each measure gave (the ANIMATEUR's notes, for a village)."""
    roofs = roofs_of(plan)
    n = len(roofs)
    edges = links(roofs)
    comps, adj_all = components(n, edges, ("flow", "leap"))
    fcomps, adj_flow = components(n, edges, ("flow",))
    houses = [r for r in roofs if r["kind"] == "house"]
    nh = max(1, len(houses))
    idx = {id(r): i for i, r in enumerate(roofs)}
    big = set(comps[0]) if comps else set()
    fbig = set(fcomps[0]) if fcomps else set()
    m = {}
    # 1. the run: the houses' roofs that are one network (a jump, or the second one)
    m["network"] = sum(1 for r in houses if idx[id(r)] in big) / nh
    # 2. its flow: the houses' roofs a run reaches without the second jump
    #    (a block run round without touching the ground: a flow group of 8 roofs or more; the
    #    lanes between blocks are leaps, the ninja's bound over a street, on purpose)
    inflow = set()
    for c in fcomps:
        if len(c) >= 8:
            inflow.update(c)
    m["flow"] = sum(1 for r in houses if idx[id(r)] in inflow) / nh
    # 3. the longest run without touching the ground (flow jumps), against 450 base studs
    length, path = longest_run(roofs, fcomps[0], adj_flow) if fcomps else (0, [])
    m["longest"] = min(1.0, length / 450.0)
    # 4. the way up: a roof reached from the street (its wall run up, a deck's ladder)
    up = 0
    for i, r in enumerate(roofs):
        if r["kind"] != "house":
            continue
        if r["top"] <= CLIMB or any(roofs[j]["top"] <= CLIMB for j in adj_all[i]):
            up += 1
    m["access"] = up / nh
    # 5. the empty space: cells of the walled village (below the rock) with nothing near
    things = [b["rect"] for b in plan.buildings] + [roofs[i]["rect"] for i in range(n)]
    things += [(p["x"] - 2, p["z"] - 2, p["x"] + 2, p["z"] + 2) for p in plan.props if p["kind"] in ("tree", "stall")]
    cell, empty, total = 8, 0, 0
    grid = {}
    for t in things:
        for gx in range(int((t[0] - 12) // cell), int((t[2] + 12) // cell) + 1):
            for gz in range(int((t[1] - 12) // cell), int((t[3] + 12) // cell) + 1):
                grid[(gx, gz)] = True
    for x in range(-K.HALF_X + 4, K.HALF_X - 3, cell):
        for z in range(-196, K.MAX_Z - 3, cell):
            if blocked_cell(x, z):
                continue
            total += 1
            if not grid.get((int(x // cell), int(z // cell))):
                empty += 1
    m["empty"] = empty / max(1, total)
    # 5b. the village built: the share of the buildable ground (not a street, an open place,
    #     the rock or the training meadow) under a roof. « La carte n'est pas complète ».
    built = ground = 0
    rects = [b["rect"] for b in plan.buildings] + [rect_of(dk["x"], dk["z"], dk["w"], dk["d"], 0) for dk in plan.decks]
    cellg = {}
    for r in rects:
        for gx in range(int(math.floor(r[0] / 2)), int(math.floor(r[2] / 2)) + 1):
            for gz in range(int(math.floor(r[1] / 2)), int(math.floor(r[3] / 2)) + 1):
                cx, cz = gx * 2 + 1, gz * 2 + 1
                if r[0] <= cx <= r[2] and r[1] <= cz <= r[3]:
                    cellg[(gx, gz)] = True
    for gx in range(-142, 142):
        for gz in range(-97, 106):
            cx, cz = gx * 2 + 1, gz * 2 + 1
            if K.district_at(cx, cz) in NO_FABRIC or blocked_cell(cx, cz):
                continue
            ground += 1
            built += cellg.get((gx, gz), False)
    m["built"] = built / max(1, ground)
    # 6. the street: a house's door looks toward its street (a back row: toward the row in
    #    front, the same way), with an alley's width clear before it. A random yaw (the old
    #    backfill) turns three houses in four away from their street: the incoherence seen.
    faced = clear = 0
    for b in plan.buildings:
        if b["landmark"]:
            continue
        yaw = b["yaw"] % 360
        fx, fz = {0: (0, 1), 180: (0, -1), 90: (1, 0), 270: (-1, 0)}.get(yaw, (0, 1))
        to = nearest_street_dir(b["x"], b["z"])
        faced += (fx * to[0] + fz * to[1]) > 0.7
        half = b["w"] * 0.3
        dep = b["d"] / 2
        cx, cz = b["x"] + fx * (dep + 3.2), b["z"] + fz * (dep + 3.2)
        sx, sz = (half, 2.9) if fx == 0 else (2.9, half)
        strip = (cx - sx, cz - sz, cx + sx, cz + sz)
        clear += not any(K.overlap(strip, o["rect"]) for o in plan.buildings if o is not b)
    m["doors"] = (faced + clear) / (2 * nh)
    # 7. the skyline: two neighbours (a stride apart) differ by a storey at most
    pairs = steady = 0
    for i, r in enumerate(houses):
        for o in houses[i + 1:]:
            if gap_between(r["rect"], o["rect"]) <= FLOW_GAP:
                pairs += 1
                steady += abs(r["top"] - o["top"]) <= STEP_MAX
    m["skyline"] = steady / max(1, pairs)
    # 8. nothing built over another, nor over a street or an open place
    clash = 0
    bl = [b for b in plan.buildings]
    for i, a in enumerate(bl):
        for b in bl[i + 1:]:
            if K.overlap(a["rect"], b["rect"]):
                clash += 1
    m["clashes"] = clash
    note = (
        1.6 * m["network"] + 1.6 * m["flow"] + 1.2 * m["longest"] + 1.0 * m["access"]
        + 1.6 * min(1.0, m["built"] / 0.5) + 1.0 * m["doors"] + 1.0 * m["skyline"]
    ) / 9.0 * 10 - min(3.0, clash * 0.5)
    m["note"] = round(note, 2)
    m["roofs"] = n
    m["houses"] = len(houses)
    m["run_length"] = round(length, 1)
    m["path"] = [centre(roofs[i]) + (roofs[i]["top"],) for i in path]
    return m


# ---------------------------------------------------------------------------------------- the race
def race_route(plan, rings=10, target=(300.0, 420.0)):
    """The rooftop race drawn on these roofs: a loop from THE ROOFTOPS' decks (the start post,
    Pois "Rooftops") out over the market roofs and back by another way, a ring every tenth of it.
    A leap costs a little more than a flow jump, so the loop keeps the run's rhythm."""
    import heapq
    roofs = roofs_of(plan)
    edges = links(roofs)
    kinds = {(i, j): k for i, j, k in edges}
    adj = {i: [] for i in range(len(roofs))}
    for (i, j), k in kinds.items():
        if (j, i) in kinds:
            ci, cj = centre(roofs[i]), centre(roofs[j])
            d = math.hypot(ci[0] - cj[0], ci[1] - cj[1])
            adj[i].append((j, d * (1.0 if k == "flow" and kinds[(j, i)] == "flow" else 1.35), d))
    post = next(p for p in K.POIS if p[0] == "Rooftops")
    sx, sz = post[2], post[3]
    decks = [i for i, r in enumerate(roofs) if r["kind"] == "deck"]
    if not decks:
        return None
    decks.sort(key=lambda i: math.hypot(centre(roofs[i])[0] - sx, centre(roofs[i])[1] - sz))

    def dijkstra(src, banned=()):
        dist, prev = {src: 0.0}, {src: None}
        q = [(0.0, src)]
        while q:
            dd, k = heapq.heappop(q)
            if dd > dist[k]:
                continue
            for m2, cost, _ in adj[k]:
                if m2 in banned:
                    continue
                nd = dd + cost
                if nd < dist.get(m2, 1e18):
                    dist[m2], prev[m2] = nd, k
                    heapq.heappush(q, (nd, m2))
        return dist, prev

    def walk(prev, end):
        path, k = [], end
        while k is not None:
            path.append(k)
            k = prev[k]
        return path[::-1]

    def length(path):
        return sum(math.hypot(centre(roofs[a])[0] - centre(roofs[b])[0], centre(roofs[a])[1] - centre(roofs[b])[1])
                   for a, b in zip(path, path[1:]))

    start, home = decks[0], decks[-1]
    dist, prev = dijkstra(start)
    best = None
    for far in sorted(dist, key=lambda k: -dist[k]):
        out = walk(prev, far)
        lo = length(out)
        if not (target[0] * .38 <= lo <= target[1] * .55) or roofs[far]["kind"] != "house":
            continue
        back_d, back_p = dijkstra(far, banned=set(out[1:-1]) | {start})
        if home not in back_d:
            continue
        loop = out + walk(back_p, home)[1:]
        total = length(loop)
        if not (target[0] <= total <= target[1]):
            continue
        hops = list(zip(loop, loop[1:]))
        flow = sum(1 for a, b in hops if kinds.get((a, b)) == "flow") / max(1, len(hops))
        value = flow - abs(total - 360) / 400
        if best is None or value > best[0]:
            best = (value, loop, total, flow)
    if not best:
        return None
    _, loop, total, flow = best
    # the rings: ten roofs of the loop in its order (a house, a landmark's roof or a deck,
    # never a walkway), the last one home on the decks, chosen so the longest stretch between
    # two (the post to the first, too) is the shortest it can be: an even rhythm
    cand = [k for k in loop[1:] if roofs[k]["kind"] in ("house", "deck", "landmark")]
    if len(cand) < rings or cand[-1] != home:
        return None
    # (along the loop, not straight: a ring never lets the run cut the loop short)
    along = {loop[0]: 0.0}
    for a, b in zip(loop, loop[1:]):
        along[b] = along[a] + math.hypot(centre(roofs[a])[0] - centre(roofs[b])[0], centre(roofs[a])[1] - centre(roofs[b])[1])
    pos = [along[k] for k in cand]
    dist2 = lambda a, b: abs(b - a)
    INF = (1e18, 1e18)
    # best[j][n]: (longest stretch, sum of squares) of n rings ending at cand j
    best = [[INF] * (rings + 1) for _ in cand]
    back = [[None] * (rings + 1) for _ in cand]
    for j, pj in enumerate(pos):
        d = pj + math.hypot(centre(roofs[loop[0]])[0] - sx, centre(roofs[loop[0]])[1] - sz)
        best[j][1] = (d, d * d)
        for n in range(2, rings + 1):
            for i in range(j):
                bi = best[i][n - 1]
                if bi == INF:
                    continue
                d = dist2(pos[i], pj)
                c = (max(bi[0], d), bi[1] + d * d)
                if c < best[j][n]:
                    best[j][n], back[j][n] = c, i
    last = len(cand) - 1
    if best[last][rings] == INF:
        return None
    picked, j, n = [], last, rings
    while j is not None:
        picked.append(cand[j])
        j, n = back[j][n], n - 1
    picked = picked[::-1]
    out = []
    for node in picked:
        c = centre(roofs[node])
        out.append((round(c[0], 1), round(roofs[node]["top"], 1), round(c[1], 1)))
    # (Shared/Solo's suite: no two rings further apart than a run, 60)
    if any(math.hypot(out[i][0] - out[i - 1][0], out[i][2] - out[i - 1][2]) >= 56 for i in range(1, len(out))):
        return None
    ring_len = math.hypot(out[0][0] - sx, out[0][2] - sz) + sum(
        math.hypot(out[i][0] - out[i - 1][0], out[i][2] - out[i - 1][2]) for i in range(1, len(out)))
    return dict(rings=out, length=round(ring_len, 1), route=round(total, 1), flow=round(flow, 2), start=(sx, sz),
                path=[centre(roofs[k]) for k in loop])


# ---------------------------------------------------------------------------------------- outputs
def to_luau(plan):
    text = K.to_luau(plan)
    text = text.replace(
        "-- GENERATED by tools/blender/konoha_layout.py: do not edit by hand (edit the generator).",
        "-- GENERATED by tools/village/konoha_village.py (seed %d): do not edit by hand.\n"
        "-- Its fixed Konoha (landmarks, streets, open places) is tools/blender/konoha_layout.py's;\n"
        "-- the houses between them, the bridges and the race on the roofs are generated (23/11)." % plan.seed)
    f = lambda v: f"{v:.1f}".rstrip("0").rstrip(".")
    extra = ["-- (23/11) Walkways over the lanes, roof to roof: {x0, z0, top0, x1, z1, top1, width},",
             "-- from one roof's edge to the other's (Server/Hub lays a plank walkway between the tops).",
             "M.Bridges={"]
    for br in plan.bridges:
        extra.append("\t{%s}," % ",".join(f(br[k]) for k in ("x0", "z0", "top0", "x1", "z1", "top1", "width")))
    extra.append("}")
    extra.append("-- (23/11, the OUTILLEUR's bot stuck between the hospital and a tower) A crack beside a")
    extra.append("-- landmark too narrow to walk, walled up: {x0, z0, x1, z1, top} (Server/Hub's Fill).")
    extra.append("M.Fills={")
    for fl in getattr(plan, "fills", []):
        extra.append("\t{%s}," % ",".join(f(fl[k]) for k in ("x0", "z0", "x1", "z1", "top")))
    extra.append("}")
    if plan.race:
        r = plan.race
        # the medals from the length, at the rate the OUTILLEUR's robot ran the first route
        # (22/11: 352 studs of rings, 22.3 s for a run that misses nothing; gold 27, silver 34,
        # bronze 45): to be measured again by the robot on this route
        rate = r["length"] / 352.0
        medals = [round(27 * rate), round(34 * rate), round(45 * rate)]
        extra.append("-- (23/11) The rooftop race on these roofs (Shared/Solo): a loop from THE ROOFTOPS' decks,")
        extra.append("-- rings {x, top, z} in order on a roof or a deck; `length` the rings' (base studs, from the")
        extra.append("-- post); medals scaled from the first route's (to measure again with tools/villagebot).")
        extra.append("M.Race={length=%s,flow=%s,medals={gold=%d,silver=%d,bronze=%d},rings={" % (f(r["length"]), r["flow"], *medals))
        for ring in r["rings"]:
            extra.append("\t{%s}," % ",".join(f(v) for v in ring))
        extra.append("}}")
    i = text.index("\n-- A base position (x, z) on the minimap")
    return text[:i] + "\n" + "\n".join(extra) + text[i:]


def sheet(before, after, mb, ma, path):
    """The contact sheet: the plan in the game and the generated one, side by side, the roofs by
    height, the run drawn, the notes under each."""
    from PIL import Image, ImageDraw
    px = 1.6
    W, H = int(2 * K.HALF_X * px), int((K.MAX_Z - K.MIN_Z) * px)
    img = Image.new("RGB", (W * 2 + 30, H + 120), (246, 240, 226))
    dr = ImageDraw.Draw(img)

    def pt(x, z, ox):
        return (ox + (x + K.HALF_X) * px, (z - K.MIN_Z) * px)

    def col(top):
        t = max(0.0, min(1.0, (top - 6) / 24))
        return (int(80 + 160 * t), int(140 - 60 * t), int(200 - 150 * t))

    for k, (plan, mm) in enumerate(((before, mb), (after, ma))):
        ox = k * (W + 30)
        for s in K.STREETS:
            r = K.street_rect(s)
            dr.rectangle([pt(r[0], r[1], ox), pt(r[2], r[3], ox)], fill=(232, 220, 196))
        for o in K.OPEN:
            if o[0] == "circle":
                a, b = pt(o[1] - o[3], o[2] - o[3], ox), pt(o[1] + o[3], o[2] + o[3], ox)
                dr.ellipse([a, b], outline=(170, 150, 120))
        for r in roofs_of(plan):
            x0, z0, x1, z1 = r["rect"]
            fill = (40, 40, 44) if r["kind"] == "landmark" else ((150, 90, 50) if r["kind"] == "bridge" else col(r["top"]))
            dr.rectangle([pt(x0, z0, ox), pt(x1, z1, ox)], fill=fill, outline=(30, 26, 24))
        run = mm.get("path") or []
        for a, b in zip(run, run[1:]):
            dr.line([pt(a[0], a[1], ox), pt(b[0], b[1], ox)], fill=(220, 30, 40), width=3)
        if getattr(plan, "race", None):
            rp = plan.race.get("path") or []
            for a, b in zip(rp, rp[1:]):
                dr.line([pt(a[0], a[1], ox), pt(b[0], b[1], ox)], fill=(255, 150, 0), width=2)
            for i, rg in enumerate(plan.race["rings"]):
                c = pt(rg[0], rg[2], ox)
                dr.ellipse([c[0] - 6, c[1] - 6, c[0] + 6, c[1] + 6], outline=(255, 140, 0), width=3)
                dr.text((c[0] + 7, c[1] - 7), str(i + 1), fill=(0, 0, 0))
        lines = [
            ("THE GAME'S PLAN" if k == 0 else f"GENERATED (seed {plan.seed})") + f"   NOTE {mm['note']}/10",
            f"roofs in one run {mm['network']:.0%}   without the 2nd jump {mm['flow']:.0%}   longest run {mm['run_length']:.0f}",
            (f"race: {plan.race['length']:.0f} studs of rings, {plan.race['flow']:.0%} of its jumps without the 2nd   " if getattr(plan, "race", None) else "")
            + f"way up {mm['access']:.0%}   built {mm['built']:.0%}   empty {mm['empty']:.0%}   doors on their street {mm['doors']:.0%}   skyline {mm['skyline']:.0%}   clashes {mm['clashes']}",
        ]
        for i, line in enumerate(lines):
            dr.text((ox + 8, H + 10 + i * 30), line, fill=(20, 20, 20))
    img.save(path)
    return path


def search(n=40):
    os.makedirs(OUT, exist_ok=True)
    base = current_plan()
    mb = score(base)
    best = None
    rows = []
    for seed in range(1, n + 1):
        alley = (0.2, 0.28, 0.36)[seed % 3]
        v = candidate(seed)
        m = score(v)
        rows.append((m["note"], seed, alley, m))
        if v.race and (best is None or m["note"] > best[0]):
            best = (m["note"], seed, v, m)
    rows.sort(reverse=True)
    print(f"the game's plan: {mb['note']}/10  " + json.dumps({k: (round(v, 3) if isinstance(v, float) else v) for k, v in mb.items() if k != 'path'}))
    for note, seed, alley, m in rows[:8]:
        print(f"seed {seed:3d} alley {alley:.2f}: {note}/10  " + json.dumps({k: (round(v, 3) if isinstance(v, float) else v) for k, v in m.items() if k != 'path'}))
    if best:
        sheet(base, best[2], mb, best[3], os.path.join(OUT, "planche_village.png"))
        json.dump(dict(seed=best[1], note=best[0], baseline=mb["note"]), open(os.path.join(OUT, "best.json"), "w"))
    return mb, best


def candidate(seed):
    """Candidate `seed`: its alleys' rhythm turns with the seed (a fifth, a quarter, a third of
    the gaps in a row are alleys)."""
    return Village(seed, alley_chance=(0.2, 0.28, 0.36)[seed % 3]).generate()


SEED_FILE = os.path.join(HERE, "SEED")


def chosen():
    """The village in the game: the candidate of the seed written in tools/village/SEED."""
    return candidate(int(open(SEED_FILE).read().split()[0]))


def write(seed):
    v = candidate(seed)
    m, mb = score(v), score(current_plan())
    if m["note"] <= mb["note"]:
        sys.exit(f"seed {seed}: {m['note']}/10 does not beat the game's plan ({mb['note']}/10): not written")
    path = os.path.join(GAME, "src", "Shared", "KonohaLayout.luau")
    with open(path, "w") as fh:
        fh.write(to_luau(v))
    with open(SEED_FILE, "w") as fh:
        fh.write(f"{seed}\n")
    os.makedirs(OUT, exist_ok=True)
    sheet(current_plan(), v, mb, m, os.path.join(OUT, "planche_village.png"))
    print(f"seed {seed}: {m['note']}/10 (the game's plan {mb['note']}/10) written to {path}; race {v.race['length']} base studs")
    return v, m


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "search"
    if cmd == "search":
        search(int(sys.argv[2]) if len(sys.argv) > 2 else 40)
    elif cmd == "write":
        write(int(sys.argv[2]))
    elif cmd == "score":
        print(json.dumps({k: v for k, v in score(current_plan()).items() if k != "path"}, indent=1))
