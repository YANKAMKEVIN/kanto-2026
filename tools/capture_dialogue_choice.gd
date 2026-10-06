extends SceneTree
## Capture du choix dans la boîte de dialogue (jalon 7, T7) : la question de l'infirmière du
## Centre, vues fabriquées (aucun câblage du Centre requis). Boot sur un intérieur (décor seul),
## boîte ouverte sur la réplique, puis choix SOIGNER / PAS MAINTENANT ; variante texte Grande.
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 400 \
##     -s res://tools/capture_dialogue_choice.gd -- --out=build/captures/jalon07_t7
## Images : nurse_choice, nurse_choice_large.

var _boot: Node
var _box: Node
var _out_dir: String = "build/captures/jalon07_t7"
var _frame: int = 0
var _shot: String = ""


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"player_house_1f")
	_boot.set(&"start_spawn", &"entrance")
	root.add_child(_boot)
	process_frame.connect(_on_frame)


func _view() -> RefCounted:
	var view: RefCounted = load("res://game/systems/menu/views/choice_view.gd").new(
		"Veux-tu soigner tes Pokémon ?", "SOIGNER", "PAS MAINTENANT")
	view.confirm_detail = "Toute l'équipe, en quelques secondes."
	return view


func _on_frame() -> void:
	_frame += 1
	if not _shot.is_empty():
		_save(_shot)
		_shot = ""
	match _frame:
		40:
			_box = _boot.call(&"get_dialogue_box")
			_box.open()
			_box.show_page("Infirmière", "Bienvenue au Centre Pokémon !", false)
			_box.set_visible_characters(-1)
		70:
			_box.show_choice(_view())
		110:
			_shot = "nurse_choice"
		120:
			_box.hide_choice()
			var settings: RefCounted = load("res://game/systems/settings/game_settings.gd").new()
			settings.text_size = 1
			settings.high_contrast = true
			load("res://game/systems/settings/ui_prefs.gd").apply(settings)
			_box.show_choice(_view())
		170:
			_shot = "nurse_choice_large"
		180:
			quit()


func _save(capture_name: String) -> void:
	DirAccess.make_dir_recursive_absolute(_out_dir)
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  -> %s" % path)
