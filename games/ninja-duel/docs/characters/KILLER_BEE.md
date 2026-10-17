# Killer Bee — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Ink`**, âge affiché14 ; mouvement/clip effectif `Lion`, armes déclarées `none`. Techniques présentes : `Lariat`, `InkMist`, `OctoHold`. Routes : airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`CircleStep`, up=`Launcher`. [Données](../../src/Shared/Wave3.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** Runtime Ink = lutteur sans armes, trois jutsus et famille Lion ; contredit le kenjutsu requis → plus gros chantier de rig/chaîne/poses, conserver Lariat comme option.

**Stade, source et extrapolation :** **EXTRAPOLATION_AUTORISÉE_PAR_BRIEF** : Le brief exige le multi-sabres dès V1 jeune. La référence officielle illustre son kenjutsu à sept lames à une période ultérieure ; ce n’est pas une preuve de cette maîtrise à14. [Référence de période](https://naruto-official.com/news/01_1316). Hors périmètre : Gyûki géant, Bijûdama de terrain, Samehada et tout contrôle adulte parfait. L’ancienne exclusion des sept sabres est remplacée par ce brief.

**Tenue/silhouette :** Tenue d’entraînement de Kumo jeune, cheveux courts, sept fourreaux/points de rangement identifiables ; armes de longueur proportionnée au jeune rig. La silhouette montre les prises de coude/genou sans armure de prime.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Faire lire une lame et frapper d’une autre configuration du corps, avec un kenjutsu multi-sabres rythmé et exposé s’il est mal engagé.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Deux sabres aux mains, troisième retenu sous coude ; autres au fourreau. |
| Jambes / centre de gravité | Base large mais mobile, poids alterné. |
| Avance | Pas dans la ligne de lame, genoux souples. |
| Recul | Recul en garde croisée, lames ne traversent pas le torse. |
| Strafe | Pied glisse pendant échange de prises. |
| Sprint | Course garde deux lames stables, autres rangées. |
| Dash / rush | Entrée d’épaule sous une lame couvrante. |
| Saut | Saut court, armes rapprochées avant décollage. |
| Chute | Lames se referment vers l’extérieur, pas pointe vers soi. |
| Landing | Pieds larges et sabres en barrage, aucun hit gratuit. |
| Garde | Deux lames croisées devant épaule. |
| Esquive | Petit pivot qui change lame exposée. |
| Réaction légère | Bras touché cède, autres lames restent rangées. |
| Réaction lourde | Configuration se défait visiblement, vrai recul. |
| Knockdown / get-up | Armes se rangent/écartent puis roulade, pas sept lames flottantes. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Sabre main droite | Diagonale hanche droite→épaule gauche adverse | Pas intérieur0.45, lame gauche reste en garde | 4.2 | 0.16/0.06/0.20 | sec : Faire lire la lame principale. |
| L2 | Sabre sous coude gauche | Coupe inverse extérieur→côtes pendant rotation retour | Pivot60°, main gauche reçoit une poignée ; pas tour complet | 4.0 | 0.23/0.06/0.18 | retard court→claque : Contact d’un angle impossible au sabreur classique. |
| L3 | Sabre retenu derrière genou droit | Balayage horizontal bas→flanc | Petit kick de hanche ; lame dirigée hors jambe, reprise main à l’arrêt | 4.4 | 0.12/0.07/0.34 | accent syncopé : Troisième configuration visible, pas multiplication de hitboxes. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : lame de coude rabat garde puis épaule/jambe soulève, launcher multi-configuration. |
| Side après1hit | Un hit : échange lame main/coude et pas dehors ; un seul tranchant de contact, pas doublehit simultané. |
| Away après2hits | Deux hits : lame en barrage et kick de retrait avec sabre de genou, configuration se ferme. |
| Air après1hit aérien | Hit air : deux lames rapprochées, un contact puis side change la main active ; down abat le sabre, pas lancer de toutes les armes. |
| Launcher | Poussée de bras/lame depuis un appui de lutteur, pas uppercut de boxe. |
| Air continuation | Une coupe de retour puis finisher à deux lames ; sabre de jambe rangé avant réception. |
| Finisher | Deux lames croisent en grand X, puis Bee se découvre pendant reprise de prise. |
| Wall / sortie de mur | Lame garde le flanc au mur, appui de pied change le corps ; aucun sabre traverse surface. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Garde croisée ouvre en X, poids avance d’épaule, deux lames suivent des plans distincts mais un seul accent de dégâts ; portée4.8. Reprise de configuration longue si whiff.

**A/C/R de départ pour Heavy : .30/.09/.42s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Garde multi-lames, esquive de pivot, contre par lame non attendue ; garde réussie adverse arrête réellement un contact. Lariat raté laisse une punition.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Exigence V1 : sept sabres physiques portés, au moins trois prises/configurations actives visibles dans L1–L3 (mains, coude, genou). Les autres restent rangés selon phase ; pas sept scripts/collisions par frame. Multi-lames enfant = extrapolation explicite autorisée par ce brief, remplace ancienne exclusion documentaire.

**Configurations d’attache minimales :** A = deux lames en mains, troisième sous coude gauche, quatre autres rangées physiquement. L1 touche avec la main droite ; transition L1→L2 échange lame de main gauche et lame de coude avec un bref croisement visible, L2 touche depuis le coude ; transition L2→L3 conduit la lame libérée jusqu’à l’arrière du genou droit, pointe orientée hors du corps, L3 touche par ce nouveau levier. Pendant sa récupération la main libre récupère cette lame et rend la configuration A (les identités des trois lames peuvent permuter). Aucun objet ne saute d’attache après son contact, aucun tranchant actif traverse le propre torse. Les quatre lames rangées ne créent pas de dégâts ; elles restent des armes du set, leur utilisation simultanée complète n’est pas nécessaire pour reconnaître le multi-sabres dès V1. Heavy croisé et Lariat utilisent une configuration de rangement déterministe, pas un bouton de sélection de lame.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Changement de configuration | Intégré Light/Side/Heavy, pas nouveau bouton | Reprise poignées mains→coude→genou au bon accent | Change angle et rythme au corps-à-corps | Lire pied/hanche, punir échange de prise | Une route puis finisher |
| Lariat | Signature conservée | Lames rangées avant bras/épaule engagés | Punition de course, garde de sortie | Esquive et whiff long | Finisher alternatif, pas cumul automatique |
| Manteau partiel | État spécial actuel | Corps se tasse, arme garde priorité de silhouette | Permet trade limité | Gros contrôle/temps mort de reprise | Pas bijû complet |

## 10. Awakening / état spécial

Heavy/Armor partiel : permet de maintenir une configuration contre un léger impact, mais une interruption forte la casse. Pas tous les sabres plus tentacules autonomes plus invulnérabilité.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Trois prises visibles minimum.
- Sept armes portées, pas sept hits.
- Coude et genou expliquent le tranchant.
- Un échange de prise a un temps mort.
- Rythme irrégulier lisible.
- Lames restent hors du propre corps.
- Lariat range les lames.
- Pas Lee avec lames collées.

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

Famille de base : **F4 configurations de lames**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 lame main ; L2 lame coude ; L3 lame genou ; Heavy X ; reprise/rangement de configuration.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L7-B** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Runtime Ink = lutteur sans armes, trois jutsus et famille Lion ; contredit le kenjutsu requis → plus gros chantier de rig/chaîne/poses, conserver Lariat comme option.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L7-B** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
