extends SceneTree
## Vérification visuelle du Sac de combat et de la carte de capture (jalon 5D, T14) : les vrais
## composants (BattleBagPanel, CaptureCard) sur la Route 1, sous le voile du combat (FADE_COLOR à
## BATTLE_DIM), avec la vraie BattleHud (cartes) et les sprites provisoires aux ancres du
## combat sauvage. Sans directeur (T15) : l'outil pilote les composants à la main. Les textes de
## la carte viennent de data/battle/messages.json.
##
## Sur le Mac (la résolution fixe la taille du viewport) :
##   godot --path . --resolution 2340x1080 --always-on-top --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_capture_ui.gd -- --out=build/captures/jalon05d_t14 [--suffix=_1920]
## Images (préfixe jalon05d_t14_) :
##   bag            Sac réel du jalon 5 : Poké Ball ×5 seule, aperçue d'emblée
##   bag_three      trois Balls (démo : les deux dernières n'existent pas encore en données),
##                  la deuxième aperçue après un toucher
##   bag_tabs       deux catégories (démo : CAPTURE et SOINS), onglet SOINS ouvert
##   bag_empty      aucun objet utilisable : une phrase et « ‹ »
##   capture_new    carte de capture avec « Nouvelle entrée Pokédex »
##   capture_known  carte de capture sans cette ligne
##   capture_storage  carte de capture, ligne « confié au système de recherche de Chen »

const BOOT_SCENE: String = "res://game/boot.tscn"
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const HUD_SCENE: String = "res://game/ui/battle/battle_hud.tscn"
const BAG_SCENE: String = "res://game/ui/battle/battle_bag_panel.tscn"
const CARD_SCENE: String = "res://game/ui/battle/capture_card.tscn"
const UI_DIR: String = "res://game/ui/battle/"
const SPRITES_DIR: String = "res://assets/sprites/pokemon/placeholder/"
const MESSAGES_PATH: String = "res://data/battle/messages.json"
const ITEMS_PATH: String = "res://data/items/items.json"
const PREFIX: String = "jalon05d_t14_"
const PLAYER := 0
const FOE := 1
const WILD_ACTIONS: Dictionary[StringName, bool] = {&"attack": true, &"run": true}

var _boot: Node
var _tokens: GDScript
var _out_dir: String = "build/captures/jalon05d_t14"
var _suffix: String = ""
var _card_view: GDScript
var _entry_view: GDScript
var _capture_view: GDScript
var _layout: GDScript
var _hud: CanvasLayer
var _bag: Control
var _card: Control
var _stage: CanvasLayer
var _messages: Dictionary = {}
var _items: Dictionary = {}


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
	_entry_view = load(UI_DIR + "bag_entry_view.gd") as GDScript
	_capture_view = load(UI_DIR + "capture_card_view.gd") as GDScript
	_layout = load(UI_DIR + "battle_hud_layout.gd") as GDScript
	_messages = JSON.parse_string(FileAccess.get_file_as_string(MESSAGES_PATH))["templates"]
	_items = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
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
	await _bag_shots()
	await _capture_shots()
	print("CAPTURE_CAPTURE_UI terminé")
	quit()


func _bag_shots() -> void:
	_bag = (load(BAG_SCENE) as PackedScene).instantiate() as Control
	_hud.call(&"get_screen").add_child(_bag)
	_layout.call(&"place", _bag, _layout.get(&"Slot")["BAG"])
	_bag.set(&"haptics_enabled", false)
	# Comme en jeu : la carte adverse reste, la carte du joueur laisse la place au Sac.
	_hud.call(&"set_card", FOE, _card_view.new("Roucool", 1, 3, 12, 12, false))
	await _frames(20)
	_bag.call(&"show_bag", _typed([_entry(&"poke_ball", 5)]), &"ball")
	await _frames(14)
	await _shot("bag")
	await _bag.call(&"slide_out")
	_bag.call(&"show_bag", _typed([
		_entry(&"poke_ball", 12),
		_entry_demo(&"super_ball", "Super Ball", 3, "ball",
			"Une Ball plus efficace que la Poké Ball."),
		_entry_demo(&"hyper_ball", "Hyper Ball", 1, "ball",
			"Une Ball très efficace."),
	]), &"ball")
	await _frames(14)
	_bag.call(&"select_item", &"super_ball")
	await _frames(8)
	await _shot("bag_three")
	_bag.call(&"show_bag", _typed([
		_entry(&"poke_ball", 5),
		_entry_demo(&"potion", "Potion", 2, "heal", "Restaure les PV d'un Pokémon."),
	]), &"ball")
	await _frames(6)
	_bag.call(&"open_category", &"heal")
	await _frames(8)
	await _shot("bag_tabs")
	_bag.call(&"show_bag", _typed([]), &"ball")
	await _frames(8)
	await _shot("bag_empty")
	await _bag.call(&"slide_out")
	_hud.call(&"hide_all")
	await _frames(12)


func _capture_shots() -> void:
	_card = (load(CARD_SCENE) as PackedScene).instantiate() as Control
	_hud.call(&"get_screen").add_child(_card)
	_layout.call(&"place", _card, _layout.get(&"Slot")["CAPTURE"])
	_card.set(&"haptics_enabled", false)
	var portrait := load(SPRITES_DIR + "pidgey_front.png") as Texture2D
	var title := String(_messages["caught_title"]["text"]).format({"pokemon": "Roucool"})
	var pokedex := String(_messages["pokedex_new"]["text"])
	var joined := String(_messages["joined_party"]["text"]).format({"pokemon": "Roucool"})
	var stored := String(_messages["sent_to_storage"]["text"]).format({"pokemon": "Roucool"})
	_card.call(&"show_capture", _capture_view.new(title, portrait, true, pokedex, joined))
	await _frames(36)
	await _shot("capture_new")
	_card.call(&"skip")
	await _frames(12)
	_card.call(&"show_capture", _capture_view.new(title, portrait, false, "", joined))
	await _frames(36)
	await _shot("capture_known")
	_card.call(&"skip")
	await _frames(12)
	_card.call(&"show_capture", _capture_view.new(title, portrait, true, pokedex, stored))
	await _frames(36)
	await _shot("capture_storage")
	_card.call(&"skip")
	await _frames(12)


## Objet des vraies données (nom accordé, description).
func _entry(id: StringName, count: int) -> RefCounted:
	var item: Dictionary = _items[String(id)]
	var name: String = item["name"]
	return _entry_view.new(id, name, count, item["description"], StringName(item["category"]))


## Objet de démonstration (absent des données du jalon 5).
func _entry_demo(id: StringName, name: String, count: int, category: String,
		text: String) -> RefCounted:
	return _entry_view.new(id, name, count, text, StringName(category))


## Array[BagEntryView] attendu par show_bag (la classe n'est pas connue de l'outil).
func _typed(views: Array) -> Array:
	var typed := Array([], TYPE_OBJECT, &"RefCounted", _entry_view)
	typed.assign(views)
	return typed


## Voile du combat, et sprites provisoires aux ancres du combat sauvage.
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
	_add_battler("charmander_back.png", Vector2(0.5 * view.x - 0.30 * 1080.0, 0.63 * 1080.0), 4)
	_add_battler("pidgey_front.png", Vector2(0.5 * view.x + 0.24 * 1080.0, 0.47 * 1080.0), 3)


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
