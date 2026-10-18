# Roster cible DEC-026 (17+3) — gate native du 18/10 (13:39–13:46)

Build : Debug, sources de ce commit (`DevGateCheck` contrôlé dans la place ouverte), Studio Mac, `workspace:SetAttribute("NinjaDuelGate","NEW,NEG,M7")`. 0 erreur serveur dans l'Output pendant la passe.

**Gate durcie (audit Codex F1/F3).** Chaque contrat est obligatoire : légers confirmés, route vers l'avant de son graphe (ou son launcher/proxy), E accepté ou refus `Committed` d'une route qui poursuit seule, au moins un coup aérien, outil accepté (exception : parade de Lee), chaque technique acceptée **avec un effet observé**, garde réellement frappée et tenue (blocage, parade ou bouclier de sable), round 2 propre pour les deux acteurs et cooldowns remis à zéro. Remplacements de position pendant la séquence : oui (sonde serveur par étapes, pas une séquence joueur continue).

| Contrôle | Résultat |
|---|---|
| NEG1 (toutes les attaques du joueur refusées) | **FAIL attendu** → `FAILED[lights,route,E,air]` |
| NEG2 (le bot ne frappe jamais la garde) | **FAIL attendu** → `FAILED[guard]` |
| Q:Rival / N:Rival (Madara) | PASS / PASS — QuillonRise, air 2, UchihaRead+UchihaKaton ; GuardCut, HeelBarrier, PommelRiposte, contre 8,3, Katon devant 9 / flanc 0 |
| Q:Sapling / N:Sapling (Hashirama) | PASS / PASS — StumpRise, air 2, ContactRoot+WoodGuard ; WrestleStep, RootBrake, ShoulderRiposte, contre 8,3 |
| Q:Professor / N:Professor (Hiruzen) | PASS / PASS — StaffLever, air 2, StaffLeverRead+TrainingKaton ; GripSwitch, HeelSweep, StaffThrust, contre 8,0, Katon devant 8 / flanc 0 |
| M7, 20 du menu | **20/20 PASS** (Flashstep, Mirage, GentleFist, Lion, Sand, Leaf, Legion, Copycat, Mirror, Mist, Bone, Flicker, Serpent, Clay, Puppet, Rinnegan, Ink, Rival, Sapling, Professor) |

Défauts trouvés en natif pendant la passe : **Katon court (cône Arc) qui suivait l'auto-facing** pendant l'incantation et brûlait un corps qui avait esquivé sur le côté (gameplay, corrigé : direction figée à la pression). Sonde : garde levée 0,1 s avant le coup = parade, pas blocage ; bot encore tenu par la dernière technique (prison d'eau, tentacule) ; marionnette de Sasori qui maintient le bot en réaction ; frappes aériennes de Gaara plus lentes que l'attente — corrigés dans la sonde, sans toucher au jeu.

Vraies entrées : menu à 20 vu ; Madara et Hiruzen choisis à la souris ; Madara 3 légers au sabre (3 HITS, 30 dégâts, Lee au sol) ; Hiruzen 3 légers au bâton puis Katon (touche 2). Non couvert : manette, ressenti humain, contre-jeu joué par un humain, Hashirama aux vraies touches.
