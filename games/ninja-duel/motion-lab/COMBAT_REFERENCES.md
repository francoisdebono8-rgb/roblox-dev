> Référence technique/recherche, non normative. État, priorités et règles : [sources actives](../docs/active/EXECUTION_RULES.md). Les commandes, exemples et anciens constats ci-dessous se vérifient sur le HEAD courant.

# Références consultées — bibliothèque commune 0.5

Recherche externe effectuée sur les textes originaux et des ressources de coaches.
Les angles, durées et trajectoires R15 sont des choix d'animation adaptés à notre rig,
pas des mesures humaines issues des articles. Aucun motion capture ni vidéo analysée
image par image. Aucun résultat scientifique ne vaut validation visuelle dans Studio.

| Source réelle | Décision dans les clips |
|---|---|
| [England Boxing, Level 1 handbook](https://www.englandboxing.org/wp-content/uploads/2022/03/EB_Boxing-Coaching-Handbook-Part-1_v8-002.pdf), sections jab/cross/hook/uppercut, pages imprimées 73–78 | Jab avant sans grand armé ; cross arrière avec pivot et brace ; hook compact avec retour garde ; uppercut porté par les jambes. |
| [England Boxing, Level 2 handbook](https://www.englandboxing.org/wp-content/uploads/2022/03/Level-2-Coaching-Handbook-compressed.pdf) | Garde exploitable et déplacement coordonné, sans isoler le membre frappeur. |
| [Kacprzak et al., Applied Sciences 2025, DOI 10.3390/app15074008](https://www.mdpi.com/2076-3417/15/7/4008) | Chaîne corporelle et synchronisation. L'étude mesure force/masse effective ; elle ne fournit pas nos keyframes. |
| [Piorkowski, Lees, Barton 2011, manuscrit auteur](https://clok.uclan.ac.uk/id/eprint/3757/1/piorkowski-et-al-2011-punch-kinematics.pdf), DOI 10.1080/14763141.2010.547590 | Distinguer trajectoires et coordination de frappes isolées/combinées. Les transferts proposés restent notre adaptation, pas une reconstruction de leurs sujets. |
| [Sylvie von Duuglas-Ittu : Golden Kick](https://8limbsus.com/muay-thai-thailand/golden-kick-how-to-improve-your-thai-kick) | Roundhouse : début compact, hanche/pied d'appui, arc continu du tibia et compensation. Évite la grosse chambre du side kick. Plusieurs écoles existent. |
| [Sylvie : vertical knee avec Chamuakpet](https://8limbsus.com/muay-thai-thailand/learning-the-details-of-the-vertical-knee-from-the-legend-chamuakpet-hapalang) | Appui avant élévation du genou ; rising knee vertical distinct du forward knee à projection de hanche. |
| [Evolve University : teep](https://evolve-university.com/blog/5-effective-ways-to-use-the-teep-in-muay-thai-and-how-to-land-them/) | Front kick de cette collection = teep/thrust : chambre, poussée, retour ; variante StopTeep pour interrompre une entrée. |
| [Paul Zaichik / ElasticSteel : side kick](https://elasticsteel.com/blogs/kicking-corrections-and-tips/what-does-your-side-kick-look-like) | Pivot du support, talon dirigé vers cible, chambre puis extension et rechamber. |
| [Kukkiwon : Technical Terminology, Dwi-chagi](https://research.kukkiwon.or.kr/homepage/boardMedia/11621) | Back kick : demi-tour, genou plié puis poussée arrière du talon ; distingué d'un kick circulaire. |
| [Evolve University : elbows](https://evolve-university.com/blog/beginners-guide-to-elbows-in-mma/) | Coude horizontal court, tronc engagé, main opposée en protection. |
| [Evolve University : catch and sweep](https://evolve-university.com/blog/heres-how-to-utilize-the-catch-and-sweep-in-muay-thai/) | Sweep = frame/catch + posture adverse rompue + reap bas + replant. Le preview solo ne simule pas le partenaire. |

Le lien utilisateur [World Muaythai Magazine](https://worldmuaythaimagazine.com/techniques/roundhouse-kick/)
a été consulté en complément ; les notes de coaching primaire ci-dessus guident le roundhouse.
Le lien [AJOL 165914](https://www.ajol.info/index.php/jfas/article/view/165914) répondait 403.
Aucun coefficient de dominance ni conclusion tirée de cet article inaccessible n'a été inventé.
Une stance équivalente peut produire des versions symétriques ; les différences viennent
explicitement de la position avant/arrière et de la fonction, sans faux biais numérique L/R.

## Matérialisation et limite physique

`ReferenceMotionLibrary` matérialise chaque côté/variante en source anatomique indépendante
et vraie `variantDefinition` six phases. Edit/Save copie les corrections dans le profil ;
la source distribuée reste immuable. HipDrive/Rechamber et les contacts suivants sont
également des ancres de retiming. Les combos conservent l'espace des appuis et relient
carry → charge suivante, sans Ready intermédiaire. Les bras/pieds ne sont pas interpolés
à travers un changement IK/FK incompatible.

Base → variante tactique change charge, chambre, frame, trajectoire ou replant selon le coup.
Ninja amplifie modestement membre/torse/carry en conservant la base d'appui. Launcher,
aerial et pursuit sont des briques de présentation de jeu, explicitement identifiées ;
pas de physique de victime, hitbox, dégâts, IA ou networking ajoutés.

Validation technique : phases, métadonnées, appuis atteignables sans clamp, pivots,
rechamber, direction des kicks, continuité R15, variantes distinctes, contacts multiples,
persistance/import/export et UI du binaire avec événements simulés. Validation native
et jugement biomécanique/visuel final : à faire par François dans Studio.
