extends GutTest
## Série 27 intégrée (J24 T5, fiche `serie-27-iles-ecume.md`) : planches de personnages et leurs
## `SpriteFrames`, Artikodin du monde, accessoires de Force, sols, coques du Labo de Cramois'Île,
## fonds de combat (non associés à une carte) et dos provisoires 144 / 140 / 138.

const CATALOGUE := "res://assets/world/catalogue.json"
const CHARACTERS := "res://assets/sprites/characters/painted/"
const TILE := 96
## Planche du catalogue → identifiant de données (`<id>_frames.tres`).
const SHEETS: Dictionary = {
	"topdresseur": "cooltrainer_m", "topdresseuse": "cooltrainer_f",
	"nageur_eau": "swimmer_water", "nageuse_eau": "swimmer_f_water",
	"heros_surf": "player_surf", "surf_monture": "surf_mount",
}
const ACCESSORIES: Dictionary = {
	"prop_rocher_force_01": 96, "prop_rocher_force_eau_01": 104,
	"decal_trou_force_01": 96, "decal_trou_force_bouche_01": 96,
}
const GROUNDS: Array[String] = ["ground_courant_01", "ground_eau_grotte_01", "ground_glace_01"]
const SHELLS: Dictionary = {
	"int_labo_cramois_hall_coque": Vector2i(27, 12),
	"int_labo_cramois_rd_coque": Vector2i(15, 10),
	"int_labo_cramois_fossiles_coque": Vector2i(15, 10),
	"int_labo_cramois_reunion_coque": Vector2i(15, 10),
}
const BACKS: Array[int] = [144, 140, 138]

var _catalogue: Dictionary = {}


func before_all() -> void:
	_catalogue = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))


func test_sheets_are_whole_grids_of_one_cell() -> void:
	for id: String in SHEETS:
		var sheet: Dictionary = _catalogue["personnages"][id]
		var texture := load(sheet["fichier"]) as Texture2D
		assert_not_null(texture, id)
		var cell: Array = sheet["cellule"]
		assert_eq(texture.get_width(), int(cell[0]) * 4, "%s : 4 colonnes" % id)
		assert_eq(texture.get_height(), int(cell[1]) * 4, "%s : 4 lignes" % id)


func test_walking_trainers_are_hero_sized() -> void:
	for id: String in ["topdresseur", "topdresseuse"]:
		var cell: Array = _catalogue["personnages"][id]["cellule"]
		assert_eq(int(cell[1]), 130, "%s : 128 px + 2" % id)


func test_sheets_have_no_alpha_halo() -> void:
	# Halo alpha de la génération (1 à 60) coupé à la préparation : pas plus de pixels très
	# transparents que sur une planche de la série précédente (bords adoucis seulement).
	var reference := _faint_ratio("res://assets/sprites/characters/painted/nageur_sheet.png")
	for id: String in SHEETS:
		var ratio := _faint_ratio(_catalogue["personnages"][id]["fichier"])
		assert_lt(ratio, reference + 0.08, "%s : halo coupé (%.3f, réf. %.3f)" % [id, ratio, reference])


func _faint_ratio(path: String) -> float:
	var image := (load(path) as Texture2D).get_image()
	var faint := 0
	var seen := 0
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var a := image.get_pixel(x, y).a
			if a > 0.0:
				seen += 1
				if a < 0.25:
					faint += 1
	return float(faint) / maxf(seen, 1.0)


func test_frames_resources_load_with_four_directions() -> void:
	for id: String in SHEETS:
		var frames := load("%s%s_frames.tres" % [CHARACTERS, SHEETS[id]]) as SpriteFrames
		assert_not_null(frames, SHEETS[id])
		if frames == null:
			continue
		for dir: String in ["down", "left", "right", "up"]:
			assert_true(frames.has_animation(StringName("idle_" + dir)), "%s idle_%s" % [id, dir])
			assert_eq(frames.get_frame_count(StringName("walk_" + dir)), 4, "%s walk_%s" % [id, dir])


func test_artikodin_loops_four_frames() -> void:
	var sheet: Dictionary = _catalogue["personnages"]["artikodin"]
	assert_eq(int(sheet["colonnes"]), 4)
	assert_eq(int(sheet["lignes"]), 1)
	assert_between(int(sheet["cellule"][1]), 163, 175, "≈ 163 px de haut")
	var frames := load("res://assets/sprites/pokemon/painted/articuno_frames.tres") as SpriteFrames
	assert_not_null(frames)
	for anim: StringName in [&"idle", &"idle_down", &"idle_left"]:
		assert_eq(frames.get_frame_count(anim), 4, String(anim))
		assert_true(frames.get_animation_loop(anim), String(anim))


func test_force_accessories_sizes() -> void:
	for id: String in ACCESSORIES:
		var entry: Dictionary = _catalogue["images"][id]
		assert_true(ResourceLoader.exists(entry["fichier"]), id)
		assert_eq(int(entry["taille"][0]), int(ACCESSORIES[id]), "%s : largeur" % id)
	assert_false(_catalogue["objets"].has("prop_rocher_force_01"),
		"image seule : pas d'objet (règle d'emprise au T7)")


func test_grounds_are_384_tiles() -> void:
	for id: String in GROUNDS:
		var entry: Dictionary = _catalogue["images"][id]
		assert_eq(Vector2i(int(entry["taille"][0]), int(entry["taille"][1])), Vector2i(384, 384), id)
		assert_true(ResourceLoader.exists(entry["fichier"]), id)


func test_labo_shells_match_their_grid() -> void:
	for id: String in SHELLS:
		var size: Array = _catalogue["images"][id]["taille"]
		assert_eq(Vector2i(int(size[0]), int(size[1])), SHELLS[id] * TILE, id)


func test_combat_backs_exist_but_are_not_placed() -> void:
	var catalog := BattleDecorCatalog.load_file()
	for id: StringName in [&"sea_open", &"seafoam_ice"]:
		assert_has(catalog.get_ids(), id)
		var decor := catalog.get_decor(id)
		assert_true(decor.is_valid(), String(id))
		assert_eq((load(decor.back_path) as Texture2D).get_size(), Vector2(2340, 1080), String(id))
	for map_id: StringName in catalog.get_maps():
		for id: StringName in [&"sea_open", &"seafoam_ice"]:
			assert_ne(catalog.default_for(map_id).id if catalog.default_for(map_id) != null
				else &"", id, "%s : pas encore associé à une carte" % map_id)


func test_provisional_backs_for_144_140_138() -> void:
	for number: int in BACKS:
		var path := "res://assets/sprites/pokemon/battle_proto/dos_ia_%d.png" % number
		var texture := load(path) as Texture2D
		assert_not_null(texture, path)
		assert_eq(texture.get_size(), Vector2(1024, 1024), path)
	# BattleArt : ces trois espèces ont déjà leur dos provisoire (jamais de côté vide).
	var art := BattleArt.new()
	for species: StringName in [&"articuno", &"kabuto", &"omanyte"]:
		assert_true(ResourceLoader.exists(BattleArt.placeholder_path(species, true)),
			"dos provisoire de %s" % species)
		assert_not_null(art.image(species, true)["texture"], String(species))
