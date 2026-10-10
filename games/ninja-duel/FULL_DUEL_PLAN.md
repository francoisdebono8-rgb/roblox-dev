# Phase 5 — plan d'exécution du duel complet

État initial : V0.2 sait sélectionner deux prototypes, combattre contre l'IA, déplacer un rig R15 avec sprint/saut/dash, enchaîner quatre coups mobiles, poursuivre, gérer chakra, techniques interruptibles et rematch. Les 18 scénarios natifs V0.2 passent. À conserver : séparation client/serveur, `Rules`, `Combat`, `Matches`, validations réseau, construction `.rbxlx` autonome et suite QA.

État provisoire : avatars, poses `Motor6D`, portraits, impacts et arène de cour carrée ; pas de sons ni de clips authored. Manquent : statistiques explicites par combattant, carte verticale, wall-run fiable, substitution/cancel, attaque aérienne dédiée, shuriken/kunai de neutral, Fire et seconde primitive élémentaire, présentation et IA adaptées à ces mécaniques.

Ordre des lots (chaque lot doit laisser le jeu lançable) :

1. **Données et socle** — stats de santé/chakra/régénération/accélération/dash/garde par combattant ; noms internes Minato/Itachi, modules élémentaires légers, validation finie et bornée. Test : sélections inversées, coûts, aucune régression V0.2. Risque : compatibilité des tests existants ; garder des alias si nécessaire pendant la migration.
2. **Carte et déplacement vertical** — agrandir la cour, murs traversables et plateformes accessibles ; refactoriser `clamp`, `Motor` et `World` pour wall enter/traverse/rebound/detach et retour au sol, sans plafond ni coins bloquants. Test natif : détection sur face, déplacement vertical/latéral, échec sur angle/coin, sortie, décès/rematch sans état résiduel. Risque : téléportation/physique côté serveur et future prédiction PvP ; limiter vitesse, durée, surfaces et vérifier géométrie côté serveur.
3. **Langage de combat commun** — substitution à charges/fenêtre de timing, coup aérien, cancel déclaré et lisible, réactions/finisher/poursuite, téléguidage léger et feedback. Test : valides/invalides, défense récupère le contrôle, pas de stunlock, géométrie et coûts vérifiés.
4. **Kits** — Minato : kunai de neutral, angle/quickstep, entrée/punition et ancre tactique conservée ; Itachi : shuriken, Read, genjutsu interactif, Fire ; deuxième élément utilisable (Wind pour Minato) pour prouver des comportements différents. Définir Fire/Lightning/Wind/Water/Earth comme familles d'effets sans fabriquer cinq boutons identiques. Test : chaque technique, interruption, coût, cooldown, LOS et nettoyage.
5. **Présentation et IA** — contrôleur procédural R15 amélioré avec poses propres aux deux personnages, wall-run, substitution, poings et coups de pied distincts ; VFX, caméra verticale/impacts, événements audio documentés. IA utilise les mêmes requêtes, traversal et ressources avec réaction imparfaite. Test : duel entier dans les deux sens, QA native complète, captures Studio et journal des erreurs.
6. **Livraison** — reconstruire les deux places, SHA manifeste, README/route de QA manuelle, rapport prouvant ce qui passe et ce qui exige un jugement humain ; commits et push GitHub limités à `games/ninja-duel`.

Travail Studio potentiellement manuel : produire/publier des clips R15 et sons originaux avec un compte détenteur des droits. Le code doit offrir les points de raccordement et des poses procédurales utilisables sans cet accès. Si ces clips ne sont pas réalisés, la qualité d'animation finale reste explicitement BLOQUÉE ; aucune affirmation de « phase terminée » sur le seul résultat technique.

Critère global : un joueur peut ouvrir la place, choisir Minato ou Itachi, parcourir le sol, les plateformes et les murs, combattre avec mêlée/air/défense/substitution/éléments/techniques, finir puis relancer un duel. Les critères subjectifs de plaisir, lisibilité et envie de rejouer sont à juger en essai humain et ne seront pas marqués PASS par les tests automatisés.

## Journal d'exécution — 9 octobre 2026

Lots 1 à 4 implémentés dans les sources et la place reconstruite. Le lot 5 est partiel : l'IA utilise outils, techniques, défense et ressources ; la caméra réagit aux deux combattants et au mur ; les poses R15 restent procédurales et le son absent. Compilation Luau et règles pures : PASS. Le passage natif de la **nouvelle** place QA reste à faire : l'instance Roblox Studio précédente est bloquée sur une boîte de dialogue de fermeture non actionnable par l'outil de contrôle. Les nouveaux scénarios natifs ne sont donc pas marqués PASS. Après déblocage, exécuter la place QA exacte, corriger tout échec, puis filmer/juger les deux sens du duel avant de conclure.

## 10 octobre — reprise Phase 6

Ce plan Phase 5 est remplacé pour la livraison active par `PHASE6_PLAN.md`. Les systèmes utiles sont conservés, la mêlée et la présentation sont remplacées. La phase 5 n’est pas déclarée finale sur ses seules poses procédurales.
