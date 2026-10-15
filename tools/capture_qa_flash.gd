extends SceneTree
## Captures de la carte de QA du voile (J17 T10, PROVISOIRE, retirée au T28 avec `qa_flash`)
## dans le **vrai Boot**, lancé sur un départ de débogage de `tools/debug_start/` :
##
##   godot --path . --resolution 2340x1080 --write-movie build/cap/f.png --fixed-fps 60 \
##     --quit-after 150 -s res://tools/capture_qa_flash.gd -- --start=flash_qa_dark
##
## Options : `--start=<départ>` (défaut flash_qa_dark), `--steps=dir:n` (pas joués après
## l'arrivée, 0,3 s chacun), `--nohud` (commandes tactiles cachées). La dernière image est la
## capture. Le journal donne la carte, la case du joueur et l'état du voile.

var _args: Dictionary = {}


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--"):
			var parts := arg.trim_prefix("--").split("=", true, 1)
			_args[parts[0]] = parts[1] if parts.size() > 1 else ""
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	var boot: Node = (load("res://game/boot.tscn") as PackedScene).instantiate()
	boot.set(&"debug_start_path", "res://tools/debug_start/%s.json"
		% String(_args.get("start", "flash_qa_dark")))
	boot.set(&"force_debug_start", true)
	root.add_child(boot)
	for i in 30:
		await process_frame
	if _args.has("nohud"):
		boot.call(&"get_hud").call(&"set_controls_visible", false)
	var player: Node = boot.call(&"get_player")
	if _args.has("steps"):
		var step: PackedStringArray = String(_args["steps"]).split(":")
		for i: int in int(step[1]):
			player.call(&"script_step", _direction(step[0]))
			await create_timer(0.3).timeout
		for i in 40:
			await process_frame
	var darkness: Node = boot.call(&"get_darkness")
	print("capture_qa_flash : carte %s, joueur %s, voile %s, Flash %s" % [
		boot.call(&"get_map").get(&"map_id"), player.call(&"get_cell"),
		darkness.call(&"is_dark"), darkness.call(&"is_lit")])


func _direction(name: String) -> Vector2i:
	match name:
		"up":
			return Vector2i.UP
		"left":
			return Vector2i.LEFT
		"right":
			return Vector2i.RIGHT
	return Vector2i.DOWN
