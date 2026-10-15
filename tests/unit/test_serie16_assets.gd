extends GutTest
## Série 16 intégrée (J14 T13, fiche `serie-16-cap-azuria.md`) : modules du rivage, maison de
## Léo, meubles de la machine, apparences (Léo humain, Mélofée), icônes du Sac.

const CATALOGUE := "res://assets/world/catalogue.json"
const SHORE_MODULES: Array[String] = [
	"relief_rivage_01", "relief_rivage_02", "relief_rivage_03", "relief_rivage_04",
	"relief_rivage_05", "relief_rivage_06",
]
const LEO_FURNITURE: Array[String] = [
	"int_cabine_teleport_01", "int_console_leo_01", "int_module_leo_01",
	"int_ecran_diagnostic_01", "int_bureau_leo_01", "int_bibliotheque_cote_01",
]

var _objects: Dictionary = {}
var _images: Dictionary = {}


func before_all() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	_objects = catalogue["objets"]
	_images = catalogue["images"]


func test_shore_modules_are_cell_multiples_wide() -> void:
	# 01 / 02 : 2 cases de long ; 03 à 06 : 1 case de large.
	for id: String in SHORE_MODULES:
		var size: Array = _objects[id]["taille"]
		var expected := 192 if id in ["relief_rivage_01", "relief_rivage_02"] else 96
		assert_eq(int(size[0]), expected, "%s : largeur" % id)


func test_east_shore_module_is_two_cells_tall() -> void:
	var size: Array = _objects["relief_rivage_03"]["taille"]
	assert_almost_eq(float(size[1]), 192.0, 24.0)


func test_leo_house_is_eight_cells_wide() -> void:
	var size: Array = _objects["bldg_maison_leo_01"]["taille"]
	assert_eq(int(size[0]), 8 * 96)
	assert_almost_eq(float(size[1]), 6.0 * 96.0, 40.0, "environ 6 cases de haut")


func test_leo_room_shell_is_16_by_11_cells() -> void:
	var size: Array = _images["int_maison_leo_coque"]["taille"]
	assert_eq(Vector2i(int(size[0]), int(size[1])), Vector2i(16 * 96, 11 * 96))


func test_leo_furniture_has_scenes_with_footprints() -> void:
	for id: String in LEO_FURNITURE + ["prop_indice_coquillage_01"]:
		var packed := load("res://game/world/props/painted/%s.tscn" % id) as PackedScene
		assert_not_null(packed, id)
		if packed == null:
			continue
		var prop := packed.instantiate() as WorldProp
		add_child_autofree(prop)
		assert_false(prop.footprint.is_empty(), "%s : emprise" % id)


func test_looks_have_frames_with_idle() -> void:
	var looks: Array[String] = [
		"res://assets/sprites/characters/painted/bill_frames.tres",
		"res://assets/sprites/pokemon/painted/clefairy_frames.tres",
	]
	for path: String in looks:
		var frames := load(path) as SpriteFrames
		assert_not_null(frames, path)
		if frames == null:
			continue
		for animation: StringName in [&"idle_down", &"walk_down", &"walk_up", &"walk_left"]:
			assert_true(frames.has_animation(animation), "%s : %s" % [path, animation])


func test_bag_icons_are_256_squares() -> void:
	for id: String in ["ss_ticket", "rare_candy"]:
		var image := Image.load_from_file(
			ProjectSettings.globalize_path("res://assets/ui/items/%s.webp" % id))
		assert_not_null(image, id)
		if image != null:
			assert_eq(image.get_size(), Vector2i(256, 256), id)
