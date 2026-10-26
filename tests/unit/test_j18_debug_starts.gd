extends GutTest
## Départs de débogage de la vie de la Route 10 sud, de Lavanville et de la Tour (jalon 18 T24,
## jalon-18.md §4.16) : fichiers valides, cartes et points d'apparition réels (case d'arrivée
## praticable), équipe Nv. 19 à 24, drapeaux de la progression (aucun de ceux que la carte pose).

const TOOL_STARTS := "res://tools/debug_start/"
## Départ → [carte, point d'apparition, orientation, drapeaux absents, drapeaux présents].
const STARTS := {
	"route_10_south": [&"route_10", &"from_dark_cave_s_w", Vector2i.DOWN,
		[&"dark_cave_crossed", &"lavender_reached"], [&"route_10_reached"]],
	"lavender": [&"lavender_town", &"from_route_10", Vector2i.DOWN,
		[&"lavender_reached", &"tower_medium_talked"], [&"dark_cave_crossed"]],
	"pokemon_tower_1f": [&"pokemon_tower_1f", &"entrance", Vector2i.UP,
		[&"tower_medium_talked", &"tower_stairs_open"], [&"lavender_reached"]],
	# Registre des reportés (RP-003) : l'arrivée de l'échelle B du B1F, côté Marcel.
	"dark_cave_b1f_b": [&"dark_cave_b1f", &"arrivee_b", Vector2i.DOWN,
		[&"dark_cave_crossed"], []],
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
		for member: Dictionary in start.party:
			assert_between(int(member["level"]), 19, 24, "%s : %s" % [name, member["species"]])
