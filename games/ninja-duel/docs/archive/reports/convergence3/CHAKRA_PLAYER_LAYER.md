# Chakra systémique — la couche joueur (convergence 3, §4 et fil de §5 Sasuke)

Branche `claude/nd-vrs-chakra2`, base `2aba0ca`. Mission : [NEXT_VALIDATION_ROSTER_SCALE](../../missions/NEXT_VALIDATION_ROSTER_SCALE.md) §4 (outils infusés, foudre + métal / fil, points plantés, rencontres de projectiles, IA) et la partie fil de §5 Sasuke. Passe précédente : [CHAKRA_TOOLS](../convergence2/CHAKRA_TOOLS.md).

**Rien n'a été vu dans Studio.** Toutes les preuves sont headless : règles, états, champs de snapshot, et un client chargé dans une scène simulée (aucune erreur, objets construits). Statut honnête : IMPLÉMENTÉ, TESTÉ TECHNIQUEMENT, NON JOUÉ.

## Ce qui change en jeu

Contrôles inchangés : outil R / R2, chakra Z + R / R1 + R2. Aucun bouton ajouté.

**Le fil est un objet.** Un corps lié par le fil de Sasuke est tenu par un objet vivant (`wirehold`) : de sa main jusqu'au corps (Wire Trap touché), ou attaché au piquet et à la lame du fil tendu dans lequel il a marché (la ligne fait un V piquet → corps → lame). Sa vie est la prise (tension) ; il disparaît avec elle (fin, substitution, mise au sol). Les deux conversions passent par lui : le **courant** (Z + R, inchangé en dégâts et bornes) entre à la main ou au piquet, illumine le fil 0,5 s et resserre la prise ; le **Dragon Flame** (1) court le long du fil depuis la main ou le piquet jusqu'au corps, et le fil brûle.

**Le métal conduit la foudre** (vraie interaction, pas un bonus de dégâts) :
- une lame de foudre saute dans le métal planté qu'elle survole à moins de 4 studs (lame plantée de l'adversaire, fil tendu de Sasuke) ; avant, il fallait un contact quasi exact (~1,3 stud), ce qui n'arrivait presque jamais (les lames volent à ~3 studs au-dessus du fil) ;
- la charge court dans le métal qui se touche (1,6 stud) : un point de foudre posé contre le fil le rend vivant, un fil vivant charge la lame posée en travers ;
- une lame chargée par l'autre combattant **électrocute celui qui marche dessus, son propre lanceur compris** (au lieu de lui rendre ses 4 de chakra) : Sasuke retourne les kunai plantés de Minato ou d'Itachi en pièges ;
- un fil vivant reste ce qu'il était : il lie et électrocute au contact.

**Route Sasuke** : 3 (Wire Trap) → lié → Z + R (le courant tient 0,4 s de plus, corps verrouillé visible) → 1 (Dragon Flame le long du fil). Ou : Wire Trap raté → fil tendu → Z + R lancé par-dessus (à la manette aussi : la visée sur l'adversaire suffit) → fil vivant → l'adversaire qui y entre est lié et électrocuté → mêmes conversions.

**Les rencontres s'expliquent** : l'impact du perdant nomme le gagnant, sa nature et la raison (`nature`, `cut`, `steel`, `volume`, `palm`, `weight`, `even`). Le gagnant éclaire dans la couleur de sa nature et continue ; une victoire de nature montre la couleur gagnante qui se referme sur la perdante ; une lame coupée tombe en deux moitiés ; un poids plus lourd donne un anneau court et dur.

**Les objets posés se lisent** (marques, couleur du propriétaire, durée) : huit traits autour de chaque lame plantée, de chaque bout du fil tendu et de chaque sceau de Minato, dans la couleur du combattant qui l'a posé ; un trait s'éteint par huitième de vie, la dernière seconde clignote. Au-dessus des lames, selon ce qu'elles valent **pour celui qui regarde** : un losange qui tourne (ta lame : marche dessus, +4 chakra), une croix (la sienne : piétine-la), un éclair crépitant (piège vivant, quel que soit le propriétaire).

**Corps et zones** : un corps verrouillé par la foudre crépite exactement le temps de l'étourdissement allongé (ou de la prise prolongée par le courant), puis plus rien ; un corps dans le feu a de petites flammes aux jambes tant que les brûlures tombent (elles n'étourdissent toujours pas et ne comptent toujours pas de coups) ; chaque zone de feu a un anneau de braises sur son bord exact, qui s'éteint avec elle, et une petite zone a moins de flammes qu'une ligne de Great Fireball.

**Vols infusés** : le kunai de vent de Minato porte deux fines arêtes d'air tranchant au-delà de la pointe (en plus de la gaine, de l'anneau et de la longue traînée) ; l'acier renforcé une coque dense (visible pour un combattant de profil Basic qui lance de l'acier : aucun des six, mais un nouveau combattant sans profil de maîtrise l'aura) ; la foudre jette de petits arcs derrière la lame. Un lancer normal reste strictement identique (test inchangé).

**IA** : Sasuke envoie le courant avant le Dragon Flame quand sa réserve paie les deux, et arme une fois son fil tendu quand l'adversaire se tient à côté. Le courant est une action outil, pas un jutsu : rythme de la régression inchangé (22 jutsu / min, borne 26).

## Fichiers

Les miens : `src/Server/ChakraCombat.luau` (fil tenu, conduction, explication des rencontres, état des corps), `src/Server/ChakraTuning.luau` (déclencheur `MetalCross`, règles `charged-point-shocks`, `lightning-charges-metal`, `thrown-object-knocks-point` devenue une vraie règle, grandeurs `charge`), nouveau `src/Client/ChakraFX.luau` (tout le dessin nouveau), `tests/Chakra.spec.luau`.

Partagés (petits, additifs) :
- `Effects.luau` : une ligne d'installation de ChakraFX (à côté de SandFX / LeeFX), un crochet `layer.step` par image (deux lignes), et les flammes / la lumière d'une zone de feu proportionnelles à son rayon (deux lignes).
- `Techniques.luau` : la ligne d'impact du Dragon Flame devient `ChakraCombat.dragonFlame` (même style `fire`, avec le chemin du fil).
- `Combat.luau` : une ligne dans `updateHazards` (`burnUntil` quand une brûlure tombe).
- `Matches.luau` : champs de snapshot additifs (`mark`, `normal`, `expires`, `charged`, `holds`, `anchored` sur les objets ; `shocked`, `burning` sur les corps).
- `AI.luau` : le bloc « opposant lié » de Sasuke et un bloc « armer le fil » ; un `require` de ChakraCombat.

## Preuves (headless)

- `Chakra.spec` : 17 → **25 cas**. Les huit nouveaux échouent sur `2aba0ca` (vérifié en copie de la base, sans arrêt au premier échec ; les deux cas qui tombent d'abord sur le nouveau champ `mark` ont été rejoués sans ce contrôle : la conduction et le réseau échouent aussi) : fil-objet (extrémités, tension = prise, disparition, courant et flamme depuis la main) ; fil tendu qui attrape (piquet et lame conservés, courant et flamme depuis le piquet) ; foudre dans un kunai planté de Minato (pas d'éjection, arc, Minato électrocuté sans remboursement ; non chargé, il rembourse toujours) ; réseau (point de foudre contre le fil, lancer par-dessus le fil, kunai en travers chargé, fil vivant qui lie et électrocute) ; explication des rencontres (cut, nature, weight, even, volume) ; IA (courant avant flamme ; fil armé) ; snapshot (marques, durées, charge, fil tenu, `shocked` exact, `burning` sans étourdissement ni coup compté) ; client sur scène simulée avec `ChakraFX.strict` (toute erreur de dessin fait échouer : marques par sens et couleur du propriétaire, traits qui s'éteignent, bouts du fil, fil tenu qui se détend et passe à la foudre, sceaux, bords de zones, vols, gagnants, arcs, Dragon Flame, corps, nettoyage, nouvelle manche, menu).
- **23 suites PASS** ; `build.py`, `--debug`, `--qa` PASS (portes incluses) ; isolation des builds 9/9, docs projet, architecture PASS.
- Endurance (copie hors dépôt, 17 duels IA de 60 s, tirages déterministes, toutes les paires avec Sasuke + paires CORE4) : **0 erreur**. Base → maintenant : courant dans le fil 0 → 9, fils vivants 0 → 7, lames adverses chargées 0 → 2, Dragon Flame le long du fil 10, liens 12 + 4 → 14 + 5.
- Artefacts : `NinjaDuel.rbxlx` `e6c0ab5b23ea15214103e20138ce38a35cb66450ff87b6917f0880ec0105f4df`, `NinjaDuel-Debug.rbxlx` `029a79951e8b660aeeb936157720bad31ff264eaaf1329a39d6754d519ddecd4`, `NinjaDuel-QA.rbxlx` `9b3520555b83425f2e6bbef4d40aa2e4a119ce228630cc0d8b13172d9f841782`.

## À valider dans Studio (`dist/NinjaDuel.rbxlx`, contre l'IA)

1. **Minato, R puis Z + R à ~20 studs** : R = kunai acier, traînée fine blanche. Z + R = plus rapide, gaine vert pâle, deux arêtes vert pâle qui dépassent la pointe, anneau qui tourne, longue traînée. Contre une paire de shuriken d'Itachi : le kunai éclaire en vert et continue, le shuriken tombe en deux moitiés.
2. **Minato, Z + R visé au sol à ~15 studs (souris sur le sol)** : kunai planté, huit traits bleus (couleur Minato) au sol autour, un losange bleu qui tourne au-dessus ; un trait s'éteint toutes les ~0,6 s, la dernière seconde clignote ; marcher dessus rend +4 chakra.
3. **Sasuke contre Minato (IA) : Z + R qui passe au-dessus d'un kunai planté de Minato** : un éclair saute dans le kunai, la croix devient un éclair crépitant pendant 4 s ; si Minato marche dessus, il est électrocuté (arcs sur le corps) sans récupérer de chakra.
4. **Sasuke, 3 (Wire Trap) sur l'IA à ~15 studs** : ligne d'acier de la main droite à la poitrine, petit nœud bleu à la main, spires sur le corps ; la ligne se détend et pâlit pendant la seconde de prise. **Z + R pendant la prise** : éclair main → corps, fil bleu électrique ~0,5 s, arcs sur le corps tout le temps de la prise prolongée, la ligne se retend. **Puis 1** : une ligne de flamme court de la main au corps avec des bouffées de feu, puis l'explosion ; le fil disparaît.
5. **Sasuke, Wire Trap raté (souris au sol sur le côté, ~20 studs)** : fil tendu, piquet et lame, huit traits à chaque bout (6 s). **Z + R vers l'IA de l'autre côté du fil** (R1 + R2 à la manette) : un éclair descend dans le fil au passage des lames, le fil devient bleu et crépite sur toute sa longueur 4 s ; l'IA qui y entre est liée et électrocutée, la ligne fait un V piquet → corps → lame ; Z + R : l'éclair part du piquet.
6. **Sasuke, Z + R qui touche un corps non gardé** : arcs sur le corps seulement le temps de l'étourdissement allongé (~0,4 s), puis plus rien.
7. **Itachi, Z + R qui touche** : petit feu au sol, anneau de braises sur son bord, petites flammes aux jambes de la cible tant qu'elle y reste ; compteur de combo inchangé par la brûlure.
8. **Minato, 1 (Marked Kunai) au sol** : huit traits bleus plus larges autour du sceau jaune, un s'éteint toutes les ~1,5 s.
9. **IA Sasuke** : quand son Wire Trap vous lie, on doit voir le courant le long du fil avant le Dragon Flame ; quand son fil tendu est à moins de 8 studs de vous, une paire de shuriken de foudre visée sur le fil.
10. **À juger** : taille et visibilité des traits et des glyphes à l'échelle du stade (épaisseur 0,08, glyphe à 1,2 stud), lisibilité du V du fil tenu, bruit des anneaux de braises quand le feu court un fil (une chaîne de petites zones), portée de 4 studs de l'arc (trop généreuse ?).

## Risques et limites

- Non vu dans Studio : tailles, transparences et couleurs sont des premières valeurs.
- HUD : les indications chakra (`LIVE WIRE`, `METAL CHARGED`, `LIVE METAL • SHOCKED`, `SHOCK POINT`) restent muettes sous le filtre « loud » de `UI.luau` (non modifié) ; l'indication du lien par fil tendu devient `TRIPWIRE • WIRED • 1 = DRAGON FLAME` pour être dite comme celle du Wire Trap (avant, la sienne écrasait l'indication parlante et restait muette).
- Le fil tenu vit dans `c.projectiles` (`kind="wirehold"`, `planted="held"`) : le dôme de Rotation et le Desert Wave, qui retirent tout projectile adverse proche, le verraient ; sans effet en 1 contre 1 (le corps tenu ne peut pas lancer de technique), à exclure dans un futur mode à plusieurs.
- `Effects.FX:planted` est appelé (pcall) pour chaque ligne `held` à chaque snapshot et renvoie nil (peu coûteux, inutile).
- Le Dragon Flame reste instantané côté serveur ; la flamme est dessinée le long du fil au moment des dégâts.
- Équilibre : une lame adverse chargée électrocute son propre lanceur (3 dégâts, 0,4 s) ; portée d'arc et durées dans `ChakraTuning.Effects.charge`.

## Pas fait

Foudre dans un kunai-sceau de Minato (les sceaux vivent hors de la liste des projectiles) ; voie de vent qui persiste après le kunai ; IA qui évite les fils vivants et les pièges ; cas NativeQA dédiés ; mise à jour des documents actifs (CURRENT_STATE, MASTER_BACKLOG, SINCE_LAST_CLAUDE) laissée au lead qui intègre les branches.
