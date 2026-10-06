extends GutTest
## ExpSummary (bilan de fin de combat, demande n° 1) : résumé de la progression construit à
## partir des événements du journal — un participant, plusieurs, plusieurs niveaux d'un coup,
## plusieurs K.O. dans le même niveau, aucun gain (pas de bilan), K.O. sans XP absent ; puis
## les lignes ([method BattleViews.exp_summary]) et un vrai combat du moteur.

const K := BattleEvent.Kind

var _data: PokemonData
var _texts: BattleText


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_texts = BattleText.new()
	_texts.load_file()


func _exp(index: int, level: int, from: float, to: float, amount: int,
		points := Vector3i.ZERO, pokemon_name := "Salamèche") -> BattleEvent:
	var event := BattleEvent.new(K.EXP_GAINED, BattleEvent.SideId.PLAYER)
	event.party_index = index
	event.pokemon_name = pokemon_name
	event.species_id = &"charmander"
	event.level = level
	event.exp_from = from
	event.exp_to = to
	event.amount = amount
	event.exp_points_from = points.x
	event.exp_points_to = points.y
	event.exp_points_need = points.z
	return event


func _level(index: int, level: int, gains: Dictionary[StringName, int],
		need: int = 100) -> BattleEvent:
	var event := BattleEvent.new(K.LEVEL_UP, BattleEvent.SideId.PLAYER)
	event.party_index = index
	event.level = level
	event.stat_gains = gains
	event.exp_from = 0.0
	event.exp_points_from = 0
	event.exp_points_need = need
	return event


func _events(list: Array) -> Array[BattleEvent]:
	var result: Array[BattleEvent] = []
	result.assign(list)
	return result


func test_one_participant_without_level() -> void:
	var summary := ExpSummary.from_events(_events([
		_exp(0, 8, 0.2, 0.45, 11, Vector3i(20, 45, 100))]))
	assert_false(summary.is_empty())
	assert_false(summary.has_level_up())
	var entries := summary.get_entries()
	assert_eq(entries.size(), 1)
	var entry := entries[0]
	assert_eq([entry.party_index, entry.start_level, entry.end_level(), entry.exp_gained],
		[0, 8, 8, 11])
	assert_eq(entry.segments, [Vector2(0.2, 0.45)] as Array[Vector2])
	assert_eq(entry.points, [Vector3i(20, 45, 100)] as Array[Vector3i])
	assert_almost_eq(entry.end_fraction(), 0.45, 0.0001)


func test_several_participants_in_party_order() -> void:
	var summary := ExpSummary.from_events(_events([
		_exp(2, 6, 0.1, 0.3, 14, Vector3i.ZERO, "Rattata"),
		_exp(0, 8, 0.2, 0.4, 14),
		_exp(1, 7, 0.5, 0.7, 14, Vector3i.ZERO, "Roucool")]))
	var names: Array[String] = []
	for entry: ExpSummaryEntry in summary.get_entries():
		names.append(entry.pokemon_name)
	assert_eq(names, ["Salamèche", "Roucool", "Rattata"] as Array[String], "ordre de l'équipe")


func test_two_levels_at_once() -> void:
	var g9: Dictionary[StringName, int] = {&"hp": 2, &"atk": 1, &"def": 1, &"spa": 1,
		&"spd": 1, &"spe": 1}
	var g10: Dictionary[StringName, int] = {&"hp": 3, &"atk": 1, &"def": 0, &"spa": 2,
		&"spd": 1, &"spe": 1}
	var summary := ExpSummary.from_events(_events([
		_exp(0, 8, 0.6, 1.0, 120, Vector3i(60, 100, 100)),
		_level(0, 9, g9, 120),
		_exp(0, 9, 0.0, 1.0, 0, Vector3i(0, 120, 120)),
		_level(0, 10, g10, 140),
		_exp(0, 10, 0.0, 0.25, 0, Vector3i(0, 35, 140))]))
	var entry := summary.get_entry(0)
	assert_true(summary.has_level_up())
	assert_eq(entry.exp_gained, 120, "le total, porté par la première tranche")
	assert_eq([entry.start_level, entry.end_level(), entry.levels_gained()], [8, 10, 2])
	assert_eq(entry.segments, [Vector2(0.6, 1.0), Vector2(0.0, 1.0), Vector2(0.0, 0.25)]
		as Array[Vector2], "une tranche par niveau")
	assert_eq(entry.points, [Vector3i(60, 100, 100), Vector3i(0, 120, 120),
		Vector3i(0, 35, 140)] as Array[Vector3i], "les nombres repartent à zéro")
	assert_eq(entry.stat_gains(1)[&"hp"], 2, "gains du premier niveau")
	var total := entry.stat_gains()
	assert_eq([total[&"hp"], total[&"atk"], total[&"def"], total[&"spa"]], [5, 2, 1, 3],
		"gains cumulés")


func test_level_up_with_nothing_left_ends_at_zero_in_the_new_level() -> void:
	var gains: Dictionary[StringName, int] = {&"hp": 2}
	var summary := ExpSummary.from_events(_events([
		_exp(0, 8, 0.9, 1.0, 10, Vector3i(90, 100, 100)), _level(0, 9, gains, 120)]))
	var entry := summary.get_entry(0)
	assert_eq(entry.segments, [Vector2(0.9, 1.0), Vector2(0.0, 0.0)] as Array[Vector2])
	assert_eq(entry.points[-1], Vector3i(0, 0, 120))
	assert_almost_eq(entry.end_fraction(), 0.0, 0.0001)


func test_two_knockouts_in_the_same_level_extend_one_slice() -> void:
	var summary := ExpSummary.from_events(_events([
		_exp(0, 8, 0.1, 0.3, 20, Vector3i(10, 30, 100)),
		_exp(0, 8, 0.3, 0.55, 25, Vector3i(30, 55, 100))]))
	var entry := summary.get_entry(0)
	assert_eq(entry.exp_gained, 45)
	assert_eq(entry.segments, [Vector2(0.1, 0.55)] as Array[Vector2])
	assert_eq(entry.points, [Vector3i(10, 55, 100)] as Array[Vector3i])


func test_no_gain_no_summary() -> void:
	var fainted := BattleEvent.new(K.FAINTED, BattleEvent.SideId.FOE)
	var ended := BattleEvent.new(K.BATTLE_ENDED, BattleEvent.SideId.PLAYER)
	var summary := ExpSummary.from_events(_events([fainted, ended]))
	assert_true(summary.is_empty(), "rien gagné : pas de bilan")


func test_a_fainted_pokemon_without_exp_is_absent() -> void:
	var mine_fainted := BattleEvent.new(K.FAINTED, BattleEvent.SideId.PLAYER)
	mine_fainted.party_index = 0
	var summary := ExpSummary.from_events(_events([mine_fainted,
		_exp(1, 7, 0.2, 0.5, 30, Vector3i.ZERO, "Roucool")]))
	assert_eq(summary.get_entries().size(), 1)
	assert_null(summary.get_entry(0), "le K.O. sans XP n'est pas listé")
	assert_eq(summary.get_entry(1).pokemon_name, "Roucool")


func test_foe_events_are_ignored() -> void:
	var foe := _exp(0, 5, 0.0, 0.5, 10)
	foe.side = BattleEvent.SideId.FOE
	assert_true(ExpSummary.from_events(_events([foe])).is_empty())


func test_rows_carry_texts_and_cumulated_stat_gains() -> void:
	var g9: Dictionary[StringName, int] = {&"hp": 2, &"atk": 1, &"def": 1, &"spa": 1,
		&"spd": 1, &"spe": 1}
	var g10: Dictionary[StringName, int] = {&"hp": 2, &"atk": 1, &"def": 0, &"spa": 0,
		&"spd": 0, &"spe": 1}
	var summary := ExpSummary.from_events(_events([
		_exp(0, 8, 0.6, 1.0, 42, Vector3i(60, 100, 100)), _level(0, 9, g9),
		_exp(0, 9, 0.0, 1.0, 0, Vector3i(0, 100, 100)), _level(0, 10, g10),
		_exp(1, 7, 0.2, 0.4, 28, Vector3i(40, 80, 200), "Roucool")]))
	var rows := BattleViews.exp_summary(summary, _texts)
	assert_eq(rows.size(), 2)
	assert_true(rows[0].is_valid() and rows[1].is_valid())
	assert_eq([rows[0].display_name, rows[0].gain_text, rows[0].start_level_text],
		["Salamèche", "+42 XP", "Nv. 8"])
	assert_eq(Array(rows[0].level_texts), ["Nv. 9", "Nv. 10"])
	assert_eq(Array(rows[0].stat_texts), [
		"PV +2 · Attaque +1 · Défense +1 · Atq. Spé. +1 · Déf. Spé. +1 · Vitesse +1",
		"PV +4 · Attaque +2 · Défense +1 · Atq. Spé. +1 · Déf. Spé. +1 · Vitesse +2"],
		"gains cumulés, niveau après niveau")
	assert_eq(rows[1].levels_gained(), 0)
	assert_eq(Array(rows[1].stat_texts), [], "pas de gains sans montée de niveau")


## Un vrai combat du moteur : les événements donnent le même résumé que l'état du Pokémon.
func test_real_battle_summary_matches_the_pokemon() -> void:
	var party := Party.new()
	var lead := PokemonFactory.create(_data, &"charmander", 5, GameRng.new(1))
	party.add(lead)
	var foes := Party.new()
	foes.add(PokemonFactory.create(_data, &"rattata", 3, GameRng.new(2)))
	var rules := BattleRules.new()
	rules.gives_exp = true
	rules.exp_multiplier = 30.0
	var battle := Battle.new(BattleSide.new(party, true), BattleSide.new(foes, false, ""),
		_data, GameRng.new(3), rules)
	var start_level := lead.level
	var start_points := ExpCalc.level_span(lead, _data)
	var events := battle.start()
	var guard := 0
	while battle.get_state() == Battle.State.CHOOSING and guard < 30:
		events.append_array(battle.submit(BattleAction.move(0)))
		guard += 1
	assert_eq(battle.get_outcome(), Battle.Outcome.WIN)
	var entry := ExpSummary.from_events(events).get_entry(0)
	assert_not_null(entry)
	assert_eq(entry.start_level, start_level)
	assert_eq(entry.end_level(), lead.level)
	assert_gt(entry.levels_gained(), 1, "plusieurs niveaux d'un coup (multiplicateur forcé)")
	assert_eq(entry.segments.size(), entry.levels_gained() + 1)
	assert_eq(entry.points[0].x, start_points.x, "les nombres partent de l'XP du niveau")
	assert_eq(entry.points[-1].y, ExpCalc.level_span(lead, _data).x, "et finissent à la bonne")
	assert_almost_eq(entry.end_fraction(), ExpCalc.progress(lead, _data), 0.0001)
	var hp_gain := entry.stat_gains()[&"hp"]
	assert_gt(hp_gain, 0)
