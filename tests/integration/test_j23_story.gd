extends GutTest
## Jalon 23 sur la vraie scène Boot : péage de la Porte (NON, refus, OUI), compteur de pas et
## pastille, sortie volontaire, fin de visite par les pas (haut-parleur, retour à la Porte), CS03
## de la Maison Secrète (une fois), Dents d'Or → CS04 du Gardien, rocher fixe (texte 46).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_j23_story_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]

var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-22T04:00:00")
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"interact", &"move_left", &"move_right", &"move_up",
			&"move_down"]:
		Input.action_release(action)


func _start(map: StringName, spawn: StringName, money: int = 3000, items: Array = [],
		visit: Dictionary = {}) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_boot.get_dialogue_runner().page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	GameState.new_game(23)
	GameState.player_name = "Kevin"
	GameState.flags.set_flag(&"starter_chosen")
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"squirtle", 30,
		GameState.rng))
	GameState.money = money
	for item: StringName in items:
		(GameState.bag as Bag).add(item)
	if not visit.is_empty():
		GameState.safari = SafariVisit.from_dict(visit)
	# Boot a déjà posé la carte avec la partie vide : la visite est relue comme au chargement.
	_boot.get_safari_director().set_map(_boot.get_map())
	# Les rencontres ne viennent pas troubler les pas comptés.
	_boot.get_encounter_director().enabled = false
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _finish(answer: bool = true) -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	while (director.is_running() or runner.is_running()
			or not _boot.get_safari_director().get_pending_end().is_empty()) \
			and Time.get_ticks_msec() < deadline:
		if runner.is_awaiting_choice():
			runner.choose(answer)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Un seul pas (appui bref, joueur déjà tourné dans le bon sens), puis les scènes qu'il déclenche.
func _step(direction: StringName, answer: bool = true) -> void:
	Input.action_press(direction)
	await wait_process_frames(1)
	Input.action_release(direction)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return not _player.is_moving(), 3.0)
	await _finish(answer)


func _place(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(2)


func _talk_to(npc_id: StringName, answer: bool = true) -> void:
	_pages.clear()
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, String(npc_id))
	if npc == null:
		return
	for direction: Vector2i in DIRECTIONS:
		var from := npc.get_cell() + direction
		if map.get_grid().is_free(from):
			map.spawn_player_at(_player, from, -direction)
			break
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _finish(answer)


func test_gate_no_steps_back_then_yes_pays_and_starts_the_visit() -> void:
	await _start(&"safari_zone_gate", &"entree")
	await _place(Vector2i(5, 5), Vector2i.UP)
	await _step(&"move_up", false)
	assert_has(_pages, "Bienvenue au PARC SAFARI !")
	assert_has(_pages, "Reviens quand tu veux !")
	assert_eq(_player.get_cell(), Vector2i(5, 5), "NON : un pas en arrière")
	assert_eq(GameState.money, 3000)
	_pages.clear()
	await _step(&"move_up", true)
	assert_has(_pages, "Voici 30 SAFARI BALLS !")
	assert_eq(GameState.money, 2500)
	assert_true(GameState.safari.active)
	assert_eq(_player.get_cell(), Vector2i(5, 4), "OUI : il passe")
	# Vers le Parc : le compteur ne tourne qu'à partir du Centre.
	await _place(Vector2i(5, 2), Vector2i.UP)
	await _step(&"move_up")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"safari_zone_center",
		TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"safari_zone_center")
	var steps: int = GameState.safari.steps_left
	assert_true(steps >= 499, "seul le pas du passage compte (%d)" % steps)
	await _step(&"move_up")
	assert_eq(GameState.safari.steps_left, steps - 1)
	var badge := _boot.get_hud().get_safari_badge()
	assert_not_null(badge, "pastille créée")
	if badge != null:
		assert_true(badge.visible)
		assert_eq(badge.get_steps_text(), str(steps - 1))
		assert_eq(badge.get_balls_text(), "30")


func test_not_enough_money_is_refused_without_debit() -> void:
	await _start(&"safari_zone_gate", &"entree", 300)
	await _place(Vector2i(5, 5), Vector2i.UP)
	await _step(&"move_up", true)
	assert_has(_pages, "Oh… Il te manque de quoi payer l'entrée.")
	assert_eq(GameState.money, 300)
	assert_false(GameState.safari.active)
	assert_eq(_player.get_cell(), Vector2i(5, 5))


func test_leaving_through_the_gate_ends_the_visit() -> void:
	await _start(&"safari_zone_gate", &"arrivee_parc", 3000, [],
		{"active": true, "steps_left": 200, "balls_left": 12})
	await _place(Vector2i(5, 3), Vector2i.DOWN)
	await _step(&"move_down", false)
	assert_has(_pages, "Tu pars déjà ?")
	assert_true(GameState.safari.active, "NON : la visite continue")
	assert_eq(_player.get_cell(), Vector2i(5, 3), "il remonte d'un pas")
	await _place(Vector2i(5, 3), Vector2i.DOWN)
	await _step(&"move_down", true)
	assert_has(_pages, "Les SAFARI BALLS restantes restent ici. Merci !")
	assert_false(GameState.safari.active)
	assert_false(GameState.flags.has_flag(&"safari_active"))


func test_time_up_returns_to_the_gate_with_the_speaker() -> void:
	await _start(&"safari_zone_east", &"arrivee_centre", 3000, [],
		{"active": true, "steps_left": 1, "balls_left": 5})
	await _place(Vector2i(1, 22), Vector2i.RIGHT)
	await _step(&"move_right")
	assert_true(GameState.safari.active, "le dernier pas est utilisable")
	await _step(&"move_right")
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"safari_zone_gate",
		TIMEOUT)
	await _finish()
	assert_has(_pages, "Ding-dong ! Le temps est écoulé !")
	assert_has(_pages, "Alors, bonne pêche ? Reviens vite !")
	assert_eq(_boot.get_map().map_id, &"safari_zone_gate")
	assert_eq(_player.get_cell(), Vector2i(5, 5), "arrivée de fin de visite")
	assert_false(GameState.safari.active)


func test_secret_house_gives_surf_once() -> void:
	await _start(&"safari_zone_secret_house", &"entree", 3000, [],
		{"active": true, "steps_left": 300, "balls_left": 30})
	await _talk_to(&"pecheur_expert")
	assert_has(_pages, "Voici ton prix : la CS03, Surf !")
	assert_eq((GameState.bag as Bag).count_of(&"hm03"), 1)
	assert_true(GameState.flags.has_flag(&"got_hm03"))
	await _talk_to(&"pecheur_expert")
	assert_eq((GameState.bag as Bag).count_of(&"hm03"), 1, "une seule fois")
	assert_has(_pages, "Il te faudra le Badge Âme de Koga.")


func test_warden_trades_the_gold_teeth_for_strength() -> void:
	await _start(&"wardens_house", &"entree")
	await _talk_to(&"gardien", true)
	assert_has(_pages, "Hif fuff hefifoo !")
	assert_false((GameState.bag as Bag).has(&"hm04"))
	(GameState.bag as Bag).add(&"gold_teeth")
	await _talk_to(&"gardien")
	assert_has(_pages, "Tiens, prends ça. C'est la CS04, Force.")
	assert_false((GameState.bag as Bag).has(&"gold_teeth"), "Dents d'Or rendues")
	assert_true((GameState.bag as Bag).has(&"hm04"))
	assert_true(GameState.flags.has_flag(&"gave_gold_teeth"))
	assert_true(GameState.flags.has_flag(&"got_hm04"))
	assert_true(_boot.get_map().get_grid().is_solid(Vector2i(11, 3)), "rocher fixe")
