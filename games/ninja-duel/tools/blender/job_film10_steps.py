"""(14/11, FILM10 A9, with the DEV) The missing steps of the Minato vs Gaara clip.

- Sand.Pivot.R90/R180/L90/L180: Gaara turning on the spot (clips_feel.pivots,
  his folded-arm stance from job_gaara_film10): the rear foot swings round
  wide, the front one turns on its ball and steps (lifted 18-26 cm; the old
  re-plant lifted 10-14 cm and read as a drag).
- Flashstep.Disengage: Minato's hop out of his string (Server Brawler.disengage:
  Recovery .26 s, 5 studs back at 46 studs/s, a kunai thrown). There was no
  clip: the legs were the gait's backward run at 46 studs/s under the throw.
  A real hop: he sinks, both feet push off, the body is in the air for the 5
  studs (legs gathered under him, toes down), both feet land together on
  their new spot and hold it while the knees take the weight, then he rises
  into his stance. The upper body is left to Flashstep.Throw.Kunai (the
  engine lays the throw over the legs). travel +z = backwards.
Run: python3 job_film10_steps.py <out.json>"""
import bpy, json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)
import nd_rig, nd_ctrl, nd_shot, clips_feel, clips_flash2
import job_gaara_film10  # the folded arms (in place in gaara_p7)
import gaara_p7
from nd_shot import Shot, merge

HOP = 5.0      # studs back (Brawler.disengage)
AIR_F = 11     # frames in the air (5 studs at 46 studs/s ~ 6.5 frames; the drawn hop is a little longer, the body eases in)


def disengage(arm):
    S = clips_flash2.STANCE
    s = clips_flash2.s
    rf, lf = S["rf"], S["lf"]

    def feet(dz, y=0.0, toe=0, knee=0, dx=0.0):
        return {"rf": {"x": rf["x"] + dx, "z": rf["z"] + dz, "y": y, "yaw": rf["yaw"], "toe": toe, "knee": knee},
                "lf": {"x": lf["x"] - dx, "z": lf["z"] + dz, "y": y, "yaw": lf["yaw"], "toe": toe, "knee": knee}}
    sh = Shot(arm, "Flashstep.Disengage")
    sh.key(0, s(merge({"travel": {"z": 0}}, feet(0))), "ease")
    # load: sinks over both feet, chest forward (eyes on the target)
    sh.key(3, s(merge({"travel": {"z": 0}, "root": {"y": -.78, "z": -.1, "pitch": 16}, "torso": {"pitch": 10}, "head": {"pitch": -14}}, feet(0))), "ease")
    # push-off: the legs extend, toes last on the floor
    sh.key(5, s(merge({"travel": {"z": .5}, "root": {"y": -.25, "pitch": 4}, "torso": {"pitch": 4}}, feet(0, toe=-30))), "launch")
    # in the air: feet gathered, a little ahead of the hips (he goes back)
    sh.key(5 + AIR_F // 2, s(merge({"travel": {"z": HOP * .55}, "root": {"y": -.05, "pitch": -6}, "torso": {"pitch": -2}, "head": {"pitch": -8}},
                                   feet(HOP * .55 - .35, y=.75, toe=-20, knee=40))), "pass")
    # reaching for the floor
    sh.key(5 + AIR_F - 2, s(merge({"travel": {"z": HOP * .92}, "root": {"y": -.25, "pitch": -2}}, feet(HOP * .98, y=.2, toe=-12, knee=18))), "pass")
    # touch-down: both feet together on their new spot
    land = 5 + AIR_F
    sh.key(land, s(merge({"travel": {"z": HOP}, "root": {"y": -.7, "z": -.05, "pitch": 14}, "torso": {"pitch": 8}}, feet(HOP))), "impact")
    sh.key(land + 4, s(merge({"travel": {"z": HOP}, "root": {"y": -.82, "z": -.1, "pitch": 18}, "torso": {"pitch": 10}, "head": {"pitch": -12}}, feet(HOP))), "ease")
    sh.key(land + 16, s(merge({"travel": {"z": HOP}}, feet(HOP))), "ease")
    sh.drag(["neck"], 2)
    return sh.build(markers={"liftoff": 5 / 60, "land": land / 60}, meta={"travel": HOP})


if __name__ == "__main__":
    out = sys.argv[-1]
    S = bpy.context.scene
    data = {}
    # Gaara's pivots, folded arms
    nd_rig.clear_scene(); S.render.fps = 60
    arm = nd_ctrl.build("Gaara", "Sand")
    b = clips_feel.Body("Sand", gaara_p7.STANCE, 1.1, 1.0, job_gaara_film10.BLOCK)
    acts = clips_feel.pivots(b, arm)
    for act in acts:
        rep = nd_shot.check(arm, act)
        print("CHECK %-24s skate_max %.3f n %d off_balance %d" % (act.name, rep["skate_max"], len(rep["skates"]), len(rep["off_balance"])))
    data.update(nd_shot.export(arm, acts, out + ".sand.json"))
    # Minato's disengage hop
    nd_rig.clear_scene(); S.render.fps = 60
    arm = nd_ctrl.build("Minato", "Flashstep")
    act = disengage(arm)
    rep = nd_shot.check(arm, act, airborne=(6, 15))
    print("CHECK %-24s skate_max %.3f n %d off_balance %d" % (act.name, rep["skate_max"], len(rep["skates"]), len(rep["off_balance"])))
    data.update(nd_shot.export(arm, [act], out + ".flash.json"))
    json.dump(data, open(out, "w"))
    print("exported", sorted(data))
