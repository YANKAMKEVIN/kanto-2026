extends GutTest
## Jalon 21 (T12, `jalon-21.md` §2.7, §5 n° 1, 2 ; dossier 24 §5, §15.1) : le 6F de la Tour en
## version « révélation » sur la **vraie scène Boot**, départs `tower_marowak_qa` (Scope au Sac,
## équipe N25-33), `tower_marowak_weak` (Salamèche N8) et `tower_marowak_noscope` (sans Scope),
## case `devant_spectre` (10, 14), texte et combat instantanés :
## - avec le Scope : pas sur (10, 16) → « …Va-t'en… Intrus… » → combat révélé (« Le Scope Sylphe
##   révèle… », « C'est un Ossatueur ! ») → victoire → §15.1.6 → `SpiritLight` → §15.1.7 →
##   `tower_6f_mist_lifted` ; brume légère visible, dense cachée ; le pas sur (10, 16) ne joue plus
##   rien ;
## - fuite : recul en (10, 15), « Quelque chose retient encore l'esprit… » (§15.1.5) ; on
##   recommence : combat neuf, PV pleins (§16 n° 2) ;
## - défaite : réveil au Centre de Lavanville, `ghost_marowak_calmed` absent, déclencheur réarmé ;
## - Ball refusée (« Ce Pokémon ne peut pas être capturé. »), non consommée, aucun tour ;
## - sans le Scope : déroulé du J19, mot pour mot (SPECTRE, « Quelque chose refuse qu'on
##   passe. ») ;
## - « Réduire les animations » : textes et brume gardés, lumière sautée.

const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const START_QA := "res://tools/debug_start/tower_marowak_qa.json"
const START_WEAK := "res://tools/debug_start/tower_marowak_weak.json"
const START_NOSCOPE := "res://tools/debug_start/tower_marowak_noscope.json"
const SAVE_PATH := "user://test_tower_6f_marowak_save.json"
const FADE := 0.05
const TIMEOUT := 30.0
const FROM := Vector2i(10, 14)
const TRIGGER := Vector2i(10, 16)
const BACK := Vector2i(10, 15)
const FOE := &"marowak"
const BALL := &"poke_ball"
const CALMED := &"ghost_marowak_calmed"
const LIFTED := &"tower_6f_mist_lifted"
## Dossier 24 §15.1 (J19 §15.3.7 pour l'avertissement, inchangé).
const WARNING: String = "…Va-t'en… Intrus…"
const HELD: String = "Quelque chose retient encore l'esprit…"
const SOUL: String = "Le SPECTRE était l'âme de la mère d'Osselait…"
const PEACE: String = "Son âme s'est apaisée. / Elle est partie en paix."
const REVEALED := "Le Scope Sylphe révèle l'identité du SPECTRE !"
const UNCATCHABLE := "Ce Pokémon ne peut pas être capturé."
## J19 (dossier 22 §15.3.8) : la variante B, sans le Scope.
const GHOST_AFTER: String = "Quelque chose refuse qu'on passe."

var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _shown_lines: Array[String] = []
var _fades: Array = []
## Le halo `SpiritLight` s'est-il montré pendant la scène (étape « animate ») ?
var _light_seen: bool = false
## PV de l'adversaire au premier choix de chaque combat : [PV, PV max].
var _foe_hp_at_start: Array = []
## Ball choisie : [tour, état] juste après le refus.
var _after_ball: Array = []
## Combats vus (un relevé de PV par combat).
var _battles_counted: Array[Battle] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-22T03:00:00")
	_pages.clear()
	_shown_lines.clear()
	_foe_hp_at_start.clear()
	_after_ball.clear()
	_battles_counted.clear()
	_light_seen = false


func after_each() -> void:
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)


func _start(path: String) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.force_debug_start = true
	_boot.debug_start_path = path
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	_boot.get_battle_hud().get_message_banner().message_shown.connect(
		func(text: String, _wait: bool) -> void: _shown_lines.append(text))
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text().replace("\n", " / ")))
	# Rencontres du sol du 6F coupées : le test porte sur la scène scriptée (comme le J19).
	_boot.get_encounter_director().enabled = false


func _map() -> GameMap:
	return _boot.get_map()


## Indice de la première capacité offensive qui ne rate jamais (précision 100 ou 0).
func _strike_index() -> int:
	var data := _boot.get_pokemon_data()
	var moves := GameState.party.get_lead().moves
	for i: int in moves.size():
		var move := data.get_move(moves[i].move_id)
		if move != null and move.power > 0 and (move.accuracy == 100 or move.accuracy == 0):
			return i
	return 0


## Un pas vers le sud depuis [param from] jusqu'au déclencheur, puis la scène jusqu'à sa fin, le
## combat mené par [param plan] : &"flee", &"win", &"lose" ou &"ball" (une Ball, puis la fuite).
## Renvoie l'issue du combat (NONE sans combat).
func _walk_into_the_ghost(from: Vector2i, plan: StringName) -> int:
	var cutscenes := _boot.get_cutscene_director()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var box := _boot.get_dialogue_box()
	var outcome: Array[int] = [Battle.Outcome.NONE]
	var on_finished := func(_id: StringName, o: int) -> void: outcome[0] = o
	battles.battle_finished.connect(on_finished)
	if _player.get_cell() != from:
		_map().spawn_player_at(_player, from, Vector2i.DOWN)
		await wait_process_frames(3)
	var light := _map().get_node_or_null(^"SpiritLight") as Node2D
	Input.action_press(&"move_down")
	await wait_until(func() -> bool: return cutscenes.is_running() or _player.get_cell() == TRIGGER,
		TIMEOUT)
	Input.action_release(&"move_down")
	var ball_done := false
	var battle_seen: Battle = null
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (cutscenes.is_running() or _runner.is_running() or battles.is_running()
			or SceneRouter.is_transitioning()) and Time.get_ticks_msec() < deadline:
		if is_instance_valid(light) and light.visible:
			_light_seen = true
		var battle := battles.get_battle() if battles.is_running() else null
		if battle != null and battle != battle_seen:
			battle_seen = battle
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			var foe := battle.get_foe_side().active.pokemon
			if _foe_hp_at_start.size() < 2 * _rounds_started(battle):
				_foe_hp_at_start.append_array([foe.hp, foe.max_hp()])
			match hud.get_zone():
				BattleHud.Zone.ACTIONS:
					if plan == &"ball" and not ball_done:
						ball_done = true
						await _throw_refused_ball(battle)
					elif plan == &"flee" or plan == &"ball":
						hud.action_selected.emit(ActionGrid.RUN)
					else:
						if plan == &"win":
							foe.hp = 1
						hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					hud.move_selected.emit(_strike_index() if plan == &"win" else 0)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	battles.battle_finished.disconnect(on_finished)
	assert_false(cutscenes.is_running(), "scène finie")
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(10)
	return outcome[0]



## Nombre de combats vus jusqu'ici, [param battle] compris.
func _rounds_started(battle: Battle) -> int:
	if not _battles_counted.has(battle):
		_battles_counted.append(battle)
	return _battles_counted.size()


## SAC → Poké Ball : refusée ; relève le tour et l'état juste après.
func _throw_refused_ball(battle: Battle) -> void:
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	hud.action_selected.emit(ActionGrid.BAG)
	await wait_until(func() -> bool:
		var panel := battles.get_bag_panel()
		return panel != null and not panel.item_chosen.get_connections().is_empty(), 5.0)
	battles.get_bag_panel().item_chosen.emit(BALL)
	await wait_until(func() -> bool: return hud.get_zone() == BattleHud.Zone.ACTIONS, 5.0)
	_after_ball = [battle.get_turn(), battle.get_state()]


func _mists() -> Array[bool]:
	var dense := _map().get_node(^"MistDenseGate") as CanvasItem
	var light := _map().get_node(^"MistLightGate") as CanvasItem
	return [dense.visible, light.visible]


# --- Avec le Scope ---------------------------------------------------------------------------


func test_victory_reveals_marowak_then_calms_the_spirit_and_lifts_the_mist() -> void:
	await _start(START_QA)
	assert_true(GameState.bag.has(&"silph_scope"), "Scope au Sac")
	assert_eq(_mists(), [true, false] as Array[bool], "avant : brume dense")
	var objectives := ObjectiveLibrary.new()
	assert_true(objectives.load_file(), "\n".join(objectives.get_errors()))
	var outcome := await _walk_into_the_ghost(FROM, &"win")
	assert_eq(outcome, Battle.Outcome.WIN, "Ossatueur vaincu")
	var name := _boot.get_pokemon_data().get_species(FOE).name
	var revealed_at := _shown_lines.find(REVEALED)
	assert_gt(revealed_at, -1, "« Le Scope Sylphe révèle… »")
	assert_gt(_shown_lines.find("C'est un %s !" % name), revealed_at, "puis « C'est un Ossatueur ! »")
	assert_does_not_have(_shown_lines, "Un SPECTRE apparaît !")
	assert_eq(_pages, [WARNING, SOUL, PEACE] as Array[String], "§15.1.1, §15.1.6, §15.1.7")
	assert_true(_light_seen, "la lumière de l'esprit monte")
	assert_true(GameState.flags.has_flag(CALMED), "Ossatueur apaisé")
	assert_true(GameState.flags.has_flag(LIFTED), "brume levée")
	assert_eq(_mists(), [false, true] as Array[bool], "brume légère visible, dense cachée")
	assert_eq(_player.get_cell(), TRIGGER, "pas de recul après la victoire")
	assert_eq(objectives.current_id(GameState.flags), &"find_fuji", "« trouver M. Fuji… »")
	assert_true(GameState.pokedex.is_seen(FOE), "Ossatueur « vu »")
	# Après : aucune variante ne s'applique, le pas sur (10, 16) ne joue plus rien.
	_pages.clear()
	var scene := _boot.get_cutscene_library().get_cutscene(&"tower_6f_ghost")
	assert_null(scene.pick(GameState.flags, GameState.bag), "aucune variante après")
	var again := await _walk_into_the_ghost(FROM, &"flee")
	assert_eq(again, Battle.Outcome.NONE, "plus de combat")
	assert_eq(_pages, [] as Array[String], "plus de texte")
	assert_eq(_player.get_cell(), TRIGGER)
	assert_push_error_count(0)


func test_flee_pushes_back_with_the_held_text_and_the_next_fight_is_fresh() -> void:
	await _start(START_QA)
	var outcome := await _walk_into_the_ghost(FROM, &"flee")
	assert_eq(outcome, Battle.Outcome.FLED, "la fuite réussit")
	assert_eq(_pages, [WARNING, HELD] as Array[String], "§15.1.1 puis §15.1.5")
	assert_eq(_player.get_cell(), BACK, "recul en (10, 15)")
	assert_false(GameState.flags.has_flag(CALMED))
	assert_false(GameState.flags.has_flag(LIFTED))
	assert_false(_light_seen, "aucune lumière")
	assert_eq(_mists(), [true, false] as Array[bool], "brume dense gardée")
	assert_true(_player.is_input_enabled(), "contrôle rendu")
	# On recommence : combat neuf, PV pleins (§16 n° 2).
	_pages.clear()
	var second := await _walk_into_the_ghost(BACK, &"flee")
	assert_eq(second, Battle.Outcome.FLED)
	assert_eq(_pages, [WARNING, HELD] as Array[String], "même déroulé")
	assert_eq(_foe_hp_at_start.size(), 4, "deux combats")
	if _foe_hp_at_start.size() == 4:
		assert_eq(_foe_hp_at_start[2], _foe_hp_at_start[3], "second combat : PV pleins")
	assert_push_error_count(0)


func test_the_ball_is_refused_and_not_spent() -> void:
	await _start(START_QA)
	var balls := GameState.bag.count_of(BALL)
	assert_gt(balls, 0)
	var outcome := await _walk_into_the_ghost(FROM, &"ball")
	assert_eq(outcome, Battle.Outcome.FLED)
	assert_has(_shown_lines, UNCATCHABLE, "§2.6")
	assert_eq(_after_ball, [0, Battle.State.CHOOSING], "aucun tour joué au refus")
	assert_eq(GameState.bag.count_of(BALL), balls, "Ball non consommée")
	assert_push_error_count(0)


func test_defeat_wakes_at_the_lavender_center_and_rearms_the_trigger() -> void:
	await _start(START_WEAK)
	var outcome := await _walk_into_the_ghost(FROM, &"lose")
	assert_eq(outcome, Battle.Outcome.LOSS, "défaite")
	await wait_until(func() -> bool: return (_map().map_id == &"lavender_center"
		and _boot.is_stable()), TIMEOUT)
	assert_eq(_map().map_id, &"lavender_center", "réveil au Centre de Lavanville")
	assert_false(GameState.flags.has_flag(CALMED), "drapeau non posé")
	assert_false(GameState.flags.has_flag(LIFTED))
	assert_does_not_have(_pages, HELD, "la scène s'arrête au réveil")
	# Déclencheur réarmé : la variante A s'applique toujours, la case garde son déclencheur.
	var scene := _boot.get_cutscene_library().get_cutscene(&"tower_6f_ghost")
	assert_same(scene.pick(GameState.flags, GameState.bag), scene.variants[0], "variante A")
	SceneRouter.change_map(&"pokemon_tower_6f", &"devant_spectre", Vector2i.DOWN)
	await wait_until(func() -> bool: return (_map().map_id == &"pokemon_tower_6f"
		and _boot.is_stable() and not SceneRouter.is_transitioning()), TIMEOUT)
	var triggers := _map().get_triggers().get_at(TRIGGER)
	assert_eq(triggers.size(), 1)
	if not triggers.is_empty():
		assert_eq(triggers[0].cutscene_id, &"tower_6f_ghost")
	assert_push_error_count(0)


func test_reduced_motion_keeps_texts_and_mist_but_skips_the_light() -> void:
	await _start(START_QA)
	_boot.get_cutscene_director().reduce_motion = true
	_boot.get_battle_stage().reduce_motion = true
	var outcome := await _walk_into_the_ghost(FROM, &"win")
	assert_eq(outcome, Battle.Outcome.WIN)
	assert_eq(_pages, [WARNING, SOUL, PEACE] as Array[String], "textes gardés")
	assert_false(_light_seen, "lumière sautée")
	assert_true(GameState.flags.has_flag(LIFTED))
	assert_eq(_mists(), [false, true] as Array[bool], "brume légère gardée")
	assert_push_error_count(0)


# --- Sans le Scope : le J19, inchangé --------------------------------------------------------


func test_without_the_scope_the_jalon_19_ghost_is_unchanged() -> void:
	await _start(START_NOSCOPE)
	assert_false(GameState.bag.has(&"silph_scope"))
	var outcome := await _walk_into_the_ghost(FROM, &"flee")
	assert_eq(outcome, Battle.Outcome.FLED)
	assert_eq(_pages, [WARNING, GHOST_AFTER] as Array[String], "J19 mot pour mot")
	assert_has(_shown_lines, "Un SPECTRE apparaît !")
	assert_does_not_have(_shown_lines, REVEALED)
	assert_eq(_player.get_cell(), BACK)
	assert_false(GameState.flags.has_flag(CALMED))
	assert_eq(_mists(), [true, false] as Array[bool])
	assert_push_error_count(0)
