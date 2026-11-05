extends GutTest
## StoneAwakening (JOHP0, `jalon-joh-pierres.md` §2.4 ; dossier JOH-11 §13) : la cible, qui se
## réveille, la chaîne d'évolutions, le lien, le moment, PV et PP, Pokédex, Stockage, et l'étape
## de scène « stones_awaken » (ordre : bloc, cinématique, écriture, écran).

const STATE_SCRIPT := preload("res://game/autoload/game_state.gd")
const TIMEOUT := 4.0

var _data: PokemonData
var _zones: ZoneLibrary
var _state: Node


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	assert_true(_zones.load_file("res://data/world/zones.json"), str(_zones.get_errors()))


func before_each() -> void:
	_state = STATE_SCRIPT.new()
	autofree(_state)
	_state.new_game(5)


func after_each() -> void:
	Evolution.set_current_period(&"")


func _make(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(level))


func _add(species: StringName, level: int) -> Pokemon:
	var mon := _make(species, level)
	_state.party.add(mon)
	return mon


func _store(species: StringName, level: int, map: StringName) -> Pokemon:
	var mon := _make(species, level)
	mon.met_map = map
	_state.storage.add(mon)
	return mon


func _kanto(levels: Array[int]) -> ConfiscatedTeam:
	var team := ConfiscatedTeam.new()
	for level: int in levels:
		team.party.append(_make(&"pidgey", level))
	return team


# --- La cible --------------------------------------------------------------------------------

func test_target_is_the_rounded_mean_of_the_three_highest() -> void:
	assert_eq(StoneAwakening.target_level(_kanto([60, 58, 57, 40, 30, 12])), 58)
	assert_eq(StoneAwakening.target_level(_kanto([59, 58, 58])), 58, "58,33 arrondi")
	assert_eq(StoneAwakening.target_level(_kanto([59, 59, 58])), 59, "58,67 arrondi")


func test_two_weak_pokemon_do_not_lower_the_target() -> void:
	assert_eq(StoneAwakening.target_level(_kanto([12, 60, 9, 60, 60, 11])), 60)


func test_fewer_than_three_are_averaged_as_they_are() -> void:
	assert_eq(StoneAwakening.target_level(_kanto([60, 57])), 59, "58,5 arrondi vers le haut")
	assert_eq(StoneAwakening.target_level(_kanto([58])), 58)


func test_target_is_bound_to_55_62() -> void:
	assert_eq(StoneAwakening.target_level(_kanto([30, 28, 20])), StoneAwakening.LEVEL_MIN)
	assert_eq(StoneAwakening.target_level(_kanto([100, 90, 80])), StoneAwakening.LEVEL_MAX)
	assert_eq(StoneAwakening.target_level(ConfiscatedTeam.new()), StoneAwakening.LEVEL_MIN)
	assert_eq(StoneAwakening.target_level(null), StoneAwakening.LEVEL_MIN)


func test_an_egg_does_not_count_for_the_target() -> void:
	var team := _kanto([60, 60])
	var egg := _make(&"pidgey", 90)
	egg.egg_steps = 100
	team.party.append(egg)
	assert_eq(StoneAwakening.target_level(team), 60)


# --- Qui ---------------------------------------------------------------------------------------

func test_eligible_takes_the_team_then_johto_captures_of_the_storage() -> void:
	_state.confiscated = _kanto([60, 60, 60])
	var low := _add(&"rattata", 40)
	_add(&"pidgey", 60)
	var above := _add(&"pidgeot", 61)
	var egg := _add(&"pidgey", 5)
	egg.egg_steps = 100
	var johto := _store(&"rattata", 30, &"route_40")
	_store(&"rattata", 30, &"route_1")
	_store(&"rattata", 30, &"")
	_store(&"rattata", 60, &"route_40")
	var found := StoneAwakening.eligible(_state, _zones)
	assert_eq(found, [low, johto] as Array[Pokemon])
	assert_eq(above.level, 61)


func test_nobody_is_ever_lowered() -> void:
	var high := _make(&"pidgeot", 62)
	var levels := high.level
	assert_null(StoneAwakening.apply(high, 58, _data))
	assert_null(StoneAwakening.apply(high, 62, _data), "à la cible : rien")
	assert_eq(high.level, levels)


func test_an_egg_is_left_alone() -> void:
	var egg := _make(&"pidgey", 5)
	egg.egg_steps = 100
	assert_null(StoneAwakening.apply(egg, 58, _data))
	assert_eq(egg.level, 5)


# --- L'effet -----------------------------------------------------------------------------------

func test_the_whole_chain_plays_in_one_go() -> void:
	var mon := _make(&"caterpie", 6)
	var result := StoneAwakening.apply(mon, 58, _data)
	assert_eq(mon.species_id, &"butterfree")
	assert_eq(mon.level, 58)
	assert_eq(result.species_before, &"caterpie")
	assert_eq(result.chain, [&"metapod", &"butterfree"] as Array[StringName])
	assert_eq(result.stage_levels, [7, 10] as Array[int])
	assert_eq(result.level_before, 6)
	assert_eq(result.level_after, 58)
	assert_eq(result.species_after(), &"butterfree")


func test_an_overdue_evolution_stops_the_counter_just_above_the_old_level() -> void:
	var mon := _make(&"caterpie", 20)
	var result := StoneAwakening.apply(mon, 58, _data)
	assert_eq(result.stage_levels, [21, 22] as Array[int], "le compteur monte toujours")


func test_experience_is_the_minimum_of_the_level_and_stats_follow() -> void:
	var mon := _make(&"rattata", 30)
	var hp: int = mon.max_hp()
	StoneAwakening.apply(mon, 58, _data)
	var species := _data.get_species(mon.species_id)
	assert_eq(mon.experience, ExpCurve.exp_for_level(species.growth_rate, 58))
	assert_gt(mon.max_hp(), hp)


func test_hp_pp_and_status_are_restored_even_when_fainted() -> void:
	var mon := _make(&"rattata", 30)
	mon.hp = 0
	mon.status = &"poison"
	mon.moves[0].pp = 0
	StoneAwakening.apply(mon, 58, _data)
	assert_eq(mon.hp, mon.max_hp())
	assert_false(mon.is_fainted())
	assert_eq(mon.status, StatusRules.NONE)
	assert_eq(mon.moves[0].pp, mon.moves[0].max_pp)


func test_bond_is_unchanged_and_decides_togepi() -> void:
	var loved := _make(&"togepi", 20)
	loved.set_bond(70)
	var distant := _make(&"togepi", 20)
	distant.set_bond(40)
	assert_eq(StoneAwakening.apply(loved, 58, _data).chain, [&"togetic"] as Array[StringName])
	assert_eq(loved.bond, 70)
	assert_true(StoneAwakening.apply(distant, 58, _data).chain.is_empty())
	assert_eq(distant.species_id, &"togepi")
	assert_eq(distant.level, 58)
	assert_eq(distant.bond, 40)


func test_eevee_follows_the_moment() -> void:
	var day := _make(&"eevee", 20)
	day.set_bond(80)
	Evolution.set_current_period(&"day")
	StoneAwakening.apply(day, 58, _data)
	assert_eq(day.species_id, &"espeon")
	var night := _make(&"eevee", 20)
	night.set_bond(80)
	Evolution.set_current_period(&"night")
	StoneAwakening.apply(night, 58, _data)
	assert_eq(night.species_id, &"umbreon")
	var kanto := _make(&"eevee", 20)
	kanto.set_bond(80)
	Evolution.set_current_period(&"")
	StoneAwakening.apply(kanto, 58, _data)
	assert_eq(kanto.species_id, &"eevee", "sans heure, pas d'évolution par moment")


func test_new_moves_are_the_three_most_recent_and_nothing_is_learned() -> void:
	var mon := _make(&"bulbasaur", 20)
	var before: Array[StringName] = []
	for slot: MoveSlot in mon.moves:
		before.append(slot.move_id)
	var result := StoneAwakening.apply(mon, 58, _data)
	assert_eq(result.new_moves.size(), StoneAwakening.OFFERED_MOVES)
	var after: Array[StringName] = []
	for slot: MoveSlot in mon.moves:
		after.append(slot.move_id)
	assert_eq(after, before, "rien n'est imposé")
	assert_eq(result.species_after(), &"venusaur")
	assert_eq(result.new_moves[2], &"sleep_powder", "la plus récente en dernier (niv. ≤ 58)")
	for move_id: StringName in result.new_moves:
		assert_false(mon.knows_move(move_id), "déjà connue : %s" % move_id)


func test_new_moves_stay_within_the_levels_crossed() -> void:
	var mon := _make(&"rattata", 56)
	var result := StoneAwakening.apply(mon, 58, _data)
	assert_true(result.new_moves.is_empty(), str(result.new_moves))


func test_a_stored_capture_gets_the_last_four_moves_with_full_pp() -> void:
	var mon := _make(&"caterpie", 6)
	var result := StoneAwakening.apply_stored(mon, 58, _data)
	assert_true(result.stored)
	assert_true(result.new_moves.is_empty(), "pas de choix")
	var expected := _data.get_species(&"butterfree").moves_at(58)
	var known: Array[StringName] = []
	for slot: MoveSlot in mon.moves:
		known.append(slot.move_id)
		assert_eq(slot.pp, slot.max_pp)
	assert_eq(known, expected)


# --- L'opération entière ----------------------------------------------------------------------

func _arc_state() -> void:
	_state.confiscated = _kanto([60, 58, 58, 20])
	_add(&"caterpie", 6)
	_add(&"rattata", 40)
	_add(&"pidgeot", 59)
	_store(&"pidgey", 30, &"route_40")
	_store(&"pidgey", 30, &"route_1")
	for stone: StringName in StoneAwakening.STONES:
		_state.bag.add(stone, 1)
	_state.bag.add(&"potion", 2)


func test_awaken_changes_everything_in_one_block() -> void:
	_arc_state()
	var report := StoneAwakening.awaken(_state, _zones, _data)
	assert_eq(report.target, 59)
	assert_eq(report.party.size(), 2, "le Roucarnage est déjà à la cible")
	assert_eq(report.stored.size(), 1)
	assert_eq(report.line_up.size(), 3, "le plan large montre toute l'équipe")
	assert_true(_state.flags.has_flag(StoneAwakening.AWAKENED))
	for stone: StringName in StoneAwakening.STONES:
		assert_false(_state.bag.has(stone), "pierre retirée : %s" % stone)
	assert_eq(_state.bag.count_of(&"potion"), 2)
	assert_eq(_state.storage.get_at(1).level, 30, "capture de Kanto au Stockage : rien")
	assert_eq(_state.storage.get_at(0).level, 59)


func test_the_pokedex_marks_each_species_of_the_chain_caught() -> void:
	_arc_state()
	_state.pokedex.mark_seen(&"caterpie")
	StoneAwakening.awaken(_state, _zones, _data)
	assert_true(_state.pokedex.is_caught(&"metapod"))
	assert_true(_state.pokedex.is_caught(&"butterfree"))
	assert_true(_state.pokedex.is_caught(&"pidgeotto"), "capture du Stockage aussi")


func test_awaken_is_used_once() -> void:
	_arc_state()
	assert_not_null(StoneAwakening.awaken(_state, _zones, _data))
	var late := _add(&"rattata", 30)
	assert_null(StoneAwakening.awaken(_state, _zones, _data))
	assert_eq(late.level, 30, "les captures d'après ne sont pas concernées")


func test_a_team_with_nobody_under_the_target_has_no_scene() -> void:
	_state.confiscated = _kanto([55, 55, 55])
	_add(&"pidgeot", 60)
	_state.bag.add(&"stone_breath", 1)
	var report := StoneAwakening.awaken(_state, _zones, _data)
	assert_false(report.has_scene())
	assert_true(_state.flags.has_flag(StoneAwakening.AWAKENED))
	assert_false(_state.bag.has(&"stone_breath"))


# --- Les données -------------------------------------------------------------------------------

func test_the_line_is_p31_word_for_word() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_file("res://data/dialogues/johp0.json"), str(library.get_errors()))
	var dossier := FileAccess.get_file_as_string(
		"res://docs/design/dossier-joh-11-arc-pierres.md")
	var pages := library.get_dialogue(&"stones_awakening_line").variants[0].pages
	assert_eq(pages.size(), 2)
	assert_true(dossier.contains("| P-31 | Système, le réveil | %s / %s |"
		% [pages[0].text, pages[1].text]))


func test_the_data_of_the_step_load() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.load_file("res://data/cutscenes/johp0_awakening.json"),
		str(scenes.get_errors()))
	assert_true(scenes.get_set_flags().has(StoneAwakening.AWAKENED))


# --- L'étape de scène --------------------------------------------------------------------------

func _director(saves: Array[String]) -> CutsceneDirector:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict({"reveil": {"steps": [
		{"set": ["before"]}, {"stones_awaken": true}, {"set": ["after"]},
	]}}, "test"), str(scenes.get_errors()))
	var director := CutsceneDirector.new()
	add_child_autofree(director)
	director.setup(scenes, _state.flags, null, null, null)
	director.set_badges(null, _state)
	director.set_pokemon_data(_data)
	director.set_zones(_zones)
	director.save_handler = func(reason: String) -> Error:
		saves.append(reason)
		return OK
	return director


func test_the_library_reads_the_step_and_knows_its_flag() -> void:
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict({"a": {"steps": [{"stones_awaken": true}]}}, "ok"))
	assert_eq(scenes.get_cutscene(&"a").variants[0].steps[0].kind,
		CutsceneStep.Kind.STONES_AWAKEN)
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.STONES_AWAKEN), &"stones_awaken")
	assert_true(scenes.get_set_flags().has(StoneAwakening.AWAKENED))
	var bad := CutsceneLibrary.new()
	assert_false(bad.add_from_dict({"b": {"steps": [{"stones_awaken": false}]}}, "bad"))
	assert_push_error_count(1)


func test_the_write_comes_after_the_film_and_before_the_screen() -> void:
	_arc_state()
	var log: Array[String] = []
	var saves: Array[String] = []
	var director := _director(saves)
	director.awakening_handler = func(report: AwakeningReport) -> void:
		assert_true(_state.flags.has_flag(StoneAwakening.AWAKENED), "bloc déjà appliqué")
		assert_eq(report.party.size(), 2)
		log.append("film, écritures : %d" % saves.size())
	director.awakening_screen_handler = func(_report: AwakeningReport) -> bool:
		log.append("écran, écritures : %d" % saves.size())
		return false
	assert_true(director.play(&"reveil"))
	await wait_until(func() -> bool: return not director.is_running(), TIMEOUT)
	assert_eq(log, ["film, écritures : 0", "écran, écritures : 1"] as Array[String])
	assert_eq(saves, [CutsceneDirector.AWAKENING_SAVE_REASON] as Array[String],
		"une seule écriture sans attaque apprise")
	assert_true(_state.flags.has_flag(&"after"))


func test_a_learned_move_is_written_when_the_screen_closes() -> void:
	_arc_state()
	var saves: Array[String] = []
	var director := _director(saves)
	director.awakening_screen_handler = func(_report: AwakeningReport) -> bool:
		return true
	director.play(&"reveil")
	await wait_until(func() -> bool: return not director.is_running(), TIMEOUT)
	assert_eq(saves, [CutsceneDirector.AWAKENING_SAVE_REASON,
		CutsceneDirector.AWAKENING_MOVES_SAVE_REASON] as Array[String])


func test_the_step_is_skipped_once_done() -> void:
	_arc_state()
	StoneAwakening.awaken(_state, _zones, _data)
	var saves: Array[String] = []
	var director := _director(saves)
	var played := [false]
	director.awakening_handler = func(_report: AwakeningReport) -> void:
		played[0] = true
	director.play(&"reveil")
	await wait_until(func() -> bool: return not director.is_running(), TIMEOUT)
	assert_false(played[0], "on ne revoit pas le Réveil")
	assert_true(saves.is_empty())
	assert_true(_state.flags.has_flag(&"after"))


func test_no_film_and_no_screen_without_anyone_to_wake() -> void:
	_state.confiscated = _kanto([55, 55, 55])
	_add(&"pidgeot", 60)
	var saves: Array[String] = []
	var director := _director(saves)
	var played := [false]
	director.awakening_handler = func(_report: AwakeningReport) -> void:
		played[0] = true
	director.awakening_screen_handler = func(_report: AwakeningReport) -> bool:
		played[0] = true
		return false
	director.play(&"reveil")
	await wait_until(func() -> bool: return not director.is_running(), TIMEOUT)
	assert_false(played[0])
	assert_eq(saves.size(), 1, "le drapeau est quand même écrit")
