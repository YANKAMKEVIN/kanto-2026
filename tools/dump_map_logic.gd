extends SceneTree
## Outil (DA.2) : écrit la grille logique d'une carte en texte, une ligne par rangée :
## « # » solide, « ~ » eau, « g » hautes herbes praticables, « G » hautes herbes solides,
## « . » praticable. Sert à figer la géométrie avant de repeindre une carte.
##   godot --headless --path . -s res://tools/dump_map_logic.gd -- <map_id> <sortie res://…>
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var id: String = args[0] if args.size() > 0 else "pallet_town"
	var map: Node = (load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate()
	var grid = map.get_grid()
	var size: Vector2i = map.size
	var lines := PackedStringArray()
	for y in size.y:
		var s := ""
		for x in size.x:
			var c := Vector2i(x, y)
			if grid.is_water(c):
				s += "~"
			elif grid.is_tall_grass(c):
				s += "G" if grid.is_solid(c) else "g"
			elif grid.is_solid(c):
				s += "#"
			else:
				s += "."
		lines.append(s)
	var text := "\n".join(lines) + "\n"
	if args.size() > 1:
		var f := FileAccess.open(args[1], FileAccess.WRITE)
		f.store_string(text)
		f.close()
	print(text)
	map.free()
	quit()
