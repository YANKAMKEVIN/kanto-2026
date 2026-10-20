extends GutTest
## Départs de débogage de la vie du 20-I (jalon 20 T17, jalon-20.md §2.14) : fichiers valides,
## cartes et points d'apparition réels (case d'arrivée praticable), équipe « arrivée J19 » (Nv. 20
## à 28), drapeaux de la progression (aucun de ceux que la carte pose elle-même), Centre de
## Céladopole enregistré pour les départs en ville.

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
	"erika_win": [&"celadon_gym", &"entrance", Vector2i.UP,
		[&"erika_met", &"badge_rainbow"], [&"cut_celadon_gym_bush", &"cut_celadon_gym_inner_bush"]],
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
		if name == "erika_weak":
			assert_eq(start.party.size(), 1, "un Salamèche N5 seul, pour perdre")
			assert_eq(int(start.party[0]["level"]), 5)
			continue
		if name == "erika_win":
			assert_gte(int(start.party[0]["level"]), 36, "équipe forte, pour gagner (QA)")
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
			"celadon_gym_outside", "celadon_gym", "erika_weak", "erika_win"]:
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
