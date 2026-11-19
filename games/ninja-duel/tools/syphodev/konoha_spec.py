#!/usr/bin/env python3
"""Konoha as a roblox-map spec, for SyphoDev's prover (.claude/skills/roblox-map/scripts/prove.py).

    lune run tools/syphodev/konoha_dump.luau work/map/konoha.json
    python3 tools/syphodev/konoha_spec.py work/map/konoha.json work/map/konoha_spec.json
    python3 ../../.claude/skills/roblox-map/scripts/prove.py work/map/konoha_spec.json --res 4

The village is the one the game builds (Server/Hub.build at its real scale). Geometry:
  * upright parts (axis-aligned or turned about Y) are exact boxes, WedgeParts exact ramps;
  * a pitched roof slab (turned about X or Z) becomes the ramp of its bounding box, rising from
    the eave to the ridge along its slope (what a player standing on it walks on);
  * ladders (TrussPart) become steep ramps: a truss is climbable on Roblox;
  * the lake is its Terrain block (a water body).
Roles come from the part's name (Ground: floor; roofs, balconies, rooftops: high ground; walls,
fences, faces: walls; trees, lamps, crates...: decor - real for rays, never a destination).
The movement profile is tools/syphodev/konoha_profile.json (the game's own numbers).
"""
import json
import math
import sys

FLOOR = {"Ground", "LakeBed"}
HIGH = {"Roof", "WedgePart", "GateRoof", "StandRoof", "Balcony", "Rooftop", "Terrace", "RoofDeck"}
WALL = {"Walls", "Wall", "Fence", "Edge", "Railing", "TerraceRail", "Face", "GatePillar", "GatePost",
        "HallPillar", "GateBeam", "StatueSleeve"}
ACCESS = {"Stair", "Step", "Ladder"}


def yaw_of(look):
    # Roblox: yaw 0 looks -Z; the spec's yaw turns the part about +Y (degrees).
    return math.degrees(math.atan2(-look[0], -look[2])) % 360


def roles_for(p):
    n = p["name"]
    if n in FLOOR:
        return ["arena_floor"], False
    if n in HIGH or n.endswith("Roof"):
        return ["high_ground"], False
    if n in WALL:
        return ["wall"], False
    if n in ACCESS:
        return ["core_access"], False
    return ["cover"], True


def convert(dump):
    parts, reachable, seen = [], [], {}
    for p in dump["parts"]:
        if not p["collide"]:
            continue
        roles, decor = roles_for(p)
        seen[p["name"]] = seen.get(p["name"], 0) + 1
        pid = f"{p['name']}_{seen[p['name']]}"
        up, look = p["up"], p["look"]
        sx, sy, sz = p["size"]
        part = {"id": pid, "roles": roles, "pos": p["pos"], "color": p["color"], "material": p["material"]}
        if decor:
            part["decor"] = True
        if abs(up[1] - 1) < 1e-3:  # upright
            part["size"] = [sx, sy, sz]
            part["yaw"] = round(yaw_of(look), 3)
            if p["class"] == "WedgePart":
                part["ramp"] = "+z"  # a WedgePart rises along its own local +Z... toward its back: -LookVector
                part["yaw"] = round((yaw_of(look) + 180) % 360, 3)
            elif p["class"] == "TrussPart":
                part["ramp"] = "+z"
        else:
            # A pitched slab: the ramp of its bounding box along the slope. The slope's
            # horizontal direction is the up vector's horizontal part (the roof rises against it).
            hx, hz = up[0], up[2]
            tilt = math.degrees(math.acos(max(-1, min(1, up[1]))))
            # bounding box in the slope's frame
            a = math.radians(tilt)
            along = sz * math.cos(a) + sy * math.sin(a)
            height = sz * math.sin(a) + sy * math.cos(a)
            across = sx
            # Which local axis carries the slope: the one that is no longer horizontal.
            # Tilted about Z (the Hyuga roofs), LookVector stays flat and RightVector
            # (look x up) climbs; tilted about X, it is the other way round.
            right_y = look[2] * up[0] - look[0] * up[2]
            if abs(right_y) > abs(look[1]):  # the slope runs along local X
                along, across = sx * math.cos(a) + sy * math.sin(a), sz
                height = sx * math.sin(a) + sy * math.cos(a)
            # the surface rises toward -(up's horizontal part)
            yaw = math.degrees(math.atan2(hx, hz)) % 360  # +Z of the ramp points down-slope... flipped below
            part["size"] = [round(across, 3), round(height, 3), round(along, 3)]
            part["yaw"] = round((yaw + 180) % 360, 3)
            part["ramp"] = "+z"
        if roles == ["high_ground"]:
            reachable.append(pid)
        parts.append(part)
    xs = [p["pos"][0] for p in parts]
    zs = [p["pos"][2] for p in parts]
    spec = {
        "name": "Konoha",
        "profile": "tools/syphodev/konoha_profile.json",
        "ground_is_parts": "Konoha is built from parts by Server/Hub (DEC-038); the lake is Terrain water",
        "parts_are_deliberate": "a procedural village of boxes, dressed client-side with meshes (HubDress)",
        "open_edges": "the village ends on the forest and the cliff; HubClient returns a fallen walker to the gate",
        "volume": {"bounds": [[min(xs) - 20, -40, min(zs) - 20], [max(xs) + 20, 140, max(zs) + 20]],
                   "killPlane": -40, "ringOutOffset": 10, "lift": 0},
        "parts": parts,
        "spawns": [[sp["pos"][0], sp["pos"][1] + sp["size"][1] / 2, sp["pos"][2]] for sp in dump["parts"] if sp["name"] == "HubSpawn"][:1],
        "intent": {"reachable": ["Ground_*"] + reachable},
    }
    return spec


if __name__ == "__main__":
    dump = json.load(open(sys.argv[1]))
    spec = convert(dump)
    json.dump(spec, open(sys.argv[2], "w"), indent=0)
    print(f"{len(spec['parts'])} solid parts, {len(spec['intent']['reachable'])} declared reachable")
