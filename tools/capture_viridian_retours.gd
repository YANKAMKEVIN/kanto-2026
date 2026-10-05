extends SceneTree
## Captures des retours de Kevin sur la nouvelle Jadielle (T5, jalon-07.md §15.21) : portes des
## maisons, cadence de marche des habitants, micro-scène d'arrivée image par image.
##
##   godot --path . --resolution 2340x1080 --fixed-fps 30 \
##     -s res://tools/capture_viridian_retours.gd -- --out=build/captures/jalon07_t5_retours \
##     --tag=apres [--only=houses,walk,scene]
##
## `--fixed-fps 30` sans Movie Maker : chaque image avance de 1/30 s de jeu (cadences lisibles).
## - houses : devant chaque portail puis devant chaque porte (EXAMINER : « C'est fermé. »)
##   → house_<nom>_<tag>.png, door_<nom>_<tag>.png ;
## - walk : planches (une vignette par image à 30 i/s) d'habitants qui marchent pendant leurs
##   pas → walk_<id>_<tag>.png ;
## - scene : micro-scène d'arrivée, une image sur trois (0,1 s) en demi-taille
##   → scene_<tag>/f<nnn>.png, planche scene_<tag>.png, et vignettes de l'enfant
##   → scene_kid_<tag>.png ; la durée est écrite dans le journal.

const BOOT_SCENE := "res://game/boot.tscn"
const START := "res://tools/debug_start/viridian.json"
## [nom, case devant le portail (sur le chemin), case devant la porte].
const HOUSES: Array = [
	["south_west", Vector2i(20, 31), Vector2i(20, 29)],
	["south_east", Vector2i(38, 31), Vector2i(38, 29)],
	["west", Vector2i(7, 22), Vector2i(7, 18)],
	["east", Vector2i(47, 22), Vector2i(47, 18)],
	["north_west", Vector2i(19, 10), Vector2i(19, 7)],
	["north_east", Vector2i(37, 10), Vector2i(37, 7)],
]
## Habitants filmés en marche : [id, case du joueur (spectateur), nombre de pas].
const WALKERS: Array = [
	["courier", Vector2i(39, 23), 4],
	["old_man", Vector2i(29, 18), 4],
	["kid", Vector2i(17, 21), 4],
	["kid_rattata", Vector2i(17, 21), 4],
]
const THUMB := Vector2i(180, 220)
const SHEET_COLUMNS := 10

var _out_dir: String = "build/captures/jalon07_t5_retours"
var _tag: String = "apres"
var _only: PackedStringArray = []
var _boot: Node
var _player: Node2D
var _router: Node


func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			_out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--tag="):
			_tag = arg.trim_prefix("--tag=")
		elif arg.begins_with("--only="):
			_only = arg.trim_prefix("--only=").split(",")
	process_frame.connect(_start, CONNECT_ONE_SHOT)


func _start() -> void:
	_boot = (load(BOOT_SCENE) as PackedScene).instantiate()
	_boot.set(&"debug_start_path", START)
	_boot.set(&"force_debug_start", true)
	root.add_child(_boot)
	_router = root.get_node(^"SceneRouter")
	_router.set(&"fade_out_duration", 0.15)
	_router.set(&"fade_in_duration", 0.15)
	_run()


func _wants(mode: String) -> bool:
	return _only.is_empty() or _only.has(mode)


func _run() -> void:
	await _frames(3)
	_player = _boot.call(&"get_player")
	DirAccess.make_dir_recursive_absolute(_out_dir)
	print("viewport %s" % root.get_texture().get_size())
	await _seconds(1.0)
	if _wants("scene"):
		await _run_scene()
	root.get_node(^"GameState").get(&"flags").call(&"set_flag", &"viridian_arrived")
	_router.call(&"change_map", &"viridian_city", &"from_center", Vector2i.DOWN)
	await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
	await _seconds(0.5)
	if _wants("houses"):
		await _run_houses()
	if _wants("walk"):
		await _run_walk()
	if _wants("shadows"):
		await _run_shadows()
	quit()


## Même cadrage avant / après la végétation sans ombre : la place de Jadielle, un jardin du
## bas, puis Bourg Palette (arbre de la place).
func _run_shadows() -> void:
	_teleport(Vector2i(28, 22), Vector2i.UP)
	await _seconds(0.6)
	await _shot("shadows_viridian_square_" + _tag)
	_teleport(Vector2i(38, 31), Vector2i.UP)
	await _seconds(0.6)
	await _shot("shadows_viridian_garden_" + _tag)
	_router.call(&"change_map", &"pallet_town", &"player_house_door", Vector2i.DOWN)
	await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
	await _seconds(2.5)
	await _shot("shadows_pallet_" + _tag)
	_teleport(Vector2i(37, 10), Vector2i.UP)
	await _seconds(0.6)
	await _shot("shadows_pallet_house_" + _tag)
	_router.call(&"change_map", &"route_1", &"start", Vector2i.UP)
	await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
	await _seconds(2.0)
	await _shot("shadows_route1_" + _tag)
	_router.call(&"change_map", &"viridian_center", &"entrance", Vector2i.UP)
	await _until(func() -> bool: return not _router.call(&"is_transitioning"), 5.0)
	await _seconds(2.0)
	await _shot("shadows_interior_" + _tag)


func _run_houses() -> void:
	var runner: Node = _boot.call(&"get_dialogue_runner")
	for house: Array in HOUSES:
		_teleport(house[1], Vector2i.UP)
		await _seconds(0.6)
		await _shot("house_%s_%s" % [house[0], _tag])
		_teleport(house[2], Vector2i.UP)
		await _seconds(0.4)
		await _tap_interact()
		await _seconds(1.2)
		print("DOOR %s : dialogue %s" % [house[0], runner.call(&"is_running")])
		await _shot("door_%s_%s" % [house[0], _tag])
		for attempt in 6:
			if not runner.call(&"is_running"):
				break
			await _tap_interact()
			await _seconds(0.4)


func _run_walk() -> void:
	var map: Node = _boot.call(&"get_map")
	for walker: Array in WALKERS:
		var npc := map.call(&"get_npc", StringName(walker[0])) as Node2D
		if npc == null:
			print("WALK %s : absent" % walker[0])
			continue
		_teleport(walker[1], Vector2i.UP)
		await _frames(2)
		var thumbs: Array[Image] = []
		var steps := 0
		var was_moving := false
		var waited := 0
		while steps < int(walker[2]) and waited < 900:
			await process_frame
			await RenderingServer.frame_post_draw
			waited += 1
			var moving: bool = npc.call(&"is_moving")
			if moving:
				thumbs.append(_crop_around(npc))
			if was_moving and not moving:
				steps += 1
			was_moving = moving
		_save_sheet(thumbs, "walk_%s_%s" % [walker[0], _tag])


func _run_scene() -> void:
	var director: Node = _boot.call(&"get_cutscene_director")
	var dir := _out_dir.path_join("scene_" + _tag)
	DirAccess.make_dir_recursive_absolute(dir)
	Input.action_press(&"move_up")
	await _until(func() -> bool: return director.call(&"is_running"), 8.0)
	Input.action_release(&"move_up")
	var map: Node = _boot.call(&"get_map")
	var kid := map.call(&"get_npc", &"arrival_kid") as Node2D
	var frames := 0
	var shots: Array[Image] = []
	var kid_thumbs: Array[Image] = []
	while director.call(&"is_running") and frames < 300:
		await process_frame
		await RenderingServer.frame_post_draw
		if is_instance_valid(kid) and kid.call(&"is_moving"):
			kid_thumbs.append(_crop_around(kid))
		if frames % 3 == 0:
			var image := root.get_texture().get_image()
			image.resize(image.get_width() / 2, image.get_height() / 2, Image.INTERPOLATE_BILINEAR)
			image.save_png(dir.path_join("f%03d.png" % frames))
			var small := image.duplicate() as Image
			small.resize(image.get_width() / 3, image.get_height() / 3,
				Image.INTERPOLATE_BILINEAR)
			shots.append(small)
		frames += 1
	print("SCENE : %d images à 30 i/s = %.2f s de jeu" % [frames, frames / 30.0])
	_save_sheet(shots, "scene_" + _tag, 6)
	_save_sheet(kid_thumbs, "scene_kid_" + _tag)
	await _seconds(0.3)
	await _shot("scene_after_" + _tag)


## Vignette centrée sur les pieds de [param node] (coordonnées du viewport).
func _crop_around(node: Node2D) -> Image:
	var image := root.get_texture().get_image()
	var feet := node.get_global_transform_with_canvas().origin
	var rect := Rect2i(Vector2i(feet) - Vector2i(THUMB.x / 2, THUMB.y - 40), THUMB)
	rect = rect.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var thumb := Image.create(THUMB.x, THUMB.y, false, image.get_format())
	thumb.blit_rect(image, rect, Vector2i.ZERO)
	return thumb


func _save_sheet(images: Array[Image], sheet_name: String, columns: int = SHEET_COLUMNS) -> void:
	if images.is_empty():
		print("SHEET %s : aucune image" % sheet_name)
		return
	var size := images[0].get_size()
	var rows := ceili(images.size() / float(columns))
	var sheet := Image.create(size.x * columns, size.y * rows, false, images[0].get_format())
	sheet.fill(Color(0.1, 0.1, 0.1))
	for i in images.size():
		var at := Vector2i(i % columns, i / columns) * size
		sheet.blit_rect(images[i], Rect2i(Vector2i.ZERO, size), at)
	var path := _out_dir.path_join(sheet_name + ".png")
	sheet.save_png(path)
	print("SHEET %s : %d images → %s" % [sheet_name, images.size(), path])


func _tap_interact() -> void:
	var press := InputEventAction.new()
	press.action = &"interact"
	press.pressed = true
	Input.parse_input_event(press)
	await _frames(3)
	var release := InputEventAction.new()
	release.action = &"interact"
	release.pressed = false
	Input.parse_input_event(release)
	await _frames(2)


func _teleport(cell: Vector2i, facing: Vector2i) -> void:
	var map: Node = _boot.call(&"get_map")
	map.call(&"spawn_player_at", _player, cell, facing)


func _frames(count: int) -> void:
	for i in count:
		await process_frame


func _seconds(seconds: float) -> void:
	await create_timer(seconds).timeout


func _until(condition: Callable, timeout: float) -> void:
	var waited := 0.0
	while not condition.call() and waited < timeout:
		await process_frame
		waited += root.get_process_delta_time()


func _shot(capture_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var path := _out_dir.path_join(capture_name + ".png")
	root.get_texture().get_image().save_png(path)
	print("CAPTURE %s cell=%s → %s" % [capture_name, _player.call(&"get_cell"), path])
