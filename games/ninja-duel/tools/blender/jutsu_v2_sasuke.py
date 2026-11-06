"""Sasuke (Lion) jutsu pass v2 - WORK IN PROGRESS: every clip name exists
(ported from the current modules), re-authored clip by clip below.
"""
import sasuke_p1, clips_lion2, jutsu_sasuke, common_e9


def author(arm):
    acts = []
    acts += sasuke_p1.katon(arm)
    acts += sasuke_p1.phoenix(arm)
    acts += sasuke_p1.wire_trap(arm)
    acts.append(sasuke_p1.awaken(arm))
    acts += [a for a in clips_lion2.chidori(arm) if a.name != "Lion.ChidoriThrust"]
    acts.append(clips_lion2.throw_shuriken(arm))
    acts.append(common_e9.throw(arm, "Lion.", clips_lion2.STANCE))
    acts += jutsu_sasuke.soshuha(arm)
    acts += jutsu_sasuke.windmill(arm)
    acts += jutsu_sasuke.counter(arm)
    acts += jutsu_sasuke.copy(arm)
    return acts
