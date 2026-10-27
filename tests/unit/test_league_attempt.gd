extends GutTest
## Tentative de Ligue (jalon 30 T5 ; `jalon-30.md` §2.2, §2.3, §2.5, §5) : machine à états pure
## sur des drapeaux. Défaite à chaque étape → retour à Olga ; victoire → étape suivante ; jamais
## d'étape sautée ; drapeaux temporaires jamais confondus avec le titre.


func _flags() -> StoryFlags:
	return StoryFlags.new()


func _cleared_up_to(flags: StoryFlags, last_stage: int) -> void:
	for stage: int in last_stage + 1:
		assert_true(LeagueAttempt.record_victory(flags, stage), "victoire %d" % stage)


func test_no_attempt_without_entering() -> void:
	var flags := _flags()
	assert_false(LeagueAttempt.is_active(flags))
	assert_eq(LeagueAttempt.current_stage(flags), LeagueAttempt.NO_STAGE)
	assert_eq(LeagueAttempt.resume_room(flags), &"")
	assert_false(LeagueAttempt.record_victory(flags, 0), "hors tentative, rien ne compte")
	assert_false(flags.has_flag(LeagueAttempt.stage_flag(0)))


func test_entering_starts_at_lorelei() -> void:
	var flags := _flags()
	assert_true(LeagueAttempt.start(flags))
	assert_true(flags.has_flag(&"league_attempt_active"))
	assert_eq(LeagueAttempt.current_stage(flags), 0)
	assert_eq(LeagueAttempt.resume_room(flags), &"league_lorelei")
	assert_true(LeagueAttempt.member_waiting(flags, 0))


func test_five_victories_in_order_reach_the_ceremony() -> void:
	var flags := _flags()
	LeagueAttempt.start(flags)
	var rooms: Array[StringName] = [&"league_lorelei", &"league_bruno", &"league_agatha",
		&"league_lance", &"league_champion"]
	for stage: int in 5:
		assert_eq(LeagueAttempt.current_stage(flags), stage)
		assert_eq(LeagueAttempt.resume_room(flags), rooms[stage])
		assert_true(LeagueAttempt.record_victory(flags, stage))
	assert_eq(LeagueAttempt.current_stage(flags), LeagueAttempt.STAGE_DONE)
	assert_eq(LeagueAttempt.resume_room(flags), &"league_champion", "cérémonie dans la salle")
	assert_false(LeagueAttempt.is_champion(flags), "pas de titre avant la cérémonie")


func test_a_stage_cannot_be_skipped_nor_won_twice() -> void:
	var flags := _flags()
	LeagueAttempt.start(flags)
	assert_false(LeagueAttempt.record_victory(flags, 1), "Aldo avant Olga")
	assert_false(LeagueAttempt.record_victory(flags, 4), "Champion avant Olga")
	assert_true(LeagueAttempt.record_victory(flags, 0))
	assert_false(LeagueAttempt.record_victory(flags, 0), "Olga deux fois")
	assert_false(LeagueAttempt.record_victory(flags, 5))
	assert_false(LeagueAttempt.record_victory(flags, -1))
	assert_eq(LeagueAttempt.current_stage(flags), 1)


func test_a_stray_later_flag_does_not_skip_a_battle() -> void:
	var flags := _flags()
	LeagueAttempt.start(flags)
	flags.set_flag(LeagueAttempt.stage_flag(2))  # fichier retouché
	assert_eq(LeagueAttempt.current_stage(flags), 0)
	assert_false(LeagueAttempt.north_door_open(flags, 2), "la porte d'Agatha reste fermée")
	assert_false(LeagueAttempt.north_door_open(flags, 0))


func test_defeat_at_every_stage_returns_to_lorelei() -> void:
	for lost_at: int in 5:
		var flags := _flags()
		LeagueAttempt.start(flags)
		if lost_at > 0:
			_cleared_up_to(flags, lost_at - 1)
		assert_true(LeagueAttempt.record_defeat(flags), "défaite à l'étape %d" % lost_at)
		assert_false(LeagueAttempt.is_active(flags))
		for flag: StringName in LeagueAttempt.temporary_flags():
			assert_false(flags.has_flag(flag), "%s effacé (étape %d)" % [flag, lost_at])
		assert_true(LeagueAttempt.start(flags))
		assert_eq(LeagueAttempt.current_stage(flags), 0, "nouvelle tentative depuis Olga")


func test_defeat_keeps_permanent_flags() -> void:
	var flags := _flags()
	flags.set_flag(LeagueAttempt.CHAMPION_DEFEATED)
	flags.set_flag(LeagueAttempt.CREDITS_SEEN)
	flags.set_flag(&"badge_earth")
	LeagueAttempt.start(flags)
	_cleared_up_to(flags, 2)
	LeagueAttempt.record_defeat(flags)
	assert_true(flags.has_flag(LeagueAttempt.CHAMPION_DEFEATED))
	assert_true(flags.has_flag(LeagueAttempt.CREDITS_SEEN))
	assert_true(flags.has_flag(&"badge_earth"))


func test_defeat_outside_an_attempt_reports_nothing() -> void:
	assert_false(LeagueAttempt.record_defeat(_flags()))


func test_reentering_during_an_attempt_does_not_reset_it() -> void:
	var flags := _flags()
	LeagueAttempt.start(flags)
	_cleared_up_to(flags, 1)
	assert_false(LeagueAttempt.start(flags), "reprise après chargement : rien ne repart")
	assert_eq(LeagueAttempt.current_stage(flags), 2)


func test_a_new_attempt_forgets_the_previous_victories() -> void:
	var flags := _flags()
	flags.set_flag(LeagueAttempt.stage_flag(0))  # reste d'une ancienne tentative
	flags.set_flag(LeagueAttempt.stage_flag(1))
	LeagueAttempt.start(flags)
	assert_eq(LeagueAttempt.current_stage(flags), 0, "vigilance A : Olga n'est pas acquise")


func test_ceremony_grants_the_title_once() -> void:
	var flags := _flags()
	LeagueAttempt.start(flags)
	assert_false(LeagueAttempt.complete(flags), "pas avant les cinq victoires")
	_cleared_up_to(flags, 4)
	assert_true(LeagueAttempt.complete(flags))
	assert_true(LeagueAttempt.is_champion(flags))
	assert_false(LeagueAttempt.is_active(flags))
	for flag: StringName in LeagueAttempt.temporary_flags():
		assert_false(flags.has_flag(flag), "%s effacé" % flag)
	assert_false(LeagueAttempt.complete(flags), "idempotente : une seule entrée au Panthéon")


func test_the_league_can_be_replayed_after_the_title() -> void:
	var flags := _flags()
	LeagueAttempt.start(flags)
	_cleared_up_to(flags, 4)
	LeagueAttempt.complete(flags)
	assert_true(LeagueAttempt.start(flags))
	assert_eq(LeagueAttempt.current_stage(flags), 0)
	_cleared_up_to(flags, 4)
	assert_true(LeagueAttempt.complete(flags), "deuxième victoire, deuxième cérémonie")


func test_doors() -> void:
	var flags := _flags()
	assert_true(LeagueAttempt.south_door_open(flags), "hors tentative : sortie libre")
	LeagueAttempt.start(flags)
	for stage: int in 5:
		assert_false(LeagueAttempt.south_door_open(flags, stage), "pas de retour (%d)" % stage)
		assert_false(LeagueAttempt.north_door_open(flags, stage), "fermée avant la victoire")
		LeagueAttempt.record_victory(flags, stage)
		assert_true(LeagueAttempt.north_door_open(flags, stage), "ouverte après (%d)" % stage)
	LeagueAttempt.record_defeat(flags)
	assert_false(LeagueAttempt.north_door_open(flags, 0), "défaite : tout se referme")
	assert_true(LeagueAttempt.south_door_open(flags))


func test_trainers_rooms_and_flags_map_to_stages() -> void:
	assert_eq(LeagueAttempt.stage_of_trainer(&"league_lorelei"), 0)
	assert_eq(LeagueAttempt.stage_of_trainer(&"rival_champion"), 4)
	assert_eq(LeagueAttempt.stage_of_trainer(&"rival_route22"), LeagueAttempt.NO_STAGE)
	assert_eq(LeagueAttempt.trainer_of_stage(3), &"league_lance")
	assert_eq(LeagueAttempt.trainer_of_stage(5), &"")
	assert_eq(LeagueAttempt.stage_of_room(&"league_agatha"), 2)
	assert_eq(LeagueAttempt.stage_of_room(&"indigo_plateau_lobby"), LeagueAttempt.NO_STAGE)
	assert_eq(LeagueAttempt.stage_flag(4), &"league_stage_4_cleared")
	assert_eq(LeagueAttempt.stage_flag(5), &"")
	assert_true(LeagueAttempt.is_temporary_flag(&"league_attempt_active"))
	assert_true(LeagueAttempt.is_temporary_flag(&"league_stage_3_cleared"))
	assert_false(LeagueAttempt.is_temporary_flag(LeagueAttempt.CHAMPION_DEFEATED))
	assert_false(LeagueAttempt.is_temporary_flag(LeagueAttempt.CREDITS_SEEN))


func test_victory_by_trainer_id() -> void:
	var flags := _flags()
	LeagueAttempt.start(flags)
	assert_false(LeagueAttempt.record_trainer_victory(flags, &"league_bruno"))
	assert_true(LeagueAttempt.record_trainer_victory(flags, &"league_lorelei"))
	assert_false(LeagueAttempt.record_trainer_victory(flags, &"celadon_gym_erika"))
	assert_eq(LeagueAttempt.current_stage(flags), 1)


func test_attempt_survives_a_save_round_trip() -> void:
	# §2.3 : les drapeaux sont ordinaires ; recharger reprend dans la salle courante.
	var flags := _flags()
	LeagueAttempt.start(flags)
	_cleared_up_to(flags, 2)
	var saved: Array = JSON.parse_string(JSON.stringify(JsonFields.ids_to_array(flags.to_array())))
	var loaded := _flags()
	loaded.load_array(saved)
	assert_eq(LeagueAttempt.current_stage(loaded), 3)
	assert_eq(LeagueAttempt.resume_room(loaded), &"league_lance")
	assert_false(LeagueAttempt.north_door_open(loaded, 3), "Peter n'est pas battu")


func test_interrupted_after_the_champion_replays_the_ceremony_once() -> void:
	# Arrêt entre la victoire contre le Champion et l'écriture du Panthéon (§2.3).
	var flags := _flags()
	LeagueAttempt.start(flags)
	_cleared_up_to(flags, 4)
	var saved: Array = JSON.parse_string(JSON.stringify(JsonFields.ids_to_array(flags.to_array())))
	var loaded := _flags()
	loaded.load_array(saved)
	assert_eq(LeagueAttempt.resume_room(loaded), &"league_champion")
	assert_true(LeagueAttempt.complete(loaded))
	assert_false(LeagueAttempt.complete(loaded))
