extends GutTest
## Monture dans la sauvegarde v7 (passe systèmes 2, `systemes-2.md` §2.13) : « mount » et
## « last_land_cell » sont des champs facultatifs, écrits seulement s'ils disent quelque chose ;
## une sauvegarde d'avant la passe se relit à pied, sans rien changer.

const SCRIPT_PATH := "res://game/autoload/game_state.gd"

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _make() -> Node:
	return autofree((load(SCRIPT_PATH) as GDScript).new())


func test_a_new_game_is_on_foot() -> void:
	var state := _make()
	state.player_mount = Mount.Kind.BIKE
	state.new_game()
	assert_eq(state.player_mount, Mount.Kind.NONE)
	assert_eq(state.last_land_cell, Vector2i.ZERO)


func test_on_foot_and_on_land_the_file_has_no_new_field() -> void:
	var state := _make()
	state.set_player_location(&"route_1", Vector2i(4, 9), Vector2i.UP)
	var saved: Dictionary = state.to_dict()
	assert_false(saved.has("mount"), "à pied : fichier d'avant la passe")
	assert_false(saved.has("last_land_cell"), "à terre : = cell")


func test_on_the_bike_the_mount_is_saved_and_read_back() -> void:
	var state := _make()
	state.set_player_location(&"route_1", Vector2i(4, 9), Vector2i.UP)
	state.player_mount = Mount.Kind.BIKE
	var saved: Dictionary = state.to_dict()
	assert_eq(saved.get("mount"), "bike")
	var loaded := _make()
	assert_true(loaded.load_dict(JSON.parse_string(JSON.stringify(saved)), _data))
	assert_eq(loaded.player_mount, Mount.Kind.BIKE)
	assert_eq(loaded.last_land_cell, Vector2i(4, 9))


func test_surfing_keeps_the_last_land_cell_apart() -> void:
	var state := _make()
	state.set_player_location(&"route_19", Vector2i(10, 4), Vector2i.DOWN)
	state.player_mount = Mount.Kind.SURF
	state.set_player_location(&"route_19", Vector2i(10, 12), Vector2i.DOWN)
	assert_eq(state.last_land_cell, Vector2i(10, 4), "en mer, la case à terre ne suit pas")
	var saved: Dictionary = state.to_dict()
	assert_eq(saved.get("mount"), "surf")
	assert_eq(saved.get("last_land_cell"), [10, 4])
	var loaded := _make()
	loaded.load_dict(JSON.parse_string(JSON.stringify(saved)), _data)
	assert_eq(loaded.player_mount, Mount.Kind.SURF)
	assert_eq(loaded.last_land_cell, Vector2i(10, 4))
	assert_eq(loaded.player_cell, Vector2i(10, 12))


func test_an_old_save_is_read_on_foot_with_the_land_cell_on_the_player() -> void:
	var state := _make()
	state.set_player_location(&"route_1", Vector2i(4, 9), Vector2i.UP)
	var saved: Dictionary = state.to_dict()
	var loaded := _make()
	loaded.player_mount = Mount.Kind.BIKE
	loaded.load_dict(saved, _data)
	assert_eq(loaded.player_mount, Mount.Kind.NONE)
	assert_eq(loaded.last_land_cell, Vector2i(4, 9))


func test_an_unknown_mount_is_read_on_foot() -> void:
	var state := _make()
	var saved: Dictionary = state.to_dict()
	saved["mount"] = "dragon"
	var loaded := _make()
	loaded.load_dict(saved, _data)
	assert_eq(loaded.player_mount, Mount.Kind.NONE)
