extends GutTest
## Départs de débogage de la Route 6 et de Carmin-sur-Mer (jalon 15 T14, jalon-15.md §2.12) :
## fichiers valides, cartes et points d'apparition réels (case d'arrivée praticable), équipe
## Nv. 18 à 22.

const TOOL_STARTS := "res://tools/debug_start/"
## Départ → [carte, point d'apparition, orientation].
const STARTS := {
	"route_6": [&"route_6", &"from_underground", Vector2i.DOWN],
	"vermilion": [&"vermilion_city", &"from_route_6_c", Vector2i.DOWN],
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
		assert_eq([start.map, start.spawn, start.facing], expected, name)
		assert_true(MapCatalog.has_map(start.map), "%s : carte" % name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition %s" % [name, start.spawn])
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)
		for member: Dictionary in start.party:
			assert_between(int(member["level"]), 18, 22, "%s : %s" % [name, member["species"]])
