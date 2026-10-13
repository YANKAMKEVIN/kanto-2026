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
