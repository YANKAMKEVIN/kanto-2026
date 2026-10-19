# Série 19 — Route 11, Cave Taupiqueur, Route 2 est et son poste (jalon 17, lumière NE)

> Rédigée au **J17 T11** (2026-10-15, branche `j17-t11-art` depuis `jalon-17`) ; génération au **T12** (Codex, Mac). Plan : `docs/tech/jalon-17.md` §1.4 ; conception : `dossier-20-*.md` (§15 art, « Vues générales »). Intégration au **T14** (manifeste, `preparer.py`, `preparer_menu.py`, `build_character_frames.gd`, décors de combat CB.3). Dos de combat : T13 (Colab), hors de cette série.
>
> **Numéro : 19.** Constaté le 2026-10-15 (`git ls-remote`, `git ls-tree` de toutes les branches `origin/*` et copies locales) : 01, 12 à 17 pris ; 18 réservé au J16 (plan §1.4), aucune trace. « Le second fusionné renumérote » : à revérifier au push (fiche, `tools/art/serie19.py`, `tools/art/prompts/serie19/`, docs).

Outil : `tools/art/serie19.py` (`--prompts`, `--refs`, `--ancres`, `--commandes`, `--planche`, `--contact`, `--manifeste` préparé et **non lancé**, `--controle` au T14, `--r2 ID [rN]` pour une révision écrite à la main). Prompts versionnés : `tools/art/prompts/serie19/`, `tools/art/attente/prompts/`, `tools/art/combat_decors/prompts/`. **Règle de Kevin pour Codex** : AVEC les ancres d'abord (2 essais), puis SANS pièce jointe (2 essais), refus consignés dans `$ART/refus_serie19.log`.

**Écarts des vues à ne pas reproduire** : Ronflex peint ≈ 5 cases (la grille : 2 × 2) ; canyon vu du ciel et absence de rais de lumière (Cave : profil `cave_sand` + `LightGlow`, rien de peint) ; clairières de la Route 2 est plus larges que la grille ; goulet d'Arthur non resserré, Gamin Louis près de la Cave, feuillage granuleux (la grille décide) ; casquettes bleue / rouge / verte des Gamins (un seul modèle).

## Liste du kit

**A. Réutilisés tels quels** : herbe, chemin, hautes herbes jaunes, `ground_roche_01` (`o`), gravats (Cave), mer `ground_eau_01` assombrie (variation, comme Carmin), rivage rocheux `relief_rivage_*` + `prop_rocher_mer_01`, **parois beiges `relief_paroi_01..04`** (talus `K` de la Route 11 et paroi de la Route 2 est : même roche moussue que la vue), `relief_falaise_01`, rochers et grande pierre, forêt (feuillus et épicéas), buissons, clôture de bois `prop_cloture_01` (digue `c`), panneaux, `prop_indice_caillou_01`, `object/poke_ball_ground`, racines ; **poste = `bldg_poste_safrania_01`** (7 × 4, porte au milieu) ; éboulis de la Route 2 nord vus de dos = rochers déjà posés par `build_route_2_north.gd` ; coque `int_maison_argenta_coque` (15 × 10), `int_bureau_chen_01`, `int_chaise_bureau_01`, `int_classeur_01`, `int_bibliotheque_cote_01`, plantes ; personnages : **assistant = `chercheur`**, **visiteur = `naturaliste`** (décision : le scientifique existant convient), **Gamins = `jeune_dresseur`** ; Pokémon : Rattata, Piafabec, Abo.

**B. Variations** : mer du port sombre (Shade) ; parois en miroir ; **affleurements des goulets** = `relief_paroi_04` (massif) + rochers (planche neuve en conditionnel) ; arbuste du goulet de la Route 2 est = **celui du J16** (provisoire : buisson) ; retouche de la Route 2 sud (clairière FUTUR A, trouée de canopée, sentier `b`) = **outil de carte** (T20, grille `route_2_j17_retouches.txt`), seul asset neuf : la barrière ouverte.

**C. Nouveaux : 22 images** (`_r1`) :

| Fiche → asset(s) | Rôle | Taille en jeu | Vague |
|---|---|---|---|
| `WORLD_GROUND_DIGUE_01` → `ground_digue_01` | digue `q` (Route 11) | texture 384 | 1 |
| `WORLD_GROUND_SABLE_GROTTE_01` → `ground_sable_grotte_01` | sol de la Cave `.` | texture 384 | 1 |
| `WORLD_GROUND_MASSE_SABLE_01` → `ground_masse_sable_01` | dessus des masses `#` | texture 384 | 1 |
| `WORLD_RELIEF_BOUCHE_TALUS_01` → `relief_bouche_talus_01` | bouche sud, Route 11 (15..16, 7) | 4 × 3 | 1 |
| `WORLD_RELIEF_BOUCHE_PAROI_01` → `relief_bouche_paroi_01` | bouche nord, Route 2 est (6..7, 3) | 4 × 3 | 1 |
| `WORLD_PROP_BARRIERE_OUVERTE_01` → `prop_barriere_ouverte_01` | FUTUR B ouverte (34, 43..44) | 1 × 2,4 | 1 |
| `WORLD_RELIEF_PAROI_SABLE_PLANCHE` → 6 modules | parois de la Cave (rôles de la planche J12) | 3/3/2/2/1/3 cases | 1 |
| `WORLD_RELIEF_BOUCHES_CAVE_PLANCHE` → 2 modules | bouches de la Cave vues de l'intérieur (79 et 0) | 4 × 1,6 / 4 × 1,8 | 1 |
| `WORLD_RELIEF_DIGUE_PLANCHE` → 2 modules | bord sud de la digue (rangée 24) | 2 × 0,9 | 1 |
| `INT_J17_PLANCHE` → 4 éléments | étagère de lampes et bocaux, carte murale, table de lecture, caisse de lampes | 2 / 2 / 3 / 1 | 2 |
| `PNJ_PARIEUR` + attente → `parieur` (`gambler`) | Joueurs D5, D6 | 128 px | 1, 2 |
| `PNJ_INGENIEUR` + attente → `ingenieur` (`engineer`) | Ingénieurs D7, D8 | 128 px | 1, 2 |
| `POKE_SOPORIFIK` → `soporifik` (`drowzee`) | Route 11, compagnon | 76 px, marche 4 × 4 | 1 |
| `POKE_TAUPIQUEUR_FIXE` → `taupiqueur` (`diglett`) | Cave, `shy = hide` : tête sortie / caché | 44 px, fixe | 1 |
| `POKE_RONFLEX_FIXE` → `ronflex` (`snorlax`) | Route 11 (66..67, 14..15) : endormi / inspire | 168 px, fixe | 1 |
| `UI_OBJETS_J17_PLANCHE` → `hm05.webp` | icône de la CS05 (aucune icône de CT peinte n'existe : modèle = Potion et Pierre Lune) | 256 px | 1 |
| `COMBAT_DECOR_ROUTE11_COTE_r1`, `COMBAT_DECOR_CAVE_TAUPIQUEUR_r1` → `route_11_coast`, `digletts_cave_rock` | décors de combat (CB.3) | 2,17 : 1 | 1 |

**Conditionnels** (prompts prêts, jamais lancés) : `WORLD_BLDG_POSTE_ASSISTANT_01` (si le poste de Safrania à porte bleue et lanternes ne se lit pas comme un poste de recherche), `WORLD_PROP_AFFLEUREMENTS_PLANCHE`.

**D. Abandonnés** : voir « Écarts » ci-dessus ; rais de lumière peints ; Triopikeur et Hypno dans le monde (combat seulement) ; mouettes ; casquettes de couleur.

## Contrôle « chaque élément des vues a un asset »
*Route 11* : mer, étincelles → A (variation) ; rivage, écume, rocher à Poké Ball → A ; digue de pierre → neuve (texture + bords) ; clôture de bois → A ; talus et bouche → parois A + bouche neuve ; affleurements gris → A (paroi_04, rochers) ; prairie, fleurs, chemin, hautes herbes jaunes, bosquets, buissons → A ; panneaux, Poké Ball, caillou → A ; Gamins → `jeune_dresseur` ; Joueurs, Ingénieurs → neufs ; Ronflex, Soporifik → neufs ; Piafabec, Abo → A. *Cave* : sol clair → neuf ; masses brunes → neuve ; parois à colonnes → planche neuve ; gravats, cailloux → A ; Taupiqueur → neuf ; bouches (lumière verte) → planche neuve ; Poké Ball → A ; racines → A. *Route 2 est* : paroi + bouche → A + neuve ; éboulis NO → A ; poste → A (Safrania) ; chemin, forêt, clairières, fleurs, Poké Balls, Piafabec → A ; arbuste → J16 ; barrière → neuve (ouverte, Route 2 sud). *Poste (grille)* : bibliothèque, bureau, classeur, plantes → A ; étagère de lampes, carte, table de lecture, caisse → neufs ; assistant, visiteur → A.

## Alignement (T14, T15, T16, T19)
Bouches : `relief_bouche_*` posées en bas de leur emprise, centrées sur les 2 cases `Q` ; paroi modulaire 4 cases (`relief_paroi_*`) de part et d'autre. Digue : `ground_digue_01` sur `q`, `relief_digue_bord_*` en rangée 24. Cave : `PaintedGround` (sable + masse sable + gravats), parois des cases `#` voisines du sol (logique des parois J12), bouches aux rangées 0 et 79. Ronflex : `FlagGate` sprite ≈ 2 × 2 (réglage de `hauteur` au T14 sur capture). Réglages du manifeste = défauts (règle 4).
