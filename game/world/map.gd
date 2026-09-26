class_name GameMap
extends Node2D
## Carte du monde : couches de tuiles, props, spawns, warps, points d'examen, PNJ. Construit
## sa [GridWorld], sa [WarpTable] et son [InteractionTable].
##
## Au chargement, lit les données `solid`, `water` et `ledge` des tuiles de
## `Ground`, `Detail` et `Obstacles`, puis ajoute l'empreinte de chaque [WorldProp]
## enfant de `Entities`. Les [WarpPoint] enfants de `Warps` forment la table des passages.
## Les [InteractPoint] enfants de `Interactables` forment la table des points fixes
## (docs/tech/jalon-03.md §2.2). Les [EventTriggerPoint] enfants de `Triggers` forment la
## table des déclencheurs de scène (docs/tech/jalon-03b.md §2.2).
## Les PNJ ne sont pas dans la scène : à [method _ready], la carte lit
## `<npcs_dir>/<map_id>.json` ([NpcRoster]), crée un [Npc] par entrée dans `Entities` et
## l'inscrit sur sa case ([method Npc.enter_grid], §2.3). Une scène scriptée peut en ajouter
## ([method add_npc]) ou en retirer ([method remove_npc]) pour la durée de la carte
## (jalon 3B §2.5). Ils n'ont pas d'owner : les scripts de construction ne les sauvent
## jamais dans les `.tscn`.
## Le joueur est ajouté à `Entities` (y-sort) par [method spawn_player].

const _TILE_LAYERS: Array[NodePath] = [^"Ground", ^"Detail", ^"Obstacles"]
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
## Dossier des fichiers de PNJ (`<map_id>.json`) ; les tests pointent sur leurs données.
@export var npcs_dir: String = NpcRoster.DATA_DIR

var _grid: GridWorld
var _warps: WarpTable
var _interactions: InteractionTable
var _triggers: TriggerTable
var _npcs: Array[Npc] = []
var _npcs_spawned: bool = false


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
	npc.queue_free()


## PNJ d'identifiant [param id], ou null.
func get_npc(id: StringName) -> Npc:
	for npc: Npc in _npcs:
		if npc.get_id() == id:
			return npc
	return null


## Rectangle monde de la carte, en pixels de référence (limites de caméra).
func get_pixel_rect() -> Rect2i:
	return Grid.map_pixel_rect(size)


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


## Ajoute le joueur à `Entities` et le place sur le spawn.
func spawn_player(player: Player, spawn_name: StringName, facing: Vector2i) -> void:
	var entities := get_entities()
	if player.get_parent() != entities:
		if player.get_parent() != null:
			player.get_parent().remove_child(player)
		entities.add_child(player)
	player.enter_map(get_grid(), get_spawn_cell(spawn_name), facing, get_pixel_rect())


func _build_grid() -> void:
	_grid = GridWorld.new(size)
	for path: NodePath in _TILE_LAYERS:
		var layer := get_node_or_null(path) as TileMapLayer
		if layer != null:
			_read_layer(layer)
	for cell: Vector2i in blocked_cells:
		_grid.set_solid(cell)
	var entities := get_node_or_null(^"Entities")
	if entities != null:
		for child: Node in entities.get_children():
			var prop := child as WorldProp
			if prop != null:
				_grid.add_solid_footprint(prop.get_anchor_cell(), prop.get_footprint())
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


## Crée les PNJ de `<npcs_dir>/<map_id>.json` dans `Entities` et les inscrit sur la grille.
## Une case hors carte ou déjà occupée : push_error, le PNJ n'est pas créé.
func _spawn_npcs() -> void:
	_npcs_spawned = true
	if map_id.is_empty():
		return
	var entities := get_node_or_null(^"Entities")
	if entities == null:
		return
	var roster := NpcRoster.load_for_map(map_id, npcs_dir)
	for spec: NpcSpec in roster.get_all():
		_create_npc(spec)


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
	entities.add_child(npc)
	npc.enter_grid(grid)
	_npcs.append(npc)
	return npc


func _read_layer(layer: TileMapLayer) -> void:
	for cell: Vector2i in layer.get_used_cells():
		var data := layer.get_cell_tile_data(cell)
		if data == null:
			continue
		if _get_bool(data, OverworldTiles.DATA_SOLID):
			_grid.set_solid(cell)
		if _get_bool(data, OverworldTiles.DATA_WATER):
			_grid.set_water(cell)
		if data.has_custom_data(OverworldTiles.DATA_LEDGE):
			var ledge: int = data.get_custom_data(OverworldTiles.DATA_LEDGE)
			if ledge != GridWorld.Ledge.NONE:
				_grid.set_ledge(cell, ledge as GridWorld.Ledge)


static func _get_bool(data: TileData, layer_name: StringName) -> bool:
	return data.has_custom_data(layer_name) and bool(data.get_custom_data(layer_name))
