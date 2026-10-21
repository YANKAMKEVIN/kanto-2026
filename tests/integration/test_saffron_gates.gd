extends GutTest
## Postes de Safrania (jalon 20 T25, docs/tech/jalon-20.md §2.16 ; décision de Kevin du
## 2026-10-19, Q-4 : A) : une boisson donnée au garde ouvre les quatre postes.
##
## - Tant que la zone `saffron_city` n'est pas jouable (aujourd'hui : `maps: []`), le garde ne
##   demande rien : texte 12, porte fermée, aucune variante « soif » (vraie donnée).
## - Zone déclarée jouable (source de zones du lecteur remplacée, vraie scène Boot sur
##   `route_8_gate`) : sans boisson → soif (216) ; avec chacune des trois → choix (217), OUI →
##   boisson retirée, `saffron_gates_open`, texte 219, le garde s'écarte en (3, 2) ; deux
##   boissons → l'Eau Fraîche part d'abord ; NON → 218, rien ne change ; ensuite → merci (215).
## - Drapeau levé : les règles de recul du J15 sont désarmées, les gardes des quatre postes sont
##   placés à côté de leur porte ; une partie v7 du J15 se recharge sans changement.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_saffron_gates_save.json"
const FADE := 0.05
const TIMEOUT := 15.0
const FLAG := &"saffron_gates_open"
const T12: Array[String] = ["Désolé, Safrania est fermée\npour le moment.",
	"Je n'en sais pas plus que vous."]
const T215: Array[String] = ["Merci encore pour la boisson.", "Allez-y, Safrania vous attend."]
const T216: Array[String] = ["Je monte la garde depuis ce matin,\nsous ce soleil…",
	"J'ai une de ces soifs."]
const T218 := "Tant pis… Je tiendrai bien encore un peu."

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
	GameState.clock = FixedClock.new("2026-10-20T15:00:00")
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Input.action_release(&"interact")


# --- Données : la zone n'est pas jouable --------------------------------------------------------

func test_saffron_is_not_playable_yet() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_false(zones.is_playable(&"saffron_city"), "Safrania : maps vide jusqu'au J26")
	assert_true(zones.is_playable(&"route_8"))
	assert_false(zones.is_playable(&"unknown_zone"))


func test_without_saffron_the_guard_asks_for_nothing() -> void:
	var guard := _dialogues.get_dialogue(&"saffron_gate_guard")
	var flags := StoryFlags.new()
	var all_drinks := func(_id: StringName) -> bool: return true
	var closed := func(_zone: StringName) -> bool: return false
	for has_flag: bool in [false, true]:
		if has_flag:
			flags.set_flag(FLAG)
		var variant := guard.pick(flags, null, 0, Callable(), all_drinks, closed)
		assert_eq(_texts(variant), T12, "texte 12 (drapeau %s)" % has_flag)
		assert_null(variant.choice, "aucune boisson demandée")


func test_the_first_drink_present_is_the_one_offered() -> void:
	var guard := _dialogues.get_dialogue(&"saffron_gate_guard")
	var open := func(_zone: StringName) -> bool: return true
	var cases := [
		[[&"fresh_water", &"soda_pop", &"lemonade"], &"saffron_gate_drink_water"],
		[[&"soda_pop", &"lemonade"], &"saffron_gate_drink_soda"],
		[[&"lemonade"], &"saffron_gate_drink_lemonade"],
	]
	for row: Array in cases:
		var bag: Array = row[0]
		var variant := guard.pick(StoryFlags.new(), null, 0, Callable(),
			func(id: StringName) -> bool: return bag.has(id), open)
		assert_not_null(variant.choice, str(bag))
		assert_eq(variant.choice.confirm_cutscene, row[1])
		assert_eq(_texts(variant).slice(0, 2), T216)
		assert_eq(variant.choice.cancel_pages[0].text, T218)
	var none := guard.pick(StoryFlags.new(), null, 0, Callable(),
		func(_id: StringName) -> bool: return false, open)
	assert_eq(_texts(none), T216, "sans boisson : la soif, sans choix")
	assert_null(none.choice)


func test_the_drink_scenes_take_the_drink_and_open_the_gates_together() -> void:
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	for row: Array in [[&"saffron_gate_drink_water", &"fresh_water"],
			[&"saffron_gate_drink_soda", &"soda_pop"], [&"saffron_gate_drink_lemonade", &"lemonade"]]:
		var variant := cutscenes.get_cutscene(row[0]).pick(StoryFlags.new())
		assert_not_null(variant, String(row[0]))
		var steps := variant.steps
		assert_eq([steps[0].kind, steps[0].item_id], [CutsceneStep.Kind.TAKE, row[1]],
			"%s : la boisson d'abord" % row[0])
		assert_eq(steps[1].kind, CutsceneStep.Kind.SET_FLAGS, "drapeau dans le même bloc")
		assert_eq(steps[1].flags, [FLAG] as Array[StringName])


func test_the_open_gates_disarm_the_j15_rules_and_move_every_guard() -> void:
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	var open := StoryFlags.new()
	open.set_flag(FLAG)
	for id: StringName in [&"route_5_gate_rule", &"route_6_gate_rule_w", &"route_6_gate_rule_e",
			&"route_6_gate_rule_s"]:
		assert_not_null(cutscenes.get_cutscene(id).pick(StoryFlags.new()), "%s armée" % id)
		assert_null(cutscenes.get_cutscene(id).pick(open), "%s désarmée" % id)
	var places := {&"route_7_gate": [&"saffron_guard", Vector2i(4, 2), Vector2i(3, 2)],
		&"route_8_gate": [&"saffron_guard", Vector2i(4, 2), Vector2i(3, 2)],
		&"route_5_gate": [&"route_5_guard", Vector2i(4, 2), Vector2i(3, 3)],
		&"route_6": [&"saffron_guard", Vector2i(36, 8), Vector2i(35, 8)]}
	for map_id: StringName in places:
		var roster := NpcRoster.new()
		assert_true(roster.load_file("res://data/npcs/%s.json" % map_id), String(map_id))
		var spec := roster.get_spec(places[map_id][0])
		assert_eq(spec.placed_for(StoryFlags.new()).cell, places[map_id][1], "%s fermé" % map_id)
		assert_eq(spec.placed_for(open).cell, places[map_id][2], "%s ouvert" % map_id)
	for id: StringName in [&"route_5_guard", &"route_6_guard", &"saffron_gate_guard"]:
		var thanks := _dialogues.get_dialogue(id).pick(open, null, 0, Callable(),
			Callable(), func(_zone: StringName) -> bool: return true)
		assert_eq(_texts(thanks), T215, "%s : merci (215)" % id)


func test_a_j15_save_with_closed_gates_loads_unchanged() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var save := SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	var state: Node = autofree(GameStateScript.new())
	state.clock = FixedClock.new("2026-10-20T10:00:00")
	state.new_game(7)
	state.set_player_location(&"route_5_gate", Vector2i(4, 4), Vector2i.UP)
	(state.bag as Bag).add(&"potion", 2)
	assert_eq(save.write(state.to_dict()), OK)
	var loaded: Node = autofree(GameStateScript.new())
	assert_true(loaded.load_dict(save.read(), data))
	assert_false((loaded.flags as StoryFlags).has_flag(FLAG), "aucun drapeau ajouté")
	assert_eq([loaded.current_map, loaded.player_cell], [&"route_5_gate", Vector2i(4, 4)])
	assert_eq((loaded.bag as Bag).count_of(&"potion"), 2)


# --- Vraie scène Boot, zone déclarée jouable --------------------------------------------------

func _start(drinks: Array) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_8_gate"
	_boot.start_spawn = &"north_door"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.zone_source = func(zone: StringName) -> bool: return zone == &"saffron_city"
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	GameState.new_game(7)
	GameState.player_name = "Kevin"
	for id: StringName in drinks:
		(GameState.bag as Bag).add(id)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


## Parle au garde (devant lui, tourné ↑) ; [param answer] au choix s'il y en a un.
func _talk(answer: bool) -> void:
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
			runner.choose(answer)
		elif box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func _guard_cell() -> Vector2i:
	return _boot.get_map().get_npc(&"saffron_guard").get_cell()


func test_without_a_drink_the_guard_is_only_thirsty() -> void:
	await _start([])
	await _talk(true)
	assert_eq(_pages, T216 as Array[String])
	assert_false(GameState.flags.has_flag(FLAG))
	assert_eq(_guard_cell(), Vector2i(4, 2))


func test_no_keeps_the_drink_and_the_gates_closed() -> void:
	await _start([&"soda_pop"])
	await _talk(false)
	assert_eq(_pages.back(), T218)
	assert_eq((GameState.bag as Bag).count_of(&"soda_pop"), 1)
	assert_false(GameState.flags.has_flag(FLAG))
	assert_eq(_guard_cell(), Vector2i(4, 2))


func test_a_drink_opens_the_gates_and_the_guard_steps_aside() -> void:
	await _start([&"fresh_water", &"lemonade"])
	await _talk(true)
	assert_true(GameState.flags.has_flag(FLAG), "postes ouverts")
	assert_false((GameState.bag as Bag).has(&"fresh_water"), "l'Eau Fraîche part d'abord")
	assert_eq((GameState.bag as Bag).count_of(&"lemonade"), 1, "la Limonade reste")
	assert_true(_pages.has("Kevin donne une Eau Fraîche\nau garde."), str(_pages))
	assert_true(_pages.has("Pour la peine, je vous laisse passer.\nBonne visite de Safrania !"))
	assert_eq(_guard_cell(), Vector2i(3, 2), "un pas de côté")
	assert_false(_boot.get_map().get_grid().is_solid(Vector2i(4, 2)), "la porte se dégage")


func _texts(variant: DialogueVariant) -> Array:
	var texts: Array = []
	for page: DialoguePage in variant.pages:
		texts.append(page.text)
	return texts
