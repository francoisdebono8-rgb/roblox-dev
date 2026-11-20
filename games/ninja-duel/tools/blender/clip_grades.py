#!/usr/bin/env python3
"""Every clip of the 8 kits graded out of 10 (20/11, étape 1 ANIMATEUR: « l'audit SyphoDev de
toutes les animations des 8 kits, chaque clip noté, la liste des pires classée »).

The numbers come first (METHODE_SYPHODEV § 3): each clip is posed frame by frame on the body
that plays it (tools/syphodev/rig.json: the player's avatar, World.RIG) by
tools/syphodev/audit_clips.py, and graded on two things:

  CLEAN (up to -6): what a player sees break - the body through the floor, a foot sliding, a
    hand or forearm inside the head or the torso, a joint that flips or spikes for a sample,
    a loop that snaps. (The engine locks a slow, low foot - VelmoraMotionEngine.authoredFeet -
    so the feet weigh less than the rest.)
  CRAFT (up to -4, the clips with a `contact` marker): the five poses of a blow (§ 4.1:
    rest, anticipation, contact, follow-through, return) read from the striking limb's path -
      wind-up    the limb goes back (against the blow) before it goes in, >= 0.15 stud;
      speed      the limb's speed at contact, >= 18 studs/s (a blow that reads at 20 studs);
      snap       it accelerates into the contact (the last fifth faster than the approach);
      through    it carries on past the contact >= 0.08 stud before it comes back;
      weight     the chest travels with the blow >= 0.15 stud (the body is behind the hit; the
                 root's ground motion belongs to the server, so the waist carries it).
    A blow whose contact comes before 0.12 s (the jabs, by the server's timing) is not asked
    for a wind-up: it has no time for one, the previous blow's end is its anticipation.
  Loops (idles, guards): a body that never moves (< 2 degrees anywhere) reads frozen: -1.

    python3 tools/blender/clip_grades.py RIG.json CLIPS.json OUT_DIR
      CLIPS.json: lune run tools/syphodev/clips_dump.luau CLIPS.json
      OUT_DIR/grades.json (every clip), OUT_DIR/grades.md (per kit, the worst ranked)
"""
import json
import os
import sys

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "syphodev"))
import audit_clips as A  # noqa: E402

KITS = {
    "Legion": "Naruto (THE LOUDMOUTH)", "Lion": "Sasuke (THE AVENGER)", "Leaf": "Lee (THE HARD WORKER)",
    "GentleFist": "Neji", "Sand": "Gaara", "Copycat": "Kakashi", "Mirage": "Itachi", "Flashstep": "Minato (THE YELLOW FLASH)",
}
LIMBS = ("RightHand", "LeftHand", "RightFoot", "LeftFoot", "Head")
# A blow (graded on its five poses): a contact marker, and not a jutsu's channel/release, a throw,
# a summon or an awakening (their contact is a release of chakra, not a limb hitting)
import re  # noqa: E402
NOT_BLOW = re.compile(r"(Channel|Release|Recover|Throw|Summon|Awaken|Ultimate|Sight|Armor|Shield|Clone(?!Kick)|Intro|Win)")


def craft(rig, W, clip):
    """The blow's five poses, from the striking limb's path (root space, authored root motion in)."""
    fps, n = clip["fps"], clip["frames"]
    tc = clip["markers"]["contact"]
    ic = min(n - 1, max(1, int(round(tc * fps))))
    P = {k: W[k][1] for k in LIMBS}
    V = {k: np.linalg.norm(np.gradient(p, axis=0), axis=1) * fps for k, p in P.items()}
    w = max(1, int(round(.1 * fps)))
    limb = max(LIMBS, key=lambda k: V[k][max(0, ic - w):ic + 1].max())
    p, v = P[limb], V[limb]
    a = max(0, ic - max(1, int(round(.08 * fps))))
    d = p[ic] - p[a]
    if np.linalg.norm(d) < 1e-4:
        d = p[ic] - p[0]
    d = d / (np.linalg.norm(d) or 1)
    proj = (p - p[0]) @ d
    windup = float(max(0.0, -proj[:max(1, a)].min()))
    speed = float(v[max(0, ic - w):ic + 1].max())
    k5 = max(1, ic // 5)
    approach = float(v[:max(1, ic - k5)].mean()) if ic - k5 > 0 else 0.0
    snap = float(v[ic - k5:ic + 1].mean()) / (approach or 1e-3)
    after = proj[ic:]
    through = float(max(0.0, after.max() - proj[ic])) if len(after) > 1 else 0.0
    # (the server owns travel: the root's ground motion is stripped from every clip, so the
    # body's weight shows in the chest: the upper torso carried toward the blow by the waist)
    chest = W["UpperTorso"][1]
    weight = float(max(0.0, ((chest[ic] - chest[0]) @ d)))
    pen, why = 0.0, []
    if tc < .12:
        why.append("contact à %.2f s : l'armé est dans le coup d'avant" % tc)
    elif windup < .15:
        pen += 1.0; why.append("pas d'armé (%.2f)" % windup)
    if speed < 18:
        pen += min(1.0, (18 - speed) / 12); why.append("contact lent (%.0f st/s)" % speed)
    if snap < 1.2:
        pen += .7; why.append("n'accélère pas dans le coup")
    if through < .08:
        pen += .7; why.append("pas d'accompagnement")
    if weight < .15:
        pen += .6; why.append("buste qui ne suit pas")
    return min(4.0, pen), why, {"limb": limb, "windup": round(windup, 2), "speed": round(speed, 1), "snap": round(snap, 2),
                                "through": round(through, 2), "weight": round(weight, 2)}


def clean(r):
    pen, why = 0.0, []
    if r["grounded"] and r["body_under_floor"] > .1:
        x = min(2.0, r["body_under_floor"] * 2); pen += x; why.append("corps sous le sol (%.2f)" % r["body_under_floor"])
    if r["moving_foot_under_floor"] > .1:
        x = min(1.0, r["moving_foot_under_floor"]); pen += x; why.append("pied qui bouge sous le sol (%.2f)" % r["moving_foot_under_floor"])
    if r["grounded"] and r["lowest_min"] > .25:
        pen += 1.0; why.append("ne touche jamais le sol")
    if r["grounded"] and r["slip_speed_max"] > 6:
        pen += min(1.0, (r["slip_speed_max"] - 6) / 20); why.append("pied d'appui qui glisse (%.0f st/s)" % r["slip_speed_max"])
    if r["grounded"] and r["slip_run_max"] > .3:
        pen += min(.8, r["slip_run_max"] - .3); why.append("glisse de %.2f stud" % r["slip_run_max"])
    head = max([v["depth"] for k, v in r["inside"].items() if "Head" in k] or [0])
    torso = max([v["depth"] for k, v in r["inside"].items() if "Torso" in k] or [0])
    hands = r["inside"].get("RightHand~LeftHand", {}).get("depth", 0)
    if head:
        pen += min(2.0, head * 2.5); why.append("main dans la tête (%.2f)" % head)
    if torso:
        pen += min(1.5, torso * 2); why.append("bras dans le torse (%.2f)" % torso)
    if hands:
        pen += min(.5, hands); why.append("mains l'une dans l'autre")
    flips = [k for k, v in r["pops"].items() if v["kind"] == "flip"]
    spikes = [k for k, v in r["pops"].items() if v["kind"] == "spike"]
    if flips:
        pen += min(2.0, 1.5 * len(flips)); why.append("articulation qui se retourne (%s)" % ", ".join(flips[:3]))
    if spikes:
        pen += min(1.5, .7 * len(spikes)); why.append("à-coup d'une image (%s)" % ", ".join(spikes[:3]))
    if r["loop_gap"]:
        pen += 1.0; why.append("boucle qui saute")
    return min(6.0, pen), why


def activity(clip):
    n = clip["frames"]
    best = 0.0
    for key, rows in clip["joints"].items():
        a = np.array(rows, float).reshape(n, 7 if key == "Root" else 4)
        q = a[:, 3:7] if key == "Root" else a
        best = max(best, float(A.angle_between(q[:1].repeat(n, 0), q).max()))
    return best


def grade(rig, name, clip):
    r = A.audit(rig, name, clip)
    pc, wc = clean(r)
    pk, wk, info = 0.0, [], None
    if "contact" in (clip.get("markers") or {}) and not NOT_BLOW.search(name):
        pk, wk, info = craft(rig, rig.pose(clip), clip)
    pa = 0.0
    if r["loop"] and activity(clip) < 2:
        pa = 1.0; wk.append("figé")
    score = round(max(0.0, 10 - pc - pk - pa), 1)
    return {"name": name, "kit": name.split(".")[0], "score": score, "clean": round(10 - pc, 1),
            "craft": None if info is None else round(4 - pk, 1), "why": wc + wk, "blow": info, "length": clip["length"]}


def main(rig_path, clips_path, out_dir):
    rig = A.Rig(json.load(open(rig_path)))
    clips = json.load(open(clips_path))
    res = [grade(rig, k, c) for k, c in sorted(clips.items()) if k.split(".")[0] in KITS]
    os.makedirs(out_dir, exist_ok=True)
    json.dump(res, open(os.path.join(out_dir, "grades.json"), "w"), indent=0, ensure_ascii=False)
    L = ["# Les clips des 8 kits, notés sur 10 (%d clips, sur le corps %s)" % (len(res), os.path.basename(rig_path)), ""]
    L.append("| Kit | Clips | Moyenne | Coups (craft /4) | Sous 5 | Sous 7 |")
    L.append("|---|---|---|---|---|---|")
    for kit, label in KITS.items():
        k = [r for r in res if r["kit"] == kit]
        cr = [r["craft"] for r in k if r["craft"] is not None]
        L.append("| %s | %d | %.1f | %.1f | %d | %d |" % (label, len(k), np.mean([r["score"] for r in k]), np.mean(cr) if cr else 0,
                                                      sum(r["score"] < 5 for r in k), sum(r["score"] < 7 for r in k)))
    L += ["", "## Les 60 pires, classés", "", "| # | Clip | Note | Ce qui ne va pas |", "|---|---|---|---|"]
    for i, r in enumerate(sorted(res, key=lambda r: (r["score"], r["name"]))[:60], 1):
        L.append("| %d | `%s` | %.1f | %s |" % (i, r["name"], r["score"], " ; ".join(r["why"])))
    open(os.path.join(out_dir, "grades.md"), "w").write("\n".join(L) + "\n")
    print("\n".join(L[:14]))


if __name__ == "__main__":
    main(*sys.argv[1:4])
