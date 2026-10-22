extends GutTest
## Activation de Force dans la vraie partie (passe systèmes 2, `systemes-2.md` §2.7.1, T18) : la
## vraie scène Boot sur la Route 1, un nœud `Boulders` posé en mémoire devant le joueur, l'état de
## la capacité imposé au lecteur de dialogues. EXAMINER face au rocher, variantes
## `strength:<état>` (T-5, T-6), UTILISER → T-7 et Force active, LAISSER → rien ; Force retombe au
## changement de carte (vrai routeur).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_strength_activation_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const T5 := "Un gros rocher. Il pourrait être déplacé."
const T6 := "Il faut le Badge Prisme pour utiliser Force hors des combats."
const T7 := "Carapuce utilise Force ! Les rochers peuvent être déplacés."

var _boot: Boot
var _fades: Array[float] = []
var _strength: StrengthDirector
var _player: Player
var _start: Vector2i
var _state: FieldMoves.State = FieldMoves.State.READY
var _pages: Array[String] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-21T10:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	var runner := _boot.get_dialogue_runner()
	runner.chars_per_second = 0.0
	runner.page_started.connect(func(_i: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.flags.set_flag(&"starter_chosen")
	_boot.get_encounter_director().enabled = false
	_strength = _boot.get_strength_director()
	_player = _boot.get_player()
	_start = _player.get_cell()
	_pages.clear()
	_state = FieldMoves.State.READY
	runner.field_source = func(_move: StringName) -> FieldMoves.Result:
		var result := FieldMoves.Result.new(_state, 0)
		result.pokemon_name = "Carapuce"
		return result
	# Un rocher juste devant le joueur, lu comme à l'arrivée sur une carte.
	var map := SceneRouter.get_current_map()
	map.get_grid().set_solid(_start + Vector2i.UP, false)
	var setup := BoulderSetup.new()
	setup.name = String(BoulderSetup.NODE_NAME)
	setup.boulder_cells = [_start + Vector2i.UP] as Array[Vector2i]
	map.add_child(setup)
	_strength.on_map_changed(map)


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	Input.action_release(&"interact")


## EXAMINER le rocher ; aux cartes UTILISER / LAISSER, répond [param confirm].
func _examine(confirm: bool) -> Array[String]:
	_pages.clear()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var deadline := Time.get_ticks_msec() + 20000
	while (runner.is_running() or box.is_open() or _strength.is_running()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_choice_showing():
			var cards := box.get_choice_cards()
			var button := cards.get_confirm_button() if confirm else cards.get_cancel_button()
			button.pressed.emit()
		elif box.is_open() and not runner.is_awaiting_choice():
			box.advance_requested.emit()
	await wait_process_frames(3)
	var pages: Array[String] = []
	pages.assign(_pages)
	return pages


func test_the_contextual_button_examines_the_boulder() -> void:
	await wait_process_frames(3)
	var target := _boot.get_interaction_controller().get_target()
	assert_not_null(target)
	assert_eq(target.kind, Interaction.Kind.EXAMINE)
	assert_eq(target.dialogue_id, &"strength_boulder")


func test_use_activates_strength_and_says_t7() -> void:
	var pages := await _examine(true)
	assert_eq(pages, [T5, T7] as Array[String])
	assert_true(_strength.is_active(), "Force active")
	assert_true(_player.is_input_enabled())
	await wait_process_frames(3)
	assert_null(_boot.get_interaction_controller().get_target(),
		"Force active : EXAMINER ne repropose rien [D]")


func test_leave_does_nothing() -> void:
	var pages := await _examine(false)
	assert_eq(pages, [T5] as Array[String])
	assert_false(_strength.is_active())


func test_without_the_badge_t6() -> void:
	_state = FieldMoves.State.NO_BADGE
	assert_eq(await _examine(true), [T6] as Array[String])
	assert_false(_strength.is_active())


func test_without_the_hm_t5_only() -> void:
	_state = FieldMoves.State.NO_HM
	assert_eq(await _examine(true), [T5] as Array[String])
	assert_false(_strength.is_active())


func test_strength_drops_on_the_next_map() -> void:
	await _examine(true)
	assert_true(_strength.is_active())
	SceneRouter.change_map(&"pallet_town", &"from_route_1_w", Vector2i.UP)
	await wait_until(func() -> bool:
		return not SceneRouter.is_transitioning() and _boot.is_stable(), TIMEOUT)
	assert_eq(SceneRouter.get_current_map().map_id, &"pallet_town")
	assert_false(_strength.is_active(), "Force retombe au changement de carte")
	assert_eq(_strength.get_boulders().size(), 0, "carte sans rochers")
