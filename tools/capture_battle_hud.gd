extends SceneTree
## Outil de vérification visuelle de la BattleHud assemblée et du toast (jalon 4B, T7), sur le
## vrai labo (oak_lab, Chen et le rival présents, contrôles d'exploration cachés).
## Sans vue de combat (T6) ni directeur (T8) : un voile FADE_COLOR à BATTLE_DIM imite celui du
## combat ; si les sprites provisoires de T6 existent, ils sont posés aux ancres prévues au
## §14.4 (pieds (0,30 ; 0,76) ×4 de dos, (0,66 ; 0,52) ×3 de face), à titre indicatif.
##
## Sur le Mac : override.cfg temporaire à la racine (window_width/height_override = 2340×1080),
## puis :
##   godot --path . --always-on-top --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_battle_hud.gd -- --out=build/captures/jalon04b_t7
## Images (préfixe jalon04b_t7_) :
##   message      « Le Rival envoie Carapuce ! », cartes et pastilles en place
##   actions      grille du premier combat (ATTAQUER mis en avant, les autres atténuées)
##   moves        Griffe + Rugissement, Griffe sélectionnée, « ‹ »
##   detail       pression longue réelle sur Griffe : fiche détaillée
##   hp_low       PV bas (joueur 3/19 rouge, adversaire 9/20 jaune), message d'attaque
##   switching    image au milieu du passage grille → message (une seule zone visible)
##   toast        toast « Poké Balls ×5 — Ajoutées au Sac » sur le labo, hors combat

const BOOT_SCENE: String = "res://game/boot.tscn"
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const HUD_SCENE: String = "res://game/ui/battle/battle_hud.tscn"
const UI_DIR: String = "res://game/ui/battle/"
const SPRITES_DIR: String = "res://assets/sprites/pokemon/placeholder/"
const PLAYER_CELL := Vector2i(10, 7)
const PREFIX: String = "jalon04b_t7_"
const PLAYER := 0
const FOE := 1

var _boot: Node
var _tokens: GDScript
var _out_dir: String = "build/captures/jalon04b_t7"
var _card_view: GDScript
var _move_view: GDScript
var _hud: CanvasLayer
var _stage: CanvasLayer


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	_tokens = load(TOKENS_PATH) as GDScript
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
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.call(&"hide_interact")
	explo.call(&"set_controls_visible", false)
	await _frames(20)
	await _battle()
	await _toast(explo)
	print("CAPTURE_BATTLE_HUD terminé")
	quit()


func _battle() -> void:
	_build_stage()
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as CanvasLayer
	root.add_child(_hud)
	_hud.set(&"haptics_enabled", false)
	await _frames(2)
	_hud.call(&"set_party", 1)
	_hud.call(&"set_card", FOE, _card_view.new("Carapuce", 2, 5, 20, 20, false))
	_hud.call(&"set_card", PLAYER, _card_view.new("Salamèche", 1, 5, 19, 19, true))
	_hud.call(&"show_message", "Le Rival envoie Carapuce !")
	await _frames(20)
	await _shot("message")
	var first: Dictionary[StringName, bool] = {&"attack": true}
	_hud.call(&"show_actions", first)
	await _frames(25)
	await _shot("actions")
	_hud.call(&"show_moves", _moves())
	await _frames(25)
	var grid: Control = _hud.call(&"get_move_grid")
	grid.call(&"select", 0)
	await _frames(4)
	await _shot("moves")
	grid.call(&"select", -1)
	var card: Control = grid.call(&"get_card", 0)
	var center := card.get_global_rect().get_center()
	_touch(center, true)
	await _frames(int(ceil(_tokens.LONG_PRESS * 30.0)) + 10)
	await _shot("detail")
	_touch(center, false)
	await _frames(8)
	_hud.call(&"show_actions", first)
	await _frames(25)
	_hud.call(&"show_message", "Carapuce utilise Charge !")
	await _frames(4)
	await _shot("switching")
	await _frames(15)
	var own: Control = _hud.call(&"get_card", PLAYER)
	var foe: Control = _hud.call(&"get_card", FOE)
	own.call(&"set_hp", 3, 19)
	foe.call(&"set_hp", 9, 20)
	await _frames(10)
	await _shot("hp_low")
	await _hud.call(&"hide_all")
	await _frames(4)
	_hud.queue_free()
	_stage.queue_free()
	await _frames(10)


func _toast(explo: CanvasLayer) -> void:
	var toast: Control = explo.call(&"get_toast")
	toast.set(&"haptics_enabled", false)
	explo.call(&"show_toast", "Poké Balls ×5", "Ajoutées au Sac")
	await _frames(int(ceil(_tokens.TOAST_FADE_IN * 30.0)) + 6)
	await _shot("toast")


## Voile du combat, et sprites provisoires de T6 aux ancres prévues s'ils existent.
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
	_add_battler("squirtle_front.png", Vector2(0.66, 0.52) * view, 3)


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


## Capacités de Salamèche au niveau 5 (valeurs de data/pokemon/moves, recopiées pour l'image).
func _moves() -> Array:
	var views: Array = [
		_move_view.new("Griffe", &"normal", "Normal", 0, 35, 35, 40, 100,
			"Lacère la cible avec des griffes acérées."),
		_move_view.new("Rugissement", &"normal", "Normal", 2, 40, 40, 0, 100,
			"Baisse l'Attaque de la cible."),
	]
	var typed := Array([], TYPE_OBJECT, &"RefCounted", _move_view)
	typed.assign(views)
	return typed


## Toucher comme sur le téléphone (la souris émulée depuis le toucher suit).
func _touch(position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = position
	event.pressed = pressed
	Input.parse_input_event(event)


## Enregistre l'image affichée à l'image suivante (celle qui contient l'état courant).
func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join(PREFIX + name + ".png")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
