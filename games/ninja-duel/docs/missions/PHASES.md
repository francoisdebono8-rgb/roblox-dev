# Ninja Duel — ordre simple pour Codex

Utiliser ce fichier comme point d'entrée. Ne pas demander à François de retrouver des SHA de commits.

## PHASE 1 — VISION
**Fichier :** `../archive/BRIEF.md`

But : comprendre le jeu complet, les principes de combat, le prototype 1v1, l'architecture future et la manière de collaborer avec François.

Codex doit lire cette phase avant toute autre.

---

## PHASE 2 — COMBAT FEEL
**Fichier :** `COMBAT_FEEL_V02.md`

But : transformer le premier prototype technique en jeu de ninja agréable à contrôler.

Priorités :
1. locomotion ;
2. grands sauts / air control ;
3. dash et déplacement autour de l'adversaire ;
4. lock-on ;
5. melee mobile ;
6. poursuite ;
7. animations/transitions ;
8. caméra et impacts ;
9. conserver chakra/interruptions ;
10. IA adaptée au nouveau combat.

C'est la phase actuellement prioritaire.

---

## PHASE 3 — PERSONNAGES
**Fichier :** `CHARACTER_REFERENCE.md`

But : donner à Codex un pool de conception très précis pour jeune Minato et jeune Itachi, avec Shisui comme alternative uniquement après discussion avec François.

Ne pas essayer d'implémenter toute la fiche. Choisir les éléments qui produisent le meilleur contraste jouable.

---

## PHASE 4 — SUPPORT TECHNIQUE
**Fichier :** `codex-support/IMPLEMENTATION_PLAYBOOK.md`

But : fournir les patterns d'implémentation lorsque Codex construit/refactorise le moteur : movement motor, action state, root motion, hitboxes, pursuit, substitution, cancel, techniques, animation controller, caméra, IA, networking futur PvP, cleanup et debug.

Ce fichier est une référence technique, pas une obligation de recopier le pseudocode.

---

# Instruction actuelle à donner à Codex

> Lis `games/ninja-duel/docs/missions/PHASES.md`. Considère-le comme l'index officiel de la mission. Lis d'abord PHASE 1 pour conserver la vision globale, puis réalise PHASE 2 en t'appuyant sur PHASE 3 pour les personnages et PHASE 4 pour les besoins techniques. Inspecte et réutilise ce qui fonctionne déjà dans le prototype. Ne cherche pas à ajouter du contenu tant que le déplacement et le combat de base ne sont pas réellement agréables. Pose à François uniquement les questions importantes/difficilement réversibles prévues dans les documents.

# Règle de validation

Après chaque phase importante, les changements doivent être identifiables dans GitHub afin qu'ils puissent être audités indépendamment.

Pour PHASE 2, ne déclarer terminé qu'avec un résumé précis des fichiers modifiés, des tests effectués et des éléments encore placeholder. François/ChatGPT vérifieront ensuite le dépôt et ne se baseront pas uniquement sur le résumé de Codex.