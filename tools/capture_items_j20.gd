extends SceneTree
## Captures des objets du jalon 20 (T11, `jalon-20.md` §2.9) avec la vraie scène Boot (Route 1 :
## les cartes de Céladopole arrivent au T16) :
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_items_j20.gd -- --out=build/captures/jalon20_t11
##
## Images, préfixées par la largeur :
##   menu_revive_targets   Sac (exploration) : Rappel, choix du Pokémon (Roucool K.O. seul possible)
##   menu_revive_result    « Roucool reprend connaissance ! »
##   shop_tm               vendeur de CT du 2e : CT01 à 3 000 ₽
##   shop_tm_owned         la même, CT01 dans le Sac : « Déjà dans le Sac »
##   shop_5f               5e : objets X et Muscle +
##   battle_bag_items      Sac de combat, onglet COMBAT
##   battle_x_item         « Kevin utilise Attaque + ! »
##   battle_revive_targets Rappel en combat : Roucool K.O. seul possible
##   battle_revive         « Roucool reprend connaissance ! »
##   battle_doll           « Kevin lance la Poupée Poké. »
##   trainer_x_item        combat de Dresseur : « Kevin utilise Défense + ! »

const SEED := 7

var _out_dir: String = "build/captures/jalon20_t11"
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
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(60)
	_state.call(&"new_game", 5)
	_state.get(&"flags").call(&"set_flag", &"starter_chosen")
	_state.set(&"starter_species", &"charmander")
	_state.set(&"player_name", "Kevin")
	_state.set(&"money", 9000)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var party: Party = _state.get(&"party")
	for spec: Array in [[&"charmander", 24], [&"pidgey", 18]]:
		party.add(PokemonFactory.create(data, spec[0], spec[1], GameRng.new(SEED)))
	var bag: Bag = _state.get(&"bag")
	for spec: Array in [[&"revive", 3], [&"x_attack", 2], [&"x_defend", 2], [&"dire_hit", 1],
			[&"poke_doll", 2], [&"potion", 2]]:
		bag.add(spec[0], spec[1])
	await _menu_flow(party)
	await _shop_flow(bag)
	party.get_at(1).hp = 0
	await _battle_flow(data, true)
	await _battle_flow(data, false)
	print("CAPTURE_ITEMS_J20 terminé")
	quit()


func _menu_flow(party: Party) -> void:
	party.get_at(1).hp = 0
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	var screen: TrainerMenu = _boot.call(&"get_trainer_menu")
	menu.open(MenuRoute.bag())
	await _frames(40)
	screen.get_bag().select_item(&"revive")
	await _frames(10)
	screen.get_bag().get_action_button().pressed.emit()
	await _frames(40)
	await _shot("menu_revive_targets")
	menu.use_item_on(&"revive", 1)
	await _frames(40)
	await _shot("menu_revive_result")
	menu.close()
	await _frames(40)


func _shop_flow(bag: Bag) -> void:
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	for spec: Array in [[&"celadon_dept_2f_tm", "shop_tm"], [&"celadon_dept_5f", "shop_5f"]]:
		menu.open(MenuRoute.shop(spec[0]), true)
		await _frames(45)
		await _shot(spec[1])
		menu.close()
		await _frames(30)
	bag.add(&"tm01")
	menu.open(MenuRoute.shop(&"celadon_dept_2f_tm"), true)
	await _frames(45)
	await _shot("shop_tm_owned")
	menu.close()
	await _frames(30)


## Combat sauvage ([param wild]) : objet X, Rappel, puis Poupée Poké ; contre un Dresseur :
## Défense +, puis les attaques jusqu'à la fin.
func _battle_flow(data: PokemonData, wild: bool) -> void:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	var items: ItemLibrary = director.get_item_library()
	_state.set(&"rng", GameRng.new(SEED))
	var request: BattleRequest
	if wild:
		var enc := WildEncounter.new(&"rattata", 5, &"route_1_grass")
		request = BattleRequest.wild(enc, data, _state.get(&"rng") as GameRng, Vector2i(5, 4),
			items)
	else:
		var foes := Party.new()
		foes.add(PokemonFactory.create(data, &"oddish", 6, GameRng.new(SEED)))
		var trainers: TrainerLibrary = _boot.call(&"get_trainer_library")
		request = BattleRequest.trainer_battle(trainers.get_trainer(&"rival_route22"), foes, {},
			items)
	var map: GameMap = _boot.call(&"get_map")
	var done: Array[bool] = [false]
	var run := func() -> void:
		await director.run_request(request, map)
		done[0] = true
	run.call()
	# Étapes : [onglet, objet, cible, capture du Sac, phrase attendue, capture de la phrase].
	var plan: Array = [
		[&"battle", &"x_attack", -1, "battle_bag_items", "utilise Attaque +", "battle_x_item"],
		[&"heal", &"revive", 1, "", "reprend connaissance", "battle_revive"],
		[&"battle", &"poke_doll", -1, "", "Poupée Poké", "battle_doll"],
	] if wild else [[&"battle", &"x_defend", -1, "", "utilise Défense +", "trainer_x_item"]]
	var step: Array = []
	var waiting := ""
	var guard := 0
	while not done[0] and guard < 9000:
		guard += 1
		var panel := director.get_bag_panel()
		var picker := director.get_party_picker()
		var battle := director.get_battle()
		var text := hud.get_message_banner().get_text()
		if not waiting.is_empty() and text.contains(waiting):
			await _shot(step[5])
			waiting = ""
		if picker != null and picker.is_shown() and not step.is_empty() and int(step[2]) >= 0:
			await _frames(30)
			await _shot("battle_revive_targets")
			picker.target_chosen.emit(int(step[2]))
			step[2] = -1
			waiting = step[4]
		elif panel != null and panel.is_shown() and not panel.is_answered() \
				and not step.is_empty() and step[3] != "done":
			panel.open_category(step[0])
			panel.select_item(step[1])
			await _frames(30)
			if not String(step[3]).is_empty():
				await _shot(step[3])
			step[3] = "done"
			if int(step[2]) < 0:
				waiting = step[4]
			panel.get_action_button().pressed.emit()
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.ACTIONS and waiting.is_empty():
			if not plan.is_empty():
				step = plan.pop_front()
				hud.action_selected.emit(ActionGrid.BAG)
			else:
				step = []
				hud.action_selected.emit(ActionGrid.ATTACK)
		elif battle != null and battle.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.MOVES:
			hud.move_selected.emit(0)
		await _frames(1)
	if not done[0]:
		push_error("capture_items_j20 : le combat ne s'est pas terminé")
	await _frames(60)
