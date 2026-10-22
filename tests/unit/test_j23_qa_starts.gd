extends GutTest
## Départs de débogage du jalon 23 (`jalon-23.md` §2.16 ; retirés à la clôture, T24) : fichiers
## valides, cartes et arrivées réelles ; visite Safari en cours pour `safari_end_qa`.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const TOOL_STARTS := "res://tools/debug_start/"
const STARTS := {
	"safari_qa": [&"safari_zone_gate", &"entree"],
	"safari_end_qa": [&"safari_zone_east", &"arrivee_centre"],
	"warden_qa": [&"wardens_house", &"entree"],
}

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _start(name: String) -> DebugStart:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items),
		"%s : %s" % [name, "\n".join(start.get_errors())])
	return start


func test_starts_land_on_real_spawns() -> void:
	for name: String in STARTS:
		var start := _start(name)
		assert_eq([start.map, start.spawn], STARTS[name] as Array, name)
		assert_true(MapCatalog.has_map(start.map), "%s : carte" % name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(start.spawn), "%s : %s" % [name, start.spawn])
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)


func test_safari_end_qa_starts_a_short_visit() -> void:
	var state: Node = autofree(GameStateScript.new())
	_start("safari_end_qa").apply(state, _data)
	assert_true(state.safari.active)
	assert_eq([state.safari.steps_left, state.safari.balls_left], [3, 2])
	assert_true(state.flags.has_flag(&"safari_active"))


func test_safari_qa_has_money_and_a_full_team() -> void:
	var state: Node = autofree(GameStateScript.new())
	_start("safari_qa").apply(state, _data)
	assert_eq(state.money, 5000)
	assert_eq(state.party.size(), 6, "équipe pleine : la capture va au Stockage")
	assert_false(state.safari.active)


func test_warden_qa_carries_the_gold_teeth() -> void:
	var state: Node = autofree(GameStateScript.new())
	_start("warden_qa").apply(state, _data)
	assert_true(state.bag.has(&"gold_teeth"))
	assert_false(state.flags.has_flag(&"got_hm04"))
