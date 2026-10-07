extends SceneTree
## Relecture UI du T21 (jalon 9) : bouton PRENDRE devant l'Antidote d'O1, Carte sur la zone
## « Forêt de Jade », fiche Pokédex d'Aspicot (habitat « Forêt de Jade »), vrai Boot et départ
## de débogage de la forêt.
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 2000 \
##     -s res://tools/capture_forest_ui_t21.gd -- --out=build/captures/jalon09_t21

var _boot: Node
var _out_dir: String = "build/captures/jalon09_t21"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(3)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"debug_start_path", "res://tools/debug_start/viridian_forest.json")
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	await _frames(90)
	var map: GameMap = _boot.call(&"get_map")
	var player: Player = _boot.call(&"get_player")
	var ball := map.get_npc(&"viridian_forest_item_1")
	var cell := ball.get_cell()
	map.spawn_player_at(player, cell + Vector2i(-1, 0), Vector2i.RIGHT)
	await _frames(40)
	await _shot("ui_prendre")
	var state: Node = root.get_node("GameState")
	state.call(&"discover_map", &"viridian_forest")
	state.call(&"discover_map", &"viridian_forest_gate_north")
	state.call(&"record_seen", &"weedle", &"viridian_forest")
	state.call(&"record_seen", &"metapod", &"viridian_forest")
	state.call(&"record_caught", &"caterpie", &"viridian_forest")
	var menu: MenuDirector = _boot.call(&"get_menu_director")
	menu.open(MenuRoute.map(&"viridian_forest"))
	await _frames(60)
	await _shot("ui_carte_foret")
	menu.close()
	await _frames(30)
	menu.open(MenuRoute.pokedex(MenuRoute.DEX_FILTER_ALL, &"weedle"))
	await _frames(60)
	await _shot("ui_pokedex_aspicot")
	menu.close()
	await _frames(20)
	menu.open(MenuRoute.pokedex())
	await _frames(60)
	await _shot("ui_pokedex_liste")
	print("CAPTURE_FOREST_UI_T21 terminé")
	quit()
