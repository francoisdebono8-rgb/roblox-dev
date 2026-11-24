# Passe commune 1, ANIMATEUR (23/11) : les habits du départ, les maisons en morceaux

Brouillon jusqu'à l'avis de François (DEC-046). Tout est vu en rendu Blender, rien dans Studio.

- **Les habits du départ** : revers croisé, obi noué, manches kimono, pans de jupe sur les cuisses, pantalon bouffant et mollets bandés, semelles épaisses. `habits_depart_avant_apres.jpg` (3 corps, face en haut, dos en bas) et `habits_depart_4_tenues.jpg`.
- **La collision des maisons** : `Shared/HubSolids.luau`, quelques solides par maison qui suivent ce qui est dessiné (murs, chaque pente de toit, bouts de croupe, auvents, balcons, garde-corps, escaliers, réservoirs). `maisons_solides.jpg` : les solides en rouge sur chaque modèle. C'est au DEV de les construire dans `Server/Hub`.
- **Cinq maisons d'Edo**, sans réservoir : maison de ville, auberge, kura, maison de thé, ferme au chaume. `maisons_edo.jpg`. Elles attendent le plan de la nouvelle ville.

## Suite (24/11)

- **Les voyous** : leur tenue (`voyou_tenue.jpg`, de face, de dos, de trois quarts) et leurs quatre clips, Idle, Racket, Taunt et Leave (`voyous_raikiri_clips.jpg`), joués sur ton écran par `Client/KonohaRogueFX`.
- **La vie de Konoha** : plus de tonneau ni d'étal là où l'on arrive, près des maîtres ni sur les places de duel.
- **Raikiri** : le clip `Copycat.Raikiri` (brouillon, note 7,6) et la traînée d'éclairs le long de la course.
