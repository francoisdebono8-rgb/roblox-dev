#!/usr/bin/env python3
"""SyphoDev's map prover (.claude/skills/roblox-map/scripts/prove.py) on the whole of Konoha.

    python3 tools/syphodev/konoha_prove.py work/map/konoha_spec.json work/map/konoha_report.json

The prover is run unchanged; only two of its loops get a spatial index, because Konoha
(711 solid parts over 800 x 670 studs, ~350 roofs) is far past the arena size they were
written for (the plain run had not finished the reach pass after 14 minutes):

  * reach._edge_map tries every component against every other one. Here a pair is skipped
    when the two are farther apart than the longest jump the profile allows (horizontally,
    or upward), and the destination's nodes are cut to those within that range of the
    source's edge, before the prover's own _transitions runs on what is left. A pair it
    skips could not have produced an edge: _transitions drops those same node pairs on
    the same two tests (dy > max_rise, flat > max_span) before any other work.
  * reach._transitions looks for a wall beside every jump that falls short, for the wall
    climb and the wall jump. Konoha's walk has neither (abilities: {}), so whatever it
    finds is thrown away; the look-up is skipped when the profile ships neither.
  * reach._flood scans the whole edge list for every component it pops; it is replaced by
    the same flood over an adjacency list (same result, linear time).
"""
import json
import math
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = os.path.normpath(os.path.join(HERE, "../../../../.claude/skills/roblox-map/scripts"))
sys.path.insert(0, SKILL)

import reach  # noqa: E402
import prove  # noqa: E402


def _limits(profile, generous):
    speed = profile.get("slideEntryCap", 32.0) if generous else profile.get("walkSpeed", 16.0)
    climb = profile.get("abilities.wallClimb.maxRise", 0.0) if generous and profile.shipped("wallClimb") else 0.0
    wj_rise = profile.get("abilities.wallJump.rise", 0.0) if generous and profile.shipped("wallJump") else 0.0
    wj_travel = profile.get("abilities.wallJump.travel", 0.0) if generous and profile.shipped("wallJump") else 0.0
    rise = profile.get("jumpApex", 10.4) + climb + wj_rise
    span = max(reach._jump_range(profile, 0.0, speed) or 0.0, wj_travel)
    return span, rise


def _bbox(nodes):
    xs = [n.x for n in nodes]
    ys = [n.y for n in nodes]
    zs = [n.z for n in nodes]
    return min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)


def _gap(a0, a1, b0, b1):
    return max(0.0, b0 - a1, a0 - b1)


class _Cut:
    """A destination component seen through a window: the same id and boxes, fewer nodes."""

    def __init__(self, comp, nodes):
        self.id, self.boxes, self.boundary, self.nodes = comp.id, comp.boxes, comp.boundary, nodes


def _edge_map(comps, profile, boxes, generous):
    span, rise = _limits(profile, generous)
    pad = span + 1e-6
    src_box = {c.id: _bbox(c.boundary) for c in comps}
    dst_box = {c.id: _bbox(c.nodes) for c in comps}
    edges, tried, t0 = {}, 0, time.time()
    for i, src in enumerate(comps):
        sx0, sx1, sy0, sy1, sz0, sz1 = src_box[src.id]
        for dst in comps:
            if src.id == dst.id:
                continue
            dx0, dx1, dy0, dy1, dz0, dz1 = dst_box[dst.id]
            if dy0 - sy1 > rise:
                continue
            gx, gz = _gap(sx0, sx1, dx0, dx1), _gap(sz0, sz1, dz0, dz1)
            if math.hypot(gx, gz) > pad:
                continue
            near = [n for n in dst.nodes
                    if sx0 - pad <= n.x <= sx1 + pad and sz0 - pad <= n.z <= sz1 + pad
                    and n.y - sy1 <= rise]
            if not near:
                continue
            tried += 1
            ways = reach._transitions(src, _Cut(dst, near), profile, boxes, generous)
            if ways:
                edges[(src.id, dst.id)] = ways
        if i % 50 == 0:
            print(f"  edges {'generous' if generous else 'conservative'}: {i}/{len(comps)} "
                  f"components, {tried} pairs tried, {len(edges)} edges, {time.time() - t0:.0f}s",
                  file=sys.stderr, flush=True)
    return edges


def _flood(edges, start_ids):
    adj = {}
    for (a, b) in edges:
        adj.setdefault(a, []).append(b)
    seen = set(start_ids)
    frontier = list(start_ids)
    while frontier:
        for b in adj.get(frontier.pop(), ()):
            if b not in seen:
                seen.add(b)
                frontier.append(b)
    return seen


_wall_beside = reach._wall_beside
_NO_WALLS = [False]


def _wall_beside_if_used(node, boxes, profile, ignore):
    if _NO_WALLS[0]:
        return None, None
    return _wall_beside(node, boxes, profile, ignore)


_edge_map_plain = _edge_map


def _edge_map_walls(comps, profile, boxes, generous):
    _NO_WALLS[0] = not (profile.shipped("wallClimb") or profile.shipped("wallJump"))
    return _edge_map_plain(comps, profile, boxes, generous)


reach._edge_map = _edge_map_walls
reach._wall_beside = _wall_beside_if_used
reach._flood = _flood

if __name__ == "__main__":
    spec, out = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else None)
    res = float(os.environ.get("RES", "4"))
    t0 = time.time()
    args = [spec, "--res", str(res)] + (["--json", out] if out else [])
    code = prove.main(args)
    print(f"(konoha_prove: {time.time() - t0:.0f}s at res {res})", file=sys.stderr)
    sys.exit(code or 0)
