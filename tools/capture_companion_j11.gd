extends SceneTree
## Captures du nœud du compagnon (jalon 11, T20b), vrai Boot sur la Route 1, compagnon posé à la
## main derrière le joueur (le contrôleur arrive au T20c) :
##   godot --path . --resolution 2340x1080 --fixed-fps 30 -s res://tools/capture_companion_j11.gd \
##     -- --out=build/captures/jalon11_t20b
## Images : companion_behind (Salamèche derrière le joueur), companion_note (bulle « ♪ »),
## companion_grass (Roucool dans les hautes herbes), companion_burst (sortie de Ball, mi-éclat).

var _boot: Node
var _out_dir: String = "build/captures/jalon11_t20b"


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


func _start() -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate()
	_boot.set(&"start_map", &"route_1")
	_boot.set(&"start_spawn", &"from_pallet_w")
	_boot.set(&"start_facing", Vector2i.UP)
	root.add_child(_boot)
	await _frames(30)
	var explo: CanvasLayer = _boot.call(&"get_hud")
	explo.visible = false
	var map: GameMap = _boot.call(&"get_map")
	var player: Player = _boot.call(&"get_player")
	# Le joueur quelques cases plus haut, pour que la caméra le centre.
	var grid0 := map.get_grid()
	for up: int in range(5, 0, -1):
		var cell := player.get_cell() + Vector2i.UP * up
		if grid0.is_free(cell) and grid0.is_free(cell + Vector2i.DOWN):
			player.enter_map(grid0, cell, Vector2i.UP, map.get_pixel_rect())
			break
	await _frames(10)
	var companion := Companion.new()
	map.get_node(^"Entities").add_child(companion)
	companion.set_grid(map.get_grid())
	companion.set_grass_front(map.grass_front)
	companion.set_species(&"charmander", &"pokemon/charmander")
	companion.place(player.get_cell() + Vector2i.DOWN, Vector2i.UP)
	companion.visible = true
	print("DEBUG ", companion.global_position, " player ", player.global_position, " vis ",
		companion.is_visible_in_tree(), " frames ", companion.get_sprite().sprite_frames,
		" anim ", companion.get_sprite().animation, " parent ", companion.get_parent().get_path(),
		" player parent ", player.get_parent().get_path(), " mod ", companion.get_sprite().modulate,
		" scale ", companion.get_sprite().scale)
	await _shot("companion_behind")
	companion.face(Vector2i.UP)
	companion.show_emote(EmoteBubble.NOTE)
	await _frames(8)
	await _shot("companion_note")
	# Roucool dans les hautes herbes les plus proches du joueur.
	var grid := map.get_grid()
	var best := Vector2i(-1, -1)
	for y: int in grid.get_size().y:
		for x: int in grid.get_size().x:
			var cell := Vector2i(x, y)
			if grid.is_tall_grass(cell) and (best.x < 0 or (cell - player.get_cell()).length() \
					< (best - player.get_cell()).length()):
				best = cell
	companion.set_species(&"pidgey", &"pokemon/pidgey")
	companion.place(best, Vector2i.DOWN)
	player.enter_map(grid, best + Vector2i.UP if grid.is_free(best + Vector2i.UP) \
		else best + Vector2i.RIGHT, Vector2i.DOWN, map.get_pixel_rect())
	await _frames(10)
	await _shot("companion_grass")
	companion.withdraw(true)
	companion.appear()
	await _frames(5)
	await _shot("companion_burst")
	print("CAPTURE_COMPANION_J11 terminé")
	quit()
