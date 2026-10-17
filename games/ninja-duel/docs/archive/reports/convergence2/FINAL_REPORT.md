# Rapport final — Convergence combat 2 et addendum d’autonomie (DEC-014, DEC-015)

Date : 2026-10-16. Branche : `claude/ninja-duel-2026-10-14` (tête au moment du rapport : voir `git log`). Missions : [CORE_COMBAT_CONVERGENCE_2](../../missions/CORE_COMBAT_CONVERGENCE_2.md), [LIVE_AUTONOMY_ADDENDUM](../../missions/LIVE_AUTONOMY_ADDENDUM.md). Rapports de passe : [combo / entrées / réengagement](COMBO_INPUT_REENGAGE.md), [identité CORE4 et jutsus](IDENTITY_JUTSU.md), [chakra systémique](CHAKRA_TOOLS.md), [Rock Lee](ROCK_LEE_STRESS_TEST.md), [outils de dev](DEVTOOLS_PORT.md).

Types de preuve : **TECHNIQUE** (suite headless qui échoue sur l’ancien code), **NATIVE_STUDIO** (mesuré ou vu dans Studio sur la place Debug construite, via les probes de `tools/studio/probes`), **HUMAIN** (jugé par une personne : aucun élément de ce rapport ne l’est encore).

État des contrôles automatiques à la fin : **23 suites, 358 cas, tous PASS** ; trois places (normal, Debug, QA) reconstruites à chaque changement de source ; isolation des builds 9/9, docs et architecture PASS.

## 1. IMPLÉMENTÉ ET JOUABLE

| Élément | Preuve |
|---|---|
| Modèle de combo à coups confirmés (un coup dans le vide ne fait pas avancer la chaîne, le premier coup qui touche ouvre) | TECHNIQUE : ComboModel.spec (24). NATIVE_STUDIO : coup dans le vide puis pression = Light1 (`staged_moment`) |
| Routes directionnelles CORE4 avec intention indulgente | NATIVE_STUDIO avec **vrais clavier et souris** (`user_keyboard_input` / `user_mouse_input` → module Input → remote `Action`) : W tenu + trois clics = Light1 > Light2 > Launcher **4/4** ; trois clics = Light1 > Light2 > Light3 2/2 ; D + deux clics = Light1 > AngleStep ; les cinq autres combattants donnent aussi leur propre route montante avec W + trois clics réels (Itachi et Neji Launcher, Sasuke LionKick, Gaara SandPillar, Lee LeafRising). Deux défauts trouvés ainsi et corrigés (`3865d87`) : marcher dans l’adversaire faisait glisser autour de lui (« vers » devenait « côté ») ; une pression un peu tardive jouait Light3 au lieu de la route |
| Double tap rapide pris en compte | NATIVE_STUDIO par le vrai remote : deux pressions à 0,1 s = Light1 seul avant, Light1 > Light2 après (`ac31aa2`, anti-triche 0,16 → 0,08 s) |
| Réengagement unique (poursuite dans une fenêtre, dash chakra hors fenêtre) | NATIVE_STUDIO : touche E réelle à 18 studs → Rush > Recovery > Neutral (`projrec.luau`) ; `reengage.luau` : dash depuis 22 studs arrivé à 3,0 studs pour Minato 0,25 s, Itachi 0,32 s, Neji 0,27 s, Sasuke 0,27 s ; poursuite après lanceur 2,6–3,6 studs. Défaut corrigé : le corps glissait 13–25 studs au-delà de la cible (`6b98e28`, Regression.spec) |
| Six combattants sélectionnables (Minato, Itachi, Neji, Sasuke, Gaara, Rock Lee) | NATIVE_STUDIO : menu vu en Studio ; endurance IA contre IA de 8 affrontements (dont Gaara et Lee) sans erreur ni avertissement de jeu (`ai_soak.luau`) |
| Image du genjutsu d’Itachi (Mirage) qui trompe | NATIVE_STUDIO : vue côté victime, Itachi plein devant, vrai corps translucide derrière, indice « GENJUTSU • TRUST THE BODY ». TECHNIQUE : Identity.spec (26) |
| Wind Cut refait (tranche horizontale au kunai, sceau de vent) | NATIVE_STUDIO : geste horizontal et croissant de vent à la sortie de la main (`fx_freeze`). TECHNIQUE : Identity.spec, Animation.spec |
| Sable de Gaara (projectiles, bouclier, flicker, cercueil, mur du Désert, fouets, pilier, charges du bouclier) | NATIVE_STUDIO : chaque effet vu sur image figée (`fx_freeze`) ; avant, ses projectiles s’affichaient en kunai et aucun contact de sable n’était dessiné (`4dbccbe`, `15008c9`). TECHNIQUE : Gaara.spec (11, dont un test client) |
| Stade de l’examen Chūnin agrandi, sans accessoires | NATIVE_STUDIO (session précédente) : rayon 145, murs 76, corniche des participants praticable |

## 2. IMPLÉMENTÉ MAIS À POLIR (ressenti)

| Élément | Preuve et limite |
|---|---|
| Chakra systémique sur l’action d’outil (Z + R / R1 + R2), maîtrise par combattant, collisions par règles | TECHNIQUE : Chakra.spec (17). NATIVE_STUDIO : kunai de vent de Minato vu en vol ; accord Z + R joué avec de vraies touches → kunai infusé au vent puis planté comme point, R seul → kunai normal ; shuriken de feu d’Itachi qui enflamme (brûlure corrigée, voir plus bas). Non observés en natif : brûlures, fil tendu, points plantés, collisions ; manette réelle jamais essayée |
| Identité CORE4 (Read visible, points de tenketsu, éveils qui changent les règles, Curse Mark) et poses associées | TECHNIQUE : Identity.spec, Animation.spec (poses de Read, Mirage, contres, tenketsu, Curse Mark, freinage de dash). Natif : seulement l’image Mirage et le Wind Cut ; le reste n’a pas été regardé en mouvement |
| Rock Lee (stress test DEC-015) | TECHNIQUE : Lee.spec (25). NATIVE_STUDIO : costume (jambières orange après correction `d866b1e`), Lotus primaire (Light1 > Light2 > Leaf Rising > Air1 > Lotus) vu en Studio, endurance IA sans erreur. Limites : la plongée du Lotus traverse le corps adverse ; vitesse de la Cinquième Porte non mesurée ; équilibre (perd contre Minato, Sasuke, Gaara en duels IA) |
| Gaara (stress test) | Visuels de sable vus figés, pas en mouvement par un humain ; Gaara bat nettement Minato en duel IA (le bouclier absorbe ses coups légers) |
| Poses et mécanique corporelle | Mesures natives de la session précédente (pieds, contacts, sauts de mains) ; poses d’identité nouvelles seulement en headless |
| Cadre de production de personnages | Familles de mouvement (client), registre de couches d’identité dans Effects (`FX.layers`, `FX.poses`, helpers passés au module du combattant), `SandFX` et `LeeFX`, `Harness.stubScene()` pour les tests client. Deux combattants l’ont traversé ; chemin d’intégration documenté pas à pas dans [PRODUCTION_FRAMEWORK](../../../characters/PRODUCTION_FRAMEWORK.md) |

## 3. PARTIEL / FONDATION

| Élément | État |
|---|---|
| En ligne 1v1 | Serveur et protocole testés (Online.spec 17) ; jamais joué à deux clients ni sous latence réelle |
| Progression (arbres, budgets, paliers d’IA) | Données et validation (Progression 49, Profiles 11) ; pas d’UI ni de persistance DataStore branchées |
| Vague du roster (Naruto, Kakashi, Temari, Shikamaru, Haku, Kisame) | Fiches et plan seulement ; aucun kit jouable |
| Utilisation de l’espace par l’IA dans le grand stade | L’IA réengage, sonde et feinte, mais n’utilise presque jamais murs ni corniche (les combats restent au centre d’un stade de rayon 145) |
| Outils de dev Studio (F6, profileur, auto-test, labo chakra) | Portés et auto-test 9/9 en natif (session précédente) ; le labo chakra reste désactivé faute des modules de labo Codex (`ChakraInteractions`, `ChakraConfig`) |

## 4. NON IMPLÉMENTÉ

- Acceptation humaine de quoi que ce soit (ressenti, lisibilité, équilibre) et tests sur manette matérielle.
- Fumée/étiquettes explosives dédiées ; poing ivre, retrait des poids et les autres ajouts Lee listés dans son rapport.
- Publication publique de la place.

## Défauts trouvés et corrigés pendant cette passe (chacun avec un test qui échoue sur l’ancien code)

Double tap mangé par l’anti-triche ; dash qui glissait au-delà de la cible ; attaques aériennes martelées qui faisaient planer au ras du sol ; marcher dans l’adversaire qui le contournait ; route perdue pour une pression un peu tardive ; projectiles de sable dessinés en kunai ; petits cubes noirs laissés à chaque son ; Curse Mark qui perdait son lanceur et Wind Cut qui ne comptait plus ses coupes (conflits de fusion) ; étape « interrompre » du tutoriel illisible contre Lee ; jambières de Lee rendues comme du bois ; brûlure qui ré-étourdissait la victime toutes les 0,48 s et gonflait le compteur de combo (« 8 HITS, next x0.35 » pour un shuriken de feu, `796eb6d`).
