# Shisui — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Flicker`**, âge affiché13 ; mouvement/clip effectif `Lion`, armes déclarées `kunai`. Techniques présentes : `BodyFlicker`, `FlickerOut`, `ShisuiFireball`, `ShisuiGenjutsu`. Routes : airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`FlickerStep`, up=`Launcher`. [Données](../../src/Shared/Wave2.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** ChainTeleport natif fonctionne ; corps Lion et FlickerStep emprunté ne donnent pas Shunshin partout → rafales, fausses continuités et coups courts cohérents.

**Stade, source et extrapolation :** **Période cible de design : jeune/prodige, environ12–14ans, pas une égalisation de puissance adulte.** Les âges du runtime15 chez Haku/Deidara restent des faits du build, pas un arbitrage canon de cette bible. Après-images : interprétation anime/perception adaptée en traces sans dégâts ; référence de médium à confirmer, pas canon manga automatique. Les gestes précis, rythmes, distances et traductions corporelles ci-dessous sont des **GAMEPLAY_LIBERTY de conception** retenues pour cette V1 ; les techniques de période non attestée restent signalées, sans effacer la fantasy du prodige. [Source secondaire Shisui](https://naruto.fandom.com/wiki/Shisui_Uchiha) — distingue après-images anime et variantes jeux ; référence primaire/âge à confirmer. Exclusions/point de période : Kotoamatsukami, Susanoo et variantes jeux/OVA hors scopeV1 ; pas les déclarer tous adultes par erreur. Après-images anime = support séparé à confirmer, pas canon manga automatique.

**Tenue/silhouette :** Tenue Uchiha sombre à col haut, touches vertes sobres, cheveux noirs courts, bandeau et petit tantō si validé par référence ; posture mobile, pas robe Akatsuki.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Changer d’angle par rafales de Shunshin, laisser une fausse continuité puis frapper depuis la vraie position.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Torse incliné, main droite près du tantō, gauche flottante. |
| Jambes / centre de gravité | Pieds en décalage, poids sur avant-pied sans saut permanent. |
| Avance | Deux pas courts puis accélération. |
| Recul | Retrait diagonal plutôt que marche arrière longue. |
| Strafe | Hanches réorientent avant tête, épaules suivent. |
| Sprint | Foulée rapide basse, bras coupent peu l’air. |
| Dash / rush | Rafale de trajet court, trace qui s’éteint derrière lui. |
| Saut | Départ compact avec genou guidant le côté. |
| Chute | Corps oblique, arme près du torse. |
| Landing | Pied extérieur freine puis bassin se recentre. |
| Garde | Tantō/avant-bras ferme une ligne étroite. |
| Esquive | Petit Shunshin tangent ; vrai corps reste traçable. |
| Réaction légère | Glissement d’appui, tête ne disparaît pas gratuitement. |
| Réaction lourde | Rafale interrompue, corps trébuche sans faux dodge. |
| Knockdown / get-up | Roule épaule puis reprend un angle, pas teleport get-up. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Droite, tantō revers | Hanche gauche→côte droite adverse | Pas intérieur0.5, torse tourne30° | 3.4 | 0.10/0.05/0.18 | sec : Entrer sans promettre téléport gratuit. |
| L2 | Gauche, paume et tranche courte | Main libre vers bras, lame revient extérieure | Demi-pas latéral0.6 dans la même continuité | 3.2 | 0.18/0.05/0.16 | pause courte→claque : Déplacer attention vers la trace du pas précédent. |
| L3 | Droite, coupe de déséquilibre | Extérieur→épaule, pas de grand kick | Rafale oblique0.8 puis pied frein visible | 3.7 | 0.12/0.06/0.28 | accéléré→arrêt : Finir sur un angle choisi, récupération réelle. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : pas intérieur puis genou/coupe montante ; un Shunshin court suit le déplacement réel, sans nouveau hit automatique. |
| Side après1hit | Un hit : dash tangent de30–45° et coupe courte ; après-image reste au départ0.2–0.35s, aucun faux corps ne touche. |
| Away après2hits | Deux hits : coupe basse de freinage puis recul de face ; une trace s’éteint à l’ancienne position. |
| Air après1hit aérien | Hit air : frappe de tantō courte ; side recroise sur un trajet borné, down coupe vers sol ; aucun warp mondial. |
| Launcher | Genou montant qui soulève pendant que tantō garde la ligne ; choix sol ou poursuite. |
| Air continuation | Une reprise par rafale aérienne puis coupe descendante ; pas retour au launcher. |
| Finisher | Coupe croisée de flanc, trace poursuit brièvement l’ancienne direction ; vrai corps s’arrête en garde. |
| Wall / sortie de mur | Rebond corporel sur mur visible ; conserve trajectoire et collision, pas traversée. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Le pied arrière charge, lame tenue court ; coupe traversante épaule→hanche et frein du pied extérieur. Portée4 ; trace en retard sur trajet, pas hitbox fantôme. Whiff laisse le bras ouvert.

**A/C/R de départ pour Heavy : .22/.07/.32s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Garde étroite ; dodge tangent du vrai corps ; contre après feinte lue, pas attaque depuis une image. Substitution distincte du Shunshin normal ; get-up reste physique.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Tantō/kunai vrais dans les attaques ; après-images attachées au trajet, une seule origine serveur de dégâts. Vitesse corporelle différente du FTG préparé de Minato.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Rafale de Shunshin | Dash/dodge existant contextualisé | Bassin part puis pied de frein final visible | Deux orientations possibles, une trace non offensive | Zone, garde orientée et arrêt exposé | Transition après hit, pas ouverture directionnelle spéciale |
| Coupe de flanc | BodyFlicker conservé | Départ/arrivée avec pose de coupe cohérente | Punit une orientation depuis une vraie portée | Garde/whiff ne rendent pas la chaîne | Éveil autorise répétition bornée existante |
| Feinte de perception | Jutsu genjutsu existant | Main libre ferme le champ puis pas latéral | Une fausse continuité brève invite une réponse | Attendre/zone/viser le vrai déplacement | Une ouverture à lire, pas stun gratuit |

## 10. Awakening / état spécial

Conserver ChainTeleport : trois refreshs sur coupes touchées, zéro sur garde/whiff. Les rafales montrent trois reprises puis fin lisible ; traces ne deviennent pas clones combattants.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Une trajectoire réelle par déplacement.
- Frein et réapparition visibles.
- Traces ne portent aucun hit.
- Rafale brève puis immobilité.
- Petites rotations, pas ballet360°.
- Lame suit la main.
- Shunshin touche aussi les transitions, pas seulement un bouton.

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

Famille de base : **F2 rafales tangentes**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 revers ; L2 décalage-paume ; L3 coupe freinée ; Heavy croisé ; transition rafale/trace sur locomotion.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L2-B** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

ChainTeleport natif fonctionne ; corps Lion et FlickerStep emprunté ne donnent pas Shunshin partout → rafales, fausses continuités et coups courts cohérents.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L2-B** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
