extends GutTest
## Série 17 intégrée (J15 T11, fiche `serie-17-carmin.md`) : bâtiments, S.S. Anne en trois
## tranches raccordées, sols, meubles, apparences (marin, docker, président), icônes du Sac,
## décor de combat.

const CATALOGUE := "res://assets/world/catalogue.json"
const BUILDINGS: Dictionary = {
	"bldg_pension_01": 7, "bldg_poste_safrania_01": 7, "bldg_entree_souterrain_01": 7,
	"bldg_arene_carmin_01": 12, "bldg_fan_club_01": 8, "bldg_maison_pecheur_01": 7,
}
const SHIP: Array[String] = [
	"bldg_ss_anne_proue_01", "bldg_ss_anne_milieu_01", "bldg_ss_anne_poupe_01"]
const SHIP_CASES: Array[int] = [10, 9, 10]
const GROUNDS: Array[String] = [
	"ground_planches_quai_01", "ground_planches_quai_ns_01", "ground_dalles_souterrain_01",
	"ground_traces_souterrain_01",
]
const FURNITURE: Array[String] = [
	"int_comptoir_pension_01", "int_escalier_descendant_01", "int_panier_pokemon_01",
	"int_fauteuil_president_01", "int_vitrine_rubans_01", "int_tableau_port_01",
]

var _objects: Dictionary = {}
var _images: Dictionary = {}


func before_all() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	_objects = catalogue["objets"]
	_images = catalogue["images"]


func test_buildings_are_whole_cells_wide() -> void:
	for id: String in BUILDINGS:
		var size: Array = _objects[id]["taille"]
		assert_eq(int(size[0]), int(BUILDINGS[id]) * 96, "%s : largeur" % id)
		assert_true(float(size[1]) > 3.0 * 96.0, "%s : au moins 3 cases de haut" % id)
		assert_true(_objects[id].has("ombre"), "%s : ombre portée" % id)


func test_ship_slices_are_10_9_10_cells_wide_with_no_shadow() -> void:
	for i in SHIP.size():
		var entry: Dictionary = _objects[SHIP[i]]
		assert_eq(int(entry["taille"][0]), SHIP_CASES[i] * 96, "%s : largeur" % SHIP[i])
		assert_false(entry.has("ombre") or entry.has("contact"), "%s : ni ombre ni contact" % SHIP[i])


func test_ship_slices_meet_on_the_same_waterline() -> void:
	# Le bas de chaque tranche (dernière rangée opaque) est à la même hauteur : posées au même
	# pied, les trois lignes de flottaison se prolongent. Les coutures ont les mêmes lignes
	# opaques (la coque est coupée net, aux mêmes hauteurs).
	var images: Array[Image] = []
	for id: String in SHIP:
		var image := Image.load_from_file(
			ProjectSettings.globalize_path(String(_objects[id]["fichier"])))
		assert_not_null(image, id)
		images.append(image)
	for i in range(1, images.size()):
		var left := images[i - 1]
		var right := images[i]
		var mismatched := 0
		for offset in range(1, 120):
			var y_left := left.get_height() - offset
			var y_right := right.get_height() - offset
			var a := left.get_pixel(left.get_width() - 1, y_left).a > 0.5
			var b := right.get_pixel(0, y_right).a > 0.5
			if a != b:
				mismatched += 1
		assert_lt(mismatched, 6, "couture %d : lignes opaques discordantes" % i)


func test_vue_du_port_has_no_water_below() -> void:
	# Base coupée net (retouche de Kevin, 2026-10-15) : la dernière rangée est la plus opaque
	# de son voisinage (pas de bandeau de mer fondu en transparence).
	var image := Image.load_from_file(
		ProjectSettings.globalize_path(String(_objects["prop_vue_port_01"]["fichier"])))
	var last_row := image.get_height() - 1
	var opaque_last := 0
	var opaque_above := 0
	for x in image.get_width():
		if image.get_pixel(x, last_row).a > 0.5:
			opaque_last += 1
		if image.get_pixel(x, last_row - 12).a > 0.5:
			opaque_above += 1
	assert_gt(opaque_last, 0)
	assert_gt(float(opaque_last), 0.6 * float(opaque_above), "base tranchée net")


func test_grounds_are_384_squares() -> void:
	for id: String in GROUNDS:
		var size: Array = _images[id]["taille"]
		assert_eq(Vector2i(int(size[0]), int(size[1])), Vector2i(384, 384), id)


func test_ground_textures_wrap_without_a_seam() -> void:
	for id: String in GROUNDS:
		var image := Image.load_from_file(
			ProjectSettings.globalize_path(String(_images[id]["fichier"])))
		var edge := 0.0
		var neighbour := 0.0
		for y in range(0, 384, 3):
			edge += _distance(image.get_pixel(0, y), image.get_pixel(383, y))
			neighbour += _distance(image.get_pixel(150, y), image.get_pixel(151, y))
		# Les planches ont des joints marqués (rapport mesuré 3,2) ; une couture visible dépasse 5.
		assert_lt(edge / maxf(neighbour, 0.001), 5.0, "%s : couture" % id)


func test_furniture_and_props_have_scenes() -> void:
	for id: String in FURNITURE + SHIP + BUILDINGS.keys() + ["prop_indice_tronc_01",
			"prop_jeune_arbre_arene_01", "prop_grue_quai_01", "prop_stele_01"]:
		var packed := load("res://game/world/props/painted/%s.tscn" % id) as PackedScene
		assert_not_null(packed, id)
		if packed == null:
			continue
		var prop := packed.instantiate() as WorldProp
		add_child_autofree(prop)
		assert_eq(prop.footprint.is_empty(), PaintedPropRules.is_traversable(StringName(id)), id)


func test_young_tree_and_ship_are_separate_objects() -> void:
	# Contrat du J16 : l'arbuste (retirable) et chaque tranche sont des objets propres.
	for id: String in ["prop_jeune_arbre_arene_01", "bldg_arene_carmin_01"] + SHIP:
		assert_true(_objects.has(id), id)


func test_looks_have_frames_with_idle() -> void:
	for look: String in ["sailor", "docker", "fan_club_chairman"]:
		var path := "res://assets/sprites/characters/painted/%s_frames.tres" % look
		var frames := load(path) as SpriteFrames
		assert_not_null(frames, path)
		if frames == null:
			continue
		for animation: StringName in [&"idle_down", &"walk_down", &"walk_up", &"walk_left"]:
			assert_true(frames.has_animation(animation), "%s : %s" % [path, animation])


func test_bag_icons_are_256_squares() -> void:
	for id: String in ["super_potion", "full_restore"]:
		var image := Image.load_from_file(
			ProjectSettings.globalize_path("res://assets/ui/items/%s.webp" % id))
		assert_not_null(image, id)
		if image != null:
			assert_eq(image.get_size(), Vector2i(256, 256), id)


func test_battle_decor_is_declared_and_present() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/battle/decors.json"))
	var decor: Dictionary = data["decors"]["route_5_6_prairie"]
	assert_true(ResourceLoader.exists(decor["back"]))
	assert_eq(Vector2i(int(decor["size"][0]), int(decor["size"][1])), Vector2i(2340, 1080))


func _distance(a: Color, b: Color) -> float:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)
