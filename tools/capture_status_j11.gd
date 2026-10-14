extends SceneTree
## Captures des effets de statut en combat (jalon 11, T7) : vrai Boot sur la Route 1, vrai
## BattleStage piloté directement (comme `capture_battle_stage_cb1.gd`). Adversaire de face
## (artwork officiel étalonné), ton Pokémon de dos (sprite provisoire) ; le même statut sur les
## deux à chaque image :
##
##   godot --path . --resolution 2340x1080 -s res://tools/capture_status_j11.gd \
##     -- --out=build/captures/jalon11_t7
##
## Images (préfixe j11_status_) : paralysis, burn, sleep, freeze, poison (rien de permanent),
## confusion (étoiles à mi-course), burn_veil (voile orangé de fin de tour, au pic),
## freeze_reduced (« Réduire les animations » : teinte seule).

const BOOT_SCENE: String = "res://game/boot.tscn"
const PLAYER := BattleEvent.SideId.PLAYER
const FOE := BattleEvent.SideId.FOE
## Instant figé de chaque effet (s depuis la pose du statut) : décharges visibles, braises et
## « z » en route.
const MOMENT: float = 0.1

var _boot: Node
var _stage: BattleStage
var _out_dir: String = "build/captures/jalon11_t7"


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.call(&"hide_interact")
	explo.call(&"set_controls_visible", false)
	explo.visible = false
	_stage = _boot.call(&"get_battle_stage")
	var camera: Camera2D = (_boot.call(&"get_player") as Node).call(&"get_camera")
	var map: Node = _boot.call(&"get_map")
	_stage.set_frame(map.call(&"get_battle_arena_rect"), Rect2(map.call(&"get_pixel_rect")))
	var player: Node2D = _boot.call(&"get_player")
	await _stage.play_wild_intro(camera, &"pikachu", player.global_position + Vector2(96, -192))
	await _stage.play_partner_enter(&"charmander")
	await _frames(6)
	# Effets figés à l'instant choisi (sous xvfb, une image peut durer une demi-seconde).
	_stage.get_status_aura(PLAYER).speed_scale = 0.0
	_stage.get_status_aura(FOE).speed_scale = 0.0
	for status: StringName in StatusRules.KNOWN:
		_stage.set_status(PLAYER, status)
		_stage.set_status(FOE, status)
		_stage.get_status_aura(PLAYER).speed_scale = 0.0
		_stage.get_status_aura(FOE).speed_scale = 0.0
		await _frames(2)
		_stage.get_status_aura(PLAYER).set_time(MOMENT)
		_stage.get_status_aura(FOE).set_time(MOMENT + 0.5)
		await _shot(String(status))
	_stage.set_status(PLAYER, StatusRules.NONE)
	_stage.set_status(FOE, StatusRules.NONE)
	_stage.play_confusion(FOE)
	await _frames(1)
	await _shot("confusion")
	await _frames(40)
	_stage.play_poison(FOE, StatusRules.BURN)
	await _frames(1)
	await _shot("burn_veil")
	await _frames(30)
	_stage.reduce_motion = true
	_stage.set_status(FOE, StatusRules.FREEZE)
	_stage.set_status(PLAYER, StatusRules.SLEEP)
	await _shot("freeze_reduced")
	print("CAPTURE_STATUS_J11 terminé")
	quit()


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join("j11_status_%s.png" % name)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s" % path)


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
