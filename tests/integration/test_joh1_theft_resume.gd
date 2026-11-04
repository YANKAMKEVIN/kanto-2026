extends GutTest
## JOH1 (bloquant de la QA A17 du 2026-11-04) : le **vrai Boot** joue l'arrivée au Centre
## d'Oliville jusqu'à l'écriture du vol, puis une **nouvelle** partie reprend sur la sauvegarde
## écrite (comme si l'application avait été tuée juste après) :
## - l'infirmière du comptoir lance la scène dès l'entrée (variante « auto ») ;
## - la sauvegarde du vol porte `johto_team_stolen` (sinon : chambre de nuit sans Orme, impasse),
##   la carte de la chambre, une équipe vide, la section `confiscated`, et garde la CS03 ;
## - à la reprise (Continuer) : chambre le matin, l'infirmière parle d'elle-même (O-10), Orme
##   propose les trois Pokémon, la légende du choix s'affiche, l'offre est ouverte.
## Système de fichiers en mémoire : jamais le vrai `user://`.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tests/fixtures/debug_start/johto_olivine_night_autosave.json"
const SAVE_PATH := "user://test_joh1_theft_save.json"
const SETTINGS_PATH := "user://test_joh1_theft_settings.json"
const ABSENT := "user://test_joh1_theft_absent.json"
const TIMEOUT := 20.0

var _fs: MemoryFs
var _boot: Boot
var _previous_scene: Node


func before_each() -> void:
	_fs = MemoryFs.new()
	_previous_scene = get_tree().current_scene
	# Midi : l'heure réelle serait le jour ; la nuit puis le matin viennent de l'histoire.
	GameState.clock = FixedClock.new("2026-11-04T12:00:00")


func after_each() -> void:
	_free_boot()
	GameState.clock = DeviceClock.new()


func _free_boot() -> void:
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null


func _launch(debug_start: String) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.debug_start_path = debug_start
	_boot.debug_unlocks_path = ABSENT
	_boot.force_debug_start = debug_start != ABSENT
	_boot.opening_speed_scale = 0.0
	var boot := _boot
	boot.tree_entered.connect(func() -> void: get_tree().current_scene = boot,
		CONNECT_ONE_SHOT)
	get_tree().root.add_child(boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)


func _saved() -> Dictionary:
	if not _fs.files.has(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(_fs.files[SAVE_PATH])
	return parsed if parsed is Dictionary else {}


## Fait défiler les dialogues jusqu'à ce que [param done] soit vrai (ou le délai de garde).
func _advance_until(done: Callable) -> void:
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)  # temps réel : délai de garde
	while not done.call() and Time.get_ticks_msec() < deadline:  # temps réel : délai de garde
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)


func test_the_theft_save_resumes_in_the_morning_with_orme() -> void:
	await _launch(START)
	assert_eq(_boot.get_map().map_id, &"olivine_center")
	# L'infirmière lance la scène dès l'entrée, sans un pas.
	await wait_until(func() -> bool: return _boot.get_cutscene_director().is_running(), TIMEOUT)
	assert_eq(_boot.get_cutscene_director().get_cutscene_id(), &"olivine_center_arrival")
	await _advance_until(func() -> bool:
		return (_saved().get("flags", []) as Array).has("johto_team_stolen"))
	var saved := _saved()
	assert_true((saved.get("flags", []) as Array).has("johto_team_stolen"),
		"le drapeau du matin est dans l'écriture du vol")
	assert_eq(saved.get("map"), "olivine_center_room", "écrite dans la chambre")
	assert_eq((saved.get("party", [1]) as Array).size(), 0, "équipe vide")
	assert_true(saved.has("confiscated"), "équipe et Sac confisqués")
	# Quantités du Sac (le rang d'obtention, gardé, n'est pas une quantité).
	var counts: Dictionary = (saved.get("bag", {}) as Dictionary).get(Bag.ITEMS_KEY, {})
	assert_true(counts.has("hm03"), "la CS03 reste au Sac (QA A17 : sinon rendue en double)")
	assert_false(counts.has("potion"), "les Potions sont volées")
	assert_eq(saved.get("heal_map"), "olivine_center", "point de repos d'Oliville (soin)")
	# L'application est tuée ici : une nouvelle partie reprend sur ce fichier.
	_free_boot()
	await wait_process_frames(2)
	await _launch(ABSENT)
	var title := _boot.get_opening().get_screen()
	assert_not_null(title, "écran titre")
	if title == null:
		return
	title.get_entry_button(&"continue").pressed.emit()
	await wait_until(func() -> bool: return _boot.get_opening().is_finished(), TIMEOUT)
	await wait_process_frames(2)
	assert_true(_boot.has_resumed(), "partie reprise")
	assert_eq(_boot.get_map().map_id, &"olivine_center_room")
	assert_eq(_boot.get_world_clock().period(), WorldClock.Period.MORNING, "matin imposé")
	assert_not_null(_boot.get_map().get_npc(&"orme"), "Orme est là")
	assert_not_null(_boot.get_map().get_npc(&"infirmiere"), "l'infirmière est là")
	# Elle parle d'elle-même (O-10) : la scène du matin.
	await wait_until(func() -> bool: return _boot.get_dialogue_runner().is_running() \
		or _boot.get_cutscene_director().is_running(), TIMEOUT)
	var caption := _boot.get_hud().get_caption()
	await _advance_until(func() -> bool:
		return GameState.flags.has_flag(&"johto_starter_offered") \
			and not _boot.get_cutscene_director().is_running())
	assert_true(GameState.flags.has_flag(&"johto_starter_offered"), "Orme a fait son offre")
	await wait_process_frames(3)
	assert_true(_boot.get_johto_starter_choice().is_open(), "le choix est ouvert")
	assert_true(caption.is_showing(), "légende du choix affichée")
	assert_eq(caption.text, "CHOISIS TON PARTENAIRE DE JOHTO")
