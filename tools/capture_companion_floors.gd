extends SceneTree
## Captures du contrôle « compagnon au chargement d'un étage » (session 12B, `etat-projet.md` J12) :
##   godot --path . --resolution 2340x1080 --fixed-fps 60 -s res://tools/capture_companion_floors.gd \
##     -- --out=build/qa/fix_etages
## Départ de débogage `mt_moon_1f` (ni lecture ni écriture de la sauvegarde), puis trois arrivées
## par une échelle, chacune : `<nom>_0` à l'arrivée (pas de case libre hors passage : caché),
## `<nom>_1` après deux pas enchaînés sans s'arrêter (il est sorti et suit derrière le joueur).
##   ladder_c_b1f : échelle C → B1F, Nosferapti (vol) ;
##   ladder_a_1f  : échelle A → 1F, Rondoudou ;
##   ladder_d_b2f : échelle D → B2F, Racaillou (planche de marche `geodude_walk`).

const START := "res://tools/debug_start/mt_moon_1f.json"
const STEPS := 2
## De côté d’abord : marchant vers le bas, le compagnon (au nord) est caché par le joueur.
const DIRECTIONS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const ACTIONS: Dictionary[Vector2i, StringName] = {
	Vector2i.DOWN: &"move_down", Vector2i.LEFT: &"move_left", Vector2i.RIGHT: &"move_right",
	Vector2i.UP: &"move_up",
}

var _boot: Node
var _router: Node
var _state: Node
var _out_dir: String = "build/qa/fix_etages"


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _frames(n: int) -> void:
	for i: int in n:
		await process_frame


func _shot(name: String) -> void:
	await _frames(2)
	root.get_texture().get_image().save_png("%s/%s.png" % [_out_dir, name])
	print("CAPTURE ", name)


func _player() -> Player:
	return _boot.call(&"get_player")


func _map() -> GameMap:
	return _boot.call(&"get_map")


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"force_debug_start", true)
	_boot.set(&"debug_start_path", START)
	root.add_child(_boot)
	await _frames(30)
	_router = root.get_node(^"SceneRouter")
	_state = root.get_node(^"GameState")
	await _ladder("ladder_c_b1f", 2, &"mt_moon_b1f", &"arrivee_c", Vector2i.UP)
	await _ladder("ladder_a_1f", 1, &"mt_moon_1f", &"arrivee_a", Vector2i.DOWN)
	await _ladder("ladder_d_b2f", 4, &"mt_moon_b2f", &"arrivee_d", Vector2i.DOWN)
	quit()


## Compagnon = membre [param member] de l'équipe, arrivée sur [param map] / [param spawn]
## (orientation [param facing] du passage), capture, deux pas, capture.
func _ladder(label: String, member: int, map: StringName, spawn: StringName,
		facing: Vector2i) -> void:
	var party: Party = _state.get(&"party")
	_state.call(&"set_companion", party.get_at(member))
	var companion: CompanionController = _boot.call(&"get_companion_controller")
	companion.refresh()
	_router.call(&"change_map", map, spawn, facing)
	await _frames(2)
	while _map().map_id != map or bool(_router.call(&"is_transitioning")):
		await process_frame
	await _frames(20)
	await _shot(label + "_0")
	print("%s : arrivée, compagnon montré = %s" % [label, companion.is_shown()])
	var direction := _free_direction()
	var steps := [0]
	var on_started := func(_f: Vector2i, _t: Vector2i, _k: StringName) -> void:
		steps[0] += 1
		if steps[0] >= STEPS:
			Input.action_release(ACTIONS[direction])
	_player().step_started.connect(on_started)
	Input.action_press(ACTIONS[direction])
	while steps[0] < STEPS or _player().is_moving():
		await process_frame
	Input.action_release(ACTIONS[direction])
	_player().step_started.disconnect(on_started)
	await _frames(30)
	await _shot(label + "_1")
	print("%s : après %d pas vers %s, compagnon montré = %s, case %s, joueur %s, planche %s" % [
		label, STEPS, direction, companion.is_shown(), companion.get_node_2d().get_cell(),
		_player().get_cell(),
		companion.get_node_2d().get_sprite().sprite_frames.resource_path.get_file()])


## Une direction avec [constant STEPS] cases libres (ni passage, ni herbes, ni gravats).
func _free_direction() -> Vector2i:
	var grid := _map().get_grid()
	var warps := _map().get_warps()
	for direction: Vector2i in DIRECTIONS:
		var ok := true
		for i: int in range(1, STEPS + 1):
			var cell := _player().get_cell() + direction * i
			if not grid.is_free(cell) or not warps.get_at(cell).is_empty() \
					or grid.is_tall_grass(cell) or grid.is_rubble(cell):
				ok = false
		if ok:
			return direction
	return Vector2i.DOWN
