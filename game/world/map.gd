class_name GameMap
extends Node2D
## Carte du monde : couches de tuiles, props, spawns. Construit sa [GridWorld].
##
## Au chargement, lit les données `solid`, `water` et `ledge` des tuiles de
## `Ground`, `Detail` et `Obstacles`, puis ajoute l'empreinte de chaque [WorldProp]
## enfant de `Entities`. Le joueur est ajouté à `Entities` (y-sort) par [method spawn_player].

const _TILE_LAYERS: Array[NodePath] = [^"Ground", ^"Detail", ^"Obstacles"]

@export var map_id: StringName = &""
@export var display_name: String = ""
@export var region: String = ""
@export var music: StringName = &""
## Taille en cases.
@export var size: Vector2i = Vector2i(16, 16)
## Cases infranchissables sans rien de visible (ex. chemin qui file hors de la carte :
## le joueur s'arrête une case avant le bord, la tête reste à l'écran).
@export var blocked_cells: Array[Vector2i] = []

var _grid: GridWorld


func _ready() -> void:
	if _grid == null:
		_build_grid()


## Grille logique de la carte (construite au premier appel si besoin).
func get_grid() -> GridWorld:
	if _grid == null:
		_build_grid()
	return _grid


## Reconstruit la grille (après modification des tuiles ou des props).
func rebuild_grid() -> GridWorld:
	_build_grid()
	return _grid


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
	if entities == null:
		return
	for child: Node in entities.get_children():
		var prop := child as WorldProp
		if prop != null:
			_grid.add_solid_footprint(prop.get_anchor_cell(), prop.get_footprint())


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
