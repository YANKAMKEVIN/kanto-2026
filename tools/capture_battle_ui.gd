extends SceneTree
## Outil de vérification visuelle de l'interface de combat (jalon 4B, composants de
## game/ui/battle/) posée sur le vrai labo (oak_lab, Chen et le rival présents, contrôles
## d'exploration cachés). Pas de BattleHud ni de BattleStage (T6/T8) : l'outil place lui-même
## les composants aux emplacements de BattleHudLayout, et un voile FADE_COLOR à BATTLE_DIM
## imite celui du futur BattleStage (sauf images « _nodim », pour juger le pire cas).
##
## Fenêtre : override.cfg temporaire à la racine (window_width/height_override), puis :
##   xvfb-run -a -s "-screen 0 2340x1080x24" godot --path . --rendering-driver opengl3 \
##     --fixed-fps 30 --quit-after 3000 -s res://tools/capture_battle_ui.gd -- \
##     --out=build/captures/jalon04b_ui [--suffix=_1920] [--only=cards,actions]
## Chaque image est la texture du viewport, enregistrée sous <out>/<nom><suffixe>.png.
## Images (préfixe jalon04b_ui_) :
##   cards          cartes + pastilles seules (SALAMÈCHE ♂ 19/19 contre CARAPUCE ♀)
##   cards_slide    cartes en train d'entrer (glissement + fondu)

const BOOT_SCENE: String = "res://game/boot.tscn"
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const UI_DIR: String = "res://game/ui/battle/"
## Case du joueur (devant la table des starters, rival à sa gauche), tournée vers le haut.
const PLAYER_CELL := Vector2i(10, 7)
const PREFIX: String = "jalon04b_ui_"

var _boot: Node
var _tokens: GDScript
var _out_dir: String = "build/captures/jalon04b_ui"
var _suffix: String = ""
var _only: PackedStringArray = []
var _layout: GDScript
var _card_view: GDScript
var _move_view: GDScript
var _dim: ColorRect
var _screen: Control
var _parts: Dictionary[StringName, Control] = {}


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--suffix="):
			_suffix = arg.trim_prefix("--suffix=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
	_tokens = load(TOKENS_PATH) as GDScript
	_layout = load(UI_DIR + "battle_hud_layout.gd") as GDScript
	_card_view = load(UI_DIR + "battle_card_view.gd") as GDScript
	_move_view = load(UI_DIR + "battle_move_view.gd") as GDScript
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"oak_lab")
	_boot.set(&"start_spawn", &"entrance")
	root.add_child(_boot)
	await _frames(5)
	var state: Node = root.get_node(^"GameState")
	var flags: RefCounted = state.get(&"flags")
	flags.call(&"set_flag", &"oak_met")
	var lab: Node = _boot.call(&"get_map")
	lab.call(&"refresh_npcs", flags)
	var player: Node = _boot.call(&"get_player")
	player.call(&"enter_map", lab.call(&"get_grid"), PLAYER_CELL, Vector2i.UP,
		lab.call(&"get_pixel_rect"))
	var hud: CanvasLayer = _boot.call(&"get_hud")
	hud.call(&"hide_interact")
	hud.call(&"set_controls_visible", false)
	_build_overlay()
	await _frames(20)
	await _run()
	print("CAPTURE_BATTLE_UI terminé")
	quit()


func _build_overlay() -> void:
	var stage := CanvasLayer.new()
	stage.layer = _tokens.LAYER_BATTLE_STAGE
	_dim = ColorRect.new()
	_dim.color = Color(_tokens.FADE_COLOR, _tokens.BATTLE_DIM)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_dim)
	root.add_child(stage)
	var hud := CanvasLayer.new()
	hud.layer = _tokens.LAYER_BATTLE_HUD
	_screen = Control.new()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_screen)
	root.add_child(hud)
	var slot: Dictionary = _layout.get(&"Slot")
	_add(&"foe", "battle_info_card.tscn", slot["FOE_CARD"])
	_add(&"own", "battle_info_card.tscn", slot["OWN_CARD"])
	_add(&"pips", "party_pips.tscn", slot["PARTY_PIPS"])
	(_parts[&"foe"] as Control).set(&"slide_direction", Vector2.RIGHT)
	(_parts[&"own"] as Control).set(&"slide_direction", Vector2.LEFT)


func _add(key: StringName, scene: String, slot: int) -> void:
	var control := (load(UI_DIR + scene) as PackedScene).instantiate() as Control
	control.set(&"haptics_enabled", false)
	_screen.add_child(control)
	_layout.call(&"place", control, slot)
	_parts[key] = control


func _run() -> void:
	var foe: Control = _parts[&"foe"]
	var own: Control = _parts[&"own"]
	var pips: Control = _parts[&"pips"]
	foe.call(&"set_view", _card(&"Carapuce", 2, 20, 20, false))
	own.call(&"set_view", _card(&"Salamèche", 1, 19, 19, true))
	pips.call(&"set_party", 1)
	if _wants("cards"):
		_slide_all([foe, own, pips], 1.0)
		await _frames(4)
		await _shot("cards_slide")
		await _frames(15)
		await _shot("cards")


func _card(name: String, gender: int, hp: int, max_hp: int, numbers: bool) -> RefCounted:
	return _card_view.new(name, gender, 5, hp, max_hp, numbers)


func _slide_all(controls: Array, scale: float) -> void:
	for control: Control in controls:
		control.set(&"speed_scale", scale)
		control.call(&"slide_in")


func _wants(name: String) -> bool:
	return _only.is_empty() or _only.has(name)


## Enregistre l'image affichée à l'image suivante (celle qui contient l'état courant).
func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join(PREFIX + name + _suffix + ".png")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
