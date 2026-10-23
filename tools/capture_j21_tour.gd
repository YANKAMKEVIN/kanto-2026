extends SceneTree
## Captures du jalon 21 (T12 à T14) sur le vrai Boot : 7F, 6F brume légère (`tower_6f_mist_lifted`),
## 6F brume dense, maison de M. Fuji (`fuji_rescued`) :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_j21_tour.gd \
##     -- --out=build/captures/jalon21_tour

## [nom, carte, arrivée, orientation, case (-1 : aucune), drapeaux à lever]
const SHOTS: Array = [
	["7f", &"pokemon_tower_7f", &"arrivee_T67", Vector2i.UP, Vector2i(10, 13), []],
	["7f_fuji", &"pokemon_tower_7f", &"arrivee_T67", Vector2i.UP, Vector2i(10, 5), []],
	["6f_brume_dense", &"pokemon_tower_6f", &"arrivee_T67", Vector2i.UP, Vector2i(-1, -1), []],
	["6f_brume_legere", &"pokemon_tower_6f", &"arrivee_T67", Vector2i.UP, Vector2i(-1, -1),
		[&"ghost_marowak_calmed", &"tower_6f_mist_lifted"]],
	["maison_fuji", &"pokemon_house", &"devant_fuji", Vector2i.UP, Vector2i(-1, -1),
		[&"fuji_rescued"]],
]

var _boot: Node
var _router: Node
var _out_dir: String = "build/captures/jalon21_tour"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"pokemon_tower_7f")
	_boot.set(&"start_spawn", &"arrivee_T67")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	_router = root.get_node(^"SceneRouter")
	(_boot.call(&"get_hud") as CanvasLayer).visible = false
	for shot: Array in SHOTS:
		var map_id: StringName = shot[1]
		var game_state: Node = root.get_node(^"GameState")
		for flag: StringName in shot[5]:
			game_state.get(&"flags").call(&"set_flag", flag)
		if _boot.call(&"get_map").map_id != map_id or shot[0] == "6f_brume_legere":
			_router.call(&"change_map", map_id, shot[2], shot[3])
			while _boot.call(&"get_map").map_id != map_id \
					or bool(_router.call(&"is_transitioning")):
				await process_frame
		var cell: Vector2i = shot[4]
		if cell.x >= 0:
			var map: GameMap = _boot.call(&"get_map")
			(_boot.call(&"get_player") as Player).enter_map(map.get_grid(), cell, shot[3],
				map.get_pixel_rect())
		await _frames(60)
		root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, shot[0]])
		print("CAPTURE ", shot[0])
	quit()
