# Série 21 — Route 9, Route 10, Grotte Sombre, Lavanville et Tour Pokémon (jalon 18, lumière NE)

> Rédigée au **J18 T1** (2026-10-15, branche `j18-t1-kit` depuis `jalon-18` à `4f90ac2c`). Plan : `docs/tech/jalon-18.md` §4.1, §4.2, §4.18, T1 ; conception : `docs/design/dossier-21-grotte-sombre-lavanville.md` (verrouillé ; §3–7, §10.4, §13.1). Génération au **T2** (Mac, Codex), validation de Kevin sur planche de contact, intégration au **T6** (manifeste, `preparer.py`, `build_painted_props.gd -- --nouveaux`). Personnages (Pokémaniac, Exorciste `channeler`) et fonds CB.3 (`route_9_roche`, `dark_cave_galerie`) : **déjà validés et intégrés** (`a7b309a5`), hors de cette série.
>
> **Numéro : 21.** Constaté le 2026-10-15 (`git fetch`, `git ls-tree` de `docs/design/fiches-assets` et `tools/art` sur toutes les branches `origin/*`) : 01, 12 à 17 pris ; 18 réservé au J16 (aucune trace) ; **19 = J17** (`origin/jalon-17`, `serie-19-chemins.md`) ; **20 = J19** (`origin/jalon-19`, `serie-20-tour-pokemon.md`). À revérifier au push (fiche, `tools/art/serie21.py`, `tools/art/prompts/serie21/` ; les identifiants d'images ne portent pas le numéro).

**Consigne de Kevin (J8–J17)** : le plus petit kit modulaire qui produit la **sensation** des vues validées dans Godot, sans répétition visible.
- **DA et composition** : `reference/route-9-vue-generale-v1.png`, `route-10-vue-generale-v1.png`, `grotte-sombre-vue-generale-v1.png` (r3), `grotte-sombre-etude-halo-v1.png`, `lavanville-vue-generale-v1.png` (validées le 2026-10-15) ; pour l'intérieur de la Tour, la vue des étages du J19 (`origin/jalon-19:docs/design/reference/tour-pokemon-vue-generale-v1.png`, validée le 2026-10-15 : même bâtiment, même famille de tombes et de bougeoirs). **Géométrie, qui fait foi** : `tools/plans/route_9.txt`, `route_10.txt`, `grotte_sombre_1f.txt`, `grotte_sombre_b1f.txt`, `lavanville.txt`, `tour_pokemon_rdc.txt`, variante J18 d'`azuria.txt` (aucune case touchée au T1).
- **Outil** : `tools/art/serie21.py` (`--prompts`, `--refs`, `--commandes`, `--planche`, `--contact`, `--manifeste` préparé et **non lancé**, `--controle` au T6 ; génération en **deux vagues**, trois à la fois ; une image de vague 2 joint les images de vague 1 de même matière). **Un prompt versionné par image** : `tools/art/prompts/serie21/<NOM>.txt` (20 fichiers : 16 + 4 conditionnels).
- **Prompts** : ADN visuel v1 (cahier §1.3) + **LUMIÈRE NE**, avec trois blocs de valeurs : `VALEURS_GROTTE_SOMBRE` (brun-ocre humide ; **peint clair et lisible** : sol 60–72 %, faces 35–45 %, dessus des masses 18–26 %, rapport sol / masse ≥ 2,5 ; aucune pénombre, aucun halo, aucun rayon : le voile, le halo du joueur, les `LightGlow` et les profils `cave_*` font le noir, dossier §5.2), `VALEURS_TOUR` (gris perle violacé, calme ; profil `tower_cold` et halos `candle` du jeu), `VALEURS_LAVANVILLE` (gris violacé, crème, sauge ; **aucune brume ni fenêtre éclairée** : profil `lavender`). Interdits répétés : texte, lettres, **inscription sur les tombes**, emblème de type balle (hors Centre et Boutique existants), faune non-Pokémon, Pikachu et tout Pokémon non demandé, sosie du héros, squelette, crâne, fantôme, toile d'araignée, croix, élément effrayant.
- **Ancres = assets préparés du dépôt** (`assets/world/...`, toujours présents dans la copie) : la génération ne dépend d'aucune image brute d'une autre copie (pas de `--ancres`). **Références** : 34 recadrages `REF_R9_*`, `REF_R10_*`, `REF_GS_*`, `REF_HA_*`, `REF_LA_*`, `REF_TP_*` (boîtes versionnées dans `REFS`, × 3, 1 536 px max ; la vue de la Tour est lue par `git show origin/jalon-19:…` si elle n'est pas dans la copie).
- **Règle de Kevin pour Codex** (reprise de la série 19) : AVEC les images jointes (2 essais), puis SANS pièce jointe (2 essais) ; refus consignés dans `$ART/refus_serie21.log`.
- **Planche de contrôle** (sans Codex) : `python3 tools/art/serie21.py --planche` → `build/art/J18_KIT_v1.png` (1 case = 48 px, héros à l'échelle) : réutilisés, sols, personnages, variations, nouveaux (référence recadrée à la taille en jeu), conditionnels, abandonnés. **Relue au T1.**

## Bilan

| | Nombre |
|---|---|
| **Réutilisés** tels quels (assets distincts, hors personnages) | **≈ 52** |
| **Variés** (dérivés d'un existant, sans image neuve) | **11** |
| **Nouveaux** : images générées → assets | **16 images → 40 assets** (10 en vague 1, 6 en vague 2) |
| Conditionnels (prompts prêts, jamais lancés par défaut) | 4 |
| Abandonnés par écrit | 13 |

## A. Réutilisés tels quels

- *Sols* : `ground_herbe_01` (`.`), `ground_chemin_01` (`=`), `ground_hautes_herbes_jaune_01` + `_bas` (`h`, comme la Route 3 : herbes jaune-vert de la vue), `ground_roche_01` (`o`, terrasses de la Route 9 et de Paul), `ground_gravats_01` (`g` de la grotte : **le brun des gravats de la série 14 est exactement celui de la vue**), `ground_eau_canal_01` (`w`, rivière de la Route 10, eau du J13) ; décalcomanies `decal_touffe_*`, `decal_terre_*`, `decal_fleur_*` (variantes blanches seulement à Lavanville), `decal_puits_jour_01` (`j`).
- *Végétation, relief* : forêt `tree_foret_01..08` + `DenseForest` / `Shade` / `ForestFloor` (`T` des cinq cartes) ; `tree_a_01`, `tree_b_01` (arbres repères `G` de Lavanville) ; `prop_buisson_a/b/c_01` (accents) ; **parois beiges de la série 12** `relief_paroi_01`, `_02` (faces), `_03` (pente, rampe), `_04` (masse) pour toutes les falaises `K` des Routes 9 et 10 (même roche en colonnes moussues que les vues) ; `relief_falaise_01` (bandes `K` d'une rangée : terrasse y 17 de la Route 9, bord de la terrasse de Paul) ; `relief_rebord_01` (`v` (64..67, 15)) ; `prop_rocher_01`, `prop_grande_pierre_01`, `prop_pierres_01` (`R`, muret de la terrasse, rochers de la Route 10) ; `prop_souche_01`, `prop_tronc_couche_01` (accents de la clairière d'entrée, vue) ; `relief_berge_01..05` + `prop_roseaux_01` (rives de la rivière, série 15).
- *Grotte* : `prop_echelle_descend_01` (`V`), `prop_echelle_monte_01` (`U`) ; `prop_lampe_chantier_01` (lampes de randonneur `halo_lampe_1..3`, + `LightGlow lamp`) ; `prop_indice_caillou_01` (indice de la Super Potion cachée (43, 32)) ; `prop_panneau_01` (panneau du randonneur « Prudence. » (26, 2)).
- *Bouches de la Grotte Sombre sur la Route 10* (`Q` (16..17, 7) et (8..9, 47)) : **`relief_bouche_paroi_01` de la série 19 (J17, validée, intégrée sur `origin/jalon-17`)** : arche sombre dans la roche beige moussue, 4 × 3, exactement la vue. Disponible dans `main` à la clôture du J17, avant les cartes du J18 (Q-4) ; sinon conditionnel `WORLD_RELIEF_BOUCHE_GROTTE_SOMBRE_01`.
- *Bâtiments* : `bldg_centre_01` (Centre de la Route 10, Centre de Lavanville), `bldg_boutique_01` (Boutique de Lavanville) — les deux seuls emblèmes ronds.
- *Mobilier de ville* : `prop_banc_01` (`n` des squares et du jardin), `prop_panneau_01` (panneaux ×3 de Lavanville, panneau de la Route 9, panneau de la grotte), `object/poke_ball_ground` (tous les objets visibles).
- *Azuria (variante J18)* : arbre à couper (53, 23) = **asset du J16** (Coupe) ; repli `prop_jeune_arbre_arene_01` (série 17, déjà « un arbre qu'on pourra couper ») ; pans de clôture `prop_cloture_01`.
- *Intérieurs* : coques `int_centre_coque` (×2), `int_boutique_coque`, `int_maison_argenta_coque` (Maison des Pokémon, maisons 1 et 2) ; meubles existants (`int_centre_comptoir`, `_terminal`, `_banquette`, `int_boutique_*`, `int_plante`, `int_table_repas_01`, `int_canape_01`, `int_lit_01`, `int_cuisine_01`, `int_panier_pokemon_01` ×2 dans la Maison des Pokémon).
- *Combat* : `route_9_roche` (Routes 9 et 10), `dark_cave_galerie` (déjà intégrés, `a7b309a5`).

**Personnages réutilisés** (aucune planche neuve dans cette série) :

| Rôle | Modèle | Carte |
|---|---|---|
| Lou, Zoé, Elsa | `lass` (`dresseuse`) | Route 9, B1F |
| Adam, Jules | `camper` | Route 9 |
| Bernard, Gilles, Paul, Roger, Marcel | `mountaineer` (`montagnard`) | Routes 9, 10, grotte |
| Noa | `scout` | Route 9 |
| Hector, Simon, Yanis | `pokemaniac` (J18) | Route 10, grotte |
| randonneur (P1) | `hiker` (`randonneuse`) [D] | Route 10 |
| Exorciste (gardienne) | `channeler` (J18, prière) | Tour |
| gardien | `old_man` | Tour |
| infirmières, vendeur | `nurse`, `clerk` | Centres, Boutique |
| habitants, visiteurs, enfant de la Maison des Pokémon, vieille dame | `lass_young`, `traveler`, `kid`, `vieille_dame`, `maman` [D] (un modèle par habitant et par carte, choix au T14) | Lavanville, Tour |
| Piafabec sur son rocher, Racaillou endormi | `spearow`, `geodude` | Route 9 |

## B. Variations sans nouvel asset

1. **Rampe** de la Route 9 (x 24..26, y 16..24) et montée (x 58..61) : chemin + `relief_paroi_03` (pente) en flanc ; aucun module de rampe (conditionnel `WORLD_RELIEF_TERRASSE_PLANCHE` si la capture du T11 ne lit pas les terrasses).
2. **Bande centrale** de la Route 10 (y 29..46) : forêt `DenseForest` au-dessus + faces `relief_paroi_01/02` sur les rangées du bas (y 43..46) et du haut (y 29..31), comme la vue (falaise puis forêt) ; aucune masse de 18 rangées peinte.
3. **Entrée E** (27..28, 0) et **sortie e** (8..9, 48) de la grotte, vues de l'intérieur : sol `j` + `decal_puits_jour_01` + halo `beam` (méthode du Mont Sélénite) ; option : `relief_bouche_cave_nord_01` / `_sud_01` (série 19) assombries au T12, à juger sur capture.
4. **Maison 2** (N, 36..42, 16..21) = `bldg_maison_lavanville_01` **en miroir** (porte centrée).
5. **Forêt et pelouse de Lavanville** : `Shade` désaturé + profil `lavender` (plan §4.1).
6. **Haie de la Tour** (colonnes `x` de part et d'autre) et toutes les `x` de Lavanville : modules de buis de la planche de Lavanville, en rangées (aucune haie sur socle `prop_haie_01`, trop « jardin de Jadielle »).
7. **Fleurs éparses** des pelouses : `decal_fleur_*` blanches et mauves seulement, valeur × 0,9.
8. **Mur du fond de la Tour** sur 3 rangées : couronnement (`relief_mur_tour_03`) + faces (`_01`, `_02`) ; cases `K` éloignées du sol = `ground_masse_roche_01` **assombrie et violacée** (`Shade`).
9. **Rochers `o`** de la grotte : rochers bruns de la planche ; repli `prop_rocher_grotte_01/02` teintés brun (`Shade`).
10. **Eau de la rivière** : `ground_eau_canal_01` sur 5 colonnes, un peu assombrie au sud (profondeur) ; écume du shader.
11. **Bancs de la Tour** `nnn` / `nn` : un module `int_banc_tour_01` d'une case, juxtaposé (pas de banc de 3 ni de 2).

## C. Nouveaux : 16 images → 40 assets

| Fiche → asset(s) | Rôle (lettre, cases) | Taille en jeu | Vague |
|---|---|---|---|
| `WORLD_GROUND_GROTTE_SOMBRE_01` → `ground_grotte_sombre_01` | sol calme `.` des deux étages | texture 384 | 1 |
| `WORLD_GROUND_MASSE_GROTTE_SOMBRE_01` → `ground_masse_grotte_sombre_01` | dessus des masses `#` | texture 384 | 1 |
| `WORLD_RELIEF_PAROI_GROTTE_SOMBRE_PLANCHE` → `relief_paroi_grotte_sombre_01..06` | faces, angles, bord latéral, lèvre nord (rôles du J12) | 3/3/2/2/1/3 cases | 1 |
| `WORLD_PROP_GROTTE_SOMBRE_PLANCHE` → `relief_paroi_fendue_01`, `prop_racines_plafond_01`, `_02`, `prop_rocher_grotte_sombre_01`, `_02` | paroi fendue `f`, racines `r`, rochers `o` | 3 / 1 / 2 / 1 / 1 | 2 |
| `WORLD_PROP_GRANDE_COLONNE_01` → `prop_grande_colonne_01` | colonne `K` (19..23, 12..17) | 5 × ≈ 5,5 | 2 |
| `WORLD_PROP_FLAQUE_GROTTE_01` → `prop_flaque_grotte_01` | flaque `w` (18..25, 29..32), à plat | 8 × 4 | 2 |
| `WORLD_BLDG_CENTRALE_LOINTAINE_01` → `bldg_centrale_lointaine_01` | centrale `E` (29..33, 3..9), sans porte | 5 × ≈ 7 | 1 |
| `WORLD_PROP_TOUR_LOINTAINE_01` → `prop_tour_lointaine_01` | repère `tour_lointaine` (8..12, 74..75), au-dessus de la forêt | 5 × ≈ 6 | 2 |
| `WORLD_GROUND_PAVES_LAVANVILLE_01` → `ground_paves_lavanville_01` | pavés `p` | texture 384 | 1 |
| `WORLD_BLDG_TOUR_POKEMON_01` → `bldg_tour_pokemon_01` | Tour `U` (29..40, 0..10), porte (34..35, 10) | 12 × 11 | 1 |
| `WORLD_BLDG_MAISON_POKEMON_01` → `bldg_maison_pokemon_01` | Maison des Pokémon `F` (11..18, 3..9), portes (14..15, 9) | 8 × 7 | 1 |
| `WORLD_BLDG_MAISON_LAVANVILLE_01` → `bldg_maison_lavanville_01` | maisons `m` (3..9, 4..9) et `N` (miroir) | 7 × 6 | 1 |
| `WORLD_PROP_LAVANVILLE_PLANCHE` → `prop_buis_taille_01`, `_02`, `prop_haie_taillee_01`, `prop_fleurs_pales_01`, `_02`, `prop_if_taille_01` | haies `x`, fleurs `y`, ifs du parvis | 1 / 1 / 2 / 1 / 2 / 1 | 1 |
| `WORLD_GROUND_DALLES_TOUR_01` → `ground_dalles_tour_01` | sol `.` de la Tour (**mutualisé J19**) | texture 384 | 1 |
| `WORLD_RELIEF_MUR_TOUR_PLANCHE` → `relief_mur_tour_01..05`, `relief_escalier_tour_01` | murs `K`, escalier `S` (17, 2) (**mutualisé J19**) | 2/2/2/0,35/0,35/1 | 2 |
| `INT_TOUR_PLANCHE` → `int_tombe_tour_01..03`, `int_bougeoir_tour_01`, `int_comptoir_tour_01`, `int_banc_tour_01` | tombes `g` ×36, chandeliers `b` ×6, comptoir `W`, bancs `n` | 1/1/1/1/4/1 | 2 |

**Écarts au plan §4.18** (défauts, règle 4, notés pour Kevin) :
- **Falaises en terrasses et rampes de la Route 9** : **réutilisées** (parois série 12, falaise basse, rebords, pente), pas d'asset neuf : la vue de la Route 9 est exactement la roche de la Route 3. Conditionnel prêt.
- **Bouches de grotte** : réutilisées de la **série 19 (J17)** au lieu d'être refaites.
- **Intérieur de la Tour en modules** (dalles + murs + meubles, sur `cave_map_kit.gd` comme le souterrain du J15) plutôt qu'une coque peinte (`build_painted_interiors.gd`, plan §4.2) : une coque de 20 × 18 cases serait générée à 1 024² puis étirée à 1 920 × 1 728 (× 1,9, floue), et le **J19** (`jalon-19.md` §2.1, §2.15) construit ses étages 2F–6F avec `relief_mur_tour_*` et un sol en dalles sur `cave_map_kit.gd` : un seul kit pour la Tour, produit ici, **noms alignés sur le plan du J19**. Repli : coque `INT_TOUR_RDC_COQUE` (conditionnel).
- **Gardien** : `old_man` réutilisé (dossier §10.4).

### Fiches

Pour chaque asset : rôle, emprise, taille en pixels du jeu (1 case = 96 px), ancrage et réglages du manifeste prévus (T6, valeurs par défaut). Prompt complet : `tools/art/prompts/serie21/<NOM>_NE_r1.txt`.

#### Grotte Sombre
- **`ground_grotte_sombre_01`** — sol `.` : terre argileuse battue beige ocre clair, légèrement humide (zones satinées), minuscules graviers ; le plus clair de la grotte. Texture 1 024² raccordable → 384 (contraste 0,6). Remplace `FLOOR_TEXTURE` de `cave_map_kit.gd` dans `build_dark_cave.gd` (constante du constructeur, le kit n'est pas modifié). **Jointes** : `REF_GS_SOL`, sol gris (à ne pas copier), gravats.
- **`ground_masse_grotte_sombre_01`** — dessus des `#` : gros blocs arrondis brun chocolat, reflets humides, rares radicelles ; 18–26 % (contraste 0,6, couleur 0,9). Remplace `MASS_TEXTURE`. **Jointes** : `REF_GS_MASSE`, masse grise.
- **`relief_paroi_grotte_sombre_01..06`** — planche 3 × 2 de 512, 1 case = 150 px, **mêmes rôles et découpes que `relief_paroi_grotte_01..06`** (J12) : 01/02 faces A/B (3 × 2), 03 angle saillant, 04 angle rentrant (2 × 2), 05 bord latéral (1 × 3), 06 lèvre nord (3 × 1). Contact 0, couche `Entities` comme au J12. Remplace `WALL_FACES`, `WALL_SIDE`, `WALL_LIP`. **Jointes** : `REF_GS_PAROI`, `REF_GS_ANGLE`, `REF_GS_B1F`, modules gris 01/03/05, masse.
- **`relief_paroi_fendue_01`** — `f` (32, 1) : face de paroi 3 × 2 (gabarit de la face A) fendue au milieu, filet de **ciel pâle peint dans sa couleur, sans rayon** ; posée sur (31..33, 1), le `LightGlow shaft` `halo_filet` (32, 3) fait la lumière ; sol `j` dessous. **Collision** : la case `f` seule (déjà bloquée par la grille).
- **`prop_racines_plafond_01`, `_02`** — `r` (41, 32) et (43, 32) : racines qui percent le plafond et descendent jusqu'au sol (1 × ≈ 2 ; 2 × ≈ 2, éventail), ancrées au pied, contact 0,15 ; bloquent leurs cases ; T-9 lu depuis (42, 32) ←, indice de l'objet caché →.
- **`prop_rocher_grotte_sombre_01`, `_02`** — `o` (cases `o` des deux grilles) : 1 case, ≈ 0,8 / 0,6 de haut.
- **`prop_grande_colonne_01`** — `K` (19..23, 12..17) : pilier 5 cases de base, ≈ 5,5 de haut, sommet coupé net (se perd dans le noir) ; ancré bas-centre sur la rangée 17, centré en x 21 ; `ombre` non, contact 0,15. La Super Potion (21, 18) est à son pied (face sud). **Jointes vague 2** : planche de parois, masse et sol de la vague 1.
- **`prop_flaque_grotte_01`** — `w` (18..25, 29..32) : nappe d'eau peu profonde 8 × 4 **à plat** (couche du sol, `GroundDecals`, comme `prop_mare_grotte_01`), bord de terre brune humide, aucune margelle ; contact aucun. **Jointes vague 2** : sol de la vague 1.
- **Repères sans asset** : passage étroit (35..40, 34) = parois ; panneau du randonneur = `prop_panneau_01`.

#### Route 10
- **`bldg_centrale_lointaine_01`** — `E` (29..33, 3..9) : bloc industriel gris-bleu, haute cheminée, **aucune porte**, lointain (pâle, bleuté), bas coupé net ; ancré bas-centre sur la rangée 9, `ombre` non, contact aucun ; forêt `T` devant/autour. Rien n'invite à y aller (I-15).
- **`prop_tour_lointaine_01`** — `tour_lointaine` (8..12, 74..75) : corps central et étages hauts de la Tour, lointain, bas coupé net ; posé **au-dessus de la forêt** (couche au-dessus des arbres, comme `prop_vue_port_01`), base sur la rangée 75, visible depuis la sortie sud (8..9, 48) en descendant le sentier. **Jointe vague 2** : `bldg_tour_pokemon_01` (même tour).

#### Lavanville
- **`ground_paves_lavanville_01`** — `p` : petits pavés rectangulaires gris violacé en appareil de briques ; texture 384 (contraste 0,7).
- **`bldg_tour_pokemon_01`** — `U` (29..40, 0..10), porte double (34..35, 10) = 6e et 7e colonnes : mémorial de pierre gris violacé, corps central à étages en retrait, toit pointu sobre, ailes basses, vitraux unis non éclairés ; **haute, digne, repère**, sans croix ni gargouille. `axe w`, `cases 12`, ombre oui, contact 0,12. Les ifs, massifs et haies du parvis sont des objets séparés (grille).
- **`bldg_maison_pokemon_01`** — `F` 8 × 7, portes (14..15, 9) = 4e et 5e colonnes : toit prune-rosé désaturé, crépi crème, jardinières blanches et mauves, gamelle et panier près de la porte ; `cases 8`.
- **`bldg_maison_lavanville_01`** — `m` (3..9, 4..9) porte (6, 9) et `N` (36..42, 16..21) porte (39, 21), **miroir** : toit taupe violacé, crépi crème rosé ; `cases 7`.
- **Planche de Lavanville** (1 case = 150 px, contact 0,2) : `prop_buis_taille_01/02` (boules 1 case, rangées des `x` ; alterner à la graine), `prop_haie_taillee_01` (2 cases, raccordable : longues haies `x` des rues 1 et 2 si les boules se répètent), `prop_fleurs_pales_01` (1 case) et `_02` (2 × 1, bordure de pierre) pour les `y`, `prop_if_taille_01` (1 × 1,8 : de part et d'autre de la porte de la Tour, sur les cases `x`/`y` du parvis, à la main au T14).

#### Tour Pokémon (rez-de-chaussée ; mutualisé avec le J19)
- **`ground_dalles_tour_01`** — sol `.` : grandes dalles carrées gris perle violacé, quadrillage droit ; texture 384 (contraste 0,8).
- **`relief_mur_tour_01..05`** — planche 3 × 2, 1 case = 150 px, **rôles du souterrain** (`relief_mur_souterrain_*`) : 01/02 faces A/B (2 × 2, sol au sud ; B porte une niche vide), 03 couronnement (sol au nord, 2 × 0,4), 04 bord latéral (0,35 × 2, miroir pour l'autre côté), 05 angle (0,35 × 0,6). RDC : mur du fond (rangées 0..2) = couronnement + faces sur la rangée 2 ; colonnes 0 et 19 = bords latéraux ; rangées 16..17 = couronnement + seuil (9..10, 16) laissé libre (paillasson : décalcomanie de sol sombre, à la main).
- **`relief_escalier_tour_01`** — `S` (17, 2) : escalier montant pris dans le mur (1 × 2, gabarit de la face), warp `STEP_ON` ↑ en `coming_soon` (plan §0.2 n° 12) ; l'Exorciste en (17, 3) le masque.
- **`int_tombe_tour_01..03`** — `g` ×36 (rangées 5, 7, 9) : stèles arrondies **sans inscription** (A nue, B bouquet, C offrande) ; alternance à la graine, B et C plus fréquentes près des 5 tombes nommées ; contact 0,2 ; lecture depuis les cases libres de la grille.
- **`int_bougeoir_tour_01`** — `b` ×6 : socle de pierre + photophore, petite flamme peinte **sans halo** ; `LightGlow candle` du jeu.
- **`int_comptoir_tour_01`** — `W` (2..5, 13) : 4 × 1, registre, vase de fleurs blanches ; gardien `old_man` en (3, 12).
- **`int_banc_tour_01`** — `n` (12..14, 13), (16..17, 13) : module 1 case juxtaposé.

## D. Abandonnés (par écrit)

1. **Pénombre, halos, rayons et lueurs peints** des vues de la grotte et de l'étude du halo → voile d'obscurité, halo du joueur, `LightGlow` (`lamp`, `shaft`, `beam`).
2. **Pokémon d'ambiance peints** (Onix, Nosferapti, Racaillou de la grotte ; Rondoudou dans la rue de Lavanville ; Voltorbe dans l'herbe de la Route 10) : personnages et Pokémon ne sont jamais dans les décors (Rondoudou et Nidoran ♀ sont dans la Maison des Pokémon, §6.2).
3. **Personnages des vues** (positions données par les grilles).
4. **Fenêtres éclairées et brume** de Lavanville et de la Route 10 sud → lumière NE + profil `lavender` / `golden_hour` ; une brume réelle relève de la phase DA (le J19 prévoit une « texture de brume qui se répète » : à reprendre si elle existe).
5. **Palissade de rondins et bordures de galets** de la vue de la Route 9 (autour du vallon, le long du sentier) : la grille met `K` (falaise basse) et `R` (rochers) ; pas de module neuf.
6. **Rochers 2 × 2 isolés** de la vue de la Route 9 : rochers existants.
7. **Centrale « bleue » proche** de la vue de la Route 10 : la centrale est un **lointain** au-delà de l'eau, sans porte (I-15).
8. **Tour octogonale à étages** de la vue de la Route 10 : la silhouette lointaine reprend la Tour de Lavanville (même bâtiment).
9. **Grande Tour gothique à flèches** de la vue de Lavanville : gardée en masse et en couleurs, **sans** flèche dentelée, croix ni allure d'église (« digne », pas inquiétante).
10. **Margelle de pierre taillée** de la flaque (vue) : bord de terre humide (une eau peu profonde de grotte).
11. **Lampe et Poké Ball peintes** dans les recadrages : objets du jeu (`prop_lampe_chantier_01`, `poke_ball_ground`).
12. **Planche d'icônes, personnages, fonds de combat** : rien de nouveau (Super Potion du J15 ; Pokémaniac, Exorciste, fonds CB.3 déjà intégrés).
13. **Panneau du Scope Sylphe** (42, 11) : **série 20 (J19)**, pas ici.

## Conditionnels (prompts prêts, jamais lancés par défaut ; décision notée dans `etat-projet.md`)

- `WORLD_RELIEF_BOUCHE_GROTTE_SOMBRE_01` (4 × 3) : si `relief_bouche_paroi_01` (série 19) n'est pas dans `main` au moment des cartes, ou ne se lit pas sur la capture du T11.
- `WORLD_BLDG_MAISON_LAVANVILLE_02` (7 × 6, ardoise) : si la maison 2 en miroir se voit comme une copie.
- `WORLD_RELIEF_TERRASSE_PLANCHE` (rebords d'une case, rampe) : si parois et falaise basse ne font pas les terrasses de la Route 9 (capture du T11).
- `INT_TOUR_RDC_COQUE` (20 × 18) : seulement si le rez-de-chaussée est construit en pièce peinte (plan §4.2) plutôt qu'en modules.

## Contrôle « chaque élément des vues a un asset » (CA du T1)

- *Route 9* : forêt, prairie, fleurs, chemin, hautes herbes → A ; grande falaise beige en colonnes (masse nord) → `relief_paroi_01..04` (A) ; terrasses rocheuses (sol gris et cailloux) → `ground_roche_01` + `prop_pierres_01` (A) ; bordures de galets et palissade → D5 ; terrasse basse → `relief_falaise_01` (A) ; rebord → A ; rochers → A ; souche, tronc couché, panneau, Poké Balls → A ; Racaillou, Piafabec, Dresseurs → sprites existants.
- *Route 10* : Centre → A ; falaises → parois A + bande centrale B2 ; deux bouches → série 19 (A) ; rivière → canal + berges + roseaux (A) ; rochers des rives → `prop_rocher_01` (A) ; centrale → **neuve** (lointain) ; Tour au sud → **neuve** (lointaine) ; brume → D4 ; herbes, Poké Ball, terrasse de Paul (cailloux) → A ; Voltorbe → D2.
- *Grotte Sombre* : sol beige → **neuf** ; masses brunes → **neuve** ; parois → **planche neuve** ; gravats → A ; colonne → **neuve** ; flaque → **neuve** ; racines → **planche des repères** ; filet de jour → paroi fendue (planche) + `shaft` ; lumière de l'entrée → B3 ; échelles ×4 → A ; lampes → A ; panneau → A ; rochers isolés → planche des repères ; passage étroit → parois ; Pokémon peints → D2.
- *Lavanville* : forêt brumeuse → A + B5 ; rues pavées → **pavés neufs** ; boules de buis, haies → **planche neuve** ; fleurs pâles → planche + B7 ; pelouses → A ; bancs → A ; arbres → A ; Centre, Boutique → A ; maison brune, maison ardoise → **maison neuve** (+ miroir) ; maison à toit rose → **Maison des Pokémon neuve** ; Tour → **neuve** ; jardinières et ifs du parvis → planche (if) + façade ; personnages, Rondoudou → D2/D3.
- *Tour (intérieur, d'après la vue des étages)* : dalles → **neuves** ; murs → **planche neuve** ; tombes et fleurs → **planche neuve** ; bougeoirs → **planche neuve** + `candle` ; escaliers → module de la planche des murs ; Exorcistes → `channeler` (A) ; brume violette, spectre → J19 (hors J18). Comptoir et bancs (grille) → planche neuve.

Rien n'est implémenté parce qu'il est sur une image (règle 10) : la grille décide de la place.

## Commandes du T2

**Sur le Mac, depuis la racine de la copie** (trois générations à la fois ; vague 1 puis 2 ; une image déjà présente n'est pas refaite ; les conditionnels ne partent pas) :

```bash
python3 tools/art/serie21.py --prompts     # sans effet si les prompts versionnés sont à jour
python3 tools/art/serie21.py --refs        # 34 recadrages dans build/art (lit la vue de la Tour depuis origin/jalon-19 au besoin : git fetch avant)
python3 tools/art/serie21.py               # 10 images (vague 1) puis 6 (vague 2), Codex, aucune API payante
python3 tools/art/serie21.py --contact     # build/captures/jalon18_assets/serie21_contact.png → Kevin
```

**Image par image** : `python3 tools/art/serie21.py --commandes`. Une correction = une entrée de `CORRECTIONS` (`(identifiant, 2)` → description corrigée), `--prompts`, relancer `_r2`. Une image de vague 2 joint la `_r1` de vague 1 : si une image de vague 1 passe en `_r2`, mettre à jour `VAGUE1` avant la vague 2. **Pas** de `manifeste.json`, `preparer.py` ni scène au T2 (T6 : `serie21.py --manifeste` puis `--controle`).

## Journal de la série 21

- **T1 (2026-10-15, branche `j18-t1-kit`)** : liste du kit (**16 images → 40 assets** + 4 conditionnels ; 52 réutilisés, 11 variations, 13 abandons), fiches, 20 prompts versionnés, 34 références recadrées (boîtes relues sur planche), commandes, entrées de manifeste préparées (non appliquées), planche de contrôle `build/art/J18_KIT_v1.png` relue. Grilles non modifiées. Aucune image générée. Aucun fichier de `game/` touché.
