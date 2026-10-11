extends GutTest
## Ouverture (OUV.1, dossier 13 §3, §3.7, §5, §7 ; docs/tech/ouverture.md §3) : Boot lancé **en
## scène courante** (comme par le moteur), sauvegarde et réglages sur un système de fichiers en
## mémoire (jamais le vrai `user://`), départ et déblocages de débogage absents.
## - sans sauvegarde, valide (partie de Kevin en v4), corrompue, plus récente : le titre qu'il faut ;
## - rien n'est écrit tant que le titre est affiché (ni autosave, ni arrière-plan, ni migration),
##   le décor ne passe pas par SceneRouter et ne touche pas GameState ;
## - Continuer reprend la partie ; Nouvelle partie (confirmée) copie l'ancienne dans
##   `save.previous.json`, écrit la nouvelle et entre dans la chambre comme avant ;
## - abandon avant le commit : l'ancienne sauvegarde intacte octet pour octet, et au relancement
##   le titre redemande la confirmation ;
## - un départ de débogage saute le titre.
## OUV.2 : Nouvelle partie joue l'introduction du Prof. Chen sur le labo en mode décor ; les
## prénoms choisis n'existent qu'en mémoire jusqu'au commit (abandon à chaque plan : rien
## d'écrit), puis arrivent dans la chambre, les étiquettes du prologue et le combat.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_ouv1_save.json"
const PREVIOUS_PATH := "user://test_ouv1_save.previous.json"
const SETTINGS_PATH := "user://test_ouv1_settings.json"
## Partie de Kevin en v4 (dérivée de sa partie S24 du J8, voir test_save_system).
const FIXTURE_V4 := "res://tests/fixtures/save/v4_kevin_s21.json"
const DEBUG_START := "res://tests/fixtures/debug_start/valid.json"
const ABSENT := "user://test_ouv1_absent.json"
const DATE := "2026-10-10T09:00:00"
const TIMEOUT := 10.0
const BEDROOM_CELL := Vector2i(3, 4)

var _fs: MemoryFs
var _boot: Boot
var _previous_scene: Node
var _map_entered: int = 0
var _fades: Array[float] = []


func before_each() -> void:
	_fs = MemoryFs.new()
	_map_entered = 0
	_previous_scene = get_tree().current_scene
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	GameState.clock = FixedClock.new(DATE)
	SceneRouter.map_entered.connect(_on_map_entered)


func after_each() -> void:
	SceneRouter.map_entered.disconnect(_on_map_entered)
	_kill_boot()
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _on_map_entered(_map: GameMap) -> void:
	_map_entered += 1


# --- Mise en place -------------------------------------------------------------------------

## Lance Boot comme le moteur le ferait (scène courante), sur le système de fichiers en mémoire.
func _launch(debug_start: String = ABSENT) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.settings_store = SettingsStore.new(_fs, SETTINGS_PATH)
	_boot.debug_start_path = debug_start
	_boot.debug_unlocks_path = ABSENT
	_boot.opening_speed_scale = 0.0
	var boot := _boot
	# Scène courante dès l'entrée dans l'arbre, avant _ready : la garde de Boot voit le moteur.
	boot.tree_entered.connect(func() -> void: get_tree().current_scene = boot,
		CONNECT_ONE_SHOT)
	get_tree().root.add_child(boot)
	assert_eq(get_tree().current_scene, boot, "Boot est la scène courante")
	await wait_process_frames(2)


## L'application est tuée (ou relancée) : Boot disparaît d'un coup, sans rien écrire de plus.
func _kill_boot() -> void:
	if is_instance_valid(_boot):
		get_tree().current_scene = _previous_scene
		_boot.free()
	_boot = null


func _opening() -> OpeningDirector:
	return _boot.get_opening()


func _title() -> TitleScreen:
	return _opening().get_screen()


func _put_save(text: String) -> void:
	_fs.files[SAVE_PATH] = text


func _fixture_text() -> String:
	return FileAccess.get_file_as_string(FIXTURE_V4)


## Opérations d'écriture (write, rename, remove) sur la sauvegarde et ses copies.
func _save_writes() -> Array[String]:
	var writes: Array[String] = []
	for entry: String in _fs.journal:
		if entry.contains("test_ouv1_save"):
			writes.append(entry)
	return writes


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


## Attend la fin de l'ouverture ; une introduction en cours est jouée jusqu'au bout avec
## [param player] et [param rival] (réponses « Oui »).
func _wait_finished(player: String = "Kevin", rival: String = "Régis") -> void:
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000.0)
	while not _opening().is_finished() and Time.get_ticks_msec() < deadline:
		_drive_intro(player, rival)
		await wait_process_frames(1)
	assert_true(_opening().is_finished(), "ouverture terminée")
	await wait_process_frames(2)


## Une action de l'introduction (s'il y en a une en cours) : prénom, Oui, ou toucher.
func _drive_intro(player: String, rival: String) -> void:
	var intro := _opening().get_intro()
	if intro == null or not intro.is_running():
		return
	if intro.is_waiting_for_name():
		var prompt := intro.get_reader().current().name
		intro.submit_name(player if prompt == IntroScript.PROMPT_PLAYER_NAME else rival)
	elif intro.is_waiting_for_choice():
		intro.answer(true)
	else:
		intro.advance()


## Joue l'introduction jusqu'à ce que [param done] soit vrai (ou la fin).
func _intro_until(done: Callable, player: String = "Kevin", rival: String = "Régis") -> void:
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000.0)
	while not done.call() and not _opening().is_finished() \
			and Time.get_ticks_msec() < deadline:
		_drive_intro(player, rival)
		await wait_process_frames(1)


## Nouvelle partie (confirmée s'il le faut) jusqu'au début de l'introduction.
func _start_intro() -> void:
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	if _title() != null and _title().get_confirm().is_showing():
		_title().get_confirm().get_confirm_button().pressed.emit()
	await wait_until(func() -> bool: return _opening().get_intro() != null, TIMEOUT)


# --- Sans sauvegarde -----------------------------------------------------------------------

func test_without_save_the_title_features_new_game_and_nothing_starts() -> void:
	await _launch()
	assert_not_null(_opening(), "l'ouverture est lancée")
	assert_true(_opening().is_active())
	var title := _title()
	assert_not_null(title)
	assert_eq(title.get_entries(), [&"new_game", &"settings"] as Array[StringName])
	assert_eq(title.get_featured(), &"new_game")
	assert_eq(title.get_message_text(), "")
	assert_null(SceneRouter.get_current_map(), "aucune carte de jeu")
	assert_false(_boot.get_hud().visible, "HUD d'exploration caché")
	assert_false(_boot._can_write(), "garde d'autosave fermée")


func test_the_backdrop_is_pallet_town_in_decor_mode() -> void:
	await _launch()
	var backdrop := _boot.get_title_backdrop()
	assert_not_null(backdrop)
	assert_eq(backdrop.get_map().map_id, &"pallet_town")
	assert_true(backdrop.get_camera().is_current(), "cadrage du titre")
	assert_null(SceneRouter.get_current_map(), "pas passé par SceneRouter")
	assert_eq(_map_entered, 0, "aucun map_entered")
	assert_eq(GameState.discovered_maps.size(), 0, "Bourg Palette pas découvert")
	assert_eq(GameState.current_map, &"")
	assert_eq(GameState.flags.size(), 0)


func test_nothing_is_written_while_the_title_is_shown() -> void:
	_put_save(_fixture_text())
	await _launch()
	_fs.journal.clear()
	await wait_process_frames(30)
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_boot.request_autosave("test")
	_boot._on_save_requested()
	await wait_process_frames(5)
	assert_eq(_save_writes(), [] as Array[String], "aucune écriture sur le titre")
	assert_eq(_fs.files[SAVE_PATH], _fixture_text(), "v4 pas réécrite (migrée en mémoire)")
	assert_eq(GameState.play_time, 0.0, "le temps de jeu ne court pas sur le titre")


# --- Sauvegarde valide : Continuer ---------------------------------------------------------

func test_a_valid_save_features_continue_with_its_summary() -> void:
	_put_save(_fixture_text())
	await _launch()
	var title := _title()
	assert_eq(title.get_entries(), [&"continue", &"new_game", &"settings"] as Array[StringName])
	assert_eq(title.get_featured(), &"continue")
	var summary := _opening().get_model().summary
	assert_eq(summary.player_name, "Kevin")
	assert_eq(summary.map_id, StringName(JSON.parse_string(_fixture_text())["map"]))
	assert_false(summary.zone_name.is_empty(), "lieu nommé")
	var texts := title.get_texts()
	assert_has(texts, "CONTINUER")
	assert_has(texts, "Kevin")
	assert_has(texts, summary.zone_name)
	assert_has(texts, summary.play_time_text())


func test_continue_resumes_the_save_where_it_was() -> void:
	var v4: Dictionary = JSON.parse_string(_fixture_text())
	_put_save(_fixture_text())
	await _launch()
	_title().get_entry_button(&"continue").pressed.emit()
	await _wait_finished()
	assert_true(_boot.has_resumed())
	assert_null(_opening().get_screen(), "titre retiré")
	assert_null(_boot.get_title_backdrop(), "décor libéré")
	var map := _boot.get_map()
	assert_eq(map.map_id, StringName(v4["map"]))
	assert_eq(_boot.get_player().get_cell(), Vector2i(v4["cell"][0], v4["cell"][1]))
	assert_eq(GameState.player_name, "Kevin")
	assert_eq(GameState.rival_name, "Régis", "v4 migrée : rival par défaut")
	assert_eq(GameState.player_look, &"hero")
	assert_true(_boot.get_hud().visible)
	assert_true(_boot._can_write(), "autosave normal")
	await wait_until(func() -> bool: return int(_saved().get("version", 0)) == 5, TIMEOUT)
	assert_eq(int(_saved()["version"]), 5, "premier autosave : la partie passe en v5")
	assert_false(_fs.files.has(PREVIOUS_PATH), "Continuer ne fait aucune copie")


# --- Nouvelle partie -----------------------------------------------------------------------

func test_new_game_without_save_goes_to_the_bedroom_and_writes_it() -> void:
	await _launch()
	_title().get_entry_button(&"new_game").pressed.emit()
	await _wait_finished()
	assert_eq(_opening().get_last_commit(), OpeningCommit.Result.OK)
	_assert_in_the_bedroom()
	var saved := _saved()
	assert_eq(int(saved["version"]), SaveSystem.VERSION)
	assert_eq(saved["map"], "player_house_2f")
	assert_eq(saved["cell"], [3.0, 4.0])
	assert_eq(saved["facing"], [0.0, 1.0])
	assert_eq(saved["player_name"], "Kevin")
	assert_eq(saved["rival_name"], "Régis")
	assert_eq(saved["player_look"], "hero")
	assert_false(_fs.files.has(PREVIOUS_PATH), "rien à copier")


func test_new_game_over_a_valid_save_asks_for_confirmation() -> void:
	_put_save(_fixture_text())
	await _launch()
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	var confirm := _title().get_confirm()
	assert_true(confirm.is_showing())
	assert_eq(_opening().get_flow().screen(), OpeningFlow.Screen.CONFIRM_OVERWRITE)
	var texts := confirm.get_texts()
	assert_has(texts, "Une aventure est déjà en cours.")
	assert_eq(texts[1], "Kevin · %s\nCommencer une nouvelle partie remplacera cette aventure "
		% _opening().get_model().summary.play_time_text()
		+ "lorsque tu arriveras dans ta chambre.")
	assert_has(texts, "Annuler")
	assert_has(texts, "Nouvelle partie")


func test_cancel_and_back_keep_the_save_untouched() -> void:
	_put_save(_fixture_text())
	await _launch()
	_fs.journal.clear()
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	_title().get_confirm().get_cancel_button().pressed.emit()
	await wait_process_frames(2)
	assert_eq(_opening().get_flow().screen(), OpeningFlow.Screen.TITLE)
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	_boot._on_go_back()
	await wait_process_frames(2)
	assert_false(_title().get_confirm().is_showing(), "retour = annuler")
	assert_eq(_opening().get_flow().screen(), OpeningFlow.Screen.TITLE)
	_boot._on_go_back()
	assert_true(_opening().is_active(), "retour au titre : rien, jamais de sortie")
	assert_eq(_save_writes(), [] as Array[String])
	assert_eq(_fs.files[SAVE_PATH], _fixture_text())


func test_confirmed_new_game_backs_up_the_old_save_then_enters_the_bedroom() -> void:
	var old := _fixture_text()
	_put_save(old)
	await _launch()
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	_title().get_confirm().get_confirm_button().pressed.emit()
	await _wait_finished()
	assert_eq(_opening().get_last_commit(), OpeningCommit.Result.OK)
	assert_eq(_fs.files[PREVIOUS_PATH], old, "ancienne partie copiée octet pour octet")
	_assert_in_the_bedroom()
	var saved := _saved()
	assert_eq(saved["map"], "player_house_2f")
	assert_eq(saved["party"], [], "nouvelle partie : équipe vide")
	assert_lt(float(saved["play_time"]), 1.0, "temps de jeu de la nouvelle partie")
	assert_false(_boot.has_resumed())
	assert_eq(GameState.party.size(), 0)
	assert_true(_boot._can_write())


func test_the_bedroom_start_is_unchanged_no_zone_title_no_dialogue() -> void:
	await _launch()
	_title().get_entry_button(&"new_game").pressed.emit()
	await _wait_finished()
	assert_eq(_map_entered, 1, "une seule entrée de carte : la chambre")
	assert_false(_boot.get_hud().get_zone_title().is_showing(), "aucun titre de zone")
	assert_false(_boot.get_dialogue_runner().is_running(), "aucun dialogue")
	assert_true(_boot.get_hud().are_controls_visible())
	assert_eq(GameState.discovered_maps.size(), 1)
	assert_true(GameState.discovered_maps.has(&"player_house_2f"), "seule la chambre découverte")


# --- Abandon et relancement (§3.7) ---------------------------------------------------------

func test_killed_on_the_confirmation_the_old_save_is_intact_and_asked_again() -> void:
	var old := _fixture_text()
	_put_save(old)
	await _launch()
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	_kill_boot()
	assert_eq(_fs.files[SAVE_PATH], old, "ancienne partie intacte")
	assert_eq(_fs.files.keys(), [SAVE_PATH], "aucun autre fichier (ni copie, ni temporaire)")
	# Relancement : titre, Continuer sur l'ancienne partie, et la confirmation redemandée.
	await _launch()
	assert_eq(_title().get_featured(), &"continue")
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	assert_true(_title().get_confirm().is_showing(), "nouvelle confirmation")


func test_killed_after_confirming_but_before_the_bedroom_writes_nothing() -> void:
	var old := _fixture_text()
	_put_save(old)
	await _launch()
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	_title().get_confirm().get_confirm_button().pressed.emit()
	# Le rideau descend (une image à vitesse 0) : l'application est tuée avant le commit.
	_kill_boot()
	await wait_process_frames(3)
	assert_eq(_fs.files[SAVE_PATH], old, "ancienne partie intacte octet pour octet")
	assert_false(_fs.files.has(PREVIOUS_PATH))


# --- Corrompue, plus récente, échec d'écriture ---------------------------------------------

func test_a_corrupt_save_is_set_aside_and_new_game_is_featured() -> void:
	_put_save("{ pas du json")
	await _launch()
	assert_eq(_title().get_entries(), [&"new_game", &"settings"] as Array[StringName])
	assert_eq(_title().get_featured(), &"new_game")
	assert_eq(_title().get_message_text(),
		"La sauvegarde n'a pas pu être lue. Une copie a été mise de côté.")
	assert_eq(_fs.files.get(SAVE_PATH + SaveSystem.CORRUPT_SUFFIX), "{ pas du json",
		"jamais détruite : mise de côté")
	assert_false(_fs.files.has(SAVE_PATH))
	_title().get_entry_button(&"new_game").pressed.emit()
	await _wait_finished()
	assert_eq(_saved()["map"], "player_house_2f", "nouvelle partie écrite")
	assert_eq(_fs.files[SAVE_PATH + SaveSystem.CORRUPT_SUFFIX], "{ pas du json")
	assert_false(_fs.files.has(PREVIOUS_PATH))


func test_a_newer_save_is_never_written_even_after_a_new_game() -> void:
	var newer := JSON.stringify({"version": SaveSystem.VERSION + 1, "map": "route_1"})
	_put_save(newer)
	await _launch()
	assert_eq(_title().get_entries(), [&"new_game", &"settings"] as Array[StringName])
	assert_eq(_title().get_message_text(), "Cette sauvegarde vient d'une version plus récente "
		+ "du jeu. Elle n'a pas été modifiée.")
	_title().get_entry_button(&"new_game").pressed.emit()
	await _wait_finished()
	_assert_in_the_bedroom()
	assert_eq(_opening().get_last_commit(), -1, "aucun commit")
	assert_false(_boot._can_write(), "aucune écriture de la session")
	_boot.request_autosave("test")
	await wait_process_frames(5)
	assert_eq(_save_writes(), [] as Array[String])
	assert_eq(_fs.files[SAVE_PATH], newer, "fichier intact")


func test_a_failed_commit_enters_the_bedroom_without_saving_and_warns() -> void:
	await _launch()
	_fs.fail_writes = true
	_title().get_entry_button(&"new_game").pressed.emit()
	await _wait_finished()
	assert_eq(_opening().get_last_commit(), OpeningCommit.Result.WRITE_FAILED)
	_assert_in_the_bedroom()
	assert_false(_boot._can_write(), "sans autosave pour la session")
	var toast := _boot.get_hud().get_toast()
	assert_true(toast.is_showing())
	assert_eq(toast.get_title_text(),
		"La partie n'a pas pu être enregistrée. Elle continue sans sauvegarde.")
	_fs.fail_writes = false
	_fs.journal.clear()
	_boot.request_autosave("test")
	await wait_process_frames(5)
	assert_eq(_save_writes(), [] as Array[String], "plus aucune tentative")


# --- Paramètres depuis le titre ------------------------------------------------------------

func test_settings_from_the_title_without_save_now() -> void:
	_put_save(_fixture_text())
	await _launch()
	_fs.journal.clear()
	_title().get_entry_button(&"settings").pressed.emit()
	await wait_process_frames(2)
	assert_true(_title().is_settings_open())
	var screen := _title().get_settings()
	assert_null(screen.get_action_button(), "pas de « Sauvegarder maintenant »")
	assert_does_not_have(screen.get_texts(), "Sauvegarder maintenant")
	screen.select_category(&"controls")
	screen.setting_changed.emit(GameSettings.LEFT_HANDED, true)
	await wait_process_frames(2)
	assert_true(_boot.get_settings().left_handed, "réglage appliqué")
	assert_true(_fs.files.has(SETTINGS_PATH), "écrit dans settings.json")
	assert_eq(_save_writes(), [] as Array[String], "la sauvegarde n'est pas touchée")
	var column := _title().get_column()
	assert_eq(column.anchor_left, 0.0, "mode gaucher : colonne à gauche")
	screen.back_requested.emit()
	await wait_process_frames(2)
	assert_false(_title().is_settings_open())
	assert_eq(_opening().get_flow().screen(), OpeningFlow.Screen.TITLE)


func test_android_back_closes_the_settings() -> void:
	await _launch()
	_title().get_entry_button(&"settings").pressed.emit()
	await wait_process_frames(2)
	_boot._on_go_back()
	assert_false(_title().is_settings_open())
	assert_true(_opening().is_active())


# --- Départ de débogage --------------------------------------------------------------------

func test_a_debug_start_skips_the_title() -> void:
	_put_save(_fixture_text())
	await _launch(DEBUG_START)
	assert_null(_boot.get_opening(), "aucune ouverture")
	assert_null(_boot.get_title_backdrop())
	assert_eq(_boot.get_map().map_id, &"route_1", "départ de débogage appliqué")
	assert_eq(_save_writes(), [] as Array[String], "sauvegarde ni lue ni écrite")
	assert_eq(_fs.files[SAVE_PATH], _fixture_text())


# --- Introduction du Prof. Chen (OUV.2) -----------------------------------------------------

func test_new_game_plays_the_introduction_on_the_lab_in_decor_mode() -> void:
	_put_save(_fixture_text())
	await _launch()
	_fs.journal.clear()
	await _start_intro()
	var backdrop := _boot.get_title_backdrop()
	assert_not_null(backdrop, "décor de l'introduction")
	assert_eq(backdrop.get_map().map_id, &"oak_lab", "le vrai labo, flouté par la scène")
	assert_true(backdrop.get_camera().is_current())
	assert_null(SceneRouter.get_current_map(), "pas passé par SceneRouter")
	assert_eq(_map_entered, 0)
	assert_not_null(_opening().get_intro_stage())
	assert_eq(_opening().get_flow().screen(), OpeningFlow.Screen.INTRO)
	assert_false(_boot.get_hud().visible, "HUD caché pendant l'introduction")
	await _intro_until(func() -> bool: return _boot.get_dialogue_box().is_open())
	assert_eq(_boot.get_dialogue_box().get_speaker_text(), "Prof. Chen")
	assert_eq(_boot.get_dialogue_box().get_text(),
		"Bonjour ! Bienvenue dans le monde des Pokémon !")
	_boot.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_boot.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	_boot.request_autosave("test")
	await wait_process_frames(5)
	assert_eq(_save_writes(), [] as Array[String], "rien d'écrit pendant l'introduction")
	assert_false(_boot._can_write())
	assert_eq(GameState.play_time, 0.0, "le temps de jeu ne court pas")


func test_the_whole_introduction_brings_the_chosen_names_into_the_bedroom() -> void:
	var old := _fixture_text()
	_put_save(old)
	await _launch()
	await _start_intro()
	await _wait_finished("Sacha", "gary")
	assert_eq(_opening().get_last_commit(), OpeningCommit.Result.OK)
	_assert_in_the_bedroom()
	assert_null(_opening().get_intro_stage(), "scène retirée")
	assert_eq(GameState.player_name, "Sacha")
	assert_eq(GameState.rival_name, "Gary", "prénom normalisé (majuscule)")
	var saved := _saved()
	assert_eq(saved["player_name"], "Sacha")
	assert_eq(saved["rival_name"], "Gary")
	assert_eq(saved["map"], "player_house_2f")
	assert_eq(_fs.files[PREVIOUS_PATH], old, "ancienne partie copiée octet pour octet")
	assert_true(_boot._can_write(), "autosave normal ensuite")


func test_the_chosen_names_label_the_prologue_and_the_rival_battle() -> void:
	await _launch()
	await _start_intro()
	await _wait_finished("Red", "Blue")
	var values := _boot._dialogue_token_values()
	assert_eq(values[DialogueTokens.PLAYER], "Red")
	assert_eq(values[DialogueTokens.RIVAL], "Blue")
	# Une réplique du rival au labo : l'étiquette est le prénom choisi.
	var runner := _boot.get_dialogue_runner()
	assert_true(runner.play(&"rival_starter_pick"))
	await wait_until(func() -> bool: return _boot.get_dialogue_box().is_open(), TIMEOUT)
	await wait_process_frames(2)
	assert_eq(_boot.get_dialogue_box().get_speaker_text(), "Blue")
	# Le combat contre le rival : le nom du dresseur des données est résolu.
	var trainer := _boot.get_trainer_library().get_trainer(&"rival_lab")
	assert_eq(trainer.name, "{rival}", "les données gardent le jeton")
	assert_eq(_boot._texts.trainer_display_name(trainer.name), "Blue")


func test_no_reopens_the_name_entry_prefilled() -> void:
	await _launch()
	await _start_intro()
	var intro := _opening().get_intro()
	await _intro_until(func() -> bool: return intro.is_waiting_for_name())
	intro.submit_name("Léo")
	await _intro_until(func() -> bool: return intro.is_waiting_for_choice())
	_boot.get_dialogue_box().get_choice_cards().get_cancel_button().pressed.emit()
	await wait_process_frames(2)
	assert_true(intro.is_waiting_for_name())
	var entry := _opening().get_intro_stage().get_name_entry()
	assert_true(entry.is_open())
	assert_eq(entry.get_text(), "Léo", "champ prérempli")


func test_android_back_during_the_introduction_does_nothing() -> void:
	await _launch()
	await _start_intro()
	var intro := _opening().get_intro()
	await _intro_until(func() -> bool: return intro.is_waiting_for_name())
	_boot._on_go_back()
	_boot._on_go_back()
	await wait_process_frames(2)
	assert_true(intro.is_waiting_for_name(), "toujours sur l'écran de prénom")
	assert_true(_opening().is_active(), "jamais de sortie")
	assert_false(_boot.get_trainer_menu().visible and _boot.get_menu_director().is_open(),
		"pas de Menu Dresseur")


## Abandon (application tuée) à chaque plan du storyboard (§4 plans 2 à 8, §3.7) : rien d'écrit,
## l'ancienne partie intacte octet pour octet, et au relancement le titre redemande la
## confirmation.
func test_killed_at_any_shot_of_the_introduction_writes_nothing() -> void:
	var old := _fixture_text()
	# Index d'étape de oak_intro.json où l'on tue l'application : Chen seul, Nidorino, le
	# joueur, son prénom, la confirmation, le rival, le prénom du rival, la dernière réplique.
	var shots: Array[int] = [1, 5, 11, 13, 14, 18, 23, 31]
	for shot: int in shots:
		_fs = MemoryFs.new()
		_put_save(old)
		await _launch()
		await _start_intro()
		var intro := _opening().get_intro()
		await _intro_until(func() -> bool: return intro.get_reader().index() >= shot \
			and not intro.is_staging(), "Sacha", "Gary")
		assert_eq(intro.get_reader().index(), shot, "plan %d atteint" % shot)
		_kill_boot()
		assert_eq(_fs.files[SAVE_PATH], old, "plan %d : ancienne partie intacte" % shot)
		assert_eq(_fs.files.keys(), [SAVE_PATH], "plan %d : aucun autre fichier" % shot)
	await _launch()
	assert_eq(_title().get_featured(), &"continue", "relancement : Continuer")
	_title().get_entry_button(&"new_game").pressed.emit()
	await wait_process_frames(2)
	assert_true(_title().get_confirm().is_showing(), "nouvelle confirmation")


func test_a_second_introduction_after_an_abandon_succeeds() -> void:
	await _launch()
	await _start_intro()
	await _intro_until(func() -> bool: return _opening().get_intro().is_waiting_for_name())
	_kill_boot()
	assert_false(_fs.files.has(SAVE_PATH), "rien d'écrit")
	await _launch()
	await _start_intro()
	await _wait_finished("Sacha", "Régis")
	_assert_in_the_bedroom()
	assert_eq(_saved()["player_name"], "Sacha")


func _assert_in_the_bedroom() -> void:
	var map := _boot.get_map()
	assert_not_null(map)
	if map == null:
		return
	assert_eq(map.map_id, &"player_house_2f")
	assert_eq(_boot.get_player().get_cell(), BEDROOM_CELL)
	assert_eq(_boot.get_player().get_facing(), Vector2i.DOWN)
	assert_true(_boot.get_player().is_input_enabled())
	assert_null(_boot.get_title_backdrop(), "décor libéré")
	assert_true(_boot.get_hud().visible)


## Splash (§5.1) : le logo Kanto 2026 sur un fond uni sombre et chaud, filtré, à l'échelle.
func test_the_boot_splash_is_the_kanto_logo() -> void:
	var image: String = ProjectSettings.get_setting("application/boot_splash/image", "")
	assert_eq(image, "res://assets/ui/opening/splash_kanto_2026.png")
	assert_true(FileAccess.file_exists(image))
	assert_true(ProjectSettings.get_setting("application/boot_splash/use_filter", false))
	var bg: Color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	assert_lt(bg.get_luminance(), 0.1, "fond sombre")
	assert_gt(bg.r, bg.b, "et chaud")
