# Refonte des attaques Plante (décidée le 2026-11-10)

Suite de la refonte par famille de types, après l'Électrik, le Feu et l'Eau (`attaques-electriques.md`, `attaques-feu.md`, `attaques-eau.md`). Avant : Vol-Vie, Méga-Sangsue, Tranch'Herbe et Danse Fleur partageaient la même rafale de feuilles, Fouet Lianes était une liane dessinée en code, Vampigraine des graines rondes en code, Spore Coton l'aura grise des baisses de statistiques et Synthèse la lueur verte générique des soins.

**Direction retenue par Kevin : A, « végétal peint »**, verts frais et tendres, feuilles et lianes à nervures, pétales roses, lumière solaire blanc doré ; la même main que la foudre, la flamme et l'eau peintes. Planche de référence : `docs/design/references/attaques/plante_direction_A.png` (directions B « jungle sauvage » et C « lumière de chlorophylle » écartées). Elle donne la direction, pas un dessin à reproduire au pixel (règle 10 de `CLAUDE.md`).

**Décision de Kevin : les poudres restent telles quelles** (Poudre Dodo, Para-Spore, Spore : la poudre qui tombe de la vague 1 Rouge).

## Les douze attaques

| N° | Attaque | Puissance | Effet visuel à obtenir | Effet avant |
|---|---|---|---|---|
| 1 | Vol-Vie | 20 | La sève jaillit de la cible, un filet de sève revient au lanceur | `plante` + `drain` |
| 2 | Méga-Sangsue | 40 | Flot de sève plus épais, le lanceur s'illumine | `plante` + `drain` |
| 3 | Fouet Lianes | 45, physique | Deux lianes torsadées qui fouettent deux fois | `fouet` (liane en code) |
| 4 | Tranch'Herbe | 55 | Volée de feuilles tranchantes qui tournoient, entailles | `plante` |
| 5 | Danse Fleur | 120 | Immense tourbillon de pétales qui engloutit la cible | `plante` |
| 6 | Lance-Soleil | 120 | Tour 1 : le lanceur absorbe la lumière ; tour 2 : rayon solaire énorme, explosion de lumière | `plante`, signature `lance_soleil` |
| 7 | Vampigraine | statut | Graines en arc, lianes qui jaillissent et enserrent la cible | `graine` (formes en code) |
| 8 | Poudre Dodo | statut | **Inchangée** (décision de Kevin) | `poudre`, variante `dodo` |
| 9 | Para-Spore | statut | **Inchangée** | `poudre`, variante `para` |
| 10 | Spore | statut | **Inchangée** | `poudre`, variante `spore` |
| 11 | Spore Coton | statut | Gros flocons de coton qui flottent et se collent en couronne | `statut_moins` |
| 12 | Synthèse | statut | Rayon de soleil sur le lanceur, aura de photosynthèse ; rien sur la cible | `soin` |

## Contraintes

- Barre de qualité : `docs/tech/combat-vivant.md` §2.9 (couches, flipbooks peints, validation **en vidéo**). Retour de Kevin sur l'Eau, appliqué d'emblée : effets puissants et bien visibles (matière dense, tailles généreuses, secousse, lumière à l'impact).
- La gradation de puissance doit se lire : Vol-Vie la plus petite, Danse Fleur et Lance-Soleil les plus grosses.

## Étapes

1. Art : `tools/art/serie_cv_fx_plante.py` (Codex, `manifeste_plante.json`).
2. Familles, variantes et signatures dans `data/battle/move_fx/` ; briques dans `game/battle/fx/move_fx_player.gd`.
3. Vidéo des neuf attaques refaites : `game/battle/fx/fx_gallery.tscn -- --moves=absorb,mega_drain,vine_whip,razor_leaf,petal_dance,solar_beam,leech_seed,cotton_spore,synthesis --mode=full` (avec `--always-on-top`).
4. Validation de Kevin sur la vidéo, puis CI GitHub verte.

## Réalisation (2026-11-10)

- **Art :** `tools/art/serie_cv_fx_plante.py` (Codex, 13 flipbooks et 24 particules, `manifeste_plante.json`), sur la chaîne de `serie_cv_fx_eau.py`. Lianes, coton, rayon et explosion solaires sur magenta, en mélange normal ; pétales roses sur **vert** (le magenta se confondait avec le rose : tourbillon et planche `part_t`) ; auras, flot de sève, rayon de Synthèse et orbes additifs sur noir.
- **Par attaque :** Vol-Vie et Méga-Sangsue famille `sangsue` (brique `siphon` : rien ne part du lanceur ; gerbe `eclat_seve` sur la cible, flot peint `flot_seve` et orbes `orbe_seve` qui reviennent au lanceur, rôle `siphon` du drain) ; Méga-Sangsue variante `mega` (flot et gerbe plus grands, aura `aura_seve` qui ne s'allume qu'au retour de la sève) ; Fouet Lianes `fouet` (rôle `vine` : `liane_fouet` peinte à la place de la liane en code, même geste en deux claquements, étoile `claque_vert`) ; Tranch'Herbe `tranch_herbe` (brique `leaf_volley` : neuf feuilles `feuille_tranchante` qui tournoient en arcs alternés, entailles `entailles_feuilles`) ; Danse Fleur `danse_fleur` (brique `petal_vortex` : la cage de Cage-Éclair, à 2,6 fois la cible) ; Lance-Soleil signature `lance_soleil` (aura `aura_solaire` au tour de charge, `rayon_solaire`, `explosion_solaire`) ; Vampigraine `graine` (graines `graine_vampi`, lianes `lianes_enserrent` jouées une fois sur la cible) ; Spore Coton `spore_coton` (brique `bubbles` avec `flocon_coton`, couronne `coton_colle`) ; Synthèse `synthese` (brique `sunshaft` : `rayon_synthese` du haut de l'écran aux pieds du lanceur, aura `aura_synthese`).
- **Valeurs par défaut [D] :** `bolt_height` (Vol-Vie 0,2, Méga-Sangsue 0,36, Lance-Soleil 0,55), tailles d'impact, volées et durées (`graine` 1,3, `spore_coton` 1,2, `synthese` 1,3) dans `families.json` ; `VINE_HEIGHT`, `LEAF_SPIN`, `LEAF_ARC`, `SUNSHAFT_WIDTH`, `SIPHON_HEIGHT` et `CRACK_SIZE` (0,26) de `move_fx_player.gd`.
- **Validation :** Kevin a comparé chaque attaque avant / après en vidéo côte à côte et gardé la version refaite pour les neuf (2026-11-10). Lance-Soleil rassemble une poussière dorée à la bouche pendant la charge (`travel` de la signature).
- **Familles :** `plante` ne sert plus qu'à Lance-Soleil (par sa signature) ; `soin` et `statut_moins` gardent leurs autres attaques.
