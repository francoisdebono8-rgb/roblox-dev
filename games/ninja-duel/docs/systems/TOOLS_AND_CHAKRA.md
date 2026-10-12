# Outils et chakra

IDs TOOL-001..006, SYS-001..003, DEF-005. Cycle existant : beginThrow/stepThrow, projectile, projectileHit/projectileSurface/onSurface, plant/anchors/markedInFlight, projectileExpire/removeProjectile/clear/expireSeals. Voir [contrats](../current/COMBAT_CONTRACTS.md). Toutes les mutations combat restent serveur.

Outil dans la main→draw/grip/release→vol→contact/surface/embedded→effet→expiration/cleanup. Lancer doit rester mobile et lié au corps, depuis run/air/dodge/angle, puis pouvoir convertir en melee ou sortie. Les outils communs portent une maîtrise propre : Minato marque/angle, Itachi geometry/ricochet/read, Sasuke fil/feu, Neji précision plutôt qu’une multiplication de boutons.

Ne pas confondre marques FTG existantes avec inventaire universel/recall/équipement. WireTrap→DragonFlame existe. Smoke n’est actuellement qu’un effet de substitution ; explosive tags dédiés absents. Ces pistes restent conditionnelles. Aucune suppression d’outils utiles pour rendre le kit artificiellement simple.

Direction systémique : objet + nature/propriété chakra + déclencheur/contexte → résultat. Commencer par interactions concrètes bornées (déviation, marque, fil/feu, impact/zone/air/mur), observer coût/contre-jeu puis seulement extraire une abstraction réellement réutilisée. Chakra doit créer un choix, pas simplement plus de dégâts. La matrice research est un réservoir de propositions, pas l’obligation de coder chaque case.

Awake : examiner ce qui modifie déjà fenêtres/règles, puis proposer des changements de comportement lisibles plutôt qu’un seul stat boost. Filtrer les idées adult-only, maintenir labels lore et jeune identité. Ne pas ajouter des yeux/pouvoirs adultes par défaut.

Validation : trajectoires et nettoyage après miss/hit/wall/reset/KO/expiration, plusieurs outils/marks distincts, conversions et ressources ; tests Tools/Systems/Phase4/Sasuke/Preparation, puis corps/contact/contre-jeu natifs. Sources complètes : [final](../archive/missions/CLAUDE_FINAL_PASS.md), [matrix](../../design_research/03_system_interactions/SYSTEM_INTERACTION_MATRIX.md), [Awakening](../../design_research/02_character_architecture/AWAKENING_DESIGN.md).
