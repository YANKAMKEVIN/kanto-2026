extends GutTest
## Parc Safari, visite (J23, dossier 26 §4 et §11, plan `jalon-23.md` §2.1, T3) : SafariConfig,
## SafariVisit.

var _config: SafariConfig


func before_each() -> void:
	_config = SafariConfig.new()
	assert_true(_config.load_file(), "data/safari/safari.json se charge")


# --- Données ---------------------------------------------------------------------------------

func test_config_reads_the_red_blue_values() -> void:
	assert_eq(_config.fee, 500, "500 ₽ par entrée (RB)")
	assert_eq(_config.balls, 30, "30 Safari Balls (RB)")
	assert_eq(_config.steps, 500, "500 pas (RB, compte du joueur)")
	assert_eq(_config.ball_bonus, 2.0, "N-5 : multiplicateur de l'Ultra Ball")
	assert_eq(_config.end_map, &"safari_zone_gate")


func test_config_lists_the_four_zones_and_the_houses() -> void:
	for map: StringName in [&"safari_zone_center", &"safari_zone_east", &"safari_zone_north",
			&"safari_zone_west", &"safari_zone_rest_house_center", &"safari_zone_rest_house_east",
			&"safari_zone_rest_house_north", &"safari_zone_rest_house_west",
			&"safari_zone_secret_house"]:
		assert_true(_config.is_safari_map(map), "%s compte les pas" % map)
	assert_false(_config.is_safari_map(&"safari_zone_gate"), "la Porte ne compte pas les pas")
	assert_false(_config.is_safari_map(&"fuchsia_city"))


func test_config_refuses_an_unknown_or_missing_key() -> void:
	var config := SafariConfig.new()
	var good := {"fee": 500, "balls": 30, "steps": 500, "ball_bonus": 2.0,
		"maps": ["safari_zone_center"], "end_map": "safari_zone_gate", "end_spawn": "end"}
	var unknown := good.duplicate()
	unknown["bonus"] = 1
	assert_false(config.set_from_dict(unknown))
	var missing := good.duplicate()
	missing.erase("steps")
	assert_false(config.set_from_dict(missing))
	var negative := good.duplicate()
	negative["fee"] = 0
	assert_false(config.set_from_dict(negative))
	assert_true(config.set_from_dict(good))
	assert_push_error_count(3)


# --- Entrée ----------------------------------------------------------------------------------

func test_entry_is_refused_below_the_fee() -> void:
	assert_null(SafariVisit.start(499, _config), "499 ₽ : refus")
	assert_false(SafariVisit.can_pay(0, _config))


func test_entry_gives_steps_and_balls() -> void:
	var visit := SafariVisit.start(500, _config)
	assert_not_null(visit, "500 ₽ : entrée")
	assert_true(visit.active)
	assert_eq(visit.steps_left, 500)
	assert_eq(visit.balls_left, 30)


# --- Pas -------------------------------------------------------------------------------------

func test_five_hundred_steps_are_usable_and_the_next_one_ends_the_visit() -> void:
	var visit := SafariVisit.start(1000, _config)
	for i: int in 500:
		assert_eq(visit.on_step(), SafariVisit.NONE, "pas %d" % (i + 1))
	assert_eq(visit.steps_left, 0)
	assert_true(visit.active, "à 0, la visite continue jusqu'au pas suivant (RB, N-8)")
	assert_eq(visit.on_step(), SafariVisit.TIME_UP, "le 501e pas termine")
	assert_false(visit.active)
	assert_eq(visit.balls_left, 0, "les Balls restantes sont perdues")


func test_a_step_outside_a_visit_does_nothing() -> void:
	var visit := SafariVisit.new()
	assert_eq(visit.on_step(), SafariVisit.NONE)
	assert_eq(visit.steps_left, 0)


# --- Balls -----------------------------------------------------------------------------------

func test_the_last_ball_ends_the_visit() -> void:
	var visit := SafariVisit.start(500, _config)
	for i: int in 29:
		assert_eq(visit.on_ball_thrown(), SafariVisit.NONE)
	assert_eq(visit.balls_left, 1)
	assert_eq(visit.on_ball_thrown(), SafariVisit.OUT_OF_BALLS)
	assert_false(visit.active)
	assert_eq(visit.steps_left, 0)


func test_finish_loses_the_remaining_balls() -> void:
	var visit := SafariVisit.start(500, _config)
	visit.finish()
	assert_false(visit.active)
	assert_eq(visit.balls_left, 0)
	assert_eq(visit.on_ball_thrown(), SafariVisit.NONE, "plus rien après la fin")


# --- Sauvegarde ------------------------------------------------------------------------------

func test_round_trip() -> void:
	var visit := SafariVisit.start(500, _config)
	for i: int in 37:
		visit.on_step()
	visit.on_ball_thrown()
	var copy := SafariVisit.from_dict(JSON.parse_string(JSON.stringify(visit.to_dict())))
	assert_true(copy.active)
	assert_eq(copy.steps_left, 463)
	assert_eq(copy.balls_left, 29)


func test_invalid_content_gives_an_inactive_visit() -> void:
	assert_false(SafariVisit.from_dict({}).active, "champ absent (ancienne sauvegarde)")
	assert_false(SafariVisit.from_dict({"active": true, "steps_left": 10}).active, "Balls absentes")
	assert_false(SafariVisit.from_dict({"active": true, "steps_left": -1, "balls_left": 3}).active)
	assert_false(SafariVisit.from_dict({"active": true, "steps_left": 4, "balls_left": 0}).active)
	assert_false(SafariVisit.from_dict({"active": "oui", "steps_left": 4, "balls_left": 3}).active)
	var ended := SafariVisit.from_dict({"active": false, "steps_left": 40, "balls_left": 3})
	assert_eq(ended.steps_left, 0, "une visite close ne rend ni pas ni Balls")
