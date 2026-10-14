extends GutTest
## Départs de débogage du Cap d'Azuria (jalon 14 T14) : fichiers valides, cartes et points
## d'apparition réels (les cartes existent, case d'arrivée praticable), équipe Nv. 18 à 22, Badge
## Roche obtenu.

const TOOL_STARTS := "res://tools/debug_start/"
## Départ → [carte, point d'apparition, orientation].
const STARTS := {
	"route_25": [&"route_25", &"from_route_24_c", Vector2i.RIGHT],
	"route_25_cape": [&"route_25", &"from_bill_house_w", Vector2i.UP],
	"bill_house": [&"bill_house", &"from_route_25", Vector2i.UP],
	"bill_after": [&"bill_house", &"from_route_25", Vector2i.UP],
}

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func test_cape_starts_are_valid_and_land_on_real_spawns() -> void:
	for name: String in STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		var expected: Array = STARTS[name]
		assert_eq([start.map, start.spawn, start.facing], expected, name)
		assert_true(MapCatalog.has_map(start.map), "%s : carte" % name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition %s" % [name, start.spawn])
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)
		assert_true(start.flags.has(&"badge_boulder"), name)
		for member: Dictionary in start.party:
			assert_between(int(member["level"]), 18, 22, "%s : %s" % [name, member["species"]])


## T18b : `rare_candy_qa` (maison de Léo) donne les cinq cas du Super Bonbon.
func test_rare_candy_qa_start() -> void:
	var start := DebugStart.new()
	assert_true(start.load_file(TOOL_STARTS + "rare_candy_qa.json", _data, _items),
		"\n".join(start.get_errors()))
	assert_eq([start.map, start.spawn, start.facing],
		[&"bill_house", &"from_route_25", Vector2i.UP])
	var state: Node = autofree(load("res://game/autoload/game_state.gd").new())
	start.apply(state, _data)
	assert_eq(state.bag.count_of(&"rare_candy"), 5)
	var rows: Array = []
	for pokemon: Pokemon in state.party.get_all():
		rows.append([pokemon.species_id, pokemon.level, RareCandy.check(pokemon),
			pokemon.moves.size()])
	assert_eq(rows.slice(0, 4), [
		[&"abra", 15, RareCandy.Check.OK, 1],
		[&"butterfree", 20, RareCandy.Check.OK, 4],
		[&"pidgeot", 100, RareCandy.Check.MAX_LEVEL, 4],
		[&"rattata", 12, RareCandy.Check.FAINTED, 3],
	])
	var abra: Pokemon = state.party.get_at(0)
	RareCandy.apply(abra, _data)
	assert_eq(RareCandy.evolution_after(abra, _data), &"kadabra", "Abra 16 : évolution due")
	var butterfree: Pokemon = state.party.get_at(1)
	assert_eq(RareCandy.apply(butterfree, _data).moves, [&"supersonic"] as Array[StringName],
		"Papilusion 21 : Ultrason (oubli)")
