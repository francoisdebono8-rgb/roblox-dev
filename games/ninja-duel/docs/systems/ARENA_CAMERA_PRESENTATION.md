# Arène, caméra et présentation

ARENA-001..003, CAM-001/002, FX-001/002, UX-001. World construit le tournoi, Camera/Presentation/Effects/feedback présentent le duel ; code et timings actuels restent inchangés dans cette orchestration.

L’arène n’est pas un décor vide : la course doit servir, la distance donne une décision, murs/obstacles/height/LOS créent des angles et parcours. Vérifier range du rush/projectile/FTG, réentrée, cover, wallcarry/pin/bounce/tech, poursuite et outils ; ne pas agrandir encore sur une ancienne demande déjà implémentée sans observer le stade actuel.

Caméra fluide en course, lock/free, dash/teleport/side swap/throw, launcher/chase/slam et mur ; éviter snap, sol masquant le contact, verticalité illisible et transitions verrouillées. Tester les quatre kits à haute vitesse et manette. Caméra sert la lecture du corps/contact, pas un effet spectacle qui masque le défaut.

Présentation de jeunes prodiges : costumes cohérents, visages lisibles, juges/public/bannières/intros/results légers ; pas cinéma long. Réactions physiques par zones, usure, knockdown/KO et réception utiles. Audio contacts/parry/steps/outils et annonces ont leur place après qualité du mouvement. Spectacle/VFX vient en second : ne pas gonfler HP pour faire durer une séquence pauvre.

Les reports documentent ce qui existait sur leur version : [phase3](../reports/PHASE3_REPORT.md), [phase4](../reports/PHASE4_REPORT.md), [arena](../reports/ARENA_COMBO_REPORT.md), [final today](../reports/FINAL_TODAY_REPORT.md), [45min](../reports/FINAL_45MIN_REPORT.md). La liste d’anciens défauts doit être reproduite, pas considérée comme actuelle. Sources détaillées : [scale/combo](../archive/missions/CLAUDE_ARENA_SCALE_COMBO_FREEDOM_PASS.md), [final](../archive/missions/CLAUDE_FINAL_PASS.md).
