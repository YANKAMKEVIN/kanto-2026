extends GutTest
## Sauvegarde du jalon 13 (T19, jalon-13.md §2.9, §2.10 ; dossier 16 §17, §19) : **aucune nouvelle
## version** (tout tient dans `flags`, `bag`, `moments`) ; les drapeaux du rival n° 3, d'Ondine, du
## badge et de la CT11 survivent à l'écriture et à la relecture ; la partie « entre deux scènes »
## (rival vaincu, Ondine pas encore invitée) et la partie badgée sans CT se rechargent telles
## quelles ; le Grand moment du rival et celui du badge Cascade aussi.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_j13.json"
const J13_FLAGS: Array[StringName] = [
	&"rival_cerulean_lost_once", &"rival_cerulean_retried", &"rival_cerulean_won",
	&"misty_invited", &"misty_met", &"badge_cascade", &"tm11_received",
]

var _data: PokemonData
var _fs: MemoryFs
var _save: SaveSystem


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-13T10:00:00")
	state.new_game(13)
	state.party.add(PokemonFactory.create(_data, &"charmander", 22, GameRng.new(1)))
	return state


func _round_trip(state: Node) -> Node:
	assert_eq(_save.write(state.to_dict()), OK, "écriture")
	var content := _save.read()
	assert_eq(_save.last_status, OK, "relecture")
	assert_eq(int(content["version"]), SaveSystem.VERSION)
	var loaded := _state()
	assert_true(loaded.load_dict(content, _data), "chargé sans entrée écartée")
	return loaded


func test_the_jalon_13_adds_no_save_version() -> void:
	# Le J13 n'ajoute aucune version ; v7 vient du J15 (Pension), intégré après.
	assert_eq(SaveSystem.VERSION, 8, "aucune version du J13 : v6 du J11, v7 du J15, v8 du J23")


func test_every_flag_of_the_jalon_survives_a_save() -> void:
	var state := _state()
	for flag: StringName in J13_FLAGS:
		state.flags.set_flag(flag)
	var loaded := _round_trip(state)
	for flag: StringName in J13_FLAGS:
		assert_true(loaded.flags.has_flag(flag), "%s relu" % flag)


func test_the_game_saved_between_the_two_scenes_reloads_as_is() -> void:
	var state := _state()
	state.flags.set_flag(&"rival_cerulean_won")
	state.flags.set_flag(&"rival_cerulean_lost_once")
	state.flags.set_flag(&"rival_cerulean_retried")
	state.record_moment(GameState.MOMENT_RIVAL_BATTLE, &"route_24", {
		"trainer": "rival_cerulean", "outcome": "win"})
	var loaded := _round_trip(state)
	assert_true(loaded.flags.has_flag(&"rival_cerulean_won"))
	assert_false(loaded.flags.has_flag(&"misty_invited"), "Ondine pas encore invitée")
	assert_eq(loaded.moments.size(), 1, "un Grand moment du rival, pas deux")
	assert_eq((loaded.moments[0]["details"] as Dictionary).get("trainer"), "rival_cerulean")


func test_the_badge_the_moment_and_the_tm_survive() -> void:
	var state := _state()
	state.flags.set_flag(&"badge_cascade")
	state.flags.set_flag(&"tm11_received")
	state.bag.add(&"tm11", 1)
	state.record_moment(BadgeMoment.TYPE, &"cerulean_gym", BadgeMoment.details(&"cascade",
		state.party))
	var loaded := _round_trip(state)
	assert_eq(loaded.bag.count_of(&"tm11"), 1)
	assert_true(BadgeMoment.has_badge_moment(loaded.moments, &"cascade"))
	assert_false(BadgeMoment.has_badge_moment(loaded.moments, &"boulder"))


func test_a_badged_game_without_the_tm_keeps_that_state() -> void:
	var state := _state()
	state.flags.set_flag(&"badge_cascade")
	var loaded := _round_trip(state)
	assert_true(loaded.flags.has_flag(&"badge_cascade"))
	assert_false(loaded.flags.has_flag(&"tm11_received"), "rattrapage encore possible")
	assert_eq(loaded.bag.count_of(&"tm11"), 0)
