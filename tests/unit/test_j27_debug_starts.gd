extends GutTest
## Départs de débogage du jalon 27 (T11, `jalon-27.md` §2.6) : fichiers valides, cartes et points
## d'apparition réels ; Safrania libérée pour l'Arène, OCCUPÉE pour le Dojo ; maître battu et
## équipe pleine pour `dojo_choice`.

const TOOL_STARTS := "res://tools/debug_start/"
## Départ → [carte, point d'apparition, drapeaux présents, drapeaux absents, taille de l'équipe].
const STARTS := {
	"saffron_gym": [&"saffron_gym", &"entrance", [&"silph_giovanni_defeated"],
		[&"badge_marsh", &"sabrina_met"], 5],
	"sabrina": [&"saffron_gym", &"tp_19", [&"silph_giovanni_defeated"], [&"badge_marsh"], 5],
	"fighting_dojo": [&"fighting_dojo", &"entrance", [&"saffron_gates_open"],
		[&"silph_giovanni_defeated", &"fighting_dojo_master_defeated"], 4],
	"dojo_choice": [&"fighting_dojo", &"entrance", [&"fighting_dojo_master_defeated"],
		[&"dojo_got_hitmonlee", &"dojo_got_hitmonchan"], 6],
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
		assert_eq([start.map, start.spawn], expected.slice(0, 2), name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(map)
		assert_true(map.has_spawn(start.spawn), "%s : point d'apparition" % name)
		assert_false(map.get_grid().is_solid(map.get_spawn_cell(start.spawn)), name)
		for flag: StringName in expected[2]:
			assert_true(start.flags.has(flag), "%s : %s posé" % [name, flag])
		for flag: StringName in expected[3]:
			assert_false(start.flags.has(flag), "%s : %s absent" % [name, flag])
		assert_eq(start.party.size(), expected[4], "%s : équipe" % name)
