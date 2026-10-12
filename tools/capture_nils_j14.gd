extends SceneTree
## Capture du renommage de Nils (jalon 14, T4) : vraie scène Boot à Bourg Palette (départ
## `tools/debug_start/pallet_town.json`), réplique de Nils jouée depuis son PNJ ; la boîte de
## dialogue affiche le locuteur « Nils ».
##
##   godot --path . --resolution 1170x540 -s res://tools/capture_nils_j14.gd -- --out=build/captures/jalon14_t4

const START := "res://tools/debug_start/pallet_town.json"

var _out_dir: String = "build/captures/jalon14_t4"
var _boot: Node
var _frame: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"pallet_town")
	_boot.set(&"start_spawn", &"player_house_door")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	var data: Object = _boot.call(&"get_pokemon_data")
	var start: Object = load("res://game/systems/debug/debug_start.gd").new()
	if not start.call(&"load_file", START, data, _boot.call(&"get_item_library")):
		push_error("capture_nils_j14 : départ illisible")
	start.call(&"apply", root.get_node(^"/root/GameState"), data)
	process_frame.connect(_on_frame)


func _on_frame() -> void:
	_frame += 1
	if _frame == 40:
		var map: Node = _boot.call(&"get_map")
		var nils: Node = map.call(&"get_npc", &"nils")
		print("PNJ nils : %s" % nils)
		print("réplique jouée : %s" % _boot.call(&"get_dialogue_runner").call(
			&"play", &"nils", nils, map))
	if _frame == 160:
		DirAccess.make_dir_recursive_absolute(_out_dir)
		var path := _out_dir.path_join("nils_dialogue.png")
		root.get_texture().get_image().save_png(path)
		print("  -> %s" % path)
		quit()
