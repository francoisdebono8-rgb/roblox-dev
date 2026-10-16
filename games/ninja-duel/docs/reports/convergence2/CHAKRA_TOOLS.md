# Chakra systémique — outils, natures, fil (CCC2 phase 5)

Branche `claude/nd-ccc2-chakra`, base `50b90bc`. Mission : [CORE_COMBAT_CONVERGENCE_2](../../missions/CORE_COMBAT_CONVERGENCE_2.md), phase 5 (chakra systémique), partie Sasuke de la phase 4 (fil / feu / foudre), phase 10, critères 13–15.

`OBJET / ACTION DU CORPS + CHAKRA + NATURE / MAÎTRISE + CONTEXTE = ACTION MODIFIÉE`, sans bouton par interaction : **un seul accord, « chakra + outil »**, et c'est la maîtrise du personnage qui décide de ce que le chakra fait. Tout est décidé côté serveur ; le client n'envoie qu'un booléen.

Rien de ce rapport n'a été vu dans Studio : toutes les preuves sont headless (règles, états, timings). Le rendu et le ressenti restent à valider (voir « À valider dans Studio »).

## Ce qui change en jeu

| Combattant | Chakra + outil | Ce qui change (comportement, pas seulement dégâts) |
|---|---|---|
| Minato | **kunai du vent** | ×1,45 en vitesse (139 au lieu de 96), ×1,7 en portée (107 au lieu de 62) ; **coupe** les lames plus légères ou égales dans sa ligne et continue ; à l'impact, pousse le corps et ouvre une fenêtre de poursuite (E) : le chakra investi dans la ré-entrée. Le feu le mange. |
| Itachi | **shuriken de feu** (la paire, ou la Geometry, ou l'éventail aérien) | enflamme le corps touché (petit feu au sol) ; un raté laisse **un point qui brûle** ; le feu **se nourrit du vent** (absorbe le kunai du vent et s'embrase : +dégâts, feu plus large) ; le ricochet garde le feu. |
| Sasuke | **shuriken de foudre** | un coup propre **étourdit plus longtemps** (≥ 0,38 s au lieu de 0,22) : de quoi enchaîner au dash ; planté, c'est **un piège électrique**. Avec le fil encore sur un corps lié : **la foudre descend le fil** (pas de lancer), la prise est prolongée, Dragon Flame (1) suit toujours. |
| Neji | **paume de chakra** (le chakra passe par le corps, jamais par une lame) | un double coup de paume court (PalmThrust) qui **chasse les lames devant lui** pendant sa sortie, et qui **traverse la garde** : chakra drainé, endurance de garde entamée, point de tenketsu fermé quand même ; un coup propre ferme un point de plus. Refusée en l'air. |
| Gaara (non CORE4) | **sable renforcé** | plus lourd (4,8), pèse sur la garde. |

**Toute lame de chakra est de l'acier renforcé** (la base commune) : plus lourde (×2), plus stable (une lame plus légère ne la dévie pas), elle **dévie** les objets plus légers qu'elle rencontre, **pèse sur la garde** (endurance −25 par kunai, −15 par shuriken, poussée, **garde brisée** quand l'endurance tombe à zéro), touche un peu plus fort (×1,25), et **reste plantée** là où elle rate (point contestable). La nature maîtrisée s'ajoute par-dessus.

Le **fil devient un objet** : un Wire Trap raté reste **tendu** du point de lancer (noué à la cheville) au point d'impact pendant 6 s. Il **lie** l'adversaire qui le traverse au sol (une roulade ou un saut passent), il **porte le feu** (une flamme qui le touche court le long et laisse une ligne de feu), la foudre de Sasuke le **charge** (lié + électrocuté), le vent (kunai du vent, Wind Cut) et la Rotation **le coupent**. Une prise par fil laisse Dragon Flame et la foudre disponibles.

Les **lames cachées du Phoenix Flower** de Sasuke sortent enflammées (elles enflamment ce qu'elles touchent, laissent un point qui brûle).

Un **lancer normal ne change pas** (vitesse, nombre, dégâts, coût, trajectoire : testé pour les cinq combattants).

## Schéma d'entrée

| | Clavier | PS5 |
|---|---|---|
| Outil normal | R | R2 |
| **Outil chakra** | **Z + R** (Z tenu, ou Z relâché < 0,3 s avant R) | **R1 + R2** |

Pourquoi :

- **PS5 R1 + R2.** R1 est déjà « le bouton chakra » de la manette (R1 + face = jutsu, R1 + L1 = détacher du mur, R1 + L2 = feinte). R1 + R2 était libre (il envoyait un outil normal). Pas de croix directionnelle, pas de nouveau bouton. R1 + face reste un jutsu (testé).
- **Clavier Z.** Touche libre collée au bloc WASD (annulaire ou auriculaire pendant que l'index est sur R), position physique (les KeyCode Roblox sont physiques : sur AZERTY c'est la touche marquée W). Accord tolérant comme le tampon d'intention directionnelle de la phase 1 : Z tenu, ou pressé juste avant R.
- **Écartés :** LeftAlt (Alt + Espace ouvre le menu système de Windows, et Espace = saut) ; Tab (liste des joueurs Roblox) ; Verr. Maj (état système) ; clic molette (inconfortable avec le clic droit = lourd) ; C (déjà le détachement du mur) ; maintenir R (retarderait chaque lancer normal) ; double appui R (le premier appui lance déjà).
- **Pourquoi seulement l'outil dans cette passe.** À la manette, chakra + lourd / esquive / saut tomberaient sur R1 + △ / ○ / × = jutsu 3 / 4 / 1. Le cadre reste donc sur l'action outil, et la maîtrise décide de l'effet : pour Neji le même accord donne une action du corps (sa paume). Le serveur n'accepte le drapeau que comme un booléen ; il est ignoré hors de l'action outil (extensible plus tard sans changer le protocole).
- L'accord clavier envoie la même visée qu'un lancer normal (point de la souris à portée, l'adversaire à la manette) : le `send` du client ne calcule pas la visée quand des extras sont passés, la branche chakra de `Input` la calcule elle-même (même règle des 140 studs que `Main.client`).
- Aide HUD : « Z + R chakra » et « R1 + R2 chakra » ajoutés aux lignes d'aide. Aucune autre UI. Un refus (chakra insuffisant) fait **pétiller le chakra à la main** (fumée grise) ; le texte « NEED CHAKRA » reste filtré par le HUD comme les autres refus.

## Architecture : ce qui vient de Codex, ce qui est écrit

**Repris de Codex (`7091585`), à l'octet près** (un portage identique en parallèle par l'agent devtools fusionne sans conflit) :

- `ChakraRules` : validation déclarative de la config (tags déclarés, effets en liste blanche, nombres finis, pas de code dans la donnée), sélection des règles (`all/any/none` sur source / cible / surface / contexte, priorité puis ID, **groupes exclusifs**), traces.
- `ChakraVectors` : requis par la validation.
- `ChakraInputPlan` : planificateur d'intention ; le mode `Modifier` choisit l'infusion proposée par la maîtrise et **refuse une proposition incompatible** avec l'objet, en gardant l'action existante.
- La sémantique `scaleStat` (facteur + bonus par niveau de maîtrise, plafonds) est reproduite dans l'adaptateur.

**Non porté** : `ChakraInteractions` (domaine-labo avec ses propres objets cinématiques) et `ChakraConfig` (fixtures du labo, `Enabled=false`) — le runtime travaille sur les vrais projectiles ; l'agent devtools les portera avec `ChakraLab/Dev/StudioView/QA`. Défaut relevé dans le moteur Codex, sans le modifier : il passe les tags de maîtrise en liste alors que le filtre attend un ensemble (une condition `when.mastery` n'aurait jamais matché) ; l'adaptateur les passe en ensemble.

**Écrit :**

- `src/Server/ChakraTuning.luau` — la donnée vivante, au format Codex et **validée par `ChakraRules` au chargement** : objets (kunai, shuriken, fil, sable, paume, volumes de jutsu), natures, infusions et coûts, **profils de maîtrise** (`CharacterMastery` : l'ID du personnage ne fait que choisir un profil), préférences par outil, 36 règles, grandeurs des effets. Un seul interpréteur, des identités différentes.
- `src/Server/ChakraCombat.luau` — l'adaptateur runtime : plan d'infusion (contexte lu dans l'état serveur, ex. « tient encore le fil »), armement du projectile, rencontres en vol (ordre temporel), contacts, surfaces, points plantés, fil tendu, paume de Neji, courant dans le fil, journal borné des décisions (`c.chakraLog`) et interrupteurs A/B (`Chakra.toggle`). Les règles choisissent des signaux nommés ; seuls les gestionnaires de ce module en font un changement de jeu, chacun borné.
- Raccords : branche `Tool` de `Combat:request` (5ᵉ paramètre `opts`), fonctions projectile de `Combat` (création, mise à jour, contact, surface, fin de vol, ricochet, Geometry), `Matches:act` (validation du booléen) et deux champs du snapshot projectile (`infusion`, `planted`), `Techniques.wireBind` (une ligne : début de la prise), `Elements.phoenix` (lames cachées enflammées), `Controls` / `Input`, `Effects` (fonctions projectile/impact), `AI` (3 lignes isolées).
- `Fighters.luau` n'est pas modifié : la maîtrise chakra vit côté serveur (une seule source de vérité, rien d'exposé au client).

## Les règles (déclencheur → règle → changement visible)

Infusion (au lancer) : `reinforced-steel` (poids ×2, impact ×1,8, portée ×1,15, dégâts ×1,25), `wind-blade` (vitesse ×1,3 + 0,05/niveau de vent, plafond ×1,5 ; portée ×1,5 ; poids ×0,8), `fire-blade` (vitesse ×1,05, enflammé), `lightning-steel` (vitesse ×1,1, conducteur), `sand-reinforced`, `lightning-down-the-wire` (contexte : un corps lié par son fil → le courant au lieu du lancer), `gentle-palm` (maîtrise du corps → la paume).

Rencontres en vol (groupe exclusif, une issue par rencontre, depuis le côté dominant) :

| Règle | Issue | Ce qu'on voit |
|---|---|---|
| `plain-pass` | deux objets simples se croisent (comportement d'avant, **interrupteur** pour l'A/B) | rien |
| `volumes-pass` | deux jutsu ne s'annulent jamais | rien |
| `fire-feeds-on-wind` | le feu absorbe le vent et s'embrase | éclair orange, anneau |
| `element-overpowers` | Feu > Vent > Foudre > Terre : l'élément dominant détruit l'autre | coupure |
| `palm-swats-blades` | la paume de Neji chasse la lame | éclat Hyūga, lame qui tournoie |
| `volume-swallows-tool` | Great Fireball / Vacuum Palm / Wind Cut / Sand Coffin / Phoenix avalent une lame | brûlée ou soufflée |
| `heavy-steel-pierces-flame` | une lame renforcée plus lourde qu'une petite flamme la traverse | coupure |
| `wind-cuts-the-lane` | le vent coupe une lame plus légère ou égale et continue | trait lumineux, lame coupée |
| `heavier-deflects` | le plus lourd dévie le plus léger et continue | étincelles, lame qui tombe |
| `even-intercept` | poids égaux : les deux tombent | « clash » + deux lames qui tombent |

Dominance, déterministe : deux jutsu → passent ; jutsu contre lame → le jutsu mène, sauf lame renforcée plus lourde de > 0,25 (jamais une lame de vent contre le feu) ; deux lames → l'élément d'abord, puis le poids (> 0,25), puis l'ancienneté (ID). Les rencontres d'un tick sont triées par instant de contact puis par ID : **le résultat ne dépend pas de l'ordre de la liste** (testé dans les deux ordres). Poids : kunai 2, shuriken 1,5 ; chakra : kunai 4 (vent 3,2), shuriken 3, sable 4,8 ; Phoenix 2,5, Wind Cut 4, Vacuum Palm 5, Fireball 6, Sand Coffin 6.

Contact (sur le corps, après la défense ; esquivé / paré / absorbé → le chakra ne fait rien) : `reinforced-guard-crush`, `lightning-shock`, `lightning-wire-surge` (sur un corps lié par son propre fil : +3 dégâts, prise +0,45 s), `fire-ignites`, `wind-gust`, `gentle-palm-through-guard`, `gentle-palm-point`.

Surface : `chakra-blade-plants` (reste plantée), `lightning-shock-point`, `fire-burn-point`, `wire-stretches`.

Point planté (`PointContact`) : `owner-recovers` (le propriétaire marche dessus : +4 chakra), `shock-point-trap` (l'adversaire au sol : 3 dégâts, étourdi 0,4 s), `opponent-tramples` (l'adversaire l'écrase : refusé). Tout objet lancé par l'adversaire qui le touche **le fait sauter**. Durée 5 s, 4 au plus par combattant.

Fil (`WireContact`, `WireCross`) : `tripwire-binds`, `charged-wire-shocks`, `fire-runs-the-wire`, `lightning-charges-wire` (sa propre foudre seulement), `wind-cuts-wire` ; le dôme de la Rotation coupe un fil qu'il touche sur toute sa longueur.

## Coûts et refus

Outil normal 4 (gratuit en annulation de chaîne, inchangé). Chakra : renforcé +6 (10), vent / feu / foudre +8 (12) ; en annulation de chaîne seul le supplément est payé ; paume de Neji 10 ; courant dans le fil 8. Payé une fois par lancer (pas par lame). Réserve insuffisante : refus `Need chakra`, rien n'est lancé ni dépensé, pétillement à la main. Courant dans le fil : deux par prise, jamais au-delà de 2,2 s de prise ; l'adversaire lié garde la substitution (X).

## Tests (headless)

- Nouvelle suite `tests/Chakra.spec.luau` (17 cas), enregistrée dans `tests/run.sh` **et** `build.py` `TEST_RUNNERS` : validation de la donnée et refus des éditions dangereuses ; mêmes entrées → identités par maîtrise (et remappage = donnée) ; lancer normal strictement inchangé ×5 ; coûts, annulation de chaîne, refus sans trace ; vent (vitesse, portée, coupe des deux shuriken, poursuite) ; renforcé (déviation, garde ×3 et poussée, garde brisée) ; feu (embrasement, point qui brûle, absorption du vent, ricochet qui garde le feu et ne plante pas) ; foudre (étourdissement plus long, piège planté) ; fil (lien, courant, borne, Dragon Flame qui suit) ; fil tendu (lien au contact, feu qui court, coupe par le vent, coupe par la Rotation) ; paume (chasse la lame, traverse la garde, refusée en l'air) ; déterminisme dans les deux ordres ; points (récupération, éjection, durée, plafond) ; volumes (Vacuum Palm souffle la lame, deux jutsu s'ignorent, l'acier traverse la petite flamme, la flamme mange le vent) ; interrupteur A/B ; entrée distante (`chakra` non booléen refusé avant toute mutation, `true` → infusion choisie par le serveur) ; client : `Effects` réel chargé dans une scène simulée, tous les types de contact chakra, objets plantés, natures et styles inconnus → aucune erreur.
- `tests/Input.spec.luau` (+1 cas) : Z tenu / Z juste avant / Z périmé, R2 seul, R1 + R2, R1 + face reste un jutsu, Z ne modifie pas la gâchette, visée identique au lancer normal (souris à portée, hors portée abandonnée, adversaire à la manette), aide.
- **Contre l'ancien code** (anciens `Combat/Matches/Input/Effects/Controls/Techniques/Elements`, nouveaux modules chakra présents) : les 14 cas de comportement de `Chakra.spec` et le cas d'entrée échouent ; seuls passent la validation de donnée, le remappage de profil et le garde « lancer normal inchangé » (qui doit passer avant comme après).
- Toutes les suites : **19 suites PASS** ; `build.py`, `--debug`, `--qa` PASS (portes automatiques incluses) ; isolation des builds, docs projet, architecture PASS.
- Endurance : 16 duels IA contre IA de 60 s (toutes les paires CORE4, générateur aléatoire déterministe de la régression de rythme), **0 erreur** ; l'IA infuse (≈ 68 infusions), et l'on observe embrasements (16), étourdissements (10), poussées du vent (4), lames plantées (≈ 74), points qui brûlent, fils tendus (7) et liens au fil (3), récupérations (6), points écrasés (5) ou éjectés (2), lames avalées par un jutsu (5). Rythme IA de la régression : 22 jutsu / 16 gardes en une minute (avant : 20 / 18 ; bornes 4–26, ≥ 3).

## À valider dans Studio

Ouvrir `dist/NinjaDuel.rbxlx`, contre l'IA :

1. **Entrées :** Z + R et Z puis R (vite) → lame de chakra ; R seul → lame normale. Manette : R2 seul normal, R1 + R2 chakra, R1 + △ / □ / × / ○ toujours des jutsu. Ligne d'aide lisible (pas de retour à la ligne).
2. **Lisibilité des infusions en vol :** gaine translucide (bleu renforcé, vert-blanc vent avec anneau, orange flamme, bleu électrique étincelles), traînée plus longue pour le vent, lumière. Au repos (plantée) : la lame dans la surface, pulsation lente.
3. **Minato :** kunai du vent contre la paire de shuriken de l'IA (trait de coupe, lames qui tombent), coup → poussée + « E — CHASE ».
4. **Itachi :** shuriken de feu : feu au sol sur le corps, point qui brûle au mur ; contre le kunai du vent de Minato : embrasement.
5. **Sasuke :** foudre → étourdissement assez long pour enchaîner ; Wire Trap → Z + R (éclair le long du fil) → 1 (Dragon Flame). Wire Trap raté : le fil est-il visible au sol (largeur 0,1, bout planté, piquet) ? L'IA le traverse-t-elle ? Un Phoenix le brûle-t-il de façon lisible ?
6. **Neji :** Z + R quand une lame arrive (fenêtre ~0,29 s) ; contre une garde : barre de chakra qui baisse, marque de tenketsu.
7. **Garde :** trois lames de chakra sur une garde → garde brisée, recul visible.
8. **Points plantés :** visibles, récupérables en marchant, éjectés par un lancer, disparus après 5 s.
9. **Caméra :** un « clash » de deux lames secoue autant qu'un choc de frappes — trop ?
10. **En ligne (deux clients) :** l'infusion et les objets plantés se répliquent.

## Risques et limites

- **Fusion :** lignes partagées avec d'autres agents : `Controls.Help` / `HelpPad` (même ligne que les textes de relance), `TEST_RUNNERS` de `build.py` (une seule ligne), `run.sh`, signature de `Combat:request`, la ligne de lancer de sonde de l'`AI`, `Elements.phoenix` (voisin de `Elements.wind` / Wind Cut). Les modules Codex portés sont identiques à l'octet.
- **Rythme IA :** la régression passe à 22 jutsu (borne 26). Si une autre branche pousse ce nombre, le crochet IA (3 lignes) se retire sans effet de bord.
- **Ce qui touche aussi le jeu « sans chakra » :** une lame normale peut maintenant être avalée par un jutsu adverse (Fireball, Vacuum Palm, Wind Cut, Sand Coffin, Phoenix), chassée par la paume de Neji, et éjecter un point planté ; une lame de chakra adverse peut **dévier le kunai marqué en vol de Minato** (le sceau est perdu) ; les lames cachées du Phoenix de Sasuke brûlent (petit bonus). Chaque cas est une règle (`volume-swallows-tool`, etc.) désactivable.
- **Contact « plus fort » :** une lame de chakra touche par une sphère (0,25 + 1,2 autour du torse) au lieu du rayon sur les membres. Voulu (« contact plus stable »), à vérifier pour que ça ne ressemble pas à du guidage.
- **Entrée :** Z est voisin de X (substitution) en QWERTY. L'étiquette « Z » ne suit pas la disposition AZERTY (comme les étiquettes WASD / Q actuelles). La visée de l'accord clavier duplique la règle de `Main.client` (140 studs) : à garder alignée.
- **Client :** non vu dans Studio ; le test headless prouve seulement l'absence d'erreur (scène simulée). Chaque visuel chakra est protégé par `pcall` : une erreur de rendu ne casse jamais le flux d'impacts.
- **Équilibrage :** coûts et grandeurs sont des premières valeurs (toutes dans `ChakraTuning.Effects`). L'IA ne contourne pas les fils tendus : ils piègent souvent le bot.
- `ChakraCombat` fait ~800 lignes (adaptateur commenté, une section par déclencheur).

## Pas fait (options suivantes)

Chakra + lourd / esquive / saut (accords manette pris par les jutsu) ; Chidori qui descend le fil (Dragon Flame remplit déjà ce rôle) ; téléportation de Minato vers un kunai de chakra planté (doublonnerait le Marked Kunai) ; rencontres lame normale contre lame normale (interrupteur `plain-pass` prêt) ; usage délibéré par l'IA de la paume, du courant et des fils ; cas NativeQA dédiés (la QA native est le domaine de l'agent devtools).

## Fichiers

Nouveaux : `src/Server/ChakraCombat.luau`, `ChakraTuning.luau`, `ChakraRules.luau`, `ChakraVectors.luau`, `ChakraInputPlan.luau`, `tests/Chakra.spec.luau`, ce rapport. Modifiés : `src/Server/Combat.luau` (branche outil, fonctions projectile), `Matches.luau` (validation, 2 champs de snapshot), `Techniques.luau` (`wireBind`), `Elements.luau` (`phoenix`), `AI.luau` (crochet isolé), `src/Shared/Controls.luau`, `src/Client/Input.luau`, `src/Client/Effects.luau`, `tests/Input.spec.luau`, `tests/run.sh`, `build.py`, `dist/*`.
