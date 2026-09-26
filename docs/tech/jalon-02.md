# Jalon 2 — Portes et intérieurs

> Objectif jouable sur le S24 : le jeu démarre dans la **chambre** du joueur. On descend l'escalier, on sort de la maison par le tapis, et « BOURG PALETTE / Kanto » s'affiche à cette première sortie. On peut ensuite entrer et sortir de sa maison, de la maison du rival (rez-de-chaussée et chambre) et du laboratoire de Chen. Chaque passage se fait par un **fondu au noir** court, et les entrées sont bloquées pendant la transition. Dans les pièces plus petites que l'écran, la carte est centrée sur un fond sombre.
>
> C'est la fin de la phase 2 « Moteur d'exploration » (portes, zones, caméra) et le premier pas de la vertical slice « sortir de chez soi ».

**Hors périmètre** :
- PNJ : mère, sœur du rival, Chen, chercheurs, Pokémon du labo. Des cases leur sont **réservées** et restent libres (§4).
- Dialogues, bouton contextuel, objets examinables (PC, télé, étagères, Poké Balls) : phase 3.
- Portes animées, sons, musique par carte.
- Lumière des fenêtres et jour/nuit en intérieur : phase 10.
- La phrase « Le commencement de toute aventure », l'écart de caméra de l'ouverture et l'écran titre : jalon « ouverture ».
- Mini-carte, menu.
- **Pas de sauvegarde** : aucune progression n'existe encore à conserver. Chaque lancement repart de la chambre, comme une nouvelle partie. La sauvegarde arrivera avec `GameState` (drapeaux d'histoire, équipe) en fin de vertical slice.
- **Pas de `GameState`** : la seule donnée qui survit à un changement de carte est la carte courante, et c'est le routeur qui la tient. `GameState` naîtra en phase 3 avec le premier drapeau d'histoire (mère qui a parlé, starter reçu).

Références : `CLAUDE.md`, [`jalon-01.md`](jalon-01.md) (conventions de position, `GameMap`, `WorldProp`, §7), skills `godot-conventions`, `world-tiles` et `ui-theme-2026`, et `docs/design/dossier-01-bourg-palette.md` (§1 maison du joueur, §2 maison du rival, §4 laboratoire, déroulé d'ouverture).

---

## 1. Fondations déjà posées (architecte, testées)

| Fichier | `class_name` | Rôle |
|---|---|---|
| `game/world/warp.gd` | `Warp` | **Donnée pure d'un passage** : `cell`, `trigger` (enum `Trigger { STEP_ON, PUSH }`), `direction`, `target_map`, `target_spawn` et `facing` (orientation d'arrivée, ZERO = garder celle du joueur). `matches_step(cell, dir)` : un pas **terminé** sur la case, dans la direction exigée (ZERO = n'importe laquelle), déclenche le passage. `matches_push(cell, dir)` : pousser depuis la case dans `direction` déclenche le passage. `get_arrival_facing(current)` renvoie l'orientation à l'arrivée. `is_valid()` vérifie que la cible est renseignée, que les directions sont nulles ou cardinales et qu'un `PUSH` a une direction. |
| `game/world/warp_table.gd` | `WarpTable` | Warps d'une carte, indexés par case : `add(warp) -> bool` (refuse un warp invalide ou **ambigu** : deux `STEP_ON` qui acceptent la même direction sur une même case, ou deux `PUSH` de même direction), `find_on_step(cell, dir)`, `find_on_push(cell, dir)`, `get_at(cell)`, `get_all()`, `size()`. |
| `game/world/camera_framing.gd` | `CameraFraming` | `limits_for(map_rect, view_size) -> Rect2i`. Sur un axe où la carte dépasse la vue, les limites sont celles de la carte. Sur un axe où elle est plus petite, elles sont élargies symétriquement jusqu'à la taille de la vue : la caméra ne bouge plus et la pièce est **centrée**. `is_static(map_rect, view_size)` dit si la carte tient entièrement à l'écran. |
| `game/world/zone_announcer.gd` | `ZoneAnnouncer` | `should_announce(zone_name, interior) -> bool`. Le titre ne s'affiche que pour une zone **extérieure** différente de la dernière annoncée (voir Q3). `reset()`, `get_last_announced()`. |
| `game/world/map_catalog.gd` | `MapCatalog` | Donne l'emplacement d'une carte à partir de son identifiant : `scene_path(&"oak_lab")` renvoie `res://game/world/maps/oak_lab.tscn`. `has_map(id)`. Il n'y a aucun registre à tenir à jour. |
| `game/world/grid_mover.gd` | `GridMover` (modifié) | `set_locked(bool)` / `is_locked()`. Une entité verrouillée **termine le pas en cours**, n'en enchaîne aucun autre, ignore les directions (ni pivot ni `bumped`), et reste verrouillée après un `place()`. Un verrou posé **depuis un gestionnaire de `step_finished`** empêche aussi le pas qui s'enchaînerait dans le même `update()`. Sans cela, un joueur qui tient la direction ferait un pas de plus après la porte pendant le fondu. |

Tests : `tests/unit/test_warp.gd`, `test_camera_framing.gd`, `test_zone_announcer.gd`, `test_map_catalog.gd` et 5 tests de verrou dans `test_grid_mover.gd`. **203 tests verts** (173 + 30).

---

## 2. Architecture

### 2.1 Arbre des scènes

```
game/boot.tscn                         scène principale (run/main_scene inchangé)
Boot (Node)  game/boot.gd  class_name Boot    racine de composition, ne fait que câbler
├─ World (Node2D)                 %World          vide : SceneRouter y met la carte courante
├─ ExplorationHud (instance)      %ExplorationHud CanvasLayer 10
└─ ScreenFade (instance)          %ScreenFade     CanvasLayer 100 (T2)

Autoload « SceneRouter » : game/autoload/scene_router.gd (Node, sans class_name)
```

`Boot` :
```gdscript
@export var start_map: StringName = &"player_house_2f"
@export var start_spawn: StringName = &"start"
@export var start_facing: Vector2i = Vector2i.DOWN
var _announcer := ZoneAnnouncer.new()

func _ready() -> void:
	# instancie player.tscn
	# SceneRouter.setup(%World, player, %ScreenFade)
	# SceneRouter.transition_started → %ExplorationHud.hide_zone_title()
	# SceneRouter.map_entered → _on_map_entered(map) :
	#     if _announcer.should_announce(map.display_name, map.interior):
	#         %ExplorationHud.show_zone_title(map.display_name, map.region)
	# SceneRouter.start(start_map, start_spawn, start_facing)
func get_player() -> Player
func get_map() -> GameMap          # = SceneRouter.get_current_map()
```
Les `@export` de départ servent au développement, aux tests et aux outils de capture : on peut démarrer n'importe où sans toucher au code. On les règle **avant** `add_child`.

### 2.2 `SceneRouter` (autoload)

Il a **un seul rôle** : changer de carte. Il charge la carte, déplace le joueur, gère le fondu et bloque les entrées. Ce sera aussi le point d'entrée des scènes scriptées (Chen qui ramène le joueur au labo), des retours de combat et du chargement d'une sauvegarde. C'est ce qui justifie un autoload.

Le script est **sans `class_name`**, parce que le nom `SceneRouter` est pris par l'autoload. Les tests instancient `preload("res://game/autoload/scene_router.gd").new()` avec `add_child_autofree`, et ne touchent **jamais** à l'instance globale.

```gdscript
signal transition_started(target_map: StringName)
## Nouvelle carte en place, joueur placé ; écran encore noir (musique, GameState plus tard).
signal map_changed(map: GameMap)
## Écran visible, joueur libre (émis aussi par start()). Titre de zone.
signal map_entered(map: GameMap)

## Dossier des cartes (MapCatalog.MAPS_DIR) ; les tests peuvent le changer.
var maps_dir: String = MapCatalog.MAPS_DIR
## Tests : fabrique func(map_id: StringName) -> GameMap utilisée à la place du chargement.
var map_factory: Callable = Callable()

func setup(world: Node2D, player: Player, fade: ScreenFade = null) -> void
func start(map_id: StringName, spawn: StringName, facing: Vector2i) -> GameMap
func change_map(map_id: StringName, spawn: StringName, facing: Vector2i = Vector2i.ZERO) -> void
func is_transitioning() -> bool
func get_current_map() -> GameMap
func get_player() -> Player
```

- `setup` connecte `player.moved` et `player.bumped`, et déconnecte ceux d'un joueur précédent : `setup` peut être rappelé, par exemple à chaque test de `Boot`. Avec `fade == null`, la transition est **instantanée**.
- `start` est **synchrone** et sans fondu : il instancie la carte, l'ajoute à `world`, y place le joueur, puis émet `map_changed` et `map_entered`. Le joueur est donc en place dès la fin de `Boot._ready`.
- **Déclenchement** (le routeur ne décide rien lui-même, il interroge la table de la carte) :
  - sur `player.moved(cell)` : `warp = map.get_warps().find_on_step(cell, player.get_facing())` ;
  - sur `player.bumped(dir)` : `warp = map.get_warps().find_on_push(player.get_cell(), dir)` ;
  - s'il y a un warp et aucune transition en cours : `change_map(warp.target_map, warp.target_spawn, warp.get_arrival_facing(player.get_facing()))`.
- **Séquence de `change_map`** (coroutine) :
  1. Transition déjà en cours : on ignore et on sort.
  2. `_busy = true`, puis `player.set_input_enabled(false)` **de façon synchrone, avant tout `await`**. On est encore dans le `step_finished` du joueur, et c'est ce qui empêche le pas enchaîné (§1, verrou).
  3. `transition_started.emit(map_id)`, puis `await fade.fade_out()`.
  4. Instanciation : `map_factory`, sinon `load(MapCatalog.scene_path(map_id, maps_dir))`. Les `PackedScene` déjà chargées sont gardées dans un dictionnaire (6 cartes : mémoire négligeable, pas de relecture disque).
  5. Si la carte est inconnue ou si `map.has_spawn(spawn)` est faux : `push_error` avec la carte et le spawn, la nouvelle carte est libérée et **on reste** sur la carte courante (étape 7).
  6. `world.add_child(new_map)`, puis `new_map.spawn_player(player, spawn, facing ou player.get_facing() si ZERO)`. Ce `spawn_player` **retire le joueur de l'ancienne carte** et libère sa case. Ensuite seulement : `old_map.queue_free()`. L'ordre est impératif, sinon le joueur serait libéré avec l'ancienne carte. Enfin `map_changed.emit(new_map)`. En debug (`OS.is_debug_build()`), on journalise le temps de l'étape 4 à 6 : `SceneRouter : <id> en <n> ms`.
  7. `await fade.fade_in()`, `player.set_input_enabled(true)`, `_busy = false`, puis `map_entered.emit(current_map)`. En cas d'échec à l'étape 5, `map_entered` n'est **pas** émis.

### 2.3 Warps : format des données

Les warps sont des **données de carte**, comme les props et les spawns. Ce sont des nœuds `WarpPoint` dans `Warps`, écrits par les scripts de construction à partir de tables (§4), jamais codés dans la logique. Pas de fichier dans `data/` : un warp n'a de sens que dans sa carte, et le garder dans la scène permet de le voir et de le déplacer dans l'éditeur.

```gdscript
# game/world/warp_point.gd
class_name WarpPoint
extends Marker2D            # croix visible dans l'éditeur ; position = Grid.cell_to_world(case)
@export var trigger: Warp.Trigger = Warp.Trigger.STEP_ON
@export var direction: Vector2i = Vector2i.ZERO   # STEP_ON : pas exigé (ZERO = tous) ; PUSH : poussée
@export var target_map: StringName = &""
@export var target_spawn: StringName = &""
@export var arrival_facing: Vector2i = Vector2i.ZERO   # ZERO = garder l'orientation
func get_cell() -> Vector2i          # Grid.world_to_cell(position)
func to_warp() -> Warp
```

`GameMap` (modifié) :
- `@export var interior: bool = false` ;
- `get_warps() -> WarpTable` : table construite avec la grille, à partir des `WarpPoint` enfants de `Warps`. Un warp invalide ou ambigu provoque un `push_error("GameMap <id> : warp invalide en <case>")` ;
- `has_spawn(name) -> bool`, sans erreur (contrairement à `get_spawn_cell`).

**Convention d'arrivée : on arrive sur la case du warp de retour.** Un warp ne se déclenche pas quand on apparaît dessus : `STEP_ON` exige un pas terminé, et `PUSH` une poussée. Le passage est donc réversible sur place, sans risque d'aller-retour involontaire.

| Passage | Déclenchement | Arrivée |
|---|---|---|
| Porte extérieure (case de porte, retirée de l'empreinte du bâtiment) | `STEP_ON`, direction `UP` | tapis de la pièce, orientation conservée (vers le haut) |
| Tapis de sortie (rangée du bas de la pièce) | `PUSH`, direction `DOWN` | case de porte dehors, orientation conservée (vers le bas) |
| Escalier (case dans un coin, contre le mur du fond) | `STEP_ON`, toute direction | escalier de l'autre étage, orientation conservée |

- **Doigt toujours posé** : `Player.enter_map` remet `DirectionInput` à zéro, mais une direction encore tenue est relue dès l'image suivante. On continue donc à marcher après le fondu, comme dans les jeux. Si l'on tient HAUT en entrant, on avance dans la pièce. Si l'on tient BAS en sortant, on s'éloigne de la porte. À l'escalier, la direction d'entrée est bloquée par le coin, donc on ne repart pas dans l'autre sens. Voir Q8.
- **Sortie d'un seul geste** : si l'on descend sur le tapis en tenant BAS, le pas suivant bute sur le bord, `bumped(DOWN)` part et on sort. Si l'on se tient sur le tapis face au nord, un appui bref sur BAS fait seulement pivoter (`TURN_HOLD_DURATION`), et le maintenir fait sortir.

### 2.4 Blocage des entrées

`Player` (modifié) : `set_input_enabled(enabled: bool)` et `is_input_enabled()` appliquent `GridMover.set_locked(not enabled)`. Le drapeau est gardé dans `Player` et **réappliqué au nouveau `GridMover`** créé par `enter_map`. Joueur bloqué : il finit son pas, reste en animation `idle_*` et ne réagit ni aux directions ni à `run`. Plus tard, les actions `interact` et `menu` seront bloquées par le même drapeau. Le HUD n'est pas touché. Le joystick continue de suivre le doigt sous le rideau (le `ColorRect` ignore la souris et le toucher), ce qui permet la continuité décrite au §2.3.

### 2.5 Transition (UI)

`ScreenFade` (`game/ui/components/screen_fade.gd` + `.tscn`, `class_name ScreenFade`) :
```
ScreenFade (CanvasLayer, layer = UiTokens.LAYER_TRANSITION = 100)
└─ Curtain (ColorRect) %Curtain   plein écran (ancres 0–1), couleur UiTokens.FADE_COLOR,
                                  mouse_filter IGNORE, alpha 0 au repos
signal faded_out
signal faded_in
func fade_out(duration: float = UiTokens.ANIM_FADE_OUT) -> void   # coroutine : await fade.fade_out()
func fade_in(duration: float = UiTokens.ANIM_FADE_IN) -> void
func set_opaque(opaque: bool) -> void                             # immédiat
func is_opaque() -> bool
```
- Tokens à ajouter : `FADE_COLOR = Color(0.02, 0.03, 0.05)` (quasi noir bleuté), `ANIM_FADE_OUT = 0.2`, `ANIM_FADE_IN = 0.25`, Tween `TRANS_SINE`. Une transition complète dure donc environ 0,45 s, chargement compris.
- Avec une durée de 0, la méthode rend la main à l'image suivante (`await get_tree().process_frame`) : on peut toujours faire `await`.
- Un fondu demandé pendant un autre remplace le Tween précédent, sans saut d'opacité.

`ExplorationHud.hide_zone_title()` et `ZoneTitle.hide_now()` : le titre disparaît en `ANIM_MICRO` (0,12 s) dès `transition_started`. Sans cela, un titre encore visible réapparaîtrait par-dessus l'intérieur après le fondu.

### 2.6 Titre de zone

Règle proposée (Q3), implémentée dans `ZoneAnnouncer` :
- **aucun titre dans les intérieurs** (`GameMap.interior = true`). Ils portent `display_name = "Bourg Palette"`, `region = "Kanto"`, car le « lieu actuel » du futur menu reste la ville ;
- une zone extérieure est annoncée **quand elle diffère de la dernière annoncée**. Comme le jeu démarre dans la chambre, « BOURG PALETTE / Kanto » s'affiche à **la première sortie**, ce qui prépare le déroulé d'ouverture. Il ne s'affiche plus à chaque porte, et il reviendra au retour de la Route 1 ;
- affichage sur `map_entered`, donc après le fondu d'ouverture.

### 2.7 Caméra dans les petites pièces

- `Player._set_camera_limits(bounds)` applique `CameraFraming.limits_for(bounds, get_viewport_rect().size)`. Hors de l'arbre, il utilise `bounds` tel quel. Le joueur garde `bounds` et recalcule les limites sur `get_viewport().size_changed` (fenêtre redimensionnée sur Mac).
- Zoom 1, pas de lissage : une pièce plus petite que l'écran est **centrée et immobile**. Toutes les pièces du jalon tiennent dans l'écran (le labo, 16 × 11 = 1056 px de haut, aussi) ; le défilement d'une pièce plus grande que l'écran reste couvert par les tests de `CameraFraming`.
- **Fond** : `rendering/environment/defaults/default_clear_color = Color(0.02, 0.03, 0.05)`, la même valeur que `FADE_COLOR`, dans `project.godot`. Les cartes extérieures ne le montrent jamais (caméra bornée). Plus de gris par défaut. Une vignette ou une lueur autour des pièces pourra venir en phase 10/12 (Q5).

### 2.8 Signaux et flux

```
Player ──moved(cell)──────────► SceneRouter ─► GameMap.get_warps().find_on_step(cell, facing)
Player ──bumped(dir)──────────► SceneRouter ─► GameMap.get_warps().find_on_push(cell, dir)
                                      │ warp trouvé
                                      ▼
                 Player.set_input_enabled(false)  (synchrone → GridMover verrouillé)
                 transition_started ──► Boot ─► ExplorationHud.hide_zone_title()
                 await ScreenFade.fade_out()
                 new GameMap → World ; new_map.spawn_player(player, spawn, facing) ; old.queue_free()
                 map_changed(map)
                 await ScreenFade.fade_in()
                 Player.set_input_enabled(true)
                 map_entered(map) ──► Boot ─► ZoneAnnouncer ─► ExplorationHud.show_zone_title()
```
Ni `GameMap`, ni `Player`, ni le HUD ne connaissent `SceneRouter`. `Boot` est la seule racine de composition. Les autoloads ne se référencent pas entre eux (il n'y en a qu'un).

---

## 3. Tuiles d'intérieur

Un **second TileSet**, `assets/tiles/interior.tres`, avec les **mêmes 4 couches de données** (`solid`, `tall_grass`, `water`, `ledge`, mêmes noms, pris dans `OverworldTiles.DATA_*`) : `GameMap._read_layer` le lit sans modification. Le catalogue `game/world/interior_tiles.gd` (`class_name InteriorTiles`) est calqué sur `OverworldTiles` (enum `Kind`, `VARIANTS`, `atlas_coords`, `TEXTURE_PATH`, `TILESET_PATH`, `SOURCE_ID`). L'atlas provisoire `assets/tiles/placeholder/interior_atlas.png` est généré par `tools/gen_placeholder_tiles.gd` (étendu) ou par un `tools/gen_placeholder_interior_tiles.gd`, au choix du constructeur.

| Kind | Couche | solid | Variantes | Aspect provisoire |
|---|---|---|---|---|
| `FLOOR_WOOD` | Ground | – | 3 | parquet chaud (maisons) |
| `FLOOR_LAB` | Ground | – | 2 | carrelage clair (labo) |
| `WALL_HOUSE` | Obstacles | ✔ | 2 | mur de maison, plinthe sur la rangée basse |
| `WALL_LAB` | Obstacles | ✔ | 2 | mur blanc/gris technique |
| `STAIRS_UP` | Ground | – | 1 | marches qui montent vers le mur du fond |
| `STAIRS_DOWN` | Ground | – | 1 | trémie, marches qui descendent |
| `MAT` | Detail | – | 1 | tapis de sortie, bord inférieur marqué |
| `RUG` | Detail | – | 2 | tapis décoratif (chambres) |

**Gabarit des pièces** (hypothèse, Q7 ; **sauf la chambre du joueur**, qui suit la référence de Kevin, §4.3) : le **mur du fond occupe les rangées y 0–1** (2 cases de haut, solide). Il n'y a ni murs latéraux ni mur de façade : comme dans Rouge/Bleu, le sol va jusqu'au bord de la carte et le vide sombre fait la coupe. Le tapis de sortie est sur la **dernière rangée**.

---

## 4. Spécification des cartes

Coordonnées : x vers l'est, y vers le sud, plages inclusives. **Tolérance ±1 case** sur le mobilier, du moment que les invariants (§4.8) tiennent. Les cartes d'intérieur sont générées par `tools/build_interiors.gd`, qui décrit chaque pièce en **tables** (tuiles, props, spawns, warps) comme `build_pallet_town.gd`, puis sauvegarde avec `ResourceSaver`. Pour toutes les cartes d'intérieur : `interior = true`, `display_name = "Bourg Palette"` et `region = "Kanto"`. La structure des nœuds est identique à celle de Bourg Palette (`Ground`, `Detail`, `Obstacles`, `Entities` y-sort, `Overhead`, `Warps`, `Spawns`, `Triggers`).

### 4.1 Props d'intérieur (provisoires, dimensions finales)

Ils sont dans `game/world/props/interior/`, en scènes héritées de `prop.tscn` et générées par `tools/gen_placeholder_props.gd` (étendu). **Ancre = case en bas à gauche** (comme le banc et les clôtures) ; l'empreinte est relative à l'ancre. Aucun ne devient transparent (`fade_when_covering = false`), les pièces étant vues de face, **sauf la plante** (retouche après QA, décision de Kevin : elle cachait le joueur debout derrière elle).

| Prop | Sprite (L × H cases) | Empreinte | Utilisé dans |
|---|---|---|---|
| `window` | 2 × 1 | aucune (`[]`, posé sur le mur) | maisons |
| `window_lab` | 3 × 1 | aucune | labo |
| `wall_map` (carte de Kanto au mur) | 2 × 1 | aucune | chambre du rival |
| `desk_pc` (bureau + PC) | 2 × 2 | 2 × 1 : x 0..1 | chambre du joueur |
| `desk_maps` (bureau couvert de cartes) | 2 × 2 | 2 × 1 | chambre du rival |
| `bookshelf` | 2 × 2 | 2 × 1 | chambres, rez-de-chaussée |
| `trophy_case` (vitrine de trophées juniors) | 2 × 2 | 2 × 1 | chambre du rival |
| `tv_console` (télé sur meuble bas) | 2 × 2 | 2 × 1 | chambre du joueur, rez-de-chaussée |
| `low_table` (table basse, livres ouverts) | 2 × 1 | 2 × 1 | chambre du rival |
| `bed` | 2 × 3 | 2 × 2 : x 0..1, y −1..0 | chambres |
| `plant` | 1 × 2 | 1 × 1 | partout |
| `kitchen_counter` (plan de travail, évier, cuisinière) | 3 × 2 | 3 × 1 : x 0..2 | rez-de-chaussée |
| `fridge` | 1 × 3 | 1 × 1 | rez-de-chaussée |
| `dining_table` (table + chaises) | 3 × 2 | 3 × 2 : x 0..2, y −1..0 | rez-de-chaussée |
| `lab_machine` | 2 × 3 | 2 × 1 | labo |
| `lab_desk` (bureau de Chen) | 3 × 2 | 3 × 1 | labo |
| `starter_table` (3 Poké Balls dessinées) | 3 × 2 | 3 × 1 | labo |
| `lab_bookshelf` | 5 × 2 | 5 × 1 : x 0..4 | labo |
| `lab_bench` (paillasse, microscopes) | 5 × 2 | 5 × 1 | labo |

### 4.2 Bourg Palette (modifications de `pallet_town`)

- **Empreintes** : la case de porte, c'est-à-dire l'**ancre** (0, 0), sort des empreintes de `house_player`, `house_rival` et `oak_lab` (`gen_placeholder_props.gd`, et §4.3 du jalon 1 dans `test_game_map.gd`).
- **Warps** (`Warps/`) :

| Nœud | Case | Déclenchement | Cible |
|---|---|---|---|
| `DoorPlayerHouse` | (36, 9) | STEP_ON, UP | `player_house_1f` / `entrance` |
| `DoorRivalHouse` | (11, 9) | STEP_ON, UP | `rival_house` / `entrance` (§4.5) |
| `DoorOakLab` | (24, 22) | STEP_ON, UP | `oak_lab` / `entrance` |

- **Spawns** : `player_house_door` (36, 9), `rival_house_door` (11, 9) et `oak_lab_door` (24, 22). `start` (36, 10) est **conservé** pour les tests et les outils, mais ce n'est plus le départ du jeu.
- Quand le joueur se tient sur une case de porte, il est dessiné **devant** la façade : même y que l'origine du bâtiment, ajouté après lui dans `Entities`. `WorldProp.covers` est faux dans ce cas, donc il n'y a pas de transparence parasite. À vérifier sur capture.

### 4.3 `player_house_2f` — chambre du joueur (14 × 10)

> **Référence visuelle fournie par Kevin** : `docs/design/reference/chambre-joueur-v1.webp`. Elle **remplace** le gabarit 11 × 8 prévu à l'origine pour cette pièce. Elle fixe l'agencement de ce jalon (graphismes provisoires) et servira de cible de rendu pour la phase DA (lumière chaude du soir par la fenêtre, parquet, décor riche).

Contrairement au gabarit générique du §3, cette chambre a des **murs sur les quatre côtés** : mur du fond sur 2 rangées (y 0–1), murs latéraux d'une colonne (x 0 et x 13), mur bas (y 9) ouvert au centre sur l'**escalier qui descend**. Sol praticable : x 1–12, y 2–8 (12 × 7).

```
      x  0 1 2 3 4 5 6 7 8 9 10 11 12 13
y0       W W W W W W W W W W W  W  W  W
y1       W W W W W W F F W W W  W  W  W     affiches (2..4, 1) · F fenêtre + rideaux (6..7, 1) · carte de Kanto (10..11, 1)
y2       W L L n b . D D D B B  . .  W      L lit, ancre (1, 4), cases (1..2, 2..4) · n chevet + lampe (3, 2) · b petite étagère (4, 2)
y3       W L L . . . . C . B B  . .  W      D bureau + ordinateur portable (6..8, 2) · C chaise (7, 3) · B grande étagère, ancre (9, 3), cases (9..10, 2..3)
y4       W L L S . R R R R . .  . T  W      S spawn start (3, 4), face au sud · R grand tapis Poké Ball (5..8, 4..6, décor, praticable)
y5       W g . . . R R R R . .  . T  W      g sac de voyage (1, 5) · T meuble télé + console le long du mur est, ancre (12, 5), cases (12, 4..5)
y6       W P . . . R R R R . .  . P  W      P plantes (1, 6) et (12, 6)
y7       W . . . . . . . . . .  . .  W      porte décorative (fermée) dessinée sur le mur est
y8       W s s s . . M M . c k  k .  W      s meuble bas (photo, plante, livres), cases (1..3, 8) · M tapis à carreaux (6..7, 8)
y9       W W W W W W E E W W W  W  W  W     c meuble bas + casquette (9, 8) · k caisse de Poké Balls (10..11, 8) · E escalier ↓ (6..7, 9)
```
- Warps `StairsDownW` (6, 9) et `StairsDownE` (7, 9) : STEP_ON en descendant (DOWN) → `player_house_1f` / `stairs`.
- Spawns : `start` (3, 4), face au sud (décision Q2 : à côté du lit) ; `stairs` (6, 8), face au nord (on arrive du rez-de-chaussée en haut de l'escalier, dans la chambre).
- Le **tapis à carreaux (6..7, 8)** marque le haut de l'escalier, comme sur la référence. Les **coins bas** de la référence (décrochements du mur de part et d'autre de l'escalier) sont rendus par les meubles bas (1..3, 8) et (9..11, 8).
- La **grande étagère (9..10, 2..3)** est l'emplacement prévu du « journal visuel de la progression » (dossier 01 §1). Elle reste sans logique dans ce jalon.
- Props nouveaux pour cette pièce (à ajouter au §4.1, provisoires, dimensions finales) : `poster` (1 × 1, sans empreinte, sur le mur), `window_curtains` (2 × 1, sans empreinte), `nightstand_lamp` (1 × 2, empreinte 1 × 1), `small_shelf` (1 × 2, 1 × 1), `laptop_desk` (3 × 2, empreinte 3 × 1), `desk_chair` (1 × 1, 1 × 1), `tall_bookshelf` (2 × 3, empreinte 2 × 2), `tv_console_side` (1 × 3 vu de côté, empreinte 1 × 2 : y −1..0), `travel_bag` (1 × 1, 1 × 1), `low_cabinet` (3 × 1 et 1 × 1, empreinte = largeur), `pokeball_crate` (2 × 1, 2 × 1), `rug_pokeball` (4 × 3, sans empreinte, sous les entités), `rug_check` (2 × 1, sans empreinte), `door_side` (décor du mur est, sans empreinte).
- Cohérence avec le rez-de-chaussée : l'escalier de `player_house_1f` (§4.4) reste en haut à droite pour ce jalon ; l'alignement vertical des deux escaliers n'est pas exigé.

**Points interprétés depuis la référence** (à confirmer par Kevin après l'essai sur S24) : dimensions 14 × 10, position exacte des meubles à ±1 case, porte du mur est seulement décorative, chaise et meubles bas solides, grand tapis praticable.

### 4.4 `player_house_1f` — rez-de-chaussée du joueur (14 × 10)

> **Référence visuelle fournie par Kevin** : `docs/design/reference/ouverture-storyboard-v1.webp`, cases 3 (rez-de-chaussée) et 4 (sortie de la maison). Elle **remplace** le gabarit 11 × 8 prévu à l'origine. Graphismes provisoires dans ce jalon ; le rendu de la référence est la cible de la phase DA.

Même gabarit que la chambre (§4.3) : murs sur les quatre côtés (fond y 0–1, côtés x 0 et x 13, bas y 9 avec la porte d'entrée). Sol praticable : x 1–12, y 2–8.

```
      x  0 1 2 3 4 5 6 7 8 9 10 11 12 13
y0       W W W W W W W W W W W  W  W  W
y1       W W W W W F F W W W W  F  F  W     F fenêtres (5..6, 1) et (11..12, 1) · étagères et plantes au mur
y2       W E E R K K K . . . .  . .  W      E escalier ↑ (1..2, 2..3) · R frigo (3, 2) · K cuisine : évier, plaques (4..6, 2)
y3       W E E . . . . . . . .  . .  W
y4       W . . M M M . m . S S  S .  W      M table + chaises, ancre (3, 5), cases (3..5, 4..5) · m mère (7, 4), réservée · S canapé (9..11, 4)
y5       W . . M M M . . . . .  . T  W      T meuble télé le long du mur est, ancre (12, 6), cases (12, 5..6)
y6       W . . . . . . . . t t  . T  W      t table basse (9..10, 6)
y7       W P . . . . . . . . .  . P  W      P plantes (1, 7) et (12, 7)
y8       W s s s . . c X . k .  . .  W      s meuble bas + photos (1..3, 8) · c porte-manteau (6, 8) · X tapis de sortie (7, 8) · k commode + Poké Ball (9, 8)
y9       W W W W W W W D W W W  W  W  W     D porte d'entrée dessinée dans le mur bas (7, 9)
```
- Warps : `StairsUpW` (1, 3) et `StairsUpE` (2, 3), STEP_ON en montant (UP) → `player_house_2f` / `stairs` ; `Exit` (7, 8), PUSH DOWN → `pallet_town` / `player_house_door`.
- Spawns : `entrance` (7, 8), face au nord ; `stairs` (2, 4), face au sud (au pied de l'escalier). Les cases (1..2, 2) sont le haut de l'escalier, solides.
- Tapis décoratifs : plaid sous la table (2..6, 3..6), tapis du salon (9..11, 5..7). Praticables.
- **Mère** : la case (7, 4), à droite de la table, reste **libre et réservée**. La mère et son dialogue (« Bonjour ! Tu es enfin réveillé ? ») arrivent au jalon des PNJ et dialogues (phase 3), **pas dans ce jalon**.
- Props nouveaux (à ajouter au §4.1, provisoires, dimensions finales) : `stairs_up_side` (2 × 3, rampe, empreinte des marches du haut 2 × 1 : y −1), `fridge` (existant), `kitchen_counter` (existant, 3 × 2), `dining_table` (existant, 3 × 2), `sofa` (3 × 2, empreinte 3 × 1), `coffee_table` (2 × 1, 2 × 1), `tv_console_side` (§4.3), `low_cabinet` (§4.3), `coat_rack` (1 × 2, 1 × 1), `dresser_pokeball` (1 × 2, 1 × 1), `front_door` (1 × 2, sans empreinte, dessinée dans le mur bas), `rug_plaid` (5 × 4, sans empreinte), `rug_living` (3 × 3, sans empreinte).

**Points interprétés depuis la référence** (à confirmer après l'essai sur S24) : dimensions 14 × 10, mobilier à ±1 case, porte-manteau et commode de la case 4 placés de part et d'autre du tapis de sortie.

### 4.5 `rival_house` — maison du rival, **un seul niveau** (18 × 11)

> **Référence visuelle fournie par Kevin (2026-09-26)** : `docs/design/reference/maison-rival-v1.webp`. Elle **remplace** les deux cartes `rival_house_1f` et `rival_house_2f` du plan d'origine (et la réponse à Q4) : la chambre du rival est **au même niveau** que le reste de la maison. Graphismes provisoires dans ce jalon ; le rendu de la référence est la cible de la phase DA. **L'Évoli visible sur la référence est une erreur** (décision de Kevin) : il n'est pas prévu ; le rival et ses Pokémon seront décidés plus tard.

Même gabarit que la maison du joueur : murs sur les quatre côtés (fond y 0–1, côtés x 0 et x 17, bas y 10 ouvert sur l'entrée), plus des **cloisons intérieures**. Sol praticable : x 1–16, y 2–9, hors cloisons et meubles.

```
      x  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17
y0       W W W W W W W W W W W  W  W  W  W  W  W  W
y1       W W W W F F W W W W W  W  W  F  F  W  W  W     F fenêtres cuisine (4..5, 1) et chambre (13..14, 1) · affiches du rival (15..16, 1)
y2       W R K K K O . E E E |  D  D  d  d  L  L  W     R frigo (1, 2) · K évier + plan de travail (2..4, 2) · O cuisinière + hotte (5, 2)
y3       W . . . . . . E E E |  D  c  .  .  L  L  W     E escalier ↑ décoratif, bloqué (7..9, 2..4) · | cloison chambre (10, 2..4)
y4       W . M M M . . E E E .  .  .  r  .  L  L  W     D bureau d'angle + PC (11..12, 2..3) · c chaise gamer (12, 3) · d commode (13..14, 2)
y5       W . M M M . . . s . .  .  .  .  .  .  n  W     L lit Poké Ball, ancre (15, 4), cases (15..16, 2..4) · n chevet + sac (16, 5)
y6       W T . . . . . . . . .  .  -  -  -  -  -  W     r rival, case réservée (13, 4) · M table à carreaux + chaises (2..4, 4..5)
y7       W T . S S S . | . . |  h  |  B  B  .  U  W     s meuble bas + Poké Ball sous l'escalier (8, 5) · T télé murale (1, 6..7)
y8       W . . t t t . | . . |  .  .  .  .  .  U  W     S canapé (3..5, 7) · t table basse (3..5, 8) · - cloison salle de bain (12..16, 6)
y9       W P . . . . P | . X |  k  .  .  m  .  P  W     | murets du couloir d'entrée (7, 7..9) et (10, 7..9) · h porte-manteau (11, 7) · k meuble à chaussures (11, 9)
y10      W W W W W W W W W O W  W  W  W  W  W  W  W     B lavabo (13..14, 7) · U douche (16, 7..8) · m tapis de bain (13, 9) · P plantes · X tapis d'entrée (9, 9) · O porte (9, 10)
```
- Warp : `Exit` (9, 9), PUSH DOWN → `pallet_town` / `rival_house_door`. Spawn : `entrance` (9, 9), face au nord.
- La salle de bain (x 12–16, y 7–9) s'ouvre sur le coin du couloir par la case (12, 8). Le couloir d'entrée (x 8–9, y 7–9) débouche au nord sur la grande pièce.
- **Escalier (7..9, 2..4)** : décoratif et **bloqué** dans ce jalon (pas d'étage chez le rival).
- **Rival** : case (13, 4) réservée, sur le tapis de sa chambre. Il arrive au jalon PNJ et dialogues. **Pas d'Évoli.**
- Le **warp** `DoorRivalHouse` de Bourg Palette (§4.2) cible désormais `rival_house` / `entrance`. Les cartes `rival_house_1f` et `rival_house_2f` sont **supprimées** (scènes, entrées du catalogue et tests).
- Props nouveaux (provisoires, dimensions finales) : `range_hood_stove` (1 × 2, 1 × 1), `stairs_up_side` (§4.4, variante 3 × 3 bloquée), `corner_desk_pc` (2 × 2, empreinte 2 × 2), `gamer_chair` (1 × 1, 1 × 1), `dresser` (2 × 2, 2 × 1), `bed_pokeball` (2 × 3, empreinte 2 × 3 : y −2..0), `nightstand_bag` (1 × 2, 1 × 1), `wall_tv_side` (1 × 3, 1 × 2), `sofa` (§4.4), `coffee_table` (§4.4), `dining_table` (existant), `low_cabinet` (§4.3), `coat_rack` (§4.4), `shoe_rack` (1 × 1, 1 × 1), `bathroom_sink` (2 × 2, 2 × 1), `shower` (1 × 3, 1 × 2), `rival_posters` (sans empreinte), `rug_bath`, `rug_bedroom_grey`, `rug_living_blue` (sans empreinte). Cloisons et murets : tuile `WALL_HOUSE` (solide) ou prop `partition` (1 × N, empreinte 1 × N), au choix du constructeur, du moment que le rendu reste lisible.

**Points interprétés depuis la référence** (à confirmer après l'essai sur S24) : dimensions 18 × 11, cloisons et mobilier à ±1 case, escalier bloqué.

### 4.7 `oak_lab` — laboratoire de Chen (16 × 11)

> **Référence visuelle fournie par Kevin (2026-09-26)** : `docs/design/reference/labo-chen-v1.png`. Elle **remplace** le plan 15 × 14 d'origine : la pièce est plus large que haute et ne défile plus (elle tient dans la hauteur de l'écran). Graphismes provisoires dans ce jalon ; le rendu de la référence est la cible de la phase DA.

Même gabarit que la maison du joueur : murs sur les quatre côtés (fond y 0–1, côtés x 0 et x 15, bas y 10 ouvert sur l'entrée). Sol praticable : x 1–14, y 2–9. Sol `FLOOR_LAB`, mur `WALL_LAB`.

```
      x  0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
y0       W W W W W W W W W W W  W  W  W  W  W
y1       W W W W W W F F F W W  W  W  W  W  W     carte de Kanto (4..5, 1) · F grande fenêtre (6..8, 1) · affiche Pokémon (10, 1)
y2       W a I I M M . D D D k  B  B  R  V  W     a aquarium (1, 2) · I incubateur (2..3, 2..3) · M machines + ordinateurs (4..5, 2)
y3       W . I I . . . . c . .  B  B  .  V  W     D bureau de Chen + ordinateur (7..9, 2) · c chaise (8, 3) · k classeurs (10, 2)
y4       W . . . . . . . . . .  S  S  S  V  W     B grande étagère (11..12, 2..3) · R frigo (13, 2) · V vitrine + Poké Balls (14, 2..4)
y5       W L L L L L . R R R R  S  S  S  .  W     L long comptoir, livres + écran (1..5, 5) · R grand tapis Poké Ball (6..9, 5..7)
y6       W . C . . . . R R R R  .  .  .  T  W     S table des starters (11..13, 4..5) · C canapé (2, 6..7) · T écran mural (14, 6..7)
y7       W . C t t . . R R R R  Q  Q  Q  T  W     t table basse sur tapis rouge (3..4, 7) · Q paillasse, microscope, terrarium (11..13, 7)
y8       W E E E . . p . . . .  .  s  .  .  W     E escalier décoratif (1..3, 8..9) · p plante (6, 8) · s tabouret (12, 8)
y9       W E E E p . . X . . p  .  .  .  P  W     p plantes (4, 9), (10, 9) · X tapis d'entrée (7, 9) · P grande plante (14, 9)
y10      W W W W W W W O O W W  W  W  W  W  W     O ouverture de l'entrée (7..8, 10)
```
- Warp : `Exit` (7, 9), PUSH DOWN → `pallet_town` / `oak_lab_door`. Spawn : `entrance` (7, 9), face au nord.
- **Chen** : case (8, 4), réservée (au-dessus du grand tapis, comme sur la référence). Il arrive au jalon PNJ et dialogues.
- **Starters** : dans ce jalon, la table ne montre que **trois Poké Balls** dessinées, non interactives. Bulbizarre, Salamèche et Carapuce posés sur la table (référence) arrivent avec les Pokémon et la scène du choix du starter.
- **Escalier (1..3, 8..9)** : décoratif et **bloqué** dans ce jalon (solide, sans warp).
- Props nouveaux (provisoires, dimensions finales) : `aquarium` (1 × 2, 1 × 1), `incubator` (2 × 3, empreinte 2 × 2), `lab_computers` (2 × 2, 2 × 1), `oak_desk` (3 × 2, 3 × 1), `desk_chair` (§4.3), `file_cabinet` (1 × 2, 1 × 1), `tall_bookshelf` (§4.3), `fridge` (existant), `display_case` (1 × 3 vu de côté, empreinte 1 × 3 : y −2..0), `long_counter` (5 × 2, 5 × 1), `sofa_side` (1 × 2, 1 × 2 : y −1..0), `coffee_table` (§4.4), `starter_table` (existant, 3 × 2 → empreinte 3 × 2 : y −1..0), `lab_bench` (3 × 2, 3 × 1), `stool` (1 × 1, 1 × 1), `wall_screen_side` (1 × 3, 1 × 2), `stairs_deco` (3 × 2, empreinte 3 × 2), `wall_map` (existant), `pokemon_poster` (1 × 1, sans empreinte), `rug_pokeball` (§4.3), `rug_red` (4 × 3, sans empreinte), `mat_pokeball` (1 × 1, tapis d'entrée).
- Les anciennes zones « Pokémon qui y vivent » (Roucool, Rattata, Pokémon endormi) ne sont pas sur la référence : **retirées** de ce plan.

**Points interprétés depuis la référence** (à confirmer après l'essai sur S24) : dimensions 16 × 11, mobilier à ±1 case, escalier décoratif bloqué.

### 4.8 Invariants (testés)

Pour **chaque intérieur** :
- `interior == true`, taille conforme, structure de nœuds conforme, et tous les spawns et warps listés ci-dessus présents ;
- **toutes les cases praticables sont atteignables** depuis `entrance` (ou depuis `stairs` pour une chambre) : `find_reachable(...).size()` égale le nombre de cases non solides. Il n'y a donc aucune poche fermée par le mobilier ;
- aucune case de mur (y 0–1) ni de mobilier n'est atteignable ;
- les **cases réservées** (mère, sœur, Chen, Pokémon du labo) sont libres et atteignables. Devant la table des starters, (11, 5) est atteignable ;
- chaque case de warp est praticable ; le tapis est sur la dernière rangée.

Pour **Bourg Palette** : tous les invariants du jalon 1 §4.4 restent vrais, **plus** les trois cases de porte atteignables. Ce sont les seules cases atteignables dans le rectangle d'un bâtiment.

**Cohérence globale** (`tests/integration/test_map_links.gd`, sur les 6 cartes) :
- chaque warp vise une carte existante (`MapCatalog.has_map`) et un spawn existant (`has_spawn`), et la case d'arrivée est praticable ;
- **réversibilité sur place** : la case d'arrivée de chaque warp porte elle-même un warp qui ramène à la carte d'origine ;
- `WarpTable` de chaque carte construite sans erreur (aucun `push_error`).

---

## 5. Découpage des tâches (dans l'ordre)

### T1 — constructeur-monde : warps dans les cartes, joueur bloquable, cadrage caméra
- `game/world/warp_point.gd` (`WarpPoint`) ; `GameMap` : `interior`, `get_warps()`, `has_spawn()` ; `Player` : `set_input_enabled`/`is_input_enabled` (verrou réappliqué dans `enter_map`), limites via `CameraFraming`, recalcul sur `size_changed` ; `project.godot` : `default_clear_color`.
- **CA** :
  - `test_game_map.gd`, étendu sur la mini-carte : deux `WarpPoint` (un STEP_ON UP et un PUSH DOWN) sont retrouvés par `get_warps().find_on_step` et `find_on_push`. Deux STEP_ON en conflit sur une même case donnent un `push_error` attendu (`assert_push_error`). `has_spawn(&"start")` est vrai, `has_spawn(&"nowhere")` faux et sans erreur. `interior` vaut faux par défaut.
  - `test_player.gd` : `set_input_enabled(false)` pendant un pas : le pas se termine, aucun autre ne part malgré `move_right` tenu, aucun `bumped`. Le verrou survit à `enter_map`. Réactivé, le joueur repart.
  - Caméra : sur une mini-carte de 10×8, les limites valent `CameraFraming.limits_for(map.get_pixel_rect(), player.get_viewport_rect().size)` (le test ne suppose aucune taille de vue). Sur `pallet_town`, les limites restent le rectangle de la carte (test existant de `test_boot.gd`, à garder vert).
  - Import sans erreur ; `tools/test.sh` vert.

### T2 — ui-mobile : fondu de transition, masquage du titre
- `ScreenFade` (§2.5), tokens `FADE_COLOR`, `ANIM_FADE_OUT`, `ANIM_FADE_IN` dans `UiTokens`, `ZoneTitle.hide_now()`, `ExplorationHud.hide_zone_title()`. **Aucune** référence au joueur, à la carte ou à `SceneRouter` dans `game/ui/`.
- **CA** :
  - `tests/integration/test_screen_fade.gd` : layer 100 ; rideau plein écran, `mouse_filter == IGNORE`, alpha 0 au repos. `await fade_out(0.05)` donne un rideau opaque, `faded_out` est émis et `is_opaque()` est vrai. `await fade_in(0.05)` donne alpha 0 et `faded_in`. Avec une durée de 0, la méthode rend la main en une image. Un `fade_in` lancé pendant un `fade_out` ne fait pas sauter l'opacité (elle part de sa valeur courante).
  - `test_exploration_hud.gd` : `hide_zone_title()` pendant l'affichage cache le titre en ≤ `ANIM_MICRO` + 1 image et émet `title_hidden`.
  - Couleur et durées uniquement via `UiTokens`.

### T3 — constructeur-monde : tuiles d'intérieur, mobilier, portes ouvertes
- `InteriorTiles`, atlas provisoire, `assets/tiles/interior.tres` (§3) ; props du §4.1 dans `game/world/props/interior/` ; case de porte retirée des empreintes des maisons et du labo.
- **CA** :
  - `tests/unit/test_interior_tileset.gd` : tuiles de 96×96, les 4 couches de données dans le même ordre qu'`overworld.tres`, et chaque `Kind` avec son nombre de variantes et la bonne donnée `solid`.
  - `test_game_map.gd` : empreintes attendues mises à jour (maisons et labo **sans** (0, 0)). Nouveau test : empreinte de chaque prop d'intérieur conforme au §4.1, texture présente, bas du sprite sur l'origine.
  - `test_pallet_town.gd` reste vert après régénération de la carte. Les cases de porte deviennent praticables (sans warp jusqu'à T4) : ajouter (36, 9), (11, 9) et (24, 22) aux cases atteignables, et vérifier que depuis chacune, HAUT, GAUCHE et DROITE restent bloqués.

### T4 — constructeur-monde : les cinq intérieurs et les portes de Bourg Palette
- `tools/build_interiors.gd` : génère `player_house_2f`, `player_house_1f`, `rival_house_1f`, `rival_house_2f` et `oak_lab` (§4.3–4.7). `tools/build_pallet_town.gd` : ajoute les warps et spawns du §4.2.
- **CA** :
  - `tests/integration/test_interiors.gd` : pour chaque intérieur, tous les invariants du §4.8.
  - `test_pallet_town.gd` : les trois `WarpPoint` et les trois spawns du §4.2, et les invariants.
  - `tests/integration/test_map_links.gd` : cohérence globale du §4.8.
  - Captures Movie Maker (outil de capture, `start_map`/`start_spawn` réglés avant `add_child`) de chaque intérieur, à 2340×1080. Chaque pièce est centrée, le fond quasi noir, sans aucun gris. Le labo (16 × 11) tient dans l'écran. Captures lues avec Read, conformes aux plans du §4.

### T5 — constructeur-monde : `SceneRouter`, nouveau `Boot`, scénario de capture
- `game/autoload/scene_router.gd` + entrée `[autoload]` dans `project.godot` ; `boot.tscn`/`boot.gd` (§2.1) ; `tools/capture_play.gd`, nouveau scénario `doors` (voir CA).
- **CA** :
  - `tests/integration/test_scene_router.gd`, sur une instance **fraîche** du routeur, avec `map_factory` qui fabrique deux mini-cartes A et B en code (une porte STEP_ON UP dans A, un tapis PUSH DOWN dans B) et un `ScreenFade` aux durées courtes :
    1. `start` place le joueur au spawn, émet `map_changed` puis `map_entered`, et `get_current_map()` est A.
    2. Un pas terminé sur la porte (`Input.action_press(&"move_up")` + appels à `_process`) bloque le joueur **dans la même image** (`is_input_enabled()` faux) et émet `transition_started`. Après `await map_entered` : joueur dans B sur le spawn, orienté vers le haut, **même instance** ; A libérée ; entrées rétablies.
    3. Tenir BAS sur le tapis de B ramène dans A, sur la case de porte, orienté vers le bas.
    4. Porte STEP_ON dans une case ouverte, direction tenue : pendant le fondu, le joueur reste sur la case de la porte (la case au-delà n'est ni occupée ni atteinte).
    5. Un second `change_map` pendant une transition est ignoré (une seule transition, un seul `map_entered`).
    6. Carte inconnue ou spawn inconnu : `push_error` attendu, le joueur reste sur la carte courante, les entrées sont rétablies, pas de `map_entered`.
    7. Avec fondu : au moment de `map_changed`, `fade.is_opaque()` est vrai.
  - `test_boot.gd` mis à jour : départ dans `player_house_2f` en (2, 6) face au sud ; **aucun** titre de zone au démarrage ; caméra encadrée selon `CameraFraming` ; pas d'écran titre.
  - `tests/integration/test_opening_walk.gd` : de la chambre, on marche jusqu'à l'escalier, puis au tapis du rez-de-chaussée, puis dehors. On arrive en (36, 9) sur `pallet_town`, orienté vers le bas, et `show_zone_title` est appelé **une fois** avec « Bourg Palette » / « Kanto ». On rentre, on ressort : **pas** de second titre.
  - Scénario `doors` de `capture_play.gd` : chambre → escalier → rez-de-chaussée → dehors (titre visible) → maison du rival → sa chambre → dehors → labo → dehors, avec une capture par étape et une capture **pendant** un fondu (écran noir, pas de gris).
  - En debug, le journal affiche le temps de changement de carte.

### T6 — qa-mobile : validation sur S24
- Checklist `android-deploy` : tests, import, `tools/deploy_s24.sh`, logcat.
- **CA à vérifier et rapporter** :
  - Le jeu démarre dans la chambre, sans titre. À la première sortie, « BOURG PALETTE / Kanto » s'affiche. Il ne s'affiche plus aux sorties suivantes.
  - Chaque porte, tapis et escalier du §4 mène au bon endroit, dans les deux sens. Parcours par glissements adb, avec captures avant et après chaque passage.
  - Fondu sans gris ni image de l'ancienne carte après la transition. Aucune entrée prise en compte pendant le fondu : un glissement adb pendant la transition ne déplace pas le joueur au-delà de la case d'arrivée.
  - **Doigt maintenu** : entrer en tenant le haut fait avancer dans la pièce, sortir en tenant le bas fait s'éloigner de la porte, et il n'y a aucun aller-retour involontaire à l'escalier.
  - Pièces centrées sur fond sombre, labo compris.
  - Temps de changement de carte (logcat) < 100 ms pour `pallet_town`, 60 fps (ou « non vérifié ») ; aucune erreur ni plantage dans logcat.
  - 20 allers-retours rapides maison ↔ village sans blocage ni fuite visible (nombre de nœuds stable dans le moniteur, si disponible).

---

## 6. Hypothèses prises et questions pour Kevin

Hypothèses techniques (pas de décision de design) :
- Warps dans les scènes de carte (`WarpPoint`), et non dans `data/` (§2.3).
- Pas de `GameState` ni de sauvegarde dans ce jalon (en-tête).
- Transition de 0,45 s environ, gardée courte pour ne pas freiner l'aller-retour ; ajustable dans `UiTokens` seulement.
- Un seul tapis de sortie par pièce (1 case), comme la porte extérieure.

**Décisions de Kevin (2026-09-25)** : les neuf propositions ci-dessous sont **acceptées telles quelles**. Plus aucune question ouverte pour ce jalon.

Rappel des questions et des réponses retenues (entre parenthèses) :

1. **Entrer dans un bâtiment** : en marchant dans la porte, comme dans Rouge/Bleu, ou avec le bouton contextuel « entrer » cité dans la vision ? (*Marcher dans la porte* : aucune friction, aucune UI. Le bouton contextuel reste pour parler et examiner, en phase 3. Si tu veux le bouton plus tard, ce sera un nouveau type de déclenchement, sans rien casser.)
2. **Départ du jeu** : désormais dans la chambre, sans titre ni tutoriel, à côté du lit, face au sud ? (*Oui*. Sans sauvegarde, chaque lancement repart de la chambre. `Boot` garde un réglage pour démarrer ailleurs pendant le développement.)
3. **Titre de zone** : seulement pour les extérieurs, et seulement quand la zone change ? Il s'afficherait donc à la première sortie de la maison, puis pas à chaque porte, et jamais dans les intérieurs. (*Oui*.)
4. **Chambre du rival** : à l'étage (2 cartes, en miroir de la maison du joueur) ou au rez-de-chaussée ? Dans Rouge/Bleu, sa maison n'a qu'un niveau. (*À l'étage* — **remplacé le 2026-09-26 par la référence de Kevin : un seul niveau, voir §4.5**.)
5. **Taille des intérieurs et fond** : pièces modestes (maisons 11×8, labo 15×14) centrées sur un fond quasi noir, ou pièces plus grandes qui remplissent l'écran ? (*Modestes, fond quasi noir* ; une vignette ou une lueur pourra adoucir les bords en phase 10/12.)
6. **Transition** : fondu au noir d'environ 0,2 s + 0,25 s ? (*Oui* ; une transition plus « 2026 » pourra venir au polish.)
7. **Agencement et mobilier des pièces** (§4.3 à 4.7) : ce sont des hypothèses inspirées de Rouge/Bleu. Escalier dans le coin haut, tapis en bas au centre, mur du fond sur 2 cases sans murs latéraux, zones du labo (recherche en haut à gauche, bureau de Chen en haut au centre, starters en haut à droite, bibliothèque en bas à gauche, paillasses en bas à droite, trois coins réservés aux Pokémon du labo). (*Validés tels quels, à ajuster après l'essai sur S24*.)
8. **Arrivée après un passage** : sur la case de la porte, du tapis ou de l'escalier, orientation conservée, et on continue à marcher si le doigt reste posé ? (*Oui*, comme dans les jeux.)
9. **« Cartes » dans la chambre du rival** (dossier 01 §2) : cartes géographiques (carte de Kanto au mur, cartes sur le bureau) ou cartes à collectionner ? (*Géographiques* : il prépare son voyage.)

---

## 7. Storyboard d'ouverture (Kevin, 2026-09-25)

Référence : `docs/design/reference/ouverture-storyboard-v1.webp` (1 chambre, 2 escalier, 3 rez-de-chaussée, 4 sortie, 5 révélation de Bourg Palette). Décisions de Kevin :

1. **Escalier (case 2)** : ce n'est pas un lieu jouable, c'est la **transition** entre la chambre et le rez-de-chaussée (fondu de ce jalon ; une animation de descente pourra venir avec la DA).
2. **Mère (case 3)** : la mère et son dialogue « Bonjour ! Tu es enfin réveillé ? » arrivent au **jalon PNJ et dialogues** (phase 3). Dans ce jalon, sa case (7, 4) reste libre et réservée.
3. **Révélation (case 5)** : **cinématique de première sortie** en vue perspective, au jalon « ouverture », avec la phrase « Le commencement de toute aventure », puis retour à la vue de jeu. Dans ce jalon, la première sortie affiche seulement le titre « BOURG PALETTE / Kanto ».

---

## 8. Retouches après la QA sur S24 (décisions de Kevin, 2026-09-26)

1. **Pas en trop si on lève le doigt à la toute fin du fondu** : laissé tel quel (conséquence voulue du « doigt maintenu »).
2. **Plantes d'intérieur** : semi-transparentes quand le joueur est derrière (`fade_when_covering`), comme les arbres du village.
3. **Bouton courir** : les plantes du coin bas-droit sont déplacées — maison du rival (16, 9) → (12, 9), labo (14, 9) → (14, 8). Le bas de la douche du rival reste partiellement sous le bouton (à revoir avec la DA ou la position du bouton).
