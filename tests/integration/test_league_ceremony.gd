extends GutTest
## Cérémonie de la Ligue (jalon 30, T15 à T17 ; `jalon-30.md` §2.3, §2.4, §5 `test_postgame`),
## vraie partie et sauvegarde en mémoire ([HideoutPlay]) :
## - victoire contre le Champion acquise → Chen, Panthéon (écran), titre et entrée écrits en une
##   fois, narration de fin, générique, Bourg Palette devant la maison ; tout est conservé ;
## - reprise au Panthéon après l'écriture (titre posé) : générique et Bourg Palette, sans
##   deuxième entrée ;
## - deuxième victoire (titre déjà obtenu) → deuxième entrée, générique passable.
## Écran du Panthéon et générique instantanés (speed_scale = 0, HideoutPlay).

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const CHAMPION := "res://tools/debug_start/league_champion_charmander.json"
const SAVE_PATH := "user://test_league_ceremony_save.json"

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


func _five_wins() -> void:
	LeagueAttempt.start(GameState.flags)
	for stage: int in LeagueAttempt.STAGE_COUNT:
		LeagueAttempt.record_victory(GameState.flags, stage)
	GameState.flags.set_flag(&"beaten_rival_champion")


func _species(entry: Dictionary) -> Array:
	return (entry["team"] as Array).map(func(member: Dictionary) -> String:
		return member["species"])


func _party_species() -> Array:
	return GameState.party.get_all().map(func(pokemon: Pokemon) -> String:
		return String(pokemon.species_id))


func test_victory_runs_hall_of_fame_credits_and_pallet_town() -> void:
	await _play.start(CHAMPION, _five_wins, false)
	var party := _party_species()
	var badges := GameState.flags.has_flag(&"badge_boulder")
	var money: int = GameState.money
	assert_eq(_play.boot.get_cutscene_director().get_cutscene_id(), &"league_victory")
	await _play.run_scene()
	assert_eq(_play.map_id(), &"pallet_town", "arrivée à Bourg Palette")
	assert_eq(_play.player.get_cell(), _play.boot.get_map().get_spawn_cell(&"player_house_door"),
		"devant la maison")
	var flags := GameState.flags
	assert_true(LeagueAttempt.is_champion(flags), "titre")
	assert_false(LeagueAttempt.is_active(flags), "tentative effacée")
	for stage: int in LeagueAttempt.STAGE_COUNT:
		assert_false(flags.has_flag(LeagueAttempt.stage_flag(stage)))
	assert_true(flags.has_flag(LeagueAttempt.CREDITS_SEEN), "générique vu")
	assert_eq(GameState.hall_of_fame.size(), 1)
	var entry := GameState.hall_of_fame.get_entry(0)
	assert_eq(_species(entry), party, "l'équipe victorieuse, dans l'ordre")
	assert_eq(entry["player"], "Kevin")
	assert_eq(entry["date"], "2026-10-20T18:00:00", "horloge de l'appareil")
	assert_eq(_party_species(), party, "équipe conservée")
	assert_eq(GameState.flags.has_flag(&"badge_boulder"), badges, "badges conservés")
	assert_eq(GameState.money, money, "argent conservé")
	var pages := _play.pages()
	assert_has(pages, "Kevin ! Félicitations. Tu es le nouveau Champion de la Ligue Pokémon.")
	assert_has(pages, "Bienvenue au Panthéon !")
	assert_has(pages, "Kevin et son équipe entrent dans la légende.")
	var saved := _play.saved()
	assert_eq((saved.get("hall_of_fame", []) as Array).size(), 1, "entrée écrite")
	assert_push_error_count(0)


func test_resume_in_the_hall_after_the_title_adds_no_second_entry() -> void:
	await _play.start(CHAMPION)
	var flags := GameState.flags
	flags.set_flag(LeagueAttempt.CHAMPION_DEFEATED)
	GameState.hall_of_fame.add(HallOfFame.snapshot(GameState.party.get_all(), "Kevin",
		&"charmander", 10.0, "2026-10-19T10:00:00"))
	await SceneRouter.change_map(&"hall_of_fame", &"from_south", Vector2i.UP)
	await wait_process_frames(3)
	var director := _play.boot.get_cutscene_director()
	assert_eq(director.get_cutscene_id(), &"league_hall_of_fame", "seule sortie du Panthéon")
	await _play.run_scene()
	assert_eq(_play.map_id(), &"pallet_town")
	assert_eq(GameState.hall_of_fame.size(), 1, "aucune entrée de plus")
	assert_does_not_have(_play.pages(), "Bienvenue au Panthéon !")
	assert_has(_play.pages(), "Kevin et son équipe entrent dans la légende.")
	assert_push_error_count(0)


func test_second_victory_adds_a_second_entry_and_credits_can_be_skipped() -> void:
	await _play.start(CHAMPION, func() -> void:
		GameState.flags.set_flag(LeagueAttempt.CHAMPION_DEFEATED)
		GameState.flags.set_flag(LeagueAttempt.CREDITS_SEEN)
		GameState.hall_of_fame.add(HallOfFame.snapshot(GameState.party.get_all(), "Kevin",
			&"charmander", 10.0, "2026-10-19T10:00:00"))
		_five_wins(), false)
	var credits := _play.boot.get_credits_screen()
	var skippable: Array[bool] = []
	credits.visibility_changed.connect(func() -> void:
		if credits.visible:
			skippable.append(credits.is_skip_visible()))
	await _play.run_scene()
	assert_eq(_play.map_id(), &"pallet_town")
	assert_eq(GameState.hall_of_fame.size(), 2, "deuxième entrée")
	assert_eq(GameState.hall_of_fame.get_entry(0)["date"], "2026-10-19T10:00:00",
		"la première n'a pas changé")
	assert_eq(skippable, [true], "générique passable (déjà vu)")
	assert_push_error_count(0)
