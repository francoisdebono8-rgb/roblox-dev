# Marché optionnel futur — aucune implémentation

Le profil actuel contient des compteurs/fragments et des flags de maîtrise ; ce ne sont pas des objets échangeables avec provenance. Ne pas construire un marché directement sur ces balances.

À prévoir si le produit retient cette option :

- Registre d'objets : ID d'instance serveur unique, type/version, propriétaire, origine/grant, quantité éventuelle, statut réservé/transféré. Tags tradeable/accountBound/masteryBound ; définir explicitement si fragments, cartes et personnages sont transférables. Conserver les XP/maîtrises personnelles hors transfert par défaut de conception à confirmer.
- Offre serveur : offerId, participants, objets réservés, expiration, prix/monnaie, révision attendue. Le client propose des ID ; le serveur vérifie ownership, disponibilité, restrictions et soldes avant réservation. Une sélection client n'est jamais une preuve d'ownership.
- Transfert durable : les deux profils ne sont pas une transaction DataStore unique. Employer un coordinateur/escrow avec intentId et étapes persistées reserve → commit → finalize, compensations explicites et récupération après crash. Ne pas confondre deux UpdateAsync successifs avec une écriture atomique entre joueurs. Chaque étape doit supporter retries/rejeu ; bloquer la revente d'un objet réservé, ne jamais recréer un objet lors d'un retry.
- Historique/audit : intent/offer/item IDs, version, avant/après, propriétaire, monnaie et provenance. Retenir les preuves nécessaires à la récupération ; pagination et politique de rétention, aucune liste infinie dans un profil. Définir reconciliation des intents en attente et procédure de restitution.
- Prix/cote : annonces demandées et échanges effectivement réalisés séparés, timestamps/volumes, échantillon minimum et médiane robuste. Une cote affichée n'est pas un solde ni une garantie ; contrôler auto-échanges et manipulations de volume. Aucun prix final proposé ici.
- Restrictions : permissions d'échange, limites de cadence/volume, règles de liaison au compte, éléments exclus, interactions avec progression et monnaies premium décidées avant intégration. Ne pas ajouter de transferts premium implicitement.

Validation future : crash après chaque étape, acquittement perdu, double acceptation, offers expirées, writers concurrents, transferts opposés/deadlock, item déjà réservé, déconnexion, rollback/reconciliation ; invariants de conservation des objets et de la monnaie. Revoir ensuite les contraintes de plateforme applicables au produit choisi. Aucun Remote, UI, pricing service ni moteur d'échange n'est créé par cette passe.
