# Menu Dresseur : rapprochement des maquettes

> Plan préparé par Claude le 2026-10-07, **décisions de Kevin le même jour** : ordre tableau de bord → Équipe → Sac (MM.1), puis Carte et Dresseur (MM.2), Paramètres en dernier (MM.3) ; images = artworks officiels pour les Pokémon, portrait peint du héros et illustrations / icônes d'objets par Codex ; l'heure et les badges sont **préparés dès maintenant** (sans attendre la phase 10 ni le J10) ; chantier en parallèle du J8 (qui ne touche pas au menu). Références : `docs/design/reference/menu-*-v1.jpg`, `docs/design/dossier-08-menu-dresseur.md`, `docs/design/ui-ux-bible-v0.1.md`, skill `ui-theme-2026`. Captures du point de départ : `build/captures/menu_actuel/cmp_*.png`.

## Constat (jeu actuel vs maquettes)
La structure des écrans est déjà la bonne (J6, Pokédex refait en octobre). L'écart est visuel :
1. **Images absentes** : cartes du tableau de bord en aplat + icône (maquette : une illustration par carte) ; héros et Pokémon en pixel art (Équipe, Dresseur, carte du Pokémon de tête) ; objets du Sac en icônes génériques.
2. **Fond** : monde assombri derrière des panneaux de verre plus légers dans la maquette ; panneaux opaques et grands dans le jeu.
3. **En-tête** : bandeau d'état en haut à droite (lieu · heure · argent) et retour « < » compact dans la maquette ; × et « RETOUR » encombrants dans le jeu.
4. **Sac** : « Utiliser sur… » avec l'équipe directement dans le panneau de droite (maquette) au lieu d'une étape séparée.
5. **Carte** : étiquettes des lieux, aperçu illustré du lieu, Pokémon observés, frise des zones (maquette).

## Hors champ (règle 10 : l'écrit prime sur la maquette)
« Titres » et « Apparence » du Dresseur ; statistiques de base et talents ; difficulté, Cloud, HDR dans les Paramètres ; « Se rendre ici » sur la Carte ; Pikachu à côté du héros ; noms de Dresseurs ou d'objets non prévus par les dossiers.

## Préparés dès maintenant (décision de Kevin)
- **L'heure** : la puce « heure » du bandeau d'état existe et lit une **horloge du jeu** (`WorldClock`, logique pure, testable) ; tant que le cycle jour/nuit n'existe pas (phase 10), l'horloge n'est pas active et la puce reste **cachée** (aucune heure inventée). La phase 10 n'aura qu'à brancher l'horloge.
- **Les badges** : les 8 badges de Kanto décrits en **données** (`data/badges.json` : identifiant, nom, Champion, ville, ordre ; textes à valider par Kevin) et une vue « badges obtenus » lue depuis l'état de partie (aucun badge obtenu pour l'instant ; pas de nouveau champ de sauvegarde avant le J10 si la vue peut s'en passer, sinon un champ vide rétrocompatible, à décider par l'architecte avec un test de chargement). L'écran Dresseur et la carte du Dresseur affichent les emplacements en silhouette « ??? » (règle de déblocage). Le J10 n'aura qu'à attribuer le badge.

## Découpage (règle 1 : une validation S24 par sous-étape)
| | Contenu | Visible sur S24 |
|---|---|---|
| **MM.0 — art** | Codex : portrait peint du héros en buste (cartes du Dresseur), 6 illustrations du tableau de bord (Équipe : les trois starters ; Pokédex ; Sac ; Carte de Kanto ; carte de Dresseur ; engrenage), icônes peintes des objets existants (`data/items/items.json`). Pokémon : artworks officiels déjà utilisés par le Pokédex (`PokedexArt`). | rien |
| **MM.1 — tableau de bord, Équipe, Sac** | bandeau d'état (lieu · heure préparée · argent), retour « < », fond assombri et panneaux de verre (tokens de `ui-theme-2026`), illustrations des cartes, portrait peint du héros, artworks officiels (Pokémon de tête, liste et grand portrait de l'Équipe, choix de la cible dans le Sac), icônes d'objets ; Sac : « Utiliser sur… » dans le panneau de droite. | les trois écrans |
| **MM.2 — Carte et Dresseur** | Carte : étiquettes des lieux connus, aperçu du lieu (image floutée de sa carte peinte, comme le Pokédex), Pokémon observés, objets trouvés, frise des zones découvertes ; Dresseur : grand portrait peint, emplacements de badges (préparés), progression, équipe en artworks, grands moments. | les deux écrans |
| **MM.3 — Paramètres** | mise en page en colonnes de la maquette, sans réglage nouveau. | l'écran |

## Règles techniques
- Logique et vues existantes **inchangées** (`MenuDirector`, `*Views`, routes, tests) : on change la présentation ; tout nouveau contenu passe par une vue testée.
- Images chargées à la demande et partagées (comme `PokedexArt`) ; budget du menu à mesurer sur S24 (le flou du fond coûte déjà : J6 « Reportés »).
- Textes nouveaux (sous-titres des cartes, bandeau) : repris de la maquette quand ils ne contredisent rien, marqués pour la relecture groupée de Kevin.
- Branche `menu-maquettes` depuis `main`, dossier de travail dédié ; fusion dans `main` après chaque validation.

## Fait au MM.1 (2026-10-07, branche `menu-maquettes`)
Tableau de bord, Équipe et Sac rapprochés des maquettes **sans changer la logique** (`MenuDirector`, `*Views`, routes, règles et tests de logique inchangés ; seuls ajouts : `TeamMemberView.dex_number`, `DashboardViews.badges_text()` et un paramètre facultatif `badges` de `DashboardViews.build`, chargé paresseusement par le directeur).

**Art (MM.0 → assets)** : `tools/art/preparer_menu.py` (étape dédiée, noms stables) écrit `assets/ui/menu/cards/{team,pokedex,bag,map,trainer,settings}.webp` (640 × 427, opaques), `assets/ui/menu/hero_bust.webp` (recadré sur la silhouette, 720 px de haut) et `assets/ui/items/{poke_ball,potion,antidote,oak_parcel}.webp` (256², découpe de la planche par colonnes vides). Seul lien chemin ↔ image : `game/ui/menu/menu_art.gd` (`MenuArt`, chargement à la demande, cache partagé ; Pokémon délégués à `PokedexArt`). Icônes peintes aussi dans le Sac du combat (`BagEntryView.icon_for` les préfère au SVG).

**Commun** : en-tête de `TrainerMenu` = × rond compact (88 px dessinés, 128 touchables) et **bandeau d'état** en haut à droite (lieu · heure · argent, puces séparées). Écrans Équipe et Sac : `MenuScreen.owns_back` → l'hôte cache le × et l'écran pose son « ‹ » rond à sa place, avec icône, titre et compteur (« Équipe 3/6 », « Sac », « Pour Salamèche ») ; le retour Android garde son chemin. Fond du menu plus clair (voile 0,3, flou du Pokédex) et panneaux de verre (`MenuGlass`, `MenuGlassCard`, jetons `MENU_GLASS_*` = ceux du Pokédex) ; nouvelles variations de thème `Menu*` (le combat et le Stockage gardent les leurs).

**Heure préparée** : `game/systems/day_night/world_clock.gd` (`WorldClock`, pur, testé) ; `TrainerMenu.set_clock()` / `get_clock()` ; inactive → puce cachée, aucune heure inventée. La phase 10 n'a qu'à passer son horloge et l'activer (`start`, `advance`).

**Badges préparés** : `data/badges.json` (8 badges : id, ordre, nom, Champion, ville, drapeau) + `BadgeLibrary` (validation, `obtained_count`, `slots()` = vue des 8 emplacements, muets tant que non obtenus). **Un badge est obtenu quand son drapeau d'histoire est levé** (`badge_boulder`…) : aucun champ de sauvegarde, `game/systems/save/` non touché. Ligne « N badges » de la carte du Dresseur seulement à partir d'un badge (Q-13). Emplacements en silhouette : MM.2 (écran Dresseur).

**Tableau de bord** : cartes illustrées (`menu_card_art.gdshader` : couverture rognée autour du haut, coins arrondis, dégradé vers la teinte de la carte ; un tracé), icône, titre, barre, légende, pastille ronde « › » teintée ; liseré ACCENT à l'appui. Portrait peint du héros dans la carte du Dresseur (ancré en bas à droite, chevauché par le Pokémon de tête) ; Pokémon de tête en artwork dans un rond.

**Équipe** : liste en verre avec artworks ronds et « › » ; grand artwork au centre (au plus 540 px, halo, ombre, respiration douce) ; onglets à icône, sections et actions en verre (icône à gauche). Même vedette en artwork dans le Stockage (192 px).

**Sac** : catégories avec icône (peinte pour Soins et Capture), titre en casse de phrase, légende et compteur rond ; cartes de verre avec icônes peintes ; panneau de droite = objet en grand sur un halo, nom, quantité, description ; **après UTILISER, « Utiliser sur… » et l'équipe (artworks, PV, raison) s'affichent dans ce panneau** (PartyPicker compact), la grille reste visible ; ANNULER sur la rangée du titre. Contrat inchangé : UTILISER → `use_requested` → `show_targets`, un toucher sur une cible = l'usage (pas de bouton « Utiliser » de confirmation, pas de « Sélection rapide »).

**Tests** : `tests/unit/test_world_clock.gd` (3), `test_badge_library.gd` (4), `test_dashboard_views.gd` (+3), `tests/integration/test_menu_mm1.gd` (6 : images des cartes, portrait, Pokémon de tête, ligne des badges, puce heure cachée/activée, argent seulement dans le Sac, « ‹ » à la place du ×, icônes peintes, « Utiliser sur… » dans le panneau, cibles ≥ 128 px dans la marge) ; présentation mise à jour : `test_team_screen.gd` (artwork au lieu du pixel art ×6), `test_battle_bag_panel.gd` (icône peinte).

**Perf (Mac, 2340 × 1080, `tools/capture_menu.gd` affiche `PERF`)** : exploration 210 appels de dessin / 85,4 Mo de textures ; tableau de bord 307 / 105,7 Mo ; Équipe 333 / 107,6 ; Sac 282 / 108,4 ; Sac + choix 312 / 108,4 ; Pokédex 413 / 111,0. Le menu ajoute ≈ 100 appels et ≈ 20 Mo à la première ouverture, dont **l'atlas des vignettes du Pokédex (10,9 Mo)**, chargé désormais dès le Pokémon de tête au lieu de la première visite du Pokédex, puis gardé (comme avant) ; illustrations 6 × 1,1 Mo, buste 1,4 Mo.

**Captures** : `build/captures/menu_mm1/` (dossier principal) : `*_2340x1080.png`, `*_1920x1080.png` (dashboard_6, dashboard_5, dashboard_no_team, team, team_sheet_moves, team_history, team_move_mode, bag, bag_use, bag_result, bag_from_team, storage, dex_grid) et planches jeu / maquette `cmp_*`.

**Valeurs par défaut (règle 4)** : × et ‹ dessinés à 88 px ; bandeau 80 px de haut, texte 30 ; voile du fond 0,3 ; cartes : rayon 24, dégradé dès 38 % de la hauteur, point gardé à 20 % du haut ; buste au plus 640 px ; artwork de l'Équipe au plus 540 ; ronds d'Évolution 88 px ; liste de l'Équipe 520 px, fiche 760 ; colonne des catégories du Sac 460 ; icône de l'objet 180 ; la description de l'objet se replie pendant « Utiliser sur… » (place des trois Pokémon) ; fond sélectionné des cartes de verre sombre + liseré ACCENT (pas de jaune plein).

**Écarts restants avec les maquettes (et pourquoi)** :
- **Argent** : la maquette et le plan le mettent dans le bandeau partout ; **affiché seulement dans le Sac** (dossier 09 §10 et dossier 08 règle 5 / Q-4 : « jamais au tableau de bord », imposé par `test_menu_unlock_rule`). → question Q-MM1-1.
- **Heure** : puce cachée (pas de cycle jour/nuit, décision de Kevin).
- **Équipe** : emplacements vides neutres, sans « Ajouter un Pokémon » (dossier 08 §2) ; Évolution sans silhouette des stades inconnus (Q-9 du J6 pour l'Équipe ; le Pokédex a la silhouette, Q-1) ; ni taille, poids, description (Pokédex) ; pas de crayon de surnom ; libellés des boutons en majuscules (textes validés).
- **Sac** : pas de « Sélection rapide » ni de bouton « Utiliser » de confirmation (contrat du Sac : un toucher sur le Pokémon = l'usage, pas de confirmations en cascade) ; pas de décor peint derrière l'objet (halo, comme le Pokédex avant son décor) ; pas de cases vides décoratives dans la grille ; Favoris restent un onglet en tête (pas en bas).
- **Tableau de bord** : pas de grand panneau englobant les six cartes ; pas de Salamèche à côté du héros (hors champ) ; pas de ligne « argent » dans la carte du Dresseur ; icône des badges = Poké Ball dorée (pas encore d'image de badge).
- **Pokédex** (hors MM.1) : garde son × + son ‹ ; le passer au « ‹ » seul viendra avec MM.2 (même mécanisme `owns_back`).

**Textes à relire par Kevin** : légendes des catégories du Sac (« Tes objets favoris. », « Restaure les PV et soigne les altérations. », « Pour attraper les Pokémon sauvages. », « Objets pour les combats. », « Objets utiles en exploration. », « Objets importants. ») et titres en casse de phrase (« Soins », « Objets clés »…) ; « Utiliser sur… » ; titres d'en-tête « Équipe 3/6 », « Sac » ; noms des 8 badges, Champions et villes (`data/badges.json` : orthographe du projet « Carmin-sur-Mer », « Erika »).

**Questions** :
- **Q-MM1-1** : argent dans le bandeau d'état — seulement le Sac (défaut appliqué, règle écrite) ou partout comme la maquette (changerait dossier 09 §10 et un test de règle) ?
- **Q-MM1-2 (J10)** : un badge obtenu = un drapeau d'histoire `badge_<id>` ; si le J10 préfère un champ de sauvegarde dédié (date d'obtention, équipe victorieuse), le prévoir dans la sauvegarde v4+ (non touchée ici).
- **Q-MM1-3** : l'illustration « Carte » de Codex montre un volcan et une géographie inventée (dossier 08 §10 : géographie de la maquette fausse) ; acceptable comme illustration de carte de menu, ou à refaire ?
