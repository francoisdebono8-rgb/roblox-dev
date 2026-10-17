# Madara enfant — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Absent du runtime** : aucune entrée Fighters/Roster/MoveGraphs/clip dédiée trouvée au HEAD. Aucun ID technique imposé ni statistique inventée comme existante. La bible conçoit une future entrée ; le code du menu n’est pas modifié.

**Écart décisif :** Aucune définition/clip/graphe dans le runtime → nouvelle identité physique simple, sans importer une prime adulte.

**Stade, source et extrapolation :** **EXTRAPOLATION_BORNÉE** : Enfance et rivalité : manga chapitres621–624 (source officielle ci-dessous). Escrime/lecture/Katon à cette précision = extrapolation de prodige ; pas attestation de chaque geste. [Référence de période](https://naruto-official.com/en/news/01_1663). Hors périmètre : EMS, Rinnegan, Susanoo, météores, Mokuton greffé, arsenal de guerre.

**Tenue/silhouette :** Tunique bleu nuit à col court, bas sombre, cheveux noirs en mèches courtes/ébouriffées, protections légères de bras et fourreau de sabre court à hanche gauche. Proposition enfant des clans, aucune armure rouge de prime. Sabre de prototype : lame≈2.5studs, prise une main + main libre.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Imposer le centre avec une escrime Uchiha frontale, provoquer le bloc puis casser l’angle par autorité physique.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Menton bas, main droite au sabre court, gauche surveille. |
| Jambes / centre de gravité | Base large, centre bas et stable. |
| Avance | Pas lourd dans la ligne, épaules carrées. |
| Recul | Un pied recule sans ouvrir la garde. |
| Strafe | Pivots secs autour du pied avant. |
| Sprint | Course compacte, arme protégée près du flanc. |
| Dash / rush | Entrée courte d’épaule, pas flash. |
| Saut | Saut peu haut, lame près du corps. |
| Chute | Deux jambes préparent l’impact. |
| Landing | Réception large absorbée aux genoux. |
| Garde | Sabre/avant-bras en croix près du torse. |
| Esquive | Déport sec d’un pas, reste face adverse. |
| Réaction légère | Absorbe avec épaule et grimace, pas impassible. |
| Réaction lourde | Pied arrière recule franchement, sabre protège la reprise. |
| Knockdown / get-up | Chute dorsale puis relève au genou, regard resté sur menace. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Droite, sabre court | Diagonale haute droite→hanche gauche adverse | Pas extérieur0.5, épaule descend | 3.8 | 0.18/0.07/0.22 | posé→sec : Prendre la ligne centrale. |
| L2 | Gauche, frappe de pommeau/paume | Intérieur→sternum pendant lame reste basse | Pied arrière rejoint0.3, poids en avant | 3.0 | 0.12/0.06/0.18 | court après la coupe : Fermer le corps plutôt que répéter une taille. |
| L3 | Droite, taille inverse | Hanche gauche→épaule droite adverse | Pivot puissant60°, pied arrière rattrape | 4.2 | 0.28/0.08/0.36 | accent fort : Chasser la garde et imposer une séparation. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : quillon contrôle le bras puis taille montante courte ; launcher lourd, pas genou de Sasuke. |
| Side après1hit | Un hit : pas extérieur et tranche de garde sur bras ; Madara reste face, pas disparition. |
| Away après2hits | Deux hits : talon bas et lame en barrage, retrait de0.8 ; portée garde la sortie. |
| Air après1hit aérien | Hit air : coupe unique vers épaule ; down accompagne la chute, side change la ligne de lame. |
| Launcher | Taille ascendante depuis hanche avec jambe qui pousse le sol. |
| Air continuation | Une coupe de rappel puis pommeau descendant ; pas danse multi-lames. |
| Finisher | Grande taille diagonale qui ouvre les bras et laisse recovery visible. |
| Wall / sortie de mur | Contrôle l’épaule contre mur, lame retient la sortie ; splat commun sans prison infinie. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Charge du sabre en arrière de l’épaule, frappe diagonale en avançant tout le poids ; portée4.5, recovery haute. La main gauche protège le visage ; garde/dodge punissent l’engagement.

**A/C/R de départ pour Heavy : .32/.09/.42s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Bloc ferme au sabre, pas latéral sec, riposte de pommeau ; sa lecture impose une ligne au lieu d’attendre calmement comme Itachi. Substitution physique commune.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Sabre court physique fondamental ; une lame active, pas gunbai géant requis ni armes de la guerre. Poignée utile à courte distance.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Lecture Uchiha naissante | Stance/lecture brève | Regard suit épaule, lame reste devant | Une parade juste prépare pommeau | Feinte/saisie et attaque hors ligne | Une riposte, pas esquive automatique |
| Souffle Katon court | Signature de fermeture | Pied arrière ancré, un signe puis torse avance | Petit cône coupe une sortie après taille | Charge attaquable, côté libre | Remplace finisher ; aucune mer de feu |

**Binding/limites de prototype :** R1+× = lecture frontale courte (fenêtre0.5s, une seule riposte de pommeau, annulée si bait/whiff) ; R1+□ = Katon de fermeture (cône court10studs, signe/canalisation≈0.35s puis récupération≈0.4s). Outil = kunai/shuriken commun. Le sabre n’a pas de projectile caché. Ces bornes définissent le prototype, coûts et dégâts restent ceux du contrat commun à régler dans le lot, pas puissance adulte.

## 10. Awakening / état spécial

Focalisation Sharingan jeune : après parade réussie, une taille d’angle devient disponible ; perdue si l’on attaque dans le vide. Pas EMS, Mangekyō requis ni Susanoo.

Condition/durée V1 de départ : reprendre le contrat partagé existant (35%HP maximum, une activation par match, fenêtre12s, seulement hors réaction), sans nouveau pouvoir de prime. Le coût/recharge associés restent à éprouver dans le prototype commun. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Base plus lourde que Sasuke.
- Une lame seulement.
- Pommeau et corps combattent ensemble.
- Aucun Shunshin de Shisui.
- Poids précède taille.
- Regard agressif mais jeune.
- Échecs montrent l’inertie.

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

Famille de base : **F4 arme à inertie**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 taille descendante ; L2 pommeau ; L3 taille inverse ; Heavy taille de corps ; parade→pommeau.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L8-A** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Aucune définition/clip/graphe dans le runtime → nouvelle identité physique simple, sans importer une prime adulte.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L8-A** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
