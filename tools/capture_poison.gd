extends SceneTree
## Captures de la présentation du poison (jalon 9, T5) avec la vraie scène Boot et le départ
## `tools/debug_start/poison_ui.json` (Salamèche N9 et Rattata N5 empoisonnés, `poison_unlocked`
## posé, 3 Antidotes, devant la Boutique de Jadielle) :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_poison.gd -- --out=build/captures/jalon09_poison
##   godot --path . --resolution 1920x1080 --fixed-fps 30 \
##     -s res://tools/capture_poison.gd -- --out=build/captures/jalon09_poison
##
## Images, préfixées par la largeur d'écran (« 2340_ », « 1920_ ») :
##   dashboard    tableau de bord : le Pokémon de tête « PSN »
##   team         Équipe : cartes « PSN » (Salamèche, Rattata), K.O. (Nidoran), fiche
##   bag          Sac, SOINS : Antidote sélectionné
##   bag_targets  choix du Pokémon : « PSN » sur les cartes, refus des autres
##   bag_result   « Salamèche n'est plus empoisonné. »
##   bag_refused  « Cela n'aurait aucun effet sur Roucool. »
##   shop         Boutique : Antidote en vente (100 ₽)
##   combat_enter combat sauvage : la carte du joueur porte « PSN » dès l'entrée
##   combat_inflicted  Poudre Toxik : « PSN » sur la carte adverse
##   combat_veil_own / combat_veil_foe  dégât de poison de fin de tour : voile violet, barre en route
##   combat_bag_targets  Antidote en combat : choix du Pokémon (ÉQUIPE « PSN »)

const START := "res://tools/debug_start/poison_ui.json"
## Graine du combat de capture.
const SEED := 11

var _out_dir: String = "build/captures/jalon09_poison"
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
	print("  -> %s %s" % [path, root.get_visible_rect().size])


func _start() -> void:
	_prefix = "%d_" % int(root.get_visible_rect().size.x)
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"viridian_city")
	_boot.set(&"start_spawn", &"from_mart")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	if not start.call(&"load_file", START, data, _boot.call(&"get_item_library")):
		push_error("capture_poison : départ illisible")
	_state = root.get_node(^"/root/GameState")
	start.call(&"apply", _state, data)
	await _frames(60)
	await _menus()
	await _combat(data)
	print("CAPTURE_POISON terminé")
	quit()


func _menus() -> void:
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	menu.open(MenuRoute.dashboard())
	await _frames(40)
	await _shot("dashboard")
	menu.close()
	await _frames(30)
	menu.open(MenuRoute.team(0))
	await _frames(40)
	await _shot("team")
	menu.close()
	await _frames(30)
	menu.open(MenuRoute.bag())
	await _frames(40)
	screen.get_bag().open_category(&"heal")
	screen.get_bag().select_item(&"antidote")
	await _frames(30)
	await _shot("bag")
	screen.get_bag().get_action_button().pressed.emit()
	await _frames(40)
	await _shot("bag_targets")
	menu.use_item_on(&"antidote", 0)
	await _frames(40)
	await _shot("bag_result")
	menu.use_item_on(&"antidote", 1)
	await _frames(40)
	await _shot("bag_refused")
	menu.close()
	await _frames(30)
	_state.get(&"party").get_at(0).status = StatusRules.POISON
	menu.open(MenuRoute.shop(&"viridian_mart"), true)
	await _frames(50)
	await _shot("shop")
	menu.close()
	await _frames(30)


func _combat(data: PokemonData) -> void:
	var party: Party = _state.get(&"party")
	var lead := party.get_lead()
	lead.moves.clear()
	for move_id: StringName in [&"poison_powder", &"scratch"] as Array[StringName]:
		lead.learn_move(move_id, data)
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	var stage: BattleStage = _boot.call(&"get_battle_stage")
	var items: ItemLibrary = director.get_item_library()
	# Graine fixe : le même combat à chaque résolution (la poudre touche, personne ne tombe).
	_state.set(&"rng", GameRng.new(SEED))
	var enc := WildEncounter.new(&"pidgey", 8, &"route_1_grass")
	var request := BattleRequest.wild(enc, data, _state.get(&"rng") as GameRng, Vector2i(5, 4),
		items)
	var map: GameMap = _boot.call(&"get_map")
	var done: Array[bool] = [false]
	var run := func() -> void:
		await director.run_request(request, map)
		done[0] = true
	run.call()
	var veils: Dictionary[StringName, bool] = {}
	var step := 0
	var guard := 0
	while not done[0] and guard < 6000:
		guard += 1
		var battle := director.get_battle()
		var panel := director.get_bag_panel()
		var picker := director.get_party_picker()
		# Pic d'un voile violet : le Pokémon du joueur (poison de fin de tour) puis l'adversaire.
		for side: BattleEvent.SideId in [BattleEvent.SideId.PLAYER, BattleEvent.SideId.FOE]:
			var key: StringName = &"own" if side == BattleEvent.SideId.PLAYER else &"foe"
			var veil := stage.get_sprite(side).material as ShaderMaterial
			if not veils.has(key) and veil != null \
					and float(veil.get_shader_parameter(&"amount")) > 0.5 \
					and (key == &"own" or _foe_tagged(hud)):
				veils[key] = true
				await _shot("combat_veil_" + String(key))
		if picker != null and picker.is_shown() and step == 7:
			await _frames(30)
			await _shot("combat_bag_targets")
			picker.cancel()
			step = 8
		elif panel != null and panel.is_shown() and not panel.is_answered() and step == 6:
			panel.open_category(&"heal")
			panel.select_item(&"antidote")
			await _frames(30)
			panel.get_action_button().pressed.emit()
			step = 7
		elif panel != null and panel.is_shown() and not panel.is_answered() and step == 8:
			panel.get_back_button().back_requested.emit()
			step = 9
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.ACTIONS:
			match step:
				0:
					await _frames(25)
					await _shot("combat_enter")
					step = 1
					hud.action_selected.emit(ActionGrid.ATTACK)
				2:
					# Fin du tour : la poudre a-t-elle touché ? Sinon on recommence.
					if _foe_tagged(hud):
						await _frames(40)
						await _shot("combat_inflicted")
						step = 3
					else:
						step = 1
						hud.action_selected.emit(ActionGrid.ATTACK)
				3:
					step = 4
					hud.action_selected.emit(ActionGrid.ATTACK)
				4:
					step = 5
				5:
					step = 6
					hud.action_selected.emit(ActionGrid.BAG)
				9:
					hud.action_selected.emit(ActionGrid.RUN)
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.MOVES and (step == 1 or step == 4):
			if step == 1:
				step = 2
				hud.move_selected.emit(0)
			else:
				step = 4
				hud.move_selected.emit(1)
		await _frames(1)
	if not done[0]:
		push_error("capture_poison : le combat ne s'est pas terminé (étape %d)" % step)


func _foe_tagged(hud: BattleHud) -> bool:
	return hud.get_card(BattleHud.Side.FOE).get_status_text() == "PSN"
