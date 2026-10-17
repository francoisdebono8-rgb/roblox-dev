# Naruto — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Legion`**, âge affiché13 ; mouvement/clip effectif `Legion`, armes déclarées `palms`. Techniques présentes : `ShadowClone`, `CloneRasengan`, `MassShadowClone`. Routes : airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Tackle`, side=`MirrorClone`, up=`UzumakiKick`. [Données](../../src/Shared/Fighters.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** Bodies/proxies et Rasengan aidé déjà substantiels ; continuer leur intégration, corriger décalages caméra/contact plutôt que refaire système de clones.

**Stade, source et extrapolation :** **Période cible de design : jeune/prodige, environ12–14ans, pas une égalisation de puissance adulte.** Les âges du runtime15 chez Haku/Deidara restent des faits du build, pas un arbitrage canon de cette bible. Les gestes précis, rythmes, distances et traductions corporelles ci-dessous sont des **GAMEPLAY_LIBERTY de conception** retenues pour cette V1 ; les techniques de période non attestée restent signalées, sans effacer la fantasy du prodige. [Source officielle fin PartieI](https://naruto-official.com/en/news/01_1296), [Rasengan puis évolution Vent](https://naruto-official.com/fr/news/01_1521). Exclusions/point de période : Rasenshuriken, mode ermite, KCM et formes de guerre ; pas d’amélioration Fûton de son Rasengan PartieI.

**Tenue/silhouette :** Veste orange/bleu, col clair, bandeau et cheveux blonds courts ; attitude inclinée et expressive ; clones portent la même silhouette.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Déborder par plusieurs origines de coups tout en gardant un vrai corps impulsif et une préparation lisible.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Poings un peu bas, épaules en avant. |
| Jambes / centre de gravité | Base large, poids saute légèrement d’un pied à l’autre. |
| Avance | Avance avec intention entière du corps. |
| Recul | Recule moins proprement, reprend vite une base. |
| Strafe | Pas larges, tête précède le pivot. |
| Sprint | Course insistante et basse. |
| Dash / rush | Rush oblique, clone couvre l’autre côté seulement si engagé. |
| Saut | Saut ample, genou monte. |
| Chute | Bras cherchent l’équilibre, pas flottement. |
| Landing | Deux pieds un peu décalés, bassin rebondit puis se fixe. |
| Garde | Avant-bras hauts, coude laisse une vraie ouverture. |
| Esquive | Petit bond de retrait, clone pas gratuit. |
| Réaction légère | Tête part et il refixe l’adversaire. |
| Réaction lourde | Torse plie, pied arrière traîne. |
| Knockdown / get-up | Chute expressive, roule puis se relève au poing. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Droite, crochet compact | Extérieur→joue/épaule | Pas avant0.5 et poids d’épaule | 3.2 | 0.16/0.07/0.20 | franc : Prendre contact avec le vrai corps. |
| L2 | Gauche, direct de corps | Centre→abdomen | Pied arrière rejoint0.4 | 3.1 | 0.14/0.06/0.21 | pressant : Fixer l’attention sur Naruto. |
| L3 | Clone au flanc, pied ; sinon Naruto pousse | Côté opposé→épaule | Naruto sort0.4 ; clone avance depuis vrai poste | 3.5 du porteur | 0.24/0.07/0.32 | léger retard : Changer l’origine du troisième contact sans coup invisible. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : clone placé sous la cible frappe vers haut, Naruto choisit poursuite ; proxy existant. |
| Side après1hit | Un hit : Naruto se décale, clone arrive du flanc choisi et repart ; pas double hit simultané garanti. |
| Away après2hits | Deux hits : Naruto fait tackle bas pendant clone protège la sortie ; une seule hitbox de branche. |
| Air après1hit aérien | Hit air : vrai Naruto frappe puis clone porte le second angle si disponible ; route ne recrée pas un clone gratuit. |
| Launcher | UzumakiKick/barrage à échelle commune, clone distinct et détruisible. |
| Air continuation | Un coup corps puis un porté par clone, finisher NarutoRendan ; sans clone version solo cohérente. |
| Finisher | Rasengan aidé ou NarutoRendan ; le clone de préparation doit pouvoir être interrompu. |
| Wall / sortie de mur | Clone utilise un vrai poste proche mur ; aucun coup depuis intérieur de décor. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Naruto charge son front/épaule pour un coup de tête court, bras gardent le corps adverse ; portée3.1 et risque net. Un clone peut couvrir la sortie mais ne crée pas un autre heavy autonome.

**A/C/R de départ pour Heavy : .28/.08/.36s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Bloc d’avant-bras moins raffiné, dodge corporel ; contre par retour impulsif. Substitution peut échanger avec corps valide selon hook, jamais effacer gratuitement une mauvaise lecture.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Corps secondaires au sein des routes et outils transformés existants ; main et clone montrent qui attaque. Faux Naruto ne remplace pas la cible de caméra sans règle explicite.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Clones limités | Signature existante | Signe visible puis fumée courte de lecture | Corps persistants fragiles à postes distincts | Les détruire ouvre le vrai corps | Portent branches avec budget commun |
| Rasengan aidé | Signature actuelle | Clone façonne, vrai Naruto porte la poussée | Finisher préparé à deux corps | Frapper le clone/whiff | Pas disponibilité instantanée universelle |

## 10. Awakening / état spécial

Chakra Kyûbi : corps plus animal et griffes, perd les routes de clones comme dans la logique actuelle ; changement de règle plutôt que clones plus manteau plus tout.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Vrai corps identifiable.
- Clones ont de vrais appuis.
- Espacer les contacts.
- Poids de poings, pas escrime.
- Fumée ne masque pas le hit.
- Aucune attaque depuis décor.
- Gestes plus expressifs que Minato.

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

Famille de base : **F7 corps secondaires**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 crochet ; L2 direct ; L3 split Naruto/clone ; Heavy tête ; transition façonnage Rasengan.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P2**, lot proposé **L5** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Bodies/proxies et Rasengan aidé déjà substantiels ; continuer leur intégration, corriger décalages caméra/contact plutôt que refaire système de clones.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L5** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
