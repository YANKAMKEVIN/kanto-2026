extends SceneTree
## Captures de la vie du 20-I (jalon 20 T17) avec la vraie scène Boot, les vraies cartes et leurs
## PNJ (Mac, pas en headless) :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_celadon_life.gd -- --out=build/captures/jalon20_t17
##
## Images, préfixées par la largeur :
##   vendeur_monde          4e étage : le vendeur de pierres derrière son comptoir
##   vendeur_boutique       la Boutique de pierres (2 100 ₽ chacune), ouverte en parlant au vendeur
##   evoli_monde            maison du toit : la Poké Ball sur la table
##   evoli_question         « Un Pokémon attend dans cette Poké Ball. / Le prendre ? »
##   evoli_recu             « Kevin reçoit Évoli ! »
##   erika_monde            Arène : Erika endormie au fond de la serre
##   erika_intro            « Oh… Bonjour. Je crois que je m'étais assoupie. »
##   erika_carte            carte de présentation « ERIKA »
##   erika_combat           début du combat contre Erika (Saquedeneu N24)
##   erika_badge            légende « BADGE PRISME » après la victoire

const SEED := 7
const START := "res://tools/debug_start/celadon_gym.json"

var _out_dir: String = "build/captures/jalon20_t17"
var _boot: Node
var _state: Node
var _prefix: String = ""
var _frames_left: int = 0


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
	_boot.set(&"start_map", &"celadon_dept_4f")
	_boot.set(&"start_spawn", &"from_up")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	await _frames(60)
	_state.call(&"new_game", SEED)
	var start := DebugStart.new()
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	if not start.load_file(START, data, _boot.call(&"get_item_library")):
		push_error("\n".join(start.get_errors()))
	start.apply(_state, data)
	_state.set(&"player_name", "Kevin")
	_state.set(&"money", 9000)
	(_boot.call(&"get_dialogue_runner") as DialogueRunner).chars_per_second = 0.0
	await _vendor()
	await _eevee()
	await _erika()
	print("CAPTURE_CELADON_LIFE terminé")
	quit()


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


func _advance() -> void:
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	box.advance_requested.emit()
	await _frames(8)


func _vendor() -> void:
	await _stand(&"celadon_dept_4f", &"from_up", Vector2i(12, 6), Vector2i.UP)
	await _shot("vendeur_monde")
	await _press_interact()
	await _frames(20)
	await _advance()
	await _frames(60)
	await _shot("vendeur_boutique")
	(_boot.call(&"get_menu_director") as MenuDirector).close()
	await _frames(30)


func _eevee() -> void:
	await _stand(&"celadon_mansion_roof_house", &"entrance", Vector2i(4, 4), Vector2i.UP)
	await _shot("evoli_monde")
	await _press_interact()
	await _frames(20)
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	await _advance()
	await _frames(20)
	await _shot("evoli_question")
	var guard := 0
	while runner.is_running() and guard < 600:
		guard += 1
		if runner.is_awaiting_choice():
			runner.choose(true)
		elif box.is_open():
			if box.get_text().contains("reçoit Évoli"):
				await _frames(25)
				await _shot("evoli_recu")
			box.advance_requested.emit()
		await _frames(2)
	await _frames(40)


func _erika() -> void:
	for flag: StringName in [&"beaten_celadon_gym_lass_lila", &"beaten_celadon_gym_lass_capucine",
			&"beaten_celadon_gym_beauty_violette", &"beaten_celadon_gym_jr_trainer_apolline",
			&"beaten_celadon_gym_cooltrainer_camelia"]:
		_state.get(&"flags").call(&"set_flag", flag)
	var party: Party = _state.get(&"party")
	while party.size() > 0:
		party.remove_at(0)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var champion := PokemonFactory.create(data, &"charmander", 40, GameRng.new(SEED))
	champion.moves.clear()
	for move: Array in [[&"ember", 25], [&"scratch", 35], [&"growl", 40], [&"leer", 30]]:
		champion.moves.append(MoveSlot.new(move[0], move[1]))
	party.add(champion)
	await _stand(&"celadon_gym", &"entrance", Vector2i(8, 3), Vector2i.UP)
	await _shot("erika_monde")
	var director: CutsceneDirector = _boot.call(&"get_cutscene_director")
	var runner: DialogueRunner = _boot.call(&"get_dialogue_runner")
	var box: DialogueBox = _boot.call(&"get_dialogue_box")
	var hud: Node = _boot.call(&"get_hud")
	var battle_director: BattleDirector = _boot.call(&"get_battle_director")
	var battle_hud: BattleHud = _boot.call(&"get_battle_hud")
	await _press_interact()
	var shot_intro := false
	var shot_card := false
	var shot_battle := false
	var shot_badge := false
	var battle_frames := 0
	var guard := 0
	while (director.is_running() or runner.is_running()) and guard < 9000:
		guard += 1
		var card: Node = hud.call(&"get_champion_card")
		if card.call(&"is_showing") and not shot_card:
			shot_card = true
			await _frames(25)
			await _shot("erika_carte")
			card.call(&"skip_hold")
		var caption: Node = hud.call(&"get_caption")
		if caption.call(&"is_showing") and not shot_badge:
			shot_badge = true
			await _frames(20)
			await _shot("erika_badge")
		if battle_director.is_running():
			battle_frames += 1
			if battle_frames == 90 and not shot_battle:
				shot_battle = true
				await _shot("erika_combat")
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				if battle_hud.get_zone() == BattleHud.Zone.ACTIONS:
					battle_hud.action_selected.emit(ActionGrid.ATTACK)
				elif battle_hud.get_zone() == BattleHud.Zone.MOVES:
					battle_hud.move_selected.emit(0)
		elif box.is_open():
			if not shot_intro and box.get_text().contains("assoupie"):
				shot_intro = true
				await _frames(25)
				await _shot("erika_intro")
			box.advance_requested.emit()
		await _frames(2)
	await _frames(40)
