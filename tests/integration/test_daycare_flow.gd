extends GutTest
## La Pension sur la carte (J15, T4 ; jalon-15.md §2.5, §5 ; dossier 18 §4, textes T-1 à T-12)
## avec le vrai Boot (Centre de Jadielle comme décor : la carte de QA `qa_daycare` vient au T6),
## une sauvegarde en mémoire et le dialogue du gardien joué tel qu'un PNJ le jouerait :
## - dépôt (T-2 → OUI → T-4 → écran du dépôt → T-6), écriture **immédiate** (le disque a la
##   Pension pleine dès T-6), compagnon effacé ; NON (T-3), ANNULER, retour Android, dernier apte ;
## - retrait (T-7 / T-8 → OUI → T-10 / T-11 → capacités → évolution → T-12), argent, soin,
##   **une seule** écriture à la fin (le disque garde l'état d'avant pendant le déroulé) ;
## - équipe pleine (T-9), argent insuffisant et 0 ₽ (tout pris, Pokémon rendu), niveau 100 ;
## - plusieurs capacités toutes refusées, évolution annulée par le retour Android ;
## - pas : marche et course comptées, mur et pas scripté ignorés.
## L'écran du dépôt (T5) est remplacé par une réponse directe au signal `pick_requested` ;
## l'écran d'évolution par le faux écran des tests.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FakeScreen := preload("res://tests/helpers/fake_evolution_screen.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_daycare_flow_save.json"
const TIMEOUT := 15.0
const FADE := 0.05
const T2: Array[String] = ["Bienvenue à la Pension ! Je garde un Pokémon pendant que tu voyages.",
	"Il s'entraîne un peu à chaque pas que tu fais. Tu veux m'en confier un ?"]
const T3 := "Reviens quand tu veux."
const T4 := "Lequel veux-tu me confier ?"
const T5 := "Tu ne peux pas partir sans un Pokémon en forme."
const T9 := "Ton équipe est complète. Fais-lui une place d'abord."
const T12 := "Je garde toujours une place. Reviens quand tu veux."

var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _daycare: DaycareDirector
var _data: PokemonData
var _saved_router: Array = []
## Réponses aux choix OUI / NON, dans l'ordre (vide : NON).
var _answers: Array[bool] = []
## Réponse à l'écran du dépôt : une place, -1 = ANNULER, -2 = retour Android.
var _pick: int = 0
var _pick_views: Array[DaycarePickView] = []
var _pick_refusals: Array[DaycareRules.Status] = []
var _pages: Array[String] = []
var _banners: Array[String] = []
var _forget_offers: int = 0
## Sauvegarde relue au début de chaque page (texte → dictionnaire).
var _saved_at: Dictionary[String, Dictionary] = {}


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	_fs = MemoryFs.new()
	_answers = []
	_pick = 0
	_pick_views.clear()
	_pick_refusals.clear()
	_pages.clear()
	_banners.clear()
	_forget_offers = 0
	_saved_at.clear()
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"viridian_center"
	_boot.start_spawn = &"heal"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	_daycare = _boot.get_daycare_director()
	_data = _boot.get_pokemon_data()
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	prompt.speed_scale = 0.0
	prompt.confirm_forget = false
	_boot.get_evolution_director().speed_scale = 0.0
	_runner.page_started.connect(_on_page_started)
	_daycare.pick_requested.connect(_on_pick_requested)
	await wait_until(func() -> bool: return _writes() >= 1, TIMEOUT)
	GameState.new_game(15)
	GameState.money = 5000


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		Input.action_release(action)


func _mon(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(level))


func _strings(items: Array) -> Array[String]:
	var result: Array[String] = []
	result.assign(items)
	return result


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _saved() -> Dictionary:
	var parsed: Variant = JSON.parse_string(_fs.files.get(SAVE_PATH, ""))
	return parsed if parsed is Dictionary else {}


func _on_page_started(_index: int) -> void:
	var text := _boot.get_dialogue_box().get_text()
	_pages.append(text)
	_saved_at[text] = _saved()


func _on_pick_requested(view: DaycarePickView) -> void:
	_pick_views.append(view)
	if _pick == -1:
		_daycare.cancel_pick()
		return
	if _pick == -2:
		_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		return
	# Une place refusée d'abord (si l'équipe en a une) : l'écran reste ouvert.
	for index: int in view.party.size():
		if not view.can_pick(index):
			_pick_refusals.append(_daycare.choose_deposit(index))
			break
	assert_eq(_daycare.choose_deposit(_pick), DaycareRules.Status.OK)


## Le gardien parle (son dialogue « action seule », comme un PNJ) et toute la conversation se
## déroule : pages avancées, choix répondus en touchant les cartes, bandeaux et panneau d'oubli
## (NE PAS APPRENDRE) traités.
func _talk() -> void:
	assert_true(_runner.play(DaycareLines.KEEPER, null, _boot.get_map()), "le gardien parle")
	var box := _boot.get_dialogue_box()
	var overlay := _boot.get_daycare_overlay()
	var prompt := _boot.get_battle_director().get_move_learn_prompt()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (_runner.is_running() or _daycare.is_running()) and Time.get_ticks_msec() < deadline:
		if box.is_choice_showing():
			var cards := box.get_choice_cards()
			var yes: bool = _answers.pop_front() if not _answers.is_empty() else false
			(cards.get_confirm_button() if yes else cards.get_cancel_button()).pressed.emit()
		elif box.is_open() and not _runner.is_awaiting_choice():
			box.advance_requested.emit()
		overlay = _boot.get_daycare_overlay()
		if overlay != null and overlay.is_open() and overlay.get_message_banner().is_waiting():
			_banners.append(overlay.get_message_banner().get_text())
			overlay.get_message_banner().skip()
		var panel := prompt.get_forget_panel()
		if panel != null and panel.is_visible_in_tree() and panel.is_shown() \
				and not panel.is_sliding() and not panel.is_answered():
			_forget_offers += 1
			panel.get_skip_button().pressed.emit()
		await wait_process_frames(1)
	assert_false(_runner.is_running() or _daycare.is_running(), "la conversation s'est terminée")
	await wait_process_frames(2)


## La partie telle qu'elle est maintenant est écrite (point de départ des vérifications « le
## disque garde l'état d'avant »).
func _save_now() -> void:
	var writes := _writes()
	_boot.request_autosave("test")
	await wait_until(func() -> bool: return _writes() > writes, TIMEOUT)


## Rattata (compagnon) et Roucool dans l'équipe.
func _two_in_party() -> Array[Pokemon]:
	var rattata := _mon(&"rattata", 5)
	var pidgey := _mon(&"pidgey", 5)
	GameState.party.add(rattata)
	GameState.party.add(pidgey)
	GameState.ensure_unique_uids()
	assert_true(GameState.set_companion(rattata))
	return [rattata, pidgey]


## Salamèche Nv. 8 (deux capacités, ou quatre) gardé, XP en attente jusqu'au niveau 16 : Flammèche
## (9) et Groz'Yeux (15) dues, évolution en Reptincel.
func _keep_charmander(four_moves: bool) -> Pokemon:
	var charmander := _mon(&"charmander", 8)
	if four_moves:
		for move_id: StringName in [&"tackle", &"tail_whip"]:
			charmander.learn_move(move_id, _data)
		assert_eq(charmander.moves.size(), 4)
	charmander.hp = 1
	charmander.ensure_uid()
	GameState.daycare.put(charmander, _data)
	var rate := _data.get_species(&"charmander").growth_rate
	GameState.daycare.pending_exp = ExpCurve.exp_for_level(rate, 16) - charmander.experience
	return charmander


func _move_ids(mon: Pokemon) -> Array[StringName]:
	var ids: Array[StringName] = []
	for slot: MoveSlot in mon.moves:
		ids.append(slot.move_id)
	return ids


# --- Dépôt -----------------------------------------------------------------------------------

func test_deposit_writes_at_once_and_clears_the_companion() -> void:
	var team := _two_in_party()
	_answers = [true]
	var writes := _writes()
	await _talk()
	var deposited := "Très bien. Je m'occupe de Rattata. Reviens le chercher quand tu veux."
	assert_eq(_pages, _strings(T2 + [T4, deposited]), "T-2, T-4, T-6")
	assert_eq(GameState.daycare.pokemon, team[0], "Rattata gardé")
	assert_eq(GameState.party.size(), 1)
	assert_eq(GameState.companion_uid, "", "le compagnon déposé est effacé")
	assert_eq(_writes(), writes + 1, "une écriture, au dépôt")
	var at_t6: Dictionary = _saved_at.get(deposited, {})
	assert_false((at_t6.get("daycare", {}) as Dictionary).is_empty(),
		"quitter avant l'autosave : le disque a déjà la Pension pleine")
	assert_eq((at_t6.get("party", []) as Array).size(), 1, "et l'équipe sans lui")
	assert_eq(str(at_t6.get("companion", "x")), "", "et aucun compagnon")
	assert_true(_player.is_input_enabled(), "joueur rendu")
	assert_true(_boot.get_hud().are_controls_visible(), "contrôles rendus")
	assert_eq(_pick_views.size(), 1)
	assert_eq(_pick_views[0].refused_title, T5, "T-5 en titre d'une place refusée")
	assert_push_error_count(0)


func test_no_ends_with_t3_and_changes_nothing() -> void:
	_two_in_party()
	_answers = [false]
	var writes := _writes()
	await _talk()
	assert_eq(_pages, _strings(T2 + [T3]))
	assert_true(GameState.daycare.is_empty())
	assert_eq(GameState.party.size(), 2)
	assert_eq(_writes(), writes, "rien à écrire")
	assert_eq(_pick_views.size(), 0)


func test_cancel_and_android_back_on_the_picker_change_nothing() -> void:
	var team := _two_in_party()
	for answer: int in [-1, -2]:
		_pick = answer
		_answers = [true]
		_pages.clear()
		var writes := _writes()
		await _talk()
		assert_eq(_pages, _strings(T2 + [T4]), "fin après l'écran (%d)" % answer)
		assert_true(GameState.daycare.is_empty())
		assert_eq(GameState.party.size(), 2)
		assert_eq(GameState.get_companion(), team[0], "compagnon gardé")
		assert_eq(_writes(), writes)
		assert_true(_player.is_input_enabled())


func test_the_last_able_pokemon_is_refused_a_fainted_one_is_kept() -> void:
	var team := _two_in_party()
	team[1].hp = 0
	_pick = 1
	_answers = [true]
	await _talk()
	assert_eq(_pick_refusals, [DaycareRules.Status.LAST_ABLE] as Array[DaycareRules.Status],
		"le dernier apte : refusé, l'écran reste ouvert")
	assert_eq(_pick_views[0].refusal_text(0), StorageViews.LAST_ABLE_TEXT)
	assert_eq(GameState.daycare.pokemon, team[1], "un K.O. peut être confié")
	assert_eq(GameState.party.get_at(0), team[0])


# --- Retrait ---------------------------------------------------------------------------------

func test_withdraw_teaches_then_evolves_heals_pays_and_writes_once_at_the_end() -> void:
	GameState.party.add(_mon(&"pidgey", 5))
	var charmander := _keep_charmander(false)
	var screen := FakeScreen.new()
	add_child_autofree(screen)
	_boot.get_evolution_director().set_screen(screen)
	var saved_during: Array[Dictionary] = []
	screen.probe = func() -> void: saved_during.append(_saved())
	_answers = [true]
	await _save_now()
	var writes := _writes()
	await _talk()
	assert_eq(_pages, ["Ah, te voilà ! Salamèche a gagné 8 niveau(x).",
		"Tu veux le reprendre ? Ce sera 900 ₽.",
		"Merci ! Voici Salamèche. Il est en pleine forme.", T12] as Array[String],
		"T-8, T-10, T-12")
	assert_eq(GameState.money, 4100, "100 + 100 × 8")
	assert_true(GameState.daycare.is_empty())
	assert_eq(GameState.party.get_at(1), charmander, "rendu en fin d'équipe")
	assert_eq(_banners, ["Salamèche apprend Flammèche !", "Salamèche apprend Groz'Yeux !"]
		as Array[String], "capacités dues, dans l'ordre, avant l'évolution")
	assert_eq(screen.calls, ["open", "present", "transform", "reveal", "close"] as Array[String])
	assert_eq(charmander.species_id, &"charmeleon", "évolution proposée et faite")
	assert_eq(charmander.hp, charmander.max_hp(), "soigné, et plein après l'évolution")
	assert_eq(_writes(), writes + 1, "une seule écriture, à la fin")
	assert_eq(saved_during.size(), 1)
	if saved_during.size() == 1:
		assert_false((saved_during[0].get("daycare", {}) as Dictionary).is_empty(),
			"pendant l'évolution, le disque garde le Pokémon à la Pension")
		assert_eq(int(saved_during[0].get("money", 0)), 5000, "et l'argent intact")
	var after := _saved()
	assert_true((after.get("daycare", {}) as Dictionary).is_empty(), "écrit à la fin")
	assert_eq(int(after.get("money", 0)), 4100)
	assert_true(_player.is_input_enabled())
	assert_push_error_count(0)


func test_all_moves_refused_and_the_evolution_cancelled_by_android_back() -> void:
	GameState.party.add(_mon(&"pidgey", 5))
	var charmander := _keep_charmander(true)
	var before := _move_ids(charmander)
	var screen := FakeScreen.new()
	add_child_autofree(screen)
	screen.cancel = true
	screen.back = func() -> bool:
		_boot.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
		return true
	_boot.get_evolution_director().set_screen(screen)
	_answers = [true]
	await _talk()
	assert_eq(_forget_offers, 2, "deux capacités dues, deux offres d'oubli")
	assert_eq(_move_ids(charmander), before, "toutes refusées : les 4 anciennes gardées")
	assert_eq(screen.calls, ["open", "present", "transform", "revert", "close"] as Array[String])
	assert_eq(charmander.species_id, &"charmander", "ARRÊTER (retour Android) : annulée")
	assert_eq(charmander.hp, charmander.max_hp(), "soigné")
	assert_eq(Evolution.level_up_target(charmander, _data), &"charmeleon",
		"reproposée au prochain niveau gagné (règle existante)")
	assert_true(_player.is_input_enabled())


func test_a_full_party_hears_t9_and_nothing_changes() -> void:
	for i: int in 6:
		GameState.party.add(_mon(&"rattata", 5))
	_keep_charmander(false)
	var writes := _writes()
	await _talk()
	assert_eq(_pages, [T9] as Array[String])
	assert_false(GameState.daycare.is_empty())
	assert_eq(GameState.money, 5000)
	assert_eq(_writes(), writes)


func test_not_enough_money_takes_it_all_and_zero_gives_it_back_for_free() -> void:
	for money: int in [150, 0]:
		GameState.new_game(15)
		GameState.party.add(_mon(&"pidgey", 5))
		var charmander := _keep_charmander(false)
		GameState.money = money
		_boot.get_evolution_director().set_screen(null)
		_answers = [true]
		_pages.clear()
		await _talk()
		assert_eq(_strings(_pages.slice(2, 4)), _strings([
			"Tu n'as pas tout à fait assez… Ce n'est rien, je prends ce que tu as.",
			"Voici Salamèche."]), "T-11 (%d ₽)" % money)
		assert_eq(GameState.money, 0, "tout l'argent pris (%d ₽)" % money)
		assert_eq(GameState.party.index_of(charmander), 1, "rendu quand même (%d ₽)" % money)


func test_level_100_visit_costs_100() -> void:
	GameState.party.add(_mon(&"pidgey", 5))
	GameState.daycare.put(_mon(&"rattata", 100), _data)
	_answers = [false]
	await _talk()
	assert_eq(_pages, ["Rattata va très bien. Il n'a pas encore beaucoup changé.",
		"Tu veux le reprendre ? Ce sera 100 ₽."] as Array[String], "T-7, NON : fin")
	assert_false(GameState.daycare.is_empty())


func test_tokens_are_empty_outside_the_daycare() -> void:
	assert_eq(_daycare.token_values().size(), 0)


# --- Pas -------------------------------------------------------------------------------------

## Appuie sur [param action] jusqu'à un pas (signal moved) ou [param frames] images.
func _press_until_step(action: StringName, frames: int) -> int:
	var steps: Array[int] = [0]
	# Relâché au premier pas (un second, déjà parti dans la même image, peut encore finir).
	var count := func(_cell: Vector2i) -> void:
		steps[0] += 1
		Input.action_release(action)
	_player.moved.connect(count)
	Input.action_press(action)
	for i: int in frames:
		await wait_process_frames(1)
		if steps[0] > 0:
			break
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), 2.0)
	_player.moved.disconnect(count)
	return steps[0]


func test_walking_and_running_count_walls_and_scripted_steps_do_not() -> void:
	GameState.party.add(_mon(&"pidgey", 5))
	GameState.daycare.put(_mon(&"rattata", 5), _data)
	assert_eq(await _press_until_step(&"move_up", 20), 0, "le comptoir : pas refusé")
	assert_eq(GameState.daycare.pending_exp, 0, "un pas refusé ne compte pas")
	# Un appui peut enchaîner un second pas avant d'être relâché : on compare au nombre de pas.
	var walked := await _press_until_step(&"move_left", 60)
	assert_gt(walked, 0)
	assert_eq(GameState.daycare.pending_exp, walked, "la marche compte, 1 XP par pas")
	Input.action_press(&"run")
	var ran := await _press_until_step(&"move_right", 60)
	Input.action_release(&"run")
	assert_gt(ran, 0, "des pas en courant")
	assert_eq(GameState.daycare.pending_exp, walked + ran, "la course compte comme la marche")
	_player.set_input_enabled(false, &"test_script")
	assert_true(_player.script_step(Vector2i.RIGHT))
	await wait_until(func() -> bool: return not _player.is_moving(), 2.0)
	_player.set_input_enabled(true, &"test_script")
	assert_eq(GameState.daycare.pending_exp, walked + ran, "un pas scripté ne compte pas")
	# GameState.daycare remplacée (chargement) : le compteur suit la nouvelle.
	GameState.daycare = Daycare.new()
	GameState.daycare.put(_mon(&"rattata", 5), _data)
	var again := await _press_until_step(&"move_left", 60)
	assert_gt(again, 0)
	assert_eq(GameState.daycare.pending_exp, again)
