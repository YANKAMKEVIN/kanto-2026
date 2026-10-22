extends GutTest
## Jalon 23 (T11, `jalon-23.md` §2.1, §2.2, §2.15) : la visite en jeu ([SafariDirector]) — péage
## sans débit partiel, compteur de pas sur les cartes du Parc seulement, fin au pas suivant le
## zéro, fin par les Balls au retour d'une rencontre, sortie volontaire, visite close hors du Parc,
## renvoi à la Porte sans visite, drapeau miroir, réconciliation des CS.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

var _state: Node
var _director: SafariDirector
var _saves: Array[String] = []
var _ended: Array[StringName] = []


func before_each() -> void:
	_state = autofree(GameStateScript.new())
	_state.clock = FixedClock.new("2026-10-22T03:00:00")
	_state.new_game(23)
	_saves.clear()
	_ended.clear()
	_director = autofree(SafariDirector.new())
	var cutscenes: CutsceneDirector = autofree(CutsceneDirector.new())
	_director.setup(_state, SafariConfig.load_default(), null, null, cutscenes, null, null,
		func(reason: String) -> void: _saves.append(reason))
	_director.visit_ended.connect(func(reason: StringName) -> void: _ended.append(reason))


func _enter_map(id: StringName) -> void:
	var map: GameMap = autofree(GameMap.new())
	map.map_id = id
	_director.set_map(map)


func _pay(money: int) -> void:
	_state.money = money
	_director.handle(&"enter")


func test_toll_takes_500_and_starts_a_visit() -> void:
	_enter_map(&"safari_zone_gate")
	_pay(1200)
	assert_eq(_state.money, 700)
	assert_true(_state.safari.active)
	assert_eq([_state.safari.steps_left, _state.safari.balls_left], [500, 30])
	assert_true(_state.flags.has_flag(&"safari_active"), "drapeau miroir")
	assert_eq(_saves, ["péage du Parc Safari"] as Array[String], "autosave demandée")


func test_toll_refused_without_partial_debit() -> void:
	_enter_map(&"safari_zone_gate")
	_pay(499)
	assert_eq(_state.money, 499, "aucun débit")
	assert_false(_state.safari.active)
	assert_true(_state.flags.has_flag(&"safari_pay_failed"))
	_director.handle(&"clear")
	assert_false(_state.flags.has_flag(&"safari_pay_failed"), "drapeau de passage effacé")


func test_steps_count_only_in_the_park_and_the_step_after_zero_ends() -> void:
	_enter_map(&"safari_zone_gate")
	_pay(500)
	for i: int in 10:
		_director._on_player_moved(Vector2i.ZERO)
	assert_eq(_state.safari.steps_left, 500, "la Porte ne compte pas")
	_enter_map(&"safari_zone_center")
	for i: int in 500:
		_director._on_player_moved(Vector2i.ZERO)
	assert_true(_state.safari.active, "500 pas utilisables")
	assert_eq(_state.safari.steps_left, 0)
	assert_eq(_director.get_pending_end(), &"")
	_director._on_player_moved(Vector2i.ZERO)
	assert_false(_state.safari.active, "le 501e pas termine")
	assert_eq(_director.get_pending_end(), SafariVisit.TIME_UP)
	assert_false(_state.flags.has_flag(&"safari_active"))
	assert_eq(_ended, [SafariVisit.TIME_UP] as Array[StringName])


func test_steps_count_in_the_rest_houses_and_the_secret_house() -> void:
	_pay(500)
	for map: StringName in [&"safari_zone_rest_house_east", &"safari_zone_secret_house"]:
		_enter_map(map)
		var before: int = _state.safari.steps_left
		_director._on_player_moved(Vector2i.ZERO)
		assert_eq(_state.safari.steps_left, before - 1, "%s compte" % map)


func test_last_ball_ends_the_visit_on_return_from_the_encounter() -> void:
	_pay(500)
	_enter_map(&"safari_zone_west")
	_state.safari.balls_left = 1
	assert_eq(_state.safari.on_ball_thrown(), SafariVisit.OUT_OF_BALLS)
	_director._on_encounter_finished(Battle.Outcome.NONE)
	assert_eq(_director.get_pending_end(), SafariVisit.OUT_OF_BALLS)
	assert_false(_state.flags.has_flag(&"safari_active"))


func test_leaving_at_the_gate_ends_the_visit() -> void:
	_pay(500)
	_enter_map(&"safari_zone_gate")
	_director.handle(&"leave")
	assert_false(_state.safari.active)
	assert_false(_state.flags.has_flag(&"safari_active"))
	assert_eq(_ended, [SafariVisit.LEFT_EARLY] as Array[StringName])


func test_a_map_outside_the_park_closes_the_visit_without_refund() -> void:
	_pay(500)
	_enter_map(&"safari_zone_center")
	_enter_map(&"fuchsia_city")
	assert_false(_state.safari.active, "Corde Sortie, réveil… : visite close")
	assert_eq(_state.money, 0, "aucun remboursement")
	assert_eq(_ended, [SafariDirector.LEFT_PARK] as Array[StringName])


func test_loaded_in_the_park_without_a_visit_goes_back_to_the_gate() -> void:
	_enter_map(&"safari_zone_north")
	assert_eq(_director.get_pending_end(), SafariDirector.NO_VISIT)


func test_a_visit_reloaded_in_the_park_goes_on() -> void:
	_state.safari = SafariVisit.from_dict({"active": true, "steps_left": 42, "balls_left": 3})
	_enter_map(&"safari_zone_east")
	assert_eq(_director.get_pending_end(), &"")
	assert_true(_state.flags.has_flag(&"safari_active"), "drapeau resynchronisé")


func test_hm_reconciliation_both_ways() -> void:
	_state.flags.set_flag(&"got_hm03")
	_state.bag.add(&"hm04")
	_director.reconcile_key_items()
	assert_true(_state.bag.has(&"hm03"), "drapeau sans objet : objet rendu")
	assert_true(_state.flags.has_flag(&"got_hm04"), "objet sans drapeau : drapeau posé")
	_director.reconcile_key_items()
	assert_eq(_state.bag.count_of(&"hm03"), 1, "une seule fois")


func test_badge_signal_only_in_the_park_during_a_visit() -> void:
	var seen: Array = []
	_director.visit_changed.connect(func(shown: bool, steps: int, balls: int) -> void:
		seen.append([shown, steps, balls]))
	_enter_map(&"safari_zone_gate")
	_pay(500)
	_enter_map(&"safari_zone_center")
	assert_eq(seen.back(), [true, 500, 30])
	_director._on_player_moved(Vector2i.ZERO)
	assert_eq(seen.back(), [true, 499, 30])
	_enter_map(&"safari_zone_gate")
	assert_eq(seen.back(), [false, 499, 30], "masquée dans la Porte")


func test_gate_scenes_load_with_their_safari_steps() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), str(library.get_errors()))
	var actions: Array[String] = []
	for id: StringName in [&"j23_safari_gate_enter", &"j23_safari_gate_leave"]:
		assert_true(library.has_cutscene(id), id)
		for variant: CutsceneVariant in library.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.SAFARI:
					actions.append(step.text)
	assert_eq(actions, ["enter", "clear", "leave", "clear"] as Array[String])
	for id: StringName in SafariDirector.END_CUTSCENES.values():
		assert_true(library.has_cutscene(id), id)
