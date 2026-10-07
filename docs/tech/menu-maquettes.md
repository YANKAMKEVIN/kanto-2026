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


## Validation MM.1 (Kevin, S24, 2026-10-07)
Tableau de bord, Équipe et Sac **validés** (« c'est top »). Questions laissées ouvertes, défauts gardés : argent seulement dans le Sac (règle des dossiers 08 et 09) ; badge obtenu = drapeau d'histoire (date / équipe victorieuse à décider au J10) ; illustration « Carte » gardée. À reprendre au MM.2 : le titre de zone de l'exploration transparaît flou derrière le × du tableau de bord ; le Pokédex passe au « ‹ » seul.

## Fait au MM.2 (2026-10-07, branche `menu-maquettes`)
Carte et Dresseur rapprochés des maquettes **sans changer la logique** (`MapJournal`, `TrainerSummary`, `MenuDirector`, routes et règles de déblocage inchangés). Ajouts de vue seulement (champs facultatifs, testés) : `ZoneEntryView.dex_number` et `MomentView.dex_number` (artworks), `TrainerView.team` (équipe actuelle, `DashboardViews.member`) et `TrainerView.zone_id` (décor du portrait), paramètre facultatif `badges: BadgeLibrary` de `TrainerSummary.build` (le directeur passe sa bibliothèque, chargée à la première demande).

**Art** : `tools/build_zone_previews.gd` (captures des cartes peintes, même méthode que les décors du Pokédex, flou léger) → `assets/ui/map/zones/{pallet_town,route_1,viridian_city,route_22}.webp` (768 × 432) ; `MenuArt.zone_preview()` ; une zone sans aperçu (pas encore de carte peinte) reçoit un **recadrage 16:9 de l'illustration de Kanto** autour de son rectangle (`MenuArt.zone_crop`). `ZoneArt` + `menu_zone_art.gdshader` (couverture, coins arrondis, dégradé, un tracé). Icônes vectorielles `assets/ui/icons/map/{town,route,place}.svg` et `trainer/badge_slot.svg` (silhouette commune). Mipmaps activées sur `kanto_placeholder.webp` (fond flou du cadre).

**Carte** : « ‹ » rond à la place du × (owns_back), Poké Ball, « Carte » et « Kanto » ; bandeau d'état (lieu) ; verre sur fond clair. Illustration entière (rapport gardé) ; quand l'écran est plus large qu'elle (2340), le cadre est prolongé par l'illustration très floue et assombrie (`map_echo.gdshader`, mipmap lointaine). Étiquettes des **seules zones connues** en pastilles avec l'icône du genre (ville, route, lieu) ; **lieu courant en ACCENT**, zone du panneau cerclée d'ACCENT (et son halo) ; portrait du joueur = tête du buste peint dans un rond. Panneau : grande image de la zone (aperçu peint ou recadrage), nom et connexions écrits dessus, « Tu es ici » sur le lieu courant, description, cartes de section « Pokémon observés » (artworks dans un rond, toucher → Pokédex) et « Objets trouvés » (icônes peintes, « ×2 »), Services ; défilement si besoin. Bas : carte « Exploration de Kanto · N zones découvertes » et frise des zones découvertes (vignettes peintes, épingle sur le lieu courant, liseré ACCENT sur la zone du panneau ; toucher = même intention que sur la carte).

**Dresseur** (paysage) : à gauche, le grand buste peint sur le décor flouté de la zone du joueur, nom, « Dresseur Pokémon », début de l'aventure, argent, liens « vus » / « capturés » ; au centre les **8 emplacements de badges** (`BadgeLibrary.slots` : silhouette commune et « ??? » ; obtenu = drapeau levé → emblème ACCENT et « Roche ») et « Équipe actuelle » (grands artworks officiels, nom, sexe, Nv., PV) ; à droite Statistiques et Grands moments (vignette du lieu, artwork du Pokémon posé dessus, titre, détail, lieu · date). « ‹ » à la place du ×.

**Reprises du MM.1** : le titre de zone ne transparaît plus derrière le × (Boot le retirait déjà à l'ouverture ; le flou venait de `tools/capture_menu.gd`, qui ouvrait le menu sans passer par Boot : il cache maintenant titre, légende et contrôles comme Boot ; Boot retire aussi la **légende du monde**, qui pouvait transparaître). Le Pokédex passe au « ‹ » seul (owns_back, plus de réserve pour le ×).

**Tests** : `tests/integration/test_menu_mm2.gd` (17 : « ‹ » à la place du ×, aucune zone non découverte nommée ni « ??? » ni total ni « Se rendre ici », lieu courant / zone du panneau, portrait peint, compteur singulier/pluriel, vignette → une intention, aperçu ou recadrage, « Tu es ici », artworks et icônes peintes, cibles ≥ 128 dans la marge à 1920 et 2340, écho ; Dresseur : buste et décor, badges via `BadgeLibrary` en silhouette puis obtenu, équipe en artworks, pas d'équipe = section absente, frise illustrée, aucun élément hors champ) ; `tests/unit/test_menu_art_zones.gd` (3) ; `test_map_journal.gd` (+1), `test_trainer_summary.gd` (+4), `test_menu_open.gd` (+1 : titre de zone et légende retirés à l'ouverture) ; mis à jour : `test_trainer_screen.gd` (silhouette « ??? » au lieu d'emplacements muets, décision du plan), `test_pokedex_screen.gd` (‹ à la place du ×).

**Perf (Mac, `tools/capture_menu.gd`, PERF)** : 2340 × 1080 — Carte 237 appels / 93,0 Mo (panneau Route 1 avec Pokémon : 262 / 104,2 Mo, l'atlas des vignettes du Pokédex y entre) ; Dresseur 315–319 / 108,4 Mo ; tableau de bord 295 / 112,4 ; Pokédex 399 / 114,9 (mémoire cumulée dans la session de capture). Avant MM.2 : Carte 252 / 87,7, Dresseur 295 / 88,1 (même méthode). Coût ajouté : 4 aperçus × ≈ 1,3 Mo, mipmaps de l'illustration (+≈ 2 Mo), grands artworks de l'équipe (un par Pokémon, chargés à l'affichage). 1920 × 1080 : ≈ 25 appels de moins.

**Captures** : `build/captures/menu_mm2/` (dossier principal) : `*_2340x1080.png`, `*_1920x1080.png` (map, map_panel, map_dex, trainer, trainer_dex, trainer_empty, trainer_badge, dashboard_6, dex_grid) et planches `cmp_map*`, `cmp_trainer*`.

**Valeurs par défaut (règle 4)** : bandeau du bas 168 px, carte « Exploration » 540, vignettes 232 × 136 ; panneau 680 à 860 px ; image de zone 230 px ; cellules Pokémon 144 × 176 (rond 108), objets 144 × 132 (icône 76) ; écho : mipmap 5, voile 0,6 ; étiquettes avec icône 28 ; portrait sur la carte 80 px ; Dresseur : identité 540, colonne de droite 640, buste au plus 560, badges 112 px de haut, équipe en 3 colonnes ; aperçus de zones 768 × 432, flou léger ; cadrages des captures (centres et zoom dans l'outil) ; le préfixe « Badge » est omis dans l'emplacement (« Roche »).

**Écarts restants avec les maquettes (et pourquoi)** :
- **Carte** : géographie et noms du vrai Kanto (dossier 08 §5), seules les zones découvertes sont nommées ; pas d'onglet Îles Sevii, pas de « Se rendre ici », pas d'heure ni d'argent ni « 27/151 » dans le bandeau (règles 2 et 5) ; « Pokémon observés » **sans « 4/6 » ni silhouettes « ??? »** : le dossier 08 §5 et la règle 2 l'interdisent (« pas de ??? qui signale une espèce manquante dans une zone ») — la consigne « ??? en silhouette selon les règles du Pokédex » revient donc à : seulement les espèces vues, en artwork ; « Exploration » **sans total ni barre** (« 8 / 12 zones » interdit par la règle 2 ; une barre suppose un total) ; pas de « › » sur les sections (aucune action prévue) ; illustration encore provisoire (`kanto_placeholder`, phase DA), plus petite que la maquette (l'écran garde l'image entière) ; aperçus des zones = captures floutées du jeu (pas d'illustration avec le héros).
- **Dresseur** : pas de menu Aperçu / Badges / Statistiques / Carnet / Titres / Apparence, ni niveau / XP de Dresseur, biographie, « Histoire principale 12 % », tenue, Pikachu (dossier 08 §6, hors champ) ; badges : silhouette **commune** (la maquette montre la forme de chaque badge, ce que le dossier interdit : « ni son nom ni son apparence ») et pas de « 1 / 8 » (Q-13) ; pas de « Voir les badges », « Voir l'équipe », « Voir tout le carnet » (pas d'écran derrière) ; équipe non touchable ; statistiques existantes seulement (pas de Pokédex en barre).
- **Écran Dresseur en début de partie** (pas d'équipe) : le centre n'a que les badges (section équipe absente), espace vide en dessous ; le décor du portrait manque si la carte du joueur n'est rangée dans aucune zone.

**Textes à relire par Kevin** : « Carte » / « Kanto » (en-tête) ; « Exploration de Kanto », « 1 zone découverte » / « N zones découvertes » ; « Tu es ici » ; « Équipe actuelle » ; « ??? » des badges ; « Roche » (nom court du badge).

**Questions** :
- **Q-MM2-1** : badge obtenu, toucher → détail (« Badge Roche — Argenta — Pierre », dossier 08 §6) : prévu au J10 avec l'image du badge (non fait ici, aucun badge avant).
- **Q-MM2-2** : rendre l'équipe du Dresseur touchable (→ fiche Équipe) et la frise de la Carte « Voir sur la carte » (dossier 08 §5) ? défaut : non (pas de lien non prévu par le §8).
- **Q-MM2-3** : aperçus des zones = captures floutées du jeu (aucune image générée) ; faut-il des illustrations dédiées (Codex) en phase DA ?


## Validation MM.2 (Kevin, S24, 2026-10-07)
Carte et Dresseur **validés** (« tout est ok »). Décisions : détail d'un badge obtenu au toucher → **J10** ; équipe de l'écran Dresseur **non touchable** (recommandation suivie) ; vraies illustrations des aperçus de lieux → **phase DA**. Pokédex non vu sur S24 (pas encore activé dans la partie de Kevin : colis non livré) ; « ‹ » seul vérifié sur capture Mac. Prochain : MM.3 (Paramètres).

## Fait au MM.3 (2026-10-07, branche `menu-maquettes`)
Écran Paramètres rapproché de la maquette **sans aucun réglage nouveau** : mêmes catégories, mêmes réglages, même contrat (`SettingsViews`, `GameSettings`, `MenuDirector`, `setting_changed(clé, valeur du réglage)`, `save_now_requested`, l'écran n'invente pas l'état). Seul ajout de vue : `SettingsCategoryView.subtitle` (sous-titre de section, repris de la maquette, testé).

**Présentation** (`SettingsScreen`, thème `Settings*` régénéré) : « ‹ » rond à la place du × (`owns_back`), engrenage et « Paramètres », bandeau d'état de l'hôte (lieu) ; fond clair et verre comme MM.1/MM.2. À gauche, catégories de verre avec icône, en casse de phrase (« Jeu », « Commandes », « Accessibilité », « Graphismes » ; conversion à l'affichage, la vue garde ses titres), la choisie en ACCENT avec un halo ; le panneau est haut comme sa liste. À droite, **la catégorie ouverte = une section de verre** : icône, titre, sous-titre ; lignes dans une carte intérieure, séparées par un filet (pas sous la dernière). La section est **haute comme ses lignes** (Graphismes : une ligne, le monde reste visible dessous) et défile seulement si elles dépassent (texte Grande, petit écran). Le résultat de la sauvegarde s'affiche sous la carte.
- **Choix** → sélecteur « ‹ Valeur › » (pilule de verre, valeur écrite au milieu, flèches de 128 px touchables) : une flèche = la valeur de l'option voisine ; aux bouts, la flèche est éteinte (hors des cibles touchables) et ne fait rien — pas de retour au début, la position se lit. « Auto (Élevée) » reste écrit.
- **Interrupteurs** : toute la ligne se touche, interrupteur vert, état écrit à côté en discret (« Activé » / « Désactivé », règle 7).
- **Curseur** : piste ACCENT, pastille blanche, pourcentage à droite (inchangé).
- **Sauvegarder maintenant** : toute la ligne se touche (comme un interrupteur), icône dans un rond ACCENT à droite ; inactive = ligne grisée avec sa raison.

**Tests** : `tests/integration/test_menu_mm3.gd` (10 : « ‹ » à la place du ×, bandeau, verre ; catégories avec icône en casse de phrase ; section = icône, titre, sous-titre de la catégorie ouverte ; **chaque réglage existant présent avec son contrôle et rien de plus** ; **chaque réglage fonctionne depuis l'écran** (interrupteurs, sélecteurs, curseur, sauvegarde) ; filets sauf la dernière ligne ; aucun texte hors champ ; cibles ≥ 128 dans la marge à 1920 et 2340, tout visible sans défiler à 1080 ; texte Grande : le sélecteur tient dans sa ligne ; section courte / longue) ; `test_settings_views.gd` (+1 : sous-titres). Mis à jour (présentation) : `test_settings_screen.gd` (flèches au lieu des options côte à côte, titres en casse de phrase, nouveau test « flèche au bout », « sélecteur dans une pilule » ; les tests « toucher ou défilement » prennent un écran de 800 px de haut, car COMMANDES tient maintenant dans 1080), `test_menu_settings.gd` (flèches). `tools/capture_settings_t29.gd` suit le sélecteur ; `tools/capture_menu.gd` pose le lieu et rouvre JEU par défaut.

**Perf (Mac, 2340 × 1080, `tools/capture_menu.gd`)** : Paramètres 224–254 appels de dessin / 88,5 Mo (texte Grande et contraste : ≈ 325, mémoire cumulée de la session de capture) ; 1920 : ≈ 25 appels de moins. Pas d'image ajoutée.

**Captures** : `build/captures/menu_mm3/` (dossier principal) : `*_2340x1080.png`, `*_1920x1080.png` (settings, settings_controls, settings_access, settings_graphics, settings_save, settings_no_save, left_handed, text_large_settings, contrast_settings) et planches jeu / maquette `cmp_*` (maquette en portrait, proportions gardées).

**Valeurs par défaut (règle 4)** : catégories 420 px, icône 44, police 32, halo ACCENT 0,4 / 14 px ; lignes de 128 px (au lieu de 144 : la maquette est plus serrée, la cible reste 128), filet blanc 9 % de 2 px, appui teinté d'ACCENT 16 % ; titre de section 44, sous-titre 24, icône 64 ; libellé 30, état d'un interrupteur 24 en TEXT_MUTED ; pilule 76 px dessinés, valeur 250 px, flèches 30 px dessinées (128 touchables), flèche éteinte à 22 % ; rond de l'action 88 px ACCENT ; pas de retour au début dans un sélecteur.

**Écarts restants avec la maquette (et pourquoi)** :
- **Contenu** : ni difficulté, animations de combat, conseils, interface adaptative, configuration des boutons, caméra, axe Y, HDR, fréquence d'images, luminosité, Audio, Langue, Compte, Divers, Cloud, sauvegarde automatique désactivable, restaurer / supprimer, mode daltonien, aide à la navigation (dossier 08 §7 « exclus », Q-17 pour l'Audio) ; pas d'« Aperçu graphique » illustré ni de cartes Qualité / Performance (Graphismes garde son sélecteur Auto · Élevée · Économie ; une illustration du MM.0 n'aurait rien montré de vrai).
- **Composition** : la maquette est en portrait et empile toutes les sections ; en paysage, **une catégorie ouverte à la fois** (contrat de l'écran inchangé, rien à faire défiler à 1080). Lignes plus hautes que la maquette (cible tactile 128).
- **Bandeau d'état** : lieu seulement (ni heure ni argent ni « 27/151 », règles des dossiers 08 et 09, heure cachée tant que le jour/nuit n'existe pas).
- **Interrupteurs** : l'état reste écrit (« Activé ») à côté, que la maquette n'a pas (règle 7 : jamais la couleur seule).
- **Sauvegarder maintenant** : rond ACCENT avec l'icône de sauvegarde au lieu d'un « › » (c'est une action immédiate, pas une page).
- Icônes des catégories : celles du J6 (manette, cible, silhouette, écran), pas d'engrenage pour « Jeu ».

**Textes à relire par Kevin** : sous-titres des sections (« Paramètres principaux du jeu. », « Personnalise tes contrôles. », « Rends le jeu accessible à tous. », « Ajuste la qualité visuelle du jeu. », repris de la maquette) ; noms des catégories en casse de phrase (« Jeu »… au lieu de « JEU »).

**Remarque (hors MM.3, déjà sur `main`)** : la capture `left_handed` de `tools/capture_menu.gd` sort assombrie (même résultat sur `main`) ; le HUD n'a pas changé ici. À regarder avec l'outil de capture, pas avec le jeu.

**Questions** :
- **Q-MM3-1** : sélecteur « ‹ Valeur › » (maquette) au lieu des options côte à côte du J6 : on voit moins vite toutes les options (Vitesse du texte en a quatre). Garder le sélecteur partout, ou revenir aux options côte à côte pour Vitesse du texte ?
- **Q-MM3-2** : aux bouts d'un sélecteur, flèche éteinte (défaut) ou retour au début ?


## Validation MM.3 (Kevin, S24, 2026-10-07) — chantier du menu terminé
Paramètres **validés**. Décisions : sélecteur « ‹ Valeur › » gardé partout, Vitesse du texte comprise (Q-MM3-1) ; flèche éteinte au bout d'un sélecteur (Q-MM3-2, défaut). Les cinq écrans du Menu Dresseur et le Pokédex sont rapprochés de leurs maquettes. Restent pour plus tard : détail d'un badge au toucher (J10), illustrations dédiées des aperçus de lieux et de la carte de Kanto (phase DA), textes à relire (MM.1 à MM.3).
