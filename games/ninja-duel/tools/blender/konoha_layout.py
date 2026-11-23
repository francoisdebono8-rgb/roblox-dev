#!/usr/bin/env python3
"""Konoha redone (19/11, plan-vrai-jeu § 4 ANIMATEUR): the village's PLAN, one source for three outputs.

    python3 tools/blender/konoha_layout.py OUT_DIR

  * src/Shared/KonohaLayout.luau  districts, streets, open places, buildings, props and the
    minimap's points of interest (Client minimap, DESIGN), in HubMap's base frame (before
    HubMap.Scale), origin HubMap.Origin, north = -Z (the Hokage faces), the gate at +Z.
  * OUT_DIR/konoha_plan_spec.json a greybox roblox-map spec at the game's scale (x HubMap.Scale),
    for tools/syphodev/konoha_prove.py (P11 empty space under 30 %, reachability, overlaps).
  * OUT_DIR/minimap.png           the minimap the layout draws, labels on.

Part I references the plan keeps (Naruto, first part; no faces, no logos):
  the Hokage Rock to the north over the village, the round Hokage Residence with the Academy at
  its foot; the great A-un gate to the south and the main street running from it to the centre;
  Ichiraku, a stand with a noren on the street; the colourful plaster blocks with round water
  tanks on their roofs and the tiled two-storey machiya; the Uchiha district walled off at the
  village's edge, along the Naka river, with the Naka shrine across it; the Hyuga compound, a
  walled courtyard of traditional halls; Training Ground Three (three posts, the memorial stone)
  on the forest's edge; the hospital; the chunin finals' stadium and the fenced Forest of Death
  outside the wall.

What the game already uses keeps its place (HubMap: spawns, masters, the proctor, the street
duels, the welcome trio): the new plan densifies around them; nothing to re-tune.

Houses are six reusable models, each 800 to 2 000 triangles (HOUSES below: the budget each one
is modelled to, after François validates the plan).
"""
import json
import math
import os
import random
import sys

SCALE = 1.3  # HubMap.Scale
HALF_X, MIN_Z, MAX_Z = 290, -262, 216

# --- the districts (minimap tint) -------------------------------------------------------------
DISTRICTS = [
    # id, name, x0, z0, x1, z1, colour (minimap)
    ("Rock", "THE HOKAGE ROCK", -290, -262, 290, -196, (120, 104, 88)),
    ("Civic", "THE HOKAGE'S QUARTER", -100, -196, 100, -40, (190, 120, 92)),
    ("Hyuga", "THE HYŪGA COMPOUND", -290, -196, -100, -40, (214, 206, 186)),
    ("Uchiha", "THE UCHIHA DISTRICT", 100, -232, 290, -30, (150, 92, 86)),
    ("Training", "TRAINING GROUND THREE", -290, -40, -60, 83, (118, 150, 92)),
    ("Centre", "THE PLAZA", -60, -40, 100, 48, (206, 182, 140)),
    ("Alleys", "THE BACK ALLEYS", 100, -30, 290, 48, (180, 150, 120)),
    ("Residences", "THE WEST RESIDENCES", -290, 83, -14, 216, (200, 170, 130)),
    ("TeaStreet", "THE TEA STREET", -60, 48, -14, 83, (214, 176, 128)),
    ("Main", "MAIN STREET", -14, 48, 14, 216, (224, 196, 150)),
    ("Market", "THE MARKET STREETS", 14, 48, 290, 216, (220, 164, 108)),
]

# --- the streets: axis-aligned segments (x0, z0, x1, z1, width) ------------------------------
STREETS = [
    ("MainStreet", "MAIN STREET", (0, 40), (0, 216), 28),
    ("Avenue", "THE AVENUE", (-200, -30), (100, -30), 16),
    ("HokageWay", "HOKAGE WAY", (-100, -115), (100, -115), 14),
    ("WestLane", "THE WEST LANE", (-70, -115), (-70, -30), 14),
    ("HyugaGate", "", (-104, -110), (-70, -110), 12),
    ("MarketLane", "THE MARKET LANE", (14, 56), (290, 56), 16),
    ("MarketNorth", "", (115, 56), (115, 216), 12),
    ("MarketEast", "", (205, 56), (205, 216), 12),
    ("MarketCross", "", (14, 150), (290, 150), 12),
    ("BackAlley", "THE BACK ALLEYS", (40, -3), (290, -3), 12),
    ("AlleyLink", "", (70, -30), (70, 56), 10),
    ("WestAvenue", "THE WEST AVENUE", (-200, 90), (-14, 90), 14),
    ("Residences", "THE RESIDENCES' LANE", (-290, 150), (-14, 150), 14),
    ("ResNorth", "", (-100, 90), (-100, 216), 12),
    ("ResWest", "", (-200, 90), (-200, 216), 12),
    ("UchihaGate", "", (70, -70), (186, -70), 12),
    ("UchihaStreet", "", (140, -200), (140, -30), 12),
    ("UchihaEast", "", (240, -200), (240, -40), 12),
    ("ShrineBridge", "", (170, -108), (226, -108), 10),
    ("TerraceWest", "", (-40, -196), (-40, -115), 12),
    ("TerraceEast", "", (40, -196), (40, -115), 12),
]

# --- places kept open (duels, squares, the training meadow) ----------------------------------
OPEN = [
    ("circle", 0, 12, 34, "the plaza (street duel r28)"),
    ("rect", -30, 120, 30, 210, "the gate square: the welcome trio, Legion's duel"),
    ("circle", -136, 10, 36, "Training Ground Three (Leaf's duel)"),
    ("rect", -190, -24, -96, 70, "the training meadow"),
    ("circle", -152, -104, 34, "the Hyuga courtyard (GentleFist's duel)"),
    ("circle", 165, -3, 24, "the back-alley courtyard"),
    ("circle", 115, 56, 24, "the market lane's crossing (street duel)"),
    ("circle", -160, 150, 22, "the residences' lane duel"),
    ("rect", -45, -100, 45, -40, "the exam hall (the proctor's floor)"),
    ("rect", 186, -232, 212, -40, "the Naka river"),
]

# --- the landmarks (hand placed): id, model, x, z, w, d, h, yaw --------------------------------
LANDMARKS = [
    ("HokageResidence", "hokage_residence", 0, -150, 44, 44, 40, 0),
    ("Hospital", "hospital", -66, -160, 36, 30, 24, 0),
    ("Archive", "academy_annex", 66, -160, 36, 30, 24, 0),
    ("ExamHallBack", "exam_hall", 0, -94, 90, 12, 26, 0),
    ("ExamHallWest", "exam_hall_wing", -41, -67, 8, 42, 18, 0),
    ("ExamHallEast", "exam_hall_wing", 41, -67, 8, 42, 18, 0),
    ("Ichiraku", "ichiraku", -28, 113, 16, 12, 9, 90),
    ("GreatGate", "great_gate", 0, 210, 48, 8, 50, 0),
    ("HyugaMainHall", "hyuga_hall", -152, -168, 60, 22, 14, 0),
    ("HyugaWestHall", "hyuga_hall", -212, -104, 18, 54, 12, 90),
    ("HyugaGatehouse", "hyuga_gate", -104, -128, 8, 20, 10, 90),
    ("UchihaPolice", "uchiha_police", 120, -50, 24, 18, 16, 0),
    ("NakaShrine", "naka_shrine", 255, -108, 26, 22, 16, 270),
    ("ShrineTorii", "torii", 178, -108, 4, 18, 15, 90),
    ("UchihaPier", "pier", 177, -60, 18, 12, 2, 0),
    ("WaterTower", "water_tower", 250, 110, 16, 16, 34, 0),
    ("MarketShop", "market_hall", 158, 76, 26, 14, 12, 0),
    ("MemorialStone", "memorial_stone", -170, 76, 4, 2, 6, 0),
    ("SwingTree", "academy_tree", -22, -14, 6, 6, 18, 0),
]
OUTSIDE = [  # backdrops beyond the wall: seen, never walked
    ("ForestOfDeath", "forest_of_death", -400, -60, 200, 260, 70, 0),
    ("Stadium", "stadium", 420, 40, 130, 130, 44, 0),
]

# --- the walls: id, x, z, w (along X), d (along Z), height ------------------------------------
# (DEV 23/11: 46, for the ANIMATEUR's towers, 28) The village wall was 42 tall: a walker on the tallest roof (an apartment, 24) jumps and leaps 21.6
# studs at the game's scale (16.6 here): 24 + 16.6 < 42, so nobody leaves over it. The clan walls
# (10) are meant to be run on, as in the anime.
WALLS = [
    ("WallW", -HALF_X - 1, (-232 + MAX_Z) / 2, 2, MAX_Z + 232, 46),
    ("WallE", HALF_X + 1, (-232 + MAX_Z) / 2, 2, MAX_Z + 232, 46),
    ("WallS1", (-HALF_X - 24) / 2, MAX_Z + 1, HALF_X - 24, 2, 46),
    ("WallS2", (HALF_X + 24) / 2, MAX_Z + 1, HALF_X - 24, 2, 46),
    ("UchihaWallW1", 101, (-196 - 76) / 2, 2, 196 - 76, 10),
    ("UchihaWallW2", 101, (-64 - 32) / 2, 2, 32, 10),
    ("UchihaWallS1", (102 + 134) / 2, -31, 32, 2, 10),
    ("UchihaWallS2", (146 + 290) / 2, -31, 144, 2, 10),
    ("HyugaWallN", -195, -190, 190, 2, 10),
    ("HyugaWallE1", -101, -167, 2, 44, 10),  # the gate between E1 and E2, at the gatehouse
    ("HyugaWallE2", -101, -71, 2, 60, 10),
    ("HyugaWallS", -195, -40, 188, 2, 10),
]

# --- the six houses (each a reusable model; budget in triangles) -----------------------------
HOUSES = {
    # model: (tris budget, wall top, w range, d range, what it is, the model's own w x d)
    # tools/blender/konoha_houses.py models them at (w, d, wall top); the builder scales X and Z
    # to each lot and keeps the height (19/11: heights are the models' measured wall tops).
    "small_house": (900, 7, (12, 16), (12, 16), "one floor, plaster, tiled roof, porch roof", (14, 14)),
    "machiya": (1400, 14, (14, 20), (14, 20), "two-storey timber townhouse, lattice front, lean-to eave", (17, 17)),
    "tank_house": (1800, 21, (14, 20), (14, 18), "ochre plaster block, three floors, round water tank on the roof", (17, 16)),
    "shop_house": (1500, 14, (16, 24), (14, 18), "shop below (counter, noren, awning, sign board), living above", (20, 16)),
    "apartment": (2000, 21, (20, 28), (14, 18), "three-floor walkway block, outside stair, two tanks", (24, 16)),
    "clan_house": (1600, 9, (18, 26), (14, 20), "hall on a stone base, engawa, shoji, hip roof", (22, 17)),
    # (22/11) never drawn by the MIX: the variety pass turns some lots into towers
    "tower_house": (2000, 28, (12, 20), (12, 18), "four-floor narrow block, balcony, tall sign, tank up high", (13, 13)),
}
MIX = {
    "Residences": [("machiya", 4), ("small_house", 3), ("tank_house", 3), ("apartment", 1)],
    "Market": [("shop_house", 5), ("tank_house", 3), ("apartment", 2), ("machiya", 1)],
    "Main": [("shop_house", 1)],
    "TeaStreet": [("shop_house", 3), ("machiya", 2)],
    "Alleys": [("tank_house", 3), ("apartment", 2), ("machiya", 2), ("small_house", 2)],
    "Centre": [("tank_house", 3), ("shop_house", 2), ("apartment", 1)],
    "Civic": [("tank_house", 2), ("apartment", 1)],
    "Uchiha": [("clan_house", 3), ("small_house", 2), ("machiya", 1)],
    "Hyuga": [("clan_house", 1)],
    "Training": [("small_house", 1)],
}
PROP_TRIS = {"lamp": 300, "tree": 2500, "stall": 600, "crate": 300, "bench": 300,
             "stone_lantern": 300, "post": 200, "barrel": 300, "fence": 300}

# The minimap's points of interest. `place` = a HubMap.Places id (same names the HUD shows);
# `master` = the kit met there; `tier` 1 = always labelled, 2 = labelled when zoomed in,
# 3 = an icon only. `far`: beyond the wall (an arrow at the map's edge).
POIS = [
    ("Gate", "THE GREAT GATE", 0, 200, "gate", 1, {"place": "Gate"}),
    ("Street", "MAIN STREET", 0, 120, "street", 2, {"place": "Street"}),
    ("Ichiraku", "ICHIRAKU RAMEN", -26, 112, "food", 1, {"place": "Ichiraku", "master": "Legion"}),
    ("Plaza", "THE PLAZA", 0, 12, "square", 1, {"place": "Plaza"}),
    ("Hall", "THE EXAM HALL", 0, -70, "duel", 1, {"place": "Hall", "master": "Sand"}),
    ("Residence", "THE HOKAGE RESIDENCE", 0, -150, "landmark", 1, {}),
    ("Faces", "THE HOKAGE FACES", 0, -214, "landmark", 1, {"place": "Faces", "master": "Flashstep"}),
    ("Hospital", "THE HOSPITAL", -66, -160, "landmark", 2, {}),
    ("Archive", "THE ARCHIVES", 66, -160, "landmark", 3, {}),
    ("Training", "TRAINING GROUND THREE", -132, 36, "training", 1, {"place": "Training", "master": "Leaf"}),
    ("Memorial", "THE MEMORIAL STONE", -170, 76, "landmark", 2, {"place": "Memorial", "master": "Copycat"}),
    ("Hyuga", "THE HYŪGA COMPOUND", -152, -104, "clan", 1, {"place": "Hyuga", "master": "GentleFist"}),
    ("Uchiha", "THE UCHIHA DISTRICT", 150, -90, "clan", 1, {"place": "Uchiha"}),
    ("Pier", "THE UCHIHA PIER", 176, -60, "master", 2, {"master": "Lion"}),
    ("Shrine", "THE NAKA SHRINE", 230, -108, "landmark", 2, {"master": "Mirage"}),
    ("Rooftops", "THE ROOFTOPS", 44, 122, "rooftops", 2, {"place": "Rooftops"}),
    ("Market", "THE MARKET STREETS", 160, 103, "shop", 1, {"place": "Market"}),
    ("MarketStall", "THE RYŌ MARKET", 158, 62, "shop", 2, {}),
    ("WaterTower", "THE WATER TOWER", 250, 110, "landmark", 3, {}),
    ("Residences", "THE WEST RESIDENCES", -170, 150, "district", 2, {"place": "Residences"}),
    ("Alleys", "THE BACK ALLEYS", 180, -3, "district", 2, {"place": "Alleys"}),
    ("ForestOfDeath", "THE FOREST OF DEATH", -300, -60, "far", 3, {"far": True}),
    ("Stadium", "THE CHŪNIN STADIUM", 290, 40, "far", 3, {"far": True}),
]

ROOF_DECKS = [  # the Rooftops: flat decks a walker reaches by ladders (high ground)
    (36, 108, 14, 14, 13), (52, 122, 14, 14, 16), (36, 136, 14, 14, 13), (60, 104, 12, 12, 10),
]


def street_rect(s, pad=0.0):
    (x0, z0), (x1, z1), w = s[2], s[3], s[4]
    h = w / 2 + pad
    return (min(x0, x1) - (h if x0 == x1 else 0), min(z0, z1) - (h if z0 == z1 else 0),
            max(x0, x1) + (h if x0 == x1 else 0), max(z0, z1) + (h if z0 == z1 else 0))


def rect_of(x, z, w, d, yaw):
    if int(yaw) % 180 == 90:
        w, d = d, w
    return (x - w / 2, z - d / 2, x + w / 2, z + d / 2)


def overlap(a, b, pad=0.0):
    return a[0] - pad < b[2] and b[0] - pad < a[2] and a[1] - pad < b[3] and b[1] - pad < a[3]


def rect_circle(r, cx, cz, rad):
    nx = min(max(cx, r[0]), r[2])
    nz = min(max(cz, r[1]), r[3])
    return (nx - cx) ** 2 + (nz - cz) ** 2 < rad * rad


def district_at(x, z):
    # the smallest district containing the point (Main inside Market's band, etc.)
    best = None
    for d in DISTRICTS:
        if d[2] <= x <= d[4] and d[3] <= z <= d[5]:
            area = (d[4] - d[2]) * (d[5] - d[3])
            if best is None or area < best[0]:
                best = (area, d[0])
    return best and best[1]


def inside_one_district(r):
    a = district_at(r[0] + .1, r[1] + .1)
    return a and all(district_at(x, z) == a for x, z in ((r[2] - .1, r[1] + .1), (r[0] + .1, r[3] - .1), (r[2] - .1, r[3] - .1)))


class Plan:
    def __init__(self, seed=19):
        self.rng = random.Random(seed)
        self.buildings = []  # dict(id, model, x, z, w, d, h, yaw, district, rect)
        self.props = []      # dict(kind, x, z, yaw, h)
        self.blocked = [street_rect(s, 1.0) for s in STREETS]
        for lm in LANDMARKS:
            self.add(lm[0], lm[1], *lm[2:], landmark=True)

    def free(self, r, gap=4.0):
        if r[0] < -HALF_X + 4 or r[2] > HALF_X - 4 or r[1] < -196 or r[3] > MAX_Z - 6:
            return False
        if any(overlap(r, b) for b in self.blocked):
            return False
        for o in OPEN:
            if o[0] == "circle" and rect_circle(r, o[1], o[2], o[3]):
                return False
            if o[0] == "rect" and overlap(r, o[1:5]):
                return False
        if any(overlap(r, b["rect"], gap) for b in self.buildings):
            return False
        for x, z, w, d, _ in ROOF_DECKS:
            if overlap(r, rect_of(x, z, w, d, 0), gap):
                return False
        # the Uchiha wall: a house stands wholly on one side
        return inside_one_district(r)

    def add(self, bid, model, x, z, w, d, h, yaw, landmark=False):
        r = rect_of(x, z, w, d, yaw)
        self.buildings.append(dict(id=bid, model=model, x=x, z=z, w=w, d=d, h=h, yaw=yaw,
                                   district=district_at(x, z), rect=r, landmark=landmark))

    def pick(self, district):
        mix = MIX.get(district) or [("small_house", 1)]
        tot = sum(n for _, n in mix)
        k = self.rng.uniform(0, tot)
        for m, n in mix:
            k -= n
            if k <= 0:
                return m
        return mix[-1][0]

    def house(self, model, x, z, yaw, gap=4.0):
        _, h, wr, dr, _, _ = HOUSES[model]
        w = round(self.rng.uniform(*wr))
        d = round(self.rng.uniform(*dr))
        r = rect_of(x, z, w, d, yaw)
        if not self.free(r, gap):
            return None
        self.rng.choice((0, 0, 2, -1))  # (kept: the validated plan's draw order) the model sets the height
        self.add(f"H{len(self.buildings) + 1}", model, x, z, w, d, h, yaw)
        return w

    def frontage(self):
        """Houses along both sides of every street, facing it."""
        for s in STREETS:
            (x0, z0), (x1, z1), wd = s[2], s[3], s[4]
            along_x = z0 == z1
            length = abs(x1 - x0) if along_x else abs(z1 - z0)
            for side in (-1, 1):
                t = 3.0
                while t < length - 3:
                    px = min(x0, x1) + t if along_x else x0
                    pz = z0 if along_x else min(z0, z1) + t
                    district = district_at(px + (0 if along_x else side * (wd / 2 + 9)),
                                           pz + (side * (wd / 2 + 9) if along_x else 0))
                    model = self.pick(district)
                    _, _, wr, dr, _, _ = HOUSES[model]
                    dd = (dr[0] + dr[1]) / 2
                    off = wd / 2 + 1.5 + dd / 2
                    # the door looks at the street: yaw 0 = the front faces +Z
                    if along_x:
                        hx, hz, yaw = px + wr[1] / 2, z0 + side * off, (0 if side < 0 else 180)
                    else:
                        hx, hz, yaw = x0 + side * off, pz + wr[1] / 2, (90 if side < 0 else 270)
                    placed = self.house(model, hx, hz, yaw)
                    t += (placed + self.rng.uniform(4.5, 6)) if placed else 3

    def backfill(self):
        """The blocks behind the frontage: more houses, alleys of 7+ studs kept between them."""
        pts = [(x, z) for x in range(-280, 281, 4) for z in range(-190, 210, 4)]
        self.rng.shuffle(pts)
        for x, z in pts:
            d = district_at(x, z)
            if d in (None, "Rock", "Training", "Main"):
                continue
            self.house(self.pick(d), x, z, self.rng.choice((0, 90, 180, 270)), gap=5.0)

    def props_pass(self):
        rng = self.rng
        # lamps along the streets, alternating sides
        for s in STREETS:
            (x0, z0), (x1, z1), wd = s[2], s[3], s[4]
            along_x = z0 == z1
            length = abs(x1 - x0) if along_x else abs(z1 - z0)
            t, side = 10.0, 1
            while t < length - 4:
                off = wd / 2 - 1.2
                x = (min(x0, x1) + t) if along_x else x0 + side * off
                z = z0 + side * off if along_x else (min(z0, z1) + t)
                self.prop("lamp", x, z, 0, 9)
                t += 22
                side = -side
        # market stalls and crates along the market lanes
        for s in STREETS:
            if s[0] not in ("MarketLane", "MarketNorth", "MarketEast", "MarketCross", "BackAlley"):
                continue
            (x0, z0), (x1, z1), wd = s[2], s[3], s[4]
            along_x = z0 == z1
            length = abs(x1 - x0) if along_x else abs(z1 - z0)
            t = 14.0
            while t < length - 6:
                side = rng.choice((-1, 1))
                off = wd / 2 - 2.6
                x = (min(x0, x1) + t) if along_x else x0 + side * off
                z = z0 + side * off if along_x else (min(z0, z1) + t)
                self.prop(rng.choice(("stall", "crate", "barrel")), x, z, 0, 4)
                t += rng.uniform(14, 22)
        # the forest's edge, the training meadow's ring, the plaza's trees
        for _ in range(900):
            x, z = rng.uniform(-286, -196), rng.uniform(-36, 80)
            if not self.near_prop(x, z, 9):
                self.prop("tree", x, z, rng.uniform(0, 360), rng.uniform(22, 34))
        for a in range(0, 360, 30):
            r = 48
            x, z = -142 + r * math.cos(math.radians(a)), 22 + r * .9 * math.sin(math.radians(a))
            if -190 < x < -62 and -36 < z < 80:
                self.prop("tree", x, z, a, 26)
        for x, z in ((-150, 16), (-143, 22), (-157, 22)):
            self.prop("post", x, z, 0, 5)
        for a in range(15, 360, 45):
            self.prop("tree", 38 * math.cos(math.radians(a)), 12 + 38 * math.sin(math.radians(a)), a, 18)
        for a in range(0, 360, 60):
            self.prop("bench", 20 * math.cos(math.radians(a)), 12 + 20 * math.sin(math.radians(a)), a, 1)
        # stone lanterns on the faces' terrace, reeds and rocks on the Naka's banks
        for x in range(-120, 121, 24):
            self.prop("stone_lantern", x, -200, 0, 4, y=24)
        for z in range(-226, -44, 14):
            self.prop("stone_lantern", 183, z, 0, 3)
            self.prop("stone_lantern", 215, z + 7, 0, 3)
        # the Hyuga courtyard: a ring of stone lanterns and the bonsai
        for a in range(0, 360, 40):
            self.prop("stone_lantern", -152 + 40 * math.cos(math.radians(a)), -104 + 40 * math.sin(math.radians(a)), a, 4)
        # the gate square, the exam floor and the courtyards: their edges dressed, their centres kept clear
        for x, z in ((-24, 128), (24, 128), (-24, 176), (24, 176), (-24, 200), (24, 200), (0, 108)):
            self.prop("barrel", x, z, 0, 3)
        for x, z in ((-30, -50), (30, -50), (-30, -86), (30, -86), (0, -60)):
            self.prop("post", x, z, 0, 6)
        for x, z, n in ((165, -3, 26), (115, 56, 26), (-160, 150, 24)):
            for a in range(0, 360, 45):
                px, pz = x + n * math.cos(math.radians(a)), z + n * math.sin(math.radians(a))
                if not any(overlap((px - 1, pz - 1, px + 1, pz + 1), b["rect"]) for b in self.buildings):
                    self.prop("crate", px, pz, a, 3)
        # the training meadow: targets, logs, the stream's stones
        for x, z in ((-110, -12), (-170, -12), (-112, 52), (-176, 48), (-136, 60), (-136, -18)):
            self.prop("fence", x, z, 0, 3)
        # backyards: one crate or barrel in every gap a house left
        for b in list(self.buildings):
            if b["landmark"]:
                continue
            r = b["rect"]
            x, z = r[2] + 2.5, (r[1] + r[3]) / 2
            if self.free_prop(x, z):
                self.prop(rng.choice(("crate", "barrel")), x, z, 0, 3)

    def keep_points(self):
        """(22/11) Places the game already uses on or by a roof (Shared/Solo's race rings and start,
        HubMap's spots): the variety pass leaves the buildings there as they are."""
        import re
        root = os.path.normpath(os.path.join(HERE, os.pardir, os.pardir, "src", "Shared"))
        pts = []
        try:
            solo = open(os.path.join(root, "Solo.luau")).read()
            race = solo[solo.index("Solo.Race="):solo.index("Solo.Race=") + 2000]
            pts += [(float(a), float(c)) for a, b, c in re.findall(r"\{(-?[\d.]+),(-?[\d.]+),(-?[\d.]+)\}", race)]
        except (OSError, ValueError):
            pass
        try:
            hm = open(os.path.join(root, "HubMap.luau")).read()
            pts += [(float(a), float(c)) for a, b, c in re.findall(r"at=Vector3\.new\((-?[\d.]+),(-?[\d.]+),(-?[\d.]+)\)", hm)]
        except OSError:
            pass
        return pts

    def variety_pass(self):
        """(22/11, François: « l'arrangement de l'espace et la différence entre les bâtiments n'est
        pas assez forte, le village est trop lisse ») After the validated plan is drawn (its draw
        order untouched): a few lots become tall towers that break the skyline, one per stretch
        of village, never where the game already uses a roof; the gaps between houses get
        pocket gardens (a tree, a stone lantern), so the blocks are not wall after wall."""
        rng = random.Random(2211)
        keep = self.keep_points()
        # the towers wait for Server/Hub to know their stand-in (Hub.LAYOUT_STANDIN: every house of
        # the plan has the old village's house of its kind under it, tests/Hub.spec); the DEV adds
        # it, this pass is re-run, the towers appear
        hub = os.path.normpath(os.path.join(HERE, os.pardir, os.pardir, "src", "Server", "Hub.luau"))
        try:
            towers_on = "tower_house=" in open(hub).read()
        except OSError:
            towers_on = False
        cands = [b for b in self.buildings if not b["landmark"] and b["model"] in ("tank_house", "apartment", "machiya", "shop_house")
                 and b["district"] in ("Market", "Centre", "Alleys", "Residences", "Civic", "TeaStreet")]
        cands.sort(key=lambda b: (b["x"], b["z"]))
        rng.shuffle(cands)
        towers = []
        for b in cands:
            if not towers_on or len(towers) >= 14:
                break
            if max(b["w"], b["d"]) > 20:
                continue
            if any((b["x"] - px) ** 2 + (b["z"] - pz) ** 2 < 34 ** 2 for px, pz in keep):
                continue
            if any((b["x"] - t["x"]) ** 2 + (b["z"] - t["z"]) ** 2 < 55 ** 2 for t in towers):
                continue
            b["model"] = "tower_house"
            b["h"] = HOUSES["tower_house"][1]
            towers.append(b)
        gardens = 0
        pts = [(x, z) for x in range(-280, 281, 6) for z in range(-190, 210, 6)]
        rng.shuffle(pts)
        for x, z in pts:
            if gardens >= 70:
                break
            d = district_at(x, z)
            if d not in ("Residences", "Alleys", "Market", "Centre", "TeaStreet", "Uchiha", "Civic"):
                continue
            r = (x - 5, z - 5, x + 5, z + 5)
            if not self.free(r, gap=1.5) or self.near_prop(x, z, 8):
                continue
            if any((x - px) ** 2 + (z - pz) ** 2 < 14 ** 2 for px, pz in keep):
                continue
            self.prop("tree", x, z, rng.uniform(0, 360), round(rng.uniform(12, 17), 1))
            if rng.random() < .45 and self.free_prop(x + 4, z + 3):
                self.prop("stone_lantern", x + 4, z + 3, 0, 3)
            gardens += 1
        self.variety = (len(towers), gardens)

    def near_prop(self, x, z, d):
        return any((p["x"] - x) ** 2 + (p["z"] - z) ** 2 < d * d for p in self.props)

    def free_prop(self, x, z):
        r = (x - 1.5, z - 1.5, x + 1.5, z + 1.5)
        return not any(overlap(r, b) for b in self.blocked) and not any(overlap(r, b["rect"], 1) for b in self.buildings)

    def prop(self, kind, x, z, yaw, h, y=0):
        self.props.append(dict(kind=kind, x=round(x, 1), z=round(z, 1), yaw=round(yaw) % 360, h=h, y=y))


# ------------------------------------------------------------------------------------------------
def to_luau(plan):
    f = lambda v: (f"{v:.1f}".rstrip("0").rstrip(".") if isinstance(v, float) else str(v))
    L = []
    L.append("--!strict")
    L.append("-- GENERATED by tools/blender/konoha_layout.py: do not edit by hand (edit the generator).")
    L.append("-- (19/11, plan-vrai-jeu § 4 ANIMATEUR) Konoha redone: the plan of the village, for the")
    L.append("-- builder (Server/Hub) and the minimap (DESIGN). HubMap's base frame: before HubMap.Scale,")
    L.append("-- relative to HubMap.Origin; north = -Z (the Hokage faces), the great gate at +Z.")
    L.append("local M={}")
    L.append(f"M.HalfX={HALF_X};M.MinZ={MIN_Z};M.MaxZ={MAX_Z}")
    L.append(f"M.Scale={SCALE} -- = HubMap.Scale (the builder multiplies every position and size)")
    L.append("-- Districts: rectangles (x0,z0,x1,z1) and their minimap tint; the smallest one wins.")
    L.append("M.Districts={")
    for d in DISTRICTS:
        L.append(f'\t{{id="{d[0]}",name="{d[1]}",x0={d[2]},z0={d[3]},x1={d[4]},z1={d[5]},color=Color3.fromRGB({d[6][0]},{d[6][1]},{d[6][2]})}},')
    L.append("}")
    L.append("-- Streets: from `a` to `b` (base studs), `width` across.")
    L.append("M.Streets={")
    for s in STREETS:
        L.append(f'\t{{id="{s[0]}",name="{s[1]}",a=Vector2.new({s[2][0]},{s[2][1]}),b=Vector2.new({s[3][0]},{s[3][1]}),width={s[4]}}},')
    L.append("}")
    L.append("-- Places kept open (duels, squares): nothing is built inside.")
    L.append("M.Open={")
    for o in OPEN:
        if o[0] == "circle":
            L.append(f'\t{{shape="circle",at=Vector2.new({o[1]},{o[2]}),radius={o[3]},why="{o[4]}"}},')
        else:
            L.append(f'\t{{shape="rect",x0={o[1]},z0={o[2]},x1={o[3]},z1={o[4]},why="{o[5]}"}},')
    L.append("}")
    L.append("-- The house models: triangle budget (800 to 2 000), base height, what each is.")
    L.append("M.Houses={")
    used = {b["model"] for b in plan.buildings}
    for k, v in HOUSES.items():
        if k == "tower_house" and k not in used:   # (22/11) listed once the plan has towers
            continue
        L.append(f'\t{k}={{tris={v[0]},height={v[1]},width={v[5][0]},depth={v[5][1]},what="{v[4]}"}},')
    L.append("}")
    L.append("-- Buildings: {model, x, z, w, d, h, yaw, district, landmark id or nil}. yaw 0: the door")
    L.append("-- looks at +Z; w along the building's own X. Footprint and height in base studs.")
    L.append("M.Buildings={")
    for b in plan.buildings:
        lid = f'"{b["id"]}"' if b["landmark"] else "nil"
        L.append(f'\t{{"{b["model"]}",{f(b["x"])},{f(b["z"])},{b["w"]},{b["d"]},{b["h"]},{b["yaw"]},"{b["district"]}",{lid}}},')
    L.append("}")
    L.append("-- Backdrops beyond the wall: seen from the roofs, never walked.")
    L.append("M.Outside={")
    for o in OUTSIDE:
        L.append(f'\t{{"{o[1]}",{o[2]},{o[3]},{o[4]},{o[5]},{o[6]},{o[7]},"{o[0]}"}},')
    L.append("}")
    L.append("-- Walls: {id, x, z, w, d, height} (the village wall, 46: higher than any roof, towers included, plus a leap).")
    L.append("M.Walls={")
    for wl in WALLS:
        L.append(f'\t{{"{wl[0]}",{f(float(wl[1]))},{f(float(wl[2]))},{wl[3]},{wl[4]},{wl[5]}}},')
    L.append("}")
    L.append("-- Rooftop decks (the Rooftops): x, z, w, d, top height; ladders on their street side.")
    L.append("M.RoofDecks={")
    for r in ROOF_DECKS:
        L.append("\t{" + ",".join(str(v) for v in r) + "},")
    L.append("}")
    L.append("-- Props: {kind, x, z, yaw, height, y}.")
    L.append("M.Props={")
    for p in plan.props:
        L.append(f'\t{{"{p["kind"]}",{f(p["x"])},{f(p["z"])},{p["yaw"]},{p["h"]},{p["y"]}}},')
    L.append("}")
    L.append("-- The minimap's points of interest. `place`: the HubMap.Places id (the name the HUD shows);")
    L.append("-- `master`: the kit met there; `tier` 1 always labelled, 2 when zoomed in, 3 icon only;")
    L.append("-- `far`: beyond the wall (an arrow on the map's edge).")
    L.append("M.Pois={")
    for p in POIS:
        extra = "".join(f',{k}="{v}"' if isinstance(v, str) else f',{k}={str(v).lower()}' for k, v in p[6].items())
        L.append(f'\t{{id="{p[0]}",name="{p[1]}",at=Vector2.new({p[2]},{p[3]}),icon="{p[4]}",tier={p[5]}{extra}}},')
    L.append("}")
    L.append("")
    L.append("-- A base position (x, z) on the minimap: 0..1 across (west to east), 0..1 down (north to south).")
    L.append("function M.toMap(x:number,z:number):Vector2")
    L.append("\treturn Vector2.new((x+M.HalfX)/(2*M.HalfX),(z-M.MinZ)/(M.MaxZ-M.MinZ))")
    L.append("end")
    L.append("-- The district a base position stands in (the smallest rectangle holding it).")
    L.append("function M.districtAt(x:number,z:number)")
    L.append("\tlocal best,area=nil,math.huge")
    L.append("\tfor _,d in M.Districts do")
    L.append("\t\tif x>=d.x0 and x<=d.x1 and z>=d.z0 and z<=d.z1 then")
    L.append("\t\t\tlocal a=(d.x1-d.x0)*(d.z1-d.z0)")
    L.append("\t\t\tif a<area then best,area=d,a end")
    L.append("\t\tend")
    L.append("\tend")
    L.append("\treturn best")
    L.append("end")
    L.append("-- The points of interest a minimap shows at a zoom tier (1 = whole village).")
    L.append("function M.poisFor(tier:number)")
    L.append("\tlocal out={}")
    L.append("\tfor _,p in M.Pois do if p.tier<=tier then table.insert(out,p) end end")
    L.append("\treturn out")
    L.append("end")
    L.append("return M")
    return "\n".join(L) + "\n"


# ------------------------------------------------------------------------------------------------
def to_spec(plan):
    s = SCALE
    parts = []

    def part(pid, roles, x, y, z, w, h, d, yaw=0, decor=False, color=None, **kw):
        p = {"id": pid, "roles": roles, "pos": [round(x * s, 2), round(y * s, 2), round(z * s, 2)],
             "size": [round(w * s, 2), round(h * s, 2), round(d * s, 2)]}
        if yaw:
            p["yaw"] = yaw
        if decor:
            p["decor"] = True
        if color:
            p["color"] = color
        p.update(kw)
        parts.append(p)

    part("Ground", ["arena_floor"], 0, -1, (MIN_Z + MAX_Z) / 2, 2 * HALF_X, 2, MAX_Z - MIN_Z, color=[170, 150, 110])
    part("Cliff", ["wall"], 0, 45, -247, 2 * HALF_X, 90, 30, color=[120, 104, 88])
    part("Terrace", ["high_ground"], 0, 12, -214, 280, 24, 36, color=[150, 130, 104])
    for i, x in enumerate((-40, 40)):
        part(f"TerraceStair{i + 1}", ["core_access"], x, 12, -183, 12, 24, 26, ramp="+z", yaw=180, color=[150, 130, 104])
    for wid, x, z, w, d, h in WALLS:
        part(wid, ["wall"], x, h / 2, z, w, h, d)
    # river: a sunken bed (the walker wades, -1.5), its banks dressed
    for b in plan.buildings:
        roles = ["landmark"] if b["landmark"] else ["cover"]
        w, d = (b["d"], b["w"]) if int(b["yaw"]) % 180 == 90 else (b["w"], b["d"])
        if b["model"] in ("torii",):
            part(b["id"], roles, b["x"], b["h"] / 2, b["z"], w, b["h"], d, decor=True, solid=False)
            continue
        if b["model"] == "pier":
            part(b["id"], ["high_ground"], b["x"], .6, b["z"], w, 1.2, d)
            continue
        part(b["id"] if b["landmark"] else f"{b['model']}_{b['id']}", roles, b["x"], b["h"] / 2, b["z"], w, b["h"], d,
             decor=not b["landmark"], mesh=None if b["landmark"] else b["model"])
    for i, (x, z, w, d, top) in enumerate(ROOF_DECKS):
        part(f"Rooftop{i + 1}", ["high_ground"], x, top / 2, z, w, top, d)
        part(f"Ladder{i + 1}", ["core_access"], x - w / 2 - 2, top / 2, z, 6, top, 4, ramp="+z", yaw=90)
    for i, p in enumerate(plan.props):
        size = {"lamp": (1, 9, 1), "tree": (8, 26, 8), "stall": (6, 4, 4), "crate": (3, 3, 3), "barrel": (2.5, 3, 2.5),
                "bench": (5, 1.4, 1.6), "stone_lantern": (2, 4, 2), "post": (1.6, 5, 1.6), "fence": (8, 3, 1)}[p["kind"]]
        h = p["h"] if p["kind"] in ("tree",) else size[1]
        part(f"{p['kind']}_{i + 1}", ["cover"], p["x"], p["y"] + h / 2, p["z"], size[0] if p["kind"] != "tree" else 3, h,
             size[2] if p["kind"] != "tree" else 3, decor=True, mesh=p["kind"])
    for p in parts:
        if p.get("mesh") is None:
            p.pop("mesh", None)
    meshes = {k: {"tris": v[0], "kind": "house", "trisBudget": 2000} for k, v in HOUSES.items()}
    meshes.update({k: {"tris": v, "kind": k} for k, v in PROP_TRIS.items()})
    return {
        "name": "KonohaPlan",
        "profile": "tools/syphodev/konoha_profile.json",
        "ground_is_parts": "Konoha is built from parts by Server/Hub (DEC-038); this is its plan, greyboxed",
        "parts_are_deliberate": "the plan of the village: each house box is one of six reusable models (800-2000 tris)",
        "open_edges": "the village wall rings it; the north is the Hokage Rock",
        "volume": {"bounds": [[-HALF_X * s - 20, -40, MIN_Z * s - 20], [HALF_X * s + 20, 140, MAX_Z * s + 20]],
                   "killPlane": -40, "ringOutOffset": 10, "lift": 0},
        "parts": parts,
        "spawns": [[0, 0, 192 * s]],
        # a ninja's village: its inner walls, roofs and stairs are meant to be run on (not the outer wall)
        "intent": {"reachable": ["Ground", "Terrace", "TerraceStair*", "Rooftop*", "Ladder*", "UchihaPier",
                                 "UchihaWall*", "HyugaWall*"] + [lm[0] for lm in LANDMARKS if lm[6] <= 30
                                                                and not lm[0].startswith("ExamHall") and lm[0] != "SwingTree"]},
        "meshes": meshes,
        "budget": {"reason": "houses modelled at 800-2000 triangles (plan-vrai-jeu § 4)"},
    }


# ------------------------------------------------------------------------------------------------
def minimap_png(plan, path, px=4):
    from PIL import Image, ImageDraw, ImageFont
    W, H = 2 * HALF_X * px // 2, (MAX_Z - MIN_Z) * px // 2
    k = px / 2
    img = Image.new("RGB", (W + 1, H + 1), (40, 52, 36))
    dr = ImageDraw.Draw(img)
    X = lambda x: (x + HALF_X) * k
    Z = lambda z: (z - MIN_Z) * k
    for d in DISTRICTS:
        dr.rectangle([X(d[2]), Z(d[3]), X(d[4]), Z(d[5])], fill=tuple(int(c * .55) for c in d[6]))
    for o in OPEN:
        if o[0] == "rect" and "river" in o[5]:
            dr.rectangle([X(o[1]), Z(o[2]), X(o[3]), Z(o[4])], fill=(70, 120, 150))
    for s in STREETS:
        r = street_rect(s)
        dr.rectangle([X(r[0]), Z(r[1]), X(r[2]), Z(r[3])], fill=(196, 178, 140))
    for o in OPEN:
        if o[0] == "circle":
            dr.ellipse([X(o[1] - o[3]), Z(o[2] - o[3]), X(o[1] + o[3]), Z(o[2] + o[3])], fill=(210, 190, 150))
    for p in plan.props:
        if p["kind"] == "tree":
            dr.ellipse([X(p["x"] - 4), Z(p["z"] - 4), X(p["x"] + 4), Z(p["z"] + 4)], fill=(52, 92, 48))
    for b in plan.buildings:
        r = b["rect"]
        col = (150, 60, 50) if b["landmark"] else (226, 214, 196)
        if b["model"] in ("tank_house", "apartment"):
            col = (200, 210, 214)
        if b["model"] == "shop_house":
            col = (236, 180, 120)
        if b["model"] == "clan_house":
            col = (120, 96, 80)
        dr.rectangle([X(r[0]), Z(r[1]), X(r[2]), Z(r[3])], fill=col, outline=(30, 26, 24))
    for x, z, w, d, _ in ROOF_DECKS:
        dr.rectangle([X(x - w / 2), Z(z - d / 2), X(x + w / 2), Z(z + d / 2)], fill=(90, 130, 170), outline=(20, 20, 30))
    dr.rectangle([X(-140), Z(-232), X(140), Z(-196)], fill=(150, 130, 104))
    for hx in (-96, -32, 32, 96):  # HubMap.Base.Heads
        dr.ellipse([X(hx - 22), Z(-246), X(hx + 22), Z(-226)], fill=(176, 160, 136), outline=(60, 50, 40))
    for wid, x, z, w, d, h in WALLS:
        dr.rectangle([X(x - w / 2 - 1), Z(z - d / 2 - 1), X(x + w / 2 + 1), Z(z + d / 2 + 1)], fill=(36, 30, 28))
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 15)
        small = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 11)
    except OSError:
        font = small = ImageFont.load_default()
    for p in POIS:
        x, z = X(max(-HALF_X + 8, min(HALF_X - 8, p[2]))), Z(p[3])
        c = (255, 210, 60) if p[6].get("master") else (255, 255, 255)
        dr.ellipse([x - 6, z - 6, x + 6, z + 6], fill=c, outline=(0, 0, 0), width=2)
        f = font if p[5] == 1 else small
        tw = dr.textlength(p[1], font=f)
        tx = min(max(4, x - tw / 2), W - tw - 4)
        dr.text((tx, z + 8), p[1], font=f, fill=c, stroke_width=3, stroke_fill=(0, 0, 0))
    img.save(path)


def board_png(plan, mini_path, report_path, path):
    """The plan to validate: the minimap, the cells the prover finds bare (approximated here, red),
    and the numbers (the prover's, read from its report)."""
    from PIL import Image, ImageDraw, ImageFont
    mini = Image.open(mini_path).convert("RGB")
    k = mini.width / (2 * HALF_X)
    ov = Image.new("RGBA", mini.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(ov)
    interest = [(b["x"], b["z"]) for b in plan.buildings] + [(q["x"], q["z"]) for q in plan.props] + [(r[0], r[1]) for r in ROOF_DECKS]
    cell, reach = 36 / SCALE, 26 / SCALE
    bare = total = 0
    zz = -196.0
    while zz < MAX_Z:
        xx = -HALF_X
        while xx < HALF_X:
            cx, cz = xx + cell / 2, zz + cell / 2
            if not any(b["rect"][0] < cx < b["rect"][2] and b["rect"][1] < cz < b["rect"][3] for b in plan.buildings):
                total += 1
                if not any((ix - cx) ** 2 + (iz - cz) ** 2 < reach * reach for ix, iz in interest):
                    bare += 1
                    od.rectangle([(xx + HALF_X) * k, (zz - MIN_Z) * k, (xx + cell + HALF_X) * k, (zz + cell - MIN_Z) * k],
                                 fill=(230, 40, 30, 90), outline=(230, 40, 30, 200))
            xx += cell
        zz += cell
    mini = Image.alpha_composite(mini.convert("RGBA"), ov).convert("RGB")
    rep = json.load(open(report_path))
    checks = {c["id"]: c for c in rep["checks"]}
    W = mini.width + 700
    img = Image.new("RGB", (W, max(mini.height, 960)), (22, 22, 26))
    img.paste(mini, (0, 0))
    dr = ImageDraw.Draw(img)
    try:
        big = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 26)
        mid = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
        sm = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 14)
    except OSError:
        big = mid = sm = ImageFont.load_default()
    x, y = mini.width + 24, 20
    dr.text((x, y), "KONOHA - LE PLAN A VALIDER", font=big, fill=(255, 220, 120)); y += 44
    houses = [b for b in plan.buildings if not b["landmark"]]
    lines = [
        (mid, f"Prouveur : {rep.get('result')}  (konoha_prove.py, res 4)", (140, 230, 140)),
        (sm, "Vide (P11) : " + checks["P11"]["detail"].split(" have")[0].replace("of", "de").replace("sampled cells", "cases") + " sans rien à 26 studs (budget 22 %)", (230, 230, 230)),
        (sm, "  aujourd'hui : 64 % ; objectif < 30 %", (180, 180, 180)),
        (sm, "Accès (P3) : " + checks["P3"]["status"] + ", chaque surface atteignable comme déclaré", (230, 230, 230)),
        (sm, "Budget (P21) : " + checks["P21"]["status"] + ", " + checks["P21"]["detail"].split(", ")[2], (230, 230, 230)),
        (sm, f"Bâti au sol : {len(houses)} maisons, {len(plan.buildings) - len(houses)} lieux, {len(plan.props)} objets", (230, 230, 230)),
        (sm, f"Rouge (approx.) : {bare} cases nues sur {total}", (240, 120, 110)),
        (mid, "", None),
        (mid, "Six maisons réutilisées (triangles)", (255, 220, 120)),
    ]
    for m, (t, h, wr, dr_, what, _) in HOUSES.items():
        n = sum(1 for b in houses if b["model"] == m)
        lines.append((sm, f"  {m} x{n} : {t} - {what}", (230, 230, 230)))
    lines += [
        (mid, "", None),
        (mid, "Repères Naruto (1re partie)", (255, 220, 120)),
        (sm, "  Rocher des Hokage au nord, résidence ronde à ses pieds", (230, 230, 230)),
        (sm, "  grande porte au sud, rue principale jusqu'à la place", (230, 230, 230)),
        (sm, "  Ichiraku sur la rue ; maisons-blocs à citerne ronde", (230, 230, 230)),
        (sm, "  quartier Uchiha muré au bord, rivière Naka, sanctuaire", (230, 230, 230)),
        (sm, "  domaine Hyuga : cour entourée de halls, mur et porte", (230, 230, 230)),
        (sm, "  terrain 3 : trois poteaux, stèle, lisière de forêt", (230, 230, 230)),
        (sm, "  hôpital ; stade et Forêt de la mort hors du mur", (230, 230, 230)),
        (mid, "", None),
        (mid, "Gardé tel quel (HubMap)", (255, 220, 120)),
        (sm, "  spawns, maîtres, examinateur, duels de rue, trio", (230, 230, 230)),
        (sm, "  d'accueil : aucun n'est dans un bâtiment", (230, 230, 230)),
        (mid, "", None),
        (sm, "Points jaunes : un maître est là (minicarte).", (255, 210, 60)),
    ]
    for f_, t, c in lines:
        if c:
            dr.text((x, y), t, font=f_, fill=c)
        y += 24 if f_ is not sm else 21
    img.save(path)


HERE = os.path.dirname(os.path.abspath(__file__))
OUT = "."

if __name__ == "__main__":
    OUT = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(OUT, exist_ok=True)
    # (DEV 23/11) the houses between the landmarks are generated for the run over the roofs
    # (tools/village/konoha_village.py, its chosen seed in tools/village/SEED): this command
    # writes that same village, so the two tools never undo each other. This file stays the
    # fixed Konoha (districts, streets, open places, landmarks, places of interest).
    sys.path.insert(0, os.path.normpath(os.path.join(HERE, os.pardir, "village")))
    import konoha_village
    plan = konoha_village.chosen()
    # (DEV, integration 19/11) the game's folder as two parent steps, not a
    # relative path string: tools/check_architecture.py reads such a string as
    # a reference to the whole folder, Motion Lab included, and failed.
    root = os.path.normpath(os.path.join(HERE, os.pardir, os.pardir))
    with open(os.path.join(root, "src/Shared/KonohaLayout.luau"), "w") as fh:
        fh.write(konoha_village.to_luau(plan))
    with open(os.path.join(OUT, "konoha_plan_spec.json"), "w") as fh:
        json.dump(to_spec(plan), fh, indent=0)
    minimap_png(plan, os.path.join(OUT, "minimap.png"))
    if os.path.exists(os.path.join(OUT, "report.json")):  # after konoha_prove.py
        board_png(plan, os.path.join(OUT, "minimap.png"), os.path.join(OUT, "report.json"), os.path.join(OUT, "plan_a_valider.png"))
    houses = [b for b in plan.buildings if not b["landmark"]]
    by = {}
    for b in houses:
        by[b["model"]] = by.get(b["model"], 0) + 1
    built = sum((b["rect"][2] - b["rect"][0]) * (b["rect"][3] - b["rect"][1]) for b in plan.buildings)
    print(f"{len(houses)} houses {by}, {len(plan.buildings) - len(houses)} landmarks, {len(plan.props)} props; "
          f"built footprint {built / (2 * HALF_X * (MAX_Z + 196)):.0%} of the village below the rock; "
          f"variety: {plan.variety[0]} towers, {plan.variety[1]} pocket gardens")
