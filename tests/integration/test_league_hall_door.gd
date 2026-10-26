extends GutTest
## Porte de la Ligue dans le hall du Plateau Indigo (jalon 30, fusion du J29 ; `jalon-30.md`
## §10.8, T30-01, Q30-6), vraie partie : devant la porte, le garde pose la question OUI / NON ;
## NON → le joueur recule d'un pas, reste dans le hall, rien ne commence ; OUI → salle d'Olga,
## tentative ouverte, point de repos = Centre du hall (réveil d'une défaite).

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const PLATEAU := "res://tools/debug_start/indigo_plateau.json"
const SAVE_PATH := "user://test_league_hall_door_save.json"
const DOOR_FRONT := Vector2i(12, 4)

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


## Hall, une case sous la porte (devant les gardes).
func _in_the_hall() -> void:
	await _play.start(PLATEAU)
	await SceneRouter.change_map(&"indigo_plateau_lobby", &"league_door", Vector2i.DOWN)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _play.boot.is_stable(), 15.0)
	assert_eq(_play.player.get_cell(), DOOR_FRONT, "arrivée par la porte de la Ligue (12, 4)")
	assert_false(_play.boot.get_cutscene_director().is_running(), "aucune question à l'arrivée")
	await _play.step(Vector2i.DOWN)
	assert_eq(_play.player.get_cell(), DOOR_FRONT + Vector2i.DOWN)


func test_answering_no_keeps_the_player_in_the_hall() -> void:
	await _in_the_hall()
	await _play.step(Vector2i.UP)
	assert_true(_play.boot.get_cutscene_director().is_running(), "question du garde")
	await _play.run_scene(false)
	assert_has(_play.pages(), "Au-delà de cette porte, pas de retour avant la fin. Tu es prêt ?")
	assert_eq(_play.map_id(), &"indigo_plateau_lobby")
	assert_eq(_play.player.get_cell(), DOOR_FRONT + Vector2i.DOWN, "un pas en arrière")
	assert_false(LeagueAttempt.is_active(GameState.flags))
	assert_false(GameState.flags.has_flag(&"league_door_declined"), "drapeau de travail effacé")
	assert_push_error_count(0)


func test_answering_yes_opens_the_attempt_in_lorelei_room() -> void:
	await _in_the_hall()
	await _play.step(Vector2i.UP)
	await _play.run_scene(true)
	assert_eq(_play.map_id(), &"league_lorelei", "salle d'Olga")
	assert_eq(_play.player.get_cell(), _play.boot.get_map().get_spawn_cell(&"from_lobby"))
	assert_true(LeagueAttempt.is_active(GameState.flags), "tentative ouverte")
	assert_eq([GameState.heal_map, GameState.heal_spawn], [&"indigo_plateau_lobby", &"heal"],
		"réveil au Centre du hall")
	assert_push_error_count(0)
