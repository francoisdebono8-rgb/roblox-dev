> Référence technique/recherche, non normative. État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md). Les commandes, exemples et anciens constats ci-dessous se vérifient sur le HEAD courant.

# Ressources gratuites R15 — combat, mouvement, animations

Recherche web large effectuée le 2026-10-13 sur Creator Store, GitHub, DevForum et YouTube. Cette liste est un **catalogue de sources à auditer**, pas une autorisation d'intégrer automatiquement quoi que ce soit.

Règle Claude : comparer chaque ressource à la vision Ninja Duel, récupérer seulement les principes, animations, patterns ou modules réellement utiles, et **ne jamais remplacer le moteur actuel en bloc** sans preuve supérieure en Studio. Les ressources sans licence claire restent référence/inspection seulement. Tout modèle avec scripts doit être audité avant exécution. Éviter les shorteners/downloaders opaques ; préférer Creator Store, GitHub source + licence, ou DevForum officiel.

## Priorité A — à inspecter en premier

### A1 — Place1 Movement System — R6/R15 — MIT
- URL : https://github.com/alexkkork/place1-movement-system
- Type : système mouvement open source.
- Licence : MIT vérifiée.
- Contenu : sprint, bunny hop, slide, slide jump, mantle, wall hop, air control, body motion procédural, camera lean/FOV, gamepad.
- Intérêt Ninja Duel : très élevé pour `MOV-001..005`, `CAM-002`, sensation de vitesse, conservation du momentum, saut/traversal ninja, wall movement.
- Limites : pensé first-person, vitesse/gravity propres au projet, mouvement client-driven ; ne pas copier autorité réseau telle quelle.
- Attente Claude : étudier surtout momentum, air control, transition landing/slide, wall-hop, caméra de vitesse ; adapter au third-person lock-on et serveur autoritaire.

### A2 — CombatEngine / roblox-combat-framework — MIT
- URL : https://github.com/heylogscript/roblox-combat-framework
- Type : framework combat melee open source.
- Licence : MIT vérifiée.
- Contenu : states, startup/active/recovery, combo windows, block/parry/perfect dodge, clash, grapple, prediction/reconciliation, lag compensation, anti-cheat.
- Intérêt Ninja Duel : élevé pour `COM-001..007`, `DEF-001..005`, futur `NET-001`, sans remplacer notre architecture.
- Limites : framework générique, pas preuve de game feel ni d'animations premium.
- Attente Claude : comparer contrats/états/timings et interaction results avec notre moteur ; extraire uniquement idées manquantes ou plus propres.

### A3 — Kvarwaxa Combat-System — R6/R15 — MIT
- URL : https://github.com/Kvarwaxa/Combat-System
- Type : fist combat minimal open source.
- Licence : MIT vérifiée.
- Contenu : 3-hit punch combo, raycast serveur, hit feedback.
- Intérêt Ninja Duel : moyen comme référence de simplicité/lecture du pipeline attaque→validation→feedback.
- Limites : beaucoup trop simple pour notre cible ; ne pas en faire une base.

### A4 — Fighting & Dash Animation (R15) — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/15958888762/FightingDash-Animation-R15
- Type : modèle R15 avec script + animations.
- Creator Store : Get Model.
- Contenu observé par métadonnées : 27 animations, 1 script.
- Intérêt Ninja Duel : élevé pour benchmark taijutsu/dash/stance et comparaison avec nos motions actuelles.
- Attente Claude : ouvrir dans Studio isolé, lister chaque animation, tester vitesse normale + ralenti, noter appuis/hanche/contact/recovery ; intégrer seulement si qualité supérieure et droits compatibles.

### A5 — R15 Fighting Animations Pack Combo Punch Kick — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/70925948463185
- Type : pack animations R15.
- Creator Store : Get Model.
- Intérêt Ninja Duel : élevé pour `COM-002/003`, coups de poing/kicks/combos, benchmark contre effet "danse".
- Attente Claude : vérifier nombre réel de clips, rig, qualité biomécanique et possibilité d'adaptation Motion Lab.

### A6 — Combat Animations R15 Fighting Punch Kick — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/72490332630186/Combat-Animations-R15-Fighting-Punch-Kick
- Type : pack animations R15.
- Creator Store : Get Model.
- Intérêt Ninja Duel : élevé comme banque alternative de punches, kicks, stance, dodge.
- Limites : description très marketing, zéro review ; audit Studio obligatoire.

### A7 — R15 Fighting Animations Pack Combo Moveset — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/112293652257087/R15-Fighting-Animations-Pack-Combo-Moveset
- Type : pack combat/moveset R15.
- Creator Store : Get Model.
- Intérêt Ninja Duel : élevé comme source de transitions et variété.
- Limites : zéro review ; ne pas supposer qualité/usage avant inspection.

## Priorité B — mouvement / locomotion à comparer

### B1 — huzv/MovementSystem — GitHub public, licence non trouvée
- URL : https://github.com/huzv/MovementSystem
- Type : movement system camera-relative.
- Contenu : 8 directions, walk/run forward/back/left/right, jump buffering, landing state, crossfades, transition clips, camera collision, smooth zoom.
- Intérêt Ninja Duel : très élevé conceptuellement pour `MOV-001/003/005`, notamment vraie course latérale et transitions.
- Licence : **non trouvée lors de la recherche** → référence/inspection seulement tant qu'elle n'est pas clarifiée.
- Attente Claude : étudier architecture et comportement ; ne pas copier code sans licence explicite.

### B2 — Realistic Run Animation R15 Smooth Parkour — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/120999921089302/Realistic-Run-Animation-R15-Smooth-Parkour
- Type : animation run R15.
- Creator Store : Get Model.
- Intérêt : benchmark cadence, posture, stride, perception vitesse.
- Attente Claude : comparer à nos run/sprint et Motion Lab ; ne garder que si silhouette/appuis supérieurs.

### B3 — R15 Best Walk Animation Run Cycle Movement — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/86919821466305/R15-Best-Walk-Animation-Run-Cycle-Movement
- Type : walk/run R15.
- Creator Store : Get Model.
- Intérêt : cadence et distinction walk/run/sprint.
- Limites : claims marketing, aucune validation qualité.

### B4 — Realistic Run Animation R15 Movement Sprint Action — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/124801344025446/Realistic-Run-Animation-R15-Movement-Sprint-Action
- Type : run/sprint R15.
- Creator Store : Get Model.
- Intérêt : sensation de vitesse, posture sprint.

### B5 — R15 Run Sprint Dash Jog Anim — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/136638246320065/R15-Run-Sprint-Dash-Jog-Anim-City-Party-Decor
- Type : animation/système R15 avec script.
- Creator Store : Get Model.
- Intérêt : run/sprint/dash comme référence.
- Sécurité : auditer le script avant Play.

### B6 — R15 Animate Script with proper running/walking — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/10708027363/R15-Animate-Script-with-proper-running-walking
- Type : Animate script + 26 animations.
- Creator Store : Get Model.
- Intérêt : séparation run/walk par vitesse, animation speed scaling.
- Limites : ancien et reviews signalant casse ; référence technique uniquement.

### B7 — SimpleAnimation [R15] — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/11720399759/SimpleAnimation-R15
- Type : système animation R15 simplifié.
- Creator Store : Get Model ; 94% / 200+ votes lors de la recherche.
- Contenu : animations R15 simplifiées, footsteps/footprints.
- Intérêt : architecture Animate/footstep et événements de pas, pas comme moteur de combat.

### B8 — Movement System Crouch + Sprint R6/R15 — DevForum — open source
- URL : https://devforum.roblox.com/t/movement-system-crouch-sprint-client-server-r6-r15/1557656
- Type : ressource communautaire open source.
- Contenu : sprint, crouch, custom animation loading.
- Intérêt : faible à moyen ; simplicité client/server et locomotion de base.

## Priorité C — animations/banques à inspecter avec prudence

### C1 — Dynamic R15 Combat Punch Animations — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/92337383665096/Dynamic-R15-Combat-Punch-Animations
- Type : modèle avec scripts.
- Creator Store : Get Model.
- Intérêt : punches/impact/poses.
- Sécurité : audit scripts obligatoire avant exécution.

### C2 — R15 Animations For Fighting Games — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/15779207139/R15-Animations-For-Fighting-Games
- Type : modèle/script R15.
- Creator Store : Get Model.
- Intérêt : référence secondaire ; inspecter contenu réel car métadonnées peu détaillées.

### C3 — {R15} Punching Animation — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/945569449
- Type : animation punch R15 ancienne.
- Creator Store : Get Model.
- Intérêt : benchmark historique seulement ; faible priorité.

### C4 — All R15 Animations — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/1006571914/All-R15-Animations
- Type : très grosse banque R15 ancienne.
- Creator Store : Get Model ; métadonnées indiquent ~590 animations / nombreux scripts.
- Intérêt : recherche de silhouettes/transitions seulement.
- Sécurité : **ne jamais exécuter la banque brute dans le projet** ; inspecter dans place jetable, scripts désactivés/supprimés au besoin.

### C5 — [R15] Animation Pack — Creator Store — gratuit
- URL : https://create.roblox.com/store/asset/15289775655/R15-ANIMATION-PACK
- Type : pack animations R15.
- Creator Store : Get Model ; reviews globalement positives lors de la recherche.
- Intérêt : locomotion/poses génériques à inventorier.
- Limites : vérifier droits d'utilisation détaillés avant redistribution/modification.

## Priorité D — architecture/réseau/futur, pas pour améliorer immédiatement le feel

### D1 — Actor-System competitive character experiment — DevForum — open source
- URL : https://devforum.roblox.com/t/open-source-server-authority-actor-system-competitive-character-experiment/4857849
- Type : expérimentation Server Authority / prediction Roblox.
- Intérêt : futur `NET-001`, PvP compétitif, séparation visual rig / actor gameplay.
- Ne pas intégrer dans la passe feel actuelle ; garder comme référence future.

### D2 — Dodo6060/TestRoGame — GitHub public, licence non trouvée
- URL : https://github.com/Dodo6060/TestRoGame
- Type : combat MVP R15-compatible, server-authoritative, config-driven.
- Intérêt : architecture simple de hitbox/server authority.
- Licence : non trouvée lors de la recherche → **reference-only** tant que non clarifiée.

## Ressources trouvées mais exclues de l'intégration directe

### YouTube — Free Advanced R15 GPO Fist Combat System
- URL : https://www.youtube.com/watch?v=569mVTr9ZK0
- Montre dash/sprint/combos/specials R15.
- La description indique un système gratuit mais contient aussi des restrictions de copyright/personnal use. Utiliser **uniquement comme référence vidéo**, pas comme source à copier ou redistribuer sans autorisation claire.

### YouTube — Free R15 Sword Combat System/Kit V2
- URL : https://www.youtube.com/watch?v=uqfCfMYxksM
- Présenté open source/free dans la vidéo, mais la description contient des restrictions de reproduction. Référence feeling/flow uniquement jusqu'à clarification de licence.

### Ressources R6
- Tout système explicitement R6 est exclu de l'intégration technique directe dans Ninja Duel.
- Il peut rester référence de feel/timing/camera uniquement si exceptionnel.

### Ressources payantes
- Exclues de ce catalogue gratuit, même si pertinentes : Camera/Movement R15 System ($6.99), Advanced Movement System ($2.99), High-Tier Movement Pack ($11.99), etc.

## Procédure d'audit Claude

Pour chaque ressource candidate :

1. confirmer R15 réel et type de rig ;
2. confirmer gratuité et licence/droits avant copie ;
3. ouvrir dans **place Studio isolée**, jamais directement dans Ninja Duel ;
4. inspecter tous les Scripts/LocalScripts/ModuleScripts avant Play ;
5. pour animation : tester normal + 0.25x/ralenti ; vérifier appui → bassin → torse → membre → contact → recovery ;
6. vérifier foot sliding, root displacement, cadence, momentum, cancel/transition ;
7. pour combat : comparer startup/active/recovery, hit detection, defense, clash, buffer et feedback ;
8. pour mouvement : comparer run/sprint, air control, jump arc, wall flow, landing, camera/FOV ;
9. classer `USE_DIRECTLY`, `ADAPT`, `REFERENCE_ONLY`, `REJECT` avec justification ;
10. si retenu, lier l'usage à `MOV-*`, `COM-*`, `DEF-*`, `CAM-*`, `LAB-*` et documenter la preuve Studio avant intégration.

## Critère Ninja Duel

Le but n'est pas de maximiser le nombre de ressources importées. Le but est de donner à Claude un éventail externe assez large pour qu'il puisse remplacer ou améliorer les briques faibles, surtout les coups qui ressemblent actuellement à de la danse, les transitions trop simples, la locomotion sans sensation de vitesse et les sauts trop Roblox. Une ressource n'est bonne que si elle rapproche le jeu de :

`mouvement lisible + appuis crédibles + vitesse ressentie + contact lourd + transition fluide + profondeur contextuelle + identité propre aux quatre personnages`.
