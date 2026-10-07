extends SceneTree
## Capture de la carte de présentation du Champion (jalon 10, T5) sur le vrai monde (Bourg
## Palette, Boot) : le joueur ne bouge pas, le HUD affiche « PIERRE ».
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_champion_card.gd -- --out=build/captures/j10_t5_carte
##
## Images : champion_card_slide (en cours d'entrée), champion_card_hold (tenue),
## champion_card_reduced (sans glissé, « Réduire les animations »). Le nom de fichier porte la
## largeur de la fenêtre (…_2340.png). Mac seulement (rendu réel, pas en headless).

var _out_dir: String = "build/captures/j10_t5_carte"
var _boot: Node
var _hud: Node
var _frame: int = 0


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"pallet_town")
	_boot.set(&"start_spawn", &"start")
	root.add_child(_boot)
	_hud = _boot.call(&"get_hud")
	process_frame.connect(_on_frame)


func _shot(shot_name: String) -> void:
	var width := root.get_visible_rect().size.x
	var path := "%s/%s_%d.png" % [_out_dir, shot_name, int(width)]
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path)


func _on_frame() -> void:
	_frame += 1
	var card: Object = _hud.call(&"get_champion_card")
	match _frame:
		120:
			_hud.call(&"hide_zone_title")
		150:
			_hud.call(&"show_champion_card", "Pierre", "Champion d'Arène d'Argenta")
		158:
			_shot("champion_card_slide")
		200:
			_shot("champion_card_hold")
		205:
			card.call(&"skip_hold")
		300:
			card.set(&"reduce_motion", true)
			_hud.call(&"show_champion_card", "Pierre", "Champion d'Arène d'Argenta")
		330:
			_shot("champion_card_reduced")
		340:
			quit()
