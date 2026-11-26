#!/usr/bin/env python3
"""The sound check's report (OUTILLEUR, passe commune 3, 26/11; DEC-055: « chaque son se
charge, a la bonne durée et un volume cohérent, avec sa licence notée »).

    python3 tools/sounds/report.py MESURE.json [--md RAPPORT.md]
    python3 tools/sounds/report.py --start            Client : _G.NDSoundCheck.start()
    python3 tools/sounds/report.py --read             Client : le JSON de la mesure

MESURE.json is _G.NDSoundCheck.read() (tools/sounds/sound_check.luau, injected by
tools/robots/inject.py sound). The licences are in tools/sounds/licences.json
(get_asset_details, Creator Store).
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
CHECK_LUA = '(_G.NDSoundCheck or error("NDSoundCheck absent : python3 tools/robots/inject.py sound (pendant le Play)"))'
# A length off by more than this (s) from what the bank says is a mismatch.
LENGTH_GAP = 0.5
# A sound whose effective loudness is under LOW or over HIGH times its layer's
# level does not sit where the bank wants it in the mix.
LOW, HIGH = 0.8, 1.25
# A street blow whose effective peak is under this share of the Konoha music's
# effective peak may be drowned by it.
MASKED = 1.0


def licences():
    path = os.path.join(HERE, "licences.json")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def asset(sound_id: str) -> str:
    return sound_id.replace("rbxassetid://", "")


def verdicts(row: dict, music_peak: float = 0.0) -> list:
    """What is wrong with one sound: a list of short French notes (empty: fine)."""
    out = []
    if row.get("error"):
        return [f"erreur : {row['error']}"]
    if not row.get("loaded"):
        return ["ne se charge pas"]
    length, measured = row.get("length"), row.get("measured")
    if length is not None and measured is not None and abs(length - measured) > LENGTH_GAP:
        out.append(f"durée {measured} s au lieu de {length} s")
    level, eff = row.get("level"), row.get("effective")
    if level and eff is not None:
        if eff < level * LOW:
            out.append(f"sous son niveau ({eff} pour {level})")
        elif eff > level * HIGH:
            out.append(f"au-dessus de son niveau ({eff} pour {level})")
    if row.get("layer") == "street" and music_peak and (row.get("effectivePeak") or 0) < music_peak * MASKED:
        out.append(f"crête {row.get('effectivePeak')} sous celle de la musique de Konoha ({music_peak}) : risque d'être couvert")
    return out


def report(rows: list) -> str:
    lic = licences()
    konoha = [r.get("effectivePeak") or 0 for r in rows if r.get("key") == "music.konoha"]
    music_peak = round(sum(konoha) / len(konoha), 1) if konoha else 0.0
    lines = ["# Contrôle des sons", "",
             f"{len(rows)} sons : la banque (`Shared/SoundBank.all()`) et les coups de rue (`Client/HubFightClient`).", "",
             "| son | titre (créateur) | chargé | durée banque / mesurée | volume | sonie effective / niveau | crête effective | à voir |",
             "|---|---|---|---|---|---|---|---|"]
    for r in rows:
        info = lic.get(asset(r.get("id", ""))) or {}
        who = f"{info.get('title', r.get('name') or '?')} ({info.get('creator', '?')})"
        notes = "; ".join(verdicts(r, music_peak)) or "·"
        vol = r.get("volume")
        lines.append(f"| `{r.get('key')}` | {who} | {'oui' if r.get('loaded') else '**non**'} | {r.get('length', '—')} / {r.get('measured', '—')} s "
                     f"| {round(vol, 2) if isinstance(vol, (int, float)) else '—'} | {r.get('effective', '—')} / {r.get('level') or '—'} "
                     f"| {r.get('effectivePeak', '—')} | {notes} |")
    lines.append("")
    lines.append(f"Sonie : `Sound.PlaybackLoudness` sans son entendu (un SoundGroup à 0), 0,6 s à cinq endroits d'un morceau long, "
                 f"une fois depuis le début pour un son court ; « effective » = sonie × volume de la banque. Un son est sous ou au-dessus "
                 f"de son niveau hors de {int(LOW * 100)} à {int(HIGH * 100)} % du niveau de sa couche (`SoundBank.LEVEL`). "
                 f"Crête moyenne de la musique de Konoha : {music_peak}.")
    lines.append("")
    lines.append("Licences (`tools/sounds/licences.json`) : chaque son est un audio gratuit de la boutique des créateurs Roblox, "
                 "d'un créateur vérifié : DistrokidOfficial pour les musiques, ProSoundEffects pour les ambiances et les coups.")
    return "\n".join(lines)


def main(argv=None):
    args = argv if argv is not None else sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    if args[0] == "--start":
        print(f"return {CHECK_LUA}.start()")
        return 0
    if args[0] == "--read":
        print(f"return {CHECK_LUA}.read()")
        return 0
    with open(args[0], encoding="utf-8") as f:
        rows = json.load(f)
    text = report(rows)
    if "--md" in args:
        with open(args[args.index("--md") + 1], "w", encoding="utf-8") as f:
            f.write(text + "\n")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
