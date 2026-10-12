# Règles d’exécution

## Reprise et approbation unique

Lire START → vision → décisions → état → depuis Claude → backlog → capacités. Inspecter `git status --short`, `git log`, diff depuis la dernière base enregistrée, puis les sources/specs pertinentes et l’artefact natif. Lire les détails archivés rattachés aux IDs visés, pas tout le repo sans nécessité.

Proposer un plan dépendant : baseline/test/Studio ; mouvement ; contact/defense/outils ; identités des quatre personnages ; arène/caméra/présentation ; validation. Adapter l’ordre aux preuves. Expliquer IDs inclus, déjà résolus, différés, dépendances, critères et risques. Demander une seule approbation globale pour ce plan avant ses changements gameplay. Enregistrer son texte/portée et l’approbation dans le journal ; une préparation documentaire ou un ancien délai « aujourd’hui/45 min » ne vaut pas approbation.

Après approbation, exécuter des blocs cohérents sans redemander à chaque fichier. Demander seulement une vraie décision de scope/design contradictoire, un conflit insoluble ou un blocage majeur nécessitant l’utilisateur. Les autorisations explicites de la session persistent. Le diagnostic, l’examen des sources et la construction du plan sont autonomes.

## Jugement et preuves

Claude peut reprioriser, améliorer une solution, constater qu’une intention est déjà satisfaite autrement, ou rejeter une mauvaise proposition. Il doit expliquer chaque disposition dans le backlog : aucune omission silencieuse. Une adaptation Studio renseigne décision, effet, contre-jeu, preuves et source, plutôt qu’effacer l’exigence.

Statuts : OPEN, PARTIAL, IN_PROGRESS, DONE, BLOCKED, DEFERRED, REJECTED. `IMPROVED` est un résultat enregistré avec `status: DONE` et `outcome: IMPROVED`, preuves et validation. DONE ne signifie pas automatiquement qualité visuelle ; le critère du ticket précise technique/native/humain. BLOCKED donne cause et condition de sortie ; DEFERRED donne déclencheur ; REJECTED donne justification. Les sources de recherches contiennent des candidats, pas un ensemble de fonctionnalités approuvées.

Avant un bloc, prendre baseline/tests/builds concernés. Après, relancer les suites et reconstruire l’artefact exact ; enregistrer SHA256, HEAD, outil, protocole, résultat et limites. Judge le mouvement dans Studio (pieds, poids, hanches, contact, récupération), puis la caméra et le duel à la manette. Un test headless valide un contrat, pas une animation premium. Un ancien rapport n’est pas une preuve nouvelle.

Ne pas réécrire un système qui passe et répond déjà à l’intention. Reproduire les anciennes listes de bugs (attaque/saut, landing, launcher/chase, airslam, téléport/poursuite, wall dash, mash/cancel/hitstun) sur la base actuelle avant de les rouvrir. Ne pas changer silencieusement le balance ou les moteurs lors d’une passe visuelle.

## Architecture et conservation

Serveur autoritaire, données/inputs validés ; client présentation/inputs. Le jeu n’importe aucun code des plugins historiques ; plugins n’importent aucun code Ninja Duel. Motion Lab peut adapter le jeu, jamais l’inverse. Shared exige deux consommateurs réels.

Avant tout déplacement/suppression : rechercher chemins, noms, imports/scripts/docs, identifier tous les consommateurs et chemins dynamiques, préserver le transversal, mettre à jour les références, tester chaque consommateur. Usage ambigu : conserver et inscrire au rapport. Aucun contenu utile supprimé avant extraction de ses exigences. Aucune installation/publication de plugin ou place implicite.

Clore chaque bloc par le [protocole de mise à jour](UPDATE_PROTOCOL.md). Un backlog garde les futurs besoins même si le plan présent est plus court.
