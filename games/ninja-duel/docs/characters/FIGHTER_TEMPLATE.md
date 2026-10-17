# Character V1 — contrat de chorégraphie

Référence de design liée à [DEC-026](../active/DECISIONS.md#dec-026--roster-cible-et-character-v1-combat-bibles), pas huitième source opérationnelle. [Vingt bibles](ROSTER_20.md). Ancien [gabarit complet des futurs systèmes](../archive/characters/2026-10-18-superseded-profiles/FIGHTER_TEMPLATE.md) conservé ; il n’est pas la définition de la V1 actuelle.

## Définition et portée

V1 = identité dans corps/mouvement/animations/contacts/combos/défense, armes fondamentales et signatures nécessaires. HUD masqué, reconnaissance en quelques secondes. Exclure arbre complet, maîtrise acquise, chakra global final, armes globales finales, sound/VFX/balance compétitifs finaux. Des pouvoirs locaux dans les gestes, comme os/mirage/clone/sable, font déjà partie de V1 ; ne pas les repousser au chantier chakra final.

Le roster cible diffère du build :17 combattants conservés, Madara/Hashirama/Hiruzen enfants à concevoir, Hinata/Temari/Kabuto hors cible. Ne pas modifier Roster/IDs/menu pendant une mission documentaire.

## Les douze rubriques obligatoires

1. Combat identity et décision propre.
2. Silhouette : idle/bras/jambes/centre, avant/arrière/strafe/sprint/dash/saut/chute/landing/garde/dodge, réactions légère/lourde et get-up.
3. Chaque Light : membre/arme, trajet, appui/translation, distance, rythme/phases et intention.
4. Forward/Side/Away/Air, launcher/continuation/finisher et mur si pertinent.
5. Heavy distinct, anticipation et récupération punissables.
6. Défense et retour au neutral.
7. Arme physique dans la chaîne, prises et rangement cohérents.
8. Pouvoir dans les gestes, source de hit et fin lors d’interruption.
9. Seulement signatures fondamentales : activation/corps/comportement/usage/contre/conversion.
10. État spécial changeant une règle, entrée/sortie et risque.
11. Cinq à dix règles d’animation propres.
12. Points d’extension futurs sans les implémenter.

Appendices A–E : réemploi, unités uniques, priorité, actuel→cible et lot proposé. Une donnée cible n’est pas un fait du runtime ni une validation canon/Studio.

## Grammaire, manette et anti-infini

Light = LMB/□, Heavy = RMB/△ ; directions relatives à l’adversaire. Avant hit confirmé, toute direction+Light reste L1. Side après1hit ; Forward/Away après2 ; branche air après contact air. Aucun nouveau bouton nécessaire pour une lame, un os, un clone ou un mirage. R1 + face utilise les signatures ; les sous-gestes de prise suivent le clip/état, pas un mini-clavier supplémentaire.

V1 cible : une branche sol, une poursuite, deux contacts air puis finisher/neutral ; signature de conversion remplace la fin. Scaling/compteurs/escape communs, pas reset caché par proxy/zone/objet. Coup autonome/poison ne confirme pas un nouveau combo du maître. Bloc, whiff, invulnérabilité, corps disparu et LOS restent respectés.

## Contrat de clip/contact

Repère gauche/droite du personnage. Pied pivot planté avant extension ; anticipation lisible ; moment de contact aligné sur le membre/objet réel ; réaction depuis source réelle ; recovery qui restitue garde/neutral. Les phases A/C/R des fiches sont des points de départ d’auteur en secondes, à confronter aux règles serveur et au rig ; pas promesse de frames/balance finale.

Corps physiques secondaires ont propriétaire/source/lifecycle, objets/armes ont attaches et configuration ; jamais dégâts depuis VFX seul. Le réseau envoie les états nécessaires, le client présente ; pas d’autorité client sur hit ou branche. Le serveur ne doit pas attribuer deux dégâts pour deux lames dessinées au même accent.

**État spécial de départ partagé :** [Config.Awaken](../../src/Shared/Config.luau) : seuil35%HP, durée12s, une activation par match et condition libre ; [Combat.awaken](../../src/Server/Combat.luau) gère entrée/recharge/recovery. Garder ce socle pour les trois nouveaux ; la règle particulière de la bible remplace un simple bonus, elle ne crée pas une nouvelle mécanique de déblocage. Coût/durée finaux ne sont pas une tâche de cette mission documentaire.

## Budget et réemploi

Cinq unités prioritaires par fighter : trois contacts Light, Heavy, un geste signature/transitoire. Environ100 unités de contact pour20, dont beaucoup déjà présentes, pas100nouveaux assets obligatoires. Les bases de locomotion/réactions/air partagent des courbes entre familles ; corps et accessoires sont retargetés, avec pauses/appuis différents. Budget de planification inférieur à200unités d’auteur y compris bases/réactions et exceptions ; mesurer l’inventaire réel avant création, pas imposer300animations uniques.

Aucun compromis sur les silhouettes irréductibles : multi-lames Bee, couperet Zabuza, os vivants Kimimaro, deux-corps Sasori/Naruto, sable Gaara et trajectoires Shisui/Haku. Réemployer une fonction de clip ne justifie pas d’importer le même kick terminal partout.

## Gates du lot

Tests pertinents → build exact → séquence continue native → comparaison avant/après HUD masqué → correction → commit et état/proof. Comparer au voisin de famille, au même adversaire et sur garde/whiff/KO/reset ; manette séparée si matériel disponible. Une régression partagée bloque le lot. Ni compilation, ni spawn, ni belle image ne valident le feel.
