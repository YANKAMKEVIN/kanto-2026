extends SceneTree
## Vérification visuelle de la BattleHud en combat SAUVAGE (jalon 5B, T6), sur la Route 1 :
## carte adverse sans pastilles d'équipe, grille d'actions avec FUITE active (ATTAQUER mis en
## avant, SAC et ÉQUIPE atténués), message « Un Rattata sauvage apparaît ! ».
## Sans directeur ni vraie transition (T5/T7) : un voile FADE_COLOR à BATTLE_DIM imite le
## combat et les sprites provisoires (Rattata de face, Salamèche de dos) sont posés aux ancres
## du §14.4, à titre indicatif.
##
## Sur le Mac (2340×1080 via override.cfg temporaire) :
##   godot --path . --always-on-top --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_wild_battle_hud.gd -- --out=build/captures/jalon05b_t6
## Images (préfixe jalon05b_t6_) :
##   appeared  « Un Rattata sauvage apparaît ! », carte adverse sans pastilles, 6 du joueur
##   actions   grille sauvage : ATTAQUER mis en avant, FUITE active, SAC/ÉQUIPE atténués

const BOOT_SCENE: String = "res://game/boot.tscn"
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const HUD_SCENE: String = "res://game/ui/battle/battle_hud.tscn"
const UI_DIR: String = "res://game/ui/battle/"
const SPRITES_DIR: String = "res://assets/sprites/pokemon/placeholder/"
const PREFIX: String = "jalon05b_t6_"
const PLAYER := 0
const FOE := 1
## Actions d'un combat sauvage (miroir de BattleViews.WILD_BATTLE_ACTIONS).
const WILD_ACTIONS: Dictionary[StringName, bool] = {&"attack": true, &"bag": true, &"run": true}

var _boot: Node
var _tokens: GDScript
var _out_dir: String = "build/captures/jalon05b_t6"
var _card_view: GDScript
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
	await _battle()
	print("CAPTURE_WILD_BATTLE_HUD terminé")
	quit()


func _battle() -> void:
	_build_stage()
	_hud = (load(HUD_SCENE) as PackedScene).instantiate() as CanvasLayer
	root.add_child(_hud)
	_hud.set(&"haptics_enabled", false)
	await _frames(2)
	# Équipe pleine (6) pour le joueur ; l'adversaire sauvage n'a aucune pastille.
	_hud.call(&"set_party", 6)
	_hud.call(&"set_card", FOE, _card_view.new("Rattata", 1, 3, 14, 14, false))
	_hud.call(&"set_card", PLAYER, _card_view.new("Salamèche", 1, 5, 19, 19, true))
	_hud.call(&"show_message", "Un Rattata sauvage apparaît !")
	await _frames(25)
	await _shot("appeared")
	_hud.call(&"show_actions", WILD_ACTIONS)
	await _frames(30)
	await _shot("actions")
	await _hud.call(&"hide_all")
	await _frames(6)


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
	var path := _out_dir.path_join(PREFIX + name + ".png")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
