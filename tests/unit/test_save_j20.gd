extends GutTest
## Sauvegarde du jalon 20 (`jalon-20.md` §2.13) : **aucune nouvelle version** (v7). T12 : le
## Pokémon donné garde son origine « gift » (valeur nouvelle d'un champ texte), son identifiant,
## sa place (équipe ou Stockage) ; une origine inconnue d'une build plus ancienne se relit en
## « unknown » (rien n'est perdu).
## T21 (complet) : drapeaux, objets clés (Clé, Scope), objets trouvés et Grand moment « giovanni »
## relus tels quels ; partie v7 du J15 relue et réécrite à l'identique ; Giovanni battu sans
## Scope ramassé → Poké Ball au sol après rechargement ; vraie Boot : sauvegarde écrite dans la
## cabine du repaire → étage courant ; aucune écriture pendant une glisse du B2F ; position
## sauvée sur une dalle du B2F → reprise sur sa case d'arrêt.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const PATH := "user://test/save_j20.json"
const FLAG := &"eevee_received"
const MAP := &"celadon_mansion_roof_house"
const FIXTURE_V6_S21 := "res://tests/fixtures/save/v6_kevin_s21.json"
const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const FrameSim := preload("res://tests/helpers/frame_sim.gd")
const BOOT_PATH := "user://test/save_j20_boot.json"
## Drapeaux du J20 posés par les données (T17, T21) : histoire, porte, Clé, Giovanni, Dresseurs
## et objets (échantillon de chaque famille).
const J20_FLAGS: Array[StringName] = [
	&"route_8_reached", &"celadon_reached", &"erika_met", &"badge_rainbow", &"tm21_received",
	&"eevee_received", &"rooftop_tm13", &"game_corner_switch", &"rocket_dropped_lift_key",
	&"rocket_hideout_b4f_door_open", &"giovanni_met", &"giovanni_hideout_won",
	&"got_rocket_hideout_b4f_lift_key", &"got_rocket_hideout_b4f_silph_scope",
	&"beaten_celadon_game_corner_rocket", &"beaten_rocket_hideout_b4f_guard_2",
	&"got_rocket_hideout_b2f_item_1", &"got_rocket_hideout_b3f_hidden_1",
	&"cut_celadon_gym_bush",
]
const J20_ITEMS: Dictionary[StringName, int] = {
	&"lift_key": 1, &"silph_scope": 1, &"fire_stone": 1, &"fresh_water": 2, &"revive": 3,
	&"poke_doll": 1, &"x_attack": 2, &"tm13": 1, &"tm21": 1, &"super_potion": 4,
}

var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "données Pokémon")


func test_version_stays_seven() -> void:
	assert_eq(SaveSystem.VERSION, 8, "le J20 n'ajoute aucune version (v8 : J23)")


func test_gift_origin_round_trip_in_the_party_and_the_storage() -> void:
	for party_size: int in [5, 6]:
		var state := _new_state()
		for i: int in party_size:
			state.party.add(PokemonFactory.create(_data, &"rattata", 10, state.rng))
		var result := PokemonGift.give(state, _data, &"eevee", 25, MAP, FLAG)
		assert_true(result.is_given(), "don (%d)" % party_size)
		var save := SaveSystem.new(MemoryFs.new(), PATH)
		assert_eq(save.write(state.to_dict()), OK)
		var raw := JSON.stringify(save.read())
		assert_string_contains(raw, "\"origin\":\"gift\"", "origine écrite en texte")
		var loaded: Node = autofree(GameStateScript.new())
		assert_true(loaded.load_dict(save.read(), _data))
		var holder: Variant = loaded.storage if result.is_stored() else loaded.party
		var back: Pokemon = holder.get_all().filter(
			func(p: Pokemon) -> bool: return p.species_id == &"eevee")[0]
		assert_eq(back.origin, Pokemon.Origin.GIFT, "origine relue (%d)" % party_size)
		assert_eq(back.uid, result.pokemon.uid, "identifiant gardé")
		assert_eq(back.met_map, MAP)
		assert_true((loaded.flags as StoryFlags).has_flag(FLAG))
		assert_true(loaded.pokedex.is_caught(&"eevee"))
		assert_eq(PokemonGift.give(loaded, _data, &"eevee", 25, MAP, FLAG).status,
			PokemonGift.Status.ALREADY_RECEIVED, "pas de second don après rechargement")
		state.free()


func test_unknown_origin_text_reads_as_unknown() -> void:
	var pokemon := PokemonFactory.create(_data, &"eevee", 25, GameRng.new(1))
	var dict := pokemon.to_dict()
	(dict["met"] as Dictionary)["origin"] = "swap" # J25 : « trade » est désormais connu
	var back := Pokemon.from_dict(dict, _data)
	assert_not_null(back)
	if back != null:
		assert_eq(back.origin, Pokemon.Origin.UNKNOWN, "valeur inconnue : « Rencontré à »")


func test_flags_key_items_found_items_and_the_giovanni_moment_survive_a_save() -> void:
	var state := _new_state()
	for flag: StringName in J20_FLAGS:
		state.flags.set_flag(flag)
	for item: StringName in J20_ITEMS:
		state.bag.add(item, J20_ITEMS[item])
	state.record_item_found(&"lift_key", &"rocket_hideout_b4f")
	state.record_item_found(&"silph_scope", &"rocket_hideout_b4f")
	state.record_moment(MomentLibrary.GIOVANNI, &"rocket_hideout_b4f")
	var save := SaveSystem.new(MemoryFs.new(), PATH)
	assert_eq(save.write(state.to_dict()), OK)
	var content := save.read()
	assert_eq(int(content["version"]), SaveSystem.VERSION)
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(content, _data), "chargée sans entrée écartée")
	for flag: StringName in J20_FLAGS:
		assert_true(loaded.flags.has_flag(flag), "%s relu" % flag)
	for item: StringName in J20_ITEMS:
		assert_eq(loaded.bag.count_of(item), J20_ITEMS[item], "%s relu" % item)
	assert_eq(loaded.found_items.map(func(e: Dictionary) -> String: return e["item"]),
		["lift_key", "silph_scope"], "objets trouvés")
	var moments: Array = loaded.moments.filter(func(m: Dictionary) -> bool:
		return str(m.get("type", "")) == "giovanni")
	assert_eq(moments.size(), 1, "Grand moment « giovanni »")
	if moments.size() == 1:
		assert_eq(str(moments[0]["map"]), "rocket_hideout_b4f")
	assert_eq(JSON.parse_string(JSON.stringify(loaded.to_dict())),
		JSON.parse_string(JSON.stringify(state.to_dict())), "réécrite à l'identique")
	state.free()


func test_a_v7_save_of_the_jalon_15_loads_and_rewrites_unchanged() -> void:
	var original: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V6_S21))
	assert_true(original is Dictionary, "fixture lisible")
	if not original is Dictionary:
		return
	var v7: Dictionary = (original as Dictionary).duplicate(true)
	v7["version"] = 7
	v7["daycare"] = {}
	var fs := MemoryFs.new()
	fs.files[PATH] = JSON.stringify(v7, "\t")
	var save := SaveSystem.new(fs, PATH)
	var content := save.read()
	assert_eq(save.last_status, OK, "acceptée")
	assert_eq(save.read_version, 7)
	var loaded := _new_state()
	assert_true(loaded.load_dict(content, _data), "chargée sans entrée écartée")
	assert_eq(save.write(loaded.to_dict()), OK)
	v7["version"] = SaveSystem.VERSION
	assert_eq(JSON.parse_string(fs.files[PATH]), JSON.parse_string(JSON.stringify(v7)),
		"réécrite à l'identique")
	for flag: StringName in J20_FLAGS:
		assert_false(loaded.flags.has_flag(flag), "%s absent d'une partie du J15" % flag)
	loaded.free()


func test_giovanni_beaten_without_the_scope_leaves_the_ball_after_a_reload() -> void:
	var state := _new_state()
	for flag: StringName in [&"giovanni_met", &"giovanni_hideout_won"]:
		state.flags.set_flag(flag)
	var save := SaveSystem.new(MemoryFs.new(), PATH)
	assert_eq(save.write(state.to_dict()), OK)
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(save.read(), _data))
	var present: Array = NpcRoster.load_for_map(&"rocket_hideout_b4f").get_present(
		loaded.flags).map(func(spec: NpcSpec) -> StringName: return spec.id)
	assert_has(present, &"rocket_hideout_b4f_silph_scope", "Poké Ball du Scope au sol")
	assert_does_not_have(present, &"giovanni", "Giovanni parti")
	state.free()


# --- Vraie Boot (repaire) --------------------------------------------------------------------

func test_a_save_written_in_the_hideout_cabin_is_the_current_floor() -> void:
	var play := HideoutPlay.new(self, BOOT_PATH)
	play.setup()
	await play.start("res://tools/debug_start/rocket_hideout_lift.json")
	await play.step(Vector2i.DOWN)
	assert_eq(play.map_id(), &"rocket_hideout_elevator", "dans la cabine")
	play.boot.request_autosave("test : cabine")
	await wait_until(func() -> bool: return _cell(play.saved()) == Vector2i(25, 18) \
		and not play.boot._save_coordinator.has_pending(), 10.0)
	var saved := play.saved()
	assert_eq(saved.get("map"), "rocket_hideout_b1f", "jamais la cabine")
	assert_eq(_cell(saved), Vector2i(25, 18), "case d'arrivée de l'étage courant")
	play.teardown()


func test_no_write_during_a_b2f_slide_and_a_save_on_an_arrow_resumes_on_its_stop() -> void:
	var play := HideoutPlay.new(self, BOOT_PATH)
	play.setup()
	await play.start("res://tools/debug_start/rocket_hideout_b2f.json")
	play.boot.get_map().spawn_player_at(play.player, Vector2i(3, 15), Vector2i.RIGHT)
	await wait_until(func() -> bool: return play.boot.is_stable() \
		and not play.boot._save_coordinator.has_pending(), 10.0)
	var spin := play.boot.get_spin_director()
	var writes := _writes(play.fs)
	var sim := FrameSim.new(get_tree(), [play.player])
	Input.action_press(&"move_right")
	await sim.frame()
	Input.action_release(&"move_right")
	await sim.run_until(func() -> bool: return spin.is_running() or not play.player.is_moving(),
		10.0)
	assert_true(spin.is_running(), "glisse partie depuis (4, 15)")
	play.boot.request_autosave("test : pendant la glisse")
	var during: Array[int] = []
	spin.slide_finished.connect(func(_cell: Vector2i) -> void: during.append(_writes(play.fs)))
	await sim.run_until(func() -> bool:
		return not spin.is_running() and not play.player.is_moving(), 10.0)
	sim.finish()
	assert_eq(during, [writes] as Array[int], "aucune écriture pendant la glisse")
	assert_eq(play.player.get_cell(), Vector2i(8, 11), "case d'arrêt de la dalle (4, 15)")
	await wait_until(func() -> bool: return _writes(play.fs) > writes, 10.0)
	assert_eq(_cell(play.saved()), Vector2i(8, 11), "sauvée sur la case d'arrêt")
	# Sauvegarde posée sur une dalle (fichier modifié) : reprise sur sa case d'arrêt.
	var edited := play.saved()
	edited["cell"] = [4, 15]
	play.fs.files[BOOT_PATH] = JSON.stringify(edited, "\t")
	await play.resume()
	assert_eq(play.map_id(), &"rocket_hideout_b2f")
	assert_eq(play.player.get_cell(), Vector2i(8, 11), "reprise sur la case d'arrêt")
	play.teardown()


func _cell(saved: Dictionary) -> Vector2i:
	var cell: Array = saved.get("cell", [-1, -1])
	return Vector2i(int(cell[0]), int(cell[1])) if cell.size() == 2 else Vector2i(-1, -1)


func _writes(fs: MemoryFs) -> int:
	return fs.journal.filter(func(line: String) -> bool: return line.begins_with("write")).size()


func _new_state() -> Node:
	var state: Node = GameStateScript.new()
	state.clock = FixedClock.new("2026-10-20T10:00:00")
	state.new_game(7)
	state.player_name = "Kevin"
	return state
