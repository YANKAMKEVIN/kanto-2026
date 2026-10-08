extends SceneTree
## Vérification visuelle du cadrage du combat (CB.1, docs/tech/combat-maquettes.md) : le vrai
## Boot, la vraie carte (lumière du lieu comprise) et le vrai BattleStage, piloté directement
## (sans directeur ni interface : CB.2 fait l'interface). Adversaire en artwork officiel, ton
## Pokémon de dos (sprite provisoire), entrée sauvage, lancer de Ball, capture, entrée de
## dresseur ; `_zones` : mêmes images avec les zones réservées à l'interface en rouge.
##
## 2340 × 1080 sur le Mac : `override.cfg` temporaire à la racine ([display]
## window/size/window_width_override=2340, window_height_override=1080), à retirer après :
##   godot --path . --fixed-fps 30 --quit-after 9000 -s res://tools/capture_battle_stage_cb1.gd \
##     -- --out=build/captures/combat_cb1 --place=route_1
##   (… --place=oak_lab : combat de dresseur au labo ; --place=route_22 : rival n° 2)
## `--perf=<images>` : après les images, mesure sans synchronisation verticale (fps moyen,
## appels de dessin, mémoire des textures) sur la vue de combat posée.
## Images (préfixe cb1_<lieu>_) :
##   route_1  sauvage_rattata (petit), sauvage_rattata_zones, sauvage_roucool,
##            sauvage_florizarre (grand), sauvage_dracaufeu, entree (mi-apparition),
##            partenaire (mi-course), coup (mi-coup sur l'adversaire), lancer (Ball en vol),
##            absorption, ball_au_sol, secousse, capture (éclat doré), libere, ko
##   oak_lab / route_22  dresseur, dresseur_zones, transition (mi-entrée), coup_critique

const BOOT_SCENE: String = "res://game/boot.tscn"
const PLAYER := 0
const FOE := 1
const SPAWNS: Dictionary = {&"route_1": &"from_pallet_w", &"oak_lab": &"entrance",
	&"route_22": &"from_viridian"}

var _boot: Node
var _stage: CanvasLayer
var _camera: Camera2D
var _out_dir: String = "build/captures/combat_cb1"
var _place: StringName = &"route_1"
var _perf_frames: int = 0
var _zones: CanvasLayer


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--place="):
			_place = StringName(arg.trim_prefix("--place="))
		elif arg.begins_with("--perf="):
			_perf_frames = arg.trim_prefix("--perf=").to_int()
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", _place)
	_boot.set(&"start_spawn", SPAWNS.get(_place, &"start"))
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.call(&"hide_interact")
	explo.call(&"set_controls_visible", false)
	explo.visible = false
	_stage = _boot.call(&"get_battle_stage")
	_camera = (_boot.call(&"get_player") as Node).call(&"get_camera")
	_build_zones()
	await _frames(10)
	if _place == &"route_1":
		await _wild_shots()
	else:
		await _trainer_shots()
	print("CAPTURE_BATTLE_STAGE_CB1 terminé")
	quit()


# --- Sauvage (Route 1) -------------------------------------------------------------------

func _wild_shots() -> void:
	await _wild(&"rattata", &"charmander")
	await _shot("sauvage_rattata")
	_zones.visible = true
	await _shot("sauvage_rattata_zones")
	_zones.visible = false
	await _perf("sauvage")
	# Coup sur l'adversaire, à mi-course.
	_stage.call(&"play_hit", FOE, false)
	await _frames(3)
	await _shot("coup")
	await _frames(30)
	# Lancer, absorption, Ball au sol, secousse, capture.
	_stage.call(&"play_throw")
	await _frames(14)
	await _shot("lancer")
	await _frames(8)
	await _shot("absorption")
	await _frames(40)
	await _shot("ball_au_sol")
	_stage.call(&"play_ball_shake")
	await _frames(5)
	await _shot("secousse")
	await _frames(20)
	_stage.call(&"play_break_free")
	await _frames(6)
	await _shot("libere")
	await _frames(20)
	_stage.call(&"play_throw")
	await _frames(60)
	_stage.call(&"play_catch_burst")
	await _frames(5)
	await _shot("capture")
	await _frames(20)
	await _exit()
	await _wild(&"pidgey", &"charmander")
	await _shot("sauvage_roucool")
	_stage.call(&"play_faint", FOE)
	await _frames(6)
	await _shot("ko")
	await _exit()
	await _wild(&"venusaur", &"squirtle")
	await _shot("sauvage_florizarre")
	_zones.visible = true
	await _shot("sauvage_florizarre_zones")
	_zones.visible = false
	await _exit()
	await _wild(&"charizard", &"bulbasaur")
	await _shot("sauvage_dracaufeu")
	await _exit()
	# Entrée réelle : le sauvage à mi-apparition, puis le partenaire à mi-course.
	var origin := _origin()
	_stage.call(&"play_wild_intro", _camera, &"rattata", origin)
	await _frames(14)
	await _shot("entree")
	await _frames(10)
	_stage.call(&"play_partner_enter", &"charmander")
	await _frames(4)
	await _shot("partenaire")
	await _frames(20)
	await _exit()


## Rencontre posée (intro sauvage puis partenaire), attendue jusqu'au bout.
func _wild(foe: StringName, mine: StringName) -> void:
	var map: Node = _boot.call(&"get_map")
	_stage.call(&"set_frame", map.call(&"get_battle_arena_rect"),
		Rect2(map.call(&"get_pixel_rect")))
	await _stage.call(&"play_wild_intro", _camera, foe, _origin())
	await _stage.call(&"play_partner_enter", mine)
	await _frames(6)


## Herbe qui bouge : deux cases devant le joueur.
func _origin() -> Vector2:
	var player: Node2D = _boot.call(&"get_player")
	return player.global_position + Vector2(96.0, -192.0)


# --- Dresseur (labo, Route 22) -----------------------------------------------------------

func _trainer_shots() -> void:
	var map: Node = _boot.call(&"get_map")
	_stage.call(&"set_frame", map.call(&"get_battle_arena_rect"),
		Rect2(map.call(&"get_pixel_rect")))
	var cells: Array[Vector2i] = []
	var player: Node = _boot.call(&"get_player")
	cells.append((player.call(&"get_cell") as Vector2i) + Vector2i(-2, -1))
	_stage.call(&"enter", _camera, null, null, &"charmander", &"squirtle", cells)
	await _frames(14)
	await _shot("transition")
	await _frames(40)
	await _shot("dresseur")
	_zones.visible = true
	await _shot("dresseur_zones")
	_zones.visible = false
	await _perf("dresseur")
	_stage.call(&"play_move", PLAYER, 0)
	await _frames(4)
	_stage.call(&"play_hit", FOE, true)
	await _frames(2)
	await _shot("coup_critique")
	await _frames(30)
	await _exit()


# --- Outils --------------------------------------------------------------------------------

func _exit() -> void:
	await _stage.call(&"exit")
	await _frames(4)


## Zones réservées à l'interface (contrat CB.1 / CB.2), en rouge translucide.
func _build_zones() -> void:
	_zones = CanvasLayer.new()
	_zones.layer = 50
	_zones.visible = false
	root.add_child(_zones)
	var layout := load("res://game/battle/battle_layout.gd") as Script
	for zone: Rect2 in layout.call(&"hud_zones", root.get_visible_rect().size):
		var rect := ColorRect.new()
		rect.position = zone.position
		rect.size = zone.size
		rect.color = Color(1.0, 0.1, 0.1, 0.18)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_zones.add_child(rect)


func _perf(label: String) -> void:
	if _perf_frames <= 0:
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var start := Time.get_ticks_usec()
	var draws := 0
	for i: int in _perf_frames:
		await process_frame
		draws = maxi(draws, int(Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	var seconds := float(Time.get_ticks_usec() - start) / 1000000.0
	print("[perf] %s %s fps=%.1f draw_max=%d tex=%.1f Mo vue=%s" % [_place, label,
		_perf_frames / seconds, draws,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		root.get_visible_rect().size])


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join("cb1_%s_%s.png" % [_place, name])
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
