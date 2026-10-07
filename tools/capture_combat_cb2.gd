extends SceneTree
## Captures du CB.2 (interface de combat rapprochée des maquettes) : la vraie BattleHud, le vrai
## Sac, la vraie ÉQUIPE et la vraie carte de capture sur la Route 1, sous le voile du combat,
## avec deux silhouettes provisoires aux places du cadrage (adversaire en haut à droite,
## Pokémon du joueur en bas à gauche) pour juger la diagonale. Artworks officiels (PokedexArt).
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 3000 \
##     -s res://tools/capture_combat_cb2.gd -- --out=build/captures/combat_cb2 [--suffix=_1920]
## Lancer les deux passes avec tools/capture_combat_cb2.sh.
## Images (préfixe cb2_) : actions, moves, moves_pp0, message, bag, bag_heal, party, capture_new,
## capture_known, cards_low (PV rouges).

const BOOT_SCENE: String = "res://game/boot.tscn"
const TOKENS_PATH: String = "res://game/ui/theme/ui_tokens.gd"
const HUD_SCENE: String = "res://game/ui/battle/battle_hud.tscn"
const BAG_SCENE: String = "res://game/ui/battle/battle_bag_panel.tscn"
const PARTY_SCENE: String = "res://game/ui/battle/battle_party_panel.tscn"
const CARD_SCENE: String = "res://game/ui/battle/capture_card.tscn"
const UI_DIR: String = "res://game/ui/battle/"
const MESSAGES_PATH: String = "res://data/battle/messages.json"
const ITEMS_PATH: String = "res://data/items/items.json"
const MOVES_PATH: String = "res://data/pokemon/moves/moves.json"
const TYPES_PATH: String = "res://data/pokemon/types.json"
const PREFIX: String = "cb2_"
const PLAYER := 0
const FOE := 1

var _boot: Node
var _tokens: GDScript
var _out_dir: String = "build/captures/combat_cb2"
var _suffix: String = ""
var _card_view: GDScript
var _move_view: GDScript
var _party_view: GDScript
var _entry_view: GDScript
var _capture_view: GDScript
var _layout: GDScript
var _hud: CanvasLayer
var _bag: Control
var _party: Control
var _card: Control
var _stage: CanvasLayer
var _messages: Dictionary = {}
var _items: Dictionary = {}
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
	_party_view = load(UI_DIR + "battle_party_view.gd") as GDScript
	_entry_view = load("res://game/ui/bag/bag_entry_view.gd") as GDScript
	_capture_view = load(UI_DIR + "capture_card_view.gd") as GDScript
	_layout = load(UI_DIR + "battle_hud_layout.gd") as GDScript
	_messages = JSON.parse_string(FileAccess.get_file_as_string(MESSAGES_PATH))["templates"]
	_items = JSON.parse_string(FileAccess.get_file_as_string(ITEMS_PATH))
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
	_hud.set(&"speed_scale", 0.0)
	await _frames(2)
	# Deux passes (tools/capture_combat_cb2.sh) : la carte de capture, montrée après les autres
	# panneaux dans la même session, reste figée à moitié ouverte (artefact d'outil, cause non
	# élucidée ; seule, elle s'affiche correctement).
	if OS.get_cmdline_user_args().has("--only-capture"):
		await _capture_shots()
	else:
		await _hud_shots()
		await _bag_shots()
		await _party_shots()
	print("CAPTURE_COMBAT_CB2 terminé")
	quit()


func _hud_shots() -> void:
	_hud.call(&"set_card", FOE, _card_view.new("Roucool", 1, 4, 12, 12, false))
	_hud.call(&"set_card", PLAYER, _card_view.new("Pikachu", 1, 7, 24, 24, true))
	_hud.call(&"set_party", 1)
	_hud.call(&"show_actions", _all())
	await _frames(10)
	await _shot("actions")
	_hud.call(&"show_moves", _typed_moves([
		_demo_move("Éclair", &"electric", "Électrik", 15, 15, 40, 0),
		_move(&"quick_attack", 30), _demo_move("Cage-Éclair", &"electric", "Électrik", 20, 20, 0, 2),
		_move(&"growl", 40)]))
	await _frames(14)
	_hud.call(&"get_move_grid").call(&"select", 0)
	await _frames(8)
	await _shot("moves")
	_hud.call(&"show_moves", _typed_moves([_move(&"water_gun", 0), _move(&"gust", 20),
		_move(&"karate_chop", 10), _move(&"agility", 30)]))
	await _frames(14)
	await _shot("moves_pp0")
	_hud.call(&"show_message", "Roucool utilise Tornade !")
	await _frames(14)
	await _shot("message")
	_hud.call(&"hide_zone")
	await _frames(10)
	_hud.call(&"set_card", PLAYER, _card_view.new("Pikachu", 1, 7, 4, 24, true))
	_hud.call(&"set_card", FOE, _card_view.new("Roucool", 1, 4, 2, 12, false))
	_hud.call(&"show_actions", _all())
	await _frames(14)
	await _shot("cards_low")
	_hud.call(&"hide_all")
	await _frames(12)


func _bag_shots() -> void:
	_bag = (load(BAG_SCENE) as PackedScene).instantiate() as Control
	_hud.call(&"get_screen").add_child(_bag)
	_layout.call(&"place", _bag, _layout.get(&"Slot")["BAG"])
	_bag.set(&"haptics_enabled", false)
	_bag.set(&"speed_scale", 0.0)
	_hud.call(&"set_card", FOE, _card_view.new("Roucool", 1, 4, 3, 12, false))
	await _frames(10)
	_bag.call(&"show_bag", _typed([_entry(&"poke_ball", 12), _entry(&"potion", 5)]), &"ball")
	await _frames(14)
	await _shot("bag")
	_bag.call(&"open_category", &"heal")
	await _frames(8)
	await _shot("bag_heal")
	await _bag.call(&"slide_out")
	_hud.call(&"hide_all")
	await _frames(12)


func _party_shots() -> void:
	_party = (load(PARTY_SCENE) as PackedScene).instantiate() as Control
	_hud.call(&"get_screen").add_child(_party)
	_layout.call(&"place", _party, _layout.get(&"Slot")["PARTY"])
	_party.set(&"haptics_enabled", false)
	_party.set(&"speed_scale", 0.0)
	_hud.call(&"set_card", FOE, _card_view.new("Roucool", 1, 4, 12, 12, false))
	var views: Array = [
		_pview(0, &"pikachu", "Pikachu", 7, 24, 24, [&"electric"], ["Électrik"], true, false, "Déjà au combat"),
		_pview(1, &"charmander", "Salamèche", 5, 19, 19, [&"fire"], ["Feu"], false, true, ""),
		_pview(2, &"pidgey", "Roucool", 3, 0, 12, [&"normal", &"flying"], ["Normal", "Vol"], false, false, "Ne peut plus combattre"),
	]
	var typed := Array([], TYPE_OBJECT, &"RefCounted", _party_view)
	typed.assign(views)
	_party.call(&"show_party", typed)
	await _frames(14)
	await _shot("party")
	await _party.call(&"slide_out")
	_hud.call(&"hide_all")
	await _frames(12)


func _pview(index: int, species: StringName, pname: String, level: int, hp: int, max_hp: int,
		type_ids: Array, type_names: Array, active: bool, can_send: bool, reason: String) -> RefCounted:
	var v: RefCounted = _party_view.new()
	v.set(&"party_index", index)
	v.set(&"species_id", species)
	v.set(&"display_name", pname)
	v.set(&"level", level)
	v.set(&"hp", hp)
	v.set(&"max_hp", max_hp)
	var ids: Array[StringName] = []
	ids.assign(type_ids)
	v.set(&"type_ids", ids)
	v.set(&"type_names", PackedStringArray(type_names))
	v.set(&"active", active)
	v.set(&"can_send", can_send)
	v.set(&"reason", reason)
	return v


func _capture_shots() -> void:
	_card = (load(CARD_SCENE) as PackedScene).instantiate() as Control
	_hud.call(&"get_screen").add_child(_card)
	_layout.call(&"place", _card, _layout.get(&"Slot")["CAPTURE"])
	_card.set(&"haptics_enabled", false)
	var portrait: Texture2D = _art(16, true)
	var title := String(_messages["caught_title"]["text"]).format({"pokemon": "Roucool"})
	var pokedex := String(_messages["pokedex_new"]["text"])
	var joined := String(_messages["joined_party"]["text"]).format({"pokemon": "Roucool"})
	_card.call(&"show_capture", _capture_view.new(title, portrait, true, pokedex, joined))
	await _wait_revealed()
	await _frames(30)
	await _shot("capture_new")
	await _dismiss()
	_card.call(&"show_capture", _capture_view.new(title, portrait, false, "", joined))
	await _wait_revealed()
	await _shot("capture_known")
	await _dismiss()


## Attend la fin de la révélation : carte pleinement opaque, toutes les lignes et le ▼ visibles
## (et non un nombre d'images fixe) ; échoue bruyamment si cela n'arrive pas.
func _wait_revealed() -> void:
	var continue_arrow: Control = _card.call(&"get_continue")
	var result: Control = _card.call(&"get_result_label")
	for i: int in 300:
		await process_frame
		if _card.modulate.a >= 0.999 and result.modulate.a >= 0.999 \
				and continue_arrow.modulate.a >= 0.999 and _card.call(&"is_waiting"):
			print("révélée après %d images" % (i + 1))
			await _frames(3)
			return
	push_error("la carte de capture n'est jamais entièrement révélée")


## Termine la carte et attend sa sortie complète.
func _dismiss() -> void:
	_card.call(&"skip")
	for i: int in 120:
		await process_frame
		if not _card.visible:
			return


## Objet des vraies données (nom accordé, description).
func _entry(id: StringName, count: int) -> RefCounted:
	var item: Dictionary = _items[String(id)]
	var name: String = item["name"]
	return _entry_view.new(id, name, count, item["description"], StringName(item["category"]))


## Array[BagEntryView] attendu par show_bag (la classe n'est pas connue de l'outil).
func _typed(views: Array) -> Array:
	var typed := Array([], TYPE_OBJECT, &"RefCounted", _entry_view)
	typed.assign(views)
	return typed


func _typed_moves(views: Array) -> Array:
	var typed := Array([], TYPE_OBJECT, &"RefCounted", _move_view)
	typed.assign(views)
	return typed


func _move(id: StringName, pp: int) -> RefCounted:
	var move: Dictionary = _moves[String(id)]
	var categories: Dictionary = {"physical": 0, "special": 1, "status": 2}
	return _move_view.new(move["name"], StringName(move["type"]), _types[move["type"]]["name"],
		categories[move["category"]], pp, int(move["pp"]), int(move.get("power", 0)),
		int(move.get("accuracy", 0)), move.get("description", ""))


## Capacité de démonstration (absente des données : l'Électrik n'a pas encore de capacité).
func _demo_move(name: String, type: StringName, type_name: String, pp: int, max_pp: int,
		power: int, category: int) -> RefCounted:
	return _move_view.new(name, type, type_name, category, pp, max_pp, power, 100, "")


func _art(number: int, portrait: bool) -> Texture2D:
	var art: GDScript = load("res://game/ui/menu/pokedex/pokedex_art.gd") as GDScript
	return art.call(&"portrait" if portrait else &"portrait", number) as Texture2D


## Voile du combat, et deux artworks provisoires aux places du cadrage (CB.1) : adversaire en
## haut à droite, Pokémon du joueur (Pikachu, vu de face faute de dos) en bas à gauche.
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
	_add_art(16, Vector2(view.x * 0.70, 440.0), 230.0)
	_add_art(25, Vector2(view.x * 0.24, 900.0), 380.0)


func _add_art(number: int, feet: Vector2, height: float) -> void:
	var texture := _art(number, true)
	if texture == null:
		return
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	var k := height / texture.get_size().y
	sprite.scale = Vector2.ONE * k
	var size := texture.get_size() * k
	sprite.position = feet - Vector2(size.x * 0.5, size.y)
	_stage.add_child(sprite)


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join(PREFIX + name + _suffix + ".png")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s PERF appels=%d texmem=%.1f Mo" % [path,
		root.get_visible_rect().size,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _all() -> Dictionary[StringName, bool]:
	return {&"attack": true, &"bag": true, &"team": true, &"run": true}

