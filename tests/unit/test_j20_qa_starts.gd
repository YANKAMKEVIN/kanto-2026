extends GutTest
## Départs de débogage de la vie du 20-I (jalon 20 T17, jalon-20.md §2.14) : fichiers valides,
## cartes et points d'apparition réels (case d'arrivée praticable), équipe « arrivée J19 » (Nv. 20
## à 28), drapeaux de la progression (aucun de ceux que la carte pose elle-même), Centre de
## Céladopole enregistré pour les départs en ville. T21 : Casino, repaire (B1F à B4F, Clé, ascenseur),
## Giovanni (et sa version pour perdre), Tour avec le Scope (Clé et Scope au Sac).

const TOOL_STARTS := "res://tools/debug_start/"
## Départ → [carte, point d'apparition, orientation, drapeaux absents, drapeaux présents].
const STARTS := {
	"route_8": [&"route_8", &"from_lavender_c", Vector2i.LEFT,
		[&"route_8_reached", &"celadon_reached"], [&"lavender_reached", &"badge_thunder"]],
	"route_8_west": [&"route_8", &"west_square", Vector2i.RIGHT,
		[&"celadon_reached"], [&"route_8_reached"]],
	"underground_7_8": [&"underground_path_7_8", &"from_route_7_n", Vector2i.RIGHT,
		[&"celadon_reached", &"got_souterrain_hidden_1"], [&"route_8_reached"]],
	"route_7": [&"route_7", &"from_underground", Vector2i.DOWN,
		[&"celadon_reached"], [&"route_8_reached"]],
	"celadon": [&"celadon_city", &"from_route_7_c", Vector2i.LEFT,
		[&"celadon_reached", &"got_celadon_hidden_1"], [&"route_8_reached"]],
	"celadon_dept": [&"celadon_dept_gf", &"entrance", Vector2i.UP,
		[&"rooftop_tm13"], [&"celadon_reached"]],
	"celadon_dept_tm01": [&"celadon_dept_2f", &"from_down", Vector2i.DOWN,
		[&"rooftop_tm13"], [&"celadon_reached"]],
	"celadon_eevee_full": [&"celadon_mansion_roof_house", &"entrance", Vector2i.UP,
		[&"eevee_received"], [&"celadon_reached"]],
	"celadon_gym_outside": [&"celadon_city", &"gym_front", Vector2i.LEFT,
		[&"cut_celadon_gym_bush", &"erika_met"], [&"celadon_reached", &"badge_cascade"]],
	"celadon_gym": [&"celadon_gym", &"entrance", Vector2i.UP,
		[&"erika_met", &"badge_rainbow"], [&"cut_celadon_gym_bush", &"cut_celadon_gym_inner_bush"]],
	"erika_weak": [&"celadon_gym", &"entrance", Vector2i.UP,
		[&"erika_met", &"badge_rainbow"], [&"cut_celadon_gym_bush", &"cut_celadon_gym_inner_bush"]],
	# T21 : vie du 20-II (Casino, repaire, Giovanni, Tour avec le Scope).
	"game_corner": [&"celadon_game_corner", &"entrance", Vector2i.UP,
		[&"game_corner_switch", &"beaten_celadon_game_corner_rocket"], [&"celadon_reached"]],
	"rocket_hideout_b1f": [&"rocket_hideout_b1f", &"from_casino", Vector2i.DOWN,
		[&"beaten_rocket_hideout_b1f_1"], [&"game_corner_switch"]],
	"rocket_hideout_b2f": [&"rocket_hideout_b2f", &"from_b1f_north", Vector2i.DOWN,
		[&"beaten_rocket_hideout_b2f_1"], [&"beaten_rocket_hideout_b1f_3"]],
	"rocket_hideout_b3f": [&"rocket_hideout_b3f", &"from_b2f", Vector2i.DOWN,
		[&"beaten_rocket_hideout_b3f_1"], [&"beaten_rocket_hideout_b2f_1"]],
	"rocket_hideout_key": [&"rocket_hideout_b4f", &"from_b3f", Vector2i.DOWN,
		[&"rocket_dropped_lift_key"], [&"beaten_rocket_hideout_b4f_key"]],
	"rocket_hideout_lift": [&"rocket_hideout_b1f", &"from_elevator", Vector2i.DOWN,
		[&"beaten_rocket_hideout_b4f_guard_1"], [&"got_rocket_hideout_b4f_lift_key"]],
	"giovanni": [&"rocket_hideout_b4f", &"from_elevator", Vector2i.UP,
		[&"giovanni_met", &"giovanni_hideout_won"], [&"rocket_hideout_b4f_door_open"]],
	"giovanni_weak": [&"rocket_hideout_b4f", &"from_elevator", Vector2i.UP,
		[&"giovanni_met", &"giovanni_hideout_won"], [&"rocket_hideout_b4f_door_open"]],
	"tower_scope": [&"pokemon_tower_3f", &"arrivee_T23", Vector2i.RIGHT,
		[], [&"got_rocket_hideout_b4f_silph_scope", &"tower_ghost_met"]],
}

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func test_starts_are_valid_and_land_on_real_spawns() -> void:
	for name: String in STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		var expected: Array = STARTS[name]
		assert_eq([start.map, start.spawn, start.facing], expected.slice(0, 3), name)
		assert_true(MapCatalog.has_map(start.map), "%s : carte" % name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition %s" % [name, start.spawn])
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)
		for flag: StringName in expected[3]:
			assert_false(start.flags.has(flag), "%s : %s pas encore posé" % [name, flag])
		for flag: StringName in expected[4]:
			assert_true(start.flags.has(flag), "%s : %s posé" % [name, flag])


func test_reference_team_badges_and_the_cut_kit() -> void:
	for name: String in STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items), name)
		if name in ["erika_weak", "giovanni_weak"]:
			assert_eq(start.party.size(), 1, "un Salamèche N5 seul, pour perdre")
			assert_eq(int(start.party[0]["level"]), 5)
			continue
		var levels: Array[int] = []
		for member: Dictionary in start.party:
			levels.append(int(member["level"]))
			assert_between(int(member["level"]), 20, 28, "%s : %s" % [name, member["species"]])
		assert_gte(levels.size(), 4, "%s : équipe de référence" % name)
		for flag: StringName in [&"badge_boulder", &"badge_cascade", &"badge_thunder",
				&"got_hm01"]:
			assert_true(start.flags.has(flag), "%s : %s" % [name, flag])
		assert_true(start.bag.has(&"hm01"), "%s : CS01 au Sac" % name)
	var full := DebugStart.new()
	assert_true(full.load_file(TOOL_STARTS + "celadon_eevee_full.json", _data, _items))
	assert_eq(full.party.size(), 6, "équipe de six : Évoli part au Stockage")


func test_town_starts_register_the_celadon_center_and_the_dept_start_carries_the_drinks() -> void:
	for name: String in ["celadon_dept", "celadon_dept_tm01", "celadon_eevee_full",
			"celadon_gym_outside", "celadon_gym", "erika_weak", "game_corner",
			"rocket_hideout_b1f", "rocket_hideout_b2f", "rocket_hideout_b3f",
			"rocket_hideout_key", "rocket_hideout_lift", "giovanni", "giovanni_weak"]:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items), name)
		assert_eq(start.rest_point, &"celadon_center", name)
	var dept := DebugStart.new()
	assert_true(dept.load_file(TOOL_STARTS + "celadon_dept.json", _data, _items))
	assert_eq(dept.money, 5000)
	assert_eq(int(dept.bag[&"fresh_water"]), 1)
	assert_eq(int(dept.bag[&"soda_pop"]), 1)
	var tm := DebugStart.new()
	assert_true(tm.load_file(TOOL_STARTS + "celadon_dept_tm01.json", _data, _items))
	assert_eq(int(tm.bag[&"tm01"]), 1, "CT01 déjà au Sac")
	var weak := DebugStart.new()
	assert_true(weak.load_file(TOOL_STARTS + "erika_weak.json", _data, _items))
	for flag: StringName in [&"beaten_celadon_gym_lass_lila", &"beaten_celadon_gym_lass_capucine",
			&"beaten_celadon_gym_beauty_violette", &"beaten_celadon_gym_jr_trainer_apolline",
			&"beaten_celadon_gym_cooltrainer_camelia"]:
		assert_true(weak.flags.has(flag), "Dresseuse déjà battue : %s" % flag)


func test_t21_starts_carry_the_key_and_the_scope_where_needed() -> void:
	var expected := {"rocket_hideout_lift": [1, 0], "giovanni": [1, 0], "giovanni_weak": [1, 0],
		"tower_scope": [1, 1], "rocket_hideout_key": [0, 0], "game_corner": [0, 0]}
	for name: String in expected:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items), name)
		assert_eq([int(start.bag.get(&"lift_key", 0)), int(start.bag.get(&"silph_scope", 0))],
			expected[name], "%s : Clé, Scope" % name)
