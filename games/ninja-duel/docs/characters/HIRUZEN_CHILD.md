# Hiruzen enfant — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Absent du runtime** : aucune entrée Fighters/Roster/MoveGraphs/clip dédiée trouvée au HEAD. Aucun ID technique imposé ni statistique inventée comme existante. La bible conçoit une future entrée ; le code du menu n’est pas modifié.

**Écart décisif :** Aucun fighter runtime → prodige de distance/bâton/outils ; Enma et arsenal adulte ne sont pas prérequis.

**Stade, source et extrapolation :** **EXTRAPOLATION_BORNÉE** : Prodige disciple des fondateurs ; une base bâton/outils et un seul Katon court sont une conception jeune, pas tout le répertoire du Hokage. Source officielle citée décrit Enma chez le Hiruzen adulte, pas chez cet enfant. [Référence de période](https://naruto-official.com/en/news/01_1287). Hors périmètre : Maîtrise de tous les jutsus, cinq natures simultanées, Enma adulte requis, Faucheuse.

**Tenue/silhouette :** Tunique ocre terre, pantalon court sombre, avant-bras bandés, cheveux bruns courts en brosse et visage juvénile ; bâton simple en bois sombre tenu à deux mains. Longueur cible du bâton≈1.1hauteur du rig, pas de télescopage/Enma ; tenue d’entraînement et non robe de Hokage.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Répondre avec la bonne extrémité d’un bâton et un outil placé, en changeant de distance plutôt qu’en accumulant les éléments.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Bâton court en diagonale basse, regard très actif. |
| Jambes / centre de gravité | Base moyenne, poids alterne entre deux pieds. |
| Avance | Avance par glissés courts de bâton. |
| Recul | Pointe reste entre lui et l’ennemi. |
| Strafe | Change de prise en pas latéral. |
| Sprint | Bâton près de hanche pour courir. |
| Dash / rush | Pas bondissant court, extrémité protège l’arrivée. |
| Saut | Saut compact guidé par une main. |
| Chute | Bâton rapproché au buste, pas hélicoptère. |
| Landing | Réception fléchie, pointe touche sol sans hit gratuit. |
| Garde | Deux mains écartées, bâton diagonal. |
| Esquive | Pivot autour d’un appui, change la main avant. |
| Réaction légère | Avant-bras ramènent bâton au corps. |
| Réaction lourde | Pointe tombe, second pas restaure l’équilibre. |
| Knockdown / get-up | Roule côté épaule, récupère prise avant de se relever. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Main avant, pointe de bâton | Estoc court centre→épaule | Glissé avant0.4, bras ne se verrouille pas | 4.2 | 0.13/0.05/0.20 | bref : Prendre la mesure. |
| L2 | Main arrière, talon du bâton | Retour horizontal vers avant-bras | Pivot du bassin et échange de main avant | 3.7 | 0.20/0.06/0.18 | retard tactile→sec : Punir l’entrée sous la pointe. |
| L3 | Deux mains, levier de manche | Bas→haut puis poussée latérale | Pas oblique0.6, bâton glisse entre doigts | 4.5 | 0.22/0.07/0.30 | accent propre : Changer la distance, pas projeter sans contrôle. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : pointe sous bras puis levier ascendant ; launcher de bâton. |
| Side après1hit | Un hit : échange de prise et pas extérieur, talon touche depuis l’autre côté. |
| Away après2hits | Deux hits : frappe basse du talon et recul, pointe reste en couverture. |
| Air après1hit aérien | Hit air : estoc bref ; down = rabattre de bâton, side = déplacer la prise autour du corps. |
| Launcher | Levier sous garde annoncé par abaissement du manche. |
| Air continuation | Un estoc puis rabattement ; réception rend le bâton au plan frontal. |
| Finisher | Coup transversal tenu à deux mains, arrêt net avant retour en garde. |
| Wall / sortie de mur | Pointe prend appui près mur pour changer côté sans générer mur élémentaire. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Bâton ramené côté hanche, frappe des deux mains en arc court vers épaule ; portée5, pas de rotation360°. Whiff laisse la pointe basse et exige reprise de prise.

**A/C/R de départ pour Heavy : .28/.08/.36s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Bloc en diagonale, parade avec levier, esquive par pas autour du bâton ; contre d’une extrémité, reprise à moyenne portée. Enma non nécessaire.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Bâton ordinaire visible en permanence ; outil tenu/repris par une main, pas multiplication de clones d’armes. Pas besoin du système armes final pour deux attaches de prise.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Levier défensif | Lecture/stance courte | Deux mains changent l’angle du bâton | Dévie un frontal puis offre un estoc | Feinte/flanc/saisie | Estoc ou sortie de distance |
| Shuriken de placement | Outil existant à adapter | Bâton dans une main, autre lance au ras du bras | Ferme une approche quand on recule | Déviation/garde, pas tir homing | Reprise de prise puis L1 seulement si hit confirmé |
| Souffle d’entraînement Katon | Un jutsu élémentaire court, extrapolation | Bâton proche flanc puis signe et souffle | Ferme une seule ligne pendant sortie | Canalisation et côté ouverts | Finisher, pas accès aux cinq éléments |

**Binding/limites de prototype :** R1+× = levier défensif≈0.5s, un seul frontal lu puis choix estoc OU retrait ; R2 = outil commun avec une main libérée ; R1+□ = souffle Katon court10studs, signe≈0.35s, récupération≈0.4s. Le bâton garde une longueur fixe ; échange des deux prises selon Light/Side, aucun mode Enma/cinq natures. Une parade ratée ne donne pas de changement de distance gratuit.

## 10. Awakening / état spécial

Aisance de prise : après parade réussie, prochaine attaque choisit pointe ou talon par la même direction de branche, sans bouton supplémentaire. Ne donne pas tout le catalogue de Konoha.

Condition/durée V1 de départ : reprendre le contrat partagé existant (35%HP maximum, une activation par match, fenêtre12s, seulement hors réaction), sans nouveau pouvoir de prime. Le coût/recharge associés restent à éprouver dans le prototype commun. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Deux extrémités lisibles.
- Changer prise sans lâcher magiquement.
- Pas de bâton tournoyant permanent.
- Posture encore jeune.
- Une réponse précise par situation.
- Outil libère une main réellement.
- Un seul élément de signature V1.

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

Famille de base : **F6 prises et portée**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 estoc ; L2 talon inverse ; L3 levier ; Heavy transversal ; transition de prise/parade.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L8-C** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Aucun fighter runtime → prodige de distance/bâton/outils ; Enma et arsenal adulte ne sont pas prérequis.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L8-C** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
