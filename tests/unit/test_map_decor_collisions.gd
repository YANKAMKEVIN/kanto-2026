extends GutTest
## Le décor peint et la grille de collisions doivent dire la même chose (audit du 2026-11-09,
## tools/audit_decor_render.gd). Un échantillon de cases ouvertes par carte, et les deux maisons de
## Doublonville, dont l'image avait été masquée sans remplaçant.

const MARGINS: Dictionary = {
	&"fuchsia_city": [Vector2i(15, 13), Vector2i(16, 13)],
	&"vermilion_city": [Vector2i(5, 17), Vector2i(11, 17)],
	&"route_39": [Vector2i(13, 24), Vector2i(19, 24)],
	&"cianwood_city": [Vector2i(7, 8), Vector2i(13, 8)],
	# Poche de Nolan, Route 3 : le sable peint va jusqu'à la rangée 24.
	&"route_3": [Vector2i(74, 24), Vector2i(75, 24)],
}
const BODIES: Dictionary = {
	# Même poche : la paroi peinte occupe ces cases.
	&"route_3": [Vector2i(76, 23), Vector2i(77, 23)],
	&"fuchsia_city": [Vector2i(2, 35)],
	&"vermilion_city": [Vector2i(5, 18)],
	&"route_39": [Vector2i(13, 25)],
	&"cianwood_city": [Vector2i(7, 9)],
}


func _load(id: StringName) -> Node:
	var map: Node = (load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate()
	add_child_autofree(map)
	return map


func test_the_two_goldenrod_houses_are_drawn() -> void:
	var map := _load(&"goldenrod_city")
	for house: NodePath in [^"Entities/Bat_Maison1", ^"Entities/Bat_Maison2"]:
		assert_true((map.get_node(house) as CanvasItem).visible, "%s est dessinée" % house)


## Rangées d'herbe au nord des toits : le joueur y marche, jusqu'au toit dessiné.
func test_building_margins_are_walkable() -> void:
	for id: StringName in MARGINS:
		var grid: GridWorld = _load(id).call(&"get_grid")
		for cell: Vector2i in MARGINS[id]:
			assert_false(grid.is_solid(cell), "%s %s est libre" % [id, cell])


## Le corps des bâtiments reste bloqué.
func test_building_bodies_stay_solid() -> void:
	for id: StringName in BODIES:
		var grid: GridWorld = _load(id).call(&"get_grid")
		for cell: Vector2i in BODIES[id]:
			assert_true(grid.is_solid(cell), "%s %s reste bloquée" % [id, cell])
