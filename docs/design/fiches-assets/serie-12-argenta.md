# Série 12 — Argenta et Route 2 nord (jalon 10, lumière NE)

> **Validé par Kevin le 2026-10-08 (10.0)** : les 23 images `_r1` générées au T2 (dans `build/art` du checkout principal ; planche de contact `build/art/AR_KIT_GENERE_v1.png`), sans nouvel essai. Intégration au T10, après la fusion du J9.

> Rédigée au **J10 T1** (2026-10-07, architecte, branche `j10-t1-kit`). Plan : `docs/tech/jalon-10.md` §1.3 (grilles), §1.4 (kit) ; conception : `docs/design/dossier-12-argenta.md` (verrouillé). Fichier **nouveau** (la fiche des séries 01–11, `serie-01-place-jadielle.md`, est modifiée par le J9). **Aucune image générée au T1** : génération au **T2** (Mac, Codex), validation de Kevin sur la planche de contact (**10.0**), intégration au **T10** (après le J9 : manifeste, `preparer.py`, règles, scènes).

**Consigne de Kevin (J8, J9)** : le plus petit kit modulaire qui produit la **sensation** de la vue validée dans Godot, sans répétition visible.
- **DA et composition** : `reference/argenta-vue-generale-v1.png` (essai 2). **Géométrie, qui fait foi** : `reference/argenta-plan-v1.png`, tiré des grilles `tools/plans/argenta.txt` et `route_2_nord.txt` (corrigées au T1), plus les grilles d'intérieurs `argenta_arene.txt`, `argenta_musee.txt`, `argenta_musee_science.txt` ; toutes contrôlées par `python3 tools/art/plan_check_argenta.py` (vert au T1). Les emprises des bâtiments sont dans `plan_check_argenta.EMPRISES`, source unique reprise par `serie12.py`.
- **Outil** : `tools/art/serie12.py` (`--prompts`, `--refs`, `--commandes`, `--planche`, `--manifeste` réservé au T10, génération en deux vagues). **Un prompt versionné par image** : `tools/art/prompts/serie12/<NOM>.txt` et, pour les attentes, `tools/art/attente/prompts/<NOM>_ATTENTE.txt` (écrits par `--prompts` depuis les tables du script : on corrige la table, on relance `--prompts`, on relit le diff).
- **Prompts** : ADN visuel v1 (cahier §1.3) + LUMIÈRE NE + fiche ; planches de marche sur le modèle `PNJ_MARCHAND_NE_r1` (héros validé joint), attentes sur le modèle des séries 10–11, Racaillou au format « Pokémon fixe » du J9 (4 poses : repos et réaction, face et profil gauche). Interdits répétés dans chaque prompt : texte, lettres, logo (sauf l'emblème demandé), faune non-Pokémon, Pikachu et tout Pokémon non demandé, personnage qui ressemble au héros (casquette rouge, t-shirt blanc, sac jaune). **Racaillou est le seul nouveau Pokémon du monde** (dossier 12 §6) ; Pierre est décrit **calme, pas arrogant** (ni bras croisés ni sourire moqueur).
- **Références** : recadrages `REF_AR_*` de la vue (`serie12.py --refs`, boîtes versionnées, agrandies × 3) : forme, matériaux, couleurs — jamais le rendu (la vue est en golden hour, les assets en lumière neutre). Ancres de style : assets validés des séries précédentes dans `build/art` du checkout principal (souche, arbre A, façade du poste, maison A, labo, Arène de Jadielle, grande pierre, rocher, falaise, coques du Centre / labo / maison du rival, vitrine à Poké Balls, étagère du labo, héros, Rattata).
- **Planche de contrôle** (sans Codex) : `python3 tools/art/serie12.py --planche` → `build/art/AR_KIT_v1.png` (1 case = 48 px, héros à l'échelle) : réutilisés, variations, nouveaux (référence recadrée à la taille en jeu), conditionnels, abandonnés.

## Corrections de grille (T1, défauts de la règle 4)

| Grille | Correction | Pourquoi |
|---|---|---|
| `argenta.txt` | panneau « ARGENTA » (16, 40) → **(16, 42)**, sur l'herbe, lu depuis l'avenue (17, 42) tourné ← | il était sur la rue et sur la routine de la visiteuse (`jalon-10.md` §0.2 n° 6) |
| `argenta.txt` | Centre `C` 9 × 6 → **8 × 7** (22..29, 33..39), porte **(25..26, 39)** | `bldg_centre_01` : `width` 8, porte = les deux cases `open` (−1, 0), (0, 0) ; l'image fait 768 × 662 px (6,9 cases) : l'emprise de la grille couvre toute l'image, toit compris, toute bloquée (comme les jardins derrière le Centre de Jadielle) |
| `argenta.txt` | Boutique `O` 8 × 6 → **8 × 7** (26..33, 25..31), porte **(29..30, 31)** ; chemin prolongé en (30, 32) | même règle (`bldg_boutique_01`, 768 × 664) ; la rue (rangée 32) dessert les deux cases de la porte ; la rangée 33 du chemin passe sous le toit du Centre (rangée 33 = Centre) |
| `argenta.txt` | (49, 24) et (49, 28) en forêt `T` | sinon on contournait le garde par le nord ou le sud du passage est : les trois cases (48, 25..27) deviennent le seul accès à la sortie est |
| `argenta.txt` + `route_2_nord.txt` | raccord : seules les **3 cases du chemin** sont praticables sur la rangée 43 d'Argenta et la rangée 0 de la Route 2 nord (herbe de bordure → forêt) | règle de l'entrée de la Route 2 sud (`plan_check.py`, critère 6) ; les deux bords se raccordent case pour case (décalage 3) |
| `argenta.txt` | positions ajoutées : `arrivee` (17..19, 42, déclencheur silencieux), `verrou_route_3` (48, 25..27), `garde_route_3_apres` (48, 23, Q-2) ; portes du Centre et de la Boutique sur 2 cases | `jalon-10.md` §2.10, §2.11 |
| `route_2_nord.txt` | positions : `arrivee_poste` (15, 20) ; commentaires (poste vu du nord, Potion « petit détour à l'ouest, hors herbes ») | — |

Plan régénéré (`plan_aplats.py --empiler … 3`) et copié dans `reference/argenta-plan-v1.png` (même nom : la vue générale reste valable, pas de nouvel essai). Le plan de la Route 2 sud (`route_2.txt --lisiere`) reste identique au pixel à `route-2-plan-v2.png` (vérifié ; `plan_aplats.py` / `plan_grille.py` non modifiés).

**Grilles des intérieurs (nouvelles)** : `argenta_arene.txt` (15 × 11, le tracé du plan §1.3 ; `X` = sortie praticable au mur du bas), `argenta_musee.txt` et `argenta_musee_science.txt` (15 × 10, convention de `build_painted_interiors.gd` : mur du fond sur 3 rangées, colonnes 0 et 14, paillasson sur l'avant-dernière rangée ; arche nord de 3 cases ouverte dans la salle principale, fermée par la porte du laboratoire dans la salle science). Pas de grille pour les maisons (une coque 15 × 10 et les meubles de Bourg Palette, posés au T13).

**Résultat du contrôle** (`plan_check_argenta.py`, 2026-10-07) : **toutes les grilles conformes**. Chiffres : Route 2 nord, porte du poste → bord nord **20 pas** (≈ 5 s à la marche, Q-4) ; H1 et H2 évitables, seules ou ensemble ; Potion par (4, 2) hors herbes, détour de 21 pas ; rien d'atteignable à l'est des éboulis. Argenta : portes du Musée 12 pas, Centre 10, Boutique 22, Arène 48, maisons 34 et 50 ; le Musée occupe **52 à 65 %** de son emprise dans le cadre à l'arrivée (porte comprise) ; sortie est à 48 pas, seulement par (48, 25..27). Arène : caméra immobile ; Pierre à 6 pas par le chemin direct (dans la vision de Liam), **12 pas** par le détour à l'est ; l'approche de Liam (arrêt de (2, 6) à (6, 6)) ne ferme aucun passage.

## Liste du kit

**A. Réutilisés tels quels** (`jalon-10.md` §1.4 A) : sols (`ground_herbe_01`, `ground_chemin_01`, `ground_paves_01`, décalcomanies) ; forêt serrée (`tree_foret_01..08`, `DenseForest` + `Shade` + `ForestFloor`) ; arbres de ville `G` (`tree_a/b/c/e_01`) ; hautes herbes `ground_hautes_herbes_jaune_01` (H1, H2) ; **Centre et Boutique** (`bldg_centre_01`, `bldg_boutique_01`, même enseigne) et leurs intérieurs (`int_centre_*`, `int_boutique_*`, `int_plante`) ; bancs `n`, panneaux, buissons `x` ; ronces, tronc couché, pierres ; mobilier des maisons et de la salle science (`int_table_repas_01`, `int_grande_etagere_01`, `int_petite_etagere_01`, `int_paillasse_01`, `int_etagere_labo_01`, `int_classeur_01`, `int_bureau_pc_01`, `int_plante`) ; habitants (enfant `kid`, visiteuse `vieille`, vieil habitant `old`, jeune Dresseuse `lass`, employé du Musée `courier`, chercheurs `researcher` + `chercheuse`, compagne `maya`, garde `guard` du J9 ; jamais deux fois le même modèle sur une carte) ; Pokémon en combat = artworks officiels (Racaillou, Onix, Sabelette).

**B. Variations sans nouvel asset** : gros rocher de la Route 2 nord = `prop_grande_pierre_01` × 0,75 en miroir ; éboulis `E` = `prop_rocher_01` × 2 + `prop_pierres_01` assombris ; forêt un peu plus sèche (`Shade`, valeur × 0,95, rouge × 1,02) ; fleurs rares (`decal_fleur_1`, `_3`, `_5`) ; buissons en miroir, teinte ± 8 % ; pots de fleurs et caisses autour du Centre et de la Boutique ; la même maison deux fois (40 colonnes d'écart, jamais à l'écran ensemble).

**C. Nouveaux : 23 images** (fiches ci-dessous) — 13 en vague 1, 10 en vague 2 (elles joignent une image de la vague 1).

| Fiche → asset | Rôle | Emprise / taille | Images |
|---|---|---|---|
| `WORLD_BLDG_MUSEE_ARGENTA_01` → `bldg_musee_argenta_01` | Musée, repère n° 1 | 12 × 9 | 1 |
| `WORLD_BLDG_ARENE_ARGENTA_01` → `bldg_arene_argenta_01` | Arène-forteresse, repère n° 2 | 12 × 7 | 1 |
| `WORLD_BLDG_MAISON_ARGENTA_01` → `bldg_maison_argenta_01` | les deux maisons | 7 × 6 | 1 |
| `WORLD_RELIEF_PAROI_PLANCHE` → `relief_paroi_01..04` | paroi de montagne, repère n° 3 | 4 modules ≈ 4 × 3 | 1 |
| `WORLD_PROP_ROCHER_PLACE_01` → `prop_rocher_place_01` | gros rocher de la place, repère n° 4 | 3 × 3 | 1 |
| `WORLD_PROP_BLOCS_TAILLES_01` → `prop_blocs_tailles_01` | chantier du tailleur | 3 × 2 | 1 |
| `WORLD_BLDG_POSTE_FORET_NORD_01` → `bldg_poste_foret_nord_01` | poste vu du nord, porte en haut | 7 × 3 | 1 |
| `PNJ_PIERRE` + `PIERRE_ATTENTE` → `pierre` | le Champion | 128 px | 2 |
| `PNJ_TAILLEUR` + attente → `tailleur` | habitant n° 1 | 128 px | 2 |
| `PNJ_MONTAGNARD` + attente → `montagnard` | Route 2 nord | 132 px | 2 |
| `PNJ_CAMPEUR` + attente → `campeur` | Campeur Liam | 112 px | 2 |
| `PNJ_GUIDE_ARENE` + attente → `guide_arene` | guide, réutilisé dans les 8 Arènes | 128 px | 2 |
| `POKE_RACAILLOU_FIXE` → `racaillou` | Racaillou du tailleur | 56 px | 1 |
| `INT_MUSEE_COQUE` → `int_musee_coque` | les deux salles du Musée | 15 × 10 | 1 |
| `INT_MUSEE_PLANCHE` → 6 meubles | vitrines, porte du labo, panneau | 1 à 3 cases | 1 |
| `INT_ARENE_COQUE` → `int_arene_coque` | salle de l'Arène | 15 × 11 | 1 |
| `INT_ARENE_ROCHERS_PLANCHE` → 3 rochers | piliers et rochers `R` | 2 × 1, 2 × 2, 1 × 1 | 1 |
| `INT_MAISON_ARGENTA_COQUE` → `int_maison_argenta_coque` | les deux maisons | 15 × 10 | 1 |

**D. Abandonnés** (dossier 12, « Vue générale peinte v1 », et T1) : décrochement du chemin de la Route 2 nord et poste décalé (chemin droit) ; façade du poste vue de face (porte en haut de l'emprise) ; **tenue du Montagnard de la vue** (chapeau de paille et sac orange = la Randonneuse de la Route 2 : tenue neuve) ; bancs et caisses au-delà de la grille ; personnages placés par la vue.

**Conditionnels** (prompts prêts, jamais lancés par défaut) : `WORLD_PROP_EBOULIS_01` (si les rochers assombris ne se lisent pas comme un sentier bloqué, capture du T11) ; `WORLD_PROP_ROCHER_ROUTE2N_01` (si la grande pierre réduite fait doublon visible) ; `UI_BADGE_ROCHE` (seulement si Kevin demande une image du badge ; sinon l'emblème existant en ACCENT).

## Fiches

Pour chaque asset : rôle, emprise (cases de la grille), taille en pixels du jeu (1 case = 96 px), ancrage et règle `PaintedPropRules` prévue (T10), ce qui est réutilisé au lieu d'être produit, images jointes. Hauteurs, tenues et emprises = **valeurs par défaut** (règle 4). Le prompt complet est dans le fichier indiqué.

### Décors (vague 1)

#### WORLD_BLDG_MUSEE_ARGENTA_01 → `bldg_musee_argenta_01`
- **Rôle** : le plus grand bâtiment, repère n° 1, visible dès l'arrivée (arbitrage 10) ; pierre claire, toit de tuiles brun chocolat, portique à 4 colonnes, double porte.
- **Emprise** : `M` 12 × 9, cases (3..14, 31..39), toit compris ; porte 2 cases (8..9, 39) = colonnes 6 et 7. **Taille** : 1 152 px de large (`axe w`, `cases 12`), ≈ 864 px de haut. **Ancrage** : pied au milieu du bas, sur le bord de case (largeur paire) : ancre (9, 39) ; règle `{"width": 12, "depth": 9, "shadow": true, "fade": true, "open": [(-1, 0), (0, 0)]}`.
- **Réutilisé à la place** : pots de fleurs, panneau (`prop_panneau_01`), parvis en pavés (masque R). **Jointes** : `REF_AR_MUSEE`, ancres `WORLD_PROP_SOUCHE_01`, `WORLD_TREE_A_01`, `WORLD_BLDG_LABO_01` (grand bâtiment), `WORLD_BLDG_POSTE_FORET_01` (pierre). Prompt : `tools/art/prompts/serie12/WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1.txt`.

#### WORLD_BLDG_ARENE_ARGENTA_01 → `bldg_arene_argenta_01`
- **Rôle** : Arène-forteresse adossée à la paroi, repère n° 2 ; pierre grise, ardoises, piliers d'angle, médaillon octogonal (seul emblème), rochers pris dans la maçonnerie aux coins arrière. `bldg_arene_01` reste celle de Jadielle.
- **Emprise** : `Z` 12 × 7, (30..41, 5..11) ; porte 2 cases (35..36, 11). **Taille** : 1 152 × ≈ 672 px. **Ancrage** : (36, 11), règle `{"width": 12, "depth": 7, "shadow": true, "fade": true, "open": [(-1, 0), (0, 0)]}`.
- **Réutilisé** : panneau de l'Arène (`prop_panneau_01`, (39, 12)), pavés du parvis. **Jointes** : `REF_AR_ARENE`, souche, arbre A, `WORLD_BLDG_ARENE_01` (à ne pas copier), poste. Prompt : `…/WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.txt`.

#### WORLD_BLDG_MAISON_ARGENTA_01 → `bldg_maison_argenta_01`
- **Rôle** : les deux maisons (tailleur à l'ouest, chercheuse à l'est) ; pierre claire, tuiles rouge-orangé, cheminée à gauche ; rien de personnel.
- **Emprise** : `m` 7 × 6, (3..9, 15..20) et (43..49, 15..20) ; porte 1 case au milieu (6, 20) et (46, 20). **Taille** : 672 × ≈ 576 px. **Ancrage** : largeur impaire, pied au milieu d'une case : ancres (6, 20) et (46, 20) ; règle `{"width": 7, "depth": 6, "shadow": true, "fade": true, "open": [(0, 0)]}`.
- **Réutilisé** : la même image deux fois (jamais à l'écran ensemble). **Jointes** : `REF_AR_MAISON`, souche, arbre A, `WORLD_BLDG_MAISON_A_01`. Prompt : `…/WORLD_BLDG_MAISON_ARGENTA_01_NE_r1.txt`.

#### WORLD_RELIEF_PAROI_PLANCHE → `relief_paroi_01..04`
- **Rôle** : la montagne, repère n° 3 : bandeau `K` du nord d'Argenta (rangées 0..4) et bloc rocheux de la Route 2 nord (19..29, 0..13). `relief_falaise_01` est une falaise basse de terrasse, pas une montagne.
- **Planche** 1536 × 1024, 2 × 2 modules d'≈ 4 × 3 cases : 01 face A, 02 face B (raccord bout à bout avec 01), 03 extrémité gauche en gradins (miroir = extrémité droite), 04 dessus de massif raccordable (intérieur des blocs `K`). **Taille en jeu** : 288 px de haut chacun (≈ 384 px de large). **Préparation** (T10) : section `planches_arbres` de `preparer.py` (coupe la plus vide, hauteur fixée). **Ancrage** : couche du sol ou entités selon la capture du T11 ; cases `K` bloquées par la carte (`traversable`), comme les murets de Jadielle.
- **Jointes** : `REF_AR_PAROI`, `REF_AR_RELIEF_ROUTE`, `WORLD_RELIEF_FALAISE_01`, `WORLD_PROP_ROCHER_01`. Prompt : `…/WORLD_RELIEF_PAROI_PLANCHE_NE_r1.txt`.

#### WORLD_PROP_ROCHER_PLACE_01 → `prop_rocher_place_01`
- **Rôle** : gros rocher au centre de la place, repère n° 4, autour duquel joue l'enfant. Granit gris clair grenu, arrondi, plus haut et plus massif que la grande pierre lisse de la Route 2.
- **Emprise** : `R` 3 × 3, (25..27, 17..19). **Taille** : 288 × ≈ 250 px (3 cases × 2,6). **Ancrage** : (26, 19), largeur impaire ; règle `{"width": 3, "depth": 3}`, sans ombre portée, contact 0,15.
- **Réutilisé** : l'îlot d'herbe sous le rocher = sol (masque), pas l'image. **Jointes** : `REF_AR_ROCHER_PLACE`, souche, arbre A, `WORLD_PROP_GRANDE_PIERRE_01` (à ne pas copier). Prompt : `…/WORLD_PROP_ROCHER_PLACE_01_NE_r1.txt`.

#### WORLD_PROP_BLOCS_TAILLES_01 → `prop_blocs_tailles_01`
- **Rôle** : chantier du tailleur (piles de blocs taillés, maillet, ciseau, chevalet).
- **Emprise** : `k` 3 × 2, (3..5, 23..24). **Taille** : 288 × ≈ 154 px. **Ancrage** : (4, 24) ; règle `{"width": 3, "depth": 2}`, contact 0,2.
- **Réutilisé** : `prop_pierres_01` (éclats) autour si besoin. **Jointes** : `REF_AR_BLOCS`, souche, arbre A, `WORLD_PROP_ROCHER_01`. Prompt : `…/WORLD_PROP_BLOCS_TAILLES_01_NE_r1.txt`.

#### WORLD_BLDG_POSTE_FORET_NORD_01 → `bldg_poste_foret_nord_01`
- **Rôle** : le poste nord de la forêt vu depuis la Route 2 nord : toit d'ardoises vu de dessus, petit avant-corps d'entrée au bord **haut** (porte vers le nord), bas de l'image coupé net (le reste est hors de la carte). Écart n° 7 du plan : aucune image existante ne montre le poste depuis le nord.
- **Emprise** : `P` 7 × 3, (12..18, 21..23) ; porte (15, 21) = 4e colonne de la rangée du **haut** (STEP_ON ↓). **Taille** : 672 × ≈ 288 px. **Ancrage** : (15, 23), largeur impaire ; règle `{"width": 7, "depth": 3, "fade": false, "open": [(0, -2)]}` (porte au bord haut ; pas d'ombre portée : le bâtiment continue sous le bord de la carte).
- **Réutilisé** : matériaux de `bldg_poste_foret_01` (même bâtiment). **Jointes** : `REF_AR_POSTE` (matériaux seulement), souche, arbre A, `WORLD_BLDG_POSTE_FORET_01`. Prompt : `…/WORLD_BLDG_POSTE_FORET_NORD_01_NE_r1.txt`. **Risque** : lecture de la porte vers le nord ; capture du T11.

### Personnages (marche en vague 1, attente en vague 2)

Modèle commun : planche de marche 4 × 4 (1024 × 1536, ligne 1 face, 2 gauche, 3 droite, 4 dos), héros validé joint (`PERSO_P2_PEINT_r1`), « ne ressemble pas au héros » ; puis planche d'attente 4 × 1 (1536 × 1024, pieds joints), calée sur la marche jointe. Préparation (T10) : sections `personnages` / `attentes` existantes ; apparences dans `build_character_frames.gd`.

| Fiche | Hauteur | Tenue (défaut, règle 4) | Référence jointe | Prompts |
|---|---|---|---|---|
| `PNJ_PIERRE` → `pierre` (`brock`) | 128 px | fidèle à Rouge/Bleu : peau hâlée, cheveux brun foncé en épis, yeux plissés, gilet vert olive sur t-shirt orange brique, pantalon brun ; **calme, jamais arrogant** (ni bras croisés ni sourire moqueur) ; attente : bras le long du corps | aucune (absent de la vue) | `serie12/PNJ_PIERRE_NE_r1.txt`, `attente/prompts/PIERRE_ATTENTE.txt` |
| `PNJ_TAILLEUR` → `tailleur` (`stonemason`) | 128 px | **tenue de la vue** : cheveux bruns courts, rasé, chemise blanche retroussée, long tablier de cuir brun, gants gris, maillet à la ceinture (≠ Marchand) | `REF_AR_TAILLEUR` (tenue seulement) | `PNJ_TAILLEUR_NE_r1.txt`, `TAILLEUR_ATTENTE.txt` |
| `PNJ_MONTAGNARD` → `montagnard` (`mountaineer`) | 132 px | grand et costaud, barbe brune, bob kaki, chemise à carreaux rouge et brun, pantalon vert olive, gros sac vert sapin à corde ; attente : pouces sous les bretelles. **Écart à la vue** : sa tenue y copie la Randonneuse (paille, sac orange) | aucune (volontairement) | `PNJ_MONTAGNARD_NE_r1.txt`, `MONTAGNARD_ATTENTE.txt` |
| `PNJ_CAMPEUR` → `campeur` (`camper`) | 112 px | garçon d'≈ 12 ans, cheveux noirs en épis **sans couvre-chef**, foulard rouge, chemise de camp beige, short vert olive, sac de couchage roulé (≠ Scout, ≠ héros) | aucune | `PNJ_CAMPEUR_NE_r1.txt`, `CAMPEUR_ATTENTE.txt` |
| `PNJ_GUIDE_ARENE` → `guide_arene` (`gym_guide`) | 128 px | jovial, polo blanc liseré bleu marine, pantalon de survêtement, serviette autour du cou, bouteille d'eau ; **rien qui le rattache à une ville** (8 Arènes) | aucune | `PNJ_GUIDE_ARENE_NE_r1.txt`, `GUIDE_ARENE_ATTENTE.txt` |

**Réutilisés au lieu d'être produits** : tous les autres habitants (§ A) ; le garde de la Route 3 = `guard` du J9.

### Pokémon d'ambiance (vague 1)

#### POKE_RACAILLOU_FIXE → `racaillou` (`pokemon/geodude`)
- **Rôle** : le Racaillou du tailleur, (4, 25), immobile, non capturable, sans dialogue ; `idle_react` toutes les 5 s (`jalon-10.md` §2.12). **Seul nouveau Pokémon du monde au J10.**
- **Format « Pokémon fixe » du J9** (`jalon-09.md` §2.8.5) : planche 1536 × 1024, une ligne de 4 poses : repos de face (mains à plat devant lui), **réaction de face (soulève une pierre au-dessus de sa tête)**, repos profil gauche, réaction profil gauche ; préparation (T10) section `pokemon_fixes` (feuille 6 × 1, droite = miroir), une échelle, **56 px** (hauteur du repos de face).
- **Jointes** : `PERSO_P2_PEINT_r1`, `POKE_RATTATA_P2_r1` (ancres), `REF_AR_RACAILLOU` (couleurs, taille relative). Prompt : `…/POKE_RACAILLOU_FIXE_NE_r1.txt`. **Repli** si Codex refuse : planche faite par Kevin dans l'app ChatGPT (précédent DA.3).

### Intérieurs (vague 2 : ils joignent la façade générée)

#### INT_MUSEE_COQUE → `int_musee_coque` (deux cartes : `pewter_museum`, `pewter_museum_science`)
- **Géométrie** (grilles `argenta_musee*.txt`) : 15 × 10 cases → 1 440 × 960 px ; mur du fond sur 3 rangées (face ≈ 2,5 cases), **arche nord ouverte de 3 cases** au milieu (6..8, 2), entrée sud de 2 cases peinte centrée (sortie = paillasson (6..8, 8)) ; dalles de pierre claire polies, pilastres, deux hautes fenêtres cintrées. La salle science pose la porte du laboratoire dans l'arche.
- **Réutilisé** : `int_plante`, `int_paillasse_01`, `int_etagere_labo_01`, `int_classeur_01` (salle science, au T13). **Jointes** : `INT_CENTRE_COQUE`, `INT_LABO_COQUE` (style, géométrie), `WORLD_BLDG_MUSEE_ARGENTA_01` (matériaux). Prompt : `…/INT_MUSEE_COQUE_NE_r1.txt`.

#### INT_MUSEE_PLANCHE → `int_vitrine_dome_01`, `int_vitrine_nautile_01`, `int_vitrine_pierre_lune_01`, `int_vitrine_journal_01`, `int_porte_labo_01`, `int_panneau_expo_01`
- **Planche** 1536 × 1024, 3 × 2 cellules, échelle commune 1 case = 150 px. Largeurs en jeu : vitrines Dôme et Nautile 2 cases ((2..3, 4), (11..12, 4) de la salle principale), Pierre Lune 1 case sur socle ((7, 5), au centre, qu'on contourne), vitrine du journal 2 cases ((11..12, 4) salle science), porte du laboratoire 3 × ≈ 2,5 cases (remplit l'arche : plaque **vierge** à gauche (6, 2), double porte fermée (7..8, 2) ; deux points d'examen), panneau d'exposition 2 cases ((2..3, 4) salle science, formes abstraites, aucun Pokémon reconnaissable). Textes = points d'examen (textes verrouillés), **jamais peints**.
- **Préparation** (T10) : section nouvelle `planches_objets` (découpe C × L, sur le modèle de `planches_arbres`). Règles : `{"width": 2, "depth": 1}` (vitrines, panneau), `{"width": 1, "depth": 1}` (Pierre Lune), porte posée dans le mur (`traversable`, cases du mur déjà bloquées). **Jointes** : `INT_VITRINE_POKEBALLS_01`, `INT_ETAGERE_LABO_01`, `WORLD_BLDG_MUSEE_ARGENTA_01`. Prompt : `…/INT_MUSEE_PLANCHE_NE_r1.txt`.

#### INT_ARENE_COQUE → `int_arene_coque` (`pewter_gym`)
- **Géométrie** (`argenta_arene.txt`) : 15 × 11 → 1 440 × 1 056 px (Codex 1536 × 1024, étiré par `preparer.py` comme les coques du labo et de la maison du rival) ; paroi du fond sur 2 rangées, parois latérales de 2 cases, mur du bas d'une rangée avec **sortie de 3 cases** (6..8, 10) ; **estrade** de pierre de 3 cases sous le mur du fond (6..8, 2), médaillon octogonal au-dessus ; sol de sable ocre. Pierre (7, 2) est **visible depuis l'entrée** (salle entière à l'écran).
- **Jointes** : `INT_CENTRE_COQUE`, `WORLD_BLDG_ARENE_ARGENTA_01`. Prompt : `…/INT_ARENE_COQUE_NE_r1.txt`.

#### INT_ARENE_ROCHERS_PLANCHE → `int_pilier_roche_01`, `int_rochers_bas_01`, `int_rochers_bas_02`
- **Planche** 1536 × 1024, 3 colonnes, 1 case = 180 px : pilier 2 × 1 (≈ 2,8 cases de haut) aux 4 piliers (2..3, 4), (11..12, 4), (2..3, 8), (11..12, 8) (miroir pour varier) ; bloc bas 2 × 2 au centre (8..9, 6..7) — il arrête la vision de Liam ; rocher 1 × 1 de part et d'autre de l'estrade (6, 2), (8, 2) (miroir). Règles `{"width": 2, "depth": 1}`, `{"width": 2, "depth": 2}`, `{"width": 1, "depth": 1}`.
- **Jointes** : `WORLD_PROP_ROCHER_01`, `WORLD_BLDG_ARENE_ARGENTA_01`. Prompt : `…/INT_ARENE_ROCHERS_PLANCHE_NE_r1.txt`.

#### INT_MAISON_ARGENTA_COQUE → `int_maison_argenta_coque` (`pewter_house_mason`, `pewter_house_researcher`)
- **Géométrie** : 15 × 10 → 1 440 × 960 px, convention du Centre (mur du fond 3 rangées, entrée de 2 cases centrée) ; planches de bois, pierre et enduit, poutres. Une enveloppe, deux mobiliers (arbitrage 14), meubles de Bourg Palette et du labo (§ A).
- **Jointes** : `INT_CENTRE_COQUE`, `INT_MAISON_RIVAL_COQUE`, `WORLD_BLDG_MAISON_ARGENTA_01`. Prompt : `…/INT_MAISON_ARGENTA_COQUE_NE_r1.txt`.

## T2 — commandes de génération

**En une fois** (sur le Mac, depuis cette copie ou le checkout principal ; trois générations à la fois, vague 1 puis vague 2 ; une image déjà présente n'est pas refaite ; les conditionnels ne partent pas) :

```bash
python3 tools/art/serie12.py --prompts     # sans effet si les prompts versionnés sont à jour
ART=/Users/kevinyankam/dev/kanto-2026/build/art python3 tools/art/serie12.py
python3 tools/art/serie12.py --planche     # planche de contrôle, à côté des images
```

**Équivalent image par image** (sortie de `python3 tools/art/serie12.py --commandes` ; à lancer **depuis la racine du checkout principal**, où `generer.sh` écrit `build/art/<NOM>.png` = `$ART`, après `serie12.py --refs` ; une correction = copier le prompt en `_r2`, le corriger, relancer la commande avec le nom `_r2`) :

```bash
ART=/Users/kevinyankam/dev/kanto-2026/build/art
# Vague 1
tools/art/generer.sh WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1 tools/art/prompts/serie12/WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1.txt $ART/REF_AR_MUSEE.png $ART/WORLD_PROP_SOUCHE_01_NE_r1.png $ART/WORLD_TREE_A_01_NE_r1.png $ART/WORLD_BLDG_LABO_01_NE_r1.png $ART/WORLD_BLDG_POSTE_FORET_01_NE_r1.png
tools/art/generer.sh WORLD_BLDG_ARENE_ARGENTA_01_NE_r1 tools/art/prompts/serie12/WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.txt $ART/REF_AR_ARENE.png $ART/WORLD_PROP_SOUCHE_01_NE_r1.png $ART/WORLD_TREE_A_01_NE_r1.png $ART/WORLD_BLDG_ARENE_01_NE_r1.png $ART/WORLD_BLDG_POSTE_FORET_01_NE_r1.png
tools/art/generer.sh WORLD_BLDG_MAISON_ARGENTA_01_NE_r1 tools/art/prompts/serie12/WORLD_BLDG_MAISON_ARGENTA_01_NE_r1.txt $ART/REF_AR_MAISON.png $ART/WORLD_PROP_SOUCHE_01_NE_r1.png $ART/WORLD_TREE_A_01_NE_r1.png $ART/WORLD_BLDG_MAISON_A_01_NE_r1.png
tools/art/generer.sh WORLD_PROP_ROCHER_PLACE_01_NE_r1 tools/art/prompts/serie12/WORLD_PROP_ROCHER_PLACE_01_NE_r1.txt $ART/REF_AR_ROCHER_PLACE.png $ART/WORLD_PROP_SOUCHE_01_NE_r1.png $ART/WORLD_TREE_A_01_NE_r1.png $ART/WORLD_PROP_GRANDE_PIERRE_01_NE_r1.png
tools/art/generer.sh WORLD_PROP_BLOCS_TAILLES_01_NE_r1 tools/art/prompts/serie12/WORLD_PROP_BLOCS_TAILLES_01_NE_r1.txt $ART/REF_AR_BLOCS.png $ART/WORLD_PROP_SOUCHE_01_NE_r1.png $ART/WORLD_TREE_A_01_NE_r1.png $ART/WORLD_PROP_ROCHER_01_NE_r1.png
tools/art/generer.sh WORLD_BLDG_POSTE_FORET_NORD_01_NE_r1 tools/art/prompts/serie12/WORLD_BLDG_POSTE_FORET_NORD_01_NE_r1.txt $ART/REF_AR_POSTE.png $ART/WORLD_PROP_SOUCHE_01_NE_r1.png $ART/WORLD_TREE_A_01_NE_r1.png $ART/WORLD_BLDG_POSTE_FORET_01_NE_r1.png
tools/art/generer.sh WORLD_RELIEF_PAROI_PLANCHE_NE_r1 tools/art/prompts/serie12/WORLD_RELIEF_PAROI_PLANCHE_NE_r1.txt $ART/REF_AR_PAROI.png $ART/REF_AR_RELIEF_ROUTE.png $ART/WORLD_RELIEF_FALAISE_01_NE_r1.png $ART/WORLD_PROP_ROCHER_01_NE_r1.png
tools/art/generer.sh PNJ_PIERRE_NE_r1 tools/art/prompts/serie12/PNJ_PIERRE_NE_r1.txt $ART/PERSO_P2_PEINT_r1.png
tools/art/generer.sh PNJ_TAILLEUR_NE_r1 tools/art/prompts/serie12/PNJ_TAILLEUR_NE_r1.txt $ART/PERSO_P2_PEINT_r1.png $ART/REF_AR_TAILLEUR.png
tools/art/generer.sh PNJ_MONTAGNARD_NE_r1 tools/art/prompts/serie12/PNJ_MONTAGNARD_NE_r1.txt $ART/PERSO_P2_PEINT_r1.png
tools/art/generer.sh PNJ_CAMPEUR_NE_r1 tools/art/prompts/serie12/PNJ_CAMPEUR_NE_r1.txt $ART/PERSO_P2_PEINT_r1.png
tools/art/generer.sh PNJ_GUIDE_ARENE_NE_r1 tools/art/prompts/serie12/PNJ_GUIDE_ARENE_NE_r1.txt $ART/PERSO_P2_PEINT_r1.png
tools/art/generer.sh POKE_RACAILLOU_FIXE_NE_r1 tools/art/prompts/serie12/POKE_RACAILLOU_FIXE_NE_r1.txt $ART/PERSO_P2_PEINT_r1.png $ART/POKE_RATTATA_P2_r1.png $ART/REF_AR_RACAILLOU.png
# Vague 2
tools/art/generer.sh PIERRE_ATTENTE_r1 tools/art/attente/prompts/PIERRE_ATTENTE.txt $ART/PNJ_PIERRE_NE_r1.png
tools/art/generer.sh TAILLEUR_ATTENTE_r1 tools/art/attente/prompts/TAILLEUR_ATTENTE.txt $ART/PNJ_TAILLEUR_NE_r1.png
tools/art/generer.sh MONTAGNARD_ATTENTE_r1 tools/art/attente/prompts/MONTAGNARD_ATTENTE.txt $ART/PNJ_MONTAGNARD_NE_r1.png
tools/art/generer.sh CAMPEUR_ATTENTE_r1 tools/art/attente/prompts/CAMPEUR_ATTENTE.txt $ART/PNJ_CAMPEUR_NE_r1.png
tools/art/generer.sh GUIDE_ARENE_ATTENTE_r1 tools/art/attente/prompts/GUIDE_ARENE_ATTENTE.txt $ART/PNJ_GUIDE_ARENE_NE_r1.png
tools/art/generer.sh INT_MUSEE_COQUE_NE_r1 tools/art/prompts/serie12/INT_MUSEE_COQUE_NE_r1.txt $ART/INT_CENTRE_COQUE_NE_r1.png $ART/INT_LABO_COQUE_NE_r1.png $ART/WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1.png
tools/art/generer.sh INT_ARENE_COQUE_NE_r1 tools/art/prompts/serie12/INT_ARENE_COQUE_NE_r1.txt $ART/INT_CENTRE_COQUE_NE_r1.png $ART/WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.png
tools/art/generer.sh INT_MAISON_ARGENTA_COQUE_NE_r1 tools/art/prompts/serie12/INT_MAISON_ARGENTA_COQUE_NE_r1.txt $ART/INT_CENTRE_COQUE_NE_r1.png $ART/INT_MAISON_RIVAL_COQUE_NE_r1.png $ART/WORLD_BLDG_MAISON_ARGENTA_01_NE_r1.png
tools/art/generer.sh INT_MUSEE_PLANCHE_NE_r1 tools/art/prompts/serie12/INT_MUSEE_PLANCHE_NE_r1.txt $ART/INT_VITRINE_POKEBALLS_01_NE_r1.png $ART/INT_ETAGERE_LABO_01_NE_r1.png $ART/WORLD_BLDG_MUSEE_ARGENTA_01_NE_r1.png
tools/art/generer.sh INT_ARENE_ROCHERS_PLANCHE_NE_r1 tools/art/prompts/serie12/INT_ARENE_ROCHERS_PLANCHE_NE_r1.txt $ART/WORLD_PROP_ROCHER_01_NE_r1.png $ART/WORLD_BLDG_ARENE_ARGENTA_01_NE_r1.png
# CONDITIONNELS — ne pas lancer par défaut
tools/art/generer.sh WORLD_PROP_EBOULIS_01_NE_r1 tools/art/prompts/serie12/WORLD_PROP_EBOULIS_01_NE_r1.txt $ART/REF_AR_RELIEF_ROUTE.png $ART/WORLD_PROP_SOUCHE_01_NE_r1.png $ART/WORLD_TREE_A_01_NE_r1.png $ART/WORLD_PROP_ROCHER_01_NE_r1.png
tools/art/generer.sh WORLD_PROP_ROCHER_ROUTE2N_01_NE_r1 tools/art/prompts/serie12/WORLD_PROP_ROCHER_ROUTE2N_01_NE_r1.txt $ART/REF_AR_ROCHER_ROUTE.png $ART/WORLD_PROP_SOUCHE_01_NE_r1.png $ART/WORLD_TREE_A_01_NE_r1.png $ART/WORLD_PROP_GRANDE_PIERRE_01_NE_r1.png
tools/art/generer.sh UI_BADGE_ROCHE_r1 tools/art/prompts/serie12/UI_BADGE_ROCHE_r1.txt
```

**Après la génération** : relecture contre la vue et `AR_KIT_v1.png`, planche de contact `build/captures/jalon10_assets/` présentée à Kevin (**10.0**). **Pas** de `manifeste.json`, `preparer.py` ni scène au T2 (T10, après le J9 : `serie12.py --manifeste` prépare les entrées, dont deux sections à créer ou à étendre dans `preparer.py` : `pokemon_fixes` (J9) et `planches_objets` (nouvelle)).

## Journal de la série 12

- **T1 (2026-10-07)** : grilles corrigées et contrôlées, fiches, prompts versionnés (23 images + 3 conditionnels), commandes, planche de contrôle. Aucune image générée.
- **T2** : _à remplir (images, essais `_r2`, refus éventuels de Codex, décision de Kevin)._
