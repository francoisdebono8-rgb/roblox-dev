# Audit incrémental Codex — 5bb52fd..aeff49a — 18 octobre 2026

Périmètre : cinq commits, M5, M6 lot1 et gate M7 ; 19 fichiers changés dont artefacts et documents. Base finale examinée : `aeff49a`. Aucun gameplay, test, build ou asset modifié par Codex. M1–M4 sont antérieurs à la plage ; ne pas les réauditer ni les déclarer ouverts depuis une ancienne revue.

**Verdict : améliorations M5/M6 cohérentes ; clôture automatique M7 non fiable.** Aucun P0 ni nouvelle régression du gameplay reproduite dans cette plage. Bloquer la clôture QA-004 sur le seul badge 20/20, pas assimiler ce défaut de validation à vingt kits cassés.

## F1 — P1 — M7 peut certifier une séquence ratée

[DevGateCheck](../../../../src/Server/DevGateCheck.luau), lignes296–341 : dégâts/route/poursuite/air/outils/jutsus/garde sont seulement inscrits dans le log. Le résultat retourne uniquement `not leftover`. Même le passage effectif au round2 n’est pas exigé après le timeout ; les cooldowns et l’état adverse ne sont pas vérifiés. La garde utilise une condition qui accepte aussi l’absence de coup (`chip<3`). Une Technique acceptée ne prouve pas son contact/effet.

Preuve native existante lue via MCP dans ND-Debug-m7b : `Q:Sand PASS • lights=0 route=Light1 E=Committed air=0 ... reset=round=2 clean=true` ; six autres lignes initiales ont aussi lights=0 avec PASS. Une passe ultérieure présente les vingt lignes cohérentes, lights>0/bonnes routes/air2/reset2. Elle apporte des observations positives, mais ne rend pas le verdict automatique fiable. [Extraits conservés](STUDIO_GATE_LOGS.txt). Ne pas prétendre que ces lignes initiales ont été reproduites par Codex aujourd’hui : il s’agit des logs présents de Claude.

Autre limite de portée : le rapport M7 dit « sans replacement après le départ », mais seq téléporte avant l’outil, plusieurs techniques et la garde (308,318,326). C’est une sonde serveur en étapes, pas une séquence joueur continue. Les vraies touches/manette/feel restent PENDING comme déjà annoncé.

**Mission Claude1 — durcir seulement les gates.** Faire échouer chaque contrat obligatoire (confirmations, route attendue du graphe, poursuite ou alternative propre Lion/Leaf, deux contacts air, outil ou exception Leaf explicite, effet propre de chaque technique, garde réellement sollicitée, round2 et nettoyage des deux acteurs/cooldowns). Propager erreurs et timeouts. Ajouter contrôles négatifs ciblés : requête refusée, whiff, zéro hit air, technique refusée, garde non sollicitée et round non avancé doivent donner FAIL. Ne pas coder un moteur QA général. Corriger S20 dans ce même commit (F3).

Validation Studio : rejouer la gate corrigée sur les vingt et archiver les vingt lignes complètes ; injecter temporairement un refus d’attaque dans une sonde isolée et vérifier FAIL ; tester l’exception E Lion/Leaf sans accepter arbitrairement tout refus. Marquer honnêtement les replacements dans le rapport. Une vraie séquence continue aux inputs est une preuve supplémentaire à faire, pas un résultat obtenu par ce script.

## F2 — P2 — artefact QA antérieur à la gate M7

`dist/NinjaDuel-QA.json` annonce sourceEquality PASS mais son hash DevGateCheck vaut `1ebd3ce861d6ce5a71e5ffd0ee66fac6d7eb6509e0bf4c537caa9f5c907e01d8`, contre `a9eea71b83dbbed64b18abbbd103d4d7132893af449d36f72ffbc0b74ee8e114` au HEAD. C’est le seul écart source relevé dans les trois manifests. Le Debug correspond au HEAD ; les trois hashes d’artefacts correspondent à leurs manifests. Pas une preuve de gameplay production périmé : DevGateCheck est exclu du normal.

**Mission Claude2 — après Mission1 :** reconstruire les trois variantes et vérifier chaque hash de source embarquée contre le commit livré ; ouvrir le Debug/QA exact, exécuter M7 corrigé et joindre fingerprint/rapport. Ne pas régénérer les artefacts dans un audit Codex ni transférer une preuve d’un build sur un autre.

## F3 — P2 — S20 n’assert pas le projectile après fermeture

DevGateCheck ligne273 affiche `kunai after close dmg` mais ne teste pas `hp-a.health>0`. Si ce dernier kunai ne fait aucun dégât, S20 peut passer quand même. Le corriger avec F1, attendre une vraie frappe post-fermeture et inclure sa réussite dans le verdict. Pas de bug Absorb affirmé : Codex a relancé S20 par l’attribut traité par DevHooks ; résultat actuel PASS, absorption/chakra=true, melee=true, fermeture=true, dégâts post-fermeture=3.0.

## Ce qui est vérifié / non vérifié

- TECHNICAL : 28 suites /508 cas PASS réexécutés (Lune0.10.5/Luau0.743), dont Convergence14 ; neuf tests Python d’isolation build PASS. [Sortie](HEADLESS_TESTS.txt). Les gates Roster/Branches/ComboModel restent vertes ; aucun changement de graphe/roster/inputs dans la plage. Invariant direction+Light avant premier hit conservé par les tests existants, pas nouveau rejeu natif de toutes directions.
- M5 : charge posé/armé dans snapshot autoritaire et présentation ; Absorb depuis buff serveur, impact drain portant projectile, fermeture dédiée. Test charge teste surtout la présentation et recalcule son état au lieu d’appeler réellement Matches:view : couverture snapshot à renforcer si contrat modifié.
- M6 : stopStyle réutilise kind/reaction/air des attaques au lieu des seuls noms génériques ; traînée du couperet limitée à Active. Pas de moteur parallèle, ni duplication par fighter. Changement de classification du test IA examiné ; suite PASS, pas preuve de variété/feel.
- NATIVE_STUDIO : MCP connecté au Studio m7b en Play, sources M7 présentes, log fingerprint Debug `2dc36969acd151fbfafb375f9f0519f64fe0ccbbed3b2000e07ffbb7700502d2` cohérent. Logs Claude lus, S20 seul rejoué par Codex. L’appel direct au module depuis execute_luau a échoué (cache/contexte DevHooks sans matches) ; relance par attribut installé réussie, ne pas classer ce premier échec comme bug du jeu.
- HUMAN_VISUAL/FEEL : aucun nouveau PASS Codex. M6 n’est qu’un lot1 : stop/trail ne produisent pas les vingt identités corporelles DEC-026. S19/S21 complet/S23/S24, vraie manette et parcours continu restent à compléter selon CURRENT_STATE.
- LIVE_ROBLOX : aucune nouvelle preuve ; hors périmètre de ce delta.

## Suite après fiabilisation

Mission3 : séquences aux vraies touches Zabuza et un voisin de famille, garde/whiff/substitution, sol→air et mur (S22–S24) sur l’artefact reconstruit ; ajuster le feel seulement si un défaut est montré. Puis ouvrir le premier petit lot identité des bibles via MASTER_BACKLOG ; ni hub/arbre/progression ni nouvelle passe globale de moteurs. Les trois entrants Madara/Hashirama/Hiruzen restent une cible future, pas présents dans les vingt de cette gate.
