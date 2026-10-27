extends GutTest
## Sauvegarde pendant la tentative de Ligue (jalon 30 T8, `jalon-30.md` §2.3, §5), vraie partie et
## sauvegarde en mémoire, application relancée ([method HideoutPlay.resume]) :
## - sauvegarde dans la salle d'Agatha (étape 2) → relance : même salle, même case, mêmes
##   drapeaux, même équipe (PV, K.O., statut) ; la tentative n'est pas remise à zéro ;
## - arrêt pendant le combat d'Agatha → relance à l'entrée de la salle (dernière écriture stable),
##   avant ce combat : rien de gagné, porte nord fermée, l'appel se rejoue au premier pas ;
## - arrêt entre la victoire contre le Champion et la cérémonie (T17) : `league_stage_4_cleared`
##   relu, Chen présent, aucun titre posé ; la cérémonie (`league_victory`) repart à l'arrivée,
##   pas l'appel du rival, et ne pose qu'une entrée du Panthéon.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const AGATHA := "res://tools/debug_start/league_agatha.json"
const CHAMPION := "res://tools/debug_start/league_champion_charmander.json"
const SAVE_PATH := "user://test_league_save_save.json"

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


## [PV, statut, PP de la 1re capacité] de chaque membre.
func _party_state() -> Array:
	var rows: Array = []
	for pokemon: Pokemon in GameState.party.get_all():
		rows.append([pokemon.species_id, pokemon.hp, pokemon.status, pokemon.moves[0].pp])
	return rows


func _league_flags() -> Array[StringName]:
	var found: Array[StringName] = []
	for flag: StringName in LeagueAttempt.temporary_flags() + LeagueDirector.beaten_flags():
		if GameState.flags.has_flag(flag):
			found.append(flag)
	return found


func test_a_save_in_agatha_room_resumes_in_agatha_room() -> void:
	await _play.start(AGATHA)
	var cell := _play.player.get_cell()
	var flags := _league_flags()
	var party := _party_state()
	assert_eq(flags, [&"league_attempt_active", &"league_stage_0_cleared",
		&"league_stage_1_cleared", &"beaten_league_lorelei", &"beaten_league_bruno"]
		as Array[StringName])
	assert_eq(_play.saved().get("map"), "league_agatha", "écrit à l'arrivée")
	await _play.resume()
	assert_eq(_play.map_id(), &"league_agatha", "reprise dans la salle courante")
	assert_eq(_play.player.get_cell(), cell)
	assert_eq(_league_flags(), flags, "tentative reprise telle quelle")
	assert_eq(_party_state(), party, "même équipe (PV, K.O., statut, PP)")
	assert_true(_play.boot.get_map().get_grid().is_occupied(Vector2i(4, 0)), "porte nord fermée")
	assert_push_error_count(0)


func test_quitting_during_the_battle_resumes_before_it() -> void:
	await _play.start(AGATHA)
	await _play.step(Vector2i.UP)
	assert_true(_play.boot.get_cutscene_director().is_running(), "appel d'Agatha")
	# Répliques d'avant le combat avancées jusqu'au combat (on « tue l'appli » pendant).
	var box := _play.boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + 20000
	while not _play.boot.get_battle_director().is_running() and Time.get_ticks_msec() < deadline:
		var card := _play.boot.get_hud().get_champion_card()
		if card.is_showing():
			card.skip_hold()
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_true(_play.boot.get_battle_director().is_running(), "combat commencé")
	await _play.resume()
	assert_eq(_play.map_id(), &"league_agatha")
	assert_eq(LeagueAttempt.current_stage(GameState.flags), 2, "Agatha toujours à battre")
	assert_eq(_play.player.get_cell(), _play.boot.get_map().get_spawn_cell(&"from_south"),
		"reprise à l'entrée de la salle (dernière écriture stable)")
	assert_false(GameState.flags.has_flag(&"beaten_league_agatha"))
	assert_true(_play.boot.get_map().get_grid().is_occupied(Vector2i(4, 0)), "porte nord fermée")
	await _play.step(Vector2i.UP)
	assert_true(_play.boot.get_cutscene_director().is_running(), "l'appel d'Agatha se rejoue")
	assert_push_error_count(0)


func test_after_the_champion_the_victory_is_kept_until_the_ceremony() -> void:
	await _play.start(CHAMPION, func() -> void:
		GameState.flags.set_flag(&"league_stage_4_cleared")
		GameState.flags.set_flag(&"beaten_rival_champion"), false)
	assert_eq(_play.map_id(), &"league_champion")
	assert_eq(LeagueAttempt.current_stage(GameState.flags), LeagueAttempt.STAGE_DONE)
	assert_false(LeagueAttempt.is_champion(GameState.flags), "titre posé par la cérémonie (T17)")
	var map := _play.boot.get_map()
	assert_not_null(map.get_npc(&"chen"), "Chen est là")
	assert_false(map.get_grid().is_occupied(Vector2i(3, 0)), "porte nord ouverte")
	# T17 : arrivée dans la salle avec la victoire acquise (reprise) → la cérémonie repart, pas
	# l'appel du rival.
	var director := _play.boot.get_cutscene_director()
	assert_true(director.is_running(), "cérémonie relancée")
	assert_eq(director.get_cutscene_id(), &"league_victory")
	await _play.run_scene()
	assert_eq(_play.map_id(), &"pallet_town")
	assert_true(LeagueAttempt.is_champion(GameState.flags))
	assert_eq(GameState.hall_of_fame.size(), 1, "une seule entrée")
	assert_push_error_count(0)
