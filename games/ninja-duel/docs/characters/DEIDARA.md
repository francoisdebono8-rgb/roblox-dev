# Deidara — Character V1 Combat Bible

**Design cible, pas implémentation.** Révision18/10/2026, audit du HEAD `41364ed` (M1 inclus ; dernière preuve native `bc7faa3`). [Roster cible / A–E globaux](ROSTER_20.md) · [contrat V1](FIGHTER_TEMPLATE.md) · [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles). Claude garde le bloc en cours ; cette bible ne lance aucun travail concurrent.

## Audit initial — ce qui existe réellement

**Présent sous `Clay`**, âge affiché15 ; mouvement/clip effectif `Mirage`, armes déclarées `none`. Techniques présentes : `ClayBirds`, `ClaySpiders`, `ClayMine`, `Katsu`. Routes : airDown=`AirSpike`, airSide=`AirSwitch`, airUp=`AirDrive`, down=`Sweep`, side=`FeintStep`, up=`Launcher`. [Données](../../src/Shared/Wave3.luau), [graphe](../../src/Shared/MoveGraphs.luau), [moteur de poses](../../src/Client/VelmoraMotionEngine.luau). Les noms de routes ne prouvent ni leur chorégraphie ni le feel ; seules les observations datées de CURRENT_STATE sont des preuves natives.

**Écart décisif :** Charges/Katsu existent, corps Mirage reste générique → pression de placement/pose dès la chaîne et défense avec vrai engagement.

**Stade, source et extrapolation :** **Période cible de design : jeune/prodige, environ12–14ans, pas une égalisation de puissance adulte.** Les âges du runtime15 chez Haku/Deidara restent des faits du build, pas un arbitrage canon de cette bible. Les gestes précis, rythmes, distances et traductions corporelles ci-dessous sont des **GAMEPLAY_LIBERTY de conception** retenues pour cette V1 ; les techniques de période non attestée restent signalées, sans effacer la fantasy du prodige. Exclusions/point de période : C2/C3/C4/C0, suicide, vol géant ; pas multiplication d’explosifs pour compenser une mine illisible.

**Tenue/silhouette :** Tenue jeune d’Iwa proposée, blond avec mèche latérale et attache haute, poches d’argile accessibles ; mains lisibles ; pas cape Akatsuki comme raccourci d’identité.

Les choix de corps/gestes et de signatures de cette bible forment le design V1 proposé à exécuter quand le lot sera ouvert. Les temps/portées sont les cibles de départ de la chorégraphie, pas un équilibrage compétitif final. Aucune validation Studio des nouveaux gestes n’est annoncée.

## 1. Combat identity

**Toucher pour repousser ou poser une petite menace, puis gagner l’espace qui rend son argile dangereuse.**

Test : HUD/nom/couleur de joueur masqués, le reconnaître par appuis, gestes et origine du contact. La signature complète l’échange, elle ne remplace pas trois attaques génériques.

## 2. Silhouette corporelle

| État | Direction pour pose et transition |
|---|---|
| Idle / bras | Mains près poches d’argile, une épaule en arrière. |
| Jambes / centre de gravité | Base légère, poids prêt au retrait. |
| Avance | Pas d’approche prudent, mains façonnent peu. |
| Recul | Recule en oblique et regarde le sol de pose. |
| Strafe | Change d’angle plutôt que tourner autour en mêlée. |
| Sprint | Course de placement, pas sprint de lutteur. |
| Dash / rush | Bond court de retrait avec fin d’appui visible. |
| Saut | Saut qui libère une main de lancer. |
| Chute | Corps protège poche et prépare réception. |
| Landing | Petit pas de fuite latéral, pas bombe gratuite automatique. |
| Garde | Avant-bras poussent puis cherchent la sortie. |
| Esquive | Paume détourne, main peut laisser un objet sous engagement. |
| Réaction légère | Tête recule, poche protégée. |
| Réaction lourde | Corps plie, mains ne continuent pas à poser sous hitstun. |
| Knockdown / get-up | Chute roulée loin de l’argile, relève sans nouvelle mine gratuite. |

Réactions reçues = vrais dégâts/states communs, avec interprétation corporelle ci-dessus ; aucune esquive/invulnérabilité implicite parce qu’une animation paraît agile. L’appui et la protection s’ouvrent effectivement sur une réaction lourde.

## 3. Light chain — contacts physiques

Repère : droite/gauche = corps de l’attaquant ; direction décrite face à l’adversaire. Distances en studs du rig actuel jusqu’au point de contact, pas rayon d’une sphère invisible. A/C/R = anticipation / fenêtre de contact / récupération, en secondes, **cibles initiales à tester**. Le serveur reste autoritaire ; la phase C et le vrai membre/objet coïncident. Le récepteur réagit selon la zone touchée, pas par le même grand recul sur tous les L1.

| Hit | Membre / arme | Trajectoire | Appuis / déplacement du corps | Distance | A/C/R | Rythme / intention |
|---|---|---|---|---:|---|---|
| L1 | Gauche, paume de dégagement | Centre→bras/épaule | Pas en retrait0.3, poids sur pied arrière | 3.0 | 0.14/0.06/0.20 | pousse : Dégager un angle, pas jab offensif. |
| L2 | Droite, revers de paume | Extérieur→torse, petite argile reste au contact | Pied latéral0.4 ; objet non armé brièvement | 3.1 | 0.21/0.06/0.24 | court→pause : Préparer une menace qui remplace un gros dommage. |
| L3 | Jambe avant, poussée basse | Pied vers hanche adverse pendant main se retire | Recul0.7, hanche reste face | 3.5 | 0.23/0.07/0.32 | accent de sortie : Créer de l’espace pour activer ou abandonner l’objet. |

**Transitions :** L1 rend une pose intermédiaire où la garde, le bras libre et le pied pivot restent lisibles ; L2 n’oblige pas à finir ; L3 non branché termine, avec récupération/retour en garde. Aucun reset gratuit de combo par apparition d’une arme, pose d’objet ou coup autonome d’un corps secondaire. Sur garde/whiff : pas d’ouverture de branche directionnelle ni auto-poursuite.

## 4. Branches de combo

Invariant serveur : **avant premier hit confirmé, Light reste L1 quelle que soit la direction tenue**. Side seulement après1hit ; Forward/Away après2hits ; branche air après1contact aérien. Le symbole direction est relatif à l’adversaire, pas au nord de la carte.

| Branche / rôle | Chorégraphie et sortie |
|---|---|
| Forward après2hits | Deux hits : paume basse et petit souffle d’argile soulèvent, pas launcher athlétique de Lee. |
| Side après1hit | Un hit : paume pousse et pas extérieur laisse une création courte à place fixe ; elle compte dans limite des charges. |
| Away après2hits | Deux hits : revers défensif puis retrait, petite création possible à la place du contact bonus, jamais stack gratuit. |
| Air après1hit aérien | Hit air : petit pied de séparation, lancer orienté de fin ; down oriente la retombée sans kick de champion. |
| Launcher | Création locale ponctuelle avec annonce claire, une seule impulsion. |
| Air continuation | Un contact d’éloignement puis finisher d’argile ; pas vol libre ni juggle de bombes. |
| Finisher | Katsu ou poussée physique, explosion remplace contact final plutôt que s’y ajouter sans budget. |
| Wall / sortie de mur | Pose sur sol/surface valide bornée, pas mine sur point libre hors Range. |

**Borne V1 anti-infini :** une branche sol consomme sa continuation, au plus une poursuite puis deux contacts air avant finisher/neutral. Une signature de conversion remplace la fin, ne remet pas le budget à zéro ; un rebond de mur n’accorde pas un nouveau launcher. Réutiliser les fenêtres/compteurs/scaling du moteur ; vérifier s’ils suffisent avant tout hook local. Pas nouveau système de combo parallèle.

## 5. Heavy propre

Deux paumes préparent une motte, pied arrière charge puis main pousse/claque au contact ; petite explosion de séparation, portée3.5. Whiff laisse Deidara proche et occupé ; ne doit pas devenir un uppercut universel.

**A/C/R de départ pour Heavy : .30/.08/.40s**, cible de chorégraphie à éprouver, pas équilibre final.

Pose de charge distincte du launcher ; le joueur peut lire l’engagement. Heavy neutral et Heavy après hit réutilisent les mêmes points d’appui mais la version après confirmation peut raccourcir l’anticipation selon fenêtres communes. Une garde tient/rompt selon les règles, pas selon une nouvelle exception nominative.

## 6. Défense

Bloc court pour sortir, esquive de placement ; une petite création défensive exige une fenêtre/limite et ne touche pas automatiquement. Substitution ne sème pas gratuitement une mine à chaque usage.

Tester : garde tenue, parade ratée, dodge baité, reprise après knockdown. La garde adverse reste une réponse valable ; le déséquilibre n’est pas une permission de toucher depuis n’importe où. Les réactions de famille restent partagées mécaniquement mais avec poses locales.

## 7. Armes intégrées au corps-à-corps

Argile passe par les mains/poche pendant la chaîne. Objet de L2/Side compte comme une charge existante, pas un deuxième système de pièges.

**Contrat de présentation/contact :** équiper/ranger/prolonger un objet à un marqueur d’action, choisir le bon point d’origine de hit, garder une seule comptabilité du contact. Le modèle ne doit ni apparaître après l’impact ni rester collé dans une mauvaise prise. Équipement V1 fixe et points d’attache suffisent ; système armes global et inventaire futur exclus.

## 8. Pouvoirs intégrés aux gestes

Les pouvoirs/corps/objets décrits dans L1–L3 et les branches font partie de l’identité de base : ils ne sont pas différés au système chakra final. Ils utilisent les familles/traits/corps actuels et des limites locales explicites ; ils ne donnent pas de dégâts bonus simplement parce qu’une trace/épine/clone est visible. Un effet de contact intégré exige le même hit confirmé et la même vérification de garde que le contact physique.

**Sans signature disponible :** conserver cette silhouette, les trois gestes et leurs intentions ; ne pas retomber sur jab→jab→kick. **Interrompu :** annuler les contacts futurs et rendre une pose vulnérable, ranger/rétracter ce qui doit l’être ; aucun corps/objet zombie au round suivant.

## 9. Signature abilities strictement nécessaires

Les signatures ci-dessous complètent la boucle. Ce n’est pas la liste de tout l’arsenal adulte et ce n’est pas une obligation de garder tous les anciens slots. Les slots actuels non retenus ne sont pas supprimés par Codex : écart à traiter par Claude dans le lot ouvert et à consigner. Activation par les actions/manette existantes, pas une nouvelle touche par sous-geste.

| Signature | Activation | Mouvement du corps | Comportement / usage tactique | Contre-jeu | Conversion autorisée |
|---|---|---|---|---|---|
| Création C1 | Oiseau/araignée du kit | Main façonne puis lâche un vrai petit objet | Force un trajet ; raté peut rester charge | Garde/contourner/détruire selon type | Choisir faire pression ou poser |
| Charge au sol | ClayMine | Main basse et pas de retrait | Une petite zone de menace armée après délai | Sortir avant armement, borne de portée | Un trigger ou Katsu, jamais les deux dégâts |
| Katsu | Signature actuelle | Doigts se referment, corps surveille l’espace | Détonne les charges posées | Lire objets/détonation et sortir du rayon | Finisher ou remise à distance |

## 10. Awakening / état spécial

ChainCharges déjà livré : réactions en chaîne locales au lieu de plus de dégâts partout. Nouvelle création déclenchée par combo respecte plafond/consommation et garde un délai lisible.

Condition/durée/coût du build restent le point de départ jusqu’au lot de tuning autorisé. Entrée/sortie par geste et état lisibles, pas simple aura plus rouge. Arrêt au KO/reset, aucune combinaison de buff ne masque une règle. Si le stade ne justifie pas un éveil canon, la focalisation technique décrite est une **GAMEPLAY_LIBERTY**, pas un pouvoir adulte affirmé.

## 11. Animation language

- Corps veut sortir.
- Une paume crée espace.
- Argile réellement façonnée.
- Objets peu nombreux et lisibles.
- Pas kicks de Lee.
- Pose/détonation séparées.
- Une défense n’offre pas une bombe gratuite.

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

Famille de base : **F6 retrait / pose**. Partager le rig, les phases startup/active/recovery, transitions d’appui, contrôles/collision et courbes de réaction ; adapter pose/portée/prise/origine de contact. Même mécanisme ≠ même silhouette. Voir [matrice globale A](ROSTER_20.md#a-animation-reuse-matrix).

## B. Unique animation requirements

L1 dégagement ; L2 paume-pose ; L3 poussée sortie ; Heavy motte ; mouvement de retrait-création.

Cinq unités d’auteur prioritaires (L1/L2/L3/Heavy + un geste signature/transitoire), pas cinq nouveaux assets Roblox obligatoires ; variations de routes dérivent de ces appuis avec marqueurs distincts. Si le clip actuel satisfait déjà le brief, le garder et prouver à l’image. Réactions/get-up s’appuient sur la famille avec pose finale propre.

## C. Implementation priority

**Priorité de design P1**, lot proposé **L6** ; ce n’est pas la priorité d’un bug P0 runtime. Les corrections Claude déjà en cours continuent. Ordre d’ouverture et dépendances dans MASTER_BACKLOG ; [table globale C](ROSTER_20.md#c-implementation-priority).

## D. Current-vs-target gap

Charges/Katsu existent, corps Mirage reste générique → pression de placement/pose dès la chaîne et défense avec vrai engagement.

**Vérification Studio du lot :** (1)20s HUD masqué sans signatures, locomotion/garde/réactions ; (2)L1–L3→branche→air/finisher sans replacement ; (3)neutral directionnel/garde/whiff ne déclenchent pas de route ; (4)Heavy raté puis punition et substitution ; (5)signature intégrée, interruption, KO/reset ; (6)contre un adversaire mobile à la manette. Montrer avant/après et un consommateur ancien du hook partagé. Ne pas clôturer par headless, spawn ou screenshot isolé.

## E. Claude execution batch — prise en main

Lot proposé **L6** : lire cette bible, le contrat commun et les seuls hooks concernés ; traiter d’abord les cinq unités B et l’intégration physique, ensuite les branches/signatures. Ne pas construire les hooks futurs de §12. Un commit cohérent par paquet : corps/Lights/Heavy, puis routes/signature, puis correctifs/rapport Studio si nécessaire ; pas vingt contextes à charger. [Lots globaux E](ROSTER_20.md#e-claude-execution-batches).
