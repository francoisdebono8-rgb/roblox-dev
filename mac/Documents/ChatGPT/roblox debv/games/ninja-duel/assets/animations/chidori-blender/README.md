# Chidori — étude animée Blender

Scène originale : Sasuke stylisé sur un squelette de type R15, Chidori main gauche. 168 images à 24 images/seconde, soit 7 secondes.

- `Chidori_R15.blend` : scène modifiable, personnage articulé, animation complète, électricité animée, caméra et éclairage.
- `Chidori_R15.fbx` : personnage et animation du corps, sans décor ni effets Blender.
- `Chidori_preview.mp4` : aperçu rendu, sans son.

Ouvrir le `.blend` dans Blender et appuyer sur Espace pour jouer. Les marqueurs de la timeline repèrent les phases : préparation, charge, poussée, course alternée, pose du pied, frappe, récupération. L'animation est dans l'action `CHIDORI__charge_run_thrust_recover__24fps` du squelette `Sasuke_Chidori_R15`.

La scène comporte quinze os de corps nommés d'après R15 plus une racine de déplacement. Le modèle a été créé pour cette étude : ce n'est pas l'avatar exporté de Ninja Duel. L'échelle, les axes locaux et les attaches devront être adaptés à l'avatar réel avant importation comme animation Roblox. Aucun script du jeu n'est modifié et aucune animation Roblox n'est publiée.

Le FBX contient le mouvement de racine. Les effets électriques restent séparés dans Blender ; ils ne font pas partie de l'animation de squelette FBX. L'éclairage bleu suit la main, les éclats de pierre commencent au contact.

Reconstruction : lancer Blender avec `--background --factory-startup --python build_chidori.py`. La scène utilise le compositeur de Blender 5.2 ; les noms de prises et l'export FBX sont conservés pour la retouche.
