extends SceneTree
## Captures du jalon 30 (T9) sur le vrai Boot : salles de la Ligue en tuiles provisoires (battants
## des portes, membres, Chen, Panthéon) :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_j30_league.gd \
##     -- --out=build/captures/jalon30_ligue

const STAGES: Array[StringName] = [&"league_stage_0_cleared", &"league_stage_1_cleared",
	&"league_stage_2_cleared", &"league_stage_3_cleared", &"league_stage_4_cleared"]

## [nom, carte, arrivée, orientation, case (-1 : aucune), drapeaux à lever]
const SHOTS: Array = [
	["olga_entree", &"league_lorelei", &"from_lobby", Vector2i.UP, Vector2i(-1, -1), []],
	["olga_face", &"league_lorelei", &"from_lobby", Vector2i.UP, Vector2i(5, 3), []],
	["aldo", &"league_bruno", &"from_south", Vector2i.UP, Vector2i(5, 5),
		[&"league_stage_0_cleared"]],
	["peter", &"league_lance", &"from_south", Vector2i.LEFT, Vector2i(-1, -1),
		[&"league_stage_0_cleared", &"league_stage_1_cleared", &"league_stage_2_cleared"]],
	["champion_chen", &"league_champion", &"from_south", Vector2i.UP, Vector2i(4, 4), STAGES],
	["pantheon", &"hall_of_fame", &"from_south", Vector2i.UP, Vector2i(-1, -1), STAGES],
]

var _boot: Node
var _router: Node
var _out_dir: String = "build/captures/jalon30_ligue"


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
	_boot.set(&"start_map", &"league_lorelei")
	_boot.set(&"start_spawn", &"from_lobby")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	_router = root.get_node(^"SceneRouter")
	(_boot.call(&"get_hud") as CanvasLayer).visible = false
	var game_state: Node = root.get_node(^"GameState")
	for shot: Array in SHOTS:
		var map_id: StringName = shot[1]
		for flag: StringName in shot[5]:
			game_state.get(&"flags").call(&"set_flag", flag)
		_router.call(&"change_map", map_id, shot[2], shot[3])
		await _frames(10)
		while _boot.call(&"get_map").map_id != map_id or bool(_router.call(&"is_transitioning")):
			await process_frame
		var cell: Vector2i = shot[4]
		if cell.x >= 0:
			var map: GameMap = _boot.call(&"get_map")
			(_boot.call(&"get_player") as Player).enter_map(map.get_grid(), cell, shot[3],
				map.get_pixel_rect())
		await _frames(90)
		root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, shot[0]])
		print("CAPTURE ", shot[0])
	quit()
