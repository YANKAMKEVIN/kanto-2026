---
name: world-tiles
description: Construction du monde de Kanto 2026 dans Godot 4.7 — 2D HD atmosphérique, cases 96 px, TileSet, TileMapLayer et props, structure d'une carte, déplacement case par case, collisions, portes et changements de zone, herbes hautes, PNJ, tri en profondeur, jour/nuit, tuiles provisoires. À charger avant de créer ou modifier une carte, le joueur, un PNJ ou un déclencheur.
---

# Monde et tuiles

## Direction artistique à respecter

**2D HD atmosphérique** (voir `docs/design/vision.md`) : décors 2D haute définition très détaillés, légèrement texturés pixel art ; personnages et Pokémon peints simplifiés (même main que les décors) ; lumière dynamique. Benchmark : `docs/design/reference/bourg-palette-aplus-v1.png`. **Pas de répétition visible** : un sol en tuiles, mais les éléments marquants (arbres, maisons, rochers, massifs) sont des **props uniques ou à variantes**, placés à la main.

## Échelle

- **Case = 96×96 px** en unités monde. Les unités monde = pixels de la résolution de référence (1080 p de haut) ; `Camera2D` **zoom 1** → ≈ 11 cases de haut, ≈ 24 de large sur S24.
- **Décors HD** dessinés à **1:1** (une tuile de sol = 96×96 px de texture), filtre `linear` (défaut du projet).
- **Personnages et Pokémon du monde** : **peints simplifiés** (décision de Kevin, 2026-10-03), planches 4 × 4 (bas, gauche, droite, haut × 4 images), héros **128 px de haut** affichés à 1:1 (≈ 1,33 case), `texture_filter = LINEAR`. Origine du sprite **aux pieds**. Voir `docs/design/cahier-art-monde-v0.1.md` §4.
- Apparence d'un personnage : `CharacterLook` (`game/world/character_look.gd`) — peinte 1:1 LINEAR si `assets/sprites/characters/painted/<id>_frames.tres` existe, sinon provisoire ×2 NEAREST. Le joueur = `player` (héros peint, marche + course). Pokémon du monde peints : `"sprite": "pokemon/<espèce>"` (explicite ; `"pidgey"` seul reste provisoire). Correspondance planches (français) → identifiants (anglais) : table `LOOKS` de `tools/build_character_frames.gd`. Ombre : l'ellipse `shadow.png` pour tous.
- `snap_2d_transforms_to_pixel` actif ; positions de caméra arrondies.

## Sol, props et collisions

**Depuis le jalon 7 (cartes peintes, `GameMap.light_profile` non vide)** — le sol ne se lit plus en tuiles : les transitions peintes par tuiles ont échoué au prototype (`docs/tech/jalon-07.md` §6.6).
- **Sol peint** : `PaintedGround` (`game/world/ground/`), un seul rectangle de la taille de la carte dessiné par `ground_blend.gdshader` : herbe, pavés (× 0,7) et chemin de terre mélangés par un **masque** `GroundMask` (1 px = 1 case ; R = pavés, G = chemin ; frontière bruitée + fine bande de terre). L'outil de construction écrit le masque dans `assets/world/maps/<carte>_ground.png`. Textures : `assets/world/ground/ground_{herbe,paves,chemin}_01.png` (384 px = 4 × 4 cases, mipmaps).
- **`Ground` reste dans la carte, invisible** : c'est la **source logique** (solide, herbes hautes, rebords) lue par `GameMap` / `GridWorld`, inchangés.
- **Décalcomanies** de bordure (terre, pavés déchaussés, touffes) : `BorderDecals.plan(cases_pavées, taille, graine)` (graine fixe par carte), posées dans `GroundDecals` (Node2D non trié).
- **Objets peints** : scènes générées `game/world/props/painted/<id>.tscn` par `tools/build_painted_props.gd` depuis `assets/world/catalogue.json` ; emprises dans `PaintedPropRules` (règles du prototype). Origine = **pied** (milieu du bas de l'image) ; largeur paire → pied sur un **bord** de case, impaire → au **milieu** (`PaintedPropRules.foot_position(id, case)`). Portes du Centre et de la Boutique : 2 cases libres au bas de l'emprise (la carte y pose ses passages) ; Arène et maisons fermées.
- **Falaises, escaliers, massif** = couche du **sol** (`GroundDecals`), jamais dans `Entities` : une face de falaise ou un escalier ne passe jamais devant un personnage. `GameMap` lit les emprises des `WorldProp` de `Entities` **et** de `GroundDecals`.
- **Ordre de dessin** (z absolus) : sol peint −3 (`WorldLighting.Z_GROUND`), ombres −2, décalcomanies et relief −1, `Entities` 0 (tri par les pieds).
- Nouvel art : `tools/art/preparer.py` (manifeste) → `godot --headless --path . --import` → `tools/build_painted_props.gd` / `tools/build_character_frames.gd`. Un objet sans règle d'emprise fait échouer l'outil.

**Cartes provisoires** (Bourg Palette, Route 1, intérieurs existants, jusqu'à la phase DA) :
- **Sol** (`Ground`, `Detail`) : `TileMapLayer` en tuiles 96 px, avec **terrains** (auto-tiling des transitions herbe/chemin/sable/eau) et **plusieurs variantes** par type (tirées au hasard avec une graine fixe par carte) pour casser la répétition.
- **Props** (`game/world/props/prop.tscn`, `class_name WorldProp`) : arbres, maisons, rochers, clôtures, lampadaires, bancs… = `Sprite2D` HD dans `Entities` (y-sort), origine au pied. Chaque prop déclare son **empreinte** (`@export var footprint: Array[Vector2i]`, cellules relatives) que `GridWorld` marque comme solides. Les cimes et toits dépassent naturellement devant/derrière le joueur grâce au y-sort.
- Petites animations d'ambiance (feuillage, fumée, eau) : `AnimatedSprite2D` ou shaders légers, toujours discrets.

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

## Lumière C2 et jour / nuit

**Jalon 7** : `WorldLighting` (`game/world/lighting/`, `CanvasLayer` `UiTokens.LAYER_WORLD_GRADE`) applique un `LightProfile` (`data/world/lighting.json`, nommé par `GameMap.light_profile`) : `global uniform` des shaders (liseré, vent, couleurs des ombres, gains), étalonnage d'écran par zones (`screen_grade`), ombres portées (groupe `cast_shadows`, pré-floutées, écrasement/inclinaison posés une fois) et de contact (groupe `contact_shadows`). **Profil vide = aucun effet.** « Économie » coupe vent et liseré. Matériaux partagés : `game/world/lighting/materials/`. Vérifier avec `tools/capture_lighting.gd` (place du prototype, captures et `[perf]`).

Plus tard (phase 10) :

La lumière est **la signature graphique** du jeu. `CanvasModulate` sur la carte, couleur interpolée selon `GameClock` entre les ambiances clés : 07:00 froide et brumeuse · 12:30 neutre et franche · 18:45 dorée, ombres longues · 23:30 bleu profond (+ pluie plus tard). Fenêtres et lampadaires : `PointLight2D` qui s'allument le soir (le renderer mobile gère les lumières 2D ; rester sobre en nombre). Les couches d'UI ne sont pas affectées (CanvasLayer).

## Assets provisoires

Tant que les vrais assets n'existent pas (ils seront produits selon un Art Bible, pas avant) :
- Générer des tuiles **provisoires 96×96 aux dimensions finales**, et des props provisoires (formes simples : arbre = tronc + cime ronde, maison = murs + toit) avec leur empreinte réelle, avec un script d'outil (`tools/gen_placeholder_tiles.gd`, API `Image`), palette cohérente (herbe verte, chemin beige, eau bleue, obstacle brun, herbe haute vert foncé), petit motif pour lire la grille.
- Les ranger dans `assets/tiles/placeholder/` ; le remplacement par le vrai tileset ne doit changer que les textures, pas les cartes (mêmes coordonnées d'atlas et custom data).
- Personnages provisoires : sprites pixel art 32×64 natifs (affichés ×2) de couleurs distinctes avec un repère de direction.
