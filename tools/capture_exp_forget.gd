extends SceneTree
## Vérification visuelle de l'XP, du niveau et du panneau d'oubli (jalon 5C, T10) : la vraie
## BattleHud et le MoveForgetPanel sur la Route 1, sous le voile du combat (FADE_COLOR à
## BATTLE_DIM). Sans directeur (T11) : l'outil pilote les composants à la main, avec les
## sprites provisoires aux ancres du §14.4. Noms et capacités lus dans data/pokemon/.
##
## Sur le Mac (la résolution fixe la taille du viewport) :
##   godot --path . --resolution 2340x1080 --always-on-top --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_exp_forget.gd -- --out=build/captures/jalon05c_t10 [--suffix=_1920]
## Images (préfixe jalon05c_t10_) :
##   exp_gain      « +21 XP » qui monte et barre d'XP en cours de remplissage (carte joueur)
##   exp_full      barre d'XP pleine (fin de la première tranche, avant « Nv. 6 »)
##   level_up      « Nv. 6 » pulse (grossi, ACCENT), PV max 22, barre d'XP de la tranche suivante
##   forget        panneau d'oubli, rien de choisi : OUBLIER inactif
##   forget_pick   Flammèche choisie : liseré d'accent, OUBLIER actif
##   forget_pp0    carte à 0 PP choisie (reste choisissable, PP en rouge)
##   forget_sheet  pression longue sur Rugissement : fiche de la capacité

const BOOT_SCENE: String = "res://game/boot.tscn"
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const HUD_SCENE: String = "res://game/ui/battle/battle_hud.tscn"
const PANEL_SCENE: String = "res://game/ui/battle/move_forget_panel.tscn"
const UI_DIR: String = "res://game/ui/battle/"
const SPRITES_DIR: String = "res://assets/sprites/pokemon/placeholder/"
const MOVES_PATH: String = "res://data/pokemon/moves/moves.json"
const TYPES_PATH: String = "res://data/pokemon/types.json"
const PREFIX: String = "jalon05c_t10_"
const PLAYER := 0
const FOE := 1
const WILD_ACTIONS: Dictionary[StringName, bool] = {&"attack": true, &"run": true}

var _boot: Node
var _tokens: GDScript
var _out_dir: String = "build/captures/jalon05c_t10"
var _suffix: String = ""
var _card_view: GDScript
var _move_view: GDScript
var _layout: GDScript
var _hud: CanvasLayer
var _panel: Control
var _stage: CanvasLayer
var _moves: Dictionary = {}
var _types: Dictionary = {}


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--suffix="):
			_suffix = arg.trim_prefix("--suffix=")
	_tokens = load(TOKENS_PATH) as GDScript
	_card_view = load(UI_DIR + "battle_card_view.gd") as GDScript
	_move_view = load(UI_DIR + "battle_move_view.gd") as GDScript
	_layout = load(UI_DIR + "battle_hud_layout.gd") as GDScript
	_moves = JSON.parse_string(FileAccess.get_file_as_string(MOVES_PATH))
	_types = JSON.parse_string(FileAccess.get_file_as_string(TYPES_PATH))["types"]
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	root.add_child(_boot)
	await _frames(20)
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.call(&"hide_interact")
	explo.call(&"set_controls_visible", false)
	await _frames(10)
	_build_stage()
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as CanvasLayer
	root.add_child(_hud)
	_hud.set(&"haptics_enabled", false)
	await _frames(2)
	await _exp()
	await _forget()
	print("CAPTURE_EXP_FORGET terminé")
	quit()


## Gain d'XP puis montée de niveau, à vitesse réelle (images à 30 par seconde).
func _exp() -> void:
	_hud.call(&"set_party", 6)
	_hud.call(&"set_card", FOE, _card_view.new("Rattata", 1, 3, 0, 14, false))
	_hud.call(&"set_card", PLAYER, _card_view.new("Salamèche", 1, 5, 19, 19, true))
	_hud.call(&"show_actions", WILD_ACTIONS)
	await _frames(30)
	_hud.call(&"animate_exp", 0.45, 1.0, 21)
	await _frames(9)
	await _shot("exp_gain")
	await _frames(10)
	await _shot("exp_full")
	await _frames(20)
	_hud.call(&"pulse_level", PLAYER, 6)
	_hud.call(&"animate_hp", PLAYER, 22, 22, false)
	_hud.call(&"animate_exp", 0.0, 0.2, 0)
	_hud.call(&"show_message", "Salamèche monte au niveau 6 !")
	await _frames(1)
	await _shot("level_up")
	await _frames(40)
	await _hud.call(&"hide_all")
	await _frames(6)


func _forget() -> void:
	_panel = (load(PANEL_SCENE) as PackedScene).instantiate() as Control
	_hud.call(&"get_screen").add_child(_panel)
	_layout.call(&"place", _panel, _layout.get(&"Slot")["FORGET"])
	_panel.set(&"haptics_enabled", false)
	_panel.set(&"speed_scale", 0.0)
	_hud.call(&"set_party", 6)
	_hud.call(&"set_card", FOE, _card_view.new("Rattata", 1, 3, 14, 14, false))
	_hud.call(&"set_card", PLAYER, _card_view.new("Salamèche", 1, 22, 55, 55, true))
	await _frames(20)
	var new_move: RefCounted = _move_views([&"rage"], [20])[0]
	var known: Array = _typed(_move_views(
		[&"scratch", &"growl", &"ember", &"leer"], [35, 40, 25, 30]))
	_panel.call(&"show_offer", new_move, known)
	await _frames(10)
	await _shot("forget")
	_panel.call(&"select", 2)
	await _frames(4)
	await _shot("forget_pick")
	known = _typed(_move_views([&"scratch", &"growl", &"ember", &"leer"], [35, 40, 25, 0]))
	_panel.call(&"show_offer", new_move, known)
	_panel.call(&"select", 3)
	await _frames(4)
	await _shot("forget_pp0")
	_panel.call(&"show_offer", new_move, _typed(_move_views(
		[&"scratch", &"growl", &"ember", &"leer"], [35, 40, 25, 30])))
	_panel.call(&"select", 2)
	var growl: Control = _panel.call(&"get_card", 1)
	var center := growl.get_global_rect().get_center()
	_touch(center, true)
	await _frames(int(_tokens.LONG_PRESS * 30.0) + 8)
	await _shot("forget_sheet")
	_touch(center, false)
	await _frames(6)


func _touch(position: Vector2, pressed: bool) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = position
	mouse.global_position = position
	mouse.pressed = pressed
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	root.push_input(mouse, true)


## Vues des capacités [param ids] (données réelles) avec les PP [param pp].
func _move_views(ids: Array, pp: Array) -> Array:
	var categories: Dictionary = {"physical": 0, "special": 1, "status": 2}
	var views: Array = []
	for i: int in ids.size():
		var move: Dictionary = _moves[String(ids[i])]
		views.append(_move_view.new(move["name"], StringName(move["type"]),
			_types[move["type"]]["name"], categories[move["category"]], pp[i],
			int(move["pp"]), int(move.get("power", 0)), int(move.get("accuracy", 0)),
			move.get("description", "")))
	return views


## Array[BattleMoveView] attendu par show_offer (la classe n'est pas connue de l'outil).
func _typed(views: Array) -> Array:
	var typed := Array([], TYPE_OBJECT, &"RefCounted", _move_view)
	typed.assign(views)
	return typed


## Voile du combat, et sprites provisoires aux ancres prévues s'ils existent.
func _build_stage() -> void:
	_stage = CanvasLayer.new()
	_stage.layer = _tokens.LAYER_BATTLE_STAGE
	var dim := ColorRect.new()
	dim.color = Color(_tokens.FADE_COLOR, _tokens.BATTLE_DIM)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(dim)
	root.add_child(_stage)
	var view := root.get_visible_rect().size
	_add_battler("charmander_back.png", Vector2(0.30, 0.76) * view, 4)
	_add_battler("rattata_front.png", Vector2(0.66, 0.52) * view, 3)


func _add_battler(file: String, feet: Vector2, scale: int) -> void:
	if not ResourceLoader.exists(SPRITES_DIR + file):
		return
	var sprite := Sprite2D.new()
	sprite.texture = load(SPRITES_DIR + file) as Texture2D
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2.ONE * scale
	var size := sprite.texture.get_size() * scale
	sprite.position = feet - Vector2(size.x * 0.5, size.y)
	_stage.add_child(sprite)


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
