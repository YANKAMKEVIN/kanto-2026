extends GutTest
## Jalon 22 (§2.13) : aucun changement de format (v7) ; drapeaux du J22 et monture en Vélo
## gardés par un aller-retour de sauvegarde ; une sauvegarde sans drapeau du J22 se recharge.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const SAVE_PATH := "user://test_save_j22.json"
const FLAGS: Array[StringName] = [&"got_bike_voucher", &"got_bicycle", &"got_old_rod",
	&"got_good_rod", &"got_super_rod", &"cycling_gate_16_greeted", &"cycling_gate_18_greeted",
	&"beaten_route_13_biker", &"got_route_17_hidden_1"]

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func _round_trip(state: Node) -> Node:
	var save := SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	assert_eq(save.write(state.to_dict()), OK)
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(save.read(), _data))
	return loaded


func _new_state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-21T10:00:00")
	state.new_game(7)
	return state


func test_the_jalon_22_adds_no_save_version() -> void:
	assert_eq(SaveSystem.VERSION, 7)


func test_riding_on_route_13_and_j22_flags_survive_a_reload() -> void:
	var state := _new_state()
	state.set_player_location(&"route_13", Vector2i(80, 16), Vector2i.LEFT)
	state.player_mount = Mount.Kind.BIKE
	for flag: StringName in FLAGS:
		(state.flags as StoryFlags).set_flag(flag)
	(state.bag as Bag).add(&"bicycle")
	(state.bag as Bag).add(&"super_rod")
	var loaded := _round_trip(state)
	assert_eq(loaded.player_mount, Mount.Kind.BIKE, "en selle")
	assert_eq(loaded.current_map, &"route_13")
	for flag: StringName in FLAGS:
		assert_true((loaded.flags as StoryFlags).has_flag(flag), String(flag))
	assert_true((loaded.bag as Bag).has(&"bicycle"))
	assert_true((loaded.bag as Bag).has(&"super_rod"))


func test_a_voucher_save_keeps_the_voucher_for_the_exchange() -> void:
	var state := _new_state()
	(state.flags as StoryFlags).set_flag(&"got_bike_voucher")
	(state.bag as Bag).add(&"bike_voucher")
	var loaded := _round_trip(state)
	assert_true((loaded.bag as Bag).has(&"bike_voucher"))
	assert_false((loaded.bag as Bag).has(&"bicycle"))


func test_a_save_without_j22_flags_loads_unchanged() -> void:
	var state := _new_state()
	state.set_player_location(&"lavender_town", Vector2i(10, 10), Vector2i.DOWN)
	(state.flags as StoryFlags).set_flag(&"snorlax_route_12_done")
	var loaded := _round_trip(state)
	assert_eq(loaded.player_mount, Mount.Kind.NONE)
	for flag: StringName in FLAGS:
		assert_false((loaded.flags as StoryFlags).has_flag(flag), String(flag))


func test_route_17_mounts_a_walker_with_a_bicycle() -> void:
	# Donnée abîmée (monture perdue) sur la Piste : la carte remet en selle (MountRules).
	var map := (load("res://game/world/maps/route_17.tscn") as PackedScene).instantiate() \
		as GameMap
	var cell := Vector2i(13, 60)
	var kind := MountRules.on_map_entered(Mount.Kind.NONE, map.mount_traits_at(cell), cell,
		map.get_grid(), true)
	assert_eq(kind, Mount.Kind.BIKE)
	var none := MountRules.on_map_entered(Mount.Kind.NONE, map.mount_traits_at(cell), cell,
		map.get_grid(), false)
	assert_eq(none, Mount.Kind.NONE, "sans Bicyclette : à pied (le garde l'empêche d'arriver là)")
	map.free()
