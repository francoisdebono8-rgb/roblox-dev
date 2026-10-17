# Nagato — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Rinnegan`**, âge affiché12 ; mouvement/clip effectif `Mirage`, armes déclarées `none`. Techniques présentes : `Repulsion`, `Attraction`, `Absorb`. Routes : airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`CircleStep`, up=`Launcher`. [Données](../../src/Shared/Wave3.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** Absorb/ReflectClear réels ; famille Mirage et RepellingPalm emprunté masquent la gestuelle → paumes et transitions de forces locales.

**Stade, source et extrapolation :** **Période cible de design : jeune/prodige, environ12–14ans, pas une égalisation de puissance adulte.** Les âges du runtime15 chez Haku/Deidara restent des faits du build, pas un arbitrage canon de cette bible. Les gestes précis, rythmes, distances et traductions corporelles ci-dessous sont des **GAMEPLAY_LIBERTY de conception** retenues pour cette V1 ; les techniques de période non attestée restent signalées, sans effacer la fantasy du prodige. Exclusions/point de période : SixPaths, corps Pain, ChibakuTensei, invocation géante, RinneRebirth ; l’existence du Rinnegan ne valide pas leur maîtrise à12.

**Tenue/silhouette :** Tenue simple d’orphelin d’Ame, cheveux roux, corps fin, yeux Rinnegan visibles ; pas robe Pain/Akatsuki ni récepteurs du corps de Yahiko.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Déplacer le rapport de forces par de petites paumes et de grands changements de distance, avec un corps fragile et minimal.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Mains ouvertes près du ventre, épaules relâchées. |
| Jambes / centre de gravité | Base étroite, centre stable. |
| Avance | Petits pas droits sans rebond. |
| Recul | Recule lentement en gardant paumes visibles. |
| Strafe | Pivot court sur pied arrière. |
| Sprint | Course sobre sans vigueur de lutteur. |
| Dash / rush | Court glissé corporel, pas téléportation. |
| Saut | Saut modéré, mains équilibrent. |
| Chute | Paumes se rapprochent pour protéger. |
| Landing | Pieds proches puis genoux absorbent. |
| Garde | Mains ouvertes dévient, pas barrière permanente. |
| Esquive | Un pas sec suffit, corps reste dans l’espace. |
| Réaction légère | Épaule/poignet cèdent et main tombe. |
| Réaction lourde | Torse plie franchement, perd sa ligne de paume. |
| Knockdown / get-up | Chute fragile, relève au genou avant paume. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Gauche, paume de mesure | Bas→sternum | Pas court0.25, doigts ouverts | 3.0 | 0.15/0.06/0.21 | mesuré : Prendre une lecture au contact. |
| L2 | Droite, paume d’appel | Extérieur→bras, bref tirage vers lui | Bassin recule0.2 pendant main ramène | 3.3 | 0.22/0.06/0.20 | aspire→pause : Ramener l’appui, pas projectile de gravité. |
| L3 | Gauche, paume de rejet | Centre→torse, petite poussée de force | Pied avant ancré, corps presque immobile | 3.6 | 0.26/0.08/0.34 | accent unique : Écarter vers neutral ; pas kick final. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : paume accompagne une impulsion locale sous le centre, launcher modeste. |
| Side après1hit | Un hit : main attire l’épaule sur un pas latéral ; force agit seulement après contact réel. |
| Away après2hits | Deux hits : deux paumes repoussent et petit recul, pas deuxième aspiration en chaîne. |
| Air après1hit aérien | Hit air : une paume de maintien puis rejet vers sol ; pas gymnastique de pied. |
| Launcher | Impulsion locale, corps reste bas et lit l’élévation. |
| Air continuation | Paume courte puis repoussement terminal, aucun re-launch par Attraction. |
| Finisher | Repulsion ou rejet de paume, termine l’échange et expose cooldown. |
| Wall / sortie de mur | Repoussement vers mur existant ; au rebond ne recharge pas Attraction gratuitement. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Deux mains s’ouvrent depuis sternum et poussent sur un pied fixe ; portée4.0, très peu de translation. L’anticipation est l’ouverture des doigts/épaules ; si raté, les bras restent ouverts.

**A/C/R de départ pour Heavy : .31/.08/.38s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Garde sobre, esquive d’un pas ; Absorb défend les projectiles, jamais les poings. Contre par rejet après lecture, pas aura omnidirectionnelle toujours active.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Forces locales dans paumes/transitions ; pas obligation de consommer un gros jutsu pour chaque geste et pas de seconde hitbox invisible.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Attraction | Signature actuelle | Une main appelle, pied arrière se place | Ramène une cible dans une vraie portée | LOS/portée, garde/contre selon état | Une paume ou rejet, pas boucle attraction-repulsion infinie |
| Répulsion | Signature actuelle | Deux paumes s’ouvrent et corps s’ancre | Dégage corps/projectiles proches | Hors rayon, bait et fin de fenêtre | Finisher/retour neutral |
| Absorption | Buff actuel | Mains ouvertes près poitrine, stance fixe | Fenêtre contre objets, récompense bornée | Melee et fermeture de fenêtre | Une reprise ensuite, pas attaque absorbante permanente |

## 10. Awakening / état spécial

ReflectClear renvoie au lieu de détruire : nouvelle lecture de projectile, même fragilité de corps. Ne donne ni corps Pain ni tous les chemins.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Minimum de gestes.
- Paumes toujours ouvertes.
- Force suit une intention de main.
- Aucune rotation de brawler.
- Le corps souffre vraiment au hit.
- Répulsion ne cache pas l’appui.
- Une pause lisible entre tirer et pousser.

L’animateur livre préparation/contact/reprise et appuis, pas seulement une pose spectaculaire. Un calage sur les phases communes est permis ; importer exactement la chaîne visible d’un autre fighter ne l’est pas. Les lames/volumes suivent leur source ; le mouvement caméra n’ajoute pas d’impact fictif.

## 12. Hooks futurs — hors V1

| Système futur | Extension réservée, sans la construire maintenant |
|---|---|
| Chakra | Coût/état de l’action et source du contact exposés ; infusion/économie globale finales ultérieures. |
| Nature / propriété | Tag de contact et point d’origine séparés du clip ; nature ≠ forme/dōjutsu/corps. Ne pas ajouter toutes les affinités adultes. |
| Outils | Fenêtres de main libre, départ et fin du lancer déjà lisibles ; variété/maîtrise globales ultérieures. |
| Armes | Attaches fixes/configurations V1 déclarées ; aucun inventaire, loot ou moteur universel d’armes. |
| Arbre | Identifiants stables des actions ; l’identité fondamentale ne sera jamais retirée pour la vendre en nœuds. Aucun arbre dessiné ici. |
| Maîtrise | Événements qualifiés existants pourront être lus plus tard ; zéro XP/compteur/règle d’acquisition ajouté à la V1. |

## A. Animation reuse matrix — part locale

Famille de base : **F8 mains de forces**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 mesure ; L2 appel ; L3 rejet ; Heavy double paume ; transition attraction/rejet.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L3-B** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Absorb/ReflectClear réels ; famille Mirage et RepellingPalm emprunté masquent la gestuelle → paumes et transitions de forces locales.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L3-B** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
