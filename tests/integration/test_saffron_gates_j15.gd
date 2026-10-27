extends GutTest
## Postes du J15 de Safrania (jalon 26 T8, docs/tech/jalon-26.md §0.1) : les déclencheurs de recul
## des Routes 5 et 6 ont leur dialogue (`route_5_gate_trigger`, `route_6_gate_trigger`) et, comme le
## garde (PARLER), remettent la boisson exactement comme aux postes des Routes 7 et 8
## (test_saffron_gates). Vraie scène Boot, zone `saffron_city` jouable (cartes du T6).
##
## - Sans boisson : soif (216), recul, rien ne change.
## - Avec une boisson : choix (217) ; OUI → la boisson part (l'Eau Fraîche d'abord), drapeau
##   `saffron_gates_open`, texte 219, garde écarté (même case que `moved` : pas de nouveau saut au
##   rechargement) ; NON → 218, recul, la boisson reste.
## - Garde (PARLER) : même remise, texte de repli intact zone fermée.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_saffron_gates_j15_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const FLAG := &"saffron_gates_open"
const T216: Array[String] = ["Je monte la garde depuis ce matin,\nsous ce soleil…",
	"J'ai une de ces soifs."]
const T217 := "Lui donner une boisson ?"
const T218 := "Tant pis… Je tiendrai bien encore un peu."
const T219 := "Pour la peine, je vous laisse passer.\nBonne visite de Safrania !"
const T215: Array[String] = ["Merci encore pour la boisson.", "Allez-y, Safrania vous attend."]
## Poste : carte, arrivée, garde, case du garde fermé / ouvert, [case de départ, direction de la
## marche, case du déclencheur, case après le recul, direction du recul].
const POSTS: Dictionary = {
	&"route_5": [&"route_5_gate", &"from_route_5", &"route_5_guard", Vector2i(4, 2),
		Vector2i(3, 3), Vector2i(4, 5), Vector2i.UP, Vector2i(4, 3), Vector2i(4, 4)],
	&"route_6_w": [&"route_6", &"from_underground", &"saffron_guard", Vector2i(36, 8),
		Vector2i(35, 8), Vector2i(33, 8), Vector2i.RIGHT, Vector2i(35, 8), Vector2i(34, 8)],
	&"route_6_e": [&"route_6", &"from_underground", &"saffron_guard", Vector2i(36, 8),
		Vector2i(35, 8), Vector2i(39, 8), Vector2i.LEFT, Vector2i(37, 8), Vector2i(38, 8)],
	&"route_6_s": [&"route_6", &"from_underground", &"saffron_guard", Vector2i(36, 8),
		Vector2i(35, 8), Vector2i(36, 11), Vector2i.UP, Vector2i(36, 9), Vector2i(36, 10)],
}

var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _pages: Array[String] = []
var _dialogues: DialogueLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	assert_true(_dialogues.load_dir(), "\n".join(_dialogues.get_errors()))


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-22T15:00:00")
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Données ----------------------------------------------------------------------------------

func test_triggers_have_their_own_dialogue_and_the_closed_zone_keeps_the_old_text() -> void:
	var closed := func(_zone: StringName) -> bool: return false
	var open_zone := func(_zone: StringName) -> bool: return true
	var no_drink := func(_id: StringName) -> bool: return false
	for id: StringName in [&"route_5_gate_trigger", &"route_5_guard", &"route_6_gate_trigger",
			&"route_6_guard"]:
		assert_not_null(_dialogues.get_dialogue(id), String(id))
		var asked := _dialogues.get_dialogue(id).pick(StoryFlags.new(), null, 0, Callable(),
			func(item: StringName) -> bool: return item == &"fresh_water", open_zone)
		assert_eq(_texts(asked), T216 + [T217] as Array, "%s : 216 puis 217" % id)
		assert_eq(asked.choice.cancel_pages[0].text, T218)
		var thirsty := _dialogues.get_dialogue(id).pick(StoryFlags.new(), null, 0, Callable(),
			no_drink, open_zone)
		assert_eq(_texts(thirsty), T216, "%s : sans boisson, 216" % id)
		assert_null(thirsty.choice)
		var old := _dialogues.get_dialogue(id).pick(StoryFlags.new(), null, 0, Callable(),
			no_drink, closed)
		assert_ne(_texts(old), T216, "%s : zone fermée, texte du J15" % id)
		assert_null(old.choice)
	assert_ne(_dialogues.get_dialogue(&"route_5_gate_trigger"),
		_dialogues.get_dialogue(&"route_5_guard"))
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	for id: StringName in [&"route_5_gate_rule", &"route_6_gate_rule_w", &"route_6_gate_rule_e",
			&"route_6_gate_rule_s"]:
		var steps := cutscenes.get_cutscene(id).variants[0].steps
		var played: Array[StringName] = []
		for step: CutsceneStep in steps:
			if step.kind == CutsceneStep.Kind.DIALOGUE:
				played.append(step.dialogue_id)
		var expected := &"route_5_gate_trigger" if id == &"route_5_gate_rule" \
			else &"route_6_gate_trigger"
		assert_eq(played, [expected] as Array[StringName], "%s : son dialogue" % id)
		assert_false(cutscenes.get_next(id).is_empty(), "%s : suite (boisson ou recul)" % id)


# --- Vraie scène Boot ---------------------------------------------------------------------------

func _start(post: StringName, drinks: Array) -> void:
	var row: Array = POSTS[post]
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = row[0]
	_boot.start_spawn = row[1]
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	GameState.new_game(7)
	GameState.player_name = "Kevin"
	for id: StringName in drinks:
		(GameState.bag as Bag).add(id)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _place(cell: Vector2i, facing: Vector2i) -> void:
	var map := _boot.get_map()
	_player.enter_map(map.get_grid(), cell, facing, map.get_pixel_rect())
	await wait_process_frames(2)


## Fait défiler dialogues et scènes (chaînées comprises) ; [param answer] au choix.
func _finish(answer: bool) -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(2)
	var idle := 0
	while idle < 20 and Time.get_ticks_msec() < deadline:
		if runner.is_awaiting_choice():
			runner.choose(answer)
		elif box.is_open():
			box.advance_requested.emit()
		idle = idle + 1 if not (director.is_running() or runner.is_running()) else 0
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Marche depuis la case de départ du poste jusqu'au déclencheur, puis joue la scène.
func _walk_in(post: StringName, answer: bool) -> void:
	var row: Array = POSTS[post]
	await _place(row[5], row[6])
	var action: StringName = {Vector2i.UP: &"move_up", Vector2i.LEFT: &"move_left",
		Vector2i.RIGHT: &"move_right"}[row[6]]
	Input.action_press(action)
	await wait_until(func() -> bool: return _boot.get_cutscene_director().is_running(),
		TIMEOUT)
	Input.action_release(action)
	await _finish(answer)


func _guard_cell(post: StringName) -> Vector2i:
	return _boot.get_map().get_npc(POSTS[post][2]).get_cell()


func _check_recoil(post: StringName) -> void:
	var row: Array = POSTS[post]
	assert_eq(_player.get_cell(), row[8], "%s : recul d'une case" % post)
	assert_eq(_guard_cell(post), row[3], "%s : le garde n'a pas bougé" % post)
	assert_false(GameState.flags.has_flag(FLAG))


func test_without_a_drink_the_trigger_says_thirst_and_pushes_back() -> void:
	for post: StringName in POSTS:
		await _start(post, [])
		await _walk_in(post, true)
		assert_eq(_pages, T216, String(post))
		_check_recoil(post)
		assert_eq(_boot.get_map().map_id, POSTS[post][0])
		_boot.queue_free()
		await wait_process_frames(2)
		_pages.clear()


func test_no_keeps_the_drink_and_pushes_back() -> void:
	for post: StringName in POSTS:
		await _start(post, [&"soda_pop"])
		await _walk_in(post, false)
		assert_eq(_pages.back(), T218, String(post))
		assert_true(_pages.has(T217))
		assert_eq((GameState.bag as Bag).count_of(&"soda_pop"), 1)
		_check_recoil(post)
		_boot.queue_free()
		await wait_process_frames(2)
		_pages.clear()


func test_a_drink_opens_the_gates_from_the_trigger() -> void:
	for post: StringName in POSTS:
		await _start(post, [&"fresh_water", &"lemonade"])
		await _walk_in(post, true)
		assert_true(_pages.has(T217), String(post))
		assert_eq(_pages.back(), T219, "%s : 219 en dernier" % post)
		assert_true(_pages.has("Kevin donne une Eau Fraîche\nau garde."), str(_pages))
		assert_true(GameState.flags.has_flag(FLAG), "%s : postes ouverts" % post)
		assert_false((GameState.bag as Bag).has(&"fresh_water"), "l'Eau Fraîche part d'abord")
		assert_eq((GameState.bag as Bag).count_of(&"lemonade"), 1, "la Limonade reste")
		assert_eq(_guard_cell(post), POSTS[post][4], "%s : garde écarté" % post)
		assert_false(_boot.get_map().get_grid().is_solid(POSTS[post][3]), "case dégagée")
		_boot.queue_free()
		await wait_process_frames(2)
		_pages.clear()


## PARLER au garde (devant lui, tourné ↑) : même remise, même résultat.
func test_a_drink_given_by_talking_to_the_guard() -> void:
	for post: StringName in [&"route_5", &"route_6_s"]:
		var row: Array = POSTS[post]
		await _start(post, [&"soda_pop"])
		await _place(row[3] + Vector2i.DOWN, Vector2i.UP)
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")
		await _finish(true)
		assert_true(_pages.has(T217), "%s : choix" % post)
		assert_true(_pages.has("Kevin donne un Soda Cool\nau garde."), str(_pages))
		assert_eq(_pages.back(), T219)
		assert_true(GameState.flags.has_flag(FLAG))
		assert_false((GameState.bag as Bag).has(&"soda_pop"))
		assert_eq(_guard_cell(post), row[4], "%s : garde écarté" % post)
		_pages.clear()
		# Ensuite : merci (215).
		await _place(row[4] + Vector2i.RIGHT if post == &"route_5" else row[4] + Vector2i.LEFT,
			Vector2i.LEFT if post == &"route_5" else Vector2i.RIGHT)
		_boot.queue_free()
		await wait_process_frames(2)


func test_talking_without_a_drink_only_shows_thirst() -> void:
	await _start(&"route_6_s", [])
	await _place(Vector2i(36, 9), Vector2i.UP)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await _finish(true)
	assert_eq(_pages, T216)
	assert_false(GameState.flags.has_flag(FLAG))
	assert_eq(_guard_cell(&"route_6_s"), Vector2i(36, 8))


func test_open_gates_give_thanks_to_the_guards() -> void:
	var open := StoryFlags.new()
	open.set_flag(FLAG)
	for id: StringName in [&"route_5_guard", &"route_6_guard"]:
		var thanks := _dialogues.get_dialogue(id).pick(open)
		assert_eq(_texts(thanks), T215, String(id))


func _texts(variant: DialogueVariant) -> Array:
	var texts: Array = []
	for page: DialoguePage in variant.pages:
		texts.append(page.text)
	return texts
