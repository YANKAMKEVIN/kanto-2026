extends GutTest
## Reliquats du chantier « Menu Dresseur peint » (2026-11-02) : disques de CT par type (RP-256,
## [D]), Master Ball repeinte, étiquettes de la Carte sans chevauchement ([MapLabelLayout]).

const TM_TYPES: Array[StringName] = [&"normal", &"fighting", &"flying", &"poison", &"ground",
	&"rock", &"electric", &"fire", &"water", &"grass", &"ice", &"psychic", &"dragon"]

var _items := ItemLibrary.new()
var _data := PokemonData.new()


func before_all() -> void:
	assert_true(_items.load_dir(), "objets")
	assert_true(_data.load_dir(), "Pokémon")


func after_each() -> void:
	MenuArt.set_tm_types({})


func test_every_tm_type_has_its_painted_disc() -> void:
	var types := MenuArt.tm_types(_items, _data)
	assert_gt(types.size(), 40, "toutes les CT ont un type")
	for type: StringName in types.values():
		assert_has(TM_TYPES, type, "type de CT prévu : %s" % type)
	for type: StringName in TM_TYPES:
		var path := MenuArt.tm_disc_path(type)
		assert_true(ResourceLoader.exists(path), path)
		var icon := load(path) as Texture2D
		if icon != null:
			assert_eq(icon.get_size(), Vector2(256, 256), path)


func test_tm_resolves_to_its_type_disc_and_hm_keeps_its_own() -> void:
	MenuArt.set_tm_types(MenuArt.tm_types(_items, _data))
	assert_eq(MenuArt.item_icon_path(&"tm38"), MenuArt.tm_disc_path(&"fire"), "Déflagration")
	assert_eq(MenuArt.item_icon_path(&"tm01"), MenuArt.tm_disc_path(&"normal"), "Ultimapoing")
	assert_eq(MenuArt.item_icon(&"tm24"), load(MenuArt.tm_disc_path(&"electric")), "Tonnerre")
	assert_eq(MenuArt.item_icon_path(&"hm01"), "res://assets/ui/items/hm01.webp", "CS01 propre")
	assert_eq(MenuArt.item_icon_path(&"potion"), "res://assets/ui/items/potion.webp")


func test_master_ball_is_its_own_painting_not_a_tint() -> void:
	var master := Image.load_from_file(ProjectSettings.globalize_path(
		"res://assets/ui/items/master_ball.webp"))
	var poke := Image.load_from_file(ProjectSettings.globalize_path(
		"res://assets/ui/items/poke_ball.webp"))
	assert_eq(master.get_size(), Vector2i(256, 256))
	var same_alpha := 0
	var total := 0
	for y: int in range(0, 256, 4):
		for x: int in range(0, 256, 4):
			total += 1
			if absf(master.get_pixel(x, y).a - poke.get_pixel(x, y).a) < 0.02:
				same_alpha += 1
	assert_lt(float(same_alpha) / total, 0.99, "silhouette différente de la Poké Ball teintée")


# --- MapLabelLayout ------------------------------------------------------------------------

func test_layout_never_overlaps_and_hides_secondary_labels() -> void:
	var sizes: Array[Vector2] = []
	var candidates: Array[Array] = []
	var order: Array[int] = []
	# Dix étiquettes au même endroit : la première (forcée) garde sa place, les autres prennent
	# une autre candidate ou sont masquées, sans jamais se chevaucher.
	for i: int in 10:
		sizes.append(Vector2(120, 40))
		candidates.append([Vector2(100, 100), Vector2(230, 100), Vector2(100, 150)])
		order.append(i)
	var placed := MapLabelLayout.place(sizes, candidates, order, 1, Rect2(0, 0, 400, 300), [], 4.0)
	assert_false(MapLabelLayout.has_overlap(placed))
	assert_eq(placed[0].position, Vector2(100, 100), "la forcée garde sa place préférée")
	assert_eq(placed[1].position, Vector2(230, 100), "la suivante prend une autre candidate")
	assert_eq(placed[2].position, Vector2(100, 150))
	assert_false(placed[9].has_area(), "étiquette secondaire sans place : masquée")


func test_forced_labels_are_never_hidden_and_avoid_obstacles() -> void:
	var sizes: Array[Vector2] = [Vector2(100, 40), Vector2(100, 40)]
	var candidates: Array[Array] = [[Vector2(50, 50)], [Vector2(50, 50)]]
	var obstacles: Array[Rect2] = [Rect2(40, 40, 30, 30)]
	var placed := MapLabelLayout.place(sizes, candidates, [0, 1] as Array[int], 2,
		Rect2(0, 0, 400, 300), obstacles, 4.0)
	assert_true(placed[0].has_area() and placed[1].has_area(), "jamais masquées")
	var all: Array[Rect2] = placed.duplicate()
	all.append_array(obstacles)
	assert_false(MapLabelLayout.has_overlap(all), "ni entre elles ni sur le portrait")
