# DAF.10c « Îles Écume et Centrale » (2026-10-30, branche `claude/hungry-perlman-8e653b`)

**En attente de validation de Kevin (DA-6), non fusionné.** Lot du J33 (gel fonctionnel). Ferme sur la branche
**RP-275** (P1, Îles Écume 1F à B4F) et **RP-276** (P1, Centrale), et la fin de **RP-280** (P2, étages de Sylphe).

Gel du J33 respecté : **aucune collision, aucun déclencheur, aucune coordonnée ne bouge**. `tools/dump_map_logic.gd`
et `tools/dump_map_nodes.gd` donnent des sorties **identiques** avant / après sur les **15 cartes** (6 cartes du lot et
9 étages de Sylphe, 30 relevés, `tools/dump_daf10c.sh avant|apres`). Tout ce qui est ajouté porte le préfixe `Daf10c` (ou `PaintedGround`, `Eau`) ;
les objets debout ne sont posés que sur des cases déjà bloquées.

**Codex** (correctif du 2026-10-31) : les 8 images du lot (`tools/art/daf10c.py`, prompts dans `tools/art/prompts/daf10c/`), générées dans la nuit du 30 au 31, **remplacent à l'identique** le kit dérivé provisoire (`daf10c.py --modules`, puis les deux passes de carte) ; relevés toujours identiques sur les 15 cartes. Le **fond de combat de la Centrale** est peint aussi (`COMBAT_DECOR_CENTRALE`, tuiles TL / TR, cousu par `combat_decors/preparer_decor.py`, horizon 415 [D], ancres inchangées) ; capture `planche-7-combat.jpg`.

| Planche | Contenu |
|---|---|
| [synthese-telephone.jpg](synthese-telephone.jpg) | **à lire en premier, sur le téléphone** |
| [planche-1-ecume.jpg](planche-1-ecume.jpg) | Îles Écume 1F, B1F, B2F : avant / après |
| [planche-2-ecume.jpg](planche-2-ecume.jpg) | Îles Écume B3F, B4F : avant / après |
| [planche-3-centrale.jpg](planche-3-centrale.jpg) | Centrale : avant / après |
| [planche-4-echelle-jeu.jpg](planche-4-echelle-jeu.jpg) | à l'échelle du jeu (zoom 1, joueur posé) : rochers, courants, sol haut, salles de la Centrale |
| [planche-7-combat.jpg](planche-7-combat.jpg) | fond de combat de la Centrale (vrai combat) |
| [planche-5-sylphe.jpg](planche-5-sylphe.jpg), [planche-6-sylphe.jpg](planche-6-sylphe.jpg) | Sylphe SARL 2F à 4F et 6F à 11F : avant / après (reste de RP-280) |

Captures en nouvelle partie (aucun trou bouché, rochers de Force à leur case d'origine). Les « avant » n'ont pas
les rochers de Force (l'outil de capture ne les posait pas encore) : c'étaient des disques gris dessinés par le code.

## Îles Écume (RP-275) — `tools/build_daf10c_seafoam.gd`

Seconde passe d'image après `build_j24_seafoam.gd`, sur le modèle de `build_daf4_caves.gd` (kit `cave_map_kit.gd`).

- **Sol à deux niveaux** : sol bas `ground_ecume_bas_01` (roche gelée bleu ardoise) ; sol haut `:` et escaliers
  `=` en `ground_glace_01` (glace bleu pâle de la série 27, nettement plus claire) ; masse `ground_masse_glace_01`.
- **Parois glacées** en modules aux gabarits du Mont Sélénite (`relief_paroi_glace_01/02/05/06`) ; **rebords**
  peints au sud et sur les côtés du sol haut, et autour des **arêtes** `|` (bloquées, entre deux niveaux) ;
  **escaliers** `relief_escalier_ecume_01`.
- **Eau froide** : `ground_eau_grotte_01` (série 27) en bandes sur `w s ^ v < > ~` et les points de chute dans
  l'eau du B3F et du B4F.
- **Courants (EAU-4)** : `SeafoamFloorGate` dessine sur chaque courant **actif** l'eau vive peinte
  `ground_courant_01` tournée dans le sens du flux et qui **défile** (120 px/s [D]), avec des chevrons clairs plus
  épais par-dessus ; un courant calme redevient de l'eau ordinaire (comportement inchangé).
- **Rochers de Force (DON-4)** : `Boulder` dessine l'image peinte `prop_rocher_force_01` (ronde, claire, fissurée)
  au lieu des disques ; même ombre, mêmes animations (glissade, tremblement, chute). Vaut aussi pour la Route
  Victoire et le rocher du Gardien. Les petits rochers fixes `o` sont des blocs anguleux plus sombres
  (`prop_rocher_glace_01`), les indices `x` un caillou clair (`prop_rocher_grotte_02`).
- **Dessins remplacés** : échelles (montante / descendante selon la grille), trous ouvert et bouché
  (`decal_trou_ecume_*`), rochers tombés dans l'eau (`prop_rocher_force_eau_01`), panneaux (`prop_panneau_01`
  ramené à une case [D]).

## Centrale (RP-276) — `tools/build_daf10c_centrale.gd`

- Sol de dalles de béton de l'usine `ground_centrale_01` ; dessus des machines et murs épais
  `ground_masse_centrale_01`.
- Machines et cloisons `#` en **modules** `relief_mur_centrale_01` à `_05` aux rôles du repaire Rocket
  (`tools/module_walls.gd` : faces, couronnements, bords latéraux).
- **Machines** posées sur le dessus des grands blocs (case `#` entourée de `#`, loin des faces, jamais deux
  voisines, une case admissible sur deux [D]) : 28 machines avec le kit Codex (générateurs et condensateurs sur deux cases, transformateurs, bobines, pupitres, tourets de câble).
- Éléments interactifs inchangés et lisibles : Électhor, les huit fausses Poké Balls, les objets, les deux indices
  d'objet caché, les portes.

## Sylphe SARL 2F à 4F, 6F à 11F (reste de RP-280) — `tools/build_daf10d.gd`, mode « auto »

Comme le 5F de DAF.10d (validé), mais tiré de la grille de chaque étage (`tools/plans/sylphe_*.txt`) au lieu de
rectangles posés à la main : moquette bleutée sur la **zone de bureaux** de chaque salle qui a au moins 4 cases
de mobilier `M` (rectangle des meubles agrandi d'une case, limité à la salle), une plante contre la cloison nord
une case sur quatre (au plus trois par salle, sur des cases `#` déjà bloquées), lueurs chaudes sur une trame de
5 cases (au plus 10) [D]. Aucune image neuve. Relevés identiques sur les 9 étages (18 relevés).

## Kit : dérivé (fusionné le 30), Codex (correctif du 31)

| Asset | Provisoire (dérivé, fusionné le 30) | Image Codex intégrée le 31 (`daf10c.py`) |
|---|---|---|
| `ground_ecume_bas_01` | sol bas de la Grotte Azurée bleui, givré | `WORLD_GROUND_ECUME_BAS_01` |
| `ground_masse_glace_01` | masse rocheuse bleuie | `WORLD_GROUND_MASSE_GLACE_01` |
| `relief_paroi_glace_01/02/05/06` | parois du Mont Sélénite bleuies, clairs tirés vers le givre | `WORLD_RELIEF_PAROI_GLACE_PLANCHE` (gabarits exacts) |
| rebords, escalier, trous, petit rocher | ceux de la Grotte Azurée, de la Route Victoire et du Mont Sélénite givrés | `INT_ECUME_PLANCHE` |
| `ground_centrale_01`, `ground_masse_centrale_01` | béton du repaire réchauffé, masse des bâtiments | `WORLD_GROUND_CENTRALE_01`, `WORLD_GROUND_MASSE_CENTRALE_01` |
| `relief_mur_centrale_01..05` | murs du repaire teintés vert d'eau | `WORLD_RELIEF_MUR_CENTRALE_PLANCHE` (machines, transformateur) |
| machines | armoires électriques et console du repaire teintées | `INT_CENTRALE_PLANCHE` (+ générateur, condensateurs, touret de câble) |
| fond de combat `power_plant_centrale` | dérivé de DAF.2 bis | `COMBAT_DECOR_CENTRALE` (+ tuiles TL / TR) |

## Valeurs par défaut [D]

- Lumière des cartes inchangée (profils `cave_*` et `office`).
- Arêtes `|` : masse givrée bordée de rebords, sans module de paroi (une case de large).
- Panneaux : le panneau de bois des routes, réduit à 0,58.
- Défilement des courants : 120 px/s, opacité 0,8.
- Machines de la Centrale : une case admissible sur deux, au hasard (graine fixe).
- Parois glacées : la face 02 de Codex porte une cascade gelée ; elle alterne avec la face 01 (décor sur case bloquée).

## Outils

- `tools/art/daf10c.py` (`--prompts`, génération, `--tuiles`, `--modules`), `tools/art/daf10c_derives.py`.
- `tools/build_daf10c_seafoam.gd` (`-- <map_id>…`), `tools/build_daf10c_centrale.gd`.
- `tools/dump_daf10c.sh`, `tools/capture_daf10c.sh`, `tools/capture_daf10c_details.sh`, `tools/daf10c_maps.txt`,
  `tools/art/planches_daf10c.py` ; option `--boulders` de `tools/capture_viridian_forest.gd`.
- Test : `tests/unit/test_daf10c.gd`.

Ordre : `python3 tools/art/daf10c_derives.py` (ou `daf10c.py --modules` une fois les images Codex là),
`godot --headless --path . -s res://tools/build_painted_props.gd -- --nouveaux`, `--import`,
`build_daf10c_seafoam.gd` et `build_daf10c_centrale.gd` (code 2 : importer puis relancer),
`tools/dump_daf10c.sh apres` (comparer à `avant`), captures, `planches_daf10c.py`.
