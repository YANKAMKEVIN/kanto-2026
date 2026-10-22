extends SceneTree
## Captures du jalon 21 (T11, T12, T20) sur le VRAI Boot (scènes, BattleDirector, BattleStage,
## BattleHud) : la révélation d'Ossatueur au 6F (silhouette + « Le Scope Sylphe révèle… », puis
## Ossatueur + « C'est un Ossatueur ! », refus de la Ball) et le réveil du Ronflex de la Route 12
## (notes de la Flûte, saut et « ! », « Ronflex se réveille ! », entrée en combat). Fenêtre (Mac,
## pas en headless : le rendu factice ne dessine rien) :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 --quit-after 9000 \
##     -s res://tools/capture_j21_reveal.gd -- --out=build/captures/jalon21

const BOOT_SCENE: String = "res://game/boot.tscn"
const START_6F: String = "res://tools/debug_start/tower_marowak_qa.json"
const START_12: String = "res://tools/debug_start/route_12_qa.json"

var _boot: Node
var _out_dir: String = "build/captures/jalon21"
var _hud: CanvasLayer
var _director: Node
var _banner: Node
var _box: CanvasLayer
var _cutscenes: Node


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"pokemon_tower_6f")
	_boot.set(&"start_spawn", &"devant_spectre")
	_boot.set(&"start_facing", Vector2i.DOWN)
	root.add_child(_boot)
	await _frames(20)
	_apply(START_6F)
	_hud = _boot.call(&"get_battle_hud")
	_hud.set(&"haptics_enabled", false)
	_director = _boot.call(&"get_battle_director")
	_banner = _hud.call(&"get_message_banner")
	_box = _boot.call(&"get_dialogue_box")
	_cutscenes = _boot.call(&"get_cutscene_director")
	(_boot.call(&"get_dialogue_runner") as Node).set(&"chars_per_second", 0.0)
	(_boot.call(&"get_encounter_director") as Node).set(&"enabled", false)
	(_boot.call(&"get_hud") as CanvasLayer).call(&"hide_interact")
	_boot.call(&"get_map").call(&"apply_flag_gates", root.get_node(^"GameState").get(&"flags"))
	await _frames(30)
	await _reveal()
	await _snorlax()
	print("CAPTURE_J21_REVEAL terminé")
	quit()


func _apply(path: String) -> void:
	var start := DebugStart.new()
	start.call(&"load_file", path, _boot.call(&"get_pokemon_data"),
		_boot.call(&"get_item_library"))
	start.call(&"apply", root.get_node(^"GameState"), _boot.call(&"get_pokemon_data"))


## 6F : la scène réelle `tower_6f_ghost` (variante A, Scope au Sac).
func _reveal() -> void:
	if not _cutscenes.call(&"play", &"tower_6f_ghost"):
		push_error("scène du 6F refusée")
		return
	await _dialogue_shown("Va-t'en")
	await _shot("6f_avertissement")
	_box.emit_signal(&"advance_requested")
	await _text_shown("révèle")
	await _shot("6f_revelation_silhouette")
	await _text_shown("C'est un")
	await _shot("6f_revelation_ossatueur")
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 900)
	await _frames(15)
	await _shot("6f_carte_ossatueur")
	_hud.emit_signal(&"action_selected", &"bag")
	var got: Array = [null]
	await _until(func() -> bool:
		got[0] = _director.call(&"get_bag_panel")
		return got[0] != null and got[0].visible and not got[0].call(&"is_sliding"), 300)
	await _frames(10)
	got[0].call(&"select_item", &"poke_ball")
	await _frames(6)
	(got[0].call(&"get_action_button") as Button).emit_signal(&"pressed")
	await _text_shown("ne peut pas")
	await _shot("6f_ball_refusee")
	await _finish_scene()


## Route 12 : la Flûte depuis la case `face_ronflex` nord (25, 92).
func _snorlax() -> void:
	_apply(START_12)
	var router: Node = root.get_node(^"SceneRouter")
	router.call(&"change_map", &"route_12", &"from_lavender", Vector2i.DOWN)
	await _until(func() -> bool:
		return _boot.call(&"get_map").get(&"map_id") == &"route_12" \
			and not bool(router.call(&"is_transitioning")), 600)
	await _frames(20)
	var map: Node = _boot.call(&"get_map")
	map.call(&"spawn_player_at", _boot.call(&"get_player"), Vector2i(25, 92), Vector2i.DOWN)
	await _frames(40)
	await _shot("r12_ronflex_endormi")
	(_boot.call(&"get_menu_director") as Node).emit_signal(&"key_item_requested", &"poke_flute")
	await _frames(18)
	await _shot("r12_flute_notes")
	await _dialogue_shown("joue de la Poké Flûte")
	_box.emit_signal(&"advance_requested")
	await _frames(12)
	await _shot("r12_ronflex_saut")
	await _dialogue_shown("se réveille")
	await _shot("r12_ronflex_reveil")
	_box.emit_signal(&"advance_requested")
	await _dialogue_shown("mauvaise humeur")
	_box.emit_signal(&"advance_requested")
	await _until(func() -> bool: return int(_hud.call(&"get_zone")) == 1, 900)
	await _frames(15)
	await _shot("r12_ronflex_combat")
	await _finish_scene()


## Fuit et fait défiler les textes jusqu'à la fin de la scène.
func _finish_scene() -> void:
	var guard := 0
	while (bool(_cutscenes.call(&"is_running")) or bool(_director.call(&"is_running"))) \
			and guard < 3000:
		guard += 1
		if bool(_director.call(&"is_running")) and int(_hud.call(&"get_zone")) == 1:
			_hud.emit_signal(&"action_selected", &"run")
		if bool(_box.call(&"is_open")) and guard % 10 == 0:
			_box.emit_signal(&"advance_requested")
		await _frames(2)
	await _frames(40)


func _text_shown(part: String) -> void:
	await _until(func() -> bool: return String(_banner.call(&"get_text")).contains(part), 900)
	await _frames(14)


func _dialogue_shown(part: String) -> void:
	await _until(func() -> bool:
		return bool(_box.call(&"is_open")) and String(_box.call(&"get_text")).contains(part), 900)
	await _frames(20)


func _until(done: Callable, frames: int) -> bool:
	for i: int in frames:
		if done.call():
			return true
		await process_frame
	push_warning("attente dépassée")
	return false


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _shot(name: String) -> void:
	paused = true
	for i: int in 6:
		await process_frame
	var path := _out_dir.path_join("j21_%s.png" % name)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(path)
	paused = false
	print("[shot] ", path)
