# Jalon 1 — Se promener dans Bourg Palette

> Objectif jouable sur le S24 : le jeu démarre directement dans Bourg Palette, devant la maison du joueur. On se déplace case par case, au clavier sur Mac et au joystick tactile sur le téléphone, en marchant ou en courant. La caméra suit le joueur sans sortir de la carte. Bâtiments, arbres, eau et clôtures bloquent le passage. Le titre « BOURG PALETTE / Kanto » s'affiche à l'arrivée.
>
> Hors périmètre : intérieurs, portes fonctionnelles, PNJ, dialogues, Chen, jour/nuit, rencontres, sauvegarde, `SceneRouter`, `GameState`. Les graphismes sont provisoires mais ont leurs dimensions finales.

Références : `CLAUDE.md`, skills `godot-conventions`, `world-tiles` et `ui-theme-2026`, `docs/design/dossier-01-bourg-palette.md`, et l'image `docs/design/reference/bourg-palette-aplus-v1.png`.

---

## 1. Fondations déjà posées (architecte, testées)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/world/grid.gd` | `Grid` | **Constantes partagées** : `TILE_SIZE = 96`, `WALK_STEP_DURATION = 0.22`, `RUN_STEP_DURATION = 0.12`, `LEDGE_JUMP_DURATION = 0.40`, `TURN_HOLD_DURATION = 0.09`. On règle les vitesses **ici seulement**. Conversions : `cell_to_world(cell)` donne les pieds, au milieu du bord bas de la case ; `world_to_cell(pos)` fait l'inverse ; `map_pixel_rect(size)` sert aux limites de caméra ; `is_cardinal(dir)`. |
| `game/world/grid_world.gd` | `GridWorld` | Règles d'accès aux cases d'une carte : limites, `set_solid`, `set_water`, `set_ledge` (enum `Ledge` : 0 aucun, 1 bas, 2 gauche, 3 droite, comme la donnée de tuile), `add_solid_footprint(anchor, footprint)` et occupation (`occupy`, `release`, `move_occupant`, `get_occupant`). **Règle unique : `can_enter(cell, direction, mover)`.** Dérivés : `get_step_target(from, dir, mover)` donne la case d'arrivée (saut de rebord compris, `from` si le pas est bloqué) ; `find_reachable(start)` sert aux tests d'accessibilité des cartes. |
| `game/world/grid_mover.gd` | `GridMover` | Contrôleur de déplacement pur. `update(delta, direction, run)` à chaque image. Il gère le pivot sur appui bref, le départ immédiat dans la direction regardée, l'enchaînement sans pause (le temps restant est reporté), le changement de direction en marche sans délai, la course, le saut de rebord et la réservation de la case d'arrivée dès le départ du pas. Signaux : `facing_changed(direction)`, `step_started(from, to, running)`, `step_finished(cell)`, `bumped(direction)` (une fois par poussée contre un obstacle). La position à afficher s'obtient par `get_world_position()`. |
| `game/systems/input/direction_input.gd` | `DirectionInput` | `update(up, down, left, right)` réduit les quatre actions à une direction : la dernière pressée encore tenue l'emporte. La méthode statique `quantize(vector, previous)` transforme le vecteur du joystick en direction cardinale, avec une zone morte de 0,3 et une hystérésis de 20 % qui évite le va-et-vient en diagonale. |

Tests : `tests/unit/test_grid.gd`, `test_grid_world.gd`, `test_grid_mover.gd`, `test_direction_input.gd`.

**Convention de position (importante pour tous)** : l'origine d'une entité ou d'un prop est **aux pieds**, au milieu du bord bas de sa case d'ancrage : `position = Grid.cell_to_world(cell)`. Une case couvre l'intervalle vertical ]haut, bas] : `world_to_cell` renvoie bien la case d'ancrage, que l'on parte de ce point ou du centre de la case. Les sprites sont décalés vers le haut (`offset`) pour que leur bas-centre tombe sur l'origine. Le y-sort fonctionne alors naturellement.

---

## 2. Arbre des scènes et des scripts

```
game/boot.tscn                      scène principale (run/main_scene inchangé)
Boot (Node)  game/boot.gd  class_name Boot
├─ World (Node2D)
│   └─ PalletTown  (instance de game/world/maps/pallet_town.tscn)   %PalletTown
└─ ExplorationHud (instance de game/ui/hud/exploration_hud.tscn)     %ExplorationHud
```
`Boot._ready()` : instancie `game/player/player.tscn`, appelle `%PalletTown.spawn_player(player, &"start", Vector2i.DOWN)`, puis `%ExplorationHud.show_zone_title(map.display_name, map.region)`. Ce câblage provisoire sera repris plus tard par l'autoload `SceneRouter`, avec les portes. **Aucun autoload dans ce jalon.**

```
game/world/maps/pallet_town.tscn    générée par tools/build_pallet_town.gd
PalletTown (Node2D)  game/world/map.gd  class_name GameMap
│   @export map_id = &"pallet_town", display_name = "Bourg Palette", region = "Kanto",
│   @export size = Vector2i(48, 34)
├─ Ground     (TileMapLayer, TileSet assets/tiles/overworld.tres)
├─ Detail     (TileMapLayer)
├─ Obstacles  (TileMapLayer)
├─ Entities   (Node2D, y_sort_enabled)     %Entities  ← props + joueur
│   └─ WorldProp…
├─ Overhead   (TileMapLayer, z_index 10)   (vide pour ce jalon)
├─ Warps (Node2D)      (vide)
├─ Spawns (Node2D)     Marker2D « start » posé sur Grid.cell_to_world(Vector2i(36, 10))
└─ Triggers (Node2D)   (vide)
```

| Script | `class_name` | Responsabilités |
|---|---|---|
| `game/world/map.gd` | `GameMap` (Node2D) | Dans `_ready`, construit **un** `GridWorld(size)`. Il lit les données `solid`, `water` et `ledge` de chaque cellule utilisée dans `Ground`, `Detail` et `Obstacles` (`get_cell_tile_data(c).get_custom_data(...)`), puis ajoute l'empreinte de chaque `WorldProp` enfant de `Entities`. Il expose `get_grid() -> GridWorld`, `get_pixel_rect() -> Rect2i`, `get_spawn_cell(name: StringName) -> Vector2i` et `spawn_player(player: Player, spawn: StringName, facing: Vector2i)`, qui ajoute le joueur à `Entities` puis appelle `player.enter_map(...)`. |
| `game/world/props/prop.gd` + `prop.tscn` | `WorldProp` (Node2D) | Élément de décor HD unique : `Sprite2D` %Sprite, filtre linear, bas-centre sur l'origine. Il porte `@export var footprint: Array[Vector2i]` (cellules relatives à la case d'ancrage) et `get_anchor_cell() -> Vector2i` (`Grid.world_to_cell(position)`). Chaque type de prop est une scène héritée dans `game/world/props/` (`house_player.tscn`, `oak_lab.tscn`, `tree_oak_a.tscn`…). |
| `game/player/player.gd` + `player.tscn` | `Player` (Node2D) | Présentation et relais d'entrée. Il possède un `GridMover` (occupant = lui-même) et un `DirectionInput`. `enter_map(grid: GridWorld, cell: Vector2i, facing: Vector2i, bounds: Rect2i)` place le joueur et règle les limites de la caméra. Dans `_process`, il lit les actions, appelle `mover.update`, fait `position = mover.get_world_position().round()` et choisit l'animation (`idle_<dir>`, `walk_<dir>`, `run_<dir>` ; sur `bumped`, marche sur place). Il relaie les signaux `moved(cell)` (depuis `step_finished`), `facing_changed(direction)` et `bumped(direction)`. |
| `game/ui/theme/ui_tokens.gd` | `UiTokens` | Tokens du skill `ui-theme-2026`. |
| `game/ui/components/zone_title.gd` + `.tscn` | `ZoneTitle` (Control) | `show_title(name: String, region: String)` : icône, NOM en MAJUSCULES (44, gras), région (24, `TEXT_MUTED`), glissement de 300 ms, maintien de 2,5 s, disparition. |
| `game/ui/components/virtual_joystick.gd` + `.tscn` | `VirtualJoystick` (Control) | Joystick flottant dans la moitié gauche, invisible au repos. Il presse ou relâche les actions `move_*` (voir §3). |
| `game/ui/components/run_button.tscn` | (scène) | `TouchScreenButton` avec `action = "run"` et un visuel de bouton rond de 128 px. |
| `game/ui/hud/exploration_hud.gd` + `.tscn` | `ExplorationHud` (CanvasLayer, layer 10) | Assemble `ZoneTitle`, `VirtualJoystick` et `RunButton`. Expose `show_zone_title(name, region)`. Il ne connaît ni le joueur ni la carte. |

Détails du `Player` :
```
Player (Node2D)  player.gd
├─ Shadow (Sprite2D, optionnel)
├─ Sprite (AnimatedSprite2D) %Sprite   texture_filter NEAREST, scale 2, pieds sur l'origine
└─ Camera (Camera2D) %Camera           zoom 1, pas de lissage, limit_* = bounds de la carte
```

---

## 3. Signaux et interfaces

```
Clavier ─┐
         ├─► InputMap : move_up/down/left/right, run ──► Player._process
Joystick ┘   (Input.action_press / action_release)         │  DirectionInput.update(4 × is_action_pressed)
RunButton ─► (TouchScreenButton, action "run")              │  GridMover.update(delta, dir, is_action_pressed(&"run"))
                                                            ▼
                                     GridMover ──► GridWorld.get_step_target / move_occupant
                                          │ signaux
                                          ▼
                    Player : position, animation ; émet moved(cell), bumped(dir)…
Boot ─► GameMap.spawn_player(player, &"start") ─► Player.enter_map(grid, cell, facing, bounds)
Boot ─► ExplorationHud.show_zone_title(map.display_name, map.region)
```

### Choix : le joystick presse les actions `move_*` avec `Input.action_press`

Le joystick convertit le vecteur du pouce avec `DirectionInput.quantize(vector, _current)`. Quand la direction change, il fait `Input.action_release(ancienne)` puis `Input.action_press(nouvelle)`. **Une seule action `move_*` est pressée à la fois.** Le bouton courir est un `TouchScreenButton` natif avec `action = "run"`, qui fait la même chose et gère le multi-touch sans code.

Pourquoi plutôt qu'un `Player.set_move_input(dir)` :
1. **Un seul chemin d'entrée** : le joueur ne lit que des actions. Clavier, joystick tactile et (plus tard) manette donnent un comportement identique, testé une seule fois.
2. **Aucun couplage entre l'UI et le joueur** : le HUD n'a pas besoin d'une référence au joueur. Rien ne casse quand le joueur est recréé ou change de carte (portes et `SceneRouter` plus tard).
3. **Testable et simulable** : les tests d'intégration et la QA pilotent le joueur avec `Input.action_press(&"move_right")`, exactement comme le joystick.
4. `TouchScreenButton.action` utilise déjà ce mécanisme dans Godot : on reste dans l'idiome du moteur.

Contraintes qui en découlent (critères d'acceptation) :
- `Input.action_press` **ne génère pas d'`InputEvent`** : le joueur doit **interroger** les actions dans `_process` (`Input.is_action_pressed`), et non les écouter dans `_unhandled_input`.
- Le joystick doit **toujours relâcher** son action : au lever du doigt, sur un toucher annulé (`InputEventScreenTouch.canceled`), et sur `NOTIFICATION_APPLICATION_FOCUS_OUT`, `NOTIFICATION_APPLICATION_PAUSED` et `NOTIFICATION_EXIT_TREE`.
- Multi-touch : le joystick suit **l'index** de son doigt (`InputEventScreenTouch`/`ScreenDrag` dans `_input`) et ignore les autres doigts ainsi que les événements souris émulés. Sur Mac, `emulate_touch_from_mouse=true` permet de le tester à la souris.

---

## 4. Spécification de la carte « pallet_town »

**Dimensions : 48 × 34 cases** (4608 × 3264 px). Deux rangées de plus que le concept, pour loger les jardins de recherche derrière le labo sans écraser la prairie ni le littoral (voir Q2). Coordonnées : x de 0 (ouest) à 47 (est), y de 0 (nord) à 33 (sud). Plages inclusives. **Tolérance : ±2 cases**, du moment que les invariants d'accessibilité (§4.4) sont respectés.

### 4.1 Zones

| Zone | Cases | Contenu |
|---|---|---|
| Lisière nord | y 0, x 0–21 et 26–47 | forêt dense (solide) |
| **Route 1** (sortie non fonctionnelle) | chemin x 23–24, y 0–3 ; clôtures bois x 22 et x 25, y 0–3 | Le chemin de terre va jusqu'au bord nord. Il est **bloqué par le bord de la carte** (hors limites = infranchissable). Rien d'autre. |
| Prairie du Nord | x 3–44, y 1–4 (hors chemin et champ) | herbe rase, fleurs, quelques arbres et rochers. Pas de hautes herbes. |
| Champ cultivé | x 34–43, y 1–2 | tuiles de culture solides, clôture en bois autour |
| Lisières ouest / est | x 0–2, y 0–25 ; x 42–47, y 0–28 | forêt (solide), arbres variés en props |
| Maison du rival | empreinte x 8–14, y 5–9 ; porte (11, 9) | jardin clôturé en piquets blancs x 6–16, y 5–11 : côtés x 6 et x 16, façade y 11 avec un portillon ouvert en (11, 11) |
| **Maison du joueur** | empreinte x 33–39, y 5–9 ; porte (36, 9) | jardin clôturé x 31–41, y 5–11, portillon (36, 11). **Spawn `start` = (36, 10), face au sud.** |
| Place centrale | x 17–31, y 12–17 (pavés) | îlot du grand arbre au centre, bancs, panneau, lampadaires. Chemins de terre depuis les deux portillons. |
| Laboratoire de Chen | empreinte x 18–30, y 18–22 ; porte (24, 22), **façade sud** | camionnette à l'ouest, parvis pavé y 23, x 17–31 |
| Pelouse ouest et falaises | x 3–16, y 12–26 | arbres, rochers ; falaises solides x 3–5, y 18–26 ; escalier en bois x 6, y 24–27 vers la plage |
| **Jardins de recherche** (derrière le labo) | x 16–36, y 24–28 | clôture blanche au nord (y 24, portillon en (24, 24)) et au sud (y 28) ; côtés x 16 et x 36. Grande serre, petite serre, potagers. |
| Couloir est | x 37–41, y 12–28 | pelouse arborée qui relie la place au sentier côtier |
| **Sentier secret** (infranchissable) | entrée (42, 26), puis x 43–46, y 26 | chemin envahi qui s'enfonce dans la forêt est. L'entrée est bouchée par un prop « ronces » et les cases suivantes sont entourées de forêt : **inaccessibles**. |
| Sentier côtier | x 7–44, y 29–30 | chemin de terre, lampadaires côté nord, barrière bois côté sud (y 31, x 15–44) |
| **Route 21** (bloquée) | x 45–47, y 29–30 | barrière bois et panneau en x 45, y 29–30. Au-delà : inaccessible. |
| Plage (sud-ouest) | x 3–14, y 27–31 | sable, rochers épars |
| Ponton | x 9, y 32–33 | terrasse bois **praticable au-dessus de l'eau** (tuile de sol non `water`) |
| Falaises / rochers côtiers | y 31, x 15–47 | solides |
| Mer | y 32–33 toute la largeur (sauf le ponton) ; x 0–2, y 26–31 | `water` |

### 4.2 Types de tuiles de sol (TileSet `assets/tiles/overworld.tres`, 96×96)

Données personnalisées : `solid: bool`, `tall_grass: bool`, `water: bool`, `ledge: int`. Au moins **2 variantes** par type.

| Type | solid | water |
|---|---|---|
| herbe rase, fleurs (Detail), chemin de terre, pavés, sable, terrasse bois (ponton, escalier) | – | – |
| sol de forêt, falaise, culture | ✔ | – |
| eau (mer), eau peu profonde du rivage | – | ✔ |

Pas de rebord (`ledge`) ni de hautes herbes dans ce jalon, mais les couches de données existent.

### 4.3 Props et empreintes

Taille du sprite en cases (L × H). L'**ancre** est la case sous l'origine (bas-centre). L'empreinte est relative à l'ancre (x vers l'est, y vers le sud ; les y négatifs vont vers le nord).

| Prop | Sprite | Empreinte | Ancres (exemples) |
|---|---|---|---|
| Maison (joueur, rival ; 2 variantes) | 7 × 6 | 7 × 5 : x −3..3, y −4..0. La rangée haute du toit déborde sans être solide. | (36, 9), (11, 9) |
| Laboratoire de Chen | 13 × 7 | 13 × 5 : x −6..6, y −4..0 | (24, 22) |
| Grand arbre de la place + îlot fleuri | 5 × 6 | 5 × 3 : x −2..2, y −2..0 | (24, 16) |
| Arbre (≥ 4 essences/variantes) | 3 × 4 | 1 × 1 (tronc) | lisières, pelouses |
| Petit arbre / buisson | 1 × 2 | 1 × 1 | jardins |
| Clôture en piquets / barrière bois (segment de N cases) | N × 1 | N × 1 : x 0..N−1, y 0 | voir zones |
| Lampadaire | 1 × 3 | 1 × 1 | place (17, 12), (31, 12), (17, 17), (31, 17) ; côte (14, 29), (26, 29), (38, 29) |
| Banc | 2 × 1 | 2 × 1 : x 0..1 | (19, 16), (28, 16) |
| Panneau « BOURG PALETTE » | 1 × 1 | 1 × 1 | (21, 13) |
| Boîte aux lettres | 1 × 1 | 1 × 1 | (13, 10), (38, 10) |
| Vélo (maison du joueur) | 1 × 1 | 1 × 1 | (40, 10) |
| Camionnette | 3 × 2 | 3 × 2 : x −1..1, y −1..0 | (15, 22) |
| Grande serre | 7 × 4 | 7 × 2 : x −3..3, y −1..0 | (20, 27) |
| Petite serre | 3 × 3 | 3 × 2 : x −1..1, y −1..0 | (33, 27) |
| Potager | 3 × 1 | 3 × 1 : x −1..1 | (27, 26), (27, 27) |
| Rocher (petit / grand) | 1 × 1 / 2 × 2 | 1 × 1 / 2 × 1 | prairie, plage |
| Ronces du sentier secret | 1 × 2 | 1 × 1 | (42, 26) |
| Barrière Route 21 | 1 × 2 | 1 × 2 : y −1..0 | (45, 30) |

Les portes font partie de l'empreinte (solides) : les intérieurs sont hors périmètre. Plus tard, la case de porte sera retirée de l'empreinte et remplacée par un warp.

### 4.4 Invariants d'accessibilité (testés)

Depuis `start` (36, 10), `GridWorld.find_reachable` doit **atteindre** : (36, 11) portillon, (23, 0) et (24, 0) haut de la Route 1, (11, 10) devant la maison du rival, (24, 17) place, (24, 23) devant le labo, (24, 25) jardins, (30, 29) et (44, 29) sentier côtier, (8, 29) plage, (9, 33) bout du ponton.

Il ne doit **pas atteindre** : toute case `water`, toute case d'empreinte de bâtiment, le champ (38, 1), le sentier secret (43, 26) à (46, 26), la Route 21 (46, 29) et (47, 30), les lisières (1, 10) et (45, 10).

---

## 5. Découpage des tâches (dans l'ordre)

### T1 — constructeur-monde : tuiles provisoires et TileSet
- `tools/gen_placeholder_tiles.gd` génère `assets/tiles/placeholder/*.png` (96×96, palette du skill, motif léger pour lire la grille), puis `assets/tiles/overworld.tres`.
- **CA** : import sans erreur. Le TileSet a une taille de tuile de 96×96 et 4 couches de données (`solid` bool, `tall_grass` bool, `water` bool, `ledge` int). Chaque type du §4.2 a ≥ 2 variantes avec les bonnes données. `tests/unit/test_overworld_tileset.gd` le vérifie, avec les coordonnées d'atlas documentées en constantes dans le générateur.

### T2 — constructeur-monde : `WorldProp`, `GameMap`, props provisoires
- `prop.tscn`/`prop.gd`, scènes héritées pour chaque prop du §4.3 (formes simples aux dimensions finales), et `map.gd`.
- **CA** : `tests/integration/test_game_map.gd` monte une mini-carte de test (quelques tuiles `solid`/`water` et un prop 3×2) avec `add_child_autofree`. Il vérifie que `get_grid()` marque exactement les bonnes cases, que `get_spawn_cell` renvoie la case du `Marker2D`, et que `get_pixel_rect()` vaut `size * 96`. Un test vérifie que l'empreinte de chaque scène de prop correspond au §4.3.

### T3 — constructeur-monde : carte `pallet_town.tscn`
- Générée par `tools/build_pallet_town.gd`, qui décrit zones et props en données (tableaux de rectangles et d'ancres) et sauvegarde avec `ResourceSaver`. Variantes tirées avec une graine fixe.
- **CA** : `tests/integration/test_pallet_town.gd` : taille 48×34, `display_name == "Bourg Palette"`, `region == "Kanto"`, spawn `start` = (36, 10), **tous les invariants du §4.4**. Capture Movie Maker de la carte entière (caméra dézoomée dans un outil de test uniquement) lue avec Read et conforme au plan du §4.1.

### T4 — constructeur-monde : joueur, caméra, `Boot`
- `player.tscn`/`player.gd` (sprite provisoire 32×64 ×2 avec repère de direction), `boot.tscn`/`boot.gd` (HUD absent tant que T5 n'est pas fait : `Boot` teste `has_node`).
- **CA** :
  - `tests/integration/test_player.gd` sur une petite `GridWorld` : `Input.action_press(&"move_right")` pendant 0,25 s simulées (appels à `_process`) amène le joueur une case plus à droite. Maintenu 1 s, il enchaîne ≥ 4 cases. Avec `run`, ≥ 8 cases par seconde. Un obstacle l'arrête et émet `bumped`. Un appui de 0,05 s dans une autre direction ne fait que tourner. `position == Grid.cell_to_world(cell)` à l'arrêt.
  - Caméra : `limit_left/top/right/bottom` = 0/0/4608/3264 ; zoom 1 ; aucun gris hors carte visible aux quatre coins (captures).
  - Au lancement de `boot.tscn` : joueur en (36, 10) face au sud, sans écran titre.
  - Capture 2340×1080 : personnage net (nearest), décor lissé (linear), joueur caché derrière le toit de sa maison quand il passe au nord de celle-ci (y-sort).

### T5 — ui-mobile : HUD d'exploration
- `UiTokens`, `ZoneTitle`, `VirtualJoystick`, `RunButton`, `ExplorationHud` ; ajout de `%ExplorationHud` dans `boot.tscn`.
- **CA** :
  - Au démarrage, « BOURG PALETTE » et « Kanto » apparaissent en haut à gauche (glissement 300 ms, 2,5 s, disparition), dans le style de la planche et à ≥ 48 px des bords.
  - Joystick : invisible au repos. Il apparaît sous le pouce dans la moitié gauche (anneau 260, pastille 110) et s'estompe en 200 ms au relâchement. **Une seule** action `move_*` est pressée à la fois, via `DirectionInput.quantize`.
  - `tests/integration/test_virtual_joystick.gd` : des `InputEventScreenTouch`/`ScreenDrag` injectés vers la droite donnent `Input.is_action_pressed(&"move_right")`. Lever le doigt, annuler le toucher ou `NOTIFICATION_APPLICATION_FOCUS_OUT` relâche **toutes** les actions `move_*`. Un deuxième doigt dans la moitié droite ne perturbe pas le joystick.
  - Bouton courir : 128 px, moitié droite, ≥ 48 px des bords ; tenu, il donne `Input.is_action_pressed(&"run")`.
  - Aucune référence au `Player` dans `game/ui/`, et aucune couleur ou taille en dur hors `UiTokens`.

### T6 — qa-mobile : validation sur S24
- Checklist `android-deploy` : tests, import, `tools/deploy_s24.sh`, logcat.
- **CA à vérifier et rapporter** : le jeu démarre dans Bourg Palette sans écran titre. Le titre de zone s'affiche puis disparaît. Un glissement adb dans la moitié gauche déplace le joueur (captures avant/après). Le bouton courir accélère. Aucune case d'obstacle n'est traversée sur un parcours scripté : maison → place → labo → côte → ponton → Route 1 → Route 21. La caméra reste dans la carte aux quatre coins. 60 fps (ou « non vérifié » si aucun moniteur). Aucune erreur ni plantage dans logcat.

---

## 6. Hypothèses prises (à confirmer, voir questions)
- Hauteur de carte : 34 au lieu de 32 (Q2).
- Entrée du labo sur la façade sud, donnant sur les jardins (Q1).
- Sortie de la Route 1 = bord de carte ; Route 21 = barrière.
- Course = bouton tenu.
- Vitesses : marche 0,22 s/case, course 0,12 s/case, à régler sur téléphone dans `Grid`.

---

## 7. Questions ouvertes pour Kevin

1. **Entrée du labo et jardins « derrière ».** En vue de dessus 3/4, seule la façade sud d'un bâtiment est visible : la porte du labo doit donc être au sud, comme dans Rouge/Bleu. Avec les jardins au sud, ils se trouvent devant la porte. Proposition : un parvis devant la porte, puis un portillon qui ouvre sur les jardins, et un accès à la côte par les côtés ouest et est du labo. Est-ce que cela te convient ?
2. **Hauteur de carte : 34 au lieu de 32.** Ces deux rangées logent les jardins sans écraser la prairie ni le littoral. Le skill `world-tiles` autorise 32 à 36. D'accord, ou faut-il rester strictement à 32 ?
3. **Sous-titre du nom de zone.** Le brief du jalon dit « Kanto », mais le déroulé d'ouverture du dossier 01 dit « Le commencement de toute aventure ». Proposition : « Kanto » à chaque arrivée, et la phrase réservée à la toute première sortie de la maison (jalon « ouverture »).
4. **Courir.** Bouton tenu (comme B), bouton bascule, ou joystick poussé à fond ? Par défaut : bouton tenu.
5. **Vitesse.** À 0,22 s/case, traverser la carte du nord au sud prend environ 7,5 s en marchant, loin des 30 à 40 s indicatifs du dossier. On garde ces valeurs pour le premier essai sur le S24, puis on les ajuste dans `Grid` ?
6. **Sortie Route 1.** Simple bord de carte (proposé), ou un élément visible qui l'explique (barrière « travaux », PNJ plus tard) ?
