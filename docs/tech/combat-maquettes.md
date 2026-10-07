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

## Fait au CB.2 (2026-10-07, branche `cb2-interface`, ui-mobile)

**Changements** (`game/ui/battle/*`, présentation seulement ; logique, événements et `BattleDirector` inchangés hors un branchement) :
- **Cartes sur la diagonale opposée** (`BattleHudLayout`) : adversaire en **haut à gauche**, carte du joueur en **bas à droite** juste au-dessus de la grille d'actions / du bandeau des capacités / du message, les 6 pastilles au-dessus d'elle, alignées à gauche de la carte. Entrées par le bord proche (adversaire depuis la gauche, joueur et pastilles depuis la droite). « ‹ » reste en bas à gauche. Contenu des cartes inchangé (déjà comme la maquette : NOM ♂/♀, Nv. N, barre PV ; adversaire sans chiffres, joueur « 24 / 24 »).
- **Actions** : déjà des boutons colorés avec icône (ATTAQUER rouge + lueur qui pulse, SAC or, ÉQUIPE bleu, FUITE gris) ; seule la hauteur passe de 136 à 128 pour tenir la pile.
- **Capacités** : cartes déjà conformes à `combat-capacites-v1` (icône, NOM, PP, pastille, « Puissance N » / « Statut », teinte du type, bordure jaune + ▶, « ‹ » rond). Ajout des **icônes de types manquantes** (Électrik, Vol, Combat, Psy, Insecte, Sol, Roche, Spectre, Glace : `assets/ui/icons/types/`, `TypeBadge.ICONS`) ; Dragon, Ténèbres, Acier, Fée gardent l'icône neutre. Cartes à 128 de haut (avant 136).
- **Sac de combat** : objets en **rangées** (`BattleBagRow` : ▶, icône, nom, « × 12 », rangée choisie = bordure jaune) au lieu de tuiles, panneau plus étroit (`BATTLE_BAG_WIDTH` 760, l'ÉQUIPE garde 1020). L'aperçu en bas ne garde que la description et LANCER. Onglets CAPTURE / SOINS et geste « choisir puis LANCER » conservés. Aucun objet ajouté (Super Ball, etc. absents des données : pas montrés).
- **Carte de capture** : vignette = **artwork officiel** (`PokedexArt.portrait`, filtre linéaire) au lieu du sprite provisoire (seul branchement dans `battle_director.gd`) ; « Nouvelle entrée Pokédex » seulement si c'est vrai (inchangé : nouvelle espèce ET Pokédex activé) ; ▼ déjà là.
- Tokens (section combat de `ui_tokens.gd`, lignes modifiées sur place, ajouts groupés `BATTLE_BAG_*`) : `BATTLE_OWN_CARD_BOTTOM` 358, `BATTLE_GRID_BOTTOM` 56, `PARTY_PIPS_GAP` 8, `BATTLE_ACTION_SIZE.y` 128, `MOVE_CARD_SIZE.y` 128, `MOVE_GAP_V` 16, `MOVE_BAND_PAD` 20, `BAG_GRID_MAX_HEIGHT` 400.

**Valeurs par défaut (règle 4)** : pile à droite = actions 56 px du bas, carte joueur à 358 px du bas (le plus haut du bandeau des capacités = 348), pastilles 8 px au-dessus. Les pastilles (décor non interactif) dépassent de ≈ 10 px la mi-hauteur à droite (le reste de l'interface est sous la mi-hauteur). ÉQUIPE et Sac gardent leur colonne gauche (ils recouvrent le quart bas gauche tant qu'ils sont ouverts, comme le storyboard) ; le panneau d'oubli de capacité (bas droite) recouvre la carte du joueur.

**Écarts avec les maquettes** : cartes de PV sur l'autre diagonale (décision de Kevin) ; pas de Super Ball / Hyper Ball / Super Potion / Rappel (absents des données) ; Sac avec onglets et bouton LANCER (le storyboard montre une liste unique sans bouton : on garde les deux gestes validés au jalon 5D) ; pas de liste unique avec séparateur Balls / soins (une catégorie à la fois) ; boutons sans dégradé ni relief de la maquette (aplats du thème) ; vignette de capture dans un cadre carré à coins arrondis, artwork non rogné ; pas de pixel art.

**Textes** : aucun texte nouveau (libellés existants ; « × 12 » avec espace comme le storyboard). À relire malgré tout : rien à ajouter.

**Tests** : `tests/unit/test_battle_hud_layout_cb2.gd` (nouveau : diagonale, pile au-dessus des commandes, contrat avec le cadrage, largeur du Sac, icônes de types) ; adaptés : `test_battle_cards` (positions), `test_battle_hud` (sens des entrées), `test_battle_message` (bandeau sous la carte joueur), `test_move_forget_panel` (carte joueur recouverte), `test_battle_bag_panel` (rangées, « × 12 », clavier vertical, +1 test), `test_capture_card` (artwork officiel). **2976 tests verts** (`tools/test.sh`), import sans erreur.

**Captures** (`tools/capture_combat_cb2.sh`, `--1920` pour 1920 × 1080) : `build/captures/combat_cb2/cb2_*.png` (actions, moves, moves_pp0, message, cards_low, bag, bag_heal, party, capture_new, capture_known) en 2340 × 1080 et `_1920`, planches `cmp_*` (maquette | jeu : actions, moves, bag, capture_new). La carte de capture, montrée après les autres panneaux dans la même session de l'outil, reste figée à moitié ouverte (artefact d'outil non élucidé, nœuds opaques à l'inspection) : l'outil la prend dans une seconde passe ; à surveiller sur S24 (capture après usage du Sac). Les Pokémon des captures sont des artworks de face placés pour juger la diagonale (le cadrage réel est CB.1).

**Mesures Mac (2340 × 1080, Route 1 comprise)** : 236–300 appels de dessin (capacités 300, ÉQUIPE 276, actions 273, Sac 258, capture 237), textures 90–92 Mo ; aucune image ajoutée hors 9 icônes SVG de types.

**À valider au doigt sur S24** : carte du joueur et pastilles en bas à droite (pouce droit, lisibilité au-dessus des commandes), pile actions / capacités sous la carte, rangées du Sac (toucher, défilement), vignette de capture, entrée des cartes par les bords.

**Questions pour Kevin** : (1) Sac : garder onglets + LANCER (défaut) ou liste unique sans bouton comme le storyboard ? (2) icônes des quatre types restants (Dragon, Ténèbres, Acier, Fée) à faire avec leurs premiers Pokémon ? (3) carte du joueur en bas à droite : gaucher = inverser les diagonales ? (le HUD de combat n'a pas de réglage gaucher aujourd'hui).
