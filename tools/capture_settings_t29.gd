extends SceneTree
## Captures du T29 (jalon 6) sur le vrai Boot (Route 1), réglages et sauvegarde en mémoire :
##   settings_game      Paramètres, catégorie JEU
##   settings_eco       GRAPHISMES après avoir touché « Économie » (fond du menu sans flou)
##   left_handed        exploration après avoir touché « Mode gaucher »
##   text_large         Paramètres en texte Grande
##   forget_confirm     combat : confirmation d'oubli (ChoiceCards) au-dessus du panneau d'oubli
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 2000 \
##     -s res://tools/capture_settings_t29.gd -- --out=build/captures/jalon06_t29

const MEMORY_FS: String = "res://tests/helpers/memory_file_system.gd"
const STORE: String = "res://game/systems/settings/settings_store.gd"
const PANEL_SCENE: String = "res://game/ui/battle/move_forget_panel.tscn"
const HUD_SCENE: String = "res://game/ui/battle/battle_hud.tscn"

var _boot: Node
var _out_dir: String = "build/captures/jalon06_t29"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	var fs: RefCounted = (load(MEMORY_FS) as GDScript).new()
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	_boot.set(&"settings_store", (load(STORE) as GDScript).new(fs, "user://cap_settings.json"))
	root.add_child(_boot)
	await _frames(60)
	_boot.call(&"get_trainer_menu").set(&"speed_scale", 0.0)
	var director: Node = _boot.call(&"get_menu_director")
	director.call(&"open", load("res://game/systems/menu/menu_route.gd").call(&"settings"))
	await _frames(10)
	await _shot("settings_game")
	var screen: Node = _boot.call(&"get_trainer_menu").call(&"get_settings")
	screen.call(&"select_category", &"graphics")
	await _frames(3)
	_choose(screen, &"graphics", 2)
	await _frames(10)
	await _shot("settings_eco")
	_choose(screen, &"graphics", 1)
	screen.call(&"select_category", &"accessibility")
	await _frames(3)
	_choose(screen, &"text_size", 1)
	await _frames(10)
	await _shot("text_large")
	_choose(screen, &"text_size", 0)
	screen.call(&"select_category", &"controls")
	await _frames(3)
	screen.call(&"get_row", &"left_handed").pressed.emit()
	await _frames(3)
	director.call(&"close")
	await _frames(15)
	await _shot("left_handed")
	await _forget()
	print("CAPTURE_T29 terminé")
	quit()


func _choose(screen: Node, key: StringName, index: int) -> void:
	var row: Node = screen.call(&"get_row", key)
	var buttons: Array = row.call(&"get_option_buttons")
	(buttons[index] as Button).pressed.emit()


## Confirmation d'oubli en combat : panneau d'oubli sous le voile, puis ChoiceCards plein cadre
## comme le fait BattleDirector._confirm_forget.
func _forget() -> void:
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.call(&"set_controls_visible", false)
	var stage := CanvasLayer.new()
	stage.layer = 5
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.05, 0.08, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(dim)
	root.add_child(stage)
	var hud: CanvasLayer = (load(HUD_SCENE) as PackedScene).instantiate() as CanvasLayer
	root.add_child(hud)
	hud.set(&"haptics_enabled", false)
	await _frames(2)
	var data := load("res://game/pokemon/pokemon_data.gd") as GDScript
	var battle_views := load("res://game/battle/battle_views.gd") as GDScript
	var pokemon_data: RefCounted = data.new()
	pokemon_data.call(&"load_dir")
	var panel: Control = (load(PANEL_SCENE) as PackedScene).instantiate() as Control
	hud.call(&"get_screen").add_child(panel)
	var layout := load("res://game/ui/battle/battle_hud_layout.gd") as GDScript
	layout.call(&"place", panel, layout.get(&"Slot")["FORGET"])
	panel.set(&"speed_scale", 0.0)
	panel.set(&"haptics_enabled", false)
	var ids: Array = [&"scratch", &"growl", &"ember", &"leer"]
	var offered: RefCounted = battle_views.call(&"offered_move", &"rage", pokemon_data)
	var typed := Array([], TYPE_OBJECT, &"RefCounted", offered.get_script())
	for id: StringName in ids:
		typed.append(battle_views.call(&"offered_move", id, pokemon_data))
	panel.call(&"show_offer", offered, typed)
	await _frames(15)
	panel.call(&"select", 2)
	await _frames(3)
	var cards: Control = (load("res://game/ui/components/choice_cards.gd") as GDScript).new()
	cards.set(&"speed_scale", 0.0)
	hud.call(&"get_screen").add_child(cards)
	cards.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var view: RefCounted = (load("res://game/systems/menu/views/choice_view.gd") as GDScript).new(
		"Oublier Flammèche ?", "OUBLIER", "GARDER")
	view.set(&"detail", "Flammèche sera remplacée par Frénésie.")
	cards.call(&"show_choice", view)
	await _frames(10)
	await _shot("forget_confirm")


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await process_frame
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
