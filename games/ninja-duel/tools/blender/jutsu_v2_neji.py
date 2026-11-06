"""Neji's jutsu, pass v2 (work in progress: v0 ports the current clips so every
name exists; each jutsu is then re-authored below)."""
from nd_shot import Shot, merge
import neji_p9
import jutsu_neji
import common_e9

N = "GentleFist."


def byakugan_v0(arm):
    s_ = neji_p9.s
    sign = s_({"root": {"y": -.5, "pitch": 4}, "head": {"pitch": 14, "yaw": 0},
               "ra": {"raise": 100, "out": -46, "twist": 60, "elbow": 130, "wrist": 0}, "la": {"raise": 20, "out": 20, "elbow": 40}})
    up = merge(sign, {"head": {"pitch": -10}, "torso": {"pitch": -6}, "ra": {"raise": 90, "out": -40, "elbow": 120}})
    out = []
    ch = Shot(arm, N + "ByakuganSight.Channel")
    ch.key(0, s_(), "ease").key(7, sign, "ease")
    out.append(ch.build())
    re = Shot(arm, N + "ByakuganSight.Release")
    re.key(0, sign, "ease").key(2, up, "impact").key(5, merge(up, {"head": {"pitch": -6}}), "ease")
    out.append(re.build(markers={"contact": 2 / 60}))
    rc = Shot(arm, N + "ByakuganSight.Recover")
    rc.key(0, up, "ease").key(12, s_(), "ease")
    out.append(rc.build())
    return out


def author(arm):
    acts = [neji_p9.awaken(arm), neji_p9.palm_thrust(arm), neji_p9.throw_kunai(arm)]
    acts += neji_p9.rotation(arm)
    acts += neji_p9.vacuum_palm(arm)
    acts += neji_p9.sixty_four(arm)
    acts += byakugan_v0(arm)
    ch, look = jutsu_neji.leg_points_channel(arm)
    acts += [ch, jutsu_neji.low_palm(arm, look)]
    acts += jutsu_neji.hasangeki(arm)
    acts += jutsu_neji.gentle_counter(arm)
    acts += jutsu_neji.trigram_field(arm)
    acts.append(common_e9.throw(arm, N, neji_p9.STANCE))
    return acts
