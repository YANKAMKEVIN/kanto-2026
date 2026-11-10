# Refonte des attaques Psy (décidée le 2026-11-10)

Suite de la refonte par famille de types, après l'Électrik, le Feu et l'Eau (`attaques-electriques.md`, `attaques-feu.md`, `attaques-eau.md`). Avant : Choc Mental, Rafale Psy, Vague Psy, Psyko, Dévorêve, Prescience, Hypnose et Voile Miroir envoyaient les mêmes anneaux roses génériques ; Yoga, Hâte, Bouclier, Protection, Mur Lumière et Amnésie montraient l'aura jaune commune à tous les types (`statut_plus`), Repos la lueur verte du soin.

**Direction retenue par Kevin : A, « psy peint »**, rose vif, magenta et violet, cœurs blanc rosé, coups de pinceau visibles ; la même main que la foudre, la flamme et l'eau peintes. Planches de référence : `docs/design/references/attaques/psy_direction_A1.png` (attaques 1 à 9) et `psy_direction_A2.png` (statuts 10 à 17) ; directions B « cosmos mental » et C « prisme » écartées. Elles donnent la direction, pas un dessin à reproduire au pixel (règle 10 de `CLAUDE.md`) : les petits cœurs dessinés par Codex sur la planche A ne sont pas repris.

**Décision de Kevin : les 17 attaques sont refaites** (aucune gardée telle quelle).

## Les dix-sept attaques

| N° | Attaque | Puissance | Effet visuel à obtenir | Effet avant |
|---|---|---|---|---|
| 1 | Choc Mental | 50 | Onde de distorsion compacte qui enserre la cible ; rien ne part du lanceur | `psy` (anneaux) |
| 2 | Rafale Psy | 65 | Rayon enfilé d'anneaux psychiques, du lanceur à la cible | `psy` |
| 3 | Vague Psy | variable | Deux ondes sinusoïdales épaisses du lanceur à la cible | `psy` |
| 4 | Psyko | 90 | Sphère qui enveloppe la cible, se comprime et explose ; la plus forte | `psy`, signature `psyko` |
| 5 | Dévorêve | 100 | Brume de rêve arrachée de la cible et aspirée par le lanceur | `psy` + `drain` |
| 6 | Prescience | 80 | Œil de lumière au-dessus du lanceur, puis colonne de lumière sur la cible | `psy` |
| 7 | Hypnose | statut | Anneaux hypnotiques en série, spirales autour de la cible | `psy` |
| 8 | Télékinésie | statut | Cuiller de lumière tordue au-dessus du lanceur, la cible ondule | `cuiller` |
| 9 | Téléport | statut | Le lanceur file dans une colonne de lumière | `teleport` |
| 10 | Yoga | statut | Halo et volutes de méditation autour du lanceur | `statut_plus` |
| 11 | Hâte | statut | Traînées de vitesse autour du lanceur | `statut_plus` |
| 12 | Bouclier | statut | Mur de cristal à alvéoles hexagonales devant le lanceur | `statut_plus` |
| 13 | Protection | statut | Panneau de verre lisse et réfléchissant devant le lanceur | `statut_plus` |
| 14 | Mur Lumière | statut | Rideau de bandes de lumière dorée et rosée devant le lanceur | `statut_plus` |
| 15 | Amnésie | statut | Brume qui s'échappe de la tête du lanceur et se dissipe | `statut_plus` |
| 16 | Voile Miroir | statut | Miroir courbe irisé devant le lanceur | `psy` |
| 17 | Repos | statut | Lueur de soin et « Z » au-dessus du lanceur (il reste debout : pas de pose couchée) | `soin` |

## Contraintes

- Barre de qualité : `docs/tech/combat-vivant.md` §2.9 (couches, flipbooks peints, validation **en vidéo**).
- Retour de Kevin sur l'Eau appliqué d'emblée : effets puissants et bien visibles (matière dense, tailles généreuses, secousse, lumière à l'impact).
- Les Pokémon n'ont pas d'autre pose que debout : Repos (en boule sur la planche) et Hâte (images rémanentes) sont rendus par l'effet seul.
- La gradation de puissance doit se lire : Choc Mental petit, Psyko le plus gros.

## Étapes

1. Art : `tools/art/serie_cv_fx_psy.py` (Codex, `manifeste_psy.json`) ; l'art est rose, donc détouré sur **vert** (jamais sur magenta).
2. Familles et briques dans `data/battle/move_fx/` et `game/battle/fx/move_fx_player.gd`.
3. Vidéo des dix-sept attaques : `game/battle/fx/fx_gallery.tscn -- --moves=confusion,psybeam,psywave,psychic,dream_eater,future_sight,hypnosis,kinesis,teleport,meditate,agility,barrier,reflect,light_screen,amnesia,mirror_coat,rest --mode=full` (avec `--always-on-top`).
4. Validation de Kevin sur la vidéo, puis CI GitHub verte.

## Réalisation (2026-11-10)

- **Art :** `tools/art/serie_cv_fx_psy.py` (Codex, 21 flipbooks et 16 particules, `manifeste_psy.json`). Masses denses (onde, implosion, rayons, brume, spirales, murs, auras) sur fond vert en mélange normal, densifiées ; œil, éclat, lueur de Repos et colonnes en additif sur noir.
- **Par attaque :** Choc Mental `psy` (plus de trajet : regard puis `onde_choc_psy` sur la cible) ; Psyko signature `psyko` (`implosion_psy`, aura `aura_psy`, secousse 6) ; Rafale Psy `rafale_psy` et Vague Psy `vague_psy` (courant `bolt` : `rayon_anneaux`, `onde_sinus`) ; Dévorêve `devoreve` (rôle `drain_band` : `brume_reve` de la cible au lanceur) ; Prescience `prescience` (rôle `eye` : `oeil_lumiere` ; colonne `colonne_psy` par `ground_pillar`) ; Hypnose `hypnose` (ondes `rings` d'`anneau_hypnose`, `spirale_hypnose`) ; Télékinésie `cuiller` et Téléport `teleport` (art refait) ; Yoga `yoga`, Hâte `hate` (aura) ; Amnésie `amnesie`, Repos `repos` (rôle `crown` au-dessus de la tête) ; Bouclier `bouclier`, Protection `protection`, Mur Lumière `mur_lumiere`, Voile Miroir `voile_miroir` (brique `barrier_wall`, rôle `wall` devant le lanceur).
- **Valeurs par défaut [D] :** `bolt_height`, `impact_size` et secousses dans `families.json` ; `WALL_SIZE`, `WALL_AHEAD`, `EYE_SIZE`, `CROWN_SIZE`, `DREAM_HEIGHT` de `move_fx_player.gd`.
