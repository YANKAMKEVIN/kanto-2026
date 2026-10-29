# DAF.9 « Cramois'Île » (2026-10-29, branche `claude/daf-9-cramois-72a15a`, depuis `main` @ `dc4bc124`)

**À valider par Kevin (planches ci-dessous) avant la fusion.** Ferme RP-024 (P1, BAT-2) : à la
clôture du J25, Cramois'Île, son Arène et le Manoir n'avaient que des tuiles provisoires et des
aplats ; aucun lot DAF ne les couvrait. Lot ouvert par Kevin le 2026-10-29 (« Oui, ouvre-le »).

Gel fonctionnel du J33 respecté : **aucune collision, aucun déclencheur, aucune coordonnée
d'événement ne bouge**. `tools/dump_map_logic.gd` (grille) et `tools/dump_map_nodes.gd` (nouveau :
tous les nœuds non graphiques avec position, script et variables) donnent des sorties **identiques**
avant / après sur les 6 cartes.

| Planche | Contenu |
|---|---|
| [synthese-telephone.jpg](synthese-telephone.jpg) | **à lire en premier, sur le téléphone** |
| [planche-1-ile.jpg](planche-1-ile.jpg) | Cramois'Île avant / après (vue d'ensemble, place, plage) |
| [planche-2-arene.jpg](planche-2-arene.jpg) | Arène : herses fermées et ouvertes, entrée, salle d'Auguste |
| [planche-3-manoir.jpg](planche-3-manoir.jpg) | Manoir 1F (ARRÊT et MARCHE), 2F, 3F, B1F en vue d'ensemble |
| [planche-4-manoir-joueur.jpg](planche-4-manoir-joueur.jpg) | Manoir à hauteur du joueur |
| [planche-5-kit.jpg](planche-5-kit.jpg) | images neuves et kit de la série 28 à l'échelle du jeu |

## Sources de l'image

- **Kit de la série 28** (J25, validé par Kevin le 2026-10-19, jamais intégré jusqu'ici) : sols
  (parquet, carrelage du B1F, dalles de l'Arène, masses), murs (faces, couronnements), mobilier du
  Manoir, statues, pupitres, grilles, escaliers, trous, seuils, gravats, machines de quiz, herses,
  statue de l'Arène. Lu dans `build/art/serie28/` (préparé par `tools/art/serie28.py` sur la branche
  `j25-kit-art`), copié dans `assets/world/` par `tools/art/daf9.py --modules`.
- **Neuf** (Codex CLI, sans dépense d'API ; prompts `tools/art/prompts/daf9/`, tous retenus r1, aucun
  refus) : façades du Manoir en ruine, de l'Arène (toit rouge, flamme sculptée) et du Labo de
  Cramois (bâtiment moderne à toit plat), 9 × 6 cases ; sol volcanique, sable noir, roche
  volcanique des récifs (384 px).

## Outils

- `tools/art/daf9.py` : prompts, génération Codex, préparation (`--modules`) ; recalage des portes
  (Codex centre la porte ; la façade est étirée de part et d'autre pour que la porte tombe sur ses
  deux cases de la grille).
- `tools/build_daf9_cramois.gd` : seconde passe d'image du Manoir (4 niveaux) et de l'Arène, règles
  de pose de `serie28.py --cartes` (la recomposition validée) ; couches de tuiles masquées, logique
  gardée ; dessins provisoires des [FlagGate] remplacés par les images peintes accrochées au même
  nœud (même visibilité : grilles A / B, rails, herses) ; herses ouvertes = [FlagGate] visuels
  `Daf9HerseOuverte_*` (aucune case bloquée).
- `tools/build_daf9_ile.gd` : seconde passe de `cinnabar_island` (sol peint, mer, façades en
  `WorldProp` à l'emprise exacte des cases du bâtiment, portes libres ; panneaux en image accrochée).
- `tools/dump_map_nodes.gd`, `tools/capture_daf9.sh` (option `--gates` ajoutée à
  `capture_viridian_forest.gd` : décors à drapeaux réglés comme en jeu), `tools/art/planches_daf9.py`,
  `tools/measure_daf9_textures.gd`.

Ordre : `daf9.py --modules`, `build_painted_props.gd -- --nouveaux`, `--import`,
`build_daf9_cramois.gd` et `build_daf9_ile.gd` (code 2 : importer puis relancer).

## Valeurs par défaut [D]

- Lumière des cartes inchangée (profils existants) ; pas de halos de bougies (la vue générale du
  Manoir en montre) : à la phase lumière si Kevin le souhaite.
- Frontière mur / sol des côtés est et ouest : bord bruité du sol peint (comme la Tour Pokémon) ;
  les faces et couronnements donnent des bords nets au nord et au sud.
- Mer de l'île : eau de mer commune (`ground_eau_01`), rivage naturel avec écume ; récifs et roche
  volcanique en sol peint (pas de rochers posés dans l'eau, pour ne rien ajouter à la grille).
- Panneaux : `prop_panneau_01` commun.
- Arène de Cramois'Île : façade propre (la façade commune des Arènes n'est pas reprise).

## Budget de textures (RP-091, repère 64 Mo par carte)

Voir la section « Mesure » ci-dessous (`tools/measure_daf9_textures.gd`).
