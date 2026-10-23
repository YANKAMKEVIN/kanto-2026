class_name GameMap
extends Node2D
## Carte du monde : couches de tuiles, props, spawns, warps, points d'examen, PNJ. Construit
## sa [GridWorld], sa [WarpTable] et son [InteractionTable].
##
## Au chargement, lit les données `solid`, `water`, `tall_grass` et `ledge` des tuiles de
## `Ground`, `Detail` et `Obstacles`, puis ajoute l'empreinte de chaque [WorldProp]
## enfant de `Entities` ou de `GroundDecals` (relief peint posé au sol, jalon 7).
## Les [WarpPoint] enfants de `Warps` forment la table des passages.
## Les [InteractPoint] enfants de `Interactables` forment la table des points fixes
## (docs/tech/jalon-03.md §2.2). Les [EventTriggerPoint] enfants de `Triggers` forment la
## table des déclencheurs de scène (docs/tech/jalon-03b.md §2.2).
## Les PNJ ne sont pas dans la scène : à [method _ready], la carte lit
## `<npcs_dir>/<map_id>.json` ([NpcRoster]), crée un [Npc] par entrée **présente en
## nouvelle partie** ([method NpcRoster.get_present] sans drapeaux) dans `Entities` et
## l'inscrit sur sa case ([method Npc.enter_grid], §2.3), même une case infranchissable
## (Pokémon d'ambiance sur un tronc ou une clôture, jalon 9 ; un Pokémon d'ambiance sans
## planche est sauté : [method awaits_painted_look]). [method refresh_npcs] ajuste
## ensuite la présence aux drapeaux de la partie (jalon 3B §2.6 : Boot l'appelle à chaque
## changement de carte, écran noir). Une scène scriptée peut en ajouter
## ([method add_npc]) ou en retirer ([method remove_npc]) pour la durée de la carte
## (jalon 3B §2.5). Ils n'ont pas d'owner : les scripts de construction ne les sauvent
## jamais dans les `.tscn`.
## Le joueur est ajouté à `Entities` (y-sort) par [method spawn_player].
## Jalon 14 (jalon-14.md §2.8) : un PNJ du fichier avec une autre place (« moved ») est créé
## à la place que lui donnent les drapeaux ; les [FlagGate] de la carte (décor qui suit les
## drapeaux) sont réglées par [method apply_flag_gates].
## DA.2 : les routines de marche des PNJ ([member NpcSpec.route_cells]) sont **retenues tant
## qu'aucun joueur n'est sur la carte** ([method Npc.set_routine_held]) et relâchées par
## [method spawn_player] / [method spawn_player_at] : une carte chargée seule (tests, outils)
## garde ses habitants sur leur case de départ.

const _TILE_LAYERS: Array[NodePath] = [^"Ground", ^"Detail", ^"Obstacles"]
## Nœuds dont les [WorldProp] enfants marquent leur emprise sur la grille.
const _PROP_LAYERS: Array[NodePath] = [^"Entities", ^"GroundDecals"]
const _NPC_SCENE: PackedScene = preload("res://game/world/npc/npc.tscn")

@export var map_id: StringName = &""
@export var display_name: String = ""
@export var region: String = ""
@export var music: StringName = &""
## Taille en cases.
@export var size: Vector2i = Vector2i(16, 16)
## Cases infranchissables sans rien de visible (ex. chemin qui file hors de la carte :
## le joueur s'arrête une case avant le bord, la tête reste à l'écran).
@export var blocked_cells: Array[Vector2i] = []
## Intérieur (maison, labo) : pas de titre de zone à l'entrée (voir ZoneAnnouncer).
@export var interior: bool = false
## Arène de combat, en cases (jalon-04.md §14.4) : sol dégagé que la vue de combat met entre
## les deux Pokémon (le tapis central du labo). Vide : cadrage sur les combattants.
@export var battle_arena: Rect2i = Rect2i()
## Dossier des fichiers de PNJ (`<map_id>.json`) ; les tests pointent sur leurs données.
@export var npcs_dir: String = NpcRoster.DATA_DIR
## Profil de lumière du monde (`data/world/lighting.json`, [LightingLibrary], jalon-07.md
## §3.2) appliqué par `WorldLighting` à l'arrivée. Vide = **aucune** lumière du monde (cartes
## encore provisoires : Bourg Palette et ses intérieurs jusqu'au DA.2 / DA.3).
@export var light_profile: StringName = &""
## Rangées des murs de soutènement et falaises qui séparent deux niveaux (Jadielle : 12, 24,
## 32). Un décor qui s'efface quand le joueur passe derrière ([member
## WorldProp.fade_when_covering]) ne le fait qu'au même niveau. Vide : un seul niveau.
@export var level_rows: Array[int] = []
## Bande d'herbe devant les jambes du joueur en hautes herbes (cartes peintes : moitié basse
## des touffes, `ground_hautes_herbes_*_bas.png`). Nulle : la bande provisoire du joueur.
@export var grass_front: Texture2D
## Cases « calmes » (Tour Pokémon, 5F : dalle purifiée et ses voisines praticables) : aucune
## rencontre sauvage n'y est tirée (jalon 19, docs/tech/jalon-19.md §2.2). Vide : aucune.
@export var calm_cells: Array[Vector2i] = []
## Tronçon de Piste Cyclable (passe systèmes 2, `systemes-2.md` §2.3) : on y monte d'office en
## Vélo avec la Bicyclette, on n'en descend pas ([MountRules], [BikeRules]).
@export var cycling_road: bool = false
## Cases de pente de la Piste (§2.3) : sans appui, le joueur en Vélo y dérive vers le bas
## ([CyclingSlope]) ; les paliers sont les cases sans marque. Vide : aucune.
@export var slope_cells: Array[Vector2i] = []
## Cases d'eau **surfable** (passe systèmes 2, §2.5) : l'eau est posée avec ([method
## GridWorld.set_surfable]). Les autres cases d'eau restent du décor. Vide : aucune.
@export var surf_cells: Array[Vector2i] = []
## Courants actifs (§2.6) : case → direction cardinale du flux ([method GridWorld.set_current]),
## joués par [ForcedSlideDirector]. Vide : aucun.
@export var current_cells: Dictionary[Vector2i, Vector2i] = {}
## Cases où l'on arrive en Surf même par un warp à pied (§2.5, « Surf forcé »).
@export var forced_surf_cells: Array[Vector2i] = []
## Cases d'eau où l'on peut pêcher (S2C-bis, [FishingSpot]). Vide : aucune. Jalon 22 (T12) :
## [method fishable_set] y ajoute les rectangles de [constant FISHABLE_PATH] pour cette carte
## (cartes livrées avant le J22, dont on ne réécrit pas les grilles).
@export var fishable_cells: Array[Vector2i] = []
## Jalon 22 (T16 [D]) : cases de Piste Cyclable d'une carte qui n'est Piste qu'en partie (Route 16
## ouest, voie basse ; Route 18, partie ouest). [member cycling_road] vrai = toute la carte.
@export var cycling_road_cells: Array[Vector2i] = []

## Cases pêchables des cartes déjà livrées (jalon 22 §0.4 n° 2) : « maps » → carte →
## rectangles [x, y, largeur, hauteur].
const FISHABLE_PATH: String = "res://data/world/fishable.json"
static var _fishable_rects: Dictionary = {}
static var _fishable_loaded: bool = false

var _grid: GridWorld
var _warps: WarpTable
var _interactions: InteractionTable
var _triggers: TriggerTable
var _npcs: Array[Npc] = []
var _npcs_spawned: bool = false
## Fichier de PNJ de la carte (présence conditionnelle, refresh_npcs).
var _roster: NpcRoster
## PNJ créés depuis le fichier (les seuls que refresh_npcs peut retirer).
var _roster_npcs: Array[Npc] = []
## Vrai dès qu'un joueur a été placé sur la carte (routines relâchées).
var _player_present: bool = false


func _ready() -> void:
	if _grid == null:
		_build_grid()
	if not _npcs_spawned:
		_spawn_npcs()


## Grille logique de la carte (construite au premier appel si besoin).
func get_grid() -> GridWorld:
	if _grid == null:
		_build_grid()
	return _grid


## Reconstruit la grille, la table des warps, celle des points d'examen et celle des
## déclencheurs (après modification des tuiles, des props, des warps ou des points). Les PNJ
## sont réinscrits sur leur case.
func rebuild_grid() -> GridWorld:
	_build_grid()
	return _grid


## Passages de la carte (construits avec la grille, à partir des [WarpPoint] de `Warps`).
func get_warps() -> WarpTable:
	if _grid == null:
		_build_grid()
	return _warps


## Points fixes d'interaction de la carte (construits avec la grille, à partir des
## [InteractPoint] de `Interactables`). Les PNJ n'y sont pas : on les trouve par la grille.
func get_interactions() -> InteractionTable:
	if _grid == null:
		_build_grid()
	return _interactions


## Déclencheurs de scène de la carte (construits avec la grille, à partir des
## [EventTriggerPoint] de `Triggers`).
func get_triggers() -> TriggerTable:
	if _grid == null:
		_build_grid()
	return _triggers


## PNJ et Pokémon du décor créés au chargement, dans l'ordre du fichier de données.
func get_npcs() -> Array[Npc]:
	return _npcs.duplicate()


## Cases de meubles dont le sprite dépasse sur la case du dessus ([method
## WorldProp.get_overhang_cells]) : une case juste au-dessus est en partie cachée.
func get_overhang_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var entities := get_node_or_null(^"Entities")
	if entities == null:
		return cells
	for child: Node in entities.get_children():
		var prop := child as WorldProp
		if prop != null:
			cells.append_array(prop.get_overhang_cells())
	return cells


## Crée le PNJ [param spec] pour la durée de la carte (étape « spawn » d'une scène) :
## ajouté à `Entities` et inscrit sur sa case. push_error et null si l'identifiant existe
## déjà, si la case est hors carte ou prise.
func add_npc(spec: NpcSpec) -> Npc:
	if spec == null:
		push_error("GameMap %s : PNJ sans description" % map_id)
		return null
	if get_npc(spec.id) != null:
		push_error("GameMap %s : PNJ « %s » déjà présent" % [map_id, spec.id])
		return null
	return _create_npc(spec)


## Retire le PNJ [param id] : case libérée, nœud libéré. Sans effet s'il n'existe pas.
func remove_npc(id: StringName) -> void:
	var npc := get_npc(id)
	if npc == null:
		return
	npc.leave_grid()
	_npcs.erase(npc)
	_roster_npcs.erase(npc)
	npc.queue_free()


## Ajuste les PNJ du fichier de la carte aux drapeaux [param flags] : crée ceux qui sont
## présents et manquent, retire ceux qui ne le sont plus (case libérée tout de suite). Les
## PNJ ajoutés par [method add_npc] ne sont jamais retirés (ils restent jusqu'au départ de
## la carte). Sans doublon si on l'appelle plusieurs fois.
func refresh_npcs(flags: StoryFlags) -> void:
	if not _npcs_spawned:
		_spawn_npcs()
	apply_flag_gates(flags)
	if _roster == null:
		return
	for npc: Npc in _roster_npcs.duplicate():
		var spec := npc.get_spec()
		if not spec.is_present(flags) or _is_misplaced(spec, flags):
			remove_npc(npc.get_id())
	for spec: NpcSpec in _present_specs(flags):
		if get_npc(spec.id) == null:
			var npc := _create_npc(spec)
			if npc != null:
				_roster_npcs.append(npc)


## Montre ou cache chaque [FlagGate] de la carte selon [param flags] (jalon 14) : appelé par
## [method refresh_npcs] à l'arrivée, puis par Boot à chaque drapeau changé pendant la visite.
## Sans effet hors de l'arbre de scènes.
func apply_flag_gates(flags: StoryFlags) -> void:
	if not is_inside_tree():
		return
	for node: Node in get_tree().get_nodes_in_group(FlagGate.GROUP):
		if is_ancestor_of(node):
			(node as FlagGate).apply(flags)
			(node as FlagGate).apply_to_grid(_grid)


## Acteur de décor [param id] (jalon 21, `jalon-21.md` §2.3) : nœud de la carte du groupe
## [constant PropActor.GROUP] nommé [param id] (le sprite de Ronflex) ; null sinon ou hors de
## l'arbre. Les étapes « react » / « emote » et la page « react » d'un dialogue s'en servent
## quand [param id] n'est pas un PNJ.
func get_scene_prop(id: StringName) -> Node:
	if not is_inside_tree() or id.is_empty():
		return null
	for node: Node in get_tree().get_nodes_in_group(PropActor.GROUP):
		if node.name == id and is_ancestor_of(node):
			return node
	return null


## PNJ d'identifiant [param id], ou null.
func get_npc(id: StringName) -> Npc:
	for npc: Npc in _npcs:
		if npc.get_id() == id:
			return npc
	return null


## Rectangle monde de la carte, en pixels de référence (limites de caméra).
func get_pixel_rect() -> Rect2i:
	return Grid.map_pixel_rect(size)


## Arène de combat en pixels monde (vide si la carte n'en a pas).
func get_battle_arena_rect() -> Rect2:
	if not battle_arena.has_area():
		return Rect2()
	return Rect2(Vector2(battle_arena.position * Grid.TILE_SIZE),
		Vector2(battle_arena.size * Grid.TILE_SIZE))


## Case d'un point d'apparition (Marker2D enfant de `Spawns`), ou (-1, -1) s'il manque.
func get_spawn_cell(spawn_name: StringName) -> Vector2i:
	var marker := get_node_or_null(NodePath("Spawns/" + String(spawn_name))) as Node2D
	if marker == null:
		push_error("GameMap %s : spawn inconnu « %s »" % [map_id, spawn_name])
		return Vector2i(-1, -1)
	return Grid.world_to_cell(marker.position)


## Vrai si le point d'apparition existe (sans erreur, contrairement à get_spawn_cell).
func has_spawn(spawn_name: StringName) -> bool:
	if spawn_name.is_empty():
		return false
	return get_node_or_null(NodePath("Spawns/" + String(spawn_name))) is Node2D


## Nœud y-trié qui contient props, PNJ et joueur.
func get_entities() -> Node2D:
	return get_node(^"Entities") as Node2D


## Dormeurs de la Poké Flûte (passe systèmes 2, §2.4) : un [FluteTarget] par point
## d'interaction qui porte une [member InteractPoint.flute_cutscene].
func flute_targets() -> Array[FluteTarget]:
	var targets: Array[FluteTarget] = []
	var points := get_node_or_null(^"Interactables")
	if points == null:
		return targets
	for child: Node in points.get_children():
		var point := child as InteractPoint
		if point == null or point.flute_cutscene.is_empty():
			continue
		var target := FluteTarget.new()
		target.cells = point.get_cells()
		target.unless_flags = point.unless_flags.duplicate()
		target.cutscene_id = point.flute_cutscene
		targets.append(target)
	return targets


## Ce que la carte permet à la monture du joueur (passe systèmes 2, §2.2).
func mount_traits() -> MapTraits:
	var traits := MapTraits.new(interior, cycling_road)
	for cell: Vector2i in forced_surf_cells:
		traits.forced_surf_cells[cell] = true
	return traits


## Cases pêchables de la carte, en ensemble ([method FishingSpot.in_front]) : celles de la
## scène et celles de [constant FISHABLE_PATH] pour [member map_id] (jalon 22, T12).
func fishable_set() -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	for cell: Vector2i in fishable_cells:
		cells[cell] = true
	for rect: Rect2i in fishable_rects_for(map_id):
		for y: int in range(rect.position.y, rect.end.y):
			for x: int in range(rect.position.x, rect.end.x):
				cells[Vector2i(x, y)] = true
	return cells


## Rectangles pêchables de [constant FISHABLE_PATH] pour [param id] (vide si aucun).
static func fishable_rects_for(id: StringName) -> Array[Rect2i]:
	if not _fishable_loaded:
		_fishable_loaded = true
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FISHABLE_PATH))
		if parsed is Dictionary and (parsed as Dictionary).get("maps") is Dictionary:
			_fishable_rects = (parsed as Dictionary)["maps"]
		else:
			push_error("GameMap : %s illisible" % FISHABLE_PATH)
	var rects: Array[Rect2i] = []
	for entry: Variant in _fishable_rects.get(String(id), []):
		var r: Array = entry
		rects.append(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
	return rects


## Vrai si [param cell] est sur la Piste Cyclable (toute la carte, ou une case de
## [member cycling_road_cells]).
func is_cycling_road_at(cell: Vector2i) -> bool:
	return cycling_road or cycling_road_cells.has(cell)


## [method mount_traits] vus depuis [param cell] (Piste en partie, jalon 22).
func mount_traits_at(cell: Vector2i) -> MapTraits:
	var traits := mount_traits()
	traits.cycling_road = is_cycling_road_at(cell)
	return traits


## Ajoute le joueur à `Entities` et le place sur le spawn.
func spawn_player(player: Player, spawn_name: StringName, facing: Vector2i) -> void:
	var entities := get_entities()
	if player.get_parent() != entities:
		if player.get_parent() != null:
			player.get_parent().remove_child(player)
		entities.add_child(player)
	player.enter_map(get_grid(), get_spawn_cell(spawn_name), facing, get_pixel_rect())
	player.set_grass_front(grass_front)
	_release_routines()


## Ajoute le joueur à `Entities` et le place sur la case [param cell] (reprise d'une
## sauvegarde, jalon 5C.5). La case doit venir de [method find_standing_cell].
func spawn_player_at(player: Player, cell: Vector2i, facing: Vector2i) -> void:
	var entities := get_entities()
	if player.get_parent() != entities:
		if player.get_parent() != null:
			player.get_parent().remove_child(player)
		entities.add_child(player)
	player.enter_map(get_grid(), cell, facing, get_pixel_rect())
	player.set_grass_front(grass_front)
	_release_routines()


## Case où reprendre la partie à partir de la case sauvegardée [param cell] (jalon 5C.5) :
## elle-même si le joueur peut s'y tenir, sinon la plus proche en marchant (parcours en
## largeur à travers les cases ni solides ni d'eau). « Pouvoir s'y tenir » : libre pour
## [param mover] ([method GridWorld.is_free]) et pas la case de départ d'un PNJ du fichier de
## la carte, présent ou non (un PNJ qui marchait peut y revenir, un PNJ conditionné par les
## drapeaux y est créé après le placement). Case hors carte ramenée au bord. (-1, -1) si
## aucune case ne convient.
func find_standing_cell(cell: Vector2i, mover: Object = null) -> Vector2i:
	var grid := get_grid()
	var start := cell.clamp(Vector2i.ZERO, size - Vector2i.ONE)
	var homes: Dictionary[Vector2i, bool] = {}
	if _roster != null:
		for spec: NpcSpec in _roster.get_all():
			homes[spec.cell] = true
	var seen: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		if grid.is_free(current, mover) and not homes.has(current):
			return current
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = current + direction
			if seen.has(next) or not grid.is_in_bounds(next) or grid.is_solid(next) \
					or grid.is_water(next):
				continue
			seen[next] = true
			queue.append(next)
	return Vector2i(-1, -1)


func _build_grid() -> void:
	_grid = GridWorld.new(size)
	for path: NodePath in _TILE_LAYERS:
		var layer := get_node_or_null(path) as TileMapLayer
		if layer != null:
			_read_layer(layer)
	for cell: Vector2i in blocked_cells:
		_grid.set_solid(cell)
	for cell: Vector2i in slope_cells:
		_grid.set_slope(cell)
	for cell: Vector2i in surf_cells:
		_grid.set_surfable(cell)
	for cell: Vector2i in current_cells:
		_grid.set_current(cell, current_cells[cell])
	# Objets triés par les pieds (Entities) et relief peint posé au sol (GroundDecals :
	# falaises, massif ; jalon-07.md §6.6).
	for layer_path: NodePath in _PROP_LAYERS:
		var layer := get_node_or_null(layer_path)
		if layer == null:
			continue
		for child: Node in layer.get_children():
			var prop := child as WorldProp
			if prop != null:
				_grid.add_solid_footprint(prop.get_anchor_cell(), prop.get_footprint())
				prop.level_rows = level_rows
	# Jalon 15 : décor qui bloque ses cases tant qu'il est affiché (FlagGate.blocking_cells).
	for layer_path: NodePath in _PROP_LAYERS:
		var gates := get_node_or_null(layer_path)
		if gates == null:
			continue
		for child: Node in gates.get_children():
			if child is FlagGate:
				(child as FlagGate).apply_to_grid(_grid)
	for npc: Npc in _npcs:
		if not npc.enter_grid(_grid):
			push_error("GameMap %s : PNJ « %s » ne peut plus occuper %s" % [
				map_id, npc.get_id(), npc.get_cell()])
	_build_warps()
	_build_interactions()
	_build_triggers()


func _build_warps() -> void:
	_warps = WarpTable.new()
	var warps := get_node_or_null(^"Warps")
	if warps == null:
		return
	for child: Node in warps.get_children():
		var point := child as WarpPoint
		if point != null and not _warps.add(point.to_warp()):
			push_error("GameMap %s : warp invalide en %s" % [map_id, point.get_cell()])


func _build_interactions() -> void:
	_interactions = InteractionTable.new()
	var points := get_node_or_null(^"Interactables")
	if points == null:
		return
	for child: Node in points.get_children():
		var point := child as InteractPoint
		if point == null:
			continue
		# Une seule erreur par point (la première case refusée) ; les autres cases restent.
		var refused := Vector2i(-1, -1)
		var interactions := point.to_interactions()
		if interactions.is_empty():
			refused = point.get_cell()
		for interaction: Interaction in interactions:
			if not _interactions.add(interaction) and refused == Vector2i(-1, -1):
				refused = interaction.cell
		if refused != Vector2i(-1, -1):
			push_error("GameMap %s : interaction invalide en %s" % [map_id, refused])


func _build_triggers() -> void:
	_triggers = TriggerTable.new()
	var points := get_node_or_null(^"Triggers")
	if points == null:
		return
	for child: Node in points.get_children():
		var point := child as EventTriggerPoint
		if point == null:
			continue
		# Une seule erreur par point (la première case refusée) ; les autres cases restent.
		var refused := Vector2i(-1, -1)
		var triggers := point.to_triggers()
		if triggers.is_empty():
			refused = point.get_cell()
		for trigger: EventTrigger in triggers:
			if not _triggers.add(trigger) and refused == Vector2i(-1, -1):
				refused = trigger.cell
		if refused != Vector2i(-1, -1):
			push_error("GameMap %s : déclencheur invalide en %s" % [map_id, refused])


## Crée les PNJ de `<npcs_dir>/<map_id>.json` présents en nouvelle partie (sans drapeaux)
## dans `Entities` et les inscrit sur la grille. Une case hors carte ou déjà occupée :
## push_error, le PNJ n'est pas créé.
func _spawn_npcs() -> void:
	_npcs_spawned = true
	if map_id.is_empty():
		return
	var entities := get_node_or_null(^"Entities")
	if entities == null:
		return
	_roster = NpcRoster.load_for_map(map_id, npcs_dir)
	for spec: NpcSpec in _present_specs(null):
		var npc := _create_npc(spec)
		if npc != null:
			_roster_npcs.append(npc)


## Entrées du fichier présentes avec [param flags], sans les Pokémon d'ambiance dont
## l'apparence manque encore ([method awaits_painted_look]), chacune à sa place pour ces
## drapeaux ([method NpcSpec.placed_for], clé « moved » du jalon 14).
func _present_specs(flags: StoryFlags) -> Array[NpcSpec]:
	var present: Array[NpcSpec] = []
	for spec: NpcSpec in _roster.get_present(flags):
		if not awaits_painted_look(spec):
			present.append(spec.placed_for(flags))
	return present


## Vrai si le PNJ créé avec [param spec] n'est pas à la place que lui donnent [param flags]
## (clé « moved », jalon 14) : [method refresh_npcs] le recrée à la bonne place. Seulement à
## l'arrivée sur la carte : dans la visite où le drapeau se lève, le PNJ reste où la scène
## l'a mené.
func _is_misplaced(spec: NpcSpec, flags: StoryFlags) -> bool:
	var roster_spec := _roster.get_spec(spec.id)
	if roster_spec == null or not roster_spec.has_moved_place():
		return false
	var placed := roster_spec.placed_for(flags)
	return placed.cell != spec.cell or placed.facing != spec.facing


## Vrai pour un Pokémon d'ambiance (`pokemon/<espèce>`, non interactif) dont aucune planche
## n'existe encore (jalon 9 : Chenipan, refusé par Codex au T17, jalon-09.md §6.15) : la carte
## le saute sans erreur plutôt que de le montrer sous l'apparence générique d'un humain ; il
## apparaît de lui-même quand ses SpriteFrames sont générés.
static func awaits_painted_look(spec: NpcSpec) -> bool:
	return String(spec.sprite).begins_with(CharacterLook.POKEMON_PREFIX) \
		and not spec.is_interactive() and not Npc.has_frames(spec.sprite)


## Crée un [Npc] dans `Entities` et l'inscrit sur sa case. Une case hors carte ou déjà
## occupée : push_error, rien n'est créé (null).
func _create_npc(spec: NpcSpec) -> Npc:
	var entities := get_node_or_null(^"Entities")
	if entities == null:
		push_error("GameMap %s : pas de nœud Entities pour « %s »" % [map_id, spec.id])
		return null
	var grid := get_grid()
	if not grid.is_in_bounds(spec.cell):
		push_error("GameMap %s : PNJ « %s » hors de la carte en %s" % [
			map_id, spec.id, spec.cell])
		return null
	if grid.is_occupied(spec.cell):
		push_error("GameMap %s : PNJ « %s » sur une case déjà occupée %s" % [
			map_id, spec.id, spec.cell])
		return null
	var npc := _NPC_SCENE.instantiate() as Npc
	npc.setup(spec)
	npc.set_routine_held(not _player_present)
	entities.add_child(npc)
	npc.enter_grid(grid)
	_npcs.append(npc)
	return npc


## Le joueur est arrivé : les routines de marche reprennent (DA.2).
func _release_routines() -> void:
	_player_present = true
	for npc: Npc in _npcs:
		npc.set_routine_held(false)


func _read_layer(layer: TileMapLayer) -> void:
	for cell: Vector2i in layer.get_used_cells():
		var data := layer.get_cell_tile_data(cell)
		if data == null:
			continue
		if _get_bool(data, OverworldTiles.DATA_SOLID):
			_grid.set_solid(cell)
		if _get_bool(data, OverworldTiles.DATA_WATER):
			_grid.set_water(cell)
		if _get_bool(data, OverworldTiles.DATA_TALL_GRASS):
			_grid.set_tall_grass(cell)
		if _get_bool(data, OverworldTiles.DATA_RUBBLE):
			_grid.set_rubble(cell)
		if data.has_custom_data(OverworldTiles.DATA_LEDGE):
			var ledge: int = data.get_custom_data(OverworldTiles.DATA_LEDGE)
			if ledge != GridWorld.Ledge.NONE:
				_grid.set_ledge(cell, ledge as GridWorld.Ledge)


static func _get_bool(data: TileData, layer_name: StringName) -> bool:
	return data.has_custom_data(layer_name) and bool(data.get_custom_data(layer_name))
