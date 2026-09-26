# Prochains produits commerciaux Roblox Studio

Recherche au 26 septembre 2026. PresetForge 2.0 est considéré comme déjà publié à 4,99 USD, conformément au contexte fourni. Aucun produit, prototype ou issue de développement n'a été créé pendant cette recherche.

**Décision : 17 candidats étudiés, 16 REJETÉE, 1 À VÉRIFIER, aucune PROMETTEUSE à ce stade.** Une batterie de tests de navigation NPC rejouables mérite une vérification commerciale ciblée. Cet audit ne justifie pas encore son développement, ni la sélection de quatre produits supplémentaires pour remplir une gamme.

La principale découverte est concurrentielle : plusieurs propositions séduisantes existent déjà gratuitement, et de nombreux petits audits payants couvrent précisément les variantes envisagées. Leur présence ne prouve pas leurs ventes. Le bon objectif reste de trouver un travail répétitif pour lequel un développeur préférerait acheter un résultat fiable plutôt qu'utiliser ces outils ou un script interne.

## Méthode et portée

- Inspection statique de trois copies locales de projets publics : fichiers de configuration, code pertinent et hiérarchies XML réellement présentes. Pas d'exécution des jeux ni de mesure de leur performance.
- Dix recherches Creator Store par famille, puis recherches élargies et adversariales pour les pistes encore plausibles. Les formulations exactes figurent en annexe. Consultation des fiches détaillées des concurrents les plus dangereux.
- Recherche dans le DevForum public, GitHub et la documentation officielle actuelle. Les témoignages attestent un problème, pas une intention d'achat.
- Les prix, dates et votes proviennent des données publiques du Creator Store : [recherche des plugins](https://create.roblox.com/store/category/plugins), endpoint public `https://apis.roblox.com/toolbox-service/v2/assets:search` avec `searchCategoryType=Plugin`, et fiches `https://apis.roblox.com/toolbox-service/v2/assets/{id}`. Les liens ci-dessous ouvrent les pages publiques correspondantes.
- Les premières recherches ont examiné jusqu'à dix résultats par formulation; les recherches larges et finales, jusqu'à trente. Certaines formulations exactes ne renvoient rien. Les résultats ne constituent pas un inventaire exhaustif, et les pages supplémentaires des grandes catégories n'ont pas toutes été parcourues.
- Aucun concurrent n'a été acheté, installé ou testé fonctionnellement. Une fonctionnalité de fiche est donc une **promesse du vendeur**, pas une capacité certifiée par cet audit. La qualité apparente est estimée par la précision du périmètre, les limites documentées, l'ancienneté et les signaux publics.

**Lecture des évaluations :** les compteurs de votes publics sont agrégés; `1 000 / 96 %` désigne le compteur renvoyé et son pourcentage, pas un nombre exact d'utilisateurs ou de ventes. Quand le compteur vaut zéro, il peut malgré tout être accompagné d'un pourcentage : ces valeurs sont notées `N/D` et ne servent pas à classer la qualité. Les avis textuels ne sont pas les votes. Pathfinder affiche un avis et une évaluation insuffisante; DeviceLab affiche zéro avis, vérifiés dans le navigateur. Les autres avis textuels n'ont pas été examinés, sauf indication explicite.

**Trois niveaux de certitude :** « observation » signifie directement lu ou compté; « inférence » désigne une conséquence raisonnable; « hypothèse » désigne notamment fréquence réelle, temps économisé, volonté de payer et potentiel de vente. Aucun gain de temps n'a été chronométré et aucune estimation de ventes n'est présentée.

## Projets inspectés

Les trois dépôts déclarent une licence MIT : [Roblox/resources](https://github.com/Roblox/resources/blob/ee51421b99234a436aa22d417a31316541b1575d/LICENSE.md), [Nexus-Battles](https://github.com/TheNexusAvenger/Nexus-Battles/blob/fd6505c3cb12c94272532e1a0b0a30bf8499fc52/LICENSE) et [hacker-tycoon](https://github.com/jblaz6335/hacker-tycoon/blob/a71871c2f29441891e975da8ee9559c6a9130957/LICENSE). Seuls le code et la structure ont été inspectés. Les assets distants référencés n'ont pas été récupérés ou redistribués; la licence du code ne permet pas de présumer les droits de chaque audio ou image Roblox.

| Projet et révision | Observation concrète | Inférence utile et contre-exemple |
| --- | --- | --- |
| Roblox/resources, `ee51421b` | Les [presets d'éclairage](https://github.com/Roblox/resources/tree/ee51421b99234a436aa22d417a31316541b1575d/packages/lighting-presets/src/shared/Demo/Presets) déclinent Dawn, Dusk, Midday et Night avec plusieurs effets. Le projet Plant contient des prefabs UI et des effets; [play-smoke-puff](https://github.com/Roblox/resources/tree/ee51421b99234a436aa22d417a31316541b1575d/packages/play-smoke-puff) encapsule un effet réutilisable. | Il faut maintenir des ensembles cohérents. Mais packages et configurations remplissent déjà une partie de ce rôle : ce n'est pas la preuve que le développeur effectue chaque réglage manuellement dans Studio. |
| Nexus-Battles, `fd6505c3` | Les 16 fichiers `.rbxmx` de `src` contiennent notamment 15 119 instances de classe exacte `Part`, 5 271 `Weld`, 44 `SpotLight`, 41 `PointLight` et 21 `Sound`. Présence de [maps](https://github.com/TheNexusAvenger/Nexus-Battles/tree/fd6505c3cb12c94272532e1a0b0a30bf8499fc52/src/ServerStorage/Maps), modèles d'armes et accessoires. | Le volume rend crédibles recherche, inspection et modifications en lot. Ces comptes ne prouvent aucun défaut, doublon inutile ou goulet de performance. Le dépôt observé est ancien, pas un échantillon représentatif des productions actuelles. |
| hacker-tycoon, `a71871c2` | Le code contient des constructions répétées d'UI, de lumières, de sons et d'effets. [AmbientConfig](https://github.com/jblaz6335/hacker-tycoon/blob/a71871c2f29441891e975da8ee9559c6a9130957/src/ReplicatedStorage/HackerTycoon/AmbientConfig.lua) centralise palette, paramètres et identifiants audio. | Éditer des instances temporaires dans Studio peut être inutile : le générateur les recrée depuis ses données. Un plugin doit respecter la source de vérité; ici un changement de configuration est souvent meilleur. |

Contre-exemple particulièrement utile : Nexus-Battles utilise [Base3DIcon](https://github.com/TheNexusAvenger/Nexus-Battles/blob/fd6505c3cb12c94272532e1a0b0a30bf8499fc52/src/ReplicatedStorage/UI/Icon/Base3DIcon.lua) et des modèles d'armes pour ses icônes 3D. Générer puis uploader une image par objet ajouterait du travail à ce workflow.

Une recherche textuelle de `PathfindingService`, `CreatePath`, `ComputeAsync` et `PathfindingModifier` n'a trouvé aucun usage dans ces trois copies. Cela ne prouve pas leur absence de tout asset binaire, mais **ces projets n'apportent aucune preuve directe du besoin de tests de navigation**. La piste conservée repose sur d'autres sources, explicitement identifiées plus loin.

## A. Candidats étudiés

Le concurrent indiqué est le plus dangereux pour la proposition envisagée, pas nécessairement le meilleur produit de toute sa catégorie.

| # | Problème répétitif | Concurrent principal | Verdict | Raison déterminante |
| --- | --- | --- | --- | --- |
| 1 | Retrouver les assets inaccessibles et tous leurs usages avant publication | [Ann Deep Assets Scanner](https://create.roblox.com/store/asset/81765987115820) | REJETÉE | Audit profond et recherche d'usages déjà proposés gratuitement; les permissions ne se déduisent pas de la propriété d'un asset. |
| 2 | Vérifier une UI sur de nombreuses tailles d'écran | [DeviceLab](https://create.roblox.com/store/asset/85509999390884) | REJETÉE | Comparaison multi-écrans déjà vendue, alternative gratuite, simulateur natif renforcé. |
| 3 | Trouver les effets VFX trop coûteux et les ajuster en lot | [VFX Optimizer](https://create.roblox.com/store/asset/115484023247306) | REJETÉE | L'inspection/réglage simple existe; une vraie mesure GPU multi-appareils dépasse un petit audit statique. |
| 4 | Refaire les mêmes vérifications de navigation après une modification de map | [Pathfinder](https://create.roblox.com/store/asset/9019193064) | À VÉRIFIER | Différence possible : suite persistante de trajets × profils, comparaison des résultats entre versions. Demande payante non établie. |
| 5 | Contrôler les erreurs courantes avant chaque publication | [Preflight](https://create.roblox.com/store/asset/75170600713119) | REJETÉE | Proposition générale déjà couverte; faux positifs et promesse excessive de sécurité. |
| 6 | Nettoyer les assets inutilisés et doublons d'une grosse place | [Vault](https://create.roblox.com/store/asset/139362231922321) | REJETÉE | Nombreux outils; impossible de prouver tous les usages dynamiques par un simple scan. |
| 7 | Vérifier et remplacer des sons dispersés | [Halide](https://create.roblox.com/store/asset/140541077204557) | REJETÉE | Audits et remplacement en lot existent; outils audio natifs annoncés. |
| 8 | Comparer et corriger tags/attributes sur beaucoup d'objets | [AttributeSheet](https://create.roblox.com/store/asset/77824934141606) | REJETÉE | Table et opérations en lot gratuites; tags natifs et recouvrement avec PresetForge. |
| 9 | Vérifier textes manquants et placeholders de traduction | [Herald](https://create.roblox.com/store/asset/86856656769974) | REJETÉE | Le contrôle spécifique envisagé est déjà vendu, extraction native et alternatives gratuites. |
| 10 | Importer/configurer/uploader de nombreuses animations | [Bulk Animation Upload](https://create.roblox.com/store/asset/134443954464349) | REJETÉE | Le workflow principal est déjà proposé directement; aucune différence forte trouvée. |
| 11 | Voir les changements de propriétés entre deux états de place | [Drydock](https://create.roblox.com/store/asset/116523806288352) | REJETÉE | Snapshot, diff, sélection et restauration déjà vendus; Rojo/Git et évolution native. |
| 12 | Adapter et vérifier une place pour le streaming | [Streaming Debugger](https://create.roblox.com/store/asset/5313525182) | REJETÉE | Débogage gratuit et conversion assistée officielle; garantie statique peu crédible. |
| 13 | Renommer un objet/module sans casser ses références | [Reference Finder](https://create.roblox.com/store/asset/121233404979804) | REJETÉE | Alternative directe; résoudre réellement les références dynamiques est nettement plus difficile qu'un remplacement de texte. |
| 14 | Repérer z-fighting et intersections accidentelles d'une map | [Advanced Z-fight](https://create.roblox.com/store/asset/16316028364) | REJETÉE | Outils gratuits établis; nombreuses intersections sont intentionnelles. |
| 15 | Remplacer une palette ou harmoniser les styles UI | [Expanded Color](https://create.roblox.com/store/asset/856308258) | REJETÉE | Outils gratuits, styles/tokens natifs et données centralisées; forte proximité avec PresetForge. |
| 16 | Produire des icônes de nombreux objets d'inventaire | [Thumbnail Creator](https://create.roblox.com/store/asset/8002148618) | REJETÉE | Concurrents gratuits et workflows ViewportFrame; bénéfice commercial supplémentaire non démontré. |
| 17 | Inspecter les assemblages, welds et pièces non ancrées | [Anchor & Weld Checker](https://create.roblox.com/store/asset/109116585413319) | REJETÉE | Vérifications simples gratuites et visualisation native; problème structurel précis encore mal établi. |

## B. Idées rejetées

Les dates ci-dessous sont celles de création/mise à jour des assets, pas une preuve d'entretien réel. `N/D` désigne une évaluation publique insuffisamment exploitable. Les jugements de marché sont des inférences à partir de l'offre observée.

### 1. Assets et permissions

[Ann Deep Assets Scanner v3.3](https://create.roblox.com/store/asset/81765987115820) : gratuit; créé le 2026-01-19, modifié le 2026-02-13; votes N/D. La fiche décrit scan profond, erreurs d'assetId, doublons, usages, sélection, filtre, rapport et textures PBR. Apparence : périmètre concret, mais aucune fiabilité vérifiée. [Easy Asset Scanner](https://create.roblox.com/store/asset/134146046534820), gratuit, créé/modifié le 2026-09-05, votes N/D, vise les assets non possédés. Aucune offre payante directement comparable suffisamment convaincante n'a été identifiée dans les résultats examinés; les scanners de virus répondent à un autre problème.

Le volume de références dans les projets rend l'inventaire utile; aucun asset inaccessible n'y a été testé. Roblox fournit déjà erreurs Output et procédures d'autorisation. **Propriétaire différent ne signifie pas permission manquante**, et un échec de chargement n'établit pas à lui seul sa cause. Une promesse « répare toutes les permissions » serait trompeuse. [Documentation des permissions](https://create.roblox.com/docs/projects/assets/privacy).

Rejet : nous n'avons pas de réponse forte à « pourquoi payer plutôt qu'Ann ? ». Des catégories supplémentaires ou un écran plus propre ne suffisent pas.

### 2. QA UI multi-écrans

[DeviceLab](https://create.roblox.com/store/asset/85509999390884) : 9,99 USD; 2026-07-29 / 2026-08-20; évaluation insuffisante et **zéro avis visible**. Il annonce des vues simultanées, contrôles de clipping, zones sûres, texte, cibles tactiles et lien vers l'instance source. [Responsive UI Checker](https://create.roblox.com/store/asset/73615161276348) : gratuit; 2026-09-18 / même date; votes N/D; scan et aperçu mobile/tablette/desktop. [Caliper](https://create.roblox.com/store/asset/129013115062665) : 6,99 USD; 2026-08-09 / 2026-08-15; votes N/D; se positionne déjà sur les tests responsive de non-régression.

Les UI des projets justifient le problème, mais pas une quatrième solution générique. Apparence : offres très proches et récentes, demande commerciale encore inconnue. Le [Device Simulator](https://create.roblox.com/docs/studio/device-simulator) et les [APIs de test Studio](https://create.roblox.com/docs/studio/testing-modes) réduisent aussi les manipulations. Rejet pour absence d'avantage démontré, pas parce que tous les concurrents seraient établis ou excellents.

### 3. Budget et optimisation VFX

[VFX Optimizer](https://create.roblox.com/store/asset/115484023247306) : gratuit; 2025-05-09 / même date; votes N/D; informations d'un modèle d'effets, modification des rates, copie de propriétés, Undo/Redo annoncés. [Ros Particle Editor](https://create.roblox.com/store/asset/8813198599) : 4,99 USD; 2022-02-13 / 2026-06-02; compteur 1 000 / 96 %; édition et visualisation spécialisées. [Particle Forge](https://create.roblox.com/store/asset/95580704382525) : 4,99 USD; 2026-06-10 / même date; votes N/D; preview, émissions, transformations, styles et bibliothèque d'effets. Ros a le signal public le plus solide; les autres capacités restent des annonces.

Le [signalement sur le coût d'émetteurs désactivés](https://devforum.roblox.com/t/4673442) montre un problème réel, avec correctif moteur annoncé dans le fil. Il ne démontre pas un besoin pérenne pour un plugin. `Rate × Lifetime` ne mesure ni overdraw ni coût GPU. Le [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler) fournit déjà des mesures et une analyse assistée. Rejet du compteur statique payant comme de la promesse d'optimisation automatique universelle.

### 5. Préflight général avant publication

[Preflight](https://create.roblox.com/store/asset/75170600713119) : 6,99 USD; 2026-08-09 / 2026-08-15; votes N/D. Quarante-trois contrôles annoncés, instances concernées, exceptions persistantes, correctifs de propriétés regroupés et rapport. Sa fiche distingue explicitement risques statiques et intention runtime : bonne précision apparente, efficacité non testée. [GameHealthLite](https://create.roblox.com/store/asset/119944378343100) : gratuit; 2026-01-12 / même date; votes N/D; contrôle plus limité, notamment ancrage.

Studio offre Script Analysis, Output et tests client/serveur; aucun ne certifie à lui seul la publication. Une liste générale de heuristiques risque de signaler comme erreurs des choix volontaires. Rejet : offre directe existante et coût de support élevé pour une assurance implicite impossible à tenir. Sources : [éditeur de scripts](https://create.roblox.com/docs/studio/script-editor), [tests Studio](https://create.roblox.com/docs/studio/testing-modes).

### 6. Nettoyage et assets inutilisés

[Vault: Unused Assets](https://create.roblox.com/store/asset/139362231922321) : 5,99 USD; 2026-09-09 / même date; votes N/D. Recherche d'identifiants inutilisés et doublons, suppression annulable annoncée. [Remove Duplicate Parts](https://create.roblox.com/store/asset/8221873153) : gratuit; 2021-12-11 / 2021-12-19; compteur 20 / 39 %. [Workspace Cleaner](https://create.roblox.com/store/asset/123169154929412) : gratuit; 2026-09-25 / même date; votes N/D; doublons et conteneurs vides.

Le nombre d'instances de Nexus donne une cible de scan, pas une preuve de déchets. Les accès par noms construits, clones et chargements conditionnels compliquent toute affirmation « inutilisé ». Apparence : offre abondante mais garanties fragiles; faible évaluation du vieux outil ne prouve pas que les autres sont bons. L'Explorer filtre déjà propriétés/classes et sélectionne les résultats. Rejet : concurrence gratuite et suppression erronée potentiellement très coûteuse. [Explorer natif](https://create.roblox.com/docs/studio/explorer).

### 7. Audit et remplacement audio

[Halide: Sound Audit](https://create.roblox.com/store/asset/140541077204557) : 7,99 USD; 2026-09-09 / même date; votes N/D; contrôle annoncé de chargement, volumes et portée. [Bulk Audio Manager](https://create.roblox.com/store/asset/9173750549) : gratuit; 2022-03-23 / même date; compteur 10 / 57 %; remplacement d'identifiants. [Audio Problem Scanner](https://create.roblox.com/store/asset/11468364320) : gratuit; 2022-11-04 / même date; votes N/D; recherche de problèmes d'IDs/permissions.

Les sons et réglages de portée sont bien présents dans les trois corpus; hacker-tycoon les centralise déjà dans AmbientConfig. La fiche Halide ne démontre pas qu'un volume soit objectivement mauvais sans connaître le mix et la scène. Les propriétés natives traitent les corrections uniformes; les [outils de débogage audio annoncés pour fin 2026](https://devforum.roblox.com/t/4880208) augmentent le risque de remplacement. Il s'agit d'une annonce, pas d'une fonctionnalité vérifiée comme livrée. Rejet de cette proposition générique.

### 8. Table de tags et attributes

[AttributeSheet](https://create.roblox.com/store/asset/77824934141606) : gratuit; 2026-09-13 / même date; votes N/D. Tableau, filtre, remplissage, ajouts/suppressions et revue avant Apply; limites documentées de 500 lignes, 128 noms et 2 000 cellules en attente. Apparence : périmètre précis, peu de recul. [Tag Editor](https://create.roblox.com/store/asset/948084095) : gratuit; 2017-07-29 / 2022-08-24; compteur 700 / 96 %. [Tag Editor Pro](https://create.roblox.com/store/asset/126519599671542) : 4,99 USD; 2026-05-09 / 2026-07-16; votes N/D.

Les [Properties](https://create.roblox.com/docs/studio/properties) exposent tags/attributes et l'Explorer filtre les tags. Une table comparative peut dépasser le natif, mais elle existe gratuitement. Rejet d'un deuxième produit voisin de PresetForge sans bénéfice distinct assez fort.

### 9. Localisation et intégrité des traductions

[Herald](https://create.roblox.com/store/asset/86856656769974) : 5,99 USD; 2026-09-09 / même date; votes N/D; placeholders, langues manquantes, cellules vides. [CSV Preflight](https://create.roblox.com/store/asset/84047470224826) : 4,99 USD; 2026-08-29 / 2026-09-01; votes N/D; contrôle de tables. [LocaleScout](https://create.roblox.com/store/asset/115087176064574) : gratuit; 2026-09-01 / même date; votes N/D; extraction de textes UI et autres sources.

Roblox propose [capture des textes](https://create.roblox.com/docs/production/localization/automatic-translations), traduction et émulation de locale/pseudolocalisation. Le contrôle des placeholders est un bon complément technique, mais précisément celui déjà vendu par Herald. Apparence : offres jeunes, pas de preuve de traction; aucun témoignage d'achat trouvé. Rejet pour différenciation insuffisante, sans prétendre que le natif fait déjà tous les contrôles.

### 10. Traitement d'animations en lot

[Bulk Animation Upload](https://create.roblox.com/store/asset/134443954464349) : 9,99 USD; 2025-01-05 / 2025-09-20; votes N/D; import, configuration et upload groupés annoncés. [Animation Bulk Importer](https://create.roblox.com/store/asset/74853533830592) : gratuit; 2024-10-07 / 2025-01-24; votes N/D. [Blender Animations Importer](https://create.roblox.com/store/asset/716953901) : gratuit; 2017-03-30 / 2022-02-17; compteur 2 000 / 83 %; cible un pipeline spécialisé.

L'éditeur natif couvre le travail unitaire. La différence « le faire cinquante fois » est réelle en principe, mais le concurrent payant promet déjà exactement le lot. Nous n'avons pas observé dans les projets un besoin supplémentaire assez spécifique pour justifier une alternative. Apparence : écosystème ancien et plusieurs solutions; ne pas confondre l'historique de l'importeur Blender avec la qualité du produit payant. Rejet.

### 11. Diff de place, snapshots et Rojo

[Drydock](https://create.roblox.com/store/asset/116523806288352) : 9,99 USD; 2026-08-09 / 2026-08-14; votes N/D. Snapshot de services, différences de propriétés suivies, sélection de l'objet, restauration annulable et baseline transférable. Limites explicites : 30 000 instances, 300 lignes, pas de restauration du code ou d'instances supprimées. Apparence : proposition bien délimitée, pas testée. [Rojo](https://create.roblox.com/store/asset/13916111004) : gratuit; 2023-07-01 / 2026-07-02; compteur 500 / 94 %.

Les [sources Rojo](https://rojo.space/docs/v7/) et Git gèrent déjà les fichiers des projets inspectés; les [packages natifs](https://create.roblox.com/docs/projects/assets/packages) couvrent une partie de la réutilisation/version. Le diff de propriétés d'une place reste distinct, mais Drydock occupe cette proposition. Roblox annonce aussi overrides de packages et branchement/fusion de places : risque futur, pas capacité supposée disponible aujourd'hui. Rejet d'un diff générique supplémentaire.

### 12. Streaming et readiness

[Streaming Debugger](https://create.roblox.com/store/asset/5313525182) : gratuit; 2020-07-08 / 2021-05-04; compteur 10 / 53 %; simulation mémoire et visualisations. [Model Streaming Help](https://create.roblox.com/store/asset/15196354485) : gratuit; 2023-10-28 / 2024-05-08; votes N/D. Aucune offre payante équivalente suffisamment documentée n'a été identifiée dans les résultats consultés.

Roblox a publié une [préversion officielle de conversion au streaming assistée par IA](https://devforum.roblox.com/t/4697943), avec refactorisation et vérifications limitées; l'annonce demande encore des tests humains. Un scanner statique ne certifie pas les accès client sur tous les états de streaming. Apparence : vieux outils partiels, mais concurrence native active. Rejet : le besoin est sérieux, la solution simple proposée ne permet pas de promettre un résultat assez fiable.

### 13. Références et renommage

[Reference Finder](https://create.roblox.com/store/asset/121233404979804) : 6,99 USD; 2026-07-02 / même date; votes N/D. Recherche de références par nom, ouverture du script et renommage groupé, y compris documents non enregistrés, annoncés. [Cross Reference Finder](https://create.roblox.com/store/asset/83242077513686) : gratuit; 2025-08-29 / 2025-09-08; votes N/D.

La fiche payante décrit des frontières de mots : cela ne prouve pas une résolution sémantique correcte des instances. Les projets emploient des accès indirects et des chemins; une vraie solution doit distinguer chaînes, symboles et objets. Le Find All natif traite déjà la recherche textuelle de base. Apparence : promesse forte, preuve technique insuffisante. Rejet : copier cette promesse serait risqué; construire un refactoriseur réellement supérieur est un chantier important sans preuve commerciale suffisante.

### 14. Z-fighting et géométrie accidentelle

[Advanced Z-fight](https://create.roblox.com/store/asset/16316028364) : gratuit; 2024-02-10 / 2024-02-12; compteur 30 / 89 %. [Z-Fight Squasher](https://create.roblox.com/store/asset/7079690622) : gratuit; 2021-07-11 / 2024-12-15; compteur 100 / 74 %. [ZFight Squasher Pro](https://create.roblox.com/store/asset/125887876997424) : 4,99 USD; 2026-06-06 / même date; votes N/D.

Les grandes maps rendent la recherche répétitive plausible; aucun z-fighting n'a été démontré dans les fichiers inspectés. Les outils gratuits ont déjà un historique et des évaluations. Le natif permet inspection visuelle et correction des positions; il n'est pas présenté ici comme un détecteur exhaustif. Généraliser aux overlaps produit facilement des alertes sur des assemblages volontaires. Rejet du nettoyeur automatique et du clone du détecteur existant.

### 15. Palettes et styles

[Expanded Color](https://create.roblox.com/store/asset/856308258) : gratuit; 2017-06-08 / 2023-02-14; compteur 70 / 89 %. [Matswap](https://create.roblox.com/store/asset/5598675947) : gratuit; 2020-08-21 / 2024-05-01; compteur 10 / 92 %; remplacement de matériaux. [Color Palette](https://create.roblox.com/store/asset/124261799240958) : 9,99 USD; 2026-07-13 / même date; votes N/D.

Les couleurs répétées sont observées, mais AmbientConfig constitue précisément une solution sans plugin. Le [styling natif](https://create.roblox.com/docs/ui/styling) fournit règles, tokens et thèmes pour l'UI. Les outils gratuits sont anciens et la simple application de configurations recoupe PresetForge. Rejet d'un produit supplémentaire de recoloration ou thèmes génériques.

### 16. Icônes et rendus de modèles en lot

[Thumbnail Creator](https://create.roblox.com/store/asset/8002148618) : gratuit; 2021-11-14 / 2022-11-13; compteur 80 / 70 %. [Icon Generator](https://create.roblox.com/store/asset/93320318498143) : gratuit; 2025-07-02 / même date; votes N/D; icônes d'items/pets annoncées. [UGC Creator](https://create.roblox.com/store/asset/17174405857) : 5,99 USD; 2024-04-16 / 2026-09-23; compteur 30 / 86 %, mais périmètre UGC adjacent, pas équivalence démontrée à l'export d'un inventaire complet.

Nexus génère déjà son affichage 3D avec des modèles : pas d'upload d'image requis pour chaque arme. Les APIs de capture existantes ne suffisent pas à présumer un export disque silencieux de centaines de PNG. Apparence : plusieurs outils disponibles, qualité variable; aucun avantage payant concret établi pour notre cible. Rejet malgré une démo potentiellement séduisante.

### 17. Intégrité des assemblages physiques

[Anchor & Weld Checker](https://create.roblox.com/store/asset/109116585413319) : gratuit; 2025-01-28 / même date; votes N/D; surbrillance des pièces non ancrées, mal alignées ou sans weld annoncée. [Constraint Editor](https://create.roblox.com/store/asset/804263305) : gratuit; 2017-05-15 / 2018-08-22; compteur 200 / 90 %. Aucun audit payant strictement comparable suffisamment documenté trouvé dans cet échantillon.

Nexus contient réellement des milliers de joints. Mais « beaucoup de joints » n'est pas « beaucoup de joints cassés ». Un [signalement de welds désactivés après réouverture](https://devforum.roblox.com/t/4015422) décrit une gêne réelle, sans fournir ici de diagnostic général reproductible. Roblox visualise déjà [assemblages](https://create.roblox.com/docs/physics/assemblies) et [contraintes](https://create.roblox.com/docs/physics/mechanical-constraints). Des joints hors Workspace peuvent normalement être inactifs. Rejet : le cas payant au-delà du filtre gratuit reste trop vague, et l'autocorrection pourrait casser des mécanismes voulus.

## C. Survivant

### Tests de navigation NPC rejouables en lot : À VÉRIFIER

**Proposition précise :** conserver une suite de trajets importants d'une map, la relancer avec plusieurs profils d'agents, puis montrer lesquels ne produisent plus le résultat attendu après une modification. Un outil de non-régression pour level designers travaillant avec des NPC, pas un nouveau moteur d'IA.

#### Problème, cible et preuves

Cible potentielle : petites équipes de jeux d'horreur, combat/PvE ou exploration, avec beaucoup de trajets dépendant de la géométrie et plusieurs gabarits de NPC. Un jeu à parcours fixe ou à déplacement entièrement custom peut ne rien y gagner. Un développeur qui vérifie deux points une fois doit rester sur un outil gratuit.

| Nature | Preuve ou raisonnement | Ce que cela n'établit pas |
| --- | --- | --- |
| Observation | L'auteur de [Pathfinder](https://devforum.roblox.com/t/1691885) explique que régler taille/rayon/coûts prend du temps et fournit un widget interactif; des réponses saluent le temps gagné. | Aucun temps chronométré ni demande explicite pour une suite payante de tests. |
| Observation | L'auteur de [Pathfinding Widget](https://devforum.roblox.com/t/1791629) voulait éviter de relancer le jeu pour prévisualiser un chemin. | Son outil gratuit résout déjà le problème unitaire. |
| Observation | Un [NoPath en août 2026](https://devforum.roblox.com/t/4827653) a été résolu par un modifier sur le bloc simulant le NPC. Un [autre fil](https://devforum.roblox.com/t/3297423) montre la confusion autour de paramètres de calcul. | Un test de trajet ne corrige pas automatiquement la cause et ne vérifie pas le mouvement réel. |
| Observation | Les API officielles calculent un chemin pour un départ, une arrivée et un profil; Studio expose navmesh et modifiers. [Documentation](https://create.roblox.com/docs/characters/pathfinding). | La documentation consultée ne prouve pas qu'aucun autre outil de tests en lot n'existe. |
| Inférence | Après une modification de portes, escaliers ou passages, conserver les trajets auparavant acceptés éviterait de reconstruire les mêmes essais. | Nous n'avons pas observé directement une équipe refaire cinquante vérifications. |
| Hypothèse | Une équipe qui modifie souvent ses maps préférerait acheter une interface persistante plutôt qu'entretenir son propre harness. | Volonté de payer, taille du marché et fréquence d'usage restent inconnues. |

**Fréquence supposée :** fréquente pendant l'itération d'une map à NPC; occasionnelle hors de ce contexte. Ce n'est pas une fréquence mesurée. **Temps perdu : non quantifié.** Exemple de charge, non observation : 50 couples départ/arrivée et 3 profils représentent 150 calculs à configurer/rejouer. Aucun engagement « 150 tests en dix secondes » ne serait acceptable sans mesure moteur.

#### Concurrents, gratuits et payants

| Outil | Prix; création / mise à jour | Signal public et périmètre annoncé | Menace |
| --- | --- | --- | --- |
| [Pathfinder](https://create.roblox.com/store/asset/9019193064) | Gratuit; 2022-03-05 / 2024-07-31 | Évaluation insuffisante; un [avis public du 2025-01-12](https://create.roblox.com/store/asset/9019193064/Pathfinder/reviews) juge l'outil simple et efficace. Deux points déplaçables, agent parameters et coûts. | **Concurrent direct le plus dangereux** : couvre très bien le besoin ponctuel et bénéficie d'un historique public. |
| [Pathfinding Widget](https://create.roblox.com/store/asset/9621353719) | Gratuit; 2022-05-14 / 2022-06-07 | Compteur 10 / 59 %. Paramètres, coûts et prévisualisation du trajet. | Élimine un produit limité à une preview paramétrable. |
| [Pathfinding Checker](https://create.roblox.com/store/asset/10525099242) | Gratuit; 2022-08-08 / même date | Votes N/D; valide ou non un chemin, description très courte. | Même besoin unitaire; périmètre complet non testé. |
| [PathBuilder](https://create.roblox.com/store/asset/106250114999860) | Gratuit; 2025-07-01 / même date | Votes N/D; son [auteur décrit](https://devforum.roblox.com/t/3791188) édition, sauvegarde/chargement et export de routes. | La persistance de routes seule n'est donc pas une différence suffisante. |
| [NPC Pathfinding Maker](https://create.roblox.com/store/asset/1292342678) | 4,99 USD; 2018-01-01 / 2023-11-10 | Compteur 300 / 61 %. Génération de comportement NPC; périmètre adjacent. | Concurrence pour le budget, mais pas preuve d'une suite de non-régression de map. |
| [NoobAI](https://create.roblox.com/store/asset/103757316856794) | Gratuit; 2026-02-09 / 2026-09-25 | Compteur 20 / 85 %. Patrouille, détection et poursuite configurables. | Élimine une dérive de notre proposition vers un générateur d'IA général. |
| [SimplePath](https://github.com/ahmicy/simplepath) | Open source MIT | Bibliothèque, visualisation et tests présents dans le dépôt; pas un produit payant comparable. | Un scripteur peut composer sa propre boucle de tests et n'a aucune obligation d'acheter. |

**Alternative native actuelle :** affichage navmesh/modifiers, scripts avec PathfindingService et playtests. Assistant/MCP peut désormais lancer des tests, lire Output et déplacer un personnage : l'[annonce officielle de mars 2026](https://devforum.roblox.com/t/4474643) est une menace concrète, pas une possibilité lointaine. La valeur restante devrait être une suite stable, lisible et partageable par l'équipe, avec résultats comparables, sans reconstruire chaque demande à un assistant.

**Différenciation acceptable :** couples de points et profils conservés dans le projet, résultat attendu par cas, exécution groupée, distinction entre « aucun chemin calculé », « erreur API » et « test non exécuté », puis comparaison avec une référence et accès visuel au trajet concerné. Ni un simple bouton de navmesh, ni la sauvegarde de routes, ni un score de santé générique.

#### Workflow et V1 minimale vendable

1. Le level designer définit les départs/arrivées importants et les profils de ses agents. Il indique pour chaque cas si un chemin doit exister ou rester interdit.
2. Il exécute la suite sur une version connue de la map et accepte explicitement cette référence.
3. Après une modification, il relance la même suite. Les nouveaux échecs apparaissent avec le profil, les paramètres et le statut moteur.
4. Il sélectionne un résultat pour localiser les extrémités et visualiser le chemin disponible, corrige lui-même la map, puis relance.

**Démo de dix secondes à concevoir, pas exécutée :** partir d'une petite suite verte déjà configurée, rétrécir une porte, relancer, montrer le seul profil large passé en échec et sélectionner le trajet. La durée de présentation ne serait pas une garantie de temps de calcul.

**V1 proposée :** suites nommées persistantes dans la place, plusieurs profils, attentes explicites, exécution contrôlée/annulable, historique de référence minimal, tableau des régressions et visualisation/sélection. Les objets de test doivent être isolés pour ne pas modifier le navmesh. L'outil doit signaler honnêtement les références supprimées et les résultats incomplets.

**Hors V1 :** génération d'IA, correction automatique de géométrie, test exhaustif de toute la map, promesse de parcours réel réussi, simulation de foule, benchmark FPS, support automatique de tous les contrôleurs custom ou de tous les états de streaming. Ajouter ces promesses avant de prouver l'achat rendrait le produit beaucoup plus risqué.

#### Marché et économie

- **Prix hypothétique : 9,99 USD**, achat unique. Positionnement possible au-dessus de PresetForge pour une équipe qui rejoue réellement beaucoup de cas; ce prix n'est appuyé par aucune vente ou entretien client. Un produit réduit à la visualisation ne justifierait même pas 4,99 USD face aux gratuits.
- **Découverte :** mots-clés `pathfinding test`, `NPC pathfinding`, `pathfinding debugger`, `navigation testing`, `map regression`. Ils décrivent le problème, mais aucun volume de recherche n'a été obtenu. Les recherches larges sont encombrées de générateurs NPC et les expressions précises produisent souvent peu de résultats.
- **Ventes sans contenu régulier :** envisageables avec une fiche très claire, une démo courte et une documentation stable; non démontrées. Le besoin spécialisé limite l'audience. Support et maintenance resteraient nécessaires, même sans publication régulière de tutoriels.
- **Valeur d'achat :** éviter de reconfigurer/rejouer les mêmes cas et de maintenir un harness maison. Le calcul moteur est gratuit; seule l'organisation reproductible du travail est vendable.
- **Décision économique :** ne pas engager le développement sur cette seule recherche. Les signaux d'intérêt pour les previews gratuites ne sont pas une preuve de demande pour un runner de régression payant.

#### Faisabilité et risques

**Difficulté estimée : moyenne à élevée.** Codex peut aider sur UI, stockage et gestion des suites; la difficulté déterminante est la fidélité des résultats au contexte du jeu. Aucun prototype n'a vérifié ici ComputeAsync depuis un plugin, le cycle de tests ou la persistance inter-sessions.

**Dépendances :** PathfindingService, statuts et waypoints, Selection/adornments, stockage de projet, cycle Edit/Run et éventuellement APIs Studio de tests. Les paramètres doivent correspondre à ceux réellement utilisés par le jeu; importer automatiquement tous les scripts serait hors scope. Les limites moteur documentées et les exceptions doivent rester visibles, sans transformer toute absence de chemin en « bug de map ».

**Risques de bugs :** départ placé dans une collision, référence d'instance perdue, marqueur qui altère le monde, mauvais profil, map construite au runtime, streaming client, navmesh en cours de mise à jour, quotas/latences et confusion entre chemin calculable et mouvement réalisable. Un résultat rassurant mais faux serait plus grave qu'une interface imparfaite.

**Maintenance : moyenne à élevée**, notamment autour des évolutions de navigation et de Studio. Un correctif de moteur peut modifier les résultats sans changement de la map. La baseline devrait donc conserver le contexte de test et rester une référence choisie par l'utilisateur.

**Risque natif : élevé.** L'automatisation Assistant est déjà annoncée comme disponible; l'[amélioration de la navigation prévue fin 2027](https://devforum.roblox.com/t/4880208) pourrait encore réduire le coût d'un outil maison. Ce calendrier est une intention publique, pas une livraison garantie. L'avantage d'interface et de suites partagées est copiable.

#### Dernière tentative de rejet

Recherche finale avec de nouvelles formulations : `Pathfinder`, `Pathfinding Widget`, `PathBuilder`, `route tester`, `agent tester`, `navigation validation`, `map traversal`, `waypoint test`, `NPC QA`, `nav test`. Elle complète les recherches initiales et les termes larges `pathfinding`, `navmesh`, `navigation`, `path debug`, `NPC tester`, `path regression`, `reachability`.

Cette passe a bien trouvé des concurrents manqués au premier balayage : Pathfinder, Pathfinding Widget, PathBuilder, [Studio Pathfinder](https://create.roblox.com/store/asset/103851279130496) et [Pathfinder AI](https://create.roblox.com/store/asset/79089627675899). Les deux derniers sont gratuits : Studio Pathfinder, 2025-11-01 / même date, annonce une preview avec coûts; Pathfinder AI, 2026-07-31 / 2026-09-18, a une description trop vague pour déterminer son périmètre, votes N/D pour les deux. Cette inconnue reste ouverte, elle ne doit pas être interprétée comme une absence de concurrence.

Les recherches DevForum `pathfinding plugin test`, `pathfinding regression`, `pathfinding batch`, `pathfinding visualizer plugin` et les recherches GitHub/web ont aussi fait apparaître bibliothèques de navigation, outils de création de routes et automatisation native. **Elles rejettent les variantes preview et création de routes.** Dans les descriptions examinées, aucune n'établit l'ensemble « suite persistante × profils × attentes × comparaison de référence ». Cela justifie seulement À VÉRIFIER, jamais une affirmation d'exclusivité.

**Inconnues qui peuvent tuer la piste :** Pathfinder AI ou un outil non trouvé couvre déjà ce workflow; les équipes n'ont que quelques trajets à vérifier; elles préfèrent leur script/Assistant; elles veulent tester la locomotion réelle plutôt que la calculabilité; la préparation des cas coûte plus que les essais manuels; elles ne paieraient pas 9,99 USD.

La prochaine décision de recherche, sous réserve d'une nouvelle mission, devrait porter sur ces inconnues : examiner ce concurrent opaque et observer quelques équipes rejouer réellement leurs tests. Aucun contact, achat ou développement n'a été entrepris dans le cadre de ce rapport.

## D. Test de différenciation

Le seul survivant reste **À VÉRIFIER**. La différence est concrète pour une équipe qui possède déjà beaucoup de trajets récurrents, mais ce profil d'acheteur n'a pas encore été observé directement. Si la différence ne tient pas après examen du meilleur concurrent ou si ce travail n'est pas réellement récurrent, il faut rejeter la piste.

« Un développeur achèterait ceci plutôt que Pathfinder parce que ses cinquante trajets et ses trois gabarits de NPC seraient conservés et retestés en une seule opération après chaque modification de map, avec la liste des cas qui ne satisfont plus les mêmes attentes, au lieu de reconfigurer les points et paramètres un trajet à la fois. »

## Annexe : requêtes Creator Store exécutées

Chaque ligne correspond à une famille de la section A. Les requêtes sont conservées pour rendre l'audit reproductible; un résultat vide n'a jamais été traité comme une preuve d'absence de concurrent.

| # | Requêtes initiales |
| --- | --- |
| 1 | `asset scanner`; `asset inventory`; `asset id finder`; `content id finder`; `missing asset`; `asset permissions`; `private asset`; `dependency scanner`; `game asset audit`; `asset ownership` |
| 2 | `UI tester`; `device UI preview`; `responsive UI`; `GUI test`; `screen size tester`; `UI emulator`; `text overflow`; `GUI accessibility`; `mobile UI`; `UI previewer` |
| 3 | `particle optimizer`; `VFX optimizer`; `particle performance`; `VFX analyzer`; `effect budget`; `particle audit`; `emitter manager`; `VFX profiler`; `particle editor`; `effects manager` |
| 4 | `pathfinding visualizer`; `pathfinding debugger`; `navigation mesh`; `NPC path tester`; `path tester`; `pathfinding tool`; `waypoint visualizer`; `unreachable area`; `agent radius`; `navmesh analyzer` |
| 5 | `game validator`; `project validator`; `publish preflight`; `game audit`; `project health`; `error scanner`; `game checker`; `release checklist`; `game diagnostics`; `studio linter` |
| 6 | `unused asset`; `unused instances`; `duplicate finder`; `duplicate detector`; `instance cleaner`; `game cleaner`; `orphan finder`; `asset cleanup`; `place cleaner`; `remove duplicates` |
| 7 | `sound manager`; `audio manager`; `sound audit`; `audio organizer`; `sound finder`; `audio preview`; `volume normalizer`; `sound replacer`; `audio scanner`; `sound browser` |
| 8 | `tag editor`; `attribute editor`; `tag manager`; `attribute manager`; `collection service editor`; `tag explorer`; `attribute explorer`; `bulk attributes`; `instance tags`; `tag audit` |
| 9 | `localization`; `translation manager`; `localization audit`; `text localization`; `translation table`; `localization exporter`; `localization scanner`; `untranslated text`; `CSV localization`; `AutoLocalize` |
| 10 | `animation batch editor`; `animation event editor`; `animation marker`; `animation retarget`; `bulk animation`; `animation importer`; `animation exporter`; `animation manager`; `keyframe editor`; `animation audit` |
| 11 | `Rojo`; `Git sync`; `Rojo diff`; `script sync`; `source control`; `model diff`; `place diff`; `project diff`; `version control`; `Rojo helper` |
| 12 | `streaming enabled`; `streaming checker`; `streaming optimizer`; `streaming audit`; `model streaming`; `persistent model`; `streaming readiness`; `world streaming`; `streaming debugger`; `streaming visualizer` |
| 13 | `reference finder`; `instance reference`; `broken reference`; `ObjectValue finder`; `constraint audit`; `broken weld`; `missing attachment`; `dependency graph`; `instance graph`; `reference viewer` |
| 14 | `overlap checker`; `gap finder`; `z fighting`; `geometry validator`; `intersection finder`; `part overlap`; `map validator`; `building inspector`; `collision visualizer`; `level audit` |
| 15 | `color palette`; `material palette`; `color manager`; `theme manager`; `color audit`; `color replacer`; `material replacer`; `style manager`; `GUI theme`; `palette extractor` |
| 16 | `thumbnail creator`; `icon generator`; `model renderer`; `asset thumbnail`; `batch screenshot`; `camera capture`; `render model`; `game thumbnail`; `viewport icon`; `product icon` |
| 17 | `constraint analyzer`; `constraint debugger`; `physics audit`; `physics inspector`; `assembly analyzer`; `weld checker`; `attachment validator`; `unanchored finder`; `mass analyzer`; `mechanism debugger` |

Compléments adversariaux hors navigation : `VFX`, `particle`, `permissions`, `asset detective`, `assembly`, `constraint`; pour les icônes : `item icon generator`, `inventory icon`, `pet icon maker`, `batch icon generator`, `viewport thumbnail`, `catalog image maker`, `render thumbnail`, `screenshot studio`, `3D thumbnail`, `asset icon maker`.

La recherche ne permet pas d'affirmer que le Creator Store manque de plugins. Elle permet de refuser plusieurs produits redondants et de définir une seule question commerciale précise à examiner avant d'investir davantage.
