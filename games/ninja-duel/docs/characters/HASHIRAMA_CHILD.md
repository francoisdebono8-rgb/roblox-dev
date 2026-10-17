# Hashirama enfant — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Absent du runtime** : aucune entrée Fighters/Roster/MoveGraphs/clip dédiée trouvée au HEAD. Aucun ID technique imposé ni statistique inventée comme existante. La bible conçoit une future entrée ; le code du menu n’est pas modifié.

**Écart décisif :** Aucun fighter runtime → lutteur/Mokuton local extrapolé, pas copie de Gaara avec FX marron.

**Stade, source et extrapolation :** **EXTRAPOLATION_BORNÉE** : Enfance : manga621–624 ; Mokuton local/gaine et racine proposés pour rendre le prodige reconnaissable. Leur disponibilité exacte à12–14 n’est pas attestée ici. [Référence de période](https://naruto-official.com/en/news/01_1663). Hors périmètre : Bouddha géant, forêt de carte entière, guérison automatique, mode ermite prime, suppression complète de bijû.

**Tenue/silhouette :** Tunique brique/brun à manches courtes ou relevées, pantalon sombre, cheveux noirs jeune longueur retenue derrière nuque, avant-bras libres pour les gaines de bois. Silhouette d’enfant solide, pas armure de Hokage ni long manteau ; couleurs et coupe = proposition cohérente de clan.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Avancer comme un lutteur, encaisser avec ses appuis et faire naître de petites prises de bois au milieu de ses gestes.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Épaules ouvertes, mains larges devant le ventre. |
| Jambes / centre de gravité | Pieds larges, centre bas élastique. |
| Avance | Pas enroulé qui pousse depuis hanche. |
| Recul | Recule en conservant la base de lutte. |
| Strafe | Pas de crabe, épaules restent tournées. |
| Sprint | Course vive mais lourde, bras près des côtes. |
| Dash / rush | Poussée d’appui, petite racine brisée au départ seulement si pouvoir actif. |
| Saut | Saut de force avec bras d’équilibre. |
| Chute | Jambes sous corps, mains prêtes à amortir. |
| Landing | Paume près du sol, pli de genoux ample. |
| Garde | Avant-bras et petite gaine de bois sous impact. |
| Esquive | Déport de bassin, pas de clone automatique. |
| Réaction légère | Absorbe au torse, un pied glisse. |
| Réaction lourde | Bloc cède, gaine se fend et il recule. |
| Knockdown / get-up | Chute lourde côté hanche, paume et jambe relèvent le vrai corps. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Gauche, paume de lutteur | Bas→sternum | Pas intérieur0.5, doigts cherchent le bras | 3.2 | 0.17/0.07/0.22 | rond→court : Gagner un appui adverse. |
| L2 | Droite, avant-bras gainé | Extérieur→épaule, bois couvre brièvement l’avant-bras | Pivot de hanche, pied avant fixe | 3.5 | 0.22/0.08/0.23 | un accent lourd : Déplacer le buste sans créer arbre géant. |
| L3 | Deux mains, poussée | Paumes vers poitrine, petite racine suit au pied | Poids entier avance0.6 puis s’arrête | 3.7 | 0.28/0.09/0.36 | lente→franche : Finir par recul adverse et bois qui se retire. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : épaule pousse vers une souche basse qui soulève ; un seul launcher local. |
| Side après1hit | Un hit : main fixe le bras puis pas de lutte latéral ; racine suit uniquement le point de contact. |
| Away après2hits | Deux hits : relâche la prise, paume au sol et racine basse freinent la poursuite, aucune entrave répétée. |
| Air après1hit aérien | Hit air : paume descendante ; down finit au sol, side garde l’adversaire hors de ses appuis. |
| Launcher | Soulèvement de hanche et souche unique, pas uppercut ni forêt. |
| Air continuation | Un contact paume puis stomp de retour ; la racine ne relance pas au sol. |
| Finisher | Poussée des deux mains, branche de soutien qui casse après l’impact. |
| Wall / sortie de mur | Racine locale remplace un appui près du mur ; pas cage permanente ni mur impassable. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Deux avant-bras se rapprochent puis poussent, courte gaine de bois forme la surface de contact. Portée4, charge visible au bassin, bois se rétracte après recovery ; garde latérale/whiff le punissent.

**A/C/R de départ pour Heavy : .34/.09/.42s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Bloc de lutte et bois bref, esquive de bassin, contre par poussée d’épaule ; reprise au sol. Pas soin passif invulnérable ni régénération automatique.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Pouvoir-bois intégré aux avant-bras/appuis, pas épée de bois tenue tout le duel. Gaine/racine ont point de naissance, durée et sortie visibles.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Racine de contact | Signature courte après ouverture ou défense lue | Main au sol puis poids avance | Une racine locale≤hauteur du genou retient un instant | Saut/esquive avant contact, substitution après prise | Une poussée ou launcher, pas les deux |
| Garde de jeune bois | Stance courte | Avant-bras se croisent, gaine pousse | Amortit un frontal puis casse | Saisie/flanc et gros engagement | Contre d’épaule unique |

**Binding/limites de prototype :** R1+× = racine de contact, cible à≤6studs/LOS, annonce sol≈0.25s, maximum1racine active, prise≈0.6s puis retrait (durée totale≤1.5s). Elle n’immobilise pas à nouveau une cible déjà en fin de branche et ne réinitialise jamais le launcher. R1+□ = garde de bois≈0.6s, une réponse frontale puis casse ; flanc/saisie la battent. La gaine visuelle des Lights ne donne ni nouvelle hitbox ni blocage passif.

## 10. Awakening / état spécial

Croissance contrôlée : une garde réussie permet de déplacer la racine suivante depuis son pied vers le point de contact ; toujours un seul ancrage, pas forêt ni guérison.

Condition/durée V1 de départ : reprendre le contrat partagé existant (35%HP maximum, une activation par match, fenêtre12s, seulement hors réaction), sans nouveau pouvoir de prime. Le coût/recharge associés restent à éprouver dans le prototype commun. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Centre de lutteur.
- Bois naît et se retire à l’appui.
- Petite échelle.
- Paumes larges, pas Jûken précis.
- Poids visible dans chaque pas.
- Mains ne font pas la même pose à tous les casts.
- Aucun avatar géant.

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

Famille de base : **F5 lutteur/appui**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 prise-paume ; L2 avant-bras bois ; L3 double poussée ; Heavy gaine ; naissance/retrait racine.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L8-B** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Aucun fighter runtime → lutteur/Mokuton local extrapolé, pas copie de Gaara avec FX marron.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L8-B** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
