extends GutTest
## Sauvegarde du jalon 12 (T25 ; `jalon-12.md` §2.20) : **aucune version nouvelle**. Une partie
## construite au B2F du Mont Sélénite (R1, R2, R3 battus, une défaite contre le chercheur, Pierre
## Lune cachée trouvée, CT01, Grodoudou évolué par une Pierre Lune) traverse
## `to_dict` → fichier JSON → `load_dict` sans rien perdre ; puis le choix du fossile (objet clé,
## drapeaux, Grand moment `fossil`) aussi.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_j12.json"
const FLAGS: Array[StringName] = [
	&"badge_boulder", &"route_3_entered", &"beaten_mt_moon_rocket_1",
	&"beaten_mt_moon_rocket_2", &"beaten_mt_moon_rocket_3", &"lost_mt_moon_rocket_1",
	&"lost_mt_moon_researcher", &"got_mt_moon_b1f_item_1", &"got_mt_moon_b2f_hidden_1",
	&"got_mt_moon_b2f_item_1",
]

var _fs: MemoryFs
var _save: SaveSystem
var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func before_each() -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, PATH)


func _state() -> Node:
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-14T10:00:00")
	state.new_game(12)
	return state


func _round_trip(state: Node) -> Node:
	assert_eq(_save.write(state.to_dict()), OK, "écrite")
	var read := _save.read()
	assert_eq(_save.last_status, OK, "relue")
	assert_eq(int(read["version"]), SaveSystem.VERSION)
	var loaded := _state()
	assert_true(loaded.load_dict(read, _data), "chargée sans entrée écartée")
	return loaded


func test_the_j12_writes_no_new_save_version() -> void:
	# v6 au J11 ; le J12 n'en ajoute pas (§2.20) ; v7 vient du J15 (Pension), intégré après.
	assert_eq(SaveSystem.VERSION, 9, "aucune version du J12 : v6 du J11, v7 du J15, v8 du J23, v9 JR")


func test_a_game_in_the_b2f_before_the_researcher_survives_a_reload() -> void:
	var state := _state()
	for flag: StringName in FLAGS:
		state.flags.set_flag(flag)
	var wigglytuff := PokemonFactory.create(_data, &"wigglytuff", 17, state.rng)
	state.party.add(PokemonFactory.create(_data, &"charmeleon", 19, state.rng))
	state.party.add(wigglytuff)
	state.bag.add(&"moon_stone", 1)
	state.bag.add(&"tm01", 1)
	state.bag.add(&"escape_rope", 2)
	state.record_item_found(&"moon_stone", &"mt_moon_b1f")
	state.record_item_found(&"moon_stone", &"mt_moon_b2f")
	state.set_player_location(&"mt_moon_b2f", Vector2i(26, 26), Vector2i.DOWN)
	var loaded := _round_trip(state)
	for flag: StringName in FLAGS:
		assert_true(loaded.flags.has_flag(flag), String(flag))
	assert_false(loaded.flags.has_flag(&"beaten_mt_moon_researcher"))
	assert_eq(loaded.bag.count_of(&"moon_stone"), 1, "une Pierre Lune (l'autre utilisée)")
	assert_eq(loaded.bag.count_of(&"tm01"), 1)
	assert_eq(loaded.bag.count_of(&"escape_rope"), 2)
	assert_eq(loaded.found_items.size(), 2, "journal des objets trouvés")
	assert_eq(loaded.party.size(), 2)
	assert_eq(loaded.party.get_at(1).species_id, &"wigglytuff", "Grodoudou gardé")
	assert_eq(loaded.current_map, &"mt_moon_b2f")
	assert_eq(loaded.player_cell, Vector2i(26, 26))
	assert_eq(loaded.player_facing, Vector2i.DOWN)


func test_the_fossil_choice_and_its_great_moment_survive_a_reload() -> void:
	var state := _state()
	state.party.add(PokemonFactory.create(_data, &"charmeleon", 19, state.rng))
	for flag: StringName in [&"beaten_mt_moon_researcher", &"mt_moon_fossil_chosen",
			&"mt_moon_got_helix_fossil"]:
		state.flags.set_flag(flag)
	state.bag.add(&"helix_fossil", 1)
	state.record_moment(&"fossil", &"mt_moon_b2f", {"item": "helix_fossil"})
	var loaded := _round_trip(state)
	assert_true(loaded.flags.has_flag(&"mt_moon_fossil_chosen"))
	assert_true(loaded.flags.has_flag(&"mt_moon_got_helix_fossil"))
	assert_eq(loaded.bag.count_of(&"helix_fossil"), 1, "objet clé")
	assert_eq(loaded.bag.count_of(&"dome_fossil"), 0, "jamais l'autre")
	var moments: Array[Dictionary] = []
	for moment: Dictionary in loaded.moments:
		if moment.get("type", "") == "fossil":
			moments.append(moment)
	assert_eq(moments.size(), 1, "Grand moment unique")
	if moments.size() == 1:
		assert_eq(moments[0]["details"], {"item": "helix_fossil"})
		assert_eq(moments[0]["map"], "mt_moon_b2f")
