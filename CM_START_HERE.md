# CM — START HERE : produire 3 vrais pilotes, sans clip buggé
Date : 2026-11-05. Propriétaire de cette branche : communauté / promotion. Pas de changement de gameplay.

## À lire dans cet ordre (pas besoin de parcourir toute la documentation du jeu)
1. [RUNBOOK DE TOURNAGE ET ANTI-BUGS](CM_EXECUTION_RUNBOOK_SHOTS_AND_BUG_QA.md) — **COMMENCER ICI**. Commandes Studio, angles, plan par plan, critères de rejet des rushes.
2. [Bible des trois séries](CM_THREE_SERIES_PRODUCTION_BIBLE_2026-11-05.md) — NINJA IQ, PRODIGY FILES, BUILDING THE IMPOSSIBLE, pilotes et ligne éditoriale.
3. [Film 01 : The Kunai Was Bait](PRODUCTION_FILM_01_THE_KUNAI_WAS_BAIT.md) — storyboard précis Minato–Neji.
4. [Caméra Studio](cm_tools/NDCM_CAMERA_PRESETS.client.luau) — à exécuter depuis la Command Bar CLIENT en Studio Play/Debug.
5. [Prises dirigées](cm_tools/NDCM_DIRECTED_TAKES.server.luau) — à exécuter depuis la Command Bar SERVER en Studio Play/Debug.
6. [Contrôle technique MP4](cm_tools/video_qc.py) — script local qui signale noirs/freezes et construit des planches-contact. Ne remplace jamais l'inspection artistique humaine.

## Mandat exécutable
Réaliser **UN pilote master A1** de qualité (Minato vs Neji, 17,5 s) avant le volume. Chaque plan doit passer les gates technique + visuel + mobile. Ensuite réaliser B1 (Itachi character showcase) et C1 (devlog caméra, ancien/nouveau build vérifiés). Conserver des rushes éditables et un rapport QC.

**Si une action du moteur échoue ou si le combat a des mouvements buggés, REJETER le plan**. Ne jamais cacher l'erreur par un flash, un cut trompeur ou un faux impact. Une vidéo techniquement exportée mais artistiquement défectueuse n'est pas un livrable.

**Rester honnête :** les scripts CM ci-dessus viennent d'être rédigés en lisant le code ; ils ne sont pas encore validés dans Studio. Faire un test Play/Debug et noter les erreurs réelles avant de produire une pub. Les captures dirigées en Debug ne sont pas des images de PvP live ; les rendus concept ne sont pas du gameplay. V39 était un test lors de cette consigne.

**Ne pas publier sur TikTok/YouTube sans feu vert du créateur.** Aucun achat de plugin ni changement des scripts gameplay sur ordre de cette branche.

## Format attendu à la fin
MASTER 9:16 + CLEAN 9:16 + COVER + projet montage éditable + preuve in-game + planche-contact + tableau ACCEPT/REJECT des prises (avec versions SHA) + 3 défauts corrigés et avis de spectateur. Statut : READY FOR USER REVIEW ou BLOCKED avec preuve et alternative.
