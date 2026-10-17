# Combat — grammaire et liberté

IDs : COM-001..007, DEF-001..005, QA-004, TOOL-005. Contrat actuel : [COMBAT_CONTRACTS](../../current/COMBAT_CONTRACTS.md), [inventaire](../../current/COMBAT_INVENTORY.json). Combat/Brawler/MoveGraphs/Attacks/VelmoraDefense sont l’autorité technique ; lire leurs branches au lieu de construire un second combat controller.

## Déjà présent techniquement

Ground strings, branches directionnelles, launcher/chase, air light/slam, grabs et throws directionnels, wall routes, guard/parry/dodge/substitution/riposte/clash. COM-001/DEF-001/004 sont clos pour leurs contrats automatiques ; leur qualité perceptive est portée par d’autres tickets. Action, réaction et terrain sont des axes distincts. OffBalance n’est pas une enum actuelle ; GuardBreak est un résultat ; Clash est un événement vers Recovery.

## Intentions à juger et compléter

La boucle entre combos doit compter : run→slow/read→feint→tool→dodge/deflect→angle→clash→shortstrike→counter→pursuit→conversion→disengage. Une longue séquence garantie ou une route optimale obligatoire réduit la liberté. Garder la possibilité de sortir et d’entrer autrement.

Taijutsu : coups courts jab/cross/hook/palm/elbow/knee, low/sweep/spin kicks, launcher/anti-air/pursuit/spike/side switch, wall splat/run/reentry, grabs/throws et contrôle court du membre. Un contact crée un état exploitable ; une transition crée un choix ; le personnage choisit sa conversion. Les briques communes gardent des physiques/rythmes spécifiques.

Défenses : appui/angle/membre lisibles pour esquive, parade, déviation et riposte ; parry et perfect dodge bornés, substitution coûteuse et vulnérabilités compréhensibles, pas sorties gratuites répétables. Frappes simultanées ont du conflit ; projectile/tool clashes généraux restent à évaluer séparément de Geometry spécifique.

Prises/micro-échanges : poignet tenu, pied retenu, contact air/mur ou projection courte doivent rester physiques et offrir une sortie/contre-jeu. Aucun film de dix secondes. Hits, guardbreak, recoil, launch, hitstun, wallpin/bounce/tech, knockdown/wakeup/KO ont une réaction cohérente et une récupération lisible.

Les routes up/down/side et conversions outils→melee, air→wall, teleport→followup ne doivent pas faire explosion d’inputs. Whiff, coût, fenêtre, cancel et recovery restent des contraintes réelles ; tester répétitions, infinites, cooldowns et ordres atypiques.

## Validation

Pour toute correction : identifier intention, comportement actuel et reproduction ; protéger tests existants ; montrer contact/cible/reaction/timecode native et preuve manette. Lire toutes les sections liées des sources, ne pas transformer cette synthèse en liste exhaustive de clips.

Sources intégrales : [final](../missions/CLAUDE_FINAL_PASS.md), [phase4](../missions/CLAUDE_PHASE_4_GAMEFEEL_ARENA_DEPTH.md), [arena/combo](../missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md), [verbs/states](../design_research/01_combat_grammar/COMBAT_VERBS_AND_STATES.md), [building blocks](../design_research/01_combat_grammar/COMBO_BUILDING_BLOCKS.md). Les nouvelles propositions research doivent passer les décisions lore et une évaluation pratique.
