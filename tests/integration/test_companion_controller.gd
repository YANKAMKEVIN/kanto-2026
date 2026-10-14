extends GutTest
## Compagnon dans la vraie partie (jalon 11, T20c ; `docs/tech/jalon-11-compagnon.md` §2.5–2.6) :
## la vraie scène Boot sur la Route 1. FAIRE SORTIR / RAPPELER par le directeur du menu, suivi
## pas à pas avec occupation douce, curiosité (phrase « {pokemon} » dans la boîte), caché pendant
## une scène et un combat, enthousiasme après une victoire, choix effacé en silence (dépôt,
## évolution en espèce non éligible), aucun bouton pour une espèce sans planche.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_companion_controller_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const ACTION := PokemonSheetView.CompanionAction

var _boot: Boot
var _fades: Array[float] = []
var _companion: CompanionController
var _lead: Pokemon
var _caterpie: Pokemon


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-12T10:00:00")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.flags.set_flag(&"starter_chosen")
	var data := _boot.get_pokemon_data()
	_lead = PokemonFactory.create(data, &"charmander", 9, GameRng.new(7))
	_caterpie = PokemonFactory.create(data, &"caterpie", 4, GameRng.new(7))
	GameState.party.add(_lead)
	GameState.party.add(_caterpie)
	_companion = _boot.get_companion_controller()


func after_each() -> void:
	Input.action_release(&"interact")
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


## FAIRE SORTIR sur le Pokémon 0, menu fermé (le monde suit), puis un pas vers le haut : le
## compagnon est sur la case quittée par le joueur.
func _send_out_and_step() -> Vector2i:
	assert_true(_boot.get_menu_director().toggle_companion(0), "FAIRE SORTIR")
	_companion.refresh()
	var player := _boot.get_player()
	var from := player.get_cell()
	assert_true(player.script_step(Vector2i.UP), "un pas vers le haut")
	await wait_until(func() -> bool: return not player.is_moving() \
		and not _companion.get_node_2d().is_moving() and _companion.is_shown(), TIMEOUT)
	return from


func test_no_companion_by_default() -> void:
	assert_eq(GameState.companion_uid, "", "aucun compagnon : état de départ")
	_companion.refresh()
	assert_false(_companion.is_shown())


func test_team_buttons_send_out_recall_and_none_for_a_species_without_sheet() -> void:
	var menu := _boot.get_menu_director()
	var views: Array = []
	menu.team_shown.connect(func(view: TeamView, _selected: int) -> void: views.append(view))
	assert_true(menu.toggle_companion(0), "FAIRE SORTIR sur Salamèche")
	assert_eq(GameState.get_companion(), _lead)
	assert_eq([views.back().sheets[0].companion_action, views.back().sheets[1].companion_action],
		[ACTION.RECALL, ACTION.NONE], "RAPPELER sur le compagnon ; rien sur Chenipan (A-11)")
	assert_false(menu.toggle_companion(1), "Chenipan : pas de FAIRE SORTIR")
	assert_eq(GameState.get_companion(), _lead, "le choix ne change pas")
	assert_true(menu.toggle_companion(0), "RAPPELER")
	assert_null(GameState.get_companion(), "aucun compagnon")
	assert_eq(views.back().sheets[0].companion_action, ACTION.SEND_OUT)


func test_follows_the_player_and_holds_its_cell_softly() -> void:
	var from := await _send_out_and_step()
	var node := _companion.get_node_2d()
	assert_true(_companion.is_shown(), "visible sur la Route 1")
	assert_eq(node.get_cell(), from, "sur la case quittée par le joueur")
	assert_eq(node.get_species(), &"charmander")
	var grid := _boot.get_map().get_grid()
	assert_true(grid.is_soft_held(from), "case tenue doucement")
	assert_true(grid.is_free(from), "jamais une case occupée pour le joueur")
	assert_eq(node.get_parent(), _boot.get_map().get_entities(), "sous les entités de la carte")


func test_talking_plays_a_line_with_its_name() -> void:
	await _send_out_and_step()
	var player := _boot.get_player()
	player.face(Vector2i.DOWN)
	var controller := _boot.get_interaction_controller()
	await wait_until(func() -> bool: return controller.get_target() != null, TIMEOUT)
	var target := controller.get_target()
	assert_not_null(target, "une cible")
	if target == null:
		return
	assert_eq(target.source, _companion, "la cible est le compagnon")
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	var box := _boot.get_dialogue_box()
	await wait_until(func() -> bool: return box.is_open() and not box.get_text().is_empty(),
		TIMEOUT)
	assert_true(box.get_text().begins_with("Salamèche "), box.get_text())
	assert_eq(box.get_speaker_text(), "", "narration, sans locuteur")
	assert_true(String(_boot.get_dialogue_runner().get_dialogue_id()).begins_with("companion_"))
	assert_eq(_companion.get_node_2d().get_facing(), Vector2i.UP, "il se tourne vers le joueur")


func test_hidden_during_a_cutscene_and_a_battle_then_joy_after_a_trainer_win() -> void:
	await _send_out_and_step()
	_companion.on_cutscene_started()
	await wait_until(func() -> bool: return not _companion.is_shown(), TIMEOUT)
	assert_false(_companion.is_shown(), "rentre au début d'une scène (D-2)")
	_companion.on_cutscene_finished()
	await wait_until(func() -> bool: return _companion.is_shown(), TIMEOUT)
	assert_true(_companion.is_shown(), "ressort à la fin")
	var node := _companion.get_node_2d()
	_companion.on_battle_started()
	assert_false(node.visible, "caché pendant le combat (D-1)")
	_companion.on_battle_finished(true)
	await wait_until(func() -> bool: return node.get_bubble().is_playing(), TIMEOUT)
	assert_eq(node.get_bubble().get_icon(), EmoteBubble.ICONS[EmoteBubble.NOTE], "« ♪ » après la victoire")
	assert_ne(node.get_cell(), Vector2i(-1, -1))
	assert_true(_companion.is_shown())


func test_a_fainted_companion_stays_chosen_but_hidden() -> void:
	await _send_out_and_step()
	_lead.hp = 0
	_companion.on_battle_started()
	_companion.on_battle_finished(false)
	assert_false(_companion.is_shown(), "K.O. : invisible")
	assert_eq(GameState.get_companion(), _lead, "reste choisi")
	assert_false(_boot.get_map().get_grid().is_soft_held(_companion.get_node_2d().get_cell()),
		"plus aucune case tenue")


func test_choice_cleared_silently_when_deposited_or_evolved_into_a_species_without_sheet() -> void:
	await _send_out_and_step()
	# Évolution en espèce sans planche (Dracaufeu) : rentre en silence.
	_companion.on_battle_started()
	_lead.species_id = &"charizard"
	_companion.on_battle_finished(false)
	assert_eq(GameState.companion_uid, "", "choix effacé (A-11)")
	assert_false(_companion.is_shown())
	# Dépôt : le choix part avec le Pokémon.
	_lead.species_id = &"charmander"
	GameState.set_companion(_lead)
	GameState.party.remove_at(0)
	_companion.refresh()
	assert_eq(GameState.companion_uid, "", "plus dans l'équipe : plus compagnon")
	assert_false(_companion.is_shown())


func test_reduce_motion_reaches_the_node() -> void:
	var settings := GameSettings.new()
	settings.reduce_motion = true
	_boot.get_menu_director().settings_changed.emit(settings)
	assert_true(_companion.get_node_2d().reduce_motion)
