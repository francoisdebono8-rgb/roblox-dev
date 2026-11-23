# Facile au premier usage, profond par combinaison

Ces six options existent comme **plans purs optionnels**, sans binding clavier/manette, sans délai actif et sans modification de Input. Le même moteur de règles reste utilisable quel que soit le choix de Claude.

| Option / mode | Apprentissage | Profondeur | Exécution en combat | Manette | Surcharge / limite |
|---|---|---|---|---|---|
| Technique active / AutoTechnique | Très facile : la technique indique l'infusion | Combinaisons technique × outil × surface | Immédiate | Excellente, aucune nouvelle touche | Faible ; rendre la nature prévisible, éviter les surprises |
| Modifier / Modifier | Facile après une indication claire | Choix volontaire sur une même action | Rapide, accord de touches | Bonne si un bouton existant peut réellement être partagé | Moyenne : vérifier les conflits avant mapping, aucun bouton réservé ici |
| Contextuelle / Contextual | Facile si le contexte est visible | Placement, timing et propriétés disponibles | Immédiate | Excellente | Faible en touches, plus forte en ambiguïté si plusieurs contextes sont compatibles |
| Preset / Loadout | Très facile en combat, petit choix hors combat | Préparation et spécialisation selon personnage | Immédiate | Excellente | Faible ; limiter le nombre de presets affichés, changements éventuels à décider |
| Hold/release / HoldRelease | Compréhensible avec un signal de préparation | Intentions/feintes et relâchement choisi | Plus lente par nature | Bonne | Moyenne : risque de concurrencer charge/maintien actuels ; Claude décide la qualification du hold |
| Compatibilité automatique / CompatibleAuto | Très facile au début | Profondeur portée par les objets/propriétés en scène | Immédiate | Excellente | Faible en touches, élevée si les règles ne sont pas lisibles ou si l'automatisme surprend |

Hypothèse à **tester**, sans l'imposer : commencer par AutoTechnique ou Loadout pour une nature prévisible avec l'action existante. Ajouter éventuellement une décision contextuelle lisible, puis un override volontaire si le jeu le justifie. Éviter un menu radial obligatoire au milieu de chaque lancer. Profondeur à tirer des combinaisons et du placement avant d'ajouter des boutons.

`ChakraInputPlan` reçoit `intent={action=<action existante>,modified?,released?}` et un **contexte serveur** : tool, techniqueInfusion, selectedInfusion, contextInfusion, compatible, loadout, holdQualified, availableProperty, propertyInfusion. Il retourne candidate/compatible/infusion, la même action, et exige la validation serveur. Un outil incompatible garde le plan None ; cela ne bloque aucune action du gameplay actuel. Les bindings, prompts PS5, seuils hold et changements de presets restent à choisir/tester par Claude dans la couche d'input existante.

Validation humaine après intégration choisie : premier lancer compréhensible sans explication longue ; nature et coût perceptibles ; aucun conflit clavier/PS5 ; pas de perte du garde/dash/substitution ; bon comportement en spam/hold/release ; compatibilité compréhensible sur mur/sol/outils ; un expert gagne des possibilités par combinaison plutôt que par multiplication des touches. Aucun PASS de feel n'est revendiqué ici.
