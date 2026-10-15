extends GutTest
## L'écran de la Pension (J15, T5 ; jalon-15.md §2.5.1) sur le vrai Boot : le choix du Pokémon à
## confier montre toute l'équipe, une place refusée garde sa raison et met T-5 en titre au
## toucher, ANNULER et le retour Android referment sans rien changer, une place valide confie le
## Pokémon et ferme l'écran. Le déroulé du dépôt est joué par le vrai gardien.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_daycare_overlay_save.json"
const TIMEOUT := 15.0
const FADE := 0.05
const T5 := "Tu ne peux pas partir sans un Pokémon en forme."

var _fs: MemoryFs
var _boot: Boot
var _runner: DialogueRunner
var _daycare: DaycareDirector
var _overlay: DaycareOverlay
var _data: PokemonData
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"viridian_center"
	_boot.start_spawn = &"heal"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	_daycare = _boot.get_daycare_director()
	_overlay = _boot.get_daycare_overlay()
	_overlay.speed_scale = 0.0
	_data = _boot.get_pokemon_data()
	await wait_until(func() -> bool: return not _fs.journal.is_empty(), TIMEOUT)
	GameState.new_game(15)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(level))


## Le gardien parle ; OUI à l'offre ; les pages défilent jusqu'à l'écran du dépôt.
func _open_pick() -> void:
	assert_true(_runner.play(DaycareLines.KEEPER, null, _boot.get_map()))
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while not _overlay.is_picking() and Time.get_ticks_msec() < deadline:
		if box.is_choice_showing():
			box.get_choice_cards().get_confirm_button().pressed.emit()
		elif box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_true(_overlay.is_picking(), "l'écran du dépôt est ouvert")
	assert_true(_daycare.is_picking())


func _finish() -> void:
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (_runner.is_running() or _daycare.is_running()) \
			and Time.get_ticks_msec() < deadline:
		if box.is_choice_showing():
			box.get_choice_cards().get_cancel_button().pressed.emit()
		elif box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_false(_daycare.is_running())


func test_single_pokemon_is_refused_with_its_reason() -> void:
	GameState.party.add(_mon(&"rattata", 5))
	await _open_pick()
	var picker := _overlay.get_picker()
	assert_eq(picker.get_title_text(), DaycarePickView.TITLE)
	var cards := picker.get_cards()
	assert_eq(cards.size(), 1)
	assert_eq(cards[0].get_reason_text(), StorageViews.LAST_POKEMON_TEXT)
	assert_false(cards[0].is_chevron_shown())
	cards[0].tapped.emit()
	assert_eq(picker.get_title_text(), T5, "T-5 en titre au toucher")
	assert_true(_overlay.is_picking(), "le choix reste ouvert")
	assert_true(GameState.daycare.is_empty())
	picker.get_cancel_button().pressed.emit()
	await wait_until(func() -> bool: return not _overlay.is_picking(), TIMEOUT)
	assert_false(_overlay.visible, "le voile se ferme")
	assert_true(GameState.daycare.is_empty(), "ANNULER ne change rien")
	await _finish()
	assert_eq(GameState.party.size(), 1)


func test_android_back_cancels() -> void:
	GameState.party.add(_mon(&"rattata", 5))
	GameState.party.add(_mon(&"pidgey", 5))
	await _open_pick()
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_until(func() -> bool: return not _overlay.is_picking(), TIMEOUT)
	assert_true(GameState.daycare.is_empty())
	await _finish()
	assert_eq(GameState.party.size(), 2)


func test_valid_card_deposits_and_closes() -> void:
	GameState.party.add(_mon(&"rattata", 5))
	GameState.party.add(_mon(&"pidgey", 5))
	await _open_pick()
	var cards := _overlay.get_picker().get_cards()
	assert_eq(cards.size(), 2)
	assert_true(cards[1].is_chevron_shown())
	assert_eq(cards[1].get_reason_text(), "")
	cards[1].tapped.emit()
	await wait_until(func() -> bool: return not _overlay.is_picking(), TIMEOUT)
	assert_false(GameState.daycare.is_empty())
	assert_eq(GameState.party.size(), 1)
	await _finish()
