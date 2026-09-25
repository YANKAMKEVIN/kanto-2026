---
name: world-tiles
description: Construction du monde de Kanto 2026 dans Godot 4.7 — 2D HD atmosphérique, cases 96 px, TileSet, TileMapLayer et props, structure d'une carte, déplacement case par case, collisions, portes et changements de zone, herbes hautes, PNJ, tri en profondeur, jour/nuit, tuiles provisoires. À charger avant de créer ou modifier une carte, le joueur, un PNJ ou un déclencheur.
---

# Monde et tuiles

## Direction artistique à respecter

**2D HD atmosphérique** (voir `docs/design/vision.md`) : décors 2D haute définition très détaillés, légèrement texturés pixel art ; personnages et Pokémon en pixel art fin ; lumière dynamique. Benchmark : `docs/design/reference/bourg-palette-aplus-v1.png`. **Pas de répétition visible** : un sol en tuiles, mais les éléments marquants (arbres, maisons, rochers, massifs) sont des **props uniques ou à variantes**, placés à la main.

## Échelle

- **Case = 96×96 px** en unités monde. Les unités monde = pixels de la résolution de référence (1080 p de haut) ; `Camera2D` **zoom 1** → ≈ 11 cases de haut, ≈ 24 de large sur S24.
- **Décors HD** dessinés à **1:1** (une tuile de sol = 96×96 px de texture), filtre `linear` (défaut du projet).
- **Personnages et Pokémon du monde** : pixel art **64 px de haut** en natif, `scale = 2` (128 px ≈ 1,33 case), `texture_filter = NEAREST` sur le nœud. Origine du sprite **aux pieds** (bas-centre de la case).
- `snap_2d_transforms_to_pixel` actif ; positions de caméra arrondies.

## Sol, props et collisions

- **Sol** (`Ground`, `Detail`) : `TileMapLayer` en tuiles 96 px, avec **terrains** (auto-tiling des transitions herbe/chemin/sable/eau) et **plusieurs variantes** par type (tirées au hasard avec une graine fixe par carte) pour casser la répétition.
- **Props** (`game/world/props/prop.tscn`, `class_name WorldProp`) : arbres, maisons, rochers, clôtures, lampadaires, bancs… = `Sprite2D` HD dans `Entities` (y-sort), origine au pied. Chaque prop déclare son **empreinte** (`@export var footprint: Array[Vector2i]`, cellules relatives) que `GridWorld` marque comme solides. Les cimes et toits dépassent naturellement devant/derrière le joueur grâce au y-sort.
- Petites animations d'ambiance (feuillage, fumée, eau) : `AnimatedSprite2D` ou shaders légers, toujours discrets.

## TileSet et couches

`TileMap` est obsolète : utiliser des **`TileMapLayer`** (un nœud par couche), partageant un même `TileSet` (`assets/tiles/overworld.tres`).

Couches d'une carte (de bas en haut) :
| Nœud | Contenu | z_index |
|---|---|---|
| `Ground` | herbe rase, chemins, sable, eau | 0 |
| `Detail` | fleurs, bordures, ombres au sol | 0 |
| `Obstacles` | tuiles solides simples (bordures d'eau, falaises) — le reste = props | 0 |
| `Entities` (Node2D, `y_sort_enabled`) | joueur, PNJ, Pokémon visibles, **props** (arbres, bâtiments, rochers…) | 0 |
| `Overhead` | rares éléments toujours devant (arches, feuillage en surplomb) | 10 |

**Custom data layers** du TileSet (lues par la logique de grille) :
- `solid: bool` — case infranchissable
- `tall_grass: bool` — rencontres possibles (+ animation de l'herbe au passage)
- `water: bool` — infranchissable à pied (Surf plus tard)
- `ledge: int` — rebord sautable (0 = aucun, sinon direction 1 bas, 2 gauche, 3 droite)

## Déplacement : grille, pas physique

- Le joueur et les PNJ se déplacent **case par case** (`Vector2i` de cellule). La position écran est interpolée (Tween) : marche ≈ 0,22 s/case, course ≈ 0,12 s/case.
- La question « puis-je entrer dans cette case ? » est tranchée par une classe logique pure `GridWorld` (`game/world/grid_world.gd`, `RefCounted`) qui combine : données des tuiles (`solid`, `water`, `ledge`) + **occupation** (dictionnaire cellule → entité pour PNJ/objets). Pas de `CharacterBody2D` / `move_and_slide` pour les déplacements.
- Entrée continue : tant que la direction est maintenue, on enchaîne les cases sans pause ; un appui très court tourne le personnage sans avancer (comportement Pokémon).
- `GridWorld` est testé unitairement (cases bloquées, rebords, occupation).

## Structure d'une carte

`game/world/maps/<id>.tscn`, racine `Node2D` avec script `map.gd` (`class_name GameMap`) :
```
PalletTown (GameMap)       @export map_id, display_name, region, music
├─ Ground / Detail / Obstacles (TileMapLayer)
├─ Entities (Node2D, y_sort_enabled)
│   ├─ Props… (WorldProp : maisons, arbres, labo… empreinte → GridWorld)
│   └─ NPCs… (instances de npc.tscn)
├─ Overhead (TileMapLayer)
├─ Warps (Node2D)          instances warp.tscn : cellule, target_map, target_spawn
├─ Spawns (Node2D)         Marker2D nommés (from_route_1, from_player_house…)
└─ Triggers (Node2D)       zones d'événements (scène de Chen dans l'herbe…)
```
- **Warps / triggers** : définis en cellules et testés par la grille quand le joueur **arrive** sur la case (pas de chevauchement physique). Un `Area2D` (couche 5 « declencheurs ») n'est utilisé que pour des zones larges non alignées.
- Changement de carte via l'autoload `SceneRouter` (fondu, chargement, placement au spawn, orientation conservée).
- Intérieurs = cartes séparées (`player_house_1f`, `oak_lab`…).

## Taille de Bourg Palette

Original ≈ 20×18 cases. **A+ validée** (≈ ×3–4 en surface ≈ ×2 en longueur) → environ **40–48 × 32–36 cases** (le concept golden hour fait ~48×32). **Kevin a tranché : on garde la taille du concept** ; la vitesse de marche se règle au test sur téléphone. Jardins de recherche et sentier secret **derrière (au sud du) labo**. Voir `docs/design/dossier-01-bourg-palette.md` pour les zones.

## PNJ

`game/world/npc/npc.tscn` : sprite 4 directions, `@export` dialogue_id, comportement (`static`, `look_around`, `wander(rayon)`, `route(points, horaires)`). Occupent leur case dans `GridWorld`. Routines horaires pilotées par `GameClock`.

## Jour / nuit

La lumière est **la signature graphique** du jeu. `CanvasModulate` sur la carte, couleur interpolée selon `GameClock` entre les ambiances clés : 07:00 froide et brumeuse · 12:30 neutre et franche · 18:45 dorée, ombres longues · 23:30 bleu profond (+ pluie plus tard). Fenêtres et lampadaires : `PointLight2D` qui s'allument le soir (le renderer mobile gère les lumières 2D ; rester sobre en nombre). Les couches d'UI ne sont pas affectées (CanvasLayer).

## Assets provisoires

Tant que les vrais assets n'existent pas (ils seront produits selon un Art Bible, pas avant) :
- Générer des tuiles **provisoires 96×96 aux dimensions finales**, et des props provisoires (formes simples : arbre = tronc + cime ronde, maison = murs + toit) avec leur empreinte réelle, avec un script d'outil (`tools/gen_placeholder_tiles.gd`, API `Image`), palette cohérente (herbe verte, chemin beige, eau bleue, obstacle brun, herbe haute vert foncé), petit motif pour lire la grille.
- Les ranger dans `assets/tiles/placeholder/` ; le remplacement par le vrai tileset ne doit changer que les textures, pas les cartes (mêmes coordonnées d'atlas et custom data).
- Personnages provisoires : sprites pixel art 32×64 natifs (affichés ×2) de couleurs distinctes avec un repère de direction.
