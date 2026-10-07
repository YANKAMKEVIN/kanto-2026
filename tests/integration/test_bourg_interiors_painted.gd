extends GutTest
## Intérieurs peints de Bourg Palette (DA.3, docs/tech/integration-da-bourg-route1.md) : lumière
## `interior_warm`, aucune tuile, enveloppe peinte à 1:1, meubles peints (scènes
## `game/world/props/painted/`), tapis à plat, et **géométrie logique du jalon 2 inchangée**
## (`tests/fixtures/maps/<carte>_logic.txt`, figée par `tools/dump_map_logic.gd` avant le
## passage au peint). Le reste (warps, spawns, cases réservées, PNJ) : test_interiors,
## test_npc_placement, test_map_links (inchangés en géométrie).

const MAPS: Dictionary = {
	&"player_house_2f": "int_chambre_joueur_coque",
	&"player_house_1f": "int_maison_joueur_rdc_coque",
	&"rival_house": "int_maison_rival_coque",
	&"oak_lab": "int_labo_coque",
}
const PAINTED_DIR := "res://game/world/props/painted/"
## Décors du jalon 3A posés sur un meuble (sans emprise), provisoires faute d'image peinte.
const DECOR: Array[StringName] = [&"Breakfast", &"BedItems"]

var _maps: Dictionary = {}


func before_all() -> void:
	for map_id: StringName in MAPS:
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


func _logic(map_id: StringName) -> PackedStringArray:
	var path := "res://tests/fixtures/maps/%s_logic.txt" % map_id
	return FileAccess.get_file_as_string(path).strip_edges().split("\n")


func test_light_profile_and_no_tiles() -> void:
	var library := LightingLibrary.new()
	library.load_file()
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		assert_eq(map.light_profile, &"interior_warm", String(map_id))
		assert_eq(map.light_profile, library.get_map_profile(map_id), "profil prévu (DA.0)")
		for child: Node in map.get_children():
			assert_false(child is TileMapLayer, "%s : %s" % [map_id, child.name])


func test_painted_shell_at_one_to_one_under_everything() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var shell := map.get_node_or_null(^"Shell") as Sprite2D
		assert_not_null(shell, String(map_id))
		if shell == null:
			continue
		assert_eq(shell.texture.resource_path.get_file().get_basename(), MAPS[map_id])
		assert_eq(shell.texture.get_size(), Vector2(map.size * Grid.TILE_SIZE), String(map_id))
		assert_eq(shell.position, Vector2.ZERO)
		assert_false(shell.centered)
		assert_eq(shell.z_index, WorldLighting.Z_GROUND)


## La grille (solides) est exactement celle du jalon 2, case par case.
func test_logic_grid_is_the_frozen_one() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var grid := map.get_grid()
		var lines := _logic(map_id)
		assert_eq(lines.size(), map.size.y, String(map_id))
		for y: int in mini(lines.size(), map.size.y):
			for x: int in map.size.x:
				var cell := Vector2i(x, y)
				assert_eq(grid.is_solid(cell), lines[y][x] == "#", "%s : %s" % [map_id, cell])


func test_furniture_is_painted_and_stands_on_solid_cells() -> void:
	for map_id: StringName in _maps:
		var map: GameMap = _maps[map_id]
		var grid := map.get_grid()
		var count := 0
		for child: Node in map.get_entities().get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			if DECOR.has(prop.name):
				assert_true(prop.get_solid_cells().is_empty(), "%s sans emprise" % prop.name)
				continue
			count += 1
			assert_true(prop.scene_file_path.begins_with(PAINTED_DIR),
				"%s/%s : %s" % [map_id, prop.name, prop.scene_file_path])
			assert_false(prop.get_solid_cells().is_empty(), "%s/%s solide" % [map_id, prop.name])
			for cell: Vector2i in prop.get_solid_cells():
				assert_true(grid.is_solid(cell), "%s/%s en %s" % [map_id, prop.name, cell])
			var sprite := prop.get_node(^"%Sprite") as Sprite2D
			assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_PARENT_NODE)
		assert_gt(count, 10, "%s meublé" % map_id)


## Meubles posés aux cases du plan du jalon 2 (cases solides exactes).
func test_furniture_at_the_cells_of_the_plan() -> void:
	var plan := {
		&"player_house_2f": {&"Bed": Rect2i(1, 2, 2, 3), &"Desk": Rect2i(6, 2, 3, 1),
			&"Bookshelf": Rect2i(9, 2, 2, 2), &"PokeballCrate": Rect2i(10, 8, 2, 1)},
		# Escalier montant : image sur (1..2, 2..3), seule la rangée du haut est solide.
		&"player_house_1f": {&"Stairs": [Rect2i(1, 2, 2, 1), Rect2i(1, 2, 2, 2)], &"Kitchen": Rect2i(4, 2, 3, 1),
			&"DiningTable": Rect2i(3, 4, 3, 2), &"Sofa": Rect2i(9, 4, 3, 1),
			&"CoatRack": Rect2i(6, 8, 1, 1)},
		&"rival_house": {&"Stairs": Rect2i(7, 2, 3, 3), &"Bed": Rect2i(15, 2, 2, 3),
			&"PartitionBathroom": Rect2i(12, 6, 5, 1), &"PartitionHallWest": Rect2i(7, 7, 1, 3),
			&"PartitionHallEast": Rect2i(10, 7, 1, 3)},
		&"oak_lab": {&"StarterTable": Rect2i(10, 4, 3, 2), &"OakDesk": Rect2i(7, 2, 3, 1),
			&"LongCounter": Rect2i(1, 5, 5, 1), &"Stairs": Rect2i(1, 8, 3, 2),
			&"Bench": Rect2i(11, 8, 3, 1)},
	}
	for map_id: StringName in plan:
		var map: GameMap = _maps[map_id]
		for prop_name: StringName in plan[map_id]:
			var prop := map.get_entities().get_node_or_null(NodePath(prop_name)) as WorldProp
			assert_not_null(prop, "%s/%s" % [map_id, prop_name])
			if prop == null:
				continue
			var entry: Variant = plan[map_id][prop_name]
			var rect: Rect2i = entry[0] if entry is Array else entry
			var image: Rect2i = entry[1] if entry is Array else entry
			var expected: Array[Vector2i] = []
			for y in range(rect.position.y, rect.end.y):
				for x in range(rect.position.x, rect.end.x):
					expected.append(Vector2i(x, y))
			var cells := prop.get_solid_cells()
			cells.sort()
			expected.sort()
			assert_eq(cells, expected, "%s/%s" % [map_id, prop_name])
			# Pied de l'image au milieu du bas du rectangle (prototype).
			var foot_x := (image.position.x + image.size.x / 2.0) * Grid.TILE_SIZE
			assert_eq(prop.position, Vector2(foot_x, image.end.y * Grid.TILE_SIZE),
				"%s/%s : pied" % [map_id, prop_name])


## Escalier du rival : solide sur ses trois colonnes (l'image en fait deux) ; rez-de-chaussée :
## sortie d'une case (7, 8), la moitié ouest de l'ouverture peinte derrière le porte-manteau.
func test_rival_stairs_three_columns_and_one_cell_exit() -> void:
	var rival: GameMap = _maps[&"rival_house"]
	for y in range(2, 5):
		for x in range(7, 10):
			assert_true(rival.get_grid().is_solid(Vector2i(x, y)), "escalier %s" % Vector2i(x, y))
	var ground: GameMap = _maps[&"player_house_1f"]
	assert_true(ground.get_grid().is_solid(Vector2i(6, 8)), "porte-manteau devant l'ouverture")
	assert_not_null(ground.get_warps().find_on_push(Vector2i(7, 8), Vector2i.DOWN))
	assert_null(ground.get_warps().find_on_push(Vector2i(8, 8), Vector2i.DOWN))


func test_rugs_flat_under_the_characters() -> void:
	for map_id: StringName in _maps:
		var decals := (_maps[map_id] as GameMap).get_node(^"GroundDecals") as Node2D
		assert_eq(decals.z_index, WorldLighting.Z_GROUND_DECALS)
		assert_false(decals.y_sort_enabled)
		assert_gt(decals.get_child_count(), 0, String(map_id))
		for rug: Node in decals.get_children():
			assert_true(rug.scene_file_path.begins_with(PAINTED_DIR + "int_tapis_"),
				String(rug.name))
			assert_true(PaintedPropRules.is_traversable(
				StringName(rug.scene_file_path.get_file().get_basename())))


## Cases réservées libres (Chen (8, 4) et devant la table (11, 6) au labo, Maman (7, 4), le
## rival (13, 4)) : praticables dans la grille peinte.
func test_reserved_cells_stay_walkable() -> void:
	var reserved := {
		&"player_house_1f": [Vector2i(7, 4)], &"rival_house": [Vector2i(13, 4)],
		&"oak_lab": [Vector2i(8, 4), Vector2i(11, 6), Vector2i(9, 6), Vector2i(5, 3)],
	}
	for map_id: StringName in reserved:
		for cell: Vector2i in reserved[map_id]:
			assert_false((_maps[map_id] as GameMap).get_grid().is_solid(cell),
				"%s : %s" % [map_id, cell])
