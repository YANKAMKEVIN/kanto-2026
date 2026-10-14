extends GutTest
## Voile de pénombre des grottes (`tools/cave_shade.gd`, passe « lumière rare » du J12) : calcul
## pur sur de petites grilles — pied des parois et pourtour plus sombres que le centre, parois à
## la valeur du pied, sources qui lèvent la pénombre et ajoutent leur flaque au sol, images aux
## dimensions de la carte, réglages obligatoires.

const CaveShade := preload("res://tools/cave_shade.gd")
const PARAMS: Dictionary = {"ambient": 0.9, "edge_min": 0.5, "edge_radius": 1.0,
	"room_min": 0.8, "room_radius": 3.0, "tint": Color(0.8, 0.9, 1.0)}
const PX: int = 8


## Salle ouverte de (1, 1) à (size − 2) : bord d'une case de paroi.
func _room(size: Vector2i) -> Dictionary:
	var open: Dictionary = {}
	for y: int in range(1, size.y - 1):
		for x: int in range(1, size.x - 1):
			open[Vector2i(x, y)] = true
	return open


func _shade(size: Vector2i, lights: Array = []) -> RefCounted:
	var shade: RefCounted = CaveShade.new(size, _room(size), PARAMS, PX)
	shade.call(&"compute", lights)
	return shade


func test_centre_is_brighter_than_the_foot_of_the_walls() -> void:
	var shade := _shade(Vector2i(13, 13))
	var centre: float = shade.call(&"cell_mean", Vector2i(6, 6))
	var foot: float = shade.call(&"cell_mean", Vector2i(1, 6))
	var second: float = shade.call(&"cell_mean", Vector2i(2, 6))
	assert_gt(centre, second, "dégradé vers le pourtour")
	assert_gt(second, foot, "pied de paroi le plus sombre")
	assert_almost_eq(centre, PARAMS["ambient"], 0.01, "centre d'une grande salle = ambiance")
	assert_gt(centre / foot, 1.25, "écart net centre / pourtour")


func test_wall_cells_take_the_value_of_the_wall_foot() -> void:
	var shade := _shade(Vector2i(9, 9))
	var wall: float = shade.call(&"cell_mean", Vector2i(0, 4))
	var expected: float = PARAMS["ambient"] * PARAMS["edge_min"] * PARAMS["room_min"]
	assert_almost_eq(wall, expected, 0.001)


func test_a_light_lifts_the_shade_and_adds_a_floor_pool() -> void:
	var size := Vector2i(13, 13)
	var dark := _shade(size)
	var light := {"center": Vector2(1.5, 6.5) * 96.0, "radius": 3.0 * 96.0, "strength": 1.0,
		"add": 0.2, "color": Color(1.0, 0.8, 0.5)}
	var lit := _shade(size, [light])
	var near: float = lit.call(&"cell_mean", Vector2i(1, 6))
	assert_gt(near, 0.95, "au pied de la source, la pénombre est levée")
	assert_gt(near, dark.call(&"cell_mean", Vector2i(1, 6)))
	assert_almost_eq(lit.call(&"cell_mean", Vector2i(11, 6)),
		dark.call(&"cell_mean", Vector2i(11, 6)), 0.0001, "hors de portée : inchangé")
	assert_gt(lit.call(&"glow_cell_mean", Vector2i(1, 6)), 0.1, "flaque ajoutée au sol")
	assert_eq(lit.call(&"glow_cell_mean", Vector2i(11, 6)), 0.0)
	assert_eq(dark.call(&"glow_cell_mean", Vector2i(1, 6)), 0.0, "aucune source, aucun ajout")


func test_a_light_without_add_only_lifts_the_shade() -> void:
	var lit := _shade(Vector2i(9, 9), [{"center": Vector2(4.5, 4.5) * 96.0,
		"radius": 2.0 * 96.0, "strength": 0.5}])
	assert_eq(lit.call(&"glow_cell_mean", Vector2i(4, 4)), 0.0)
	assert_gt(lit.call(&"cell_mean", Vector2i(4, 4)), _shade(Vector2i(9, 9)).call(&"cell_mean",
		Vector2i(4, 4)))


func test_falloff() -> void:
	assert_eq(CaveShade.falloff(0.0), 1.0)
	assert_eq(CaveShade.falloff(0.25), 1.0, "cœur d'un quart du rayon")
	assert_eq(CaveShade.falloff(1.0), 0.0)
	assert_eq(CaveShade.falloff(2.0), 0.0)
	assert_between(CaveShade.falloff(0.6), 0.0, 1.0)
	assert_gt(CaveShade.falloff(0.4), CaveShade.falloff(0.8))


func test_images_have_the_map_size_and_cool_the_shadows() -> void:
	var size := Vector2i(7, 5)
	var shade := _shade(size)
	var image: Image = shade.call(&"to_image")
	assert_eq(image.get_size(), size * PX)
	assert_eq((shade.call(&"glow_image") as Image).get_size(), size * PX)
	var wall := image.get_pixel(0, 0)
	assert_gt(wall.b, wall.r, "pénombre refroidie (teinte bleutée)")
	assert_almost_eq(shade.call(&"sample", Vector2(3.5, 2.5) * 96.0),
		shade.get(&"values")[(2 * PX + PX / 2) * size.x * PX + 3 * PX + PX / 2], 0.0001)


func test_missing_params_are_reported() -> void:
	var params := PARAMS.duplicate()
	params.erase("tint")
	params.erase("ambient")
	var errors: PackedStringArray = CaveShade.check_params(params)
	assert_eq(errors.size(), 2)
	assert_eq(CaveShade.check_params(PARAMS).size(), 0)
