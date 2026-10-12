extends GutTest
## Bourg Palette peint (DA.2, docs/tech/integration-da-bourg-route1.md, Q1 = A) : lumière,
## aucune tuile visible, sol peint avec son rivage (sable, mer), sous-bois et forêt serrée dont
## le feuillage ne couvre aucune case praticable, bâtiments peints aux ancres du plan,
## **géométrie logique du jalon 6 inchangée** (`tests/fixtures/maps/pallet_town_logic.txt`,
## à une case près : la mangeoire de Mme Aoki), objets solides hors des cases utiles, PNJ
## peints, quatre routines valides et retenues tant qu'aucun joueur n'est sur la carte.
## Le reste de la géométrie est vérifié par test_pallet_town (inchangé).

const MAP_PATH := "res://game/world/maps/pallet_town.tscn"
const LOGIC_PATH := "res://tests/fixtures/maps/pallet_town_logic.txt"
const SIZE := Vector2i(48, 34)
const START := Vector2i(36, 10)
## Seules cases solides nouvelles (défaut DA.2) : la mangeoire.
const NEW_SOLID: Array[Vector2i] = [Vector2i(30, 15)]
## Bâtiments et repères : nom → [objet peint, ancre].
const BUILDINGS: Dictionary = {
	&"RivalHouse": ["bldg_maison_rival_01", Vector2i(11, 9)],
	&"PlayerHouse": ["bldg_maison_joueur_01", Vector2i(36, 9)],
	&"OakLab": ["bldg_labo_01", Vector2i(24, 22)],
	&"PlazaTree": ["tree_ancien_01", Vector2i(24, 16)],
	&"GreenhouseLarge": ["bldg_serre_01", Vector2i(20, 27)],
	&"GreenhouseSmall": ["bldg_serre_01", Vector2i(33, 27)],
	&"Van": ["prop_camionnette_01", Vector2i(15, 22)],
	&"SecretBrambles": ["prop_ronces_01", Vector2i(42, 26)],
	&"AokiFeeder": ["prop_mangeoire_01", Vector2i(30, 15)],
}
## Objets « avec propriétaire » (dossier 01, principes d'habillage).
const OWNED: Array[StringName] = [
	&"RivalWoodpile", &"MomHydrangeas", &"MomPots", &"Wheelbarrow", &"WateringCan",
	&"Scarecrow", &"HaruTraps", &"HaruBoat", &"LabBikes", &"LabEquipment", &"AokiFeeder",
]
## Personnes et Pokémon peints de la carte (CharacterLook les trouve à 1:1, LINEAR).
const PAINTED: Array[StringName] = [
	&"aoki", &"leo", &"haru", &"researcher", &"pokemon/pidgey", &"pokemon/rattata",
]
## Les quatre routines (dossier 01).
const ROUTINES: Array[StringName] = [&"aoki", &"haru", &"nils", &"researcher"]
## Cases du prologue : Chen part de (24, 13), remonte les colonnes 23–24 jusqu'aux herbes,
## puis redescend 8 pas avec le joueur.
const PROLOGUE := Rect2i(22, 3, 4, 11)

var _map: GameMap
var _grid: GridWorld
var _reachable: Dictionary[Vector2i, bool]
var _logic: PackedStringArray


func before_all() -> void:
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_reachable = _grid.find_reachable(START)
	_logic = FileAccess.get_file_as_string(LOGIC_PATH).strip_edges().split("\n")


func after_all() -> void:
	_map.free()


func _prop_id(node: Node) -> String:
	return node.scene_file_path.get_file().get_basename()


func _entities_of(prefix: String) -> Array[Node2D]:
	var found: Array[Node2D] = []
	for child: Node in _map.get_entities().get_children():
		if child is Node2D and _prop_id(child).begins_with(prefix):
			found.append(child as Node2D)
	return found


## Cases utiles : chemins logiques et allées pavées (hors de la place), warps, spawns, déclencheurs, PNJ et leurs
## routines, colonnes du prologue.
func _useful_cells() -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	for warp: Warp in _map.get_warps().get_all():
		cells[warp.cell] = true
	for trigger: EventTrigger in _map.get_triggers().get_all():
		cells[trigger.cell] = true
	for marker: Node in _map.get_node(^"Spawns").get_children():
		cells[Grid.world_to_cell((marker as Node2D).position)] = true
	for spec: NpcSpec in NpcRoster.load_for_map(&"pallet_town").get_all():
		cells[spec.cell] = true
		for cell: Vector2i in spec.route_cells:
			cells[cell] = true
	var ground := _map.get_node(^"Ground") as TileMapLayer
	for cell: Vector2i in ground.get_used_cells():
		var kind := ground.get_cell_atlas_coords(cell).y
		# Les allées pavées comptent ; la place elle-même (17..31 × 12..17) est un espace
		# ouvert où un banc ou une mangeoire peuvent se poser.
		var on_plaza := Rect2i(17, 12, 15, 6).has_point(cell)
		if kind == OverworldTiles.Kind.DIRT or kind == OverworldTiles.Kind.BOARDWALK \
				or (kind == OverworldTiles.Kind.COBBLE and not on_plaza):
			cells[cell] = true
	for y in range(PROLOGUE.position.y, PROLOGUE.end.y):
		for x in range(PROLOGUE.position.x, PROLOGUE.end.x):
			cells[Vector2i(x, y)] = true
	return cells


func test_light_profile_and_grass_front() -> void:
	assert_eq(_map.light_profile, &"golden_hour")
	assert_not_null(_map.grass_front, "cache-jambes peint")
	assert_eq(_map.grass_front.resource_path,
		"res://assets/world/ground/ground_hautes_herbes_jaune_01_bas.png")


func test_no_tile_layer_is_visible() -> void:
	var layers := _map.find_children("*", "TileMapLayer", true, false)
	assert_eq(layers.size(), 4, "Ground, Detail, Obstacles, Overhead gardés (source logique)")
	for layer: Node in layers:
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_logic_grid_is_the_jalon_6_one() -> void:
	assert_eq(_logic.size(), SIZE.y, "géométrie figée")
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			var c := _logic[y][x]
			assert_eq(_grid.is_water(cell), c == "~", "eau en %s" % cell)
			assert_eq(_grid.is_tall_grass(cell), c == "g" or c == "G", "herbes en %s" % cell)
			var solid := c == "#" or c == "G" or NEW_SOLID.has(cell)
			if c != "~":
				assert_eq(_grid.is_solid(cell), solid, "solide en %s" % cell)
	for cell: Vector2i in NEW_SOLID:
		assert_eq(_logic[cell.y][cell.x], ".", "%s était praticable" % cell)


func test_painted_ground_with_shore_then_forest_floor() -> void:
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	var floor_node := _map.get_node_or_null(^"ForestFloor") as ForestFloor
	assert_not_null(ground, "sol peint")
	assert_not_null(floor_node, "sous-bois")
	if ground == null or floor_node == null:
		return
	assert_eq(ground.size, SIZE)
	assert_lt(ground.get_index(), floor_node.get_index(), "sous-bois au-dessus du sol peint")
	var mask := ground.mask.get_image()
	assert_eq(GroundMask.kind_at(mask, Vector2i(24, 14)), GroundMask.Kind.PAVING, "place")
	assert_eq(GroundMask.kind_at(mask, Vector2i(23, 6)), GroundMask.Kind.PATH, "Route 1")
	assert_eq(GroundMask.kind_at(mask, Vector2i(30, 29)), GroundMask.Kind.PATH, "sentier côtier")
	assert_eq(GroundMask.kind_at(mask, Vector2i(10, 7)), GroundMask.Kind.GRASS)
	assert_not_null(ground.shore_mask, "rivage")
	var shore := ground.shore_mask.get_image()
	assert_eq(GroundMask.shore_at(shore, Vector2i(8, 28)), GroundMask.Kind.SAND, "plage")
	assert_eq(GroundMask.shore_at(shore, Vector2i(10, 30)), GroundMask.Kind.SAND,
		"le sentier traverse la plage")
	assert_eq(GroundMask.shore_at(shore, Vector2i(9, 33)), GroundMask.Kind.WATER, "sous le ponton")
	assert_eq(GroundMask.shore_at(shore, Vector2i(24, 14)), GroundMask.Kind.GRASS)
	var material := ground.get_shader_material()
	assert_true(material.get_shader_parameter(&"has_shore"), "rivage dessiné")
	assert_not_null(material.get_shader_parameter(&"water_texture"))
	for y in SIZE.y:
		for x in SIZE.x:
			var cell := Vector2i(x, y)
			if _grid.is_water(cell) and cell != Vector2i(9, 32) and cell != Vector2i(9, 33):
				assert_eq(GroundMask.shore_at(shore, cell), GroundMask.Kind.WATER,
					"eau dessinée en %s" % cell)
			if floor_node.is_forest(cell):
				assert_false(_reachable.has(cell), "sous-bois sur une case praticable %s" % cell)


func test_buildings_at_the_plan_anchors() -> void:
	for node_name: StringName in BUILDINGS:
		var spec: Array = BUILDINGS[node_name]
		var prop := _map.get_entities().get_node_or_null(NodePath(node_name)) as WorldProp
		assert_not_null(prop, String(node_name))
		if prop == null:
			continue
		assert_eq(_prop_id(prop), spec[0], "%s : objet peint" % node_name)
		assert_eq(prop.get_anchor_cell(), spec[1], "%s : ancre" % node_name)
		for cell: Vector2i in prop.get_solid_cells():
			assert_true(_grid.is_solid(cell), "%s solide en %s" % [node_name, cell])
	# Labo : la double porte peinte est centrée sur la case de porte, ses voisines bloquées.
	var lab := _map.get_entities().get_node(^"OakLab") as WorldProp
	assert_almost_eq(lab.position.x, 24.5 * Grid.TILE_SIZE, 1.0)
	assert_true(_grid.is_solid(Vector2i(23, 22)) and _grid.is_solid(Vector2i(25, 22)))
	assert_false(_grid.is_solid(Vector2i(24, 22)))
	assert_false(lab.fade_when_covering, "labo réduit : pas de fondu pour ses antennes")


func test_no_placeholder_prop_left() -> void:
	for child: Node in _map.get_entities().get_children():
		if child is WorldProp:
			assert_true(child.scene_file_path.begins_with("res://game/world/props/painted/"),
				"%s : %s" % [child.name, child.scene_file_path])


func test_forest_canopy_never_covers_a_walkable_cell() -> void:
	var trees := _entities_of("tree_foret_")
	assert_gt(trees.size(), 60, "forêt serrée sur les lisières")
	for tree: Node2D in trees:
		var foot := tree.position / float(Grid.TILE_SIZE)
		for cell: Vector2i in DenseForest.canopy_cells(foot):
			if not _grid.is_in_bounds(cell):
				continue
			assert_false(_reachable.has(cell), "%s : feuillage sur %s" % [tree.name, cell])
			assert_true(_grid.is_solid(cell), "%s : %s est solide" % [tree.name, cell])
		assert_true((tree as WorldProp).get_footprint().is_empty(), "%s sans emprise" % tree.name)


func test_tall_grass_tufts_two_per_cell() -> void:
	var tufts := _entities_of("ground_hautes_herbes_jaune_01")
	assert_eq(tufts.size(), 12, "deux touffes par case (23..24 × 0..2)")
	for tuft: Node2D in tufts:
		var cell := Vector2i((tuft.position / float(Grid.TILE_SIZE) - Vector2(0, 0.01)).floor())
		assert_true(_grid.is_tall_grass(cell), "%s sur les hautes herbes" % tuft.name)


func test_shore_props_cliff_pier_boat() -> void:
	var decals := _map.get_node(^"GroundDecals")
	var cliffs := 0
	for child: Node in decals.get_children():
		if child is WorldProp and _prop_id(child) == "relief_falaise_01":
			cliffs += 1
			for cell: Vector2i in (child as WorldProp).get_solid_cells():
				assert_eq(cell.y, 31, "falaise sur la rangée 31")
	assert_eq(cliffs, 9, "falaise de x 15 au bord est")
	var pier := decals.get_node_or_null(^"Pier") as Sprite2D
	assert_not_null(pier, "ponton")
	assert_not_null(decals.get_node_or_null(^"BeachStairs"), "escalier en bois")
	var boat := _map.get_entities().get_node(^"HaruBoat") as WorldProp
	assert_eq(boat.get_solid_cells(), [Vector2i(12, 31)] as Array[Vector2i])


func test_owned_objects_exist_and_new_solids_avoid_useful_cells() -> void:
	for node_name: StringName in OWNED:
		assert_not_null(_map.get_entities().get_node_or_null(NodePath(node_name)),
			String(node_name))
	var useful := _useful_cells()
	for cell: Vector2i in NEW_SOLID:
		assert_false(useful.has(cell), "%s hors des cases utiles" % cell)
	# Tout le reste de l'emprise des objets est fait de cases déjà solides au jalon 6.
	for child: Node in _map.get_entities().get_children():
		var prop := child as WorldProp
		if prop == null:
			continue
		for cell: Vector2i in prop.get_solid_cells():
			var c := _logic[cell.y][cell.x]
			assert_true(c == "#" or NEW_SOLID.has(cell), "%s : %s" % [prop.name, cell])


func test_npcs_are_painted() -> void:
	for sprite: StringName in PAINTED:
		var look := CharacterLook.resolve(sprite)
		assert_true(look.painted, String(sprite))
		assert_eq(look.filter, CanvasItem.TEXTURE_FILTER_LINEAR)
	for npc: Npc in _map.get_npcs():
		assert_true(CharacterLook.resolve(npc.get_spec().sprite).painted,
			"%s peint" % npc.get_id())
	for sprite: StringName in [&"mom", &"oak", &"maya"]:
		assert_true(CharacterLook.resolve(sprite).painted, "%s peint (DA.4)" % sprite)


func test_routines_are_valid_and_clear_of_the_prologue() -> void:
	var roster := NpcRoster.load_for_map(&"pallet_town")
	var warps: Array[Vector2i] = []
	for warp: Warp in _map.get_warps().get_all():
		warps.append(warp.cell)
	for id: StringName in ROUTINES:
		var spec := roster.get_spec(id)
		assert_not_null(spec, String(id))
		if spec == null:
			continue
		assert_true(spec.has_route(), "%s a une routine" % id)
		for cell: Vector2i in spec.route_cells:
			var label := "%s en %s" % [id, cell]
			assert_true(_reachable.has(cell) or _grid.get_occupant(cell) is Npc, label)
			assert_false(_grid.is_solid(cell) or _grid.is_water(cell), label + " praticable")
			assert_false(warps.has(cell), label + " hors warp")
			assert_false(PROLOGUE.has_point(cell), label + " hors du prologue")
			assert_false(_grid.is_tall_grass(cell), label + " hors des herbes")
			assert_ne(cell, Vector2i(28, 13), label + " : graines de Mme Aoki")
	# Chercheur : interactif (réplique validée par Kevin), même réplique avant et après le labo.
	var researcher := roster.get_spec(&"researcher")
	assert_eq(researcher.dialogue, &"researcher")
	assert_eq(researcher.verb, Interaction.Kind.TALK)
	assert_false(researcher.is_conditional())
	var library := DialogueLibrary.new()
	library.load_dir()
	var talk := library.get_dialogue(&"researcher")
	assert_not_null(talk, "dialogue du chercheur")
	if talk != null:
		assert_eq(talk.variants.size(), 1, "une seule réplique")
		assert_eq(talk.variants[0].pages.size(), 2)
	# Nils et son Rattata : même boucle, le Rattata un pas derrière.
	var nils := roster.get_spec(&"nils")
	var rattata := roster.get_spec(&"nils_rattata")
	assert_eq(nils.route_cells, rattata.route_cells)
	assert_eq((rattata.route_start + 1) % rattata.route_cells.size(), nils.route_start)


func test_routines_wait_for_the_player() -> void:
	for id: StringName in ROUTINES:
		var npc := _map.get_npc(id)
		assert_true(npc.is_routine_held(), "%s retenu sans joueur" % id)
		assert_eq(npc.get_cell(), npc.get_spec().cell, "%s sur sa case de départ" % id)
