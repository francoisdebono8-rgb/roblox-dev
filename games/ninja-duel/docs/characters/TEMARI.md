# Temari — zoning longue portée par le vent (vague d'archétypes)

Code proposé : `Gale` (absent du code). IDs : CHR-EXT-002, SYS-001/002, TOOL-006, DEF-005, ARENA-001, CAM-002.

> Fiche de conception Claude du 2026-10-16 (mission [COMBAT_CONVERGENCE_ONLINE_ROSTER](../missions/COMBAT_CONVERGENCE_ONLINE_ROSTER.md) §18–21, DEC-012/DEC-013). Rien n'est implémenté ; valeurs = points de départ à régler en natif. Code lu sur `c2d797c` (chemins relatifs à `games/ninja-duel/src/`, le nom de fonction fait foi). Sources canon « à vérifier » non confirmées. Plan : [ROSTER_WAVE_PLAN](ROSTER_WAVE_PLAN.md) ; hooks : [ROSTER_WAVE_HOOKS](ROSTER_WAVE_HOOKS.md).
>
> **Hors du pool de 25 noms** du 2026-10-13 ([ROSTER_ARCHETYPES_32](../../design_research/02_character_architecture/ROSTER_ARCHETYPES_32.md), où elle figure parmi les candidats secondaires), mais nommée explicitement par la mission utilisateur du 2026-10-16, plus récente : la demande actuelle prime (priorité normative de DECISIONS).

## Stade retenu (DEC-013)

**Examen chûnin → récupération de Sasuke (15–16 ans, à vérifier)** : grand éventail de fer aux trois lunes, Kamaitachi, vent qui balaie les armes, invocation de Kamatari (contre Tayuya) à échelle réduite. Plus âgée que le slogan « 12–14 ans » du menu (`Client/UI.luau`) : DEC-013 écarte toute limite d'âge rigide, mais le texte du menu est à harmoniser (décision utilisateur). Échelle adulte absente : rien de la jônin de Partie II.

## Pourquoi elle mérite une place (système éprouvé)

1. **Zoning à longue portée sur l'arène à l'échelle** (ARENA-001) : distances 25–60, cadrage caméra de deux corps éloignés (CAM-002), IA qui doit franchir un terrain hostile (aujourd'hui l'IA ne sait que « fermer la distance » contre une portée supérieure, `Server/AI.luau:286-292`).
2. **Zones directionnelles persistantes** (H06) qui modifient **les projectiles** (dévier, accélérer, nourrir le feu) et **le mouvement** (vent contraire/porteur) : première zone qui n'est pas un sol brûlant (`Combat:addHazard` ne connaît que des dégâts, rendus tous en feu côté client, `Client/Effects.luau:783-810`).
3. **Charge par maintien/relâchement** (H09) : la technique change de palier selon la durée du maintien — aucun input de relâchement n'existe pour les techniques.
4. **Réplication des trajectoires** : le client reconstruit chaque projectile par `origin + direction × t` ; un vent qui dévie doit tuer/recréer le projectile (comme le ricochet et la redirection Geometry le font déjà : `Combat:projectileSurface` et `Combat:projectileExpire`, `Server/Combat.luau:1160-1220`).

## Mécanique signature

**L'éventail à trois lunes** : Kamaitachi se charge par maintien — tapé = 1re lune, 0.35 s = 2e, 0.7 s = 3e (l'éventail s'ouvre visiblement : le palier est lisible et interruptible). Chaque Kamaitachi laisse un **couloir de vent** (2/3/4 s ; largeur 4/6/8 ; longueur 30/45/60) : marcher contre le vent ×0.7, avec le vent ×1.15 ; un projectile physique qui le remonte est dévié ; un projectile de feu qui le traverse **grossit** (rayon ×1.5, +20 % dégâts) — y compris contre elle.

## Fiche FIGHTER_TEMPLATE

### 1. Identité
- PROPOSÉ `Fighters.Gale` : « THE WIND FAN » (à valider), `Age = 15`, HP 130, chakra 120, regen 8, vitesse 17.5, sprint ×0.95, saut ×1.0, **air ×1.3** (vol plané), accél. ×0.95, `CombatTravel 0.9`, `PreferredRange 16` (la plus longue du roster), `Tool = "Gust"`.
- Fantasy : celle qui décide où l'on peut marcher. Rôle : zoneuse. Rythme : patient, puis punition à distance. Distance : 16–60.
- Forces : portée, contrôle de l'espace, anti-projectiles. Faiblesse : collée, canaux longs, feu adverse nourri par son vent, chakra vite vidé.
- Question : « Peux-tu m'atteindre à travers le vent ? »

### 2. Mouvement
- PROPOSÉ : stance large, éventail fermé tenu en travers du dos ou au sol ; démarche posée `stride 1.0, cadence .92, arm 18, lean 0, bob .7, guard .3` ; course latérale soignée (elle tient la distance en strafant, MOV-003).
- **Vol plané** : maintenir Saut en l'air = chute plafonnée à 12 studs/s, contrôle aérien ×1.3, éventail ouvert (H04/H09) ; pas d'attaque en planant hors Kamaitachi.
- **Rush inversé** : E hors fenêtre de poursuite = bond de repli porté par le vent (20 studs **à l'opposé** de l'adversaire, coût 10, CD 0.9). La poursuite (E dans la fenêtre) reste commune. Variante de `Combat:rush` (`:475`).
- Mur : course murale commune ; sortie de mur en plané.

### 3. Neutral / entrée en combat
- Elle ne ferme pas la distance : elle la **peint**. Poke : Kamaitachi tapé (1re lune) ; Bourrasque (outil) pour repousser.
- Forcer une réaction : un couloir de 3e lune entre elle et l'adversaire l'oblige à le contourner (latéral) ou à le traverser à ×0.7.
- Sortie : Bourrasque + rush inversé ; substitution longue.
- À respecter : la direction de chaque couloir (contre ou avec soi), l'ouverture de l'éventail (charge en cours = fenêtre pour l'interrompre).

### 4. Taijutsu et combos (H02 : éventail fermé = masse)
| Entrée | Move proposé | Fonction |
|---|---|---|
| L1 → L2 → L3 | **pointe** d'éventail (portée 7.5) → **fauche** horizontale (largeur 8) → **rafale d'éventail** (l'éventail s'ouvre : Knockback `impulseZ 70`) | la string **crée la distance** au lieu de coller ; démarrages ×1.1 |
| ↑ (≥2) | **Updraft** (pelletée vers le haut, Launched 45) | payoff `updraft` : 1.2 s de chute ralentie → conversion **à distance** (Kamaitachi tapé ou Bourrasque vers un mur) au lieu d'une poursuite |
| ↓ (≥2) | **FanSlam** (éventail fermé abattu au sol, Knockdown) | fin de string |
| ←→ (≥1) | **FanPirouette** (tour complet, souffle latéral : l'adversaire est poussé de 6 studs sur le côté) | espace latéral, termine la string |
| Lourd après 1 coup | **FanBackhand** (revers, Knockback 50) | repousser |
| Lourd neutre | abattement vertical (Knockdown) | punition |
| Air | Air1/Air2 coups d'éventail ; airUp = AirDrive ; airDown = **FanDive** (souffle vers le bas : Spiked, elle remonte légèrement) | DÉCISION : pas d'AirSwitch (elle ne passe pas de l'autre côté) |
- Le vent qui projette doit appliquer une **réaction Knockback** pour permettre le splat à distance : la branche `wind` actuelle pose une vitesse sans réaction (`Combat:projectileHit`, branche `wind`), contrairement à la paume de Neji.

### 5. Armes et ninja tools
- Arme : **grand éventail de fer** (H01 : objet tenu, fermé/ouvert selon l'action) ; il change portée, largeur et récupération des coups (pas un mesh sur un combo commun).
- **R = Bourrasque** : souffle court (cône 30°, portée 18, 0 dégât) qui repousse la cible de 6 studs et **renvoie** les projectiles physiques du cône dans sa direction (H08) ; coût 4, récupération 0.7.
- DÉCISION : ni kunai ni shuriken.

### 6. Jutsus / techniques
| Technique | Coût | Canal/actif/récup | CD | Effet | Contre-jeu |
|---|---|---|---|---|---|
| Kamaitachi (maintien) | 10 / 16 / 24 | maintien 0–0.7 + .12 / .1 / .3 | 3.5 | projectile `wind` (rayon selon la lune ; 3/5/8 dégâts ; Knockback 20/30/40) + couloir (H06) | interrompre la charge ; contourner ; avancer en diagonale |
| Mur de vent | 18 | .15 / 2.0 / .25 | 6 | zone 7×3 devant elle : détruit les projectiles physiques et les volumes non-feu, repousse l'entrée (8 studs) ; **le feu passe et grossit** | feu, saisie par le côté, attendre 2 s |
| Tourbillon ascendant | 16 | .4 retardé / .1 / .3 | 5 | cyclone à 25 studs (rayon 3) : Launched 50 + courant ascendant 1.5 s | rester en mouvement (le cyclone ne suit pas) |

### 7. Garde / défense
- **Garde-éventail** : la garde frontale arrête les projectiles physiques **sans coût de stamina** (éventail de fer) ; contre la mêlée, garde/parry communs.
- Perfect dodge : Bourrasque gratuite immédiate (repousse l'attaquant).
- Anti-air : Tourbillon, Updraft. Défense en l'air : vol plané (fuite verticale lente, donc punissable).

### 8. Esquive et substitution
- Esquive commune. **Substitution « retraite du vent »** : saut de 14 studs vers l'arrière (au lieu de 8, `Config.Substitution.Distance`) ; même coût et même suivi adverse (0.75 s), mais la poursuite de 46 studs doit traverser ses couloirs.

### 9. Rush / poursuite
- DÉCISION : pas de poursuite identitaire en mêlée. Conversion après Updraft/Knockback **à distance** (Kamaitachi tapé sur le corps qui flotte, Bourrasque vers un mur → splat).
- Casser sa « poursuite » : air dodge hors de l'axe, sortir du courant ascendant.

### 10. Chakra
- 120 / 8 ; le zoning coûte cher (3e lune 24, mur 18). Low-chakra : plus que lune 1, Bourrasque (4) et éventail : elle doit **laisser entrer** l'adversaire — état ressenti, pas un refus « Need chakra ».
- PROPOSÉ : un couloir qui dévie un projectile lui rend 2 chakra (récompense de placement).

### 11. Infusion / interactions de chakra (H07)
- `vent + projectile physique remontant le couloir → dévié` ; `vent + projectile avec le courant → +40 % vitesse, +1 dégât` ; `vent + feu → feu grossi` ; `vent + sable répandu (Gaara) → dispersé`.
- Copiable par Kakashi (Fūton, pas de kekkei genkai).

### 12. Éveil — KUCHIYOSE : KIRIKIRI MAI
- Activation : Kamatari (belette à la faucille) traverse l'arène en ligne droite (80 studs, vitesse 120) : 18 dégâts + Knockdown si elle touche (gardable, avec chip) ; laisse un couloir de 3e lune 6 s. Implémentation minimale : **un grand projectile avec modèle**, pas une entité (H12 inutile).
- Règles (12 s) : temps de maintien divisés par 2 (3e lune à 0.35 s), couloirs ×1.5 en durée, Bourrasque ×1.5 en rayon.
- Contrepartie : à la sortie, **éventail fermé** 3 s (aucune technique). Pas de multiplicateur de dégâts.

### 13. États et réactions
- Crée : Knockback (L3, revers, Kamaitachi), Launched (Updraft, Tourbillon), Spiked (FanDive), Knockdown (FanSlam, Kamatari), WallSplat **à distance** (vent → mur).
- Exploite : corps en chute ralentie (updraft), projectiles adverses (couloirs), position de l'adversaire entre elle et un mur.

### 14. Boucle de jeu
- Représentative : `16+ studs → Kamaitachi 2e lune (couloir entre eux) → l'adversaire contourne → Tourbillon sur sa ligne → Launched → Kamaitachi tapé → Bourrasque vers le mur → splat`.
- Défensive : `entrée adverse → L1 L2 L3 (rafale : distance) → rush inversé → Mur de vent`.
- Low-chakra : `taps + Bourrasque + string de distance → regen`.
- Air : `vol plané au-dessus de la mêlée → Kamaitachi vers le bas`.

### 15. Skill ceiling
- Débutant : Kamaitachi tapé en boucle.
- Intermédiaire : paliers de lune au bon moment, couloirs orientés pour bloquer les projectiles adverses, rush inversé.
- Expert : géométrie des couloirs (ne jamais offrir un vent porteur à l'adversaire, ne jamais nourrir le feu adverse), conversion à distance vers les murs, gestion du chakra pour garder une 3e lune en réserve.

### 16. Signature irremplaçable
Temari est la seule dont les techniques **réécrivent les règles de déplacement et de vol des projectiles** dans une portion d'arène pendant plusieurs secondes. Quatre jutsus à distance sur ses stats ne feraient que du *zoning par projectiles* ; elle fait du *zoning par terrain mobile*.

## Différenciation

| Axe | Temari | Minato | Itachi | Neji | Sasuke |
|---|---|---|---|---|---|
| Neutral | 16–60, couloirs | 6, sceaux | 10, shuriken | 5 | 6 |
| Mouvement | plané, rush **inversé** | rush avant, FTG | contrôlé | pas courts | saut haut |
| String | crée la distance | colle (dérive) | recule (auto) | colle | colle |
| Launcher | conversion à distance | FTG | lames | paume | chasse |
| Outils | Bourrasque (renvoie) | kunai | Geometry | kunai | fil |
| Défense | garde anti-projectiles | mobilité | lecture | Rotation | Sharingan |
| Recouvrement | **WindCut de Minato** (vent qui déplace, sans source jeune, déjà signalé redondant dans [MINATO](MINATO.md)) : proposer de le retirer ou de le recadrer une fois Temari jouable | | | | |

| Vague | Recouvrement | Ce qui les sépare |
|---|---|---|
| Gaara | zoning | Gaara fixe le sol et lie ; Temari déplace l'air et repousse |
| Kisame | zones élémentaires | les zones d'eau de Kisame le renforcent lui ; les couloirs de Temari gênent l'autre |
| Shikamaru | contrôle à distance | Shikamaru capture un corps ; Temari interdit des lignes |
| Haku | projectiles | Haku multiplie les origines de tir ; Temari modifie le vol de ceux des autres |
| Kakashi | — | peut copier Kamaitachi (palier 1 seulement, PROPOSÉ KAKASHI) |
| Lee, Naruto | — | contres naturels par la vitesse et le nombre ; les couloirs les ralentissent |

## Labels lore par capacité

| Capacité | Label | Source / justification |
|---|---|---|
| Grand éventail de fer | CANON_YOUNG | examen chûnin (Partie I) |
| Kamaitachi no Jutsu | CANON_YOUNG | préliminaires contre Tenten ; finale contre Shikamaru (ch. à vérifier) |
| Trois lunes = paliers de puissance | CANON_YOUNG (concept) | lunes révélées en ouvrant l'éventail ; formulation exacte à vérifier |
| Vent qui balaie les armes | CANON_YOUNG | contre Tenten |
| Couloirs persistants, effets sur le mouvement | GAMEPLAY_LIBERTY | traduction en zones lisibles et contournables |
| Le vent nourrit le feu | PLAUSIBLE_YOUNG | relation des natures exposée en Partie II (règle indépendante de l'âge) |
| String à l'éventail fermé | PLAUSIBLE_YOUNG | combat à l'éventail ; coups exacts non canon |
| Vol plané | GAMEPLAY_LIBERTY | usage de l'éventail en vol à vérifier |
| Rush inversé, substitution longue | GAMEPLAY_LIBERTY | identité de zoneuse ; contre-jeu : poursuite commune |
| Bourrasque, Mur de vent, Tourbillon | PLAUSIBLE_YOUNG | variations de Fūton cohérentes ; noms non canon |
| Kuchiyose : Kirikiri Mai (Kamatari) | CANON_YOUNG (échelle réduite = GAMEPLAY_LIBERTY) | contre Tayuya (ch. à vérifier) ; la forêt rasée devient un passage |
| Âge 15–16 | CANON (à vérifier) | databooks à vérifier ; hors slogan « 12–14 » |

## Plan d'implémentation

**Réutilisé** : projectile `wind` et son modèle client (`Elements.wind`, `FX.buildWind`), suppression de projectiles en zone (modèle de `Techniques.DesertWave`, `Server/Techniques.luau:395-426`), `Combat:addHazard` comme base des zones, `Combat:rush`, mode `hop` de substitution (distance paramétrée), réaction Knockback et splat (`Brawler.react`, `Brawler.splat`).

**Nouvelles données** : `Fighters.Gale` (stats §1, `Tool="Gust"`, `Glide`, `Rush={Reverse=true}`, `Substitution={Distance=14}`) ; `MoveGraphs.Gale` (`routes={up="Updraft",down="FanSlam",side="FanPirouette",airUp="AirDrive",airDown="FanDive"}`, `onRoute={Updraft="updraft"}`, `heavyAfterOne="FanBackhand"`, `disengage` = Bourrasque) ; `Attacks` : `FanTip/FanSweep/FanGust` (string propre, H02), `Updraft`, `FanSlam`, `FanPirouette`, `FanBackhand`, `FanDive` ; `Techniques` : `Kamaitachi` (paliers), `WindWall`, `Cyclone`, éveil `Kamatari` ; IA : profil zoneuse (tenir 16–30, peindre un couloir entre elle et l'adversaire, Bourrasque contre projectiles, rush inversé quand il entre).

**Hooks** : H06 (couloir vectoriel, rendu client par kind), H08 (renvoi/déviation), H09 (maintien/relâchement + état d'éventail), H04 (modificateurs de vitesse du vent, vol plané), H07 (vent × feu/sable, différable), H17 (substitution longue, rush inversé, perfect dodge → Bourrasque, `disengage` Bourrasque), H02, H03, H01.

**Motion** : stance, démarche, intro (éventail planté) ; clips propres : string FanTip/FanSweep/FanGust, Updraft, FanSlam, FanPirouette, FanBackhand, FanDive, Air1/Air2, Grab/Throw (prise d'éventail), Riposte ; poses de cast : ouverture progressive (1/2/3 lunes), Mur de vent, Tourbillon, invocation (pouce mordu + éventail) ; objet tenu éventail (fermé/ouvert).

**Effets/UI** : rendu des couloirs (lignes de vent orientées, pas de feu) ; jauge de lune pendant le maintien ; Kamatari.

**Tests** (`tests/Temari.spec.luau`) : paliers selon la durée du maintien ; couloir : vitesse contre/avec, déviation d'un kunai, feu grossi ; Bourrasque renvoie un shuriken ; rush inversé ; splat à distance via la réaction Knockback ; nettoyage des zones (fin de manche, KO) ; duels IA contre les 12 ; test sans jutsu (string de distance + Bourrasque).

**Effort** : **M** (dépend d'ARENA-001 pour les distances).

**Périmètre minimal jouable** : string d'éventail, Bourrasque, Kamaitachi à 3 paliers + couloir (vitesse + déviation), rush inversé, vol plané. Hors minimal : interactions feu/sable, Mur de vent, Tourbillon, Kamatari.

## Points à vérifier
- Âge exact et scène de chaque technique ; formulation canon des « lunes ».
- Vitesse de projectile et durée des couloirs après le re-scale d'arène (ARENA-001).
- Lisibilité caméra à 40–60 studs (CAM-002).

## État d'implémentation (2026-10-17, convergence 3)

Code de `claude/nd-vrs-temari` (base `2aba0ca`), mission [NEXT_VALIDATION_ROSTER_SCALE](../missions/NEXT_VALIDATION_ROSTER_SCALE.md) §9. Rapport, découvertes moteur et liste Studio : [TEMARI (convergence 3)](../reports/convergence3/TEMARI.md). **Validé en headless uniquement** (`tests/Temari.spec.luau`, 35 cas ; limites articulaires dans `tests/Animation.spec.luau`) : feel, lecture du vent, éventail et costume restent à juger dans Studio. Identifiant de code : **`Gale`**.

**Implémenté et jouable (sélectionnable dans le roster)**
- `Fighters.Gale` : HP 130, chakra 120, regen 8, vitesse 17,5, air ×1,3, `PreferredRange 16`, `Tool="Gust"` (aucune lame lancée), substitution « retraite du vent » 14 studs (`Substitution.Distance`), profil IA `Zoner` (bande de ~20 studs).
- String à l'éventail fermé (portée 7,5, contact à 5 studs : `AttackProfile.contact`) : pointe → fauche → **rafale** (l'éventail s'ouvre, Knockback 70 : la string fait de la distance). Routes : ↑ **Updraft** (lourd après deux coups aussi) : le corps est tenu dans une colonne d'air montant (`Zones` « Updraft ») → conversion à distance ; ↓ **Fan Slam** (Knockdown) ; ←→ **Fan Pirouette** (tour complet, le corps est jeté sur le côté demandé : `Attacks.lateral`) ; lourd après un coup = **revers** (Knockback 52). Air : ↑ AirDrive (clip à elle), ↓ **Fan Dive** (Spiked), pas d'AirSwitch.
- **Signature : zones de vent persistantes** (`Server/Zones.luau`, composant réutilisable à côté des hazards) : couloir orienté — contre le vent ×0,7, avec ×1,15 (le stick décide), le corps libre est porté (4 studs/s, 11 en l'air), une ruée chakra qui remonte le couloir **se brise** (+0,25 s de récupération ; jamais celle de la propriétaire), une lame qui le remonte est **déviée** (+2 chakra pour elle), une lame qui le descend va ×1,4 et +1 dégât, le **feu qui le traverse grossit** (rayon ×1,5, dégâts ×1,2, même contre elle) ; colonne d'air (corps lancé tenu, chute lente). Chaque changement de vol est **réannoncé** (`Combat:redirect` + continuité côté client). Rendu client en vent (`GaleFX`), jamais en feu.
- Techniques : **Kamaitachi** (12 chakra, canal 0,3 interruptible, faux de vent qui grandit, Knockback → splat mural à distance, couloir posé pendant le vol) ; **Great Gust** (22, trois lunes, cône : lames soufflées, feu nourri, corps rejeté au mur, couloir large) ; **Rising Whirlwind** (16, l'endroit est marqué, la colonne monte 0,45 s plus tard : Launched + maintien, rien si le corps a bougé). Le vent disperse le sable : faux, Great Gust et Kamatari brisent le bouclier de Gaara.
- Outil **Bourrasque** (R) : cône de 18 studs, 0 dégât, repousse le corps (Knockback), **renvoie les lames** du cône vers leur lanceur, nourrit le feu ; gratuite dans une string propre, arrière + R saute hors de la string. Modificateur chakra = infusion **Vent** de l'éventail (profil `WindFan` dans `ChakraTuning`) : plus longue, laisse un couloir ; refus avec fizzle si le chakra manque.
- Réengagement **pas de vent** (E hors fenêtre) : retour à 17 studs (sortie en angle si proche, approche sans jamais entrer en mêlée si loin, pas de côté à distance), même prix et état `Rush` que la ruée commune ; la poursuite dans une fenêtre reste commune. **Vol plané** : saut maintenu en l'air, chute plafonnée à 12 studs/s.
- Éveil **KIRIKIRI MAI** : Kamatari traverse l'arène (projectile lourd, Knockdown, long couloir) ; ensuite couloirs ×1,5 en durée et ×1,3 en largeur qui **renvoient** les lames, chaque Bourrasque pose un couloir, portée ×1,4 ; aucun multiplicateur de dégâts ; à la sortie l'éventail reste fermé 3 s (techniques refusées : « Fan closed »).
- IA : zoneuse (`AI:zone`) — faux à distance (visée anticipée), tourbillon devant l'approche, Great Gust contre une entrée, Bourrasque contre une ruée ou des lames, garde contre un coup déjà lancé, pointe d'éventail à sa portée, pas de vent pour sortir, conversion à distance d'un corps en l'air. Les IA adverses ne sondent plus à sa portée, zigzaguent, sortent d'un couloir de face et ne ruent jamais dans un couloir.
- Client : famille de mouvement `GaleMotion` (posture main sur la hanche, démarche, clips à elle pour string, routes, lourd, air, sprint ; poses de cast éventail ouvert ; superposition de la Bourrasque ; intro éventail planté), couche `GaleFX` (éventail : dos / main fermé / ouvert lune par lune / planté ; faux et Kamatari ; couloirs et colonnes ; contacts), costume `dressTemari` (quatre couettes, bandeau de Suna, kimono lilas, obi rouge, résille aux coudes et genoux, tout en SmoothPlastic).

**Décisions par rapport à la fiche**
- Pas de charge maintenir/relâcher : aucune entrée de relâchement de technique n'existe (il faudrait un nouveau message client). Les trois lunes sont l'ouverture visible de l'éventail (1 pour Kamaitachi, 2 pour le tourbillon, 3 pour Great Gust) ; un palier unique par technique.
- **Great Gust** (souffle large) remplace le Mur de vent ; le tourbillon de la fiche est implémenté.
- Saisies et projections : clips d'Itachi (repli `__index`, listé ici comme dette).

**Non implémenté**
- Charge maintenir/relâcher (H09), garde-éventail anti-projectiles, Bourrasque gratuite sur esquive parfaite, vent × sable répandu au sol, règle « couloir qui dévie : +2 chakra » en IA (le gain existe, l'IA ne le cherche pas), recadrage du Wind Cut de Minato (recouvrement signalé).
