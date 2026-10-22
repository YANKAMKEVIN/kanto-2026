extends GutTest
## Jalon 21 (T20, `jalon-21.md` §2.10, §5 n° 9, 12 ; dossier 24 §8, §15.6, §15.7) : le Ronflex du
## croisement de la Route 12 (M-3) sur la **vraie scène Boot**, départ `route_12_qa` (équipe
## N25-33, Flûte et Scope au Sac), joueur posé sur les cases `face_ronflex` de la grille :
## - sans la Flûte : T-6 puis T-7 (textes du J17, mot pour mot), passage fermé ;
## - avec la Flûte, en parlant : « Jouer de la Poké Flûte ? » ; NON → rien ; OUI → réveil → combat ;
## - Sac → UTILISER la Flûte depuis chaque case `face_ronflex` (nord, ouest, sud) → réveil ; à deux
##   cases → « ailleurs » (§15.6.6), aucun réveil ;
## - les quatre issues (K.O., capture, fuite, défaite) : `_awake` toujours effacé, `_woken` gardé,
##   `_done` / `_caught` selon l'issue, chacune relue après un aller-retour de sauvegarde ;
##   l'autre Ronflex (Route 16) n'est jamais touché ;
## - après `_done`, les cases de Ronflex sont praticables (le joueur les traverse).

const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const START := "res://tools/debug_start/route_12_qa.json"
const SAVE_PATH := "user://test_snorlax_route_12_save.json"
const FADE := 0.05
const TIMEOUT := 30.0
const FLUTE := &"poke_flute"
const BALL := &"poke_ball"
const WAKE := &"snorlax_route_12_wake"
const AWAKE := &"snorlax_route_12_awake"
const WOKEN := &"snorlax_route_12_woken"
const DONE := &"snorlax_route_12_done"
const CAUGHT := &"snorlax_route_12_caught"
const SEEN := &"snorlax_route_12_seen"
const SNORLAX: Array[Vector2i] = [Vector2i(25, 93), Vector2i(26, 93), Vector2i(25, 94),
	Vector2i(26, 94)]
## Cases `face_ronflex` de la grille (nord ↓, ouest →, sud ↑).
const FACES: Array = [[Vector2i(25, 92), Vector2i.DOWN], [Vector2i(24, 93), Vector2i.RIGHT],
	[Vector2i(25, 95), Vector2i.UP]]
const NORTH_FACE := Vector2i(25, 92)
## Textes du J17 (T-6, T-7) repris par la Route 12, et dossier 24 §15.6, §15.7.
const T6: Array[String] = ["Un énorme Pokémon dort au milieu du chemin.",
	"Il ne bouge pas d'un pouce."]
const T7: Array[String] = ["Il ronfle paisiblement.", "Rien ne semble pouvoir le réveiller."]
const ASK: String = "Jouer de la Poké Flûte ?"
const AGAIN: Array[String] = ["Ronflex dort de nouveau.", "Il ronfle comme si de rien n'était."]
const WAKES: Array[String] = ["Ronflex se réveille !", "Il attaque, de très mauvaise humeur !"]
const CALMS: Array[String] = ["Ronflex se calme…",
	"Avec un grand bâillement, il retourne dans les montagnes."]
const SLEEPS: Array[String] = ["Ronflex bâille…", "et se rendort aussitôt."]
const ELSEWHERE_END: String = "Quel air entraînant !"


## Aléatoire « toujours 1 » : la Ball prend à coup sûr (capture déterministe).
class LowRng extends GameRng:
	func roll(_n: int) -> int:
		return 1


var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _fades: Array = []
var _saved_rng: GameRng
var _flute_scenes: Array[StringName] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-22T03:30:00")
	_saved_rng = GameState.rng
	_pages.clear()
	_flute_scenes.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	GameState.rng = _saved_rng
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _start(with_flute: bool = true) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_12"
	_boot.start_spawn = &"from_lavender"
	_boot.start_facing = Vector2i.DOWN
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	if not with_flute:
		GameState.bag.remove(FLUTE)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_map().apply_flag_gates(GameState.flags)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	_boot.get_key_item_director().flute_played.connect(
		func(id: StringName) -> void: _flute_scenes.append(id))
	_boot.get_encounter_director().enabled = false


func _place(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


## Indice de la première capacité offensive qui ne rate jamais (précision 100 ou 0).
func _strike_index() -> int:
	var data := _boot.get_pokemon_data()
	var moves := GameState.party.get_lead().moves
	for i: int in moves.size():
		var move := data.get_move(moves[i].move_id)
		if move != null and move.power > 0 and (move.accuracy == 100 or move.accuracy == 0):
			return i
	return 0


## Mène dialogues, choix ([param confirm]) et combat ([param plan] : &"win", &"catch", &"flee",
## &"lose") jusqu'à la fin. Renvoie l'issue du combat (NONE sans combat).
func _play_out(confirm: bool, plan: StringName) -> int:
	var cutscenes := _boot.get_cutscene_director()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var box := _boot.get_dialogue_box()
	var outcome: Array[int] = [Battle.Outcome.NONE]
	var on_finished := func(_id: StringName, o: int) -> void: outcome[0] = o
	battles.battle_finished.connect(on_finished)
	var ball_thrown := false
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	await wait_process_frames(3)
	while (cutscenes.is_running() or _runner.is_running() or box.is_open()
			or battles.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		var card := battles.get_capture_card()
		if card != null and card.is_waiting():
			card.skip()
		var battle := battles.get_battle() if battles.is_running() else null
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			var foe := battle.get_foe_side().active.pokemon
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					if plan == &"flee":
						hud.action_selected.emit(ActionGrid.RUN)
					elif plan == &"catch" and not ball_thrown:
						ball_thrown = true
						hud.action_selected.emit(ActionGrid.BAG)
						await wait_until(func() -> bool:
							var panel := battles.get_bag_panel()
							return panel != null \
								and not panel.item_chosen.get_connections().is_empty(), 5.0)
						battles.get_bag_panel().item_chosen.emit(BALL)
					else:
						if plan == &"win":
							foe.hp = 1
						elif plan == &"lose":
							foe.hp = foe.max_hp()
						hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(_strike_index() if plan == &"win" else 0)
		await wait_process_frames(1)
		if box.is_choice_showing():
			var cards := box.get_choice_cards()
			(cards.get_confirm_button() if confirm else cards.get_cancel_button()).pressed.emit()
		elif box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
	battles.battle_finished.disconnect(on_finished)
	assert_false(cutscenes.is_running(), "scène finie")
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(5)
	return outcome[0]


func _talk(confirm: bool = false, plan: StringName = &"flee") -> int:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	return await _play_out(confirm, plan)


func _use_flute(plan: StringName = &"flee") -> int:
	_boot.get_menu_director().key_item_requested.emit(FLUTE)
	return await _play_out(true, plan)


## Aller-retour de sauvegarde (`GameState.to_dict` / `load_dict`).
func _reload() -> void:
	var saved := GameState.to_dict()
	GameState.new_game(5)
	assert_true(GameState.load_dict(saved, _boot.get_pokemon_data()), "partie relue")


func _route_16_untouched() -> void:
	for flag: StringName in [&"snorlax_route_16_awake", &"snorlax_route_16_woken",
			&"snorlax_route_16_done", &"snorlax_route_16_caught"]:
		assert_false(GameState.flags.has_flag(flag), "Ronflex 16 inchangé : %s" % flag)


func _blocked() -> bool:
	var grid := _boot.get_map().get_grid()
	for cell: Vector2i in SNORLAX:
		if not grid.is_occupied(cell):
			return false
	return true


# --- Sans la Flûte ---------------------------------------------------------------------------


func test_without_the_flute_t6_then_t7_and_the_passage_stays_closed() -> void:
	await _start(false)
	assert_false(GameState.bag.has(FLUTE))
	await _place(NORTH_FACE, Vector2i.DOWN)
	await _talk()
	assert_eq(_pages, T6, "T-6 (J17)")
	assert_true(GameState.flags.has_flag(SEEN))
	_pages.clear()
	await _talk()
	assert_eq(_pages, T7, "T-7 (J17)")
	assert_true(_blocked(), "passage fermé")
	assert_false(GameState.flags.has_flag(AWAKE) or GameState.flags.has_flag(WOKEN))
	assert_push_error_count(0)


# --- Avec la Flûte : parler ------------------------------------------------------------------


func test_talking_with_the_flute_asks_no_does_nothing_yes_wakes_and_fights() -> void:
	await _start()
	await _place(NORTH_FACE, Vector2i.DOWN)
	var none := await _talk(false)
	assert_eq(none, Battle.Outcome.NONE, "NON : aucun combat")
	assert_eq(_pages, [ASK] as Array[String])
	assert_false(GameState.flags.has_flag(WOKEN), "NON : rien")
	_pages.clear()
	var outcome := await _talk(true, &"flee")
	assert_eq(outcome, Battle.Outcome.FLED, "OUI : réveil puis combat")
	var expected: Array[String] = [ASK, "%s joue de la Poké Flûte." % GameState.player_name]
	expected.append_array(WAKES)
	expected.append_array(SLEEPS)
	assert_eq(_pages, expected, "§15.6.3, §15.7.2, §15.7.4")
	assert_true(GameState.flags.has_flag(WOKEN))
	# Rendormi : §15.7.5 puis la question (§16 n° 9 : réveil à volonté).
	_pages.clear()
	await _talk(false)
	var again := AGAIN.duplicate()
	again.append(ASK)
	assert_eq(_pages, again, "§15.7.5")
	assert_push_error_count(0)


# --- Avec la Flûte : le Sac ------------------------------------------------------------------


func test_the_flute_from_the_bag_wakes_him_from_each_face_cell_only() -> void:
	await _start()
	for face: Array in FACES:
		await _place(face[0], face[1])
		_flute_scenes.clear()
		var outcome := await _use_flute(&"flee")
		assert_eq(_flute_scenes, [WAKE] as Array[StringName], "réveil depuis %s" % face[0])
		assert_eq(outcome, Battle.Outcome.FLED, "combat depuis %s" % face[0])
		assert_false(GameState.flags.has_flag(AWAKE), "`_awake` effacé")
	# À deux cases : la Flûte joue « ailleurs ».
	await _place(NORTH_FACE + Vector2i.UP, Vector2i.DOWN)
	_flute_scenes.clear()
	_pages.clear()
	var outcome := await _use_flute()
	assert_eq(outcome, Battle.Outcome.NONE, "aucun combat")
	assert_eq(_flute_scenes, [&""] as Array[StringName], "« ailleurs »")
	assert_eq(_pages.back() if not _pages.is_empty() else "", ELSEWHERE_END, "§15.6.6")
	assert_eq(GameState.bag.count_of(FLUTE), 1, "la Flûte reste au Sac")
	assert_push_error_count(0)


# --- Les quatre issues -----------------------------------------------------------------------


func test_knock_out_clears_awake_keeps_woken_and_frees_the_cells() -> void:
	await _start()
	await _place(NORTH_FACE, Vector2i.DOWN)
	var outcome := await _use_flute(&"win")
	assert_eq(outcome, Battle.Outcome.WIN)
	assert_eq(_pages.slice(-2), CALMS, "§15.7.3")
	_reload()
	for flag: StringName in [WOKEN, DONE]:
		assert_true(GameState.flags.has_flag(flag), String(flag))
	assert_false(GameState.flags.has_flag(AWAKE), "`_awake` jamais sur disque")
	assert_false(GameState.flags.has_flag(CAUGHT))
	_route_16_untouched()
	_boot.get_map().apply_flag_gates(GameState.flags)
	assert_false(_blocked(), "cases libres")
	# Le joueur traverse les cases de Ronflex vers le sud.
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return _player.get_cell().y >= 95, TIMEOUT)
	Input.action_release(&"move_down")
	assert_gte(_player.get_cell().y, 95, "traversée")
	assert_push_error_count(0)


func test_capture_sets_done_and_caught_and_the_snorlax_joins() -> void:
	await _start()
	await _place(NORTH_FACE, Vector2i.DOWN)
	var before := GameState.party.size() + GameState.storage.size()
	GameState.rng = LowRng.new(0)
	var outcome := await _use_flute(&"catch")
	GameState.rng = _saved_rng
	assert_eq(outcome, Battle.Outcome.CAUGHT)
	assert_does_not_have(_pages, CALMS[0], "aucun texte après la capture")
	assert_does_not_have(_pages, SLEEPS[0])
	_reload()
	for flag: StringName in [WOKEN, DONE, CAUGHT]:
		assert_true(GameState.flags.has_flag(flag), String(flag))
	assert_false(GameState.flags.has_flag(AWAKE))
	assert_eq(GameState.party.size() + GameState.storage.size(), before + 1)
	var found := false
	for pokemon: Pokemon in GameState.party.get_all() + GameState.storage.get_all():
		found = found or pokemon.species_id == &"snorlax"
	assert_true(found, "Ronflex dans l'équipe ou le Stockage (équipe pleine : Stockage)")
	_route_16_untouched()
	_boot.get_map().apply_flag_gates(GameState.flags)
	assert_false(_blocked(), "cases libres")
	assert_push_error_count(0)


func test_flee_clears_awake_and_he_stays() -> void:
	await _start()
	await _place(NORTH_FACE, Vector2i.DOWN)
	var outcome := await _use_flute(&"flee")
	assert_eq(outcome, Battle.Outcome.FLED)
	assert_eq(_pages.slice(-2), SLEEPS, "§15.7.4")
	_reload()
	assert_true(GameState.flags.has_flag(WOKEN))
	assert_false(GameState.flags.has_flag(AWAKE))
	assert_false(GameState.flags.has_flag(DONE))
	_route_16_untouched()
	assert_true(_blocked(), "il reste")
	assert_push_error_count(0)


func test_defeat_clears_awake_before_waking_at_the_center() -> void:
	await _start()
	# Une seule Pokémon à 1 PV : le premier coup de Ronflex finit le combat.
	while GameState.party.size() > 1:
		GameState.party.remove_at(GameState.party.size() - 1)
	GameState.party.get_lead().hp = 1
	await _place(NORTH_FACE, Vector2i.DOWN)
	var outcome := await _use_flute(&"lose")
	assert_eq(outcome, Battle.Outcome.LOSS)
	await wait_until(func() -> bool: return (_boot.get_map().map_id == &"lavender_center"
		and _boot.is_stable()), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"lavender_center", "réveil au Centre")
	_reload()
	assert_true(GameState.flags.has_flag(WOKEN))
	assert_false(GameState.flags.has_flag(AWAKE), "effacé avant le réveil")
	assert_false(GameState.flags.has_flag(DONE), "il dort toujours")
	_route_16_untouched()
	assert_push_error_count(0)
