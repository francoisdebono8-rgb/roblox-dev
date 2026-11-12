# ANIMATEUR — passe lumière : ombres, blanc cassé, halo, images (12/11/2026)

Branche `work/anim-light-shadows`, faite à partir de la référence 268a183 (#58, #59, #60, #61 fusionnées).

## 1. Ombres : la lumière n'en projette pas (fait)

**`src/Client/ShadowFX.luau` (nouveau).** Une seule règle pour tous les effets, quel que soit le module qui les crée :
- Toute pièce posée dans le dossier des effets (`workspace.NinjaDuelFX`) passe en `CastShadow = false` dès qu'elle y arrive : feu, foudre, sable en vol, halos, auras, traînées.
- Les pièces créées par `block()` l'étaient déjà. Le garde rattrape les pièces faites à la main (`Instance.new`, `K.new("Part")`), qui projetaient une ombre par défaut.
- **Exception, attribut `KeepShadow`** (posé sur la pièce ou sur son modèle) : ces objets gardent leur ombre. `ShadowFX.keep(part)` pose l'attribut et l'ombre.

Ce qui garde son ombre :

| Objet | Fichier |
|---|---|
| Cailloux de l'élément Terre | `ChakraFlowFX` |
| Pic de terre | `ChakraFlowFX` |
| Blocs de sol arrachés | `GroundFX` |
| Rochers des ultimes (2 endroits) | `UltimateFX` |
| Bûche de substitution | `Effects` |
| Chiens ninja de Kakashi | `HoundFX` |

Hors du dossier des effets :
- `VelmoraHitFeedback` (éclats, poussière de mur, anneau d'atterrissage, ancre d'impact, tous posés dans `workspace`) : `CastShadow = false`.
- `VfxKit` (ancre des sprites) : `CastShadow = false`.

Côté serveur, `Combat:effect` avait déjà `CastShadow = false`.

Test : `tests/Shadow.spec.luau` (4 tests), branché dans `run.sh`.

**Question pour toi.** Les accessoires solides tenus en main (éventail de Temari, kunai, fil, Kamatari) passent par `block()` et n'ont donc pas d'ombre. Avec les ombres du jeu activées, ils peuvent paraître flotter. Je les passe en `KeepShadow` comme les rochers ?

## 2. Tenues blanches et peaux (couleurs : faites ; plis et coutures : prêts, en attente d'envoi)

**Couleurs.** Elles changent tout de suite, sans nouvel envoi :
- **Blanc cassé** : le canal le plus clair est ramené à 226 au plus, avec la même teinte. Par exemple :
  - chemise de Neji 236,230,216 → 226,220,207 ;
  - blanc de Minato 236,238,242 → 220,222,226 ;
  - short de Sasuke 238,236,230 → 226,224,218.
  - Mêmes règles pour : bandages de Neji, Lee et Naruto, col de Naruto, rond blanc dans le dos de Sasuke, attache de cheveux de Neji.
- **Peaux** : le canal le plus clair est ramené à 238 au plus, pour les 8 personnages. Par exemple, Naruto 252,220,186 → 238,208,176.
- Appliqué dans les sources Blender (`nd_kit.off_white`, `skin_tone`), dans `imports/*.manifest.json`, puis `LookMeshData` régénéré par `looks_to_luau.py` (84 pièces recolorées). Mêmes valeurs dans les looks de secours (`Server/Looks.luau`).
- Vérifié : aucun regroupement de pièces par couleur ne change, donc tous les maillages déjà envoyés restent valables.

**Plis et coutures, dans les looks Blender** (`nd_kit` : `shirt_detail`, `trouser_detail`, `wrap_detail`). Les coutures sont d'un ton plus sombre (×0,82), les plis aussi (×0,88) :
- **Haut blanc** (Neji, Minato) :
  - coutures sur les côtés du buste ;
  - coutures d'épaule et sous les bras ;
  - plis au creux des coudes ;
  - plis à la taille ;
  - ourlet piqué (Neji).
- **Pantalon blanc** (Minato) et **short** (Sasuke) :
  - coutures sur l'extérieur des jambes ;
  - plis aux hanches ;
  - fronces sous la ceinture ;
  - plis derrière les genoux (Minato).
- **Bandages** (Neji, Sasuke, Itachi, Gaara, Naruto) : les tours de bande sont visibles, en lignes légèrement inclinées.
- 47 nouvelles pièces au total (Neji 14, Minato 19, Sasuke 7, Gaara, Itachi et Naruto 2, 2 et 1).
- Les FBX et les fichiers de couleurs sont sur le Mac : `LAB/looks-v2/`.
- **En attente d'envoi** (voir le point 5). Ensuite :
  1. importer les FBX ;
  2. compléter `imports/*.studio.json` ;
  3. relancer `looks_to_luau.py`.

## 3. Halo à 2,2 : à revoir quand la lumière du DEV sera en place

Avec le seuil à 2,2, le Neon uni n'atteint plus le halo. Ce qui reposait dessus :

| Effet | Où | Ce qui brillait grâce au halo |
|---|---|---|
| Chidori | `Effects` (sphère, désormais en ForceField), `LightningFX` | sphère de la main ; les éclairs en Beams avec LightEmission 1 restent lumineux |
| Rasengan | `IdentityFX` (~418) | anneaux en Neon (RASENGAN, RASENGAN_CORE) |
| Éclair jaune | `IdentityFX` (MINATO, MINATO_CORE : anneaux ~361, glyphes du corps ~259) et `DashTrailFX` | anneaux et glyphes en Neon |
| Cheveux de Minato | look (255,218,80) | la couleur seule ; plus de halo |

Pistes, à valider en jouant avec la vraie lumière :
- remplacer le Neon par des Beams ou des particules en LightEmission 1 (le principe de la bible) ;
- ajouter une PointLight brève sur les cœurs ;
- pour les cheveux de Minato : une Highlight légère pendant l'éveil plutôt qu'un halo permanent.

Je ne touche à rien avant de voir la nouvelle lumière : régler sur l'ancienne serait refait.

## 4. Les 9 images d'AwakenFX (régénérées, en attente d'envoi)

- Régénérées avec `vfxgen.py` (branche `claude/vfx-redesign`, mêmes recettes) : spark, smoke, fire_burst, flame_loop, lightning, ring, leaf, feather, glyph 飛雷神.
- Vérifiées à l'œil.
- Elles sont sur le Mac : `LAB/vfx-reupload/`.
- Dès que les nouveaux identifiants existent, je les mets dans `AwakenFX.TEX`. Les images de secours restent en filet de sécurité.

## 5. Ce qui bloque, et comment le débloquer

Studio refuse les envois avec ses propres messages :
- « not inside a directory approved for uploads » : `LAB` n'est pas un dossier autorisé pour les envois ;
- « Scope 'asset:read' has not been granted » : la lecture est nécessaire pour savoir si Roblox a accepté l'image, et pourquoi les anciennes ne s'affichent pas.

Il faut, dans **Studio > Assistant > Settings > MCP Permissions** :
1. ajouter `~/Documents/NinjaDuel/LAB` aux dossiers autorisés pour les envois ;
2. accorder `asset:read`.

Autre possibilité : le plugin Blender officiel de Roblox, avec ta connexion.

## 6. Tests

- Suite Lune : tout passe, sauf `CameraFeel`, qui échoue déjà sur la référence.
- `Naruto` passait de nouveau après la correction de la bûche (un `SetAttribute` est maintenant protégé par un `pcall`).
- Nouveau : `Shadow`, 4 tests.

## 7. À tester en jeu (avec la lumière du DEV)

1. Un Katon, un Chidori ou un sable en vol au-dessus du sol : aucune ombre noire sous l'effet.
2. Un ultime qui soulève des rochers, ou un coup qui arrache le sol : les rochers ont leur ombre.
3. Neji et Minato au soleil : le blanc garde du relief, il ne brûle pas en une tache.
