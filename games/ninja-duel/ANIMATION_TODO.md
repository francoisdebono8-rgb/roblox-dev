# Travail d'animation à réaliser dans Roblox Studio

Le rig procédural est R15 avec `Humanoid`, `Animator` et joints standard (`Root`, `Waist`, `Neck`, épaules, coudes, poignets, hanches, genoux, chevilles). `World.pose` anime actuellement les `Motor6D.C0` avec interpolation ; ces poses sont uniquement des placeholders. Les volumes des avatars, portraits et impacts doivent être retravaillés après validation du combat.

1. Créer des animations **originales** dans Studio pour idle de combat, départ de course, sprint, strafe gauche/droite, recul, takeoff, montée, chute, atterrissage, dash au sol/en l'air, garde, réaction au coup, quatre frappes distinctes, startup/canalisation/release/récupération de technique et défaite. Prévoir des signatures différentes pour Flashstep (compact, rapide) et Mirage (retenu, feintes).
2. Publier les clips sous un compte/groupe autorisé et relever les IDs dans un manifeste. Ne jamais intégrer des animations rippées ni des ID tiers non autorisés.
3. Remplacer `World.pose` par un contrôleur d'animation R15 unique : priorité des actions sur la locomotion, fondus rapides, locomotion directionnelle et vitesse ajustée, suivi du saut et de l'atterrissage, absence de retour à idle entre deux coups chaînés. Vérifier que le script Roblox `Animate` par défaut ne combat pas ce contrôleur.
4. Ajouter des marqueurs d'animation pour caler les fenêtres actives du serveur, les trails, la réaction, le coup final et les appels de sons. Le serveur reste propriétaire des dégâts et des déplacements ; les marqueurs client ne décident pas d'un hit.
5. Filmer en Studio les deux personnages de face/profil à vitesse réelle et ralentie : sprint/arrêt, strafe, saut/air dodge/atterrissage, chaîne complète, whiff, interruption, lecture de Mirage, poursuite. Ajuster rythme, lisibilité, transitions, caméra, impacts et sons après essai humain.

La place n'embarque aucun asset audio externe. `Combat:cue` et les événements d'état constituent les points de raccordement ; les sons de pas, dash, hit, garde, launch et techniques restent à créer/licencier et synchroniser.
