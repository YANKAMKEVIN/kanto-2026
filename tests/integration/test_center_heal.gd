extends GutTest
## Centre Pokémon jouable (jalon 7 T8, jalon-07.md §8 ; dossier 09 §7, §19) avec la vraie scène
## Boot, la vraie carte du Centre, la partie du départ de débogage `center_qa` (équipe blessée et
## un K.O.) et une sauvegarde en mémoire :
## - parler à l'infirmière par-dessus le comptoir → « Bonjour. Je m'occupe de ton équipe ? » et le
##   choix SOIGNER / PAS MAINTENANT (vue du choix) ;
## - SOIGNER → équipe pleine, rituel d'environ 3 s (machine, vibration à l'éclat), « Voilà. Tout le
##   monde est en pleine forme. », toast « Point de repos enregistré — Jadielle » **une fois**,
##   sauvegarde écrite avec le Centre comme point de repos ; un second soin : pas de toast ;
## - PAS MAINTENANT → « Très bien. Reviens quand tu veux. », rien ne change ;
## - « Réduire les animations » : rituel deux fois plus court ;
## - une défaite après le soin réveille au Centre (mot de l'infirmière), sauvegardé au réveil.
## Le choix est répondu en touchant une carte de la vraie boîte de dialogue (T7, ChoiceCards) ;
## le retour Android pendant le choix vaut PAS MAINTENANT.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const START := "res://tools/debug_start/center_qa.json"
const SAVE_PATH := "user://test_center_heal_save.json"
const DATE := "2026-10-05T18:00:00"
const FADE := 0.05
const TIMEOUT := 12.0
const FRAME := 1.0 / 60.0
const QUESTION := "Bonjour. Je m'occupe de ton équipe ?"
const DONE := "Voilà. Tout le monde est en pleine forme."
const LATER := "Très bien. Reviens quand tu veux."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _saved_router: Array = []
## Réponse donnée au prochain choix ; vues reçues.
var _answer: bool = true
var _views: Array[ChoiceView] = []
var _pages: Array[String] = []
var _toasts: Array[PackedStringArray] = []
var _vibrations: Array[int] = []
## Rituel en temps simulé ([method _drive_ritual_by_hand]) : machine, images avancées à la
## main pendant qu'elle joue, et leur nombre quand la réplique suivante commence.
var _machine: HealMachine
var _ritual_frames: int = 0
var _frames_at_reply: int = -1


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_views.clear()
	_pages.clear()
	_toasts.clear()
	_vibrations.clear()
	_answer = true
	_machine = null
	_ritual_frames = 0
	_frames_at_reply = -1
	Haptics.sink = func(ms: int) -> void: _vibrations.append(ms)


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


## Boot (sauvegarde en mémoire, autosave actif) sur [param map] / [param spawn], puis la partie de
## `center_qa` (équipe blessée et un K.O., aucun Centre enregistré).
func _start(map: StringName = &"viridian_center", spawn: StringName = &"heal") -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = map
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	_runner.choice_requested.connect(_on_choice_requested)
	_runner.page_started.connect(_on_page_started)
	_boot.get_hud().get_toast().toast_shown.connect(
		func(title: String, detail: String) -> void:
			_toasts.append(PackedStringArray([title, detail])))
	await wait_process_frames(3)


## Le joueur touche une carte de la boîte (T7) quelques images plus tard.
func _on_choice_requested(view: ChoiceView) -> void:
	_views.append(view)
	await wait_process_frames(3)
	var box := _boot.get_dialogue_box()
	assert_true(box.is_choice_showing(), "les cartes sont affichées")
	var cards := box.get_choice_cards()
	(cards.get_confirm_button() if _answer else cards.get_cancel_button()).pressed.emit()


func _on_page_started(_index: int) -> void:
	var text := _boot.get_dialogue_box().get_text()
	_pages.append(text)
	if _ritual_frames > 0 and _frames_at_reply < 0:
		_frames_at_reply = _ritual_frames


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _is_hurt() -> bool:
	for pokemon: Pokemon in GameState.party.get_all():
		if pokemon.hp < pokemon.max_hp():
			return true
	return false


## La machine du Centre n'avance plus avec le moteur : [method _talk_to_the_nurse] fait
## avancer son animation d'une image de FRAME par tour pendant qu'elle joue. La durée du
## rituel se compte alors en images, quelle que soit la charge de la machine.
func _drive_ritual_by_hand() -> void:
	_machine = _boot.get_map().get_node(^"%HealMachine") as HealMachine
	_machine.get_animation_player().callback_mode_process = \
			AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL


## Le rituel a duré [param seconds] (temps simulé), et la réplique suivante l'a attendu :
## pas commencée avant, au plus une image après.
func _assert_ritual_lasts(seconds: float, label: String) -> void:
	var ritual := _frames_at_reply * FRAME
	assert_between(ritual, seconds - 0.0001, seconds + FRAME + 0.0001,
		"%s (%.3f s pour %.2f s)" % [label, ritual, seconds])


## Parle à l'infirmière (joueur devant le comptoir) et déroule tout le dialogue.
func _talk_to_the_nurse() -> void:
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
		if _machine != null and _machine.is_playing():
			# Comptée avant : la fin de l'animation enchaîne la réplique dans advance() même.
			_ritual_frames += 1
			_machine.get_animation_player().advance(FRAME)
	assert_false(_runner.is_running(), "le dialogue s'est terminé")
	await wait_process_frames(3)


func test_center_qa_starts_hurt_without_a_registered_center() -> void:
	await _start()
	assert_true(_is_hurt(), "équipe blessée")
	assert_true(GameState.party.get_at(1).is_fainted(), "un K.O.")
	assert_eq(GameState.heal_map, &"player_house_1f", "maison tant qu'aucun Centre n'a servi")
	assert_eq(_boot.get_map().map_id, &"viridian_center")
	assert_eq(_boot.get_map().light_profile, &"interior_warm")


func test_heal_fills_the_team_plays_the_ritual_registers_and_saves() -> void:
	await _start()
	var writes := _writes()
	_drive_ritual_by_hand()
	await _talk_to_the_nurse()
	assert_eq(_views.size(), 1, "un choix")
	if _views.size() == 1:
		assert_eq(_views[0].title, QUESTION, "la question dans le titre (voile plein cadre)")
		assert_eq([_views[0].confirm_label, _views[0].cancel_label], ["SOIGNER", "PAS MAINTENANT"])
	assert_eq(_pages, [QUESTION, DONE] as Array[String], "question, puis la réplique de fin")
	assert_false(_is_hurt(), "équipe pleine")
	for pokemon: Pokemon in GameState.party.get_all():
		for slot: MoveSlot in pokemon.moves:
			assert_eq(slot.pp, slot.max_pp, "%s : PP pleins" % pokemon.species_id)
	_assert_ritual_lasts(UiTokens.CENTER_HEAL, "rituel d'environ 3 s")
	assert_eq(_vibrations.count(UiTokens.CENTER_HEAL_HAPTIC_MS), 1, "vibration à l'éclat")
	assert_eq(GameState.heal_map, &"viridian_center", "dernier Centre utilisé")
	assert_eq(GameState.heal_spawn, &"heal")
	assert_eq(_toasts.size(), 1, "toast une fois")
	if _toasts.size() == 1:
		assert_eq(_toasts[0], PackedStringArray(["Point de repos enregistré", "Jadielle"]))
	assert_gt(_writes(), writes, "sauvegarde écrite")
	var saved := _saved()
	assert_eq(saved.get("heal_map"), "viridian_center", "le Centre est le point de repos écrit")
	var lead: Dictionary = (saved.get("party", []) as Array)[0]
	assert_eq(int(lead.get("hp", 0)), GameState.party.get_lead().max_hp(), "PV pleins écrits")
	assert_true(_player.is_input_enabled(), "joueur libre")
	# Second soin au même Centre : soigné, mais plus de toast.
	GameState.party.get_lead().hp = 1
	await _talk_to_the_nurse()
	assert_false(_is_hurt(), "soigné une seconde fois")
	assert_eq(_toasts.size(), 1, "le point de repos n'a pas changé : pas de second toast")
	assert_push_error_count(0)


func test_not_now_changes_nothing() -> void:
	await _start()
	_answer = false
	var writes := _writes()
	await _talk_to_the_nurse()
	assert_eq(_pages, [QUESTION, LATER] as Array[String])
	assert_true(_is_hurt(), "pas de soin")
	assert_eq(GameState.heal_map, &"player_house_1f", "point de repos inchangé")
	assert_eq(_toasts.size(), 0)
	assert_false(_vibrations.has(UiTokens.CENTER_HEAL_HAPTIC_MS), "pas de rituel")
	assert_eq(_writes(), writes, "rien à écrire")
	assert_push_error_count(0)


func test_reduce_motion_halves_the_ritual() -> void:
	await _start()
	var settings := _boot.get_settings()
	settings.reduce_motion = true
	_boot.get_menu_director().settings_changed.emit(settings)
	assert_almost_eq(_boot.get_service_director().ritual_duration(), 1.5, 0.001)
	_drive_ritual_by_hand()
	await _talk_to_the_nurse()
	_assert_ritual_lasts(1.5, "rituel raccourci")
	assert_false(_is_hurt())


func test_the_heal_machine_lights_one_slot_per_pokemon() -> void:
	await _start()
	var machine := _boot.get_map().get_node(^"%HealMachine") as HealMachine
	var nurse := _boot.get_map().get_npc(&"nurse")
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while not machine.is_playing() and Time.get_ticks_msec() < deadline:
		if box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_true(machine.is_playing(), "le rituel joue")
	assert_eq(nurse.get_facing(), Vector2i.RIGHT, "l'infirmière se tourne vers la machine")
	var lit := 0
	for slot: Sprite2D in machine.get_slots():
		if slot.visible:
			lit += 1
	assert_eq(lit, GameState.party.size(), "une alvéole par Pokémon")
	await wait_until(func() -> bool: return not machine.is_playing(), TIMEOUT)
	await wait_process_frames(2)
	assert_eq(nurse.get_facing(), Vector2i.DOWN, "puis revient")
	while _runner.is_running() and Time.get_ticks_msec() < deadline:
		if box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		await wait_process_frames(1)


## Retour Android pendant le choix (jalon-07.md §6.5) : la carte d'annulation, rien ne change.
func test_android_back_during_the_choice_means_not_now() -> void:
	await _start()
	_runner.choice_requested.disconnect(_on_choice_requested)
	var box := _boot.get_dialogue_box()
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while not box.is_choice_showing() and Time.get_ticks_msec() < deadline:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_true(box.is_choice_showing(), "SOIGNER / PAS MAINTENANT")
	_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_false(box.is_choice_showing(), "choix fermé")
	assert_false(_boot.get_menu_director().is_open(), "le menu ne s'ouvre pas")
	await wait_until(func() -> bool: return box.is_open() and box.get_text() == LATER, TIMEOUT)
	assert_eq(box.get_text(), LATER)
	while _runner.is_running() and Time.get_ticks_msec() < deadline:
		box.advance_requested.emit()
		await wait_process_frames(1)
	assert_true(_is_hurt(), "pas de soin")
	assert_eq(GameState.heal_map, &"player_house_1f")
	assert_push_error_count(0)


## Une défaite sauvage après un soin au Centre : réveil devant le comptoir, tourné vers
## l'infirmière, son mot (la réplique validée), sauvegardé au réveil (jalon-07.md §5.3).
func test_a_defeat_after_a_center_heal_wakes_at_the_center() -> void:
	await _start(&"route_1", &"from_pallet_w")
	var data := _boot.get_pokemon_data()
	var seed := _defeat_seed(data)
	assert_gt(seed, -1, "une graine de défaite")
	if seed < 0:
		return
	GameState.rng = GameRng.new(seed)
	GameState.party.clear()
	GameState.party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(999)))
	GameState.party.get_lead().hp = 1
	RestPointLibrary.register(GameState, _boot.get_rest_points().get_point(&"viridian_center"))
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	var writes := _writes()
	var wakeups: Array[StringName] = []
	_boot.get_defeat_recovery().woke_up.connect(func(map_id: StringName) -> void:
		wakeups.append(map_id))
	var enc := _boot.get_encounter_director()
	assert_true(enc.start_encounter(WildEncounter.new(&"rattata", 10, &"route_1_grass")))
	var battle_hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while enc.is_running() and Time.get_ticks_msec() < deadline:
		var battle := _boot.get_battle_director().get_battle()
		if battle != null and battle.get_state() == Battle.State.CHOOSING:
			match battle_hud.get_zone():
				BattleHud.Zone.ACTIONS:
					battle_hud.action_selected.emit(ActionGrid.ATTACK)
				BattleHud.Zone.MOVES:
					battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
	assert_false(enc.is_running(), "rencontre terminée")
	assert_eq(wakeups, [&"viridian_center"] as Array[StringName])
	var map := _boot.get_map()
	assert_eq(map.map_id, &"viridian_center", "réveil au Centre")
	assert_eq(_player.get_cell(), map.get_spawn_cell(&"heal"), "devant le comptoir")
	assert_eq(_player.get_facing(), Vector2i.UP, "face à l'infirmière")
	assert_eq(GameState.party.get_lead().hp, GameState.party.get_lead().max_hp(), "soigné")
	assert_gt(_writes(), writes, "sauvegardé au réveil")
	assert_eq(_saved().get("map"), "viridian_center")
	await wait_until(func() -> bool:
		return _runner.is_running() and _runner.get_dialogue_id() == &"nurse_wakeup", TIMEOUT)
	assert_eq(_runner.get_dialogue_id(), &"nurse_wakeup", "le mot de l'infirmière")
	await wait_until(func() -> bool: return _boot.get_dialogue_box().is_open(), TIMEOUT)
	assert_eq(_boot.get_dialogue_box().get_text(), DONE)
	assert_eq(_views.size(), 0, "aucun choix au réveil")
	var box := _boot.get_dialogue_box()
	while _runner.is_running() and Time.get_ticks_msec() < deadline + 5000:
		if box.is_open():
			box.advance_requested.emit()
		await wait_process_frames(1)
	assert_push_error_count(0)


## Graine d'une défaite certaine : Salamèche N5 à 1 PV contre un Rattata N10.
func _defeat_seed(data: PokemonData) -> int:
	for seed: int in range(0, 2000):
		var rng := GameRng.new(seed)
		var encounter := WildEncounter.new(&"rattata", 10, &"route_1_grass")
		var request := BattleRequest.wild(encounter, data, rng, Vector2i.ZERO)
		var party := Party.new()
		party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(999)))
		party.get_lead().hp = 1
		var battle := Battle.new(BattleSide.new(party, true),
			BattleSide.new(request.foe_party, false, "", null), data, rng, request.rules)
		battle.start()
		while battle.get_state() == Battle.State.CHOOSING:
			battle.submit(BattleAction.move(0 if not battle.get_usable_moves().is_empty() \
				else BattleAction.STRUGGLE))
		if battle.get_outcome() == Battle.Outcome.LOSS:
			return seed
	return -1
