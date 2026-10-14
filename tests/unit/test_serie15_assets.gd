extends GutTest
## Série 15 intégrée (J13 T5, fiche `serie-15-azuria.md`) : apparences des personnages, icône de la
## Pépite, modules de quai et de pont aux tailles attendues par `cerulean_map_kit`.

const CATALOGUE := "res://assets/world/catalogue.json"
const LOOKS: Array[String] = ["misty", "swimmer", "swimmer_f"]
const QUAY_SIZES: Dictionary = {
	"relief_quai_01": Vector2i(192, 69), "relief_quai_03": Vector2i(192, 30),
	"relief_quai_04": Vector2i(20, 112), "relief_quai_05": Vector2i(40, 51),
}

var _objects: Dictionary = {}


func before_all() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	_objects = catalogue["objets"]


func test_character_looks_have_frames_with_idle() -> void:
	for id: String in LOOKS:
		var frames := load("res://assets/sprites/characters/painted/%s_frames.tres" % id) \
			as SpriteFrames
		assert_not_null(frames, id)
		if frames == null:
			continue
		for animation: StringName in [&"idle_down", &"walk_down", &"walk_up", &"walk_left"]:
			assert_true(frames.has_animation(animation), "%s : %s" % [id, animation])


func test_nugget_icon_is_a_256_square() -> void:
	var image := Image.load_from_file(
		ProjectSettings.globalize_path("res://assets/ui/items/nugget.webp"))
	assert_not_null(image)
	assert_eq(image.get_size(), Vector2i(256, 256))


func test_quay_modules_have_the_sizes_the_kit_expects() -> void:
	for id: String in QUAY_SIZES:
		var size: Array = _objects[id]["taille"]
		var expected: Vector2i = QUAY_SIZES[id]
		assert_eq(int(size[0]), expected.x, "%s : largeur" % id)
		assert_almost_eq(float(size[1]), float(expected.y), 3.0, "%s : hauteur" % id)


func test_stone_decks_are_two_cells_long() -> void:
	# Tabliers de pierre recadrés (`serie15.py --retouches`) : 2 cases de long, sans poteau d'angle.
	for id: String in ["prop_pont_ville_01", "prop_pont_ville_03_01"]:
		var size: Array = _objects[id]["taille"]
		assert_almost_eq(float(size[1]), 192.0, 14.0, "%s : 2 cases de long" % id)
