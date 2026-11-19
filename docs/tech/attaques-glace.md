# Refonte des attaques Glace (décidée le 2026-11-19)

Suite de la refonte par famille de types, après l'Électrik, le Feu, l'Eau, le Psy et la Plante (`attaques-electriques.md`, `attaques-feu.md`, `attaques-eau.md`, `attaques-psy.md`, `attaques-plante.md`). Avant : Onde Boréale, Laser Glace et Blizzard étaient le même trait bleu fin en code (seule la taille changeait), Poing-Glace un cristal peint de la vague 2, Buée Noire une brume violette sur le terrain, Brume l'aura bleue générique des hausses de statistiques.

**Direction retenue par Kevin : A, « givre peint »**, bleus glacier pâles, cyan clair et blanc pur, cristaux à facettes peints, neige poudreuse ; la même main que la flamme et l'eau peintes ; Onde Boréale garde un ruban d'aurore. Planche de référence : `docs/design/references/attaques/glace_direction_A.png` (directions B « aurore polaire » et C « glace brute » écartées). Elle donne la direction, pas un dessin à reproduire au pixel (règle 10 de `CLAUDE.md`).

**Décision de Kevin : les six attaques sont refaites**, aucune n'est gardée telle quelle.

## Les six attaques

Inventaire de `data/pokemon/moves/` (`type: "ice"`), Johto compris : aucune autre attaque Glace.

| N° | Attaque | Puissance | Effet visuel à obtenir | Effet avant |
|---|---|---|---|---|
| 1 | Onde Boréale | 65 | Ruban d'aurore ondulant de la bouche à la cible, étoile de givre | `glace` (trait en code) |
| 2 | Laser Glace | 90 | Rayon de glace épais et droit ; cristaux qui enferment la cible puis éclatent | `glace` (trait en code) |
| 3 | Blizzard | 110 | Tempête de neige sur tout l'écran, mur de blizzard qui engloutit la cible, explosion de pics | `glace`, signature `blizzard` |
| 4 | Poing-Glace | 75, physique | Coup unique, étoile de cristaux au contact, sans poing dessiné | `poing`, variante `glace` |
| 5 | Buée Noire | statut | Brume froide et sombre sur tout le terrain ; aucun coup | `brume` (brume violette) |
| 6 | Brume | statut | Voile de brume blanche scintillante autour du lanceur ; rien sur la cible | `statut_plus` (aura bleue) |

## Contraintes

- Barre de qualité : `docs/tech/combat-vivant.md` §2.9 (couches, flipbooks peints, validation **en vidéo**). Retour de Kevin sur l'Eau, appliqué d'emblée : effets puissants et bien visibles (matière dense, tailles généreuses, secousse, lumière à l'impact).
- La gradation de puissance doit se lire : Onde Boréale la plus petite, Blizzard la plus grosse.
- Les Pokémon n'ont pas de pose de coup de poing : pour Poing-Glace, la charge de Contact existante porte le geste.

## Étapes

1. Art : `tools/art/serie_cv_fx_glace.py` (Codex, `manifeste_glace.json`).
2. Familles, variantes et briques dans `data/battle/move_fx/` et `game/battle/fx/move_fx_player.gd`.
3. Vidéo des six attaques : `game/battle/fx/fx_gallery.tscn -- --moves=aurora_beam,ice_beam,blizzard,ice_punch,haze,mist --mode=full` (avec `--always-on-top`).
4. Validation de Kevin sur la vidéo, puis CI GitHub verte.

## Réalisation (2026-11-19)

- **Art :** `tools/art/serie_cv_fx_glace.py` (Codex, 9 flipbooks et 16 particules, `manifeste_glace.json`), sur la chaîne de `serie_cv_fx_eau.py`. Rayon, cristaux, tempête, neige et brume sombre sur magenta (la glace n'a ni rose ni violet), densifiés, en mélange normal ; ruban d'aurore (rose et violet) sur **vert** ; voile de Brume et étincelles additifs sur noir. Bords fondus plus loin pour le mur de blizzard (0,36) et les nappes de Buée Noire (0,32) ; trois particules de `part_g` nettoyées d'un bout de nappe voisine (`_BAVURES`).
- **Par attaque :** Onde Boréale `glace` (la famille du type, repeinte : courant `bolt` `ruban_aurore`, étoile `eclat_givre`) ; Laser Glace `laser_glace` (courant `bolt` `rayon_glace`, cage de cristaux `bloc_glace` qui éclate) ; Blizzard `blizzard` (brique `snowstorm` : la neige `tempete_neige` en quatre tuiles sur tout l'écran comme la pluie de Danse Pluie, mais la cible encaisse ; mur `rafale_blizzard` par `wave_sweep` ; `explosion_glace` ; la signature `blizzard` est retirée) ; Poing-Glace `poing` variante `glace` (marque `contact_givre`, étoile `etoile_cristaux`, plus de cristal de la vague 2) ; Buée Noire `brume` (nappes `nappe_buee` bleu nuit, plus nombreuses et plus grandes, décor plus sombre) ; Brume `voile_brume` (brique `shield`, aura `voile_brume` sur le lanceur).
- **Valeurs par défaut [D] :** `bolt_height` (Onde Boréale 0,26, Laser Glace 0,42), `impact_size` (1,8, 2,6, Blizzard 3,2), secousses (3, 5, 7) et volée de Buée Noire (7 nappes, 0,85) dans `families.json`.
