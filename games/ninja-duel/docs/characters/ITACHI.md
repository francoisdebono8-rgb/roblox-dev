# Itachi — jeune prodige

Code : `Mirage`. IDs : CHR-ITA-001/002, CHR-CORE-001/002. Les données réelles viennent de Fighters/MoveGraphs/Attacks et [inventaire](../current/COMBAT_INVENTORY.json) ; le label lore n’est pas automatiquement prouvé par le nom du move.

## Expression visée

Calme et précis ; peu de mouvement pour lire/feinter/faire perdre la ligne. Shuriken/ricochet/geometry et feu créent un angle ou une menace, pas simple spam. Défense et courtes frappes propres ; costume jeune, pas Akatsuki, pas capacités adultes transférées sans filtre.

## Conversions à rechercher, pas à ajouter aveuglément

Projectile collision→RedirectTrajectory ; feinte→outside angle→counter court ; geometry→fire lane→conversion. Geometry actuel prouvé, nouveau conflit généralisé à évaluer séparément.

Pour chaque exemple : source/âge/scene/timecode, label lore, état initial/contact/réaction/résultat/followup, brique commune et expression spécifique, input/camera/air/wall/risque. Vérifier d’abord si le code satisfait déjà l’intention. Lire le blueprint complet dans [ROSTER_MOVESETS_10_PRODIGIES](ROSTER_MOVESETS_10_PRODIGIES.md) et les passages propres à Itachi dans [CLAUDE_FINAL_PASS](../archive/missions/CLAUDE_FINAL_PASS.md).

## Validation

Baseline native + garde/course/strafe/dash/jump, contact/defense/throw/outil/jutsu/air/mur/KO ; duel contre les quatre IA et manette. Même scénario avant/après ; motion/export sélectionné par Claude, contrats/costs/timings protégés. Reconnaissance de Itachi sans jutsu ; vérifier jeunesse et contre-jeu. Un headless PASS technique ne clôt pas cette identité visuelle.
