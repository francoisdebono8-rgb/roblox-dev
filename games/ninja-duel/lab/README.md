# Bibliothèque optionnelle pour Claude

Aucun fichier de `lab/` n’est chargé par le jeu ni par le build. Ce sont des propositions à reprendre, adapter ou ignorer. Les noms d’attaques servent à repérer les briques existantes, sans garantir qu’une séquence soit aujourd’hui autorisée.

`combat-library.json` contient 33 propositions : usage, contexte, dix familles de personnages, difficulté, risque, valeur visuelle/gameplay et points d’intégration. Les variantes Minato/Itachi/Neji/Sasuke référencent le catalogue ; elles ne remplacent aucun moveset.

`templates/` décrit les formes des données existantes, avec valeurs non décidées à `null`. Aucun générateur ne les enregistre. `combat-tags.json` est une taxonomie de travail, sans effet sur les acteurs.

Depuis le dossier du jeu (`python` sous Windows) : `python3 tools/dev.py catalogue --archetype acrobatique` pour filtrer, `python3 tools/dev.py compare` pour extraire/comparer les véritables données actives, et `python3 tools/dev.py verify` avant toute proposition d’intégration. Voir [DEVTOOLS](../docs/tools/DEVTOOLS.md) pour Studio et les checklists.

Porté depuis Codex (`33028b2`) sans modification des données ; `tests/test_build_isolation.py` vérifie que le catalogue reste valide et qu’aucune source `src/` ne le référence.
