> Guide technique (outil Studio). État, priorités et règles : [sources actives](../active/EXECUTION_RULES.md).

# Outil visuel F7 — lumière, ombres, visibilité des effets, tout ce qui casse

Demandé par le propriétaire le 08/11/2026 : « un outil sur la visibilité des effets, lumières, ombres du jeu et tout ce qui bug ».

Module : `src/Client/DevVisual.luau`, chargé par `DevClient` dans les places **DEV, QA et FILM** uniquement (`build.py` `DEBUG_SOURCES`, prouvé par `tests/test_build_isolation.py`). La place GAME (`ND-JEU`) ne le contient pas.

## Utilisation

Ouvrir `ND-DEV.rbxlx` (ou une copie dans `LAB/repro/`), **Play**, lancer un duel, puis **F7** :

| Appui | Ce qui s'affiche | Combat |
|---|---|---|
| 1er | le panneau (à gauche) | bloqué, comme F6 |
| 2e | un bandeau en haut à gauche : FPS, effets, lumières, surbrillances, derniers problèmes | jouable |
| 3e | rien | normal |

Rien ne change le jeu : la lumière et la visibilité sont modifiées **sur cet écran seulement**. « Remettre le jeu » remet tout comme avant.

### Onglet Lumière
- Lecture en direct : heure, latitude, luminosité, exposition, ombres globales, technologie, ambiances, post-effets, lumières d'effet allumées (dont avec ombres), surface Néon visible.
- Éclairages de test : **Jeu (d'origine)** (celui de `Client/WorldLook`), **Fin d'après-midi (film)** (réglage de tournage du 06/11), **Midi plein soleil**, **Contre-jour**, **Nuit**, **Gris neutre** (pour juger un effet sans l'étalonnage).
- Heure ±1 h, exposition ±, luminosité ±, ombres globales ON/OFF, post-effets ON/OFF.
- Tant que l'outil tient la lumière, `WorldLook.borrowed` est vrai (comme le menu) : le jeu ne la réimpose pas. « Jeu » la rend.

### Onglet Effets
- Compteurs : émetteurs de particules (allumés), mémoire des particules, faisceaux et traînées, lumières, surbrillances **sur 31** (au-delà Roblox n'en dessine plus aucune, les contours des corps disparaissent), sprites 2D, formes d'effet, marques au sol, saccades.
- Cacher / montrer chaque famille : particules, faisceaux/traînées, lumières, surbrillances, sprites 2D, formes d'effet, marques au sol, post-effets. Sert à savoir quel effet produit ce qu'on voit.
- Contours des effets (bleu ; rouge si l'objet a un problème), particules figées ou au ralenti ×0,2, « Couper les ombres des effets » (essai sur l'écran ; la vraie correction se fait dans `src/`).

### Onglet Problèmes
Liste en direct, triée erreurs → à voir → infos, avec l'heure et le nombre de fois :

| Problème | Gravité |
|---|---|
| Erreur de script (client ou serveur) | ERREUR |
| Image ou maillage qui ne charge pas | ERREUR |
| Effet qui bloque les corps (CanCollide) | ERREUR |
| Trop de surbrillances (≥ 25 sur 31) | ERREUR |
| Effet qui projette une ombre | À VOIR |
| Lumière d'effet avec ombres, lumière très forte, trop de lumières | À VOIR |
| Grande surface Néon (éblouit) | À VOIR |
| Effet qui ne disparaît pas (> 20 s), émetteur resté allumé | À VOIR |
| Marque au sol en l'air | À VOIR |
| La caméra est dans un effet | À VOIR |
| Surbrillance restée allumée sur un corps | À VOIR |
| Animation pas chargée | À VOIR |
| Particules sans image (carré blanc) | À VOIR |
| Avertissements, saccades > 120 ms, corps presque invisible > 3 s, marque enterrée, éclairage inhabituel | INFO |

Cliquer une ligne : l'objet s'entoure en jaune 3 s et son chemin complet part dans Output. « Rapport → Output » imprime tout en lignes `[NinjaDuelVisual]` (JSON), à joindre à un bug (RUNBOOK § 4).

## Pour les agents (Studio MCP)

Côté Client, pendant le Play :

```lua
local r=game.Players.LocalPlayer.PlayerGui.DevVisualPanel.Report
print(r:Invoke())                 -- rapport JSON (compteurs, lumière, problèmes)
r:Invoke("mode",2)                -- 0 fermé, 1 panneau, 2 bandeau
r:Invoke("preset","nuit")         -- jeu, film, midi, contre, nuit, gris
r:Invoke("hide","particles")      -- particles, beams, lights, highlights, sprites, shapes, marks, post
r:Invoke("show","particles")
r:Invoke("restore")               -- tout comme le jeu
r:Invoke("clear")                 -- vide la liste des problèmes
r:Invoke("tab","lumiere")         -- lumiere, effets, problemes
```

## Limites connues
- Les familles sont reconnues par leur classe et leur dossier (`NinjaDuelFX`, `Effects`, `NinjaUltimateFX`, `VfxMesh`, `WorldMemory`, noms en Scar/Mark/Crater…). Un effet posé ailleurs n'est compté que s'il est une particule, un faisceau, une lumière, une surbrillance ou un sprite.
- Les erreurs serveur viennent du relais `NinjaDuelDevLog` de `DevHooks` (« serverlog »).
- Une saccade dit qu'une image a été longue, pas quel script en est la cause : pour l'attribuer, utiliser les mesures F6 / MicroProfiler (DEVTOOLS.md).
- La technologie d'éclairage (Future, ShadowMap…) se lit mais ne se change pas en jeu.
