# DAF.10d « Ligue, Labo, Sylphe » et DAF.2 bis « fonds de combat » (2026-10-30, branche `claude/magical-villani-726092`)

**En attente de validation de Kevin (DA-6), non fusionné.** Lots du J33 (gel fonctionnel) faits **sans Codex** (limite
d'usage) : rien que des dérivés de l'art déjà dans le dépôt (kits peints répétés, recadrés, teintés ; fonds de combat
étalonnés et mis en miroir). Aucune image neuve.

Ferme **RP-277** (P1, salles de la Ligue et Panthéon), **RP-278** et **RP-279** (P2, fonds de combat), **RP-157** (P2) ;
**RP-280** en partie (Labo de Cramois'Île, Panthéon, Sylphe 5F ; les autres étages de Sylphe restent).

Gel du J33 respecté : **aucune collision, aucun déclencheur, aucune coordonnée ne bouge**. `tools/dump_map_logic.gd`
et `tools/dump_map_nodes.gd` donnent des sorties **identiques** avant / après sur les **8 cartes** touchées
(`tools/dump_daf10d.sh avant|apres`). Tout ce qui est ajouté porte le préfixe `Daf10d` ; les objets debout ne sont
posés que sur des cases déjà bloquées ; le sol praticable ne reçoit que du plat (tapis, moquette, lueurs).

| Planche | Contenu |
|---|---|
| [planche-1-ligue.jpg](planche-1-ligue.jpg) | Olga, Aldo, Agatha : avant / après |
| [planche-2-ligue-pantheon.jpg](planche-2-ligue-pantheon.jpg) | Peter, Champion, Panthéon : avant / après |
| [planche-3-labo-sylphe.jpg](planche-3-labo-sylphe.jpg) | Labo de Cramois'Île, Sylphe SARL 5F : avant / après |
| [planche-4-fonds-combat.jpg](planche-4-fonds-combat.jpg) | les cinq fonds de combat, en vrai combat (Parc : aperçu du décor) |

RP-277 était « à confirmer sur S24 » : confirmé sur les captures de l'audit (`../t2-audit/`), comme demandé.

## DAF.10d : identité des salles

Salles de la Ligue et Panthéon (tuiles provisoires `InteriorTiles`, masquées) : sol répété, masse de mur, faces
peintes au bas des murs, voile sombre sur les murs profonds, ombre au pied des murs latéraux, objets du thème, lueurs
additives.

| Salle | Sol | Murs | Objets |
|---|---|---|---|
| Olga (glace) | `ground_glace_01` bleuté | roche bleue (`relief_paroi_grotte_01/02`, `ground_azuree_bas_01`) | cristaux de glace (éclats de Pierre Lune teintés), lueurs froides |
| Aldo (roche) | `ground_victoire_haut_01` | roche brune (`relief_paroi_grotte_sombre_01/02`) | rochers, lueurs de torche |
| Agatha (spectre) | dalles de la Tour teintées violet | murs de la Tour teintés | tombes et bougeoirs de la Tour, lueurs violettes |
| Peter (dragon) | `ground_victoire_bas_01` rougi | briques à braises de l'Arène (`relief_mur_arene_*`) | statues (gargouilles d'Arène), bougeoirs, tapis rouge le long du chemin, lueurs de braise |
| Champion | marbre `ground_dalles_morgane_01` | panneaux bordeaux à appliques dorées (`relief_mur_casino_01/02`) | quatre statues sur les piliers, tapis rouge, lueurs dorées |
| Panthéon | marbre | marbre violet du Manoir (`relief_mur_manoir_b1_01/02`) | machine du Panthéon (`int_machines_labo_01`) sur l'alcôve bloquée, deux vitrines de trophées, tapis rouge |

Labo de Cramois'Île (coque peinte) : étagère, poste de mesure, classeur et plantes contre le mur du fond ; paillasse
sur le bloc central déjà bloqué (3 × 2, jusque-là invisible) ; plantes dans les quatre coins bloqués ; deux tapis
Poké Ball ; lueurs chaudes (BAT-5).

Sylphe SARL 5F (étage type) : moquette bleutée dans le grand bureau et le petit bureau du haut, deux tapis bleus,
plantes contre les cloisons, lueurs chaudes de plafonnier.

## DAF.2 bis : fonds de combat dérivés

`tools/art/daf2bis.py` (2340 × 1080, WEBP 90, mêmes ancres et même horizon que la source) ; branchés dans
`data/battle/decors.json`.

| Fond | Lieu | Source | Dérivation |
|---|---|---|---|
| `silph_co_hall` | Sylphe 1F (n'avait aucun fond : repli) | `silph_co_bureaux` | miroir, moquette passée en dallage clair |
| `fuchsia_gym_ninja` | Arène de Parmanie | `fighting_dojo_salle` | miroir, crépuscule violet, parquet assombri (l'Arène est peinte en parquet et shoji, DAF.10a) |
| `cinnabar_gym_volcan` (décor `arene_cramois`) | Arène de Cramois'Île | `pewter_gym_roche` | miroir, pierre embrasée, haut assombri |
| `power_plant_centrale` **[D]** | Centrale | `rocket_hideout_repaire` | lumière jaune électrique, sol sombre ; provisoire jusqu'à DAF.10c |
| `safari_zone_savane` | Parc Safari (4 zones) | `route_5_6_prairie` | miroir, herbes dorées de savane |

Le « repli » noté par l'audit dans le Parc Safari venait de l'outil de capture : sans visite en cours, le joueur est
renvoyé à l'accueil (`safari_zone_gate`, sans fond) avant le combat. En jeu, le Parc avait déjà `route_5_6_prairie`.

## Valeurs par défaut [D]

- Lumière des cartes inchangée (profil `interior_warm`) ; l'ambiance de chaque salle vient des teintes et des lueurs
  additives (`Lueur_*`, sans nœud de lumière).
- Portes de la Ligue : dessins des [FlagGate] inchangés (rectangles sombres) ; une porte peinte reste à faire.
- Tapis rouge de Peter et du Champion : neuf-carreaux de `int_tapis_rouge_01` étiré sur le chemin.
- Sylphe : seul le 5F est habillé (« étage type ») ; `tools/build_daf10d.gd` s'étend aux autres étages en ajoutant
  une entrée au tableau `THEMES`.
- Centrale : dérivé industriel, à remplacer par DAF.10c.

## À refaire en vraie image Codex plus tard

1. ~~**Fonds de combat**~~ **faits le 2026-10-31** (Codex, `tools/art/daf10c.py` `COMBATS`, cousus par `combat_decors/preparer_decor.py`, ancres inchangées, horizons recalés [D] : Parmanie 418, Cramois'Île 418, Safari 455, Sylphe 310 ; Centrale avec DAF.10c ; `planche-codex-2026-10-31.jpg`) : les cinq sont des étalonnages ; vrais fonds peints pour l'Arène de Parmanie (dojo ninja
   violet, pièges), l'Arène de Cramois'Île (salle volcanique, lave), la Centrale (machines électriques, DAF.10c),
   le Parc Safari (savane, enclos) et le hall de Sylphe 1F (accueil, ascenseurs).
2. ~~**Murs de la Ligue**~~ **faits le 2026-10-31** (Codex, `tools/art/daf10d_codex.py`, faces `relief_mur_ligue_*` au gabarit 192 × 186, Panthéon compris ; `planche-codex-ligue-1.jpg`, `-2.jpg`) : faces dédiées par salle (glace sculptée, temple de pierre, crypte, temple du dragon, salle
   du Champion), aujourd'hui empruntées aux grottes, à la Tour, à l'Arène de Carmin et au Casino.
3. ~~**Objets de thème**~~ **faits le 2026-10-31** (colonne de glace, brasero, candélabre, statue de dragon, colonne d'honneur, machine du Panthéon ; portes de la Ligue non touchées, ce sont des éléments interactifs) : statue de dragon (aujourd'hui gargouille d'Arène), colonnes de glace, braseros, portes peintes
   de la Ligue, machine du Panthéon (aujourd'hui poste de laboratoire).
4. **Sylphe** : mobilier d'accueil et de bureau propre à chaque étage.

## Outils

- `tools/build_daf10d.gd` (`-- <map_id>…` pour une seule carte) : les deux modes « salle » et « coque ».
- `tools/art/daf2bis.py` : les cinq fonds.
- `tools/dump_daf10d.sh`, `tools/capture_daf10d.sh`, `tools/daf10d_maps.txt`, `tools/art/planches_daf10d.py`.
- Test : `tests/unit/test_daf10d.gd` (nœuds `Daf10d` sans emprise, tuiles masquées, fonds par lieu et taille).

Ordre : `python3 tools/art/daf2bis.py`, `godot --headless --path . --import`, `build_daf10d.gd`,
`tools/dump_daf10d.sh apres` (comparer à `avant`), `tools/capture_daf10d.sh build/daf10d/apres`, captures de combat
(`tools/capture_t2_combat.gd --place=… | --decor=safari_zone_savane`), `planches_daf10d.py`.
