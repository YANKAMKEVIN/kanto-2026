extends SceneTree
## Captures de l'interface de combat du jalon 12 (T14) avec la vraie scène Boot : départ
## `tools/debug_start/poison_ui.json` (Jadielle) dont l'équipe est remplacée par Mélofée N12
## (Fée), Rondoudou N10 (Normal / Fée) et Salamèche N9 ; Pokédex débloqué (fixture de test).
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_combat_t14.gd -- --out=build/captures/jalon12_t14
##
## Le piège et l'Entrave sont posés directement sur le Battler (le moteur est celui du T13) et
## retirés avant le seul tour joué (la fuite finale). Images, préfixées par la largeur :
##   blocked_move     capacités : Écras'Face grisée, cadenas, « BLOQUÉE »
##   flee_refused     FUITE piégé : « Impossible de fuir ! » dans le bandeau
##   team_trapped     ÉQUIPE piégé : « Impossible de changer », pastilles Fée
##   team_refused     carte touchée : pied « Rondoudou : Impossible de changer »
##   menu_team        Équipe (menu) : fiche de Mélofée, pastille FÉE
##   dex_sheet        Pokédex : fiche de Mélofée, pastille FÉE

const START := "res://tools/debug_start/poison_ui.json"
const UNLOCKS := "res://tests/fixtures/debug_unlocks/pokedex.json"
const SEED := 11

var _out_dir: String = "build/captures/jalon12_t14"
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
	_boot.set(&"force_debug_unlocks", true)
	_boot.set(&"debug_unlocks_path", UNLOCKS)
	root.add_child(_boot)
	var data: PokemonData = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	if not start.call(&"load_file", START, data, _boot.call(&"get_item_library")):
		push_error("capture_combat_t14 : départ illisible")
	_state = root.get_node(^"/root/GameState")
	start.call(&"apply", _state, data)
	var party: Party = _state.get(&"party")
	party.clear()
	var team: Array = [[&"clefairy", 12, [&"pound", &"sing", &"growl", &"double_slap"]],
		[&"jigglypuff", 10, [&"sing", &"pound"]], [&"charmander", 9, [&"scratch", &"ember"]]]
	for entry: Array in team:
		var pokemon := PokemonFactory.create(data, entry[0], entry[1], GameRng.new(SEED))
		pokemon.moves.clear()
		for move_id: StringName in entry[2]:
			pokemon.learn_move(move_id, data)
		party.add(pokemon)
		_state.call(&"record_caught", entry[0], &"mt_moon_1f")
	await _frames(60)
	await _combat(data)
	await _menus()
	print("CAPTURE_COMBAT_T14 terminé")
	quit()


func _combat(data: PokemonData) -> void:
	var director: BattleDirector = _boot.call(&"get_battle_director")
	var hud: BattleHud = _boot.call(&"get_battle_hud")
	_state.set(&"rng", GameRng.new(SEED))
	var enc := WildEncounter.new(&"ekans", 8, &"route_1_grass")
	var request := BattleRequest.wild(enc, data, _state.get(&"rng") as GameRng, Vector2i(5, 4),
		director.get_item_library())
	var map: GameMap = _boot.call(&"get_map")
	var done: Array[bool] = [false]
	var run := func() -> void:
		await director.run_request(request, map)
		done[0] = true
	run.call()
	var step := 0
	var guard := 0
	while not done[0] and guard < 6000:
		guard += 1
		var battle := director.get_battle()
		var panel := director.get_party_panel()
		var choosing := battle != null and battle.get_state() == Battle.State.CHOOSING
		if choosing and hud.get_zone() == BattleHud.Zone.ACTIONS and step == 0:
			var lead := battle.get_player_side().active
			lead.trap_turns = 3
			lead.trap_move = &"wrap"
			lead.disabled_slot = 0
			lead.disabled_turns = 3
			await _frames(25)
			step = 1
			hud.action_selected.emit(ActionGrid.ATTACK)
		elif choosing and hud.get_zone() == BattleHud.Zone.MOVES and step == 1:
			await _frames(30)
			var grid := hud.get_move_grid()
			while grid.is_sliding():
				await _frames(1)
			await _frames(15)
			await _shot("blocked_move")
			step = 2
			hud.get_back_button().back_requested.emit()
		elif choosing and hud.get_zone() == BattleHud.Zone.ACTIONS and step == 2:
			await _frames(20)
			step = 3
			hud.action_selected.emit(ActionGrid.RUN)
			await _frames(18)
			await _shot("flee_refused")
		elif choosing and hud.get_zone() == BattleHud.Zone.ACTIONS and step == 3:
			await _frames(20)
			step = 4
			hud.action_selected.emit(ActionGrid.TEAM)
		elif panel != null and panel.is_shown() and not panel.is_answered() \
				and not panel.is_sliding() and step == 4:
			await _frames(20)
			await _shot("team_trapped")
			panel.get_card(1).tapped.emit()
			await _frames(30)
			await _shot("team_refused")
			step = 5
			panel.get_back_button().back_requested.emit()
		elif choosing and hud.get_zone() == BattleHud.Zone.ACTIONS and step == 5:
			var lead := battle.get_player_side().active
			lead.clear_trap()
			lead.clear_disable()
			await _frames(20)
			step = 6
			hud.action_selected.emit(ActionGrid.RUN)
		await _frames(1)
	if not done[0]:
		push_error("capture_combat_t14 : le combat ne s'est pas terminé (étape %d)" % step)
	await _frames(60)


func _menus() -> void:
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	menu.open(MenuRoute.team(0))
	await _frames(45)
	await _shot("menu_team")
	menu.close()
	await _frames(30)
	menu.open(MenuRoute.pokedex(MenuRoute.DEX_FILTER_ALL, &"clefairy"))
	await _frames(45)
	await _shot("dex_sheet")
	menu.close()
	await _frames(20)
