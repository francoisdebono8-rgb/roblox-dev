# Sasori — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Puppet`**, âge affiché14 ; mouvement/clip effectif `Sand`, armes déclarées `none`. Techniques présentes : `Marionette`, `FatherMother`, `NeedleRain`, `PuppetShield`. Routes : airDown=`AirSpike`, airUp=`AirDrive`, down=`PuppetSweep`, side=`FeintStep`, up=`PuppetRise`. [Données](../../src/Shared/Wave3.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** M1 (`41364ed`) restaure le porteur persistant après proxy et interdit le poison sur garde ; validation native de ce delta encore attendue. Light Sand reste porté par le maître → alternance maître/marionnette à chorégraphier.

**Stade, source et extrapolation :** **Période cible de design : jeune/prodige, environ12–14ans, pas une égalisation de puissance adulte.** Les âges du runtime15 chez Haku/Deidara restent des faits du build, pas un arbitrage canon de cette bible. Les gestes précis, rythmes, distances et traductions corporelles ci-dessous sont des **GAMEPLAY_LIBERTY de conception** retenues pour cette V1 ; les techniques de période non attestée restent signalées, sans effacer la fantasy du prodige. [Source officielle Sasori](https://naruto-official.com/en/news/01_1641) — enfance et parents-puppets, pas arsenal complet à14. Exclusions/point de période : Corps-pantin adulte, Troisième Kazekage/Sable de fer, armée de cent ; poison et FatherMother de combat à14 nécessitent preuve ou liberté explicite.

**Tenue/silhouette :** Tenue de jeune Suna brun/ocre, cheveux roux courts, mains de marionnettiste et fils visibles ; marionnette en bois distincte, pas corps-pantin adulte de Sasori.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Contrôler deux corps avec un seul cerveau : le maître donne le rythme et la marionnette déplace l’origine du danger.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Doigts écartés devant taille, torse calme. |
| Jambes / centre de gravité | Base stable, poids légèrement arrière. |
| Avance | Maître avance lentement, porteur prend le poste. |
| Recul | Retrait du maître tandis que fils restent tendus. |
| Strafe | Petit pas latéral du maître et déplacement opposé du porteur. |
| Sprint | Course retenue, mains ramènent les fils. |
| Dash / rush | Maître se replace court, puppet ne téléporte que sous règle proxy explicite. |
| Saut | Saut bref du maître, porteur reste source séparée. |
| Chute | Doigts se rapprochent, fils lisibles. |
| Landing | Maître amortit, porteur retrouve son poste. |
| Garde | Main relève un bouclier-puppet sous fenêtre, corps maître vulnérable. |
| Esquive | Pas du maître pendant porteur couvre une ligne choisie. |
| Réaction légère | Doigts se crispent et une commande se décale. |
| Réaction lourde | Maître perd sa ligne, porteur cesse la route sans mourir automatiquement. |
| Knockdown / get-up | Maître tombe/reprend fils après relevé, aucun contrôle zombie. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Sasori, main gauche/fil court | Poignet chasse le bras adverse | Petit pas arrière0.25 ; puppet gagne0.5 sur flanc | 3.0 maître | 0.12/0.05/0.20 | bref : Fixer l’attention et préparer le second corps. |
| L2 | Puppet, avant-bras lame | Flanc choisi→côtes | Maître pivote0.3, porteur frappe depuis vrai poste | 5.2 porteur | 0.24/0.07/0.20 | contretemps : Changer origine de la garde. |
| L3 | Puppet croise, Sasori repositionne | Autre bras du puppet rabat vers épaule | Maître sort0.6 et récupère les fils | 5.5 porteur | 0.28/0.07/0.34 | accent croisé : Finir en deux positions lisibles, pas deux hits simultanés gratuits. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : maître tire la main, puppet frappe de bas en haut sous cible ; porteur reste vivant après. |
| Side après1hit | Un hit : maître recule d’un côté, puppet avance de l’autre et coupe le bras ; budget de branche unique. |
| Away après2hits | Deux hits : puppet fauche pendant que maître récupère la laisse, puis les deux se séparent. |
| Air après1hit aérien | Hit air : puppet porte une frappe à hauteur bornée puis rabat ; maître ne devient pas kick fighter volant. |
| Launcher | PuppetRise depuis vrai corps secondaire, pas depuis main du maître. |
| Air continuation | Une frappe portée puis finisher de rabat ; pas nouvelle invocation de combo gratuite. |
| Finisher | PuppetBlade de croisement ou retrait protégé, choix ; s’il est détruit, version solo courte de secours. |
| Wall / sortie de mur | Poste local au bord du mur, laisse/LOS ; porteur ne frappe jamais depuis décor. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Maître tire deux fils en opposé, puppet avance les deux bras en ciseaux puis se retire ; portée5.8 depuis le porteur, anticipation du déplacement visible. Sans puppet : simple paume de recul au contact, nettement moins de contrôle.

**A/C/R de départ pour Heavy : .34/.08/.40s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Garde du maître normale courte ; PuppetShield est une lecture, pas protection passive totale. Esquive déplace maître, contre du porteur si fenêtre ; bloquer jab empêche poison accidentel.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Marionnette persistante intégrée à L2/L3/routes, fils changent vraiment de direction ; un seul propriétaire de hit et contre-jeu sur corps secondaire. Réutiliser Bodies, jamais second moteur.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Marionnette | Summon/Lunge actuel | Mains tirent puis porteur arrive de côté | Créer poste attaquable et lunge commandé | Détruire porteur/attaquer maître | Light chain utilise porteur existant |
| Embrassement | FatherMother retenu sous forme courte | Deux mains ferment une pince | Prise préparée à deux trajectoires | Éviter la fermeture/substituer | Un finisher, pas auto-summon armée |
| Bouclier-puppet | Counter existant | Main relève puis porteur interpose un bras | Répond à une lecture proche | Bait/flanc/attendre | Une riposte, pas contrôle autonome infini |

## 10. Awakening / état spécial

PuppetMaster : déplacement du maître après une riposte réussie garde une commande croisée, pas double puppet gratuit ; conserver poison/entrave bornés. Persistance et budget commun doivent fonctionner avant ajout.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Maître ne mime pas les coups.
- Fils montrent la commande.
- Porteur a des appuis.
- Espacer les origines de hit.
- Ne pas cacher la cible par fumée.
- Destruction expose le maître.
- Retour de route conserve le corps persistant.

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

Famille de base : **F7 maître / porteur**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 commande/contact ; L2 coupe puppet ; L3 attaque croisée ; Heavy ciseaux ; reprise de fils/porteur.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L5** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

M1 (`41364ed`) restaure le porteur persistant après proxy et interdit le poison sur garde ; validation native de ce delta encore attendue. Light Sand reste porté par le maître → alternance maître/marionnette à chorégraphier.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L5** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
