extends GutTest
## Jalon 32, lot 32J (`jalon-32.md` T3 ; N-1 à N-5, textes 1 à 7) avec le vrai Boot :
## - Carmin : le docker de la rumeur ; le vieux camion du quai ne cache Mew que quand les
##   **150 autres espèces** sont capturées (rencontre unique, N30, `mew_appeared`) ;
## - Résidence de Céladopole, 3e : le concepteur, après la Ligue, remet le Diplôme à 150.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_j32_mew_save.json"
const LEAGUE := &"league_champion_defeated"
const FADE := 0.05
const TIMEOUT := 15.0
const TRUCK_LINE := "Quelque chose bouge sous le camion…"

var _boot: Boot
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	Input.action_release(&"interact")


func _catch_all_but(missing: Array[StringName]) -> void:
	for id: StringName in _boot.get_pokemon_data().get_species_ids():
		if not missing.has(id):
			GameState.pokedex.mark_caught(id)


func test_the_rumor_docker_stands_on_the_quay() -> void:
	await _start(&"vermilion_city", &"from_fisher_house", [])
	var docker := _boot.get_map().get_npc(&"rumor_docker")
	assert_not_null(docker, "présent dès le J15, sans condition")
	if docker != null:
		assert_eq(docker.get_cell(), Vector2i(7, 25))


func test_the_truck_hides_mew_once_150_are_caught() -> void:
	await _start(&"vermilion_city", &"from_fisher_house", [LEAGUE])
	_catch_all_but([&"mew"])
	assert_eq(GameState.pokedex.caught_count(), 150)
	var battles: Array = []
	_boot.get_battle_director().battle_started.connect(func(id: StringName) -> void:
		battles.append(id))
	await _examine(Vector2i(6, 25), Vector2i.LEFT, func() -> bool: return not battles.is_empty())
	assert_true(_pages.has(TRUCK_LINE), "%s" % [_pages])
	assert_true(GameState.flags.has_flag(&"mew_appeared"))
	assert_eq(battles.size(), 1, "le combat commence, sans autre texte")
	await wait_until(func() -> bool: return GameState.pokedex.is_seen(&"mew"), TIMEOUT)
	assert_true(GameState.pokedex.is_seen(&"mew"), "« vu » à la rencontre")


func test_the_truck_is_only_a_truck_before_150() -> void:
	await _start(&"vermilion_city", &"from_fisher_house", [LEAGUE])
	_catch_all_but([&"mew", &"porygon"])
	await _examine(Vector2i(6, 25), Vector2i.LEFT, func() -> bool: return false)
	assert_false(_pages.has(TRUCK_LINE))
	assert_false(GameState.flags.has_flag(&"mew_appeared"))
	assert_eq(_pages.size(), 1, "une seule page")


func test_the_designer_gives_the_diploma_at_150() -> void:
	await _start(&"celadon_mansion_3f", &"from_down", [LEAGUE])
	_catch_all_but([&"mew"])
	assert_not_null(_boot.get_map().get_npc(&"designer"))
	await _talk(Vector2i(9, 4), Vector2i.UP)
	assert_true(GameState.flags.has_flag(&"diploma_received"))
	assert_true(_pages.has("Kevin reçoit le Diplôme !"), "%s" % [_pages])
	_pages.clear()
	await _talk(Vector2i(9, 4), Vector2i.UP)
	assert_eq(_pages, ["Incroyable ! Tu as complété\nton Pokédex ! Félicitations !"]
		as Array[String], "une seule fois")


func test_the_designer_encourages_below_150_and_is_absent_before_the_league() -> void:
	await _start(&"celadon_mansion_3f", &"from_down", [LEAGUE])
	await _talk(Vector2i(9, 4), Vector2i.UP)
	assert_false(GameState.flags.has_flag(&"diploma_received"))
	assert_true(_pages.has("Remplir le Pokédex, c'est dur.\nMais n'abandonne pas !"))
	_boot.queue_free()
	await wait_process_frames(2)
	await _start(&"celadon_mansion_3f", &"from_down", [])
	assert_null(_boot.get_map().get_npc(&"designer"))


# --- Outils -----------------------------------------------------------------------------------

func _start(map_id: StringName, spawn: StringName, flags: Array) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.new_game(32)
	GameState.player_name = "Kevin"
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"rattata", 10,
		GameState.rng))
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	# Les PNJ conditionnels suivent les drapeaux à l'entrée sur la carte : on y revient.
	await SceneRouter.change_map(map_id, spawn)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable() \
		and _boot.get_map() != null and _boot.get_map().map_id == map_id, TIMEOUT)


func _talk(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_boot.get_player(), cell, facing)
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) and Time.get_ticks_msec() < deadline:
		if runner.is_awaiting_choice():
			runner.choose(true)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _species() -> Array[StringName]:
	var result: Array[StringName] = []
	for pokemon: Pokemon in GameState.party.get_all():
		result.append(pokemon.species_id)
	return result


## Examine devant [param cell] ; s'arrête quand [param stop] est vrai (un combat a commencé).
func _examine(cell: Vector2i, facing: Vector2i, stop: Callable) -> void:
	_boot.get_map().spawn_player_at(_boot.get_player(), cell, facing)
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()) and not stop.call() \
			and Time.get_ticks_msec() < deadline:
		if box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
