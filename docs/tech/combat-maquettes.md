# Combat : cadrage du pilote et rapprochement des maquettes

> Plan préparé par Claude le 2026-10-07, **décisions de Kevin le même jour** : on fait en parallèle (1) le **cadrage validé du pilote avec l'artwork officiel de l'adversaire** et (3) l'**interface de combat rapprochée des maquettes** ; les dos peints des Pokémon du joueur restent pour plus tard (J11, premier lot de dos d'abord) ; **cartes de PV sur la diagonale opposée aux Pokémon** (carte adverse en haut à gauche, la tienne en bas à droite au-dessus des commandes : cadrage du pilote, préféré à la maquette) ; branche `combat-maquettes` depuis `main`, en parallèle du J9 (autre session, qui touche aussi le combat : conflits résolus à la fusion par celle qui arrive en second).
>
> Références : `docs/design/reference/combat-v1.webp`, `combat-capacites-v1.png`, `combat-capture-v1.webp` (décrites dans `ui-reference.md` l. 15–17), `dossier-05-combat.md`, `fiches-assets/serie-combat-dos-pilote.md` §1 (cadrage figé le 2026-10-05), prototype `proto/battle_faceoff/` de la branche `art/pokemon-pilote` (dossier `.claude/worktrees/art-pokemon`), skill `ui-theme-2026`.

## Hors champ (règle 10 : l'écrit prime sur la maquette)
- Pokémon en **pixel art** des maquettes : la DA est « peints simplifiés » ; adversaire = artwork officiel, dos du joueur = sprite provisoire actuel jusqu'au premier lot de dos.
- Place des cartes de PV de la maquette (remplacée par le cadrage du pilote, décision du 2026-10-07).
- Objets absents des données (Super Ball, Hyper Ball, Super Potion, Rappel du storyboard de capture).
- Toute mécanique nouvelle : on change la présentation, pas les règles du combat.

## Découpage (règle 1 : une seule validation S24 à la fin)
| | Contenu | Agent | Fichiers |
|---|---|---|---|
| **CB.1 — cadrage et artwork adverse** | Composition du pilote dans `BattleStage` (caméra resserrée sur le vrai lieu, adversaire en haut à droite au second plan, ton Pokémon de dos au premier plan en bas à gauche, échelle Salamèche ≈ 60 % du premier essai, normalisée par taille) ; **adversaire = artwork officiel** (`assets/sprites/pokemon/official/`, chargement partagé comme `PokedexArt`) avec ombre au sol et étalonnage dans la lumière du lieu ; entrées, coups, K.O., capture (Ball, absorption) recalées sur ces positions. | constructeur-monde (Opus) | `game/battle/battle_stage.*`, `battle_layout.gd`, shaders de `game/battle/`, nouveaux fichiers d'art de combat, outils de capture du stage |
| **CB.2 — interface** | Cartes de PV sur l'autre diagonale (adverse en haut à gauche ; la tienne en bas à droite au-dessus des commandes, pastilles d'équipe au-dessus d'elle) ; grille d'actions en **boutons colorés** avec icônes (ATTAQUER rouge + lueur, SAC or, ÉQUIPE bleu, FUITE gris) ; cartes de capacités (icône et pastille du type, PP, « Puissance N » / « Statut », teinte du type, sélection bordure jaune + ▶) ; panneau Sac de combat et carte « … CAPTURÉ ! / Nouvelle entrée Pokédex » comme le storyboard ; retour rond « ‹ ». | ui-mobile | `game/ui/battle/*`, section combat de `ui_tokens.gd`, `assets/ui/icons/battle/`, `game/battle/battle_views.gd` (si une vue manque) |

Contrat entre les deux : CB.1 ne touche pas à `game/ui/` ; CB.2 ne touche pas au stage. Les zones occupées par les Pokémon (CB.1) et par l'interface (CB.2) sont sur des diagonales opposées : CB.1 laisse libres le haut gauche et le bas droit, CB.2 n'occupe rien au-dessus de la moitié de la hauteur à droite.

## Règles techniques
- Logique du combat, `BattleDirector`, événements et tests de logique **inchangés** ; tout nouveau contenu passe par une vue testée.
- Images chargées à la demande et partagées ; appels de dessin et mémoire mesurés (Mac) et notés.
- Textes nouveaux : repris de la maquette s'ils ne contredisent rien, marqués pour la relecture groupée de Kevin.
- Chaque tâche sur sa branche (`cb1-cadrage`, `cb2-interface`) depuis `combat-maquettes`, fusionnée dans `combat-maquettes` ; captures 2340 × 1080 relues avant la fin ; une seule session S24 pour CB.1 + CB.2.
