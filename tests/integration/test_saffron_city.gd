extends GutTest
## Carte saffron_city (Safrania, jalon 26 T6, docs/tech/jalon-26.md §2.1, §5) sur la vraie scène :
## métadonnées, lumière et zone ; **grille de la scène = grille fonctionnelle**
## `tools/plans/safrania.txt` case par case ; portes de la grille (arrivées `from_*` devant chaque
## porte) ; **quatre postes ↔ ville dans les deux sens** (Routes 5, 7, 8 : intérieurs du J15 / J20 ;
## Route 6 : porte du poste) ; zone jouable → le garde du J20 demande une boisson ; sauvegarde sur
## chaque case d'arrivée de la ville → reprise sur la case (dans les postes : à un pas, la case
## d'arrivée étant celle du garde quand les postes sont fermés) ; Arène et Dojo ouverts au J27, **Dojo jamais
## conditionné par un drapeau** ; panneaux ; objets peints sur des cases bloquées.
## Vie (sbires, habitants, libération) : T9 ; Sylphe : T7.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const MAP_PATH := "res://game/world/maps/saffron_city.tscn"
const PLAN_PATH := "res://tools/plans/safrania.txt"
const SAVE_PATH := "user://test_saffron_city_save.json"
const SIZE := Vector2i(60, 50)
const WALKABLE := ".pD"
const NODE_BUDGET := 3000
const DIRS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}
## Postes : [porte de la ville, arrivée en ville, carte du poste, arrivée dans le poste, case de
## cette arrivée, orientation à l'arrivée en ville, case de la porte du poste vers la ville].
const GATES: Array = [
	["porte_poste_r5", &"from_gate_r5", &"route_5_gate", &"from_saffron", Vector2i(4, 2),
		Vector2i.DOWN, Vector2i(4, 1)],
	["porte_poste_r6", &"from_gate_r6", &"route_6", &"from_saffron", Vector2i(36, 8),
		Vector2i.UP, Vector2i(36, 7)],
	["porte_poste_r7", &"from_gate_r7", &"route_7_gate", &"from_saffron", Vector2i(4, 2),
		Vector2i.RIGHT, Vector2i(4, 1)],
	["porte_poste_r8", &"from_gate_r8", &"route_8_gate", &"from_saffron", Vector2i(4, 2),
		Vector2i.LEFT, Vector2i(4, 1)],
]
## Portes des bâtiments : [position, intérieur, nœud de la façade, objet peint].
const BUILDINGS: Array = [
	["porte_copieur", &"saffron_copycat_house_1f", "CopycatHouse", "bldg_maison_safrania_01"],
	["porte_dojo", &"fighting_dojo", "Dojo", "bldg_dojo_safrania_01"],
	["porte_arene", &"saffron_gym", "Gym", "bldg_arene_safrania_01"],
	["porte_roucool", &"saffron_pidgey_house", "PidgeyHouse", "bldg_maison_safrania_02"],
	["porte_boutique", &"saffron_mart", "PokeMart", "bldg_boutique_01"],
	["porte_sylphe", &"silph_co_1f", "SilphCo", "bldg_sylphe_safrania_01"],
	["porte_centre", &"saffron_center", "PokemonCenter", "bldg_centre_01"],
	["porte_psy", &"saffron_psychic_house", "PsychicHouse", "bldg_maison_safrania_03"],
]

var _map: GameMap
var _grid: GridWorld
var _plan: PlanGrid


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


func _load_map(map_id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _warp_cells() -> Dictionary:
	var cells: Dictionary = {}
	for cell: Vector2i in _plan.cells_of("D"):
		cells[cell] = true
	return cells


func test_metadata_light_and_zone() -> void:
	assert_eq(_map.map_id, &"saffron_city")
	assert_eq(_map.display_name, "Safrania")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var lighting := LightingLibrary.new()
	lighting.load_file()
	assert_eq(lighting.get_map_profile(&"saffron_city"), &"golden_hour")
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_eq(zones.zone_of(&"saffron_city"), &"saffron_city")
	assert_true(zones.is_playable(&"saffron_city"), "zone jouable : les postes s'ouvrent")
	for map_id: StringName in [&"saffron_center", &"saffron_mart", &"saffron_psychic_house",
			&"saffron_pidgey_house", &"saffron_copycat_house_1f", &"saffron_copycat_house_2f"]:
		assert_eq(zones.zone_of(map_id), &"saffron_city", String(map_id))
		assert_true(MapCatalog.has_map(map_id), String(map_id))
	# Fusion T6 + T7 : la ville, ses six intérieurs, puis les 12 cartes de la Sylphe.
	var maps: Array[StringName] = zones.get_zone(&"saffron_city").maps
	# J27 (T6) : l'Arène et le Dojo à la fin.
	assert_eq(maps.size(), 21, "7 cartes du T6 + 12 de la Sylphe + Arène et Dojo (J27)")
	assert_eq(maps[0], &"saffron_city", "Safrania en tête (zone jouable)")
	assert_eq(maps.slice(19), [&"saffron_gym", &"fighting_dojo"] as Array[StringName], "J27")
	for map_id: StringName in maps.slice(7, 19):
		assert_true(String(map_id).begins_with("silph_co"), String(map_id))
	for layer: Node in _map.find_children("*", "TileMapLayer", true, false):
		assert_false((layer as TileMapLayer).visible, "%s invisible" % layer.name)


func test_scene_grid_is_the_functional_grid() -> void:
	var mismatches := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			var solid := not _plan.is_walkable(cell)
			if _grid.is_solid(cell) != solid or _grid.is_tall_grass(cell) or _grid.is_water(cell):
				mismatches += 1
				if mismatches <= 10:
					fail_test("case %s « %s » : solide %s" % [cell, _plan.at(cell),
						_grid.is_solid(cell)])
	assert_eq(mismatches, 0, "grille de la scène = tools/plans/safrania.txt")
	assert_eq(_plan.walkable, WALKABLE)


func test_every_planned_door_has_its_warp_and_arrival() -> void:
	var count := 0
	for id: String in _plan.positions:
		var position: Dictionary = _plan.positions[id]
		if position["kind"] == "spawn":
			assert_eq(_map.get_spawn_cell(StringName(id)), (position["cells"] as Array)[0], id)
		if position["kind"] != "warp":
			continue
		var direction: Vector2i = DIRS[_plan.attr(id, "dir")]
		for cell: Vector2i in position["cells"]:
			count += 1
			assert_false(_grid.is_solid(cell), "%s %s franchissable" % [id, cell])
			var warp := _map.get_warps().find_on_step(cell, direction)
			assert_not_null(warp, "%s %s (STEP_ON)" % [id, cell])
			if warp == null:
				continue
			var target := StringName(_plan.attr(id, "to"))
			if warp.is_coming_soon():
				assert_false(MapCatalog.has_map(target) and _plan.attr(id, "a_venir") != "oui",
					"%s : « à venir » alors que %s existe" % [id, target])
				var back := _map.get_spawn_cell(warp.target_spawn)
				assert_true(Grid.is_cardinal(back + direction - cell) or back + direction == cell,
					"%s : retour devant la porte (%s)" % [id, back])
				assert_false(_grid.is_solid(back), "%s : retour praticable" % id)
				assert_eq(warp.facing, -direction, "%s : dos à la porte" % id)
			else:
				assert_eq([warp.target_map, warp.target_spawn],
					[target, StringName(_plan.attr(id, "spawn"))], id)
	assert_eq(count, _plan.cells_of("D").size(), "toutes les portes de la grille")
	assert_eq(_map.get_warps().size(), count, "rien d'autre que les portes de la grille")
	for entry: Array in BUILDINGS:
		var building := _map.get_node_or_null(NodePath("Entities/" + entry[2])) as WorldProp
		assert_not_null(building, entry[2])
		if building != null:
			assert_eq(building.scene_file_path.get_file().get_basename(), entry[3])


## J27 (T6) : les deux portes mènent à leurs cartes ; aucune ne porte de drapeau (l'Arène n'est
## fermée que par le sbire `unless silph_giovanni_defeated`, le Dojo jamais).
func test_gym_and_dojo_open_to_their_maps_and_the_dojo_never_needs_a_flag() -> void:
	for entry: Array in [["porte_dojo", &"fighting_dojo"], ["porte_arene", &"saffron_gym"]]:
		for cell: Vector2i in _plan.cells_at(entry[0]):
			var warp := _map.get_warps().find_on_step(cell, Vector2i.UP)
			assert_not_null(warp, entry[0])
			if warp != null:
				assert_false(warp.is_coming_soon(), "%s : ouverte (J27)" % entry[0])
				assert_eq([warp.target_map, warp.target_spawn], [entry[1], &"entrance"], entry[0])
				assert_true(warp.unless_flags.is_empty(), "%s : aucun drapeau" % entry[0])
	assert_eq(_map.find_children("*", "FlagGate", true, false).size(), 0,
		"aucun décor conditionnel dans la ville (T6)")
	var dojo_front := _plan.cells_at("from_dojo")
	var open := GridPaths.distances(GridPaths.relief(_grid, SIZE),
		[_map.get_spawn_cell(&"from_gate_r8")], _warp_cells())
	for cell: Vector2i in dojo_front:
		assert_true(open.has(cell), "devant le Dojo %s atteignable sans drapeau" % cell)
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] != "pnj":
			continue
		for cell: Vector2i in _plan.cells_at(id):
			assert_false(dojo_front.has(cell) or _plan.cells_at("porte_dojo").has(cell),
				"%s ne se tient pas devant le Dojo" % id)
	var silph := _map.get_warps().find_on_step(_plan.cells_at("porte_sylphe")[0], Vector2i.UP)
	assert_not_null(silph)
	if silph != null and not MapCatalog.has_map(&"silph_co_1f"):
		assert_eq(silph.coming_soon, "Sylphe SARL", "Sylphe « À venir » jusqu'au T7")


func test_the_whole_town_is_reachable_from_each_gate() -> void:
	var relief := GridPaths.relief(_grid, SIZE)
	for gate: Array in GATES:
		var reach := GridPaths.distances(relief, [_map.get_spawn_cell(gate[1])], _warp_cells())
		var missing := 0
		for cell: Vector2i in _plan.cells_of(WALKABLE):
			if not reach.has(cell):
				missing += 1
		assert_eq(missing, 0, "%s : toute la ville atteignable (sans PNJ, T6)" % gate[1])


func test_the_four_gates_link_to_the_town_both_ways() -> void:
	for gate: Array in GATES:
		var cells := _plan.cells_at(gate[0])
		var direction: Vector2i = DIRS[_plan.attr(gate[0], "dir")]
		var other := _load_map(gate[2])
		# Ville → poste.
		for cell: Vector2i in cells:
			var out := _map.get_warps().find_on_step(cell, direction)
			assert_not_null(out, "%s %s" % [gate[0], cell])
			if out == null:
				continue
			assert_eq([out.target_map, out.target_spawn], [gate[2], gate[3]], gate[0])
			assert_eq(out.facing, Vector2i.DOWN, "%s : dos à la porte de Safrania" % gate[0])
		assert_eq(other.get_spawn_cell(gate[3]), gate[4], "%s/%s" % [gate[2], gate[3]])
		assert_false(other.get_grid().is_solid(gate[4]), "%s : arrivée praticable" % gate[2])
		# Poste → ville : un pas vers le haut depuis l'arrivée, sur la porte de Safrania.
		var back := other.get_warps().find_on_step(gate[6], Vector2i.UP)
		assert_not_null(back, "%s : porte vers Safrania" % gate[2])
		if back == null:
			continue
		assert_false(back.is_coming_soon(), "%s : Safrania n'est plus « à venir »" % gate[2])
		assert_eq([back.target_map, back.target_spawn], [&"saffron_city", gate[1]], gate[2])
		assert_eq(back.facing, gate[5], "%s : orientation à l'arrivée en ville" % gate[2])
		assert_eq(gate[4] + Vector2i.UP, gate[6], "%s : un pas de la porte" % gate[2])
		var arrival := _map.get_spawn_cell(gate[1])
		assert_true(cells.has(arrival + direction), "%s : la porte est à un pas" % gate[1])


func test_the_gates_stay_guarded_until_the_drink() -> void:
	# Postes du J20 et du J15 : le garde bloque l'accès à la porte de Safrania sans le drapeau.
	var flags := StoryFlags.new()
	var open := StoryFlags.new()
	open.set_flag(&"saffron_gates_open")
	var guards := {&"route_5_gate": [&"route_5_guard", Vector2i(4, 2)],
		&"route_7_gate": [&"saffron_guard", Vector2i(4, 2)],
		&"route_8_gate": [&"saffron_guard", Vector2i(4, 2)],
		&"route_6": [&"saffron_guard", Vector2i(36, 8)]}
	for map_id: StringName in guards:
		var roster := NpcRoster.new()
		assert_true(roster.load_file("res://data/npcs/%s.json" % map_id), String(map_id))
		var spec := roster.get_spec(guards[map_id][0])
		assert_eq(spec.placed_for(flags).cell, guards[map_id][1], "%s : gardé" % map_id)
		assert_ne(spec.placed_for(open).cell, guards[map_id][1], "%s : ouvert" % map_id)


func test_playable_zone_makes_the_guard_ask_for_a_drink() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	var guard := dialogues.get_dialogue(&"saffron_gate_guard")
	var variant := guard.pick(StoryFlags.new(), null, 0, Callable(),
		func(id: StringName) -> bool: return id == &"fresh_water",
		func(zone: StringName) -> bool: return zones.is_playable(zone))
	assert_not_null(variant.choice, "boisson demandée (216, 217)")
	if variant.choice != null:
		assert_eq(variant.choice.confirm_cutscene, &"saffron_gate_drink_water")


func test_a_save_on_each_arrival_resumes_on_the_same_cell() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var save := SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	var places: Array = []
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] == "spawn":
			for cell: Vector2i in _plan.cells_at(id):
				places.append([&"saffron_city", _map, cell])
	for gate: Array in GATES:
		places.append([gate[2], _load_map(gate[2]), gate[4]])
	for place: Array in places:
		var cell: Vector2i = place[2]
		var state: Node = autofree(GameStateScript.new())
		state.clock = FixedClock.new("2026-10-22T10:00:00")
		state.new_game(7)
		state.set_player_location(place[0], cell, Vector2i.DOWN)
		assert_eq(save.write(state.to_dict()), OK, "sauvegarde en %s" % cell)
		var loaded: Node = autofree(GameStateScript.new())
		assert_true(loaded.load_dict(save.read(), data), "rechargée en %s" % cell)
		assert_eq([loaded.current_map, loaded.player_cell], [place[0], cell])
		var map: GameMap = place[1]
		assert_false(map.get_grid().is_solid(cell), "%s %s praticable" % [place[0], cell])
		var resumed := map.find_standing_cell(cell)
		if place[0] == &"saffron_city":
			if map.get_grid().is_occupied(cell):
				# T9 : un sbire de l'occupation se tient sur certaines cases d'arrivée (devant la
				# maison du Copieur, du Roucool, l'Arène) : la reprise se fait à un pas.
				assert_true(Grid.is_cardinal(resumed - cell), "%s : reprise à un pas" % cell)
			else:
				assert_eq(resumed, cell, "%s : reprise sur la case" % cell)
		else:
			# Arrivée dans un poste = case du garde quand les postes sont fermés (il s'écarte
			# avec `saffron_gates_open`) : la reprise ne se fait jamais sur la case de départ d'un
			# PNJ (`GameMap.find_standing_cell`), elle se fait à un pas, sur une case praticable.
			assert_true(Grid.is_cardinal(resumed - cell), "%s %s : reprise à un pas (%s)"
				% [place[0], cell, resumed])
			assert_false(map.get_grid().is_solid(resumed))


func test_fly_arrives_in_front_of_the_center() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/world/fly_points.json"))
	var found := false
	for point: Dictionary in doc["points"]:
		if point["zone"] == "saffron_city":
			found = true
			assert_eq([point["map"], point["spawn"]], ["saffron_city", "from_center"])
	assert_true(found)
	assert_eq(_map.get_spawn_cell(&"from_center"), _plan.cell_of("vol_safrania"))
	assert_eq(_map.get_spawn_cell(&"from_center") + Vector2i.UP, _plan.cells_at("porte_centre")[0])


func test_signs_read_their_texts_from_the_planned_side() -> void:
	var found: Dictionary = {}
	for point: Node in _map.get_node(^"Interactables").get_children():
		found[(point as InteractPoint).dialogue_id] = point
	for row: Array in [[&"saffron_city_sign", "panneau_ville"],
			[&"saffron_gym_sign", "panneau_arene"]]:
		var point := found.get(row[0]) as InteractPoint
		assert_not_null(point, String(row[0]))
		if point != null:
			assert_eq([point.get_cell(), point.facing], [_plan.cell_of(row[1]), Vector2i.UP])
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_eq(dialogues.get_dialogue(&"saffron_city_sign").variants[0].pages[0].text,
		"SAFRANIA\nVille dorée, cœur commercial de Kanto.", "T26-22")
	assert_eq(dialogues.get_dialogue(&"saffron_gym_sign").variants[0].pages[0].text,
		"ARÈNE DE SAFRANIA\nChampion : Morgane")


func test_npc_cells_are_walkable_and_held_by_the_occupation_npcs() -> void:
	# T9 : les PNJ de la grille sont posés ; en nouvelle partie (occupation) seuls ceux sans
	# condition `if` sont là, les autres (libération) attendent le drapeau.
	var count := 0
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] != "pnj":
			continue
		for cell: Vector2i in _plan.cells_at(id):
			count += 1
			assert_false(_grid.is_solid(cell), "%s %s praticable" % [id, cell])
			if _plan.attr(id, "if").is_empty():
				assert_true(_grid.is_occupied(cell), "%s %s : tenue par son PNJ" % [id, cell])
	assert_gt(count, 10)


func test_props_never_block_a_walkable_cell() -> void:
	for layer: NodePath in [^"Entities", ^"GroundDecals"]:
		for child: Node in _map.get_node(layer).get_children():
			var prop := child as WorldProp
			if prop == null:
				continue
			for cell: Vector2i in prop.get_solid_cells():
				assert_false(_plan.is_walkable(cell), "%s bloque la case praticable %s"
					% [prop.name, cell])


func test_node_budget() -> void:
	var count := GridPaths.count_nodes(_map)
	gut.p("saffron_city : %d nœuds" % count)
	assert_lte(count, NODE_BUDGET)


func test_center_and_mart_work_like_the_others() -> void:
	var center := _load_map(&"saffron_center")
	assert_true(center.interior)
	assert_eq(center.display_name, "Safrania")
	var found: Dictionary = {}
	for point: Node in center.get_node(^"Interactables").get_children():
		found[(point as InteractPoint).dialogue_id] = true
	assert_true(found.has(&"nurse") and found.has(&"storage_terminal"), "infirmière et Stockage")
	var points := RestPointLibrary.new()
	assert_true(points.load_file())
	var rest := points.get_point(&"saffron_center")
	assert_not_null(rest, "point de repos")
	if rest != null:
		assert_true(center.has_spawn(rest.spawn))
	var mart := _load_map(&"saffron_mart")
	var clerk := false
	for point: Node in mart.get_node(^"Interactables").get_children():
		clerk = clerk or (point as InteractPoint).dialogue_id == &"clerk"
	assert_true(clerk, "marchand")
	var shops := ShopLibrary.new()
	assert_true(shops.load_dir())
	var shop := shops.get_shop(&"saffron_mart")
	assert_not_null(shop)
	if shop != null:
		# RB : Super Ball, Hyper Potion, Max Repousse, Corde Sortie, Total Soin, Rappel ; seuls
		# ceux qui existent [D].
		assert_eq(shop.item_ids(), [&"great_ball", &"escape_rope", &"revive"] as Array[StringName])


func test_interiors_lead_back_to_their_door() -> void:
	for row: Array in [[&"saffron_center", &"from_center"], [&"saffron_mart", &"from_mart"],
			[&"saffron_psychic_house", &"from_psychic_house"],
			[&"saffron_pidgey_house", &"from_pidgey_house"],
			[&"saffron_copycat_house_1f", &"from_copycat_house"]]:
		var room := _load_map(row[0])
		assert_eq(room.get_spawn_cell(&"entrance"), Vector2i(7, 8), String(row[0]))
		for x: int in range(6, 9):
			var exit := room.get_warps().find_on_push(Vector2i(x, 8), Vector2i.DOWN)
			assert_not_null(exit, "%s : sortie (%d, 8)" % [row[0], x])
			if exit != null:
				assert_eq([exit.target_map, exit.target_spawn], [&"saffron_city", row[1]])
	var ground := _load_map(&"saffron_copycat_house_1f")
	var upstairs := _load_map(&"saffron_copycat_house_2f")
	for x: int in [12, 13]:
		var up := ground.get_warps().find_on_step(Vector2i(x, 2), Vector2i.UP)
		var down := upstairs.get_warps().find_on_step(Vector2i(x, 2), Vector2i.UP)
		assert_not_null(up)
		assert_not_null(down)
		if up != null and down != null:
			assert_eq([up.target_map, up.target_spawn], [&"saffron_copycat_house_2f", &"from_1f"])
			assert_eq([down.target_map, down.target_spawn],
				[&"saffron_copycat_house_1f", &"from_2f"])
	assert_eq(upstairs.get_warps().size(), 2, "l'étage n'a que l'escalier")
