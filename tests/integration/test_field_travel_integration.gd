extends GutTest
## Téléport et Tunnel hors combat (passe systèmes 2, `systemes-2.md` §3.6 T25b) :
## [FieldTravelDirector] (conditions sur la carte courante, voyage, arrivée), UTILISER de l'écran
## Équipe ([TeamScreen], [TeamViews]) et revérification par [MenuDirector] (refus dans le
## bandeau). Routeur factice ; puis le câblage réel dans Boot (Téléport sans soin).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const READY := FieldMoves.State.READY
const Check := FieldTravelRules.Check


class FakeRouter:
	extends Node
	var calls: Array[Array] = []

	func change_map(map_id: StringName, spawn: StringName, facing: Vector2i = Vector2i.ZERO) -> void:
		calls.append([map_id, spawn, facing])


var _data: PokemonData
var _zones: ZoneLibrary
var _caves: CaveLibrary
var _map: GameMap
var _player: Player
var _router: FakeRouter
var _director: FieldTravelDirector
var _state: FieldMoves.State = READY
var _heal: RestPoint


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_state = READY
	_caves = CaveLibrary.new()
	assert_true(_caves.load_file())
	_heal = RestPoint.new()
	_heal.map = &"pewter_center"
	_heal.spawn = &"heal"
	_heal.facing = Vector2i.UP
	_map = _make_map(&"route_3", false)
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_player.set_process(false)
	_router = FakeRouter.new()
	add_child_autofree(_router)
	_director = FieldTravelDirector.new()
	add_child_autofree(_director)
	_director.setup(func(_move: StringName) -> FieldMoves.Result: return FieldMoves.Result.new(_state),
		func() -> RestPoint: return _heal, _caves, func() -> GameMap: return _map, _player, null,
		_router)


func _make_map(map_id: StringName, interior: bool) -> GameMap:
	var map := GameMap.new()
	map.map_id = map_id
	map.interior = interior
	autofree(map)
	return map


# --- Directeur -------------------------------------------------------------------------

func test_director_checks_the_current_map() -> void:
	assert_eq(_director.check(&"teleport"), Check.OK, "extérieur")
	assert_eq(_director.check(&"dig"), Check.NOT_HERE, "Tunnel hors grotte")
	_map = _make_map(&"mt_moon_1f", false)
	assert_eq(_director.check(&"teleport"), Check.OK, "Téléport permis en grotte [D]")
	assert_eq(_director.check(&"dig"), Check.OK)
	_map = _make_map(&"pewter_center", true)
	assert_eq(_director.check(&"teleport"), Check.NOT_HERE, "intérieur")
	_state = FieldMoves.State.NO_POKEMON
	assert_eq(_director.check(&"teleport"), Check.NO_POKEMON)
	assert_eq(_director.check(&"fly"), Check.UNKNOWN_MOVE)


func test_teleport_goes_to_the_heal_point() -> void:
	watch_signals(_director)
	await _director.travel(&"teleport")
	assert_eq(_router.calls, [[&"pewter_center", &"heal", Vector2i.UP]] as Array[Array])
	assert_signal_emitted_with_parameters(_director, "travel_started", [&"teleport"])
	assert_signal_emitted_with_parameters(_director, "travel_finished", [&"teleport"])
	assert_true(_player.is_input_enabled())
	assert_eq(_player.modulate.a, 1.0, "joueur de nouveau visible")
	assert_false(_director.is_travelling())


func test_dig_goes_where_the_escape_rope_goes() -> void:
	_map = _make_map(&"mt_moon_b2f", false)
	var exit := FieldItemRules.escape_target(&"mt_moon_b2f", _caves, _player.get_cell())
	await _director.travel(&"dig")
	assert_eq(_router.calls, [[exit.map, exit.spawn, exit.facing]] as Array[Array])
	assert_eq(exit.map, &"route_3")


func test_refused_travel_does_nothing() -> void:
	await _director.travel(&"dig")
	_map = _make_map(&"pewter_center", true)
	await _director.travel(&"teleport")
	assert_eq(_router.calls.size(), 0)
	assert_true(_player.is_input_enabled())


func test_texts_exist_with_the_field_variant() -> void:
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	for id: StringName in FieldTravelDirector.DIALOGUES.values():
		assert_true(dialogues.has_dialogue(id), id)


# --- Menu ------------------------------------------------------------------------------

func _game_state() -> Node:
	var state: Node = GameStateScript.new()
	state.new_game(7)
	state.party.add(PokemonFactory.create(_data, &"charmander", 14, state.rng))
	var abra := PokemonFactory.create(_data, &"abra", 15, state.rng)
	if not abra.knows_move(&"teleport"):
		abra.replace_move(0, &"teleport", _data)
	state.party.add(abra)
	var diglett := PokemonFactory.create(_data, &"diglett", 18, state.rng)
	diglett.replace_move(0, &"dig", _data)
	state.party.add(diglett)
	for pokemon: Pokemon in state.party.get_all():
		state.stamp_meeting(pokemon, Pokemon.Origin.CAPTURE, &"route_1")
	return state


func test_team_views_list_the_travel_moves_by_card() -> void:
	var state := _game_state()
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	var plain := TeamViews.build(state.party, _data, _zones, state.pokedex, unlocks)
	assert_true(plain.sheet_at(1).field_moves.is_empty(), "sans vérification : rien")
	var view := TeamViews.build(state.party, _data, _zones, state.pokedex, unlocks, null, "",
		FieldTravelRules.MOVES)
	assert_true(view.sheet_at(0).field_moves.is_empty())
	assert_true(view.sheet_at(1).field_moves.values().has(&"teleport"))
	assert_eq(view.sheet_at(2).field_moves, {0: &"dig"} as Dictionary[int, StringName])
	state.free()


func test_menu_director_rechecks_and_explains_a_refusal() -> void:
	var state := _game_state()
	var menu := MenuDirector.new()
	add_child_autofree(menu)
	menu.setup(state, _data, _zones, null, MenuUnlocks.new(state.flags, state.party), Callable())
	var answers := {&"teleport": Check.OK, &"dig": Check.NOT_HERE}
	menu.set_field_travel_check(func(move: StringName) -> Check: return answers[move])
	watch_signals(menu)
	menu.request_field_travel(0, &"teleport")
	assert_signal_not_emitted(menu, "field_travel_requested", "Salamèche ne connaît pas Téléport")
	menu.request_field_travel(2, &"dig")
	assert_signal_not_emitted(menu, "field_travel_requested")
	assert_signal_emitted_with_parameters(menu, "team_notice_shown",
		["Impossible de l'utiliser ici."])
	menu.request_field_travel(1, &"teleport")
	assert_signal_emitted_with_parameters(menu, "field_travel_requested", [&"teleport"])
	state.free()


func test_team_screen_offers_use_under_the_move_sheet() -> void:
	var state := _game_state()
	var view := TeamViews.build(state.party, _data, _zones, state.pokedex,
		MenuUnlocks.new(state.flags, state.party), null, "", FieldTravelRules.MOVES)
	state.free()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2340, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.show_team(view, 2)
	menu.open_animated()
	await wait_frames(3)
	var team := menu.get_team()
	var requested: Array = []
	menu.team_field_move_requested.connect(func(i: int, move: StringName) -> void:
		requested.append([i, move]))
	team.get_sheet().select_tab(PokemonSheet.Tab.MOVES)
	team.get_sheet().get_move_cards()[1].tapped.emit()
	await wait_frames(2)
	assert_true(team.is_move_sheet_open())
	assert_false(team.get_field_use_button().visible, "Griffe : pas d'UTILISER")
	team.close_move_sheet()
	team.get_sheet().get_move_cards()[0].tapped.emit()
	await wait_frames(2)
	var button := team.get_field_use_button()
	assert_true(button.visible, "Tunnel : UTILISER")
	assert_eq(button.text, "UTILISER")
	assert_gte(button.size.y, float(UiTokens.TOUCH_MIN), "zone tactile")
	var sheet_rect := team.get_move_sheet().get_global_rect()
	assert_gt(button.get_global_rect().position.y, sheet_rect.position.y, "sous la fiche")
	button.pressed.emit()
	assert_eq(requested, [[2, &"dig"]])
	assert_false(team.is_move_sheet_open(), "fiche refermée")
	menu.show_team_notice("Impossible de l'utiliser ici.")
	assert_eq(team.get_hint_text(), "Impossible de l'utiliser ici.")


# --- Boot ------------------------------------------------------------------------------

func test_boot_teleports_from_the_team_without_healing() -> void:
	var fades := [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = 0.05
	SceneRouter.fade_in_duration = 0.05
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	boot.save_system = SaveSystem.new(preload("res://tests/helpers/memory_file_system.gd").new(),
		"user://test_t25b_save.json")
	boot.start_map = &"route_1"
	boot.start_spawn = &"from_pallet_w"
	boot.start_facing = Vector2i.UP
	add_child_autofree(boot)
	boot.get_dialogue_runner().chars_per_second = 0.0
	await wait_process_frames(2)
	await wait_until(func() -> bool: return boot.is_stable(), 12.0)
	GameState.new_game(5)
	GameState.flags.set_flag(&"starter_chosen")
	var abra := PokemonFactory.create(_data, &"abra", 15, GameRng.new(2))
	if not abra.knows_move(&"teleport"):
		abra.replace_move(0, &"teleport", _data)
	abra.hp = 1
	GameState.party.add(abra)
	var director := boot.get_field_travel_director()
	assert_not_null(director)
	assert_eq(director.check(&"teleport"), Check.OK)
	assert_eq(director.check(&"dig"), Check.NO_POKEMON)
	var menu := boot.get_menu_director()
	watch_signals(menu)
	menu.request_field_travel(0, &"teleport")
	assert_signal_emitted(menu, "field_travel_requested")
	await wait_until(func() -> bool: return director.is_travelling(), 2.0)
	var box := boot.get_dialogue_box()
	var pages: Array[String] = []
	var deadline := Time.get_ticks_msec() + 8000
	while director.is_travelling() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			if pages.is_empty() or pages.back() != box.get_text():
				pages.append(box.get_text())
			box.advance_requested.emit()
	assert_false(director.is_travelling())
	assert_eq(pages, ["Abra utilise Téléport !"] as Array[String])
	var current := SceneRouter.get_current_map()
	assert_eq(current.map_id, GameState.heal_map, "au point de soin")
	assert_eq(abra.hp, 1, "sans soin")
	get_tree().paused = false
	SceneRouter.fade_out_duration = fades[0]
	SceneRouter.fade_in_duration = fades[1]
