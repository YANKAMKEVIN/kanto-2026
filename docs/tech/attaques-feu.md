# Refonte des attaques Feu (décidée le 2026-11-10)

Suite de la refonte par famille de types, après l'Électrik (`attaques-electriques.md`). Avant : six des huit attaques lançaient la même boule de feu, Poing de Feu affichait un poing gris dessiné et Zénith l'aura bleue générique des hausses de statistiques.

**Direction retenue par Kevin : A, « flamme peinte »**, orange et jaune chauds, cœur jaune pâle, coups de pinceau visibles, lumière naturelle ; la même main que la foudre peinte de l'Électrik. Planche de référence : `docs/design/references/attaques/feu_direction_A.png` (directions B « brasier » et C « feu solaire » écartées). Elle donne la direction, pas un dessin à reproduire au pixel (règle 10 de `CLAUDE.md`).

## Les huit attaques

| N° | Attaque | Puissance | Effet visuel à obtenir | Effet avant |
|---|---|---|---|---|
| 1 | Flammèche | 40 | Petite gerbe de flammèches de la bouche à la cible, petit impact | `feu` (boule) |
| 2 | Danse Flamme | 35, piège | Tourbillon de feu qui enferme la cible ; pas de projectile | `feu` + `piege` |
| 3 | Roue de Feu | 60, physique | Le lanceur dans une roue de feu, traînée de flammes vers la cible | `feu` (boule) |
| 4 | Poing de Feu | 75, physique | Coup unique, explosion de flammes au contact, sans poing dessiné | `poing`, variante `feu` |
| 5 | Lance-Flammes | 90 | Jet de flammes continu et épais du lanceur à la cible | `feu`, signature `lance_flammes` (boule) |
| 6 | Feu Sacré | 100, physique | Colonne de flammes qui jaillit du sol sous la cible | `feu` (boule) |
| 7 | Déflagration | 110 | Grande étoile de feu à cinq branches qui frappe et s'embrase | `feu`, signature `deflagration` (boule) |
| 8 | Zénith | statut | Soleil ardent et rayons chauds sur tout le terrain ; rien sur la cible | `statut_plus` (aura bleue) |

## Contraintes

- Barre de qualité : `docs/tech/combat-vivant.md` §2.9 (couches, flipbooks peints, validation **en vidéo**).
- Les Pokémon n'ont pas de pose de course ni de coup de poing : pour 3 et 4, la charge existante porte le geste, les flammes font le reste.
- La gradation de puissance doit se lire : Flammèche la plus petite, Déflagration la plus grosse.

## Étapes

1. Art : `tools/art/serie_cv_fx_feu.py` (Codex, `manifeste_feu.json`), en reprenant les briques de l'Électrik (cage, aura et traînée de charge, courant, projectile, plafond de ciel) ; brique nouvelle : colonne qui monte du sol (Feu Sacré).
2. Familles et signatures dans `data/battle/move_fx/`.
3. Vidéo des huit attaques : `game/battle/fx/fx_gallery.tscn -- --moves=ember,fire_spin,flame_wheel,fire_punch,flamethrower,sacred_fire,fire_blast,sunny_day --mode=full` (avec `--always-on-top`).
4. Validation de Kevin sur la vidéo, puis CI GitHub verte.

## Réalisation (2026-11-10)

- **Art :** `tools/art/serie_cv_fx_feu.py` (Codex, 10 flipbooks et 8 particules, `manifeste_feu.json`). Le jet s'appelle `fleuve_flammes` : `jet_flammes` existe déjà dans la vague 1. Rayons du soleil refaits une fois (`_r2`) : la première planche ressemblait à des flammes. Tourbillon, jet, colonne et explosion sont posés en mélange normal (en additif, ils viraient au blanc sur le décor clair).
- **Par attaque :** Flammèche signature `flammeche` (gerbe `flammeches`, petite) ; Danse Flamme `danse_flamme` (brique `fire_vortex`, la cage de Cage-Éclair avec le tourbillon) ; Roue de Feu `roue_feu` (roue `anneau_feu` et traînée sur la charge, impact `flamme`) ; Poing de Feu `poing` variante `feu` (plus de poing dessiné : `contact_flamme` et `eclat_feu`) ; Lance-Flammes signature `lance_flammes` (`fleuve_flammes`, du lanceur à la cible) ; Feu Sacré `feu_sacre` (brique `ground_pillar` : la colonne jaillit du sol sous la cible) ; Déflagration signature `deflagration` (étoile `etoile_feu`, embrasement `explosion_feu`) ; Zénith `zenith` (brique `sunshine` : soleil et rayons dans le coin haut droit de l'écran, rien sur la cible).
- **Valeurs par défaut [D] :** `travel_scale` (Flammèche 1,15, Déflagration 1,9), `bolt_height` 0,42 et tailles d'impact dans `families.json` ; `PILLAR_WIDTH`, `PILLAR_HEIGHT`, `SUN_ALPHA`, `SUN_SIZE` de `move_fx_player.gd`.
