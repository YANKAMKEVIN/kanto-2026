extends SceneTree
## Captures de la lumière de la Tour Pokémon (jalon 19, T19), sur le vrai Boot, 2F à 6F :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_tower_t19.gd \
##     -- --out=build/captures/jalon19_t19
## Une image par étage à l'arrivée par l'escalier, plus la zone purifiée du 5F.

const SHOTS: Array = [
	["2f", &"pokemon_tower_2f", &"arrivee_T12", Vector2i.UP, Vector2i(-1, -1)],
	["3f", &"pokemon_tower_3f", &"arrivee_T23", Vector2i.UP, Vector2i(-1, -1)],
	["4f", &"pokemon_tower_4f", &"arrivee_T34", Vector2i.UP, Vector2i(-1, -1)],
	["5f", &"pokemon_tower_5f", &"arrivee_T45", Vector2i.UP, Vector2i(-1, -1)],
	["5f_zone", &"pokemon_tower_5f", &"arrivee_T45", Vector2i.UP, Vector2i(10, 11)],
	["6f", &"pokemon_tower_6f", &"arrivee_T56", Vector2i.UP, Vector2i(-1, -1)],
	["6f_spectre", &"pokemon_tower_6f", &"devant_spectre", Vector2i.UP, Vector2i(-1, -1)],
]

var _boot: Node
var _router: Node
var _out_dir: String = "build/captures/jalon19_t19"


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
	_boot.set(&"start_map", &"pokemon_tower_2f")
	_boot.set(&"start_spawn", &"arrivee_T12")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	_router = root.get_node(^"SceneRouter")
	(_boot.call(&"get_hud") as CanvasLayer).visible = false
	for shot: Array in SHOTS:
		var map_id: StringName = shot[1]
		if _boot.call(&"get_map").map_id != map_id:
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
