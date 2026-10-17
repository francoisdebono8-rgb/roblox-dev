# Anciennes fiches remplacées par Combat Bibles V1

Source avant changement :61eb585. Vingt profils et index/template conservés, liens recalculés. Nouvelles cibles dans docs/characters, roster normatif DEC-026. Trois fiches retirées restent des redirects historiques ; aucun runtime modifié.

- [MINATO.md](MINATO.md)
- [ITACHI.md](ITACHI.md)
- [NEJI.md](NEJI.md)
- [SASUKE.md](SASUKE.md)
- [GAARA.md](GAARA.md)
- [ROCK_LEE.md](ROCK_LEE.md)
- [NARUTO.md](NARUTO.md)
- [TEMARI.md](TEMARI.md)
- [HINATA.md](HINATA.md)
- [KAKASHI.md](KAKASHI.md)
- [HAKU.md](HAKU.md)
- [ZABUZA.md](ZABUZA.md)
- [KIMIMARO.md](KIMIMARO.md)
- [SHISUI.md](SHISUI.md)
- [OROCHIMARU.md](OROCHIMARU.md)
- [KABUTO.md](KABUTO.md)
- [DEIDARA.md](DEIDARA.md)
- [SASORI.md](SASORI.md)
- [NAGATO.md](NAGATO.md)
- [KILLER_BEE.md](KILLER_BEE.md)
- [ROSTER_20.md](ROSTER_20.md)
- [FIGHTER_TEMPLATE.md](FIGHTER_TEMPLATE.md)

## Livraison documentaire — vérifications

Base finale : source Claude `41364ed5c79cfdac4d7a29bbcdc75b893caad622` (M1 reconnu). Aucun code runtime/test/build modifié par Codex. Réexécution : 28 suites / 503 cas PASS, Lune0.10.5 / Luau0.743 ; contrôle documentaire (75 tickets + sept autotests) PASS ; frontières (408 fichiers) PASS ; 964 liens relatifs vérifiés, zéro cible absente. Les nouvelles chorégraphies restent du design non implémenté/non validé en Studio.

## Liste exacte des fichiers livrés

Statut Git relativement à cette base : A = créé ; M = modifié. Les22 anciennes versions sont archivées par copie avec liens recalculés ; leurs chemins actifs sont remplacés ou redirigés, aucune suppression de contenu historique.

```text
M	games/ninja-duel/CLAUDE_START_HERE.md
M	games/ninja-duel/docs/active/CURRENT_STATE.md
M	games/ninja-duel/docs/active/DECISIONS.md
M	games/ninja-duel/docs/active/ENGINEERING_REVIEW.md
M	games/ninja-duel/docs/active/MASTER_BACKLOG.md
M	games/ninja-duel/docs/active/SINCE_LAST_CLAUDE.md
M	games/ninja-duel/docs/active/VISION.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/DEIDARA.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/DISPOSITION.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/FIGHTER_TEMPLATE.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/GAARA.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/HAKU.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/HINATA.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/ITACHI.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/KABUTO.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/KAKASHI.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/KILLER_BEE.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/KIMIMARO.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/MINATO.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/NAGATO.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/NARUTO.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/NEJI.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/OROCHIMARU.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/ROCK_LEE.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/ROSTER_20.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/SASORI.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/SASUKE.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/SHISUI.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/TEMARI.md
A	games/ninja-duel/docs/archive/characters/2026-10-18-superseded-profiles/ZABUZA.md
M	games/ninja-duel/docs/archive/reports/SOURCE_COVERAGE.json
M	games/ninja-duel/docs/archive/reports/SOURCE_COVERAGE.md
A	games/ninja-duel/docs/archive/requests/2026-10-18-character-v1-combat-bibles.md
M	games/ninja-duel/docs/characters/CORE_ROSTER.md
M	games/ninja-duel/docs/characters/DEIDARA.md
M	games/ninja-duel/docs/characters/FIGHTER_TEMPLATE.md
M	games/ninja-duel/docs/characters/GAARA.md
M	games/ninja-duel/docs/characters/HAKU.md
A	games/ninja-duel/docs/characters/HASHIRAMA_CHILD.md
M	games/ninja-duel/docs/characters/HINATA.md
A	games/ninja-duel/docs/characters/HIRUZEN_CHILD.md
M	games/ninja-duel/docs/characters/ITACHI.md
M	games/ninja-duel/docs/characters/KABUTO.md
M	games/ninja-duel/docs/characters/KAKASHI.md
M	games/ninja-duel/docs/characters/KILLER_BEE.md
M	games/ninja-duel/docs/characters/KIMIMARO.md
A	games/ninja-duel/docs/characters/MADARA_CHILD.md
M	games/ninja-duel/docs/characters/MINATO.md
M	games/ninja-duel/docs/characters/NAGATO.md
M	games/ninja-duel/docs/characters/NARUTO.md
M	games/ninja-duel/docs/characters/NEJI.md
M	games/ninja-duel/docs/characters/OROCHIMARU.md
M	games/ninja-duel/docs/characters/ROCK_LEE.md
M	games/ninja-duel/docs/characters/ROSTER_20.md
M	games/ninja-duel/docs/characters/SASORI.md
M	games/ninja-duel/docs/characters/SASUKE.md
M	games/ninja-duel/docs/characters/SHISUI.md
M	games/ninja-duel/docs/characters/TEMARI.md
M	games/ninja-duel/docs/characters/ZABUZA.md
```
