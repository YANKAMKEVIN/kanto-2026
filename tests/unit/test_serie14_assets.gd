extends GutTest
## Série 14 (J12 T6, `docs/design/fiches-assets/serie-14-mont-selenite.md`) : assets de la
## Route 3 et du Mont Sélénite préparés à l'échelle du jeu, règles d'emprise, apparences des
## quatre personnages, fossiles en objets fixes, textures de sol de la grotte, icônes du Sac.
## Aucune carte (T8, T9).

const CATALOGUE := "res://assets/world/catalogue.json"
const SCENES := "res://game/world/props/painted/"
const FRAMES_TOOL := "res://tools/build_character_frames.gd"
const CAVE_KIT := "res://tools/cave_map_kit.gd"
## Objets peints de la série 14 → largeur en cases (fiche).
const WIDTHS: Dictionary = {
	"relief_entree_grotte_01": 4, "prop_mare_grotte_01": 4, "decal_puits_jour_01": 4,
	"relief_paroi_grotte_01": 3, "relief_paroi_grotte_02": 3, "relief_paroi_grotte_03": 2,
	"relief_paroi_grotte_04": 2, "relief_paroi_grotte_05": 1, "relief_paroi_grotte_06": 3,
	"prop_colonne_grotte_01": 2, "prop_colonne_grotte_02": 1, "prop_rocher_grotte_01": 1,
	"prop_rocher_grotte_02": 1, "prop_eclats_lune_01": 1, "prop_eclats_lune_02": 1,
	"prop_lampe_chantier_01": 1, "prop_caisse_r_01": 1, "prop_caisse_r_02": 2,
	"prop_tranchee_01": 3, "prop_projecteur_01": 1, "prop_outils_fouille_01": 1,
	"prop_echelle_descend_01": 1, "prop_echelle_monte_01": 1, "prop_dalle_01": 3,
}
const ARDOISE: Array[String] = ["relief_paroi_ardoise_01", "relief_paroi_ardoise_02",
	"relief_paroi_ardoise_03", "relief_paroi_ardoise_04"]
const GROUNDS: Array[String] = ["ground_roche_01", "ground_grotte_01", "ground_gravats_01",
	"ground_masse_roche_01"]
## Apparence → [planche, hauteur de fiche].
const PEOPLE: Dictionary = {
	&"lass_young": ["fillette", 108], &"rocket_grunt_m": ["sbire_h", 128],
	&"rocket_grunt_f": ["sbire_f", 124], &"fossil_researcher": ["chercheur_fossiles", 128],
}
const ICONS: Array[String] = ["moon_stone", "escape_rope", "dome_fossil", "helix_fossil"]

var _objects: Dictionary = {}
var _images: Dictionary = {}
var _sheets: Dictionary = {}


func before_all() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	_objects = catalogue["objets"]
	_images = catalogue["images"]
	_sheets = catalogue["personnages"]


func test_props_are_prepared_at_their_width_without_shadow() -> void:
	for id: String in WIDTHS:
		assert_true(_objects.has(id), "%s au catalogue" % id)
		if not _objects.has(id):
			continue
		assert_eq(int(_objects[id]["taille"][0]), int(WIDTHS[id]) * Grid.TILE_SIZE, id)
		assert_false(_objects[id].has("ombre"), "%s : aucune ombre portée" % id)
		assert_false(PaintedPropRules.casts_shadows(StringName(id)), id)
		assert_true(ResourceLoader.exists(SCENES + id + ".tscn"), "%s a sa scène" % id)
	for id: String in ARDOISE:
		assert_eq(int(_objects[id]["taille"][1]), 288, "%s : 3 cases de haut" % id)
		assert_true(PaintedPropRules.is_traversable(StringName(id)), "%s : la carte bloque" % id)
		assert_eq(PaintedPropRules.layer(StringName(id)), PaintedPropRules.LAYER_GROUND, id)
	# Indices discrets et fossiles : plus petits qu'une case.
	for id: String in ["prop_indice_caillou_01", "prop_indice_eclat_01", "prop_fossile_dome_01",
			"prop_fossile_nautile_01"]:
		assert_lt(int(_objects[id]["taille"][0]), Grid.TILE_SIZE, id)


func test_footprints_of_the_cave_kit() -> void:
	# Entrée 4 × 3 : les deux cases de l'ouverture (bas, au milieu) restent libres.
	var entrance := PaintedPropRules.footprint(&"relief_entree_grotte_01")
	assert_eq(entrance.size(), 4 * 3 - 2)
	assert_eq(PaintedPropRules.open_cells(&"relief_entree_grotte_01"),
		[Vector2i(-1, 0), Vector2i(0, 0)])
	for cell: Vector2i in [Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -2), Vector2i(1, -2)]:
		assert_true(entrance.has(cell), "bord de l'entrée %s" % cell)
	assert_eq(PaintedPropRules.footprint(&"prop_colonne_grotte_01").size(), 6)
	assert_eq(PaintedPropRules.footprint(&"prop_tranchee_01").size(), 9)
	assert_eq(PaintedPropRules.layer(&"prop_tranchee_01"), PaintedPropRules.LAYER_GROUND)
	assert_eq(PaintedPropRules.footprint(&"prop_dalle_01"),
		[Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0)])
	assert_eq(PaintedPropRules.footprint(&"prop_caisse_r_02"), [Vector2i(-1, 0), Vector2i(0, 0)])
	# Échelles : warps « en marchant dessus », jamais devant le personnage.
	for id: StringName in [&"prop_echelle_descend_01", &"prop_echelle_monte_01"]:
		assert_true(PaintedPropRules.is_traversable(id), String(id))
		assert_eq(PaintedPropRules.layer(id), PaintedPropRules.LAYER_GROUND, String(id))
	# Parois de grotte : triées au pied avec les personnages, cases bloquées par la carte.
	for i in range(1, 7):
		var id := StringName("relief_paroi_grotte_0%d" % i)
		assert_true(PaintedPropRules.is_traversable(id), String(id))
		assert_eq(PaintedPropRules.layer(id), PaintedPropRules.LAYER_ENTITIES, String(id))


func test_daylight_well_is_soft_and_half_transparent() -> void:
	var image := (load("res://assets/world/ground/decals/decal_puits_jour_01.png")
		as Texture2D).get_image()
	var max_alpha := 0.0
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			max_alpha = maxf(max_alpha, image.get_pixel(x, y).a)
	# Alpha × 0,55 (≈ 0,98 à la génération) : jamais plus de 0,6 au centre.
	assert_between(max_alpha, 0.4, 0.6, "alpha du puits")
	# Bordure floutée : rien d'opaque sur le pourtour.
	var edge := 0.0
	var last_x := image.get_width() - 1
	var last_y := image.get_height() - 1
	for x in image.get_width():
		edge = maxf(edge, maxf(image.get_pixel(x, 0).a, image.get_pixel(x, last_y).a))
	for y in image.get_height():
		edge = maxf(edge, maxf(image.get_pixel(0, y).a, image.get_pixel(last_x, y).a))
	assert_lt(edge, 0.15, "bord du puits fondu")
	assert_false(PaintedPropRules.uses_material(&"decal_puits_jour_01"), "lumière sans liseré")


func test_ground_textures_tile_on_their_four_edges() -> void:
	for id: String in GROUNDS:
		assert_true(_images.has(id), "%s au catalogue" % id)
		var path := "res://assets/world/ground/%s.png" % id
		var texture := load(path) as Texture2D
		assert_not_null(texture, id)
		if texture == null:
			continue
		assert_eq(texture.get_size(), Vector2(384, 384), "%s : 4 × 4 cases" % id)
		assert_true(FileAccess.get_file_as_string(path + ".import").contains(
			"mipmaps/generate=true"), "%s : mipmaps (sol répété)" % id)
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		assert_lt(_edge_gap(image, true), 8.0 / 255.0, "%s : raccord gauche / droite" % id)
		assert_lt(_edge_gap(image, false), 8.0 / 255.0, "%s : raccord haut / bas" % id)


func test_cave_kit_textures_exist_and_share_a_size() -> void:
	var constants := (load(CAVE_KIT) as Script).get_script_constant_map()
	var size := Vector2.ZERO
	for key: String in ["FLOOR_TEXTURE", "RUBBLE_TEXTURE", "MASS_TEXTURE"]:
		var texture := load(String(constants[key])) as Texture2D
		assert_not_null(texture, key)
		if texture == null:
			continue
		if size == Vector2.ZERO:
			size = texture.get_size()
		assert_eq(texture.get_size(), size, "%s : même taille (texture_size du shader)" % key)


func test_people_are_painted_with_their_idle_sheet() -> void:
	var looks: Dictionary = (load(FRAMES_TOOL) as Script).get_script_constant_map()["LOOKS"]
	for sprite: StringName in PEOPLE:
		var sheet: String = PEOPLE[sprite][0]
		assert_eq(String(looks[sheet][1]), String(sprite), "%s → %s" % [sheet, sprite])
		var look := CharacterLook.resolve(sprite)
		assert_true(look.painted, String(sprite))
		assert_eq(look.filter, CanvasItem.TEXTURE_FILTER_LINEAR)
		var frames := load(look.frames_path) as SpriteFrames
		assert_not_null(frames, String(sprite))
		if frames == null:
			continue
		var height: int = PEOPLE[sprite][1]
		for dir: String in ["down", "left", "right", "up"]:
			var idle := frames.get_frame_texture(StringName("idle_" + dir), 0) as AtlasTexture
			assert_eq(idle.atlas.resource_path, CharacterLook.PAINTED_DIR + sheet
				+ "_idle_sheet.png", "%s : attente %s" % [sprite, dir])
			var walk := frames.get_frame_texture(StringName("walk_" + dir), 0) as AtlasTexture
			assert_between(walk.get_size().y, float(height), float(height) + 4.0,
				"%s : hauteur de fiche" % sprite)
			# Même hauteur de cellule : même ancrage aux pieds à l'arrêt et en marche.
			assert_eq(idle.get_size().y, walk.get_size().y, "%s : cellule %s" % [sprite, dir])
			assert_false(frames.has_animation(StringName("run_" + dir)), "%s marche" % sprite)


func test_digging_grunt_is_lower_than_standing_and_on_her_feet() -> void:
	var frames := load(CharacterLook.painted_frames_path(&"rocket_grunt_f")) as SpriteFrames
	var walk := frames.get_frame_texture(&"walk_down", 3) as AtlasTexture
	var standing := _used_height(walk)
	for dir: String in ["down", "left", "right", "up"]:
		var idle := frames.get_frame_texture(StringName("idle_" + dir), 0) as AtlasTexture
		var used := _used_rect(idle)
		assert_between(float(used.size.y) / standing, 0.65, 0.85, "accroupie %s" % dir)
		assert_gte(used.end.y, int(idle.get_size().y) - 2, "pieds au bas de la cellule %s" % dir)


func test_fossils_are_fixed_objects() -> void:
	var objects: Dictionary = (load(FRAMES_TOOL) as Script).get_script_constant_map()[
		"FIXED_OBJECTS"]
	for id: String in ["fossil_dome", "fossil_helix"]:
		assert_eq(objects.get(id), id)
		assert_true(_images.has(id), "%s au catalogue" % id)
		var look := CharacterLook.resolve(StringName("object/" + id))
		assert_true(look.painted, id)
		var frames := load(look.frames_path) as SpriteFrames
		assert_not_null(frames, id)
		if frames == null:
			continue
		var texture := frames.get_frame_texture(&"idle_down", 0)
		assert_lt(texture.get_width(), Grid.TILE_SIZE, "%s : posé sur la dalle" % id)
		assert_false(frames.has_animation(&"walk_down"), "objet immobile")


func test_bag_icons_of_the_series() -> void:
	for id: String in ICONS:
		var texture := load("res://assets/ui/items/%s.webp" % id) as Texture2D
		assert_not_null(texture, id)
		if texture != null:
			assert_eq(texture.get_size(), Vector2(256, 256), id)


## Plus grand écart moyen (par bloc de 16 px, RVB) entre deux bords opposés.
func _edge_gap(image: Image, horizontal: bool) -> float:
	var size := image.get_width()
	var worst := 0.0
	for start in range(0, size, 16):
		var sum := Vector3.ZERO
		for i in range(start, start + 16):
			var a := image.get_pixel(0, i) if horizontal else image.get_pixel(i, 0)
			var b := image.get_pixel(size - 1, i) if horizontal else image.get_pixel(i, size - 1)
			sum += Vector3(a.r - b.r, a.g - b.g, a.b - b.b)
		sum /= 16.0
		worst = maxf(worst, maxf(absf(sum.x), maxf(absf(sum.y), absf(sum.z))))
	return worst


func _used_rect(atlas: AtlasTexture) -> Rect2i:
	var image := atlas.atlas.get_image()
	if image.is_compressed():
		image.decompress()
	return image.get_region(Rect2i(atlas.region)).get_used_rect()


func _used_height(atlas: AtlasTexture) -> float:
	return float(_used_rect(atlas).size.y)
