# V0.2 — audit visuel Roblox avant l'UI finale

Date : 15 octobre 2026. Baseline : bc0bf2f54414b67ad102ad35da6c49d4e9f1713f.
Frontend Skill est exclu des décisions visuelles et UX. Les captures de recherche ne sont ni des assets du jeu ni des médias commerciaux. Aucun asset ni code tiers n'est repris.

## Sources effectivement observées

| Référence | Preuve et nature | Observation visuelle | Traduction pour Forge & Flex |
|---|---|---|---|
| The Forge | [Capture de sélection de minerais](https://deltiasgaming.com/roblox-all-the-forge-armor-recipes/), `qa/references/the-forge-materials.png`, gameplay statique | La forge physique reste au centre. Deux panneaux latéraux occupent environ un cinquième de la largeur chacun. Petites cartes de minerais avec volume 3D, nom et quantité. Le bouton FORGE! est environ cinq fois plus large qu'une carte ; il ferme la composition en bas. | Le choix du matériau prépare une action physique. Mettre le matériau et son effet dans une carte, puis un seul grand CTA. Ne pas reproduire la densité des probabilités de cet RPG dans notre tycoon mobile. |
| Marble Merge Tycoon | [Capture des paramètres](https://www.sportskeeda.com/roblox-news/marble-merge-tycoon-codes), `qa/references/marble-merge-settings.png`, gameplay statique annoté par le guide | Titre blanc très épais avec contour sombre, grand X rouge dépassant du panneau, boutons bleus de même taille ; Locked est écrit et grisé. Les icônes restent lisibles sur le monde vert et bleu. Le panneau occupe environ 37% de la largeur, le monde reste visible autour. | Titres courts, contours forts, boutons hauts avec état textuel. Fermeture toujours au même endroit. Les informations secondaires passent dans le contexte ouvert, pas en bandeaux permanents. Ne pas reprendre la multiplication des devises et boutons périphériques. |
| Forge a Weapon | [Page officielle](https://www.roblox.com/games/126625214460461/Forge-a-Weapon), captures officielles obtenues via l'API Roblox, `forge-a-weapon-official-presentation.png` et `forge-a-weapon-workshop.png` | Visuels promotionnels, pas preuve du HUD : grande silhouette d'arme, contraste métal simple / arc-en-ciel, contour noir, chiffre de progression dominant. L'atelier est concentré autour d'une enclume ; armes et supports se trouvent directement derrière elle. | Le joueur doit reconnaître l'objet avant de lire son nom. Grande arme au reveal, variante visible dans sa silhouette et ses matériaux. Enclume, four et vitrine dans un même champ de caméra. Ces images ne permettent pas de conclure sur la durée d'un reveal ou les boutons de son inventaire. |
| Build A Factory Tycoon | [Page officielle](https://www.roblox.com/games/99882939762109/Build-A-Factory-Tycoon), `build-factory-official-progression.png`, comparaison promotionnelle de scènes 3D | Installation initiale courte, puis machines plus hautes, portiques, convoyeurs lumineux et densité de production supérieure. Le contraste avant/après se lit sans menu ; les machines ont des accents colorés par fonction. | Les upgrades ajoutent du volume : double brûleur puis renforts ; les slots ajoutent de vrais supports. Magma et Arcane changent architecture, lumière et silhouettes, pas seulement la couleur d'une dalle. Pas de système de convoyeurs ajouté au scope. |

Ces quatre références sont auditées visuellement, avec leurs limites explicites. Deux sources montrent des interfaces de gameplay et deux montrent la présentation officielle d'objets/monde. Aucune animation, ergonomie tactile ou boutique non observée n'est attribuée à ces jeux. Les séquences reveal/merge ci-dessous sont des adaptations de la spec utilisateur, à vérifier dans notre propre playtest natif. Les vidéos homonymes anciennes de Weapon Factory ne sont pas utilisées : l'identité du jeu de la spec n'est pas suffisamment établie.

## Contrat visuel d'implémentation

- HUD : pièces en haut à gauche ; un objectif avec jauge en haut au centre ; boutique/paramètres à droite. Quatre entrées en bas : Inventory, Collection, Forge, Upgrades. L'aire centrale doit laisser voir l'atelier.
- Typographie Roblox : titres gras et contrastés, libellés courts, contour sombre sur les titres flottants. Aucun tableau de bord de type SaaS, liste de propriétés ou texte de debug en jeu.
- Cibles tactiles : minimum 48 px logiques sur le téléphone de QA, espacement de 8 px. Boutons d'action 52–60 px ; fermeture 48 px. Vérifier sur le rendu natif, pas seulement dans le code.
- Cartes : l'arme 3D occupe plus de la moitié de la carte. La rareté est un mot ET une couleur de bord/dégradé. Nom, mutation et valeur ont chacun une ligne lisible. Le détail remplace les boutons multiples sur chaque carte.
- Reveal : fond assombri sans panneau opaque massif ; arme dominante au centre, rotation lente ; titre de rareté puis valeur puis mutation. Trois décisions grandes et stables. Legendary/Mythic ajoutent un burst et une couronne de rayons ; mode VFX réduits conserve les informations.
- Merge : trois objets visibles avant validation ; absorption vers le centre puis le même langage de reveal. Quick Merge réduit la durée, jamais la validation serveur.
- Boutique : offres de confort en cartes avec bénéfice et prix réel configuré. Aucune fenêtre d'achat automatique. Une suggestion contextuelle peut apparaître après quatre minutes, fermable et unique.
- Palette propre au jeu : atelier bois brun/pierre chaude, actions orange forge, vente vert monnaie, collection bleu, merge violet ; raretés existantes conservées. Les couleurs servent l'action et l'objet, pas une grille de cartes identiques.
- Pas d'assets copiés. Les icônes et modèles sont originaux, construits dans Roblox.

## Audit du build initial

| Élément | Classe | Décision |
|---|---|---|
| Transactions serveur, verrouillage vente/merge, reçus persistés avant ACK | GOOD | Préserver et faire passer les régressions. |
| Premier craft qui finance le premier upgrade | GOOD | Préserver ce rythme en ajoutant chauffe et impacts. |
| Réutilisation des modèles pour inventaire et vitrine | ACCEPTABLE | Garder le principe, refaire les modèles modulaires et leur cadrage. |
| HUD large + tutoriel permanent + cinq onglets + bouton de forge isolé | CODEX-PROTOTYPE | Recomposer selon le contrat HUD. |
| Reveal dans le panneau générique d'inventaire | CODEX-PROTOTYPE | Remplacer par une scène de récompense dédiée. |
| Grille sombre avec armes petites et texte long | CODEX-PROTOTYPE | Cartes dominées par l'objet, détail contextuel. |
| Collection limitée à neuf cases sans variantes ni récompenses | CODEX-PROTOTYPE | Index de découvertes, silhouettes et paliers. |
| Merge seulement confirmé par une notification | CODEX-PROTOTYPE | Trois entrées, absorption et reveal de sortie. |
| Même atelier rectangulaire, zones par recoloration, six socles déjà posés | CODEX-PROTOTYPE | Donner une composition et des volumes distincts aux trois zones ; ajouter les supports au déblocage. |
| Armes en quelques Parts uniformes, mutations surtout lumineuses | CODEX-PROTOTYPE | Lame, garde, poignée, matériau et effets reconnaissables. |
| Hooks audio sans IDs | ACCEPTABLE, incomplet commercialement | Conserver le fonctionnement sans erreur ; documenter les sons à configurer. Ne pas inventer d'IDs. |

Baseline visuelle conservée dans `qa/native-before.png`, `qa/mobile-before.png` et les captures release V0. Les captures finales devront être faites dans Studio sur le build exact, et comparer les mêmes usages.
