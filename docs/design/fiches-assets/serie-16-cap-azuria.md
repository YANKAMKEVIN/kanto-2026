# Série 16 — Route 25, Cap d'Azuria et maison de Léo (jalon 14, lumière NE)

> Rédigée au **J14 T1** (2026-10-12, branche `j14-t1` depuis `jalon-14`). Plan : `docs/tech/jalon-14.md` §1.3, §1.4, §2.2, §2.9 ; conception : `docs/design/dossier-17-cap-azuria.md` (verrouillé le 2026-10-12). Génération au **T2** (Mac, Codex), validation de Kevin sur planche de contact (**14.0-art**), intégration au **T13** (manifeste, `preparer.py`, `preparer_menu.py`, règles, scènes, look `bill`).

**Consigne de Kevin (J8–J13)** : le plus petit kit modulaire qui produit la **sensation** des vues validées dans Godot, sans répétition visible.
- **DA et composition** : `reference/route-25-vue-generale-v1.png`, `maison-leo-v1.png`. **Géométrie, qui fait foi** : `tools/plans/route_25.txt`, `bill_house.txt` (aucune case changée au T1 ; seuls les en-têtes passent de « BROUILLON » à « validée » ; `plan_check_route_25.py` : conforme).
- **Outil** : `tools/art/serie16.py` (`--prompts`, `--refs`, `--ancres`, `--commandes`, `--planche`, `--contact`, `--manifeste` préparé et **non lancé**, `--controle` au T13 ; génération en **deux vagues**). **Un prompt versionné par image** : `tools/art/prompts/serie16/<NOM>.txt`, `tools/art/attente/prompts/LEO_HUMAIN_ATTENTE.txt`, et le décor de combat conditionnel dans `tools/art/combat_decors/prompts/`.
- **Prompts** : ADN visuel v1 + **LUMIÈRE NE** ; aucun nom de licence ; aucun emblème de type balle ; interdits : texte, lettres, logo, faune non-Pokémon (mouettes, crabes), Pikachu, sosie du héros. Les vues sont en golden hour : les prompts demandent explicitement de **ne pas** en reprendre la lumière (le jeu éclaire lui-même).
- **Références** : recadrages `REF_R25_*` et `REF_LEO_*` (boîtes versionnées dans `REFS`, × 3 au plus, 1 536 px max). Ancres copiées par `--ancres` depuis le checkout principal puis les copies du J13 (`j13-t5`, `j13-t1`) pour la série 15.
- **Planche de contrôle** (sans Codex) : `python3 tools/art/serie16.py --planche` → `build/art/R25_KIT_v1.png` (1 case = 48 px, héros à l'échelle). Relue au T1.

## Liste du kit

**A. Réutilisés tels quels** : sols `ground_herbe_01`, `ground_chemin_01`, **`ground_sable_01`** (crique `s`), **`ground_eau_01`** (mer `w`, écume du shader, `square_shore`) ; décalcomanies ; falaise `K` et piliers `R` loin de l'eau : `relief_paroi_01..04` (série 12, même roche beige) ; forêt `T` (`DenseForest`, `tree_foret_*`) ; hautes herbes H1–H4 `ground_hautes_herbes_jaune_01` ; rebord L1 `relief_rebord_01` ; buissons `x` `prop_buisson_*` ; massifs `f` `prop_massif_01`, `prop_hortensias_01`, `prop_platebande_01` ; accents `prop_rocher_mer_01` ; `prop_panneau_01` ; `object/poke_ball_ground` (O1–O3). **Azuria** : `prop_ruban_01` (bande du barrage, ruban de la porte), **`prop_barriere_croisillon_01`** (série 15 : 2 cases de long, exactement les barrières (32..33, 38) ; image de l'objet `police_barrier` au T13). **Intérieur** : `int_lit_01` (L), `int_chevet_lampe_01`, `int_plante` (x), `int_chaise_bureau_01` (chaise (6, 8)), tapis `int_tapis_*`. **Personnages** : `youngster` (Jules, D6), `mountaineer` (D2, D4), `lass_young` (Zoé, J12), `camper` (D5 [D]), `traveler` (promeneur P1), `old_man` (pêcheur P2), `guard` (policiers), `sbire_h` (Rocket, J12) ; **Mélofée de Léo** = planche `POKE_MELOFEE` de la série 14 (J12 T3, sans accessoire, E-4) ; Roucool d'ambiance ; artworks 063, 064, 066 et dos provisoires en combat.

**B. Variations sans nouvel asset** : falaise plus claire au soleil couchant (profil `golden_hour`) ; piliers rocheux en modules de paroi empilés ; massifs en miroir ± 8 % ; bureau de Chen `int_bureau_chen_01` = **repli** du bureau encombré si la planche de Léo est refusée.

**C. Nouveaux : 7 images** (fiches ci-dessous).

| Fiche → asset(s) | Rôle | Taille en jeu | Images | Vague |
|---|---|---|---|---|
| `WORLD_RELIEF_RIVAGE_PLANCHE` → `relief_rivage_01..06`, `prop_indice_coquillage_01`, `prop_cloture_reparee_01` | rivage rocheux (rôles de la grille), indice O4, planche clouée d'Azuria | voir fiche | 1 | 1 |
| `WORLD_BLDG_MAISON_LEO_01` → `bldg_maison_leo_01` | maison du Cap | 8 × 6 | 1 | 1 |
| `INT_MAISON_LEO_PLANCHE` → 6 meubles | cabine (A et B en miroir), console, module, écran, bureau encombré, bibliothèque de côté | 1 à 3 cases | 1 | 1 |
| `PNJ_LEO_HUMAIN` → `leo_humain` (look `bill`) | Léo humain, marche | 128 px | 1 | 1 |
| `UI_OBJETS_J14_PLANCHE` → `ss_ticket.webp`, `rare_candy.webp` | icônes du Sac | 256 px | 1 | 1 |
| `INT_MAISON_LEO_COQUE` → `int_maison_leo_coque` | enveloppe 16 × 11 | 1 536 × 1 056 | 1 | 2 |
| `LEO_HUMAIN_ATTENTE` → `leo_humain_idle` | Léo humain, attente | 128 px | 1 | 2 |

**Écarts au plan §1.4 C (≈ 11 images → 7)**, défauts (règle 4) :
- `WORLD_PROP_INDICE_COQUILLAGE_01` **fusionnée** dans la planche du rivage (cellule 7) ;
- `INT_BUREAU_LEO_01` **fusionnée** dans la planche des meubles de Léo (cellule 5) : la contradiction du plan (« nouveau » et « conditionnel ») disparaît sans image de plus ; repli : bureau de Chen ;
- `UI_ITEM_PASSE_BATEAU` + `UI_ITEM_SUPER_BONBON` → **une** planche de 4 colonnes (chaîne `preparer_menu.py`, `PLANCHES_OBJETS_SUIVANTES`) ;
- `WORLD_PROP_BARRIERE_POLICE_01` → **conditionnel** : la barrière à croisillon de la série 15 a la bonne taille ;
- **ajoutés** dans des cellules libres : `prop_cloture_reparee_01` (la « planche clouée » du §2.12 n'existe pas dans la planche du cambriolage de la série 15, qui n'a que clôture arrachée, porte condamnée, pot, trou, ruban) et `int_bibliotheque_cote_01` (les bibliothèques `b` (1, 6..7) et (14, 6..7) sont adossées aux murs latéraux, 1 × 2 : `int_grande_etagere_01`, de face et 2 cases de large, n'y tient pas).

**D. Abandonnés** : personnages placés par le peintre (Scout de D5 → `camper`, pêcheur, enfant) ; marche d'entrée de la maison (dossier §3) ; flaques de lumière dorée de l'intérieur (lumière NE + éclairage du jeu) ; états peints des cabines (reportés DA, plan §0.2 n° 12) ; poisson / mouette : aucun.

**Conditionnels** (prompts prêts, jamais lancés par défaut ; décision notée dans `etat-projet.md`) : `WORLD_PROP_BARRIERE_POLICE_01` (si le croisillon ne se lit pas comme un barrage de police sur la capture de 14C) ; `COMBAT_DECOR_ROUTE25_COTE_r1` (le dossier ne demande aucun décor de combat : repli = carte floutée ; chaîne `tools/art/combat_decors/`, jointes `combat-v1.webp`, `combat-decors-planche-v1.webp`, vue de la Route 25).

**Contrôle « chaque élément des vues a un asset »** (CA du T1) — *Route 25* : falaise beige → paroi série 12 ; forêt, buissons, fleurs, herbe, chemin de terre → A ; hautes herbes ×4 → A ; piliers rocheux → paroi empilée (B) ; rebord de bois de la terrasse → `relief_rebord_01` ; rivage de blocs (droits, angles) → `relief_rivage_*` ; crique de sable → `ground_sable_01` ; mer turquoise et écume → `ground_eau_01` + shader ; rochers dans l'eau → `prop_rocher_mer_01` ; maison à toit d'ardoise, parabole, cheminée → façade neuve ; massifs entre lesquels elle se tient → massifs A ; panneaux, Poké Balls → A ; Roucool → A ; personnages → modèles A ; massif de buissons ronds de la poche sud-est → buissons `x` (A). *Maison de Léo* : lambris, parquet, grande fenêtre sur la mer → coque neuve ; cabines ×2, armoires électriques → planche (miroir) ; écran, console à bouton rouge, module et tuyaux → planche ; bureau encombré → planche (repli Chen) ; chaise, lit, chevet, plantes, tapis → A ; bibliothèques murales → planche ; tableaux → peints sur la coque ; coffre au pied du lit → abandonné ; marche d'entrée → abandonnée. Rien n'est implémenté parce qu'il est sur une image (règle 10) : la grille décide de la place.

## Alignement sur l'outil côtier (T14, `tools/coast_map_kit.gd` à écrire)

Les modules du rivage sont posés **sur les cases `R` qui touchent la mer** (4-voisinage), jamais sur une case praticable. Décompte de la grille (script du T1) : 218 cases `R` ; **72 « mer au sud »**, **26 « mer à l'est »**, **8 « mer à l'ouest »**, **3 angles sud-est**, **3 angles sud-ouest**, **2 + 2 angles intérieurs** (mer en diagonale seulement), **0 « mer au nord »**, 102 loin de l'eau. Rôles → images :

| Rôle | Image | Taille préparée visée |
|---|---|---|
| mer au sud | `relief_rivage_01` / `02` (variantes à la graine) | 192 × 110 (2 × 1,15 cases) |
| mer à l'est / à l'ouest | `relief_rivage_03` / en miroir | 96 × 192 |
| angle extérieur sud-est / sud-ouest | `relief_rivage_04` / en miroir | 96 × 110 |
| angle intérieur (diagonale sud-est / sud-ouest) | `relief_rivage_05` / en miroir | 96 × 96 |
| `R` loin de l'eau, extrémités | paroi série 12 (défaut du plan) ou `relief_rivage_06` (bloc plein) | 96 × 96 |

Aucun module « mer au nord » : la grille n'en a pas (si une grille future en a, `03` posé à plat ou une correction `_r2`). L'écume reste celle du shader (`foam_strength` de Bourg Palette) ; la ligne d'eau mouillée peinte au pied des blocs fait la jonction. Longueur d'un module = `round(largeur / 96)` cases, lue par l'outil.

## Fiches

Hauteurs et réglages = **valeurs par défaut** (règle 4). Le prompt complet est dans `tools/art/prompts/serie16/<NOM>.txt`.

### Côte

#### WORLD_RELIEF_RIVAGE_PLANCHE → 8 éléments (vague 1)
- Planche 1536 × 1024, **4 × 2 cellules de 384 × 512**, 1 case = 180 px, `planches_objets` (découpe par taches) largeurs `[2, 2, 1, 1, 1, 1, 0.35, 1]`, contact 0, couche du sol (`GroundDecals`) pour les modules, ombre non. Gros blocs de roche beige-gris arrondis, angles droits du module, fine ligne d'eau mouillée côté mer, **ni écume ni eau peintes**. Cellule 7 : **coquillage** nacré (0,35 case) posé sur le pilier `R` (64, 20) de l'objet caché O4 (examiné depuis (64, 19) ↓). Cellule 8 : **clôture réparée** (1 case, deux planches neuves clouées) posée à côté du trou d'Azuria (14, 3) après `cerulean_rocket_beaten` (T20b, décor seul, aucune case ne change). **Jointes** : `REF_R25_RIVAGE`, `REF_R25_RIVAGE_CAP`, `REF_R25_RIVAGE_ANGLE`, paroi série 12, rocher de mer, quais (gabarit), planche du cambriolage (clôture). **Risque** : blocs trop ronds (bords non raccordables) → `_r2` avec « bords droits coupés net ».

#### WORLD_BLDG_MAISON_LEO_01 → `bldg_maison_leo_01` (vague 1)
- Emprise `M` 8 × 6 (68..75, 6..11), porte `D` (71..72, 11) = 4e et 5e colonnes → **porte double de 2 cases** au milieu exact ; `axe w`, `cases 8`, ombre oui, contact 0,12 (comme les maisons). Pierre crème, **toit d'ardoise bleu-gris**, cheminée à droite, **parabole** blanche, fenêtre droite au reflet bleu d'écran discret. Massifs, panneau (69, 12) et chemin posés par la carte. **Jointes** : `REF_R25_MAISON`, souche, arbre A, maisons d'Argenta et A.

### Maison de Léo

#### INT_MAISON_LEO_COQUE → `int_maison_leo_coque` (vague 2, joint la façade)
- 16 × 11 cases, 1536 × 1024 étiré à 1 536 × 1 056 (`pieces`, `cases [16, 11]`). Mur du fond sur **3 rangées** (≈ 280 px, rangées 0–2), **grande fenêtre de 5 cases** (x 576–1056, colonnes 6–10) sur la mer avec îlot et phare, lambris miel, tuyaux de cuivre, deux cadres ; murs latéraux ≈ 48 px ; mur du bas ≈ 60 px avec l'**entrée de 2 cases** (x 672–864, colonnes 7–8) et un paillasson brun uni (sortie `X` (7..8, 10)). Les cases `K` (0..1, 3..4) et (14..15, 3..4) sont couvertes par les armoires accolées aux cabines (planche). Vide ; **sans marche d'entrée**. **Jointes** : coques d'Argenta et du labo, façade neuve, `REF_LEO_PIECE` (composition seulement).

#### INT_MAISON_LEO_PLANCHE → 6 meubles (vague 1)
- Planche **3 × 2 cellules de 512 × 512**, 1 case = 150 px, largeurs `[3, 2, 1, 1.3, 3, 1]`, contact 0,2. Posés par `build_painted_interiors.gd` (T14) aux cases de la grille :
  - `int_cabine_teleport_01` (3 × ≈ 2,6 : armoire 1 + cabine 2) : cabine A (2..3, 3..4) avec l'armoire en (1, 3..4) ; **cabine B en miroir** (12..13, 3..4), armoire en (14, 3..4). Anneau bleu pâle peint doucement ; la lueur d'étape vient du `LightGlow hint` sous `FlagGate` (§2.8), jamais peinte en halo.
  - `int_console_leo_01` (2 × 1) : console (7..8, 3), **grand bouton rouge** (seul rouge vif).
  - `int_module_leo_01` (1 × 1,3) : module (10, 3), tuyaux et câbles.
  - `int_ecran_diagnostic_01` (≈ 1,3 de large, 2,2 de haut) : écran (5, 3) sur meuble bas, courbes cyan **sans chiffres ni lettres**.
  - `int_bureau_leo_01` (3 × 1) : bureau `N` (5..7, 7), plans étalés ; chaise (6, 8) = `int_chaise_bureau_01`.
  - `int_bibliotheque_cote_01` (1 × 2) : bibliothèques `b` (1, 6..7) ; **en miroir** en (14, 6..7).
- **Jointes** : `REF_LEO_CABINE`, `_CONSOLE`, `_MODULE`, `_ECRAN`, `_BUREAU`, `_BIBLIO`, machines du labo, bureau de Chen, grande étagère.

### Personnage

Modèle commun des séries 10–15 : marche 4 × 4 (1024 × 1536, héros validé joint, « ne ressemble pas au héros »), attente 4 × 1 (1536 × 1024) calée sur la marche jointe. **128 px** de haut. Préparation (T13) : sections `personnages` / `attentes` ; look **`bill`** en fin de `LOOKS` (le look `leo` existe déjà : c'est Nils, §6 « Nils : apparence `leo` gardée »). Planche `leo_humain_sheet.png`.

| Fiche | Tenue (défaut, règle 4 ; dossier §4.1 « bricoleur, manches retroussées » [D]) | Attente | Jointes |
|---|---|---|---|
| `PNJ_LEO_HUMAIN` → `leo_humain` (`bill`) | ≈ 25 ans, cheveux **châtain-roux en bataille**, **lunettes de protection** relevées sur le front, chemise à carreaux vert sapin et crème **manches retroussées**, **tablier d'atelier** brun (tournevis, crayon), pantalon beige, bottines brunes ; un peu plus grand que le héros | pieds joints, mains sur les hanches, l'air ravi | héros ; Chen (même main pour un adulte, à ne pas copier) ; aucune référence peinte |

### Icônes du Sac

#### UI_OBJETS_J14_PLANCHE → `assets/ui/items/ss_ticket.webp`, `rare_candy.webp` (vague 1)
- Planche 1536 × 1024 à **4 colonnes de 384**, le **Passe Bateau** dans la 1re (billet crème à liseré bleu marine, silhouette de paquebot, **aucune lettre**), le **Super Bonbon** dans la 2e (papillote bleu ciel et blanc, étoile blanche) ; colonnes 3–4 vides. Chaîne `preparer_menu.py` (`_bandes`, 256 px, WebP) : T13 ajoute `("UI_OBJETS_J14_PLANCHE_r1.png", ["ss_ticket", "rare_candy"])` **en fin** de `PLANCHES_OBJETS_SUIVANTES`. CT28, CT19 : illustration CT du J11. **Jointe** : `MENU_OBJETS_PLANCHE_r1`.

### Conditionnels (prompts prêts, non lancés)

- `WORLD_PROP_BARRIERE_POLICE_01` (1 × 0,8, bandes bleu marine et blanc, gyrophare éteint ; jointe : fermetures de la série 15).
- `COMBAT_DECOR_ROUTE25_COTE_r1` (corniche, mer à gauche, falaise et forêt à droite, golden hour ; points A et B, zones calmes des décors du J13).

## Commandes du T2

`python3 tools/art/serie16.py --refs && python3 tools/art/serie16.py --ancres`, puis `python3 tools/art/serie16.py` (vague 1 : 5 images, trois à la fois ; vague 2 : coque, attente), ou une à une par `--commandes`. Contact : `python3 tools/art/serie16.py --contact` → `build/captures/jalon14_assets/serie16_contact.png` → Kevin (14.0-art). Corrections en `_r2` par la table `CORRECTIONS`.
