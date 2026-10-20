extends SceneTree
## Captures de la vie du 20-II (jalon 20 T21) avec la vraie scène Boot, les vraies cartes et leurs
## PNJ (Mac, pas en headless) :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_hideout_life.gd -- --out=build/captures/jalon20_t21
##
## Images, préfixées par la largeur :
##   casino_rocket          le Rocket devant l'affiche, le joueur à côté
##   interrupteur_question  « Il y a un interrupteur derrière l'affiche. / Appuyer ? »
##   interrupteur_ouvert    « Un bruit sourd… Un passage s'est ouvert. », mur escamoté
##   interrupteur_escalier  l'escalier (17, 4) dégagé, dialogue fermé
##   b2f_glisse             B2F : le joueur au milieu de la glisse (4, 15) → (8, 11)
##   b2f_arret              B2F : arrêté sur la case (8, 11)
##   giovanni_monde         B4F : Giovanni dans son bureau, le joueur à sa gauche
##   giovanni_carte         carte « GIOVANNI / Chef de la Team Rocket »
##   giovanni_combat        le combat contre Giovanni (Onix N23)
##   scope_au_sol           Giovanni parti, la Poké Ball du Scope au sol
##   scope_recu             « Kevin obtient le Scope Sylphe ! »
##   tour_scope             Tour 3F, Scope au Sac : rencontre identifiée (Fantominus)

const SEED := 7
const START := "res://tools/debug_start/giovanni.json"

var _out_dir: String = "build/captures/jalon20_t21"
var _boot: Node
var _state: Node
var _prefix: String = ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(capture_name: String) -> void:
	await _frames(3)
	var path := "%s/%s%s.png" % [_out_dir, _prefix, capture_name]
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s" % path)


func _start() -> void:
	_prefix = "%d_" % int(root.get_visible_rect().size.x)
	_state = root.get_node("GameState")
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"celadon_game_corner")
	_boot.set(&"start_spawn", &"entrance")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(60)
	_state.call(&"new_game", SEED)
	var start := DebugStart.new()
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	if not start.load_file(START, data, _boot.call(&"get_item_library")):
		push_error("\n".join(start.get_errors()))
	start.apply(_state, data)
	_state.set(&"player_name", "Kevin")
	var flags: StoryFlags = _state.get(&"flags")
	flags.set_flag(&"game_corner_switch", false)
	flags.set_flag(&"beaten_celadon_game_corner_rocket", false)
	(_boot.call(&"get_dialogue_runner") as DialogueRunner).chars_per_second = 0.0
	_strong_party()
	await _casino()
	await _glide()
	await _giovanni()
	await _tower()
	print("CAPTURE_HIDEOUT_LIFE terminé")
	quit()


func _strong_party() -> void:
	var party: Party = _state.get(&"party")
	while party.size() > 0:
		party.remove_at(0)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var champion := PokemonFactory.create(data, &"charmander", 40, GameRng.new(SEED))
	champion.moves.clear()
	for move: Array in [[&"ember", 25], [&"scratch", 35], [&"growl", 40], [&"leer", 30]]:
		champion.moves.append(MoveSlot.new(move[0], move[1]))
	party.add(champion)


func _stand(map_id: StringName, spawn: StringName, cell: Vector2i, facing: Vector2i) -> void:
	var router: Variant = root.get_node("SceneRouter")
	await router.change_map(map_id, spawn, facing)
	await _frames(40)
	var player: Node = _boot.call(&"get_player")
	(_boot.call(&"get_map") as GameMap).spawn_player_at(player, cell, facing)
	await _frames(40)


func _press_interact() -> void:
	Input.action_press(&"interact")
	await _frames(3)
	Input.action_release(&"interact")
	await _frames(8)


func _casino() -> void:
	await _stand(&"celadon_game_corner", &"entrance", Vector2i(10, 5), Vector2i.LEFT)
	await _shot("casino_rocket")
	(_state.get(&"flags") as StoryFlags).set_flag(&"beaten_celadon_game_corner_rocket")
	await _stand(&"celadon_game_corner", &"entrance", Vector2i(9, 5), Vector2i.UP)
	await _press_interact()
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	var asked := false
	var opened := false
	var guard := 0
	while (runner.is_running() or director.is_running()) and guard < 3000:
		guard += 1
		if runner.is_awaiting_choice():
			if not asked:
				asked = true
				await _frames(25)
				await _shot("interrupteur_question")
			runner.choose(true)
		elif box.is_open():
			if not opened and box.get_text().contains("bruit sourd"):
				opened = true
				await _frames(25)
				await _shot("interrupteur_ouvert")
			box.advance_requested.emit()
		await _frames(2)
	await _frames(40)
	await _shot("interrupteur_escalier")


func _glide() -> void:
	await _stand(&"rocket_hideout_b2f", &"from_b1f_north", Vector2i(3, 15), Vector2i.RIGHT)
	var spin: SpinTileDirector = _boot.call(&"get_spin_director")
	Input.action_press(&"move_right")
	await _frames(3)
	Input.action_release(&"move_right")
	var guard := 0
	var mid := false
	while guard < 600:
		guard += 1
		var player: Player = _boot.call(&"get_player")
		if spin.is_running() and not mid and player.get_cell() == Vector2i(8, 15):
			mid = true
			root.get_texture().get_image().save_png("%s/%sb2f_glisse.png" % [_out_dir, _prefix])
			print("CAPTURE b2f_glisse")
		if not spin.is_running() and mid and not player.is_moving():
			break
		await _frames(1)
	await _frames(30)
	await _shot("b2f_arret")


func _giovanni() -> void:
	await _stand(&"rocket_hideout_b4f", &"from_elevator", Vector2i(24, 3), Vector2i.RIGHT)
	await _shot("giovanni_monde")
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	var hud: Node = _boot.call(&"get_hud")
	var battle_director: BattleDirector = _boot.call(&"get_battle_director")
	var battle_hud: BattleHud = _boot.call(&"get_battle_hud")
	await _press_interact()
	var shot_card := false
	var shot_battle := false
	var battle_frames := 0
	var guard := 0
	while (director.is_running() or runner.is_running() or battle_director.is_running()
			or _summary_open(battle_director)) and guard < 9000:
		guard += 1
		var summary := battle_director.get_summary_card()
		if summary != null and summary.visible:
			await _frames(10)
			summary.tap()
		var card: Node = hud.call(&"get_champion_card")
		if card.call(&"is_showing") and not shot_card:
			shot_card = true
			await _frames(25)
			await _shot("giovanni_carte")
			card.call(&"skip_hold")
		if battle_director.is_running():
			battle_frames += 1
			if battle_frames == 90 and not shot_battle:
				shot_battle = true
				await _shot("giovanni_combat")
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				if battle_hud.get_zone() == BattleHud.Zone.ACTIONS:
					battle_hud.action_selected.emit(ActionGrid.ATTACK)
				elif battle_hud.get_zone() == BattleHud.Zone.MOVES:
					battle_hud.move_selected.emit(0)
		elif box.is_open():
			box.advance_requested.emit()
		await _frames(2)
	await _frames(60)
	await _shot("scope_au_sol")
	await _press_interact()
	guard = 0
	var shot_scope := false
	while (director.is_running() or runner.is_running()) and guard < 2000:
		guard += 1
		if box.is_open():
			if not shot_scope and box.get_text().contains("Scope Sylphe"):
				shot_scope = true
				await _frames(25)
				await _shot("scope_recu")
			box.advance_requested.emit()
		await _frames(2)
	await _frames(40)


func _tower() -> void:
	var router: Variant = root.get_node("SceneRouter")
	await router.change_map(&"pokemon_tower_3f", &"arrivee_T23", Vector2i.RIGHT)
	await _frames(60)
	var encounters: EncounterDirector = _boot.call(&"get_encounter_director")
	encounters.start_encounter(WildEncounter.new(&"gastly", 22))
	await _frames(150)
	await _shot("tour_scope")


func _summary_open(battles: BattleDirector) -> bool:
	var summary := battles.get_summary_card()
	return summary != null and summary.visible
