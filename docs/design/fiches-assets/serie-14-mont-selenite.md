# Série 14 — Route 3 et Mont Sélénite (jalon 12, lumière NE)

> Rédigée au **J12 T1** (2026-10-11, architecte, branche `j12-t1-kit` depuis `jalon-12`). Plan : `docs/tech/jalon-12.md` §1.3 (lecture des grilles), §1.4 (kit) ; conception : `docs/design/dossier-15-route-3-mont-selenite.md` (verrouillé). Fichier **nouveau**. **Aucune image générée au T1** : génération au **T2** (Mac, Codex), validation de Kevin sur planche de contact (**12.0-art**), intégration au **T6** (manifeste, `preparer.py`, `preparer_menu.py`, règles, scènes, looks).

**Consigne de Kevin (J8–J10)** : le plus petit kit modulaire qui produit la **sensation** des vues validées dans Godot, sans répétition visible.
- **DA et composition** : `reference/route-3-vue-generale-v1.png` et `reference/mont-selenite-vue-generale-v1.png` (essais 2). **Géométrie, qui fait foi** : `tools/plans/route_3.txt`, `mont_selenite_1f.txt`, `mont_selenite_b1f.txt`, `mont_selenite_b2f.txt`, `route_4_sas.txt` (non modifiées au T1).
- **Outil** : `tools/art/serie14.py` (`--prompts`, `--refs`, `--commandes`, `--planche`, `--manifeste` réservé au T6, `--controle` au T6, génération en **trois vagues** : une image de vague n+1 joint une image de la vague n). **Un prompt versionné par image** : `tools/art/prompts/serie14/<NOM>.txt` et, pour les attentes, `tools/art/attente/prompts/<NOM>_ATTENTE.txt` (écrits par `--prompts` depuis les tables du script : on corrige la table, on relance `--prompts`, on relit le diff).
- **Prompts** : ADN visuel v1 (cahier §1.3) + **LUMIÈRE NE** pour les objets, personnages et icônes ; **VALEURS DE GROTTE** pour les sols et parois souterrains (exception de palette : ardoise, gris bleuté ; sol clair, faces moyennes, dessus des masses très sombre, rapport sol / paroi ≥ 2 ; aucune flaque de lumière ni ombre portée peinte : les halos sont du moteur, `jalon-12.md` §2.4). Planches de marche sur le modèle `MODELE_MARCHE` de la série 12 (héros validé joint), attentes sur le modèle des séries 10–12. Interdits répétés : texte, lettres, logo (sauf le R rouge demandé), faune non-Pokémon, Pikachu et tout Pokémon non demandé, sosie du héros, squelette, toile d'araignée, élément effrayant.
- **Team Rocket (B-7)** : uniforme décrit **une fois** (`UNIFORME` du script) et repris mot pour mot par les deux Sbires : blouson noir anthracite à col montant, **grand R rouge plein sur la poitrine (seul emblème)**, pantalon noir, gants et bottes gris clair, **casquette noire unie** ; sbires **anonymes** ; ni grade, ni arme, ni équipement tactique (pas militaire), ni rictus ni pose théâtrale (pas caricatural) ; aucune ressemblance avec un personnage connu (ni cheveux roses / bleus / violets, ni uniforme blanc : écarts de l'essai 1). La Sbire ♀ est générée en **vague 2** en joignant la planche du Sbire ♂ (même uniforme au pixel près).
- **Références** : recadrages `REF_R3_*` et `REF_MS_*` des deux vues (`serie14.py --refs`, boîtes versionnées dans `REFS`, agrandies × 3) : forme, matériaux, couleurs — jamais le rendu ni la couleur beige de la montagne (§7 du dossier). `REF_AR_PAROI` (vue d'Argenta, même boîte que la série 12) = **ancre de style** de la roche. Ancres validées (dans `build/art` du checkout principal) : souche, arbre A, `WORLD_RELIEF_PAROI_PLANCHE` (modules `relief_paroi_*`), rocher, grande pierre, pierres, caisses, tonneau, chemin, héros `PERSO_P2_PEINT_r1`, `MENU_OBJETS_PLANCHE_r1`, `INT_MUSEE_PLANCHE_NE_r1` (formes de la Pierre Lune et des fossiles du Musée).
- **Planche de contrôle** (sans Codex) : `python3 tools/art/serie14.py --planche` → `build/art/MS_KIT_v1.png` (1 case = 48 px, héros à l'échelle) : réutilisés, variations, nouveaux (référence recadrée à la taille en jeu), icônes, conditionnels, abandonnés. Relue au T1.

## Liste du kit

**A. Réutilisés tels quels** (`jalon-12.md` §1.4 A) : sols `ground_herbe_01`, `ground_chemin_01` (masque G), décalcomanies `decal_touffe_*`, `decal_terre_*`, `decal_fleur_*` (de plus en plus rares vers l'est) ; forêt et bosquets `T` (`tree_foret_01..08`, `DenseForest` + `Shade` + `ForestFloor`) ; hautes herbes H1–H4 `ground_hautes_herbes_jaune_01` (+ `_bas`) ; rebords L1, L2 `relief_rebord_01` ; rochers et affleurements `R`, buissons `x` (`prop_rocher_01`, `prop_grande_pierre_01` à 0,6–1, `prop_pierres_01`, `prop_buisson_a/b/c_01_bourg`) ; panneaux `prop_panneau_01` (×4) ; **paroi de la série 12** `relief_paroi_01..04` à l'**ouest** seulement (masse `K` des rangées 0..3 vers x 30–40) ; Centre `bldg_centre_01` (8 × 7) et intérieur `_pokemon_center` du J10 ; Poké Ball au sol `poke_ball_ground` pour **tous** les objets visibles (Poké Ball, Potion, Anti-Para, Corde Sortie, Pierre Lune visible, CT01) ; personnages Gamin `youngster` (×2), Scout `scout` (×2), voyageur `traveler`, randonneuse `hiker`, randonneur `mountaineer` (1F), infirmière `nurse` ; Piafabec `spearow` (×2, `shy=fly`) ; Rondoudou d'ambiance : sa planche C-4 (T3) ; Pokémon en combat = artworks officiels.

**B. Variations sans nouvel asset** : forêt plus sèche vers l'est (`Shade`, valeur × 0,95 puis × 0,9) ; rochers assombris et teintés gris bleuté à l'est ; grande pierre × 0,6 en miroir ; buissons en miroir, teinte ± 8 % ; **sas** : rebord du versant `~` = `relief_falaise_01`, blocs de lisière `b` = buissons + rochers, rochers `o` = `prop_rocher_01` teinté, bouche `D` = `relief_entree_grotte_01` en **miroir** (conditionnel si cela ne se lit pas) ; **entrée `E` du 1F** (bord sud, vers la Route 3) = sol de grotte + halo « jour » du moteur, aucun asset ; puits de jour 2 × 2 du secteur nord = `decal_puits_jour_01` réduit ; tranchée de B1F (4 × 3) = `prop_tranchee_01` à l'échelle 4/3 ; lampes des niches et du couloir = `prop_lampe_chantier_01` (miroir pour varier).

**C. Nouveaux : 23 images** (fiches ci-dessous) — 9 en vague 1, 12 en vague 2, 2 en vague 3.

| Fiche → asset(s) | Rôle | Emprise / taille | Images | Vague |
|---|---|---|---|---|
| `WORLD_GROUND_ROCHE_01` → `ground_roche_01` | sol rocheux `o` (Route 3 est, plateau, parvis, sas) | texture | 1 | 1 |
| `WORLD_RELIEF_PAROI_ARDOISE_PLANCHE` → `relief_paroi_ardoise_01..04` | montagne d'ardoise (Route 3 est, parvis, sas) | 4 modules 4 × 3 | 1 | 1 |
| `WORLD_RELIEF_ENTREE_GROTTE_01` → `relief_entree_grotte_01` | entrée `Q` (73..74, 9) ; miroir pour `D` du sas | 4 × 3, ouverture 2 | 1 | 2 |
| `WORLD_GROUND_GROTTE_01` → `ground_grotte_01` | sol calme `.` des trois étages | texture | 1 | 1 |
| `WORLD_GROUND_GRAVATS_01` → `ground_gravats_01` | gravats `g` (terrain de rencontre, B-3) | texture | 1 | 2 |
| `WORLD_GROUND_MASSE_ROCHE_01` → `ground_masse_roche_01` | dessus des masses `#` | texture | 1 | 2 |
| `WORLD_RELIEF_PAROI_GROTTE_PLANCHE` → `relief_paroi_grotte_01..06` | faces, angles, bord latéral, lèvre nord | 3 × 2 … 1 × 3 | 1 | 2 |
| `WORLD_PROP_GROTTE_PLANCHE` → `prop_colonne_grotte_01/02`, `prop_rocher_grotte_01/02`, `prop_eclats_lune_01/02` | repères minéraux `K`, `o`, `*` (V-3) | 1 à 2 cases | 1 | 2 |
| `WORLD_PROP_MARE_GROTTE_01` → `prop_mare_grotte_01` | mare `w` du 1F (47..50, 4..6) | 4 × 3, au sol | 1 | 2 |
| `WORLD_DECAL_PUITS_JOUR_01` → `decal_puits_jour_01` | puits de jour `j` | 4 × 3 (et 2 × 2) | 1 | 2 |
| `WORLD_PROP_ROCKET_PLANCHE` → `prop_lampe_chantier_01`, `prop_caisse_r_01/02`, `prop_tranchee_01`, `prop_projecteur_01`, `prop_outils_fouille_01` | indices et camp Rocket `L`, `R`, `F`, projecteurs | 1 à 3 cases | 1 | 1 |
| `WORLD_PROP_ECHELLES_PLANCHE` → `prop_echelle_descend_01`, `prop_echelle_monte_01` | `V`, `U` « clairement visibles » | 1 case (+ débord) | 1 | 1 |
| `WORLD_PROP_DALLE_FOSSILES_PLANCHE` → `prop_dalle_01`, `prop_fossile_dome_01`, `prop_fossile_nautile_01` | dalle `S` (24..26, 31) et fossiles posés | 3 × 1 ; 0,6 | 1 | 2 |
| `WORLD_PROP_INDICES_PLANCHE` → `prop_indice_caillou_01`, `prop_indice_eclat_01` | indices des objets cachés (B-10, Q-2) | 1 case | 1 | 3 |
| `PNJ_FILLETTE` + `FILLETTE_ATTENTE` → `fillette` (`lass_young`) | Léa, Inès | 108 px | 2 | 1, 2 |
| `PNJ_SBIRE_ROCKET_H` + attente → `sbire_h` (`rocket_grunt_m`) | R1, R3 | 128 px | 2 | 1, 2 |
| `PNJ_SBIRE_ROCKET_F` + attente **qui creuse** → `sbire_f` (`rocket_grunt_f`) | R2, la fouilleuse | 124 px | 2 | 2, 3 |
| `PNJ_CHERCHEUR_FOSSILES` + attente → `chercheur_fossiles` (`fossil_researcher`) | Gaspard | 128 px | 2 | 1, 2 |
| `UI_OBJETS_J12_PLANCHE` → `assets/ui/items/{moon_stone, escape_rope, dome_fossil, helix_fossil}.webp` | illustrations du Sac | 4 icônes 256 px | 1 | 1 |

**Écarts au §1.4 C du plan** (défauts, règle 4) : la planche des trois sols de grotte devient **trois textures** (chaque texture doit être raccordable sur ses quatre bords et `preparer.py` / section `sols` prend une image entière) ; les **4 icônes** deviennent **une planche** (la chaîne de `potion.webp` est une planche 4 × 1, `preparer_menu.py`) ; la **mare** sort de la planche des repères (4 × 3 ne tient pas à l'échelle commune et la découpe par taches exige une grille pleine) ; ajouts sans image en plus : `prop_colonne_grotte_02` (colonnes 1 × 1 du B2F), `prop_outils_fouille_01` (camp du B2F, niche de R2). **CT01** : aucune image (Poké Ball au sol ; icône du Sac = celle du J11, conditionnel `UI_ITEM_CT` si le J11 n'en livre pas).

**D. Abandonnés** (dossier 15, « Vues générales peintes v1 », §1.3 n° 7 du plan) : **Pokémon d'ambiance de la grotte** (Nosferapti ×2, Mélofée, Racaillou, Paras de la vue) ; personnages placés par les vues ; **montagne beige à l'est** (→ ardoise) ; Fillette sur le plateau (elle garde le goulet de la jonction) ; randonneur dans la galerie est (il est au hall, (34, 38)) ; **fossiles peints de la vue** (formes inventées → objets officiels) ; entrée de grotte **en escalier** et sbire aux **cheveux roses** (essais 1) ; petit sapin isolé du plateau (forêt `T` seulement là où la grille en met).

**Conditionnels** (prompts prêts, jamais lancés par défaut, décision notée dans `etat-projet.md`) : `WORLD_PROP_AFFLEUREMENTS_PLANCHE` (si `prop_rocher_01` et la grande pierre ne remplissent pas les blocs `R` de la Route 3 sans répétition, capture du T8) ; `WORLD_RELIEF_BOUCHE_SAS_01` (bouche vue de côté, ouverte vers l'est, si le miroir de l'entrée ne se lit pas dans le sas, capture du T8) ; `UI_ITEM_CT` (si le J11 se clôt sans illustration de CT).

**Contrôle « chaque élément des vues a un asset »** (CA du T1) — Route 3 : forêt, prairie fleurie, hautes herbes, chemin, sentier d'herbe, rebords, rochers, buissons, panneaux, Poké Balls, Centre, Piafabec, Rondoudou, personnages → A ; sol caillouteux → `ground_roche_01` ; paroi → série 12 (ouest) + ardoise (est) ; entrée → `relief_entree_grotte_01` ; éclats bleus de la paroi → module 2 de l'ardoise ; Fillette → nouveau. Mont Sélénite : sol, gravats, masses, faces → 3 textures + planche de parois ; colonnes, rochers, éclats, mare, puits, échelles → C ; caisses R, lampes, planches et outils de fouille, tranchée, projecteurs → planche Rocket ; dalle et fossiles → planche dalle ; Sbires, chercheur → C ; randonneur → `mountaineer` ; Poké Balls → `poke_ball_ground` ; Pokémon, sapin → D. Rien n'est implémenté parce qu'il est sur une image (règle 10) : la grille décide de la place de chaque élément.

## Fiches

Pour chaque asset : rôle, emprise (cases de la grille), taille en pixels du jeu (1 case = 96 px), ancrage et règle `PaintedPropRules` prévue (T6), ce qui est réutilisé, images jointes. Hauteurs, tenues, emprises et réglages = **valeurs par défaut** (règle 4). Le prompt complet est dans le fichier indiqué (`tools/art/prompts/serie14/<NOM>.txt`).

### Route 3 et sas

#### WORLD_GROUND_ROCHE_01 → `ground_roche_01` (vague 1)
- **Rôle** : sol praticable `o` du pied de la montagne (x 54..81 de la Route 3, plateau du Centre, parvis), et du sas (avec le chemin). Terre gris-beige sèche, cailloux, roche plate affleurante, rares brins secs ; plus froid que `ground_chemin_01`.
- **Format** : texture opaque 1024², raccordable ; préparée en 384 px (section `sols`, contraste 0,7). **Usage** : texture de base ou masque de `PaintedGround` (textures réglables du T7). **Jointes** : `REF_R3_SOL_ROCHE`, souche, arbre A, `WORLD_GROUND_CHEMIN_01` (à ne pas copier).

#### WORLD_RELIEF_PAROI_ARDOISE_PLANCHE → `relief_paroi_ardoise_01..04` (vague 1)
- **Rôle** : la montagne qui **passe à l'ardoise** vers l'est (§7 du dossier, écart de la vue) : masse `K` de la Route 3 au-delà de x ≈ 45, au-dessus du parvis (rangées 0..9), bord est (x 78..81), sud-est ; parois `#` du sas.
- **Planche** 1536 × 1024, 2 × 2 modules de **4 × 3 cases** (la découpe exacte de la série 12, pour se raccorder bout à bout avec `relief_paroi_01..04` à la transition ; le plan proposait ≈ 5 × 3 : 4 × 3 retenu pour l'interchangeabilité) : 01 face A, 02 face B (faille + quelques éclats bleu pâle discrets), 03 extrémité gauche en gradins (miroir = droite), 04 dessus de massif raccordable. **Préparation** : `planches_arbres` (coupe la plus vide), 288 px de haut. **Ancrage** : comme la série 12 (cases `K` bloquées par la carte).
- **Jointes** : `REF_R3_PAROI_EST`, `REF_R3_PAROI_SUD` (formes ; leur beige ne fait pas foi), `REF_AR_PAROI`, `WORLD_RELIEF_PAROI_PLANCHE`, `WORLD_PROP_ROCHER_01`.

#### WORLD_RELIEF_ENTREE_GROTTE_01 → `relief_entree_grotte_01` (vague 2)
- **Rôle** : entrée du Mont Sélénite `Q` (73..74, 9), dans la paroi d'ardoise, au bout du chemin du parvis ; reprise **en miroir** pour la bouche `D` du sas (2, 6).
- **Emprise** : module 4 × 3 (72..75, 7..9), ouverture de 2 cases au milieu du bas = les deux cases `Q`. **Taille** : 384 × ≈ 288 px (`axe w`, `cases 4`). **Ancrage** : pied au milieu du bas, sur le bord de case (largeur paire) : ancre (74, 9) ; règle `{"width": 4, "depth": 3, "open": [(-1, 0), (0, 0)]}`, sans ombre portée, contact 0. Pas d'escalier, d'étai ni de panneau (le panneau du 1F est à l'intérieur, (26, 43)).
- **Jointes** : `REF_R3_ENTREE`, souche, arbre A, `WORLD_RELIEF_PAROI_ARDOISE_PLANCHE` (vague 1 : même roche, même hauteur), `WORLD_RELIEF_PAROI_PLANCHE`. **Risque** : la bouche du sas s'ouvre dans la paroi **ouest** (sortie vers l'est) ; le miroir garde une ouverture « de face » → capture du T8, sinon le conditionnel `WORLD_RELIEF_BOUCHE_SAS_01`.

#### PNJ_FILLETTE (+ `FILLETTE_ATTENTE`) → `fillette` (`lass_young`) (vagues 1, 2)
- **Rôle** : classe nouvelle « Fillette » (le `lass` du J7 est la jeune Dresseuse) : Léa (51, 16, D2, inévitable) et Inès (41, 35, D5) partagent le modèle (précédent des Scouts). **108 px** (taille de l'enfant).
- **Tenue** (défaut ; la vue lui donne cheveux châtains longs, haut clair, jupe bleu pâle) : longs cheveux châtains détachés, petit nœud rose, chemisier blanc, robe chasuble bleu ciel, chaussettes blanches, ballerines brunes, sacoche ronde rose ; **ni orange ni serre-tête** (≠ jeune Dresseuse), ≠ enfant, ≠ héros. **Attente** : pieds joints, mains jointes derrière le dos, petit sourire.
- **Jointes** : `PERSO_P2_PEINT_r1`, `REF_R3_FILLETTE` (tenue seulement). Prompts : `serie14/PNJ_FILLETTE_NE_r1.txt`, `attente/prompts/FILLETTE_ATTENTE.txt`.

### Mont Sélénite : sols et parois (valeurs de grotte)

**Règle de lumière** (§1.4 du plan) : la lisibilité est **dans la valeur peinte** — sol calme ≈ 65–75 % de luminosité, gravats ≈ 50–60 % mais **plus bruns et granuleux**, faces de paroi moyennes à sombres, dessus des masses ≈ 15–25 % ; rapport sol / paroi ≥ 2 (seuil Mac du plan : luminance sol ≥ 0,22 et sol / paroi ≥ 2,0 **après** le profil `cave_*` du moteur, vérifié au T9). Aucune flaque de lumière peinte (sauf la décalcomanie du puits, qui est la lumière elle-même), aucune ombre portée.

#### WORLD_GROUND_GROTTE_01 → `ground_grotte_01` (vague 1)
- Sol calme `.` (96 % du parcours) : roche plate tassée gris-beige pâle, dalles naturelles, poussière claire. Texture 1024² raccordable → 384 px (contraste 0,6). Texture de base des trois étages (`PaintedGround.base_texture`, T7). **Jointes** : `REF_MS_SOL`, souche, arbre A, `REF_AR_PAROI`.

#### WORLD_GROUND_GRAVATS_01 → `ground_gravats_01` (vague 2)
- Gravats `g` = **seul terrain de rencontre** sous terre (B-3), « identifiable » : cailloux anguleux brun ocre serrés. Texture raccordable → 384 px (contraste 0,8) ; masque des zones `g` (tuiles `RUBBLE`, T7). Les zones sont des rectangles nets (G1..G3 de chaque étage) : bord adouci par le masque, sans asset de bordure. **Jointes** : `REF_MS_GRAVATS`, souche, arbre A, `WORLD_GROUND_GROTTE_01` (contraste de matière, valeur proche).

#### WORLD_GROUND_MASSE_ROCHE_01 → `ground_masse_roche_01` (vague 2)
- Dessus des masses `#` (infranchissables) : ardoise bleu-gris très sombre, blocs facettés vus de dessus. Texture → 384 px (contraste 0,6, couleur 0,9) ; couche de sol sous les faces de paroi. **Jointes** : `REF_MS_MASSE`, souche, arbre A, `WORLD_GROUND_GROTTE_01` (rapport ≥ 3).

#### WORLD_RELIEF_PAROI_GROTTE_PLANCHE → `relief_paroi_grotte_01..06` (vague 2)
- **Rôle** : les bords des masses autour des galeries. Planche 1536 × 1024, 3 × 2 cellules, 1 case = 150 px : **01** face A (bord **sud** d'une masse, 3 × 2 : bande du dessus, arête claire, face), **02** face B (fissure, blocs au pied ; raccord bout à bout avec 01), **03** angle saillant (2 × 2 ; miroir = autre côté), **04** angle rentrant (2 × 2 ; miroir), **05** bord latéral (bande verticale 1 × 3, côtés est / ouest ; miroir), **06** lèvre nord (bande 3 × 1 : masse au sud d'une galerie, arête seule).
- **Préparation** : `planches_objets` (découpe par taches), largeurs `[3, 3, 2, 2, 1, 3]`, contact 0. **Pose** (T7 `cave_map_kit.gd`, T9) : automatique d'après la grille (face sur chaque case `#` dont la voisine sud est praticable, bord latéral sur les voisines est / ouest, lèvre sur la voisine nord), les faces **débordent d'une case vers le haut** sur la masse (comme les parois de la série 12) ; couche des entités, triées au pied ; aucune case praticable recouverte. Goulets (1F (7, 12) et B1F (14, 1..2) d'une case ; couloir du gardien B2F (25..26, 19..25) de deux) = deux bords latéraux face à face.
- **Jointes** : `REF_MS_PAROI`, `REF_MS_SECTEUR`, `WORLD_GROUND_GROTTE_01`, `WORLD_GROUND_MASSE_ROCHE_01`, `WORLD_RELIEF_PAROI_PLANCHE`.

### Mont Sélénite : repères et objets

#### WORLD_PROP_GROTTE_PLANCHE (vague 2)
- Planche 3 × 2, 1 case = 150 px, lumière NE (le profil de grotte assombrit) :

| Élément | Grille | Emprise | Taille en jeu |
|---|---|---|---|
| `prop_colonne_grotte_01` | colonne `K` du carrefour 1F (29..30, 24..26) | 2 × 3 | 192 × ≈ 230 px |
| `prop_colonne_grotte_02` | 4 colonnes `K` du B2F ((23, 8), (28, 8), (23, 12), (28, 12)) | 1 × 1 | 96 × ≈ 154 px |
| `prop_rocher_grotte_01/02` | rochers `o` des trois étages (miroir pour varier) | 1 × 1 | 96 × ≈ 70 px |
| `prop_eclats_lune_01/02` | éclats `*` (1F (43, 30), (57, 30..31), (49, 40), (53, 40) ; B1F (25, 18), (27, 18), (23, 21) ; B2F (5, 3), (7, 3), (2, 6)) | 1 × 1 | 96 × ≈ 96 px |

- Règles `{"width": n, "depth": n}`, contact 0,15. Les éclats ont leur propre éclat peint ; leur halo bleuté est un `LightGlow` du moteur (§2.4). **Jointes** : `REF_MS_COLONNE`, `REF_MS_COLONNES`, `REF_MS_ROCHER`, `REF_MS_ECLATS`, `WORLD_GROUND_GROTTE_01`, `WORLD_PROP_ROCHER_01`.

#### WORLD_PROP_MARE_GROTTE_01 → `prop_mare_grotte_01` (vague 2)
- Mare `w` du secteur nord du 1F (47..50, 4..6), 4 × 3, **à plat** (couche du sol, cases bloquées par la grille), sans ombre ni contact. 384 × ≈ 288 px. **Jointes** : `REF_MS_MARE`, souche, arbre A, `WORLD_GROUND_GROTTE_01`.

#### WORLD_DECAL_PUITS_JOUR_01 → `decal_puits_jour_01` (vague 2)
- Puits de jour `j` du 1F : hall (28..31, 39..41) à 4 × 3, fissure du secteur nord (32..33, 8..9) réduite à 2 × 2. Lumière seule (alpha ≤ 0,6 au centre), sur la couche du sol, mode normal ou additif décidé au T9 ; complétée par un `LightGlow` « jour » (§2.4). 384 × ≈ 288 px. **Jointes** : `REF_MS_PUITS`, souche, arbre A, `WORLD_GROUND_GROTTE_01`.

#### WORLD_PROP_ROCKET_PLANCHE (vague 1)
- Planche 3 × 2, 1 case = 150 px :

| Élément | Grille | Emprise | Rôle |
|---|---|---|---|
| `prop_lampe_chantier_01` | `L` : 1F (10, 14) (examinable « Encore tiède ») ; B1F (13, 3), (15, 3), (18, 7), (8, 14), (17, 19) ; B2F couloir (24/27, 20/26) | 1 × 1 | repère + indice ; halo chaud du moteur |
| `prop_caisse_r_01` | `R` isolés (1F (4, 15) ; B2F (16, 33), (34, 30)) | 1 × 1 | caisse au R rouge |
| `prop_caisse_r_02` | `RR` (1F (4..5, 14) ; B1F (14..15, 15) ; B2F (33..34, 29)) | 2 × 1 | deux caisses empilées |
| `prop_tranchee_01` | `F` : 1F (4..6, 27..29) (traces de fouille) ; B1F (4..7, 19..21) × 4/3 | 3 × 3 | fouilles |
| `prop_projecteur_01` | B2F, chambre : 4 coins + 2 sur la dalle ((15, 27), (35, 27), (13, 34), (37, 34), (20, 30), (30, 30)) | 1 × 1 | lumière de la chambre (halo du moteur) |
| `prop_outils_fouille_01` | à côté de R2 (B1F) et dans le camp du B2F, sur des cases déjà bloquées | 1 × 1 | habillage |

- Caisses et lampes **restent** après le départ des Sbires (dossier 15 §8.4). R rouge = seul emblème (B-7). Règles `{"width": 1|2|3, "depth": 1|3}`, contact 0,15. **Jointes** : `REF_MS_CAISSES`, `REF_MS_LAMPE`, `REF_MS_FOUILLE`, `REF_MS_TRANCHEE`, `REF_MS_PROJECTEUR`, `WORLD_PROP_CAISSES_01`, `WORLD_PROP_TONNEAU_01`.

#### WORLD_PROP_ECHELLES_PLANCHE → `prop_echelle_descend_01` (`V`), `prop_echelle_monte_01` (`U`) (vague 1)
- `V` : puits carré bordé de planches d'où sort le haut d'une échelle (≈ 1,2 case de haut) ; `U` : échelle dressée contre la paroi, ≈ 2 cases, le haut dans un trou sombre. Cases : 1F A (7, 9), B (31, 2), C (51, 41), D (57, 8) ; B1F A (4, 1), B (35, 4), C (35, 28) ; B2F D (46, 2), sortie (11, 29). Les échelles sont des warps `STEP_ON` (§1.3 n° 3) : le décor ne bloque pas leur case. 96 × ≈ 115 / 192 px, contact 0. **Jointes** : `REF_MS_ECHELLE_V`, `REF_MS_ECHELLE_U`, `WORLD_PROP_ROCHER_01`. **À vérifier au T9** : une `V` posée dans le mur au **sud** d'une salle (1F C (51, 41)) se lit de dos — capture.

#### WORLD_PROP_DALLE_FOSSILES_PLANCHE → `prop_dalle_01`, `prop_fossile_dome_01`, `prop_fossile_nautile_01` (vague 2)
- Dalle `S` (24..26, 31), 3 × 1, basse (≈ 0,4 case), pinceaux au bout ; fossiles posés sur (24, 31) et (26, 31) (0,6 case de large), **mêmes formes que les icônes du Sac** (objets officiels, §1.3 n° 7) ; le fossile choisi disparaît de la dalle, puis l'autre quand le chercheur le prend (T25). Règle de la dalle `{"width": 3, "depth": 1}` ; fossiles = scènes d'objet `object/fossil_dome`, `object/fossil_helix` (T6), contact 0,1. **Jointes** : `REF_MS_DALLE` (forme de la dalle seulement), `UI_OBJETS_J12_PLANCHE` (vague 1), `WORLD_PROP_ROCHER_01`.

#### WORLD_PROP_INDICES_PLANCHE → `prop_indice_caillou_01`, `prop_indice_eclat_01` (vague 3)
- Indices **discrets** des objets cachés (B-10, Q-2 : point d'examen sur la case de l'indice, aucun scintillement) : caillou beige rosé plus clair et plus lisse que les rochers (Route 3 (36, 18), Réveil) ; petit éclat terne à demi enfoncé dans un caillou d'ardoise (1F (57, 19), Réveil ; B2F (36, 12), Pierre Lune), **plus petit et plus terne** que les éclats `*` (pour ne pas être confondu avec un repère). Disparaissent une fois l'objet trouvé (défaut du plan §6). 1 case bloquée ; ≈ 67 et 58 px de large, contact 0,2. **Jointes** : `WORLD_PROP_GROTTE_PLANCHE` (vague 2, à ne pas copier), `WORLD_PROP_ROCHER_01`, `WORLD_PROP_PIERRES_01`.

### Personnages (marche puis attente)

Modèle commun : planche de marche 4 × 4 (1024 × 1536, ligne 1 face, 2 gauche, 3 droite, 4 dos), héros validé joint, « ne ressemble pas au héros » ; planche d'attente 4 × 1 (1536 × 1024), calée sur la marche jointe. Préparation (T6) : sections `personnages` / `attentes` ; looks en fin de `build_character_frames.gd`.

| Fiche | Hauteur | Tenue (défaut, règle 4) | Attente | Jointes |
|---|---|---|---|---|
| `PNJ_FILLETTE` → `fillette` (`lass_young`) | 108 px | ci-dessus | pieds joints, mains dans le dos | `REF_R3_FILLETTE` |
| `PNJ_SBIRE_ROCKET_H` → `sbire_h` (`rocket_grunt_m`) | 128 px | homme ≈ 25 ans, mince, l'air froid et attentif, cheveux noirs courts, rasé ; `UNIFORME` | pieds joints, **mains dans le dos**, regard de guetteur (R1 et R3 ; R3 se distingue par sa place, sa niche entre les lampes et sa scène, pas par la tenue ni par une seconde attente) | `REF_MS_GUETTEUR`, `REF_MS_GARDIEN` |
| `PNJ_SBIRE_ROCKET_F` → `sbire_f` (`rocket_grunt_f`) | 124 px | femme ≈ 25 ans, cheveux brun foncé en courte queue de cheval, aucune mèche colorée ; `UNIFORME` + genouillères, manches retroussées, petite pioche à la ceinture | **« en train de creuser »** : un genou à terre, buste penché, deux mains sur la pioche dont la pointe gratte le sol, casquette baissée (≈ 75 % de la hauteur debout, même échelle) ; une image par direction, comme toutes les attentes (`IDLE_COLUMNS`) ; à la détection (`!`) elle passe en marche, debout | `REF_MS_FOUILLEUSE`, **`PNJ_SBIRE_ROCKET_H`** (vague 1) |
| `PNJ_CHERCHEUR_FOSSILES` → `chercheur_fossiles` (`fossil_researcher`) | 128 px | Gaspard, ≈ 35 ans, scientifique de terrain : cheveux en bataille, barbe naissante, lunettes rondes, casque colonial beige poussiéreux, gilet sable à poches sur chemise bleu pâle, pantalon brun, sacoche de cuir en bandoulière, brosse et marteau de géologue ; **pas de blouse** (≠ chercheurs du Musée et du labo), **pas de gros sac** (≠ Montagnard, Randonneuse) | pieds joints, main droite sur la sangle de la sacoche, sur ses gardes | `REF_MS_CHERCHEUR` |

Noms de fichiers d'attente nouveaux (`FILLETTE_ATTENTE.txt`, `SBIRE_ROCKET_H_ATTENTE.txt`, `SBIRE_ROCKET_F_ATTENTE.txt`, `CHERCHEUR_FOSSILES_ATTENTE.txt`) : `CHERCHEUR_ATTENTE.txt` (chercheur du labo) n'est pas touché. **Point T6** : l'attente « creuse » est plus basse que la marche ; si `build_character_frames.gd` exige la même hauteur de cellule que la marche (contrôle `idle_cell.y != walk_cell.y`), `preparer.py` la cale au pied dans une cellule de la hauteur de la marche.

### Icônes du Sac

#### UI_OBJETS_J12_PLANCHE → `assets/ui/items/moon_stone.webp`, `escape_rope.webp`, `dome_fossil.webp`, `helix_fossil.webp` (vague 1)
- Planche 1536 × 1024 transparente, 4 icônes ≈ 280 px dans des colonnes de 384 px, rendu `RENDU` du Menu (série 10) : **Pierre Lune** (celle de la vitrine du Musée), **Corde Sortie** (écheveau de chanvre beige noué), **Fossile Dôme** et **Fossile Nautile** fidèles aux objets officiels (et aux vitrines du Musée). Identifiants = ceux des grilles (`item=`), indicatifs jusqu'aux données du T12.
- **Préparation (T6)** : `preparer_menu.py` ne lit aujourd'hui qu'une planche (`OBJETS`, `OBJETS_IDS`) ; ajouter la seconde planche **en fin** (même découpe `_bandes`, 256 px, WebP) : ordre `serie14.ICONES_IDS`. **Jointes** : `MENU_OBJETS_PLANCHE_r1`, `INT_MUSEE_PLANCHE_NE_r1`.

### Conditionnels (prompts prêts, non lancés)

- `WORLD_PROP_AFFLEUREMENTS_PLANCHE` : 4 amas de rochers 3 × 2 (2 beige chaud, 2 gris bleuté), raccordables, pour les blocs `R` (ex. 45..57 × 11..17). Jointes : `REF_R3_AFFLEUREMENT`, `REF_R3_PAROI_SUD`, rocher, grande pierre.
- `WORLD_RELIEF_BOUCHE_SAS_01` : bouche vue de côté, 3 × 4, ouverture d'une case vers l'est, bord ouest du sas. Jointes : `REF_R3_ENTREE`, souche, arbre A, `WORLD_RELIEF_ENTREE_GROTTE_01`, ardoise.
- `UI_ITEM_CT` : disque de CT générique sans chiffre (le numéro est affiché par l'interface), 1024². Jointe : `MENU_OBJETS_PLANCHE_r1`.

## T2 — commandes de génération

**En une fois** (sur le Mac ; trois générations à la fois, vague 1, puis 2, puis 3 ; une image déjà présente n'est pas refaite ; les conditionnels ne partent pas) :

```bash
python3 tools/art/serie14.py --prompts     # sans effet si les prompts versionnés sont à jour
ART=/Users/kevinyankam/dev/kanto-2026/build/art python3 tools/art/serie14.py
python3 tools/art/serie14.py --planche     # planche de contrôle du kit, à côté des images
```

**Image par image** : `python3 tools/art/serie14.py --commandes` imprime les 23 commandes `tools/art/generer.sh` (+ 3 conditionnelles), à lancer **depuis la racine du checkout principal** après `ART=/Users/kevinyankam/dev/kanto-2026/build/art python3 tools/art/serie14.py --refs`. Une correction = copier le prompt en `_r2`, le corriger, relancer la commande avec le nom `_r2`. **Repli** si Codex refuse (Sbires Rocket, fossiles officiels) : coller le prompt dans l'app ChatGPT avec les mêmes images jointes (précédent de la série 09), ranger l'image sous le même nom dans `build/art`.

**Après la génération** : relecture contre les vues et `MS_KIT_v1.png` (la Sbire ♀ porte-t-elle exactement l'uniforme du ♂ ? le R est-il le seul emblème ? les gravats se distinguent-ils du sol calme en niveaux de gris ?), planche de contact `build/captures/jalon12_assets/` présentée à Kevin (**12.0-art**). **Pas** de `manifeste.json`, `preparer.py`, `preparer_menu.py` ni scène au T2 (T6 : `serie14.py --manifeste`, entrées **en fin** de sections, puis `serie14.py --controle`).

## Journal de la série 14

- **T1 (2026-10-11)** : liste du kit (23 images + 3 conditionnels), fiches, 26 prompts versionnés, commandes, planche de contrôle `build/art/MS_KIT_v1.png` relue. Grilles non modifiées. Aucune image générée.
- **T2** : _à remplir (images, essais `_r2`, refus éventuels de Codex, décision de Kevin)._
- **T6** : _à remplir._
