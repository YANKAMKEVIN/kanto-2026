extends SceneTree
## Vérification visuelle des dos peints de battle_proto en combat (Route 1, 2340 × 1080 via
## override.cfg temporaire) : une capture par espèce du joueur (IA : Salamèche, Pikachu ; 3D seul :
## Taupiqueur, Soporifik, Smogo ; IA sur 3D : Bulbizarre).
##   godot --path . --fixed-fps 30 --quit-after 9000 -s res://tools/capture_dos_proto.gd -- --out=build/captures/dos_proto
## `--species=a,b,c` remplace la liste des espèces du joueur.

const BOOT_SCENE: String = "res://game/boot.tscn"
const PLAYER := 0
const FOE := 1
const SPAWNS: Dictionary = {&"route_1": &"from_pallet_w", &"oak_lab": &"entrance",
	&"route_22": &"from_viridian"}

var _boot: Node
var _stage: CanvasLayer
var _camera: Camera2D
var _out_dir: String = "build/captures/dos_proto"
var _place: StringName = &"route_1"
var _species: Array[StringName] = [&"charmander", &"pikachu", &"bulbasaur", &"diglett", &"drowzee",
	&"koffing"]


func _init() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		InputMap.action_erase_events(action)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--place="):
			_place = StringName(arg.trim_prefix("--place="))
		elif arg.begins_with("--species="):
			_species.clear()
			for id: String in arg.trim_prefix("--species=").split(","):
				_species.append(StringName(id))
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
	await _frames(10)
	await _start_shots()
	print("CAPTURE_DOS_PROTO terminé")
	quit()


func _start_shots() -> void:
	var first := true
	for mine: StringName in _species:
		if not first:
			await _exit()
		first = false
		await _wild(&"rattata", mine)
		await _shot(String(mine))


func _wild(foe: StringName, mine: StringName) -> void:
	var map: Node = _boot.call(&"get_map")
	_stage.call(&"set_frame", map.call(&"get_battle_arena_rect"),
		Rect2(map.call(&"get_pixel_rect")))
	await _stage.call(&"play_wild_intro", _camera, foe, _origin())
	await _stage.call(&"play_partner_enter", mine)
	await _frames(6)


func _origin() -> Vector2:
	var player: Node2D = _boot.call(&"get_player")
	return player.global_position + Vector2(96.0, -192.0)


func _exit() -> void:
	await _stage.call(&"exit")
	await _frames(4)


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var path := _out_dir.path_join("dos_%s.png" % name)
	DirAccess.make_dir_recursive_absolute(_out_dir)
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s viewport=%s" % [path, root.get_visible_rect().size])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
