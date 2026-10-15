MISSION : WEAPON FORGE TYCOON — V0 COMMERCIALISABLE

Repo GitHub source de vérité :
francoisdebono8-rgb/roblox-dev

IMPORTANT :
- Utilise le GITHUB DISTANT comme source de vérité, pas une éventuelle copie locale obsolète.
- Commence par git fetch origin --prune et identifie la branche distante principale actuelle.
- Crée une branche dédiée depuis le HEAD distant actuel :
  codex/weapon-forge-tycoon-v0
- Nouveau projet isolé :
  games/weapon-forge-tycoon/
- NE TOUCHE PAS à Ninja Duel, Motion Lab, Forge Studio ou aux autres jeux/plugins.
- Tu dois construire le jeu, pas seulement écrire un document de conception.
- Travaille en autonomie.
- Ne demande pas une validation entre chaque étape.
- Si une petite décision n'est pas spécifiée, choisis l'option la plus simple qui respecte cette spec et documente-la.
- Aucun scope creep.
- Objectif = version réellement jouable, présentable et monétisable, pas une démo technique grise.

==================================================
1. OBJECTIF PRODUIT
==================================================

Construire un mini-jeu Roblox commercial simple mais suffisamment propre pour être publié et testé auprès de vrais joueurs :

WORKING TITLE :
"Forge & Flex ⚒️ Weapon Tycoon"

Pitch :
FORGE des armes → obtiens des raretés/mutations → MERGE tes armes → VENDS-les ou EXPOSE-les dans ton armurerie → améliore ta forge → débloque de nouvelles zones → prestige.

Le jeu doit être compréhensible en moins de 10 secondes.

Il ne doit PAS ressembler à :
- une baseplate avec des boutons Roblox par défaut ;
- un prototype de développeur ;
- une accumulation de Parts grises ;
- une UI de debug ;
- un jeu dont la monétisation est ajoutée après coup.

Il doit ressembler à un petit jeu Roblox volontairement simple mais cohérent, satisfaisant et déjà publiable.

==================================================
2. RÉFÉRENCES PRODUIT
==================================================

Ne copie aucun asset/code propriétaire.

Utilise uniquement leurs idées de boucle/UX comme benchmark.

A. Forge a Weapon
Place ID : 126625214460461

À observer conceptuellement :
- métal → forge → arme ;
- vente ou conservation ;
- rare VFX ;
- valeur de collection/flex ;
- progression même hors ligne.

B. Forge Master
Place ID : 72670175932716

À retenir :
- forge aléatoire ;
- mutations intéressantes ;
- armes à collectionner/exposer ;
- boucle simple sans combat obligatoire.

C. Weapon Factory Tycoon
Place ID : 90885889120938

À retenir :
- progression visuelle claire ;
- production → argent → amélioration → expansion ;
- toujours montrer le prochain objectif.

D. Marble Merge Tycoon
Place ID : 11796791326

À retenir :
- merge immédiatement compréhensible ;
- progression continue ;
- multiplicateurs ;
- leaderboard / prestige comme objectif long terme.

E. Untitled Forge
Place ID : 89357660029295

À retenir UNIQUEMENT pour le "feel" :
- métal chaud ;
- coups de marteau ;
- forge ;
- trempe ;
- sensation physique/satisfaisante.

NE PAS reproduire sa complexité artisanale complète.

F. +1 Gun Forge
Place ID : 75687962646869

À retenir :
- grande collection ;
- rarités ;
- progression visible ;
- rebirth ;
- offline progress.

NE PAS ajouter les zombies/boss/fighting dans notre V0.

==================================================
3. JOUEUR CIBLE
==================================================

Joueur Roblox simulation/tycoon/incremental.

Il doit immédiatement comprendre :

"Je forge une arme.
Elle peut être rare.
Je peux la vendre ou la garder.
Si je garde mes meilleures armes, ma forge devient meilleure.
Je veux voir la prochaine arme."

La motivation n'est pas une histoire complexe.

La motivation est :
- nombres qui montent ;
- nouvelle arme ;
- meilleure rareté ;
- mutation rare ;
- nouvelle zone ;
- armurerie plus impressionnante ;
- prochain upgrade ;
- prestige.

==================================================
4. CORE LOOP — NON NÉGOCIABLE
==================================================

LOOP PRINCIPALE :

FORGE
↓
REÇOIT UNE ARME
↓
RARITÉ / MUTATION
↓
DÉCISION :
SELL / DISPLAY / KEEP FOR MERGE
↓
COINS
↓
UPGRADES
↓
MEILLEURS BLUEPRINTS / MEILLEURE FORGE
↓
ZONE SUIVANTE
↓
PRESTIGE
↓
RECOMMENCER PLUS EFFICACEMENT

Le joueur ne doit jamais avoir plus de ~30 secondes sans :
- récompense ;
- décision ;
- progression visible ;
- nouvel objectif proche.

==================================================
5. PREMIÈRES 10 MINUTES
==================================================

Pacing attendu :

0–10 sec :
- joueur spawn directement devant sa forge ;
- tutoriel très court ;
- gros bouton / indication "FORGE YOUR FIRST WEAPON".

<30 sec :
- première arme obtenue.

<60 sec :
- première vente ET premier upgrade.

2–4 min :
- première rareté supérieure ou mutation intéressante.

3–5 min :
- joueur comprend l'intérêt du Display Rack.

5–10 min :
- plusieurs armes découvertes ;
- armurerie commence à être visuellement différente ;
- joueur voit clairement l'objectif Zone 2.

Zone 2 cible :
~8–12 minutes pour un joueur normal.

Zone 3 cible :
~25–35 minutes.

Premier prestige :
~45–60 minutes.

Ce sont des objectifs de tuning, pas des contraintes absolues si le playtest montre mieux.

==================================================
6. FORGING GAMEPLAY
==================================================

La forge ne doit PAS être un simple TextButton "Generate Sword".

Interaction physique minimale :

1. Le joueur démarre une forge.
2. Le métal chauffe.
3. Une barre/progression très courte s'affiche.
4. 3 impacts de marteau sont joués.
5. Étincelles + petit impact caméra/UI.
6. Arme apparaît encore chaude.
7. Révélation du résultat :
   COMMON / UNCOMMON / RARE / EPIC / LEGENDARY / MYTHIC.
8. Si mutation :
   reveal supplémentaire.

Interaction manuelle :
- un bouton/tap de marteau accélère légèrement chaque étape ;
- compatible souris/touch/controller ;
- pas de skill-check frustrant.

Auto Forge Game Pass :
- répète automatiquement le processus ;
- le joueur peut toujours regarder la révélation ;
- ne doit pas provoquer du spam VFX ingérable.

Le forging doit être satisfaisant :
- chaleur ;
- glow ;
- sparks ;
- impact ;
- squash/scale UI ;
- son hooks ;
- reveal.

S'il n'y a pas encore d'audio validé :
- créer le système SoundConfig ;
- ne PAS inventer de faux asset IDs ;
- le jeu doit fonctionner sans erreur sans les sons.

==================================================
7. ARMES V0
==================================================

Minimum 9 silhouettes différentes.

ZONE 1 — VILLAGE FORGE
1. Rusted Shortsword
2. Iron Saber
3. Steel Axe

ZONE 2 — MAGMA FOUNDRY
4. Ember Dagger
5. Magma Hammer
6. Obsidian Greatsword

ZONE 3 — ARCANE FORGE
7. Arcane Katana
8. Void Scythe
9. Runic Greatblade

IMPORTANT :
ne pas faire neuf rectangles avec une couleur différente.

Construire des silhouettes low-poly propres avec :
- WedgeParts ;
- Cylinders ;
- Parts ;
- guards ;
- handles ;
- blade width/length différents ;
- proportions distinctes.

Une arme doit être reconnaissable juste par sa silhouette.

==================================================
8. RARETÉS
==================================================

Raretés :

Common
Uncommon
Rare
Epic
Legendary
Mythic

Multiplicateurs de valeur initiaux :

Common = x1.00
Uncommon = x1.35
Rare = x2.00
Epic = x3.50
Legendary = x6.00
Mythic = x10.00

Les probabilités doivent être CENTRALISÉES dans Config et facilement tunables.

Ne pas disperser les valeurs dans plusieurs scripts.

Les meilleures raretés doivent avoir :
- reveal plus impactant ;
- VFX plus visible ;
- présentation inventory différente ;
- aura légère en Display Rack.

Pas de VFX qui aveuglent.

==================================================
9. MUTATIONS
==================================================

Ajouter quelques mutations rares séparées de la rareté.

V0 :
- Heated
- Frozen
- Arcane
- Glitched

Elles changent :
- apparence ;
- VFX ;
- valeur.

Elles NE changent pas le gameplay puisqu'il n'y a pas de combat.

Mutation roll doit être serveur-authoritative.

Avoir un Legendary Glitched doit immédiatement donner envie de le garder/exposer.

==================================================
10. SELL / DISPLAY / INVENTORY
==================================================

Après chaque forge :
boutons clairs :

SELL
DISPLAY
KEEP

SELL :
coins immédiats.

KEEP :
va dans inventory.

DISPLAY :
si slot disponible, l'arme apparaît physiquement dans l'armurerie du joueur.

DISPLAY RACK :
- plusieurs slots visibles dans le monde ;
- les meilleures armes exposées génèrent un petit passive income ;
- le joueur peut retirer/remplacer une arme ;
- nom + rarity visible en regardant/interagissant ;
- les autres joueurs peuvent voir les racks.

La collection physique doit être une partie importante du plaisir.

DISPLAY income :
doit aider mais ne doit pas remplacer complètement la forge active.

==================================================
11. MERGE
==================================================

Le merge doit être très simple.

Ne PAS construire un système drag-and-drop compliqué.

Bouton :
"QUICK MERGE"

Règle V0 recommandée :
3 armes d'une même rareté → 1 arme de la rareté suivante.

Le système choisit uniquement des armes non exposées et non verrouillées.

Avant confirmation :
montrer clairement les 3 objets consommés et le résultat attendu.

Possibilité :
LOCK WEAPON
pour empêcher vente/merge accidentels.

Auto Merge Game Pass :
effectue automatiquement les merges valides selon les préférences du joueur.

Ajouter dans Settings :
Auto Merge max rarity :
Uncommon / Rare / Epic etc.

Ne jamais auto-merge un item verrouillé ou exposé.

==================================================
12. ÉCONOMIE
==================================================

Une seule monnaie principale :
COINS.

Pas de 5 currencies dans la V0.

Toutes les valeurs doivent être configurables.

Créer un EconomyConfig unique contenant :
- base weapon values ;
- upgrade costs ;
- zone unlock costs ;
- rarity multipliers ;
- mutation multipliers ;
- display income ;
- prestige multipliers ;
- forge speed curve.

Objectifs :
upgrade très fréquent au début ;
ralentissement progressif ;
jamais de mur de 20 minutes sans décision.

Zone 2 :
ordre de grandeur initial ~2,500 coins.

Zone 3 :
~25,000 coins.

Prestige :
ordre de grandeur initial ~150,000 coins.

Ces nombres doivent être facilement tunables après simulation.

==================================================
13. UPGRADES
==================================================

Pas 40 systèmes.

V0 = upgrades clairs :

FORGE SPEED
VALUE
LUCK
DISPLAY INCOME
INVENTORY CAPACITY

Chaque upgrade :
- niveau visible ;
- prix suivant ;
- effet exact ;
- feedback immédiat.

Éviter les upgrades minuscules du genre +0.1% invisibles.

Le joueur doit sentir l'amélioration.

==================================================
14. ZONES
==================================================

Trois environnements.

ZONE 1 — VILLAGE FORGE
Look :
- pierre ;
- bois ;
- fer ;
- feu chaud ;
- atelier artisanal.

ZONE 2 — MAGMA FOUNDRY
Look :
- roche sombre ;
- magma ;
- métal industriel ;
- chaleur ;
- orange/rouge intense.

ZONE 3 — ARCANE FORGE
Look :
- pierre sombre ;
- cristaux ;
- énergie magique ;
- bleu/violet ;
- plus mystérieux.

Chaque zone doit changer visuellement la forge.

Ne pas simplement changer la couleur du sol.

==================================================
15. MONDE MULTIJOUEUR
==================================================

Server size cible :
6 joueurs.

Un plot personnel par joueur autour d'un hub central.

Auto-assign du plot à l'arrivée.

Chaque plot :
- forge ;
- anvil ;
- racks ;
- sell station ;
- upgrade station ;
- portes vers extensions Zone 2/3.

Les joueurs doivent pouvoir voir les belles armes des autres.

Pas de PvP.
Pas de vol.
Pas de trading V0.

Désactiver/limiter collisions joueur-joueur si elles gênent.

==================================================
16. PRESTIGE
==================================================

Après progression suffisante :
"MASTER FORGE / PRESTIGE"

Le prestige reset :
- coins ;
- upgrades économiques principaux ;
- zone progression.

Il conserve :
- collection découverte ;
- statistiques ;
- cosmetics ;
- Robux purchases ;
- prestige count.

Prestige donne :
- multiplicateur permanent raisonnable ;
- badge visuel / étoile ;
- légère amélioration de chance ou vitesse.

Le prestige doit être expliqué AVANT confirmation.

Confirmation en deux étapes.
Pas de reset accidentel.

==================================================
17. OFFLINE PROGRESS
==================================================

Ajouter offline income simple.

Calcul serveur :
temps depuis LastSeen.

Cap gratuit initial :
2 heures.

Basé principalement sur les Display Racks / progression actuelle.

Au retour :
popup propre :
"YOUR FORGE WORKED WHILE YOU WERE AWAY"
+ montant.

Pas de récompense infinie.
Pas de calcul client.

==================================================
18. UI — EXIGENCE QUALITÉ
==================================================

INTERDIT :
- boutons Roblox par défaut ;
- textes mal alignés ;
- rectangles gris ;
- 10 popups simultanées ;
- fenêtre couvrant 90% de l'écran ;
- menus non responsives ;
- debug text en production.

Direction :
fantasy blacksmith premium/simple.

Palette :
- fond charbon/noir chaud ;
- surfaces métalliques ;
- accents orange forge ;
- accent rarity uniquement quand nécessaire.

Arcane zone peut introduire bleu/violet.

Fonts :
maximum 2 familles/styles cohérents.
Privilégier fonts Roblox natives lisibles.

Utiliser proprement :
UICorner
UIStroke
UIGradient
UIPadding
UIListLayout
UIScale
UIAspectRatioConstraint si nécessaire.

Animation UI :
0.15–0.25 sec généralement.
Hover/tap subtil.
Scale légère.
Pas d'animation lente qui bloque.

HUD :

TOP :
Coins
Prestige
Zone / Forge Level

BOTTOM :
Inventory
Collection
Upgrades
Shop
Settings

Forge interaction :
grande information contextuelle au centre/bas mais pas HUD permanent géant.

Inventory :
grid propre.
Chaque carte :
- ViewportFrame arme ;
- nom ;
- rarity ;
- mutation ;
- value ;
- lock icon.

Collection :
silhouettes des armes non découvertes.
% completion.
Découvertes = visibles.

Shop :
clair.
Pas de faux countdown.
Pas de "90% OFF" mensonger.

==================================================
19. RESPONSIVE
==================================================

Desktop + mobile obligatoires.

Support controller souhaité.

Touch targets assez grands.

Tester :
16:9 desktop
petit écran mobile
portrait si Roblox l'autorise dans la config retenue
console/controller navigation basique.

Aucune info critique ne doit dépendre du hover.

==================================================
20. VFX / GAME FEEL
==================================================

Le jeu est simple, donc le FEEL est important.

Créer :
- sparks impact ;
- metal heat gradient/glow ;
- short shockwave au craft ;
- rarity reveal ;
- weapon floating reveal ;
- merge burst ;
- zone gate unlock ;
- coin gain feedback.

Camera :
très légère impulsion sur forge/merge.
Jamais de shake constant.

Limiter nombre de particules.
Prévoir mode Low VFX.

==================================================
21. MONÉTISATION V0
==================================================

Tout doit être piloté par MonetizationConfig.

Ne hardcode jamais un prix affiché si MarketplaceService peut fournir le prix réel.

GAME PASSES recommandés :

1. AUTO FORGE
prix cible : 99 Robux

2. AUTO MERGE
prix cible : 129 Robux

3. 2X COINS
prix cible : 149 Robux

4. +2 DISPLAY SLOTS
prix cible : 79 Robux

5. STARTER PACK
prix cible : ~49 Robux
one-time
contenu :
- petit boost coins ;
- boost luck temporaire ;
- cosmetic hammer/forge accent si faisable.

Ne pas afficher 15 passes au lancement.

DEVELOPER PRODUCTS repeatables :

A. Instant Coins Small
~29 R$

B. Instant Coins Medium
~79 R$

C. Instant Coins Large
~199 R$

IMPORTANT :
éviter les montants fixes qui deviennent inutiles en endgame.

Si possible, calculer le grant comme l'équivalent approximatif de :
Small = quelques minutes d'income actuel
Medium = ~20 min
Large = ~60 min

avec floors/caps sécurisés.

Boosts possibles SI architecture simple :
- Lucky Forge 10 min
- Forge Frenzy 10 min

Mais P0 = passes + coin packs avant extras.

==================================================
22. RÈGLES MONÉTISATION
==================================================

La boutique doit être visible sans être agressive.

Interdit :
- popup Robux au spawn ;
- purchase prompt sans action utilisateur ;
- faux prix barrés ;
- faux stocks ;
- fausse urgence ;
- boutons trompeurs ;
- faire passer un bouton Robux pour un bouton Coins.

Le joueur doit obtenir une vraie boucle gratuite complète.

Première mise en avant commerciale :
après qu'il ait compris le jeu, idéalement après tutoriel/premières forges.

Maximum une suggestion commerciale non bloquante dans les premières minutes.

==================================================
23. MARKETPLACE / ACHATS — TECHNIQUE
==================================================

Game Passes = avantages permanents.

Developer Products = achats répétables.

MarketplaceService :
- centraliser IDs ;
- GetProductInfo pour prix/metadata ;
- PromptGamePassPurchase ;
- PromptProductPurchase.

Developer Products :
- traiter les achats par ProcessReceipt côté serveur ;
- validation stricte ;
- idempotency ;
- ne jamais grant uniquement depuis PromptProductPurchaseFinished côté client.

Aucun achat ne doit pouvoir être accordé deux fois à cause d'un reconnect/retry.

Si l'expérience n'est pas encore publiée et que les Product IDs n'existent pas :
- laisser des placeholders propres dans MonetizationConfig ;
- désactiver gracieusement l'achat correspondant ;
- créer SETUP_MONETIZATION.md avec chaque produit à créer, type, nom, prix cible et emplacement où coller son ID.

Le jeu doit fonctionner gratuitement avec IDs nil.

==================================================
24. SAUVEGARDE
==================================================

DataStore robuste.

Sauvegarder :
- Coins
- Upgrades
- Zones
- Inventory
- Displayed weapons
- Collection discoveries
- Prestige
- Purchase-owned permanent effects si nécessaire
- Settings
- LastSeen
- lifetime stats

Versionner schema.

Autosave.
PlayerRemoving.
BindToClose.
Retry/backoff.

Toute économie serveur-authoritative.

Client n'envoie jamais :
"give me 10000 coins".

Client envoie :
"request forge"
"request sell weaponId"

Serveur valide.

==================================================
25. ANTI-EXPLOIT
==================================================

Serveur décide :
- RNG ;
- rarity ;
- mutation ;
- craft cooldown ;
- weapon creation ;
- sell value ;
- merge ;
- coins ;
- upgrade ;
- prestige ;
- purchases.

Ajouter rate limits simples sur RemoteEvents.

IDs uniques pour chaque weapon inventory item.

Empêcher :
- double sell ;
- double merge ;
- sell item displayed ;
- merge item locked ;
- spam forge ;
- negative quantities ;
- arbitrary upgrade level ;
- duplicate receipts.

==================================================
26. TUTORIEL
==================================================

MAXIMUM ~45 secondes si joueur suit normalement.

Étapes :

1. FORGE
2. révélation arme
3. SELL
4. BUY FIRST UPGRADE
5. FORGE SECOND WEAPON
6. expliquer en une phrase DISPLAY / MERGE
7. joueur libre

Pas de dialogue PNJ de 12 pages.

Pointers/Highlights.
Progress visible 1/5 etc.

Skip possible après première session.

==================================================
27. SHOP UX
==================================================

Boutique avec 3 tabs max :

PERMANENT
BOOSTS
COINS

Chaque item :
- icon ;
- nom ;
- bénéfice extrêmement clair ;
- prix réel ;
- CTA.

Mettre un petit badge "Popular" ou "Best Value" UNIQUEMENT de manière cohérente, pas sur tout.

Starter pack présenté séparément mais non bloquant.

==================================================
28. RETENTION SIMPLE
==================================================

Ne construis PAS un système daily quests complexe.

P0/P1 possibles :

- Daily login chest très simple ;
- Collection completion ;
- Prestige ;
- offline income ;
- leaderboard lifetime value / prestige.

Si cela risque de retarder P0, daily reward et leaderboard passent après publication.

==================================================
29. ANALYTICS / FUNNEL
==================================================

Instrumenter au minimum, avec API Roblox actuelle appropriée :

session_start
tutorial_start
tutorial_complete
first_forge
first_sell
first_upgrade
first_merge
first_display
zone_2_unlock
zone_3_unlock
prestige
shop_open
purchase_prompt
purchase_success

Ajouter aussi durée/session ou points permettant de l'analyser via Roblox analytics.

Objectif :
pouvoir répondre après les premiers vrais joueurs :
- comprennent-ils le jeu ?
- où quittent-ils ?
- atteignent-ils Zone 2 ?
- ouvrent-ils le shop ?
- quels produits intéressent ?
- combien arrivent à 10 minutes ?

==================================================
30. ART DIRECTION — NE PAS ÊTRE MOCHE
==================================================

Pas besoin d'un artiste 3D, mais il faut une intention visuelle.

Construire le monde comme un mini-diorama stylisé.

Règles :

- proportions volontairement stylisées ;
- gros éléments lisibles ;
- pas de réalisme maladroit ;
- matériaux cohérents ;
- warm lighting dans Zone 1 ;
- magma contrasté Zone 2 ;
- arcane plus magique Zone 3 ;
- sol propre ;
- bordures/props ;
- enclumes ;
- furnace ;
- racks ;
- barrels/crates/chains décoratifs simples ;
- silhouettes distinctes.

Pas de map vide immense.

La densité visuelle doit être autour du joueur.

Créer les props principalement à partir de primitives Roblox propres.

Si tu utilises un modèle Creator Store :
- vérifier provenance ;
- inspecter ;
- supprimer/auditer tous scripts ;
- ne jamais introduire un modèle scripté inconnu directement dans le jeu.

==================================================
31. LIGHTING
==================================================

Faire un pass Lighting réel :

- Atmosphere légère si utile ;
- ColorCorrection légère ;
- Bloom très mesuré pour forge/rare weapons ;
- shadows ;
- contraste suffisant ;
- ne jamais rendre l'expérience trop sombre sur mobile.

Tester dans Studio.

==================================================
32. PERFORMANCE
==================================================

Cible mobile.

Éviter :
- milliers de particules ;
- boucles Heartbeat inutiles ;
- une boucle par weapon ;
- trop de physical parts non anchored ;
- clones de VFX jamais nettoyés.

Object pooling si nécessaire.
Debris/Cleanup.
Streaming si utile mais ne pas surarchitecturer.

Displayed weapons anchored/non-collidable.

==================================================
33. ACCESSIBILITÉ / SETTINGS
==================================================

Settings minimum :
Music
SFX
Low VFX
Camera Shake
Auto Merge threshold si pass possédé

Ne pas bloquer gameplay si audio désactivé.

==================================================
34. TITLE / DESCRIPTION PRÉPARÉS
==================================================

Préparer dans PUBLISH_CHECKLIST.md :

TITLE :
Forge & Flex ⚒️ Weapon Tycoon

DESCRIPTION PROPOSÉE :

⚒️ FORGE powerful weapons
✨ Discover RARE mutations
🔀 MERGE weapons into better rarities
🏛️ DISPLAY your best creations for passive income
💰 SELL the rest and upgrade your forge
🔥 Unlock Magma & Arcane Forges

Can you forge a MYTHIC weapon?

Optimiser sans spam de mots-clés.

==================================================
35. ICON / THUMBNAILS SPECS
==================================================

Codex ne doit pas produire une image affreuse automatiquement juste pour cocher une case.

Préparer specs précises.

ICON :
- close-up Legendary/Mythic sword ;
- anvil below ;
- sparks ;
- dark forge background ;
- très lisible petit ;
- pas de petit texte.

THUMBNAIL 1 :
large forge + weapon reveal.
Message visuel :
FORGE → MERGE → FLEX

THUMBNAIL 2 :
3 weapons progression :
Common → Epic → Mythic.

THUMBNAIL 3 éventuel :
player's armory full of glowing weapons.

Créer un THUMBNAIL_BRIEF.md prêt à donner à un générateur d'image/designer.

==================================================
36. SOUND
==================================================

Prévoir hooks pour :

hammer_hit
forge_fire
quench
rarity_reveal
legendary_reveal
merge
coins
upgrade
zone_unlock
button_click

Ne pas inventer des IDs.

==================================================
37. STRUCTURE CODE ATTENDUE
==================================================

Architecture claire, pas 1 script de 5000 lignes.

Exemple logique :

Shared/
  Config/
    EconomyConfig
    WeaponConfig
    RarityConfig
    MonetizationConfig
  Types / utilities

Server/
  DataService
  ForgeService
  EconomyService
  InventoryService
  MergeService
  DisplayService
  UpgradeService
  PrestigeService
  MonetizationService
  PlotService
  AnalyticsService wrapper

Client/
  UI controller
  Forge controller
  Inventory controller
  Shop controller
  Tutorial controller
  Effects controller
  Settings controller

World/
  procedural/simple map builder if repo workflow benefits from it.

Adapte au repo si une meilleure convention existe.

==================================================
38. TESTS
==================================================

Tests obligatoires au minimum :

- rarity probability config valid ;
- mutation config valid ;
- economy never negative ;
- cannot sell same weapon twice ;
- cannot merge consumed weapon ;
- cannot merge locked/displayed ;
- forge cooldown enforced ;
- upgrades respect max level ;
- zone unlock once ;
- prestige reset correct fields only ;
- purchases idempotent ;
- save/load serialization ;
- old schema migration graceful ;
- offline income capped ;
- pass benefit applied once ;
- missing product IDs do not crash.

Faire aussi des simulations économie sans Studio :
- 10 min progression ;
- 30 min ;
- 60 min ;
- vérifier qu'il n'y a pas de mur absurde ou inflation immédiate.

==================================================
39. PLAYTEST STUDIO
==================================================

Ne t'arrête PAS à "les tests passent".

Faire plusieurs Play Solo / Start Server si disponible.

Vérifier visuellement :

- spawn ;
- tutoriel ;
- première forge ;
- reveal ;
- sale ;
- inventory ;
- display ;
- merge ;
- upgrades ;
- zone unlock ;
- death/respawn ;
- rejoin/save ;
- mobile emulation ;
- shop ;
- absence d'erreurs Output.

Corriger les problèmes constatés.

==================================================
40. CRITÈRES DE QUALITÉ AVANT FIN
==================================================

Le jeu n'est PAS fini si :

- on ne sait pas quoi faire au spawn ;
- la première arme met trop longtemps ;
- UI ressemble à du debug ;
- forge n'a aucun feedback ;
- armes se ressemblent toutes ;
- shop casse avec IDs nil ;
- sauvegarde peut dupliquer items ;
- mobile UI déborde ;
- map ressemble à une baseplate ;
- le joueur n'a aucune raison de garder une arme ;
- Zone 2 n'est pas visible comme objectif ;
- aucun produit n'est préparé ;
- un exploit client peut générer coins/weapons.

==================================================
41. PRIORITÉS SI TEMPS LIMITÉ
==================================================

P0 — OBLIGATOIRE AVANT PUBLICATION

- polished forge loop
- 9 weapons
- rarity
- mutations
- sell
- display
- inventory
- quick merge
- upgrades
- 3 zones
- DataStore
- tutorial
- shop UI
- passes/products architecture
- anti exploit
- responsive UI
- basic effects
- product setup docs
- publication docs

P1 — TRÈS SOUHAITÉ

- prestige
- offline income
- collection book
- analytics
- settings
- leaderboard

P2 — APRÈS PREMIERS JOUEURS

- daily quests
- pets
- combat
- bosses
- trading
- clans
- battle pass
- many more zones
- 50 weapons

NE PAS commencer P2 avant P0 terminé.

==================================================
42. COMMIT PLAN
==================================================

Commits simples :

WFT-1 core-loop
WFT-2 progression-ui
WFT-3 shop-save
WFT-4 polish-release

Plus si nécessaire, mais noms lisibles.

==================================================
43. LIVRABLE FINAL
==================================================

À la fin je veux :

1. jeu complet dans games/weapon-forge-tycoon/
2. build ouvrable/testable dans Roblox Studio
3. tests verts
4. UI fonctionnelle
5. economy config centralisée
6. monetization config centralisée
7. README
8. SETUP_MONETIZATION.md
9. PUBLISH_CHECKLIST.md
10. THUMBNAIL_BRIEF.md
11. QA_REPORT.md
12. liste EXACTE des seules actions manuelles qui me restent à faire dans Roblox Dashboard/Studio
13. HEAD SHA final
14. aucun changement dans Ninja Duel/autres projets

Dans le rapport final, sépare clairement :

DONE BY CODEX
MANUAL ROBLOX ACTION REQUIRED
OPTIONAL AFTER LAUNCH

==================================================
44. RÈGLE FINALE
==================================================

Le but n'est pas de construire "beaucoup de features".

Le but est de construire un produit très simple qui donne envie de :

FORGE AGAIN
GET A BETTER WEAPON
KEEP/FLEX IT
UNLOCK THE NEXT FORGE

Chaque feature doit servir cette boucle.

Si une feature complique fortement le jeu sans améliorer une de ces quatre motivations, ne la construis pas dans la V0.

Commence maintenant par inspecter le GitHub distant puis implémente en autonomie jusqu'au livrable.