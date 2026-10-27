extends GutTest
## Série 23 intégrée (J21 T7, fiche `serie-23-repos-des-esprits.md`) : M. Fuji (marche et prière),
## Osselait du monde, dos de Ronflex, notes de la Poké Flûte, halo de l'esprit, icône de la Flûte.

const CATALOGUE := "res://assets/world/catalogue.json"

var _sheets: Dictionary = {}
var _images: Dictionary = {}


func before_all() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	_sheets = catalogue["personnages"]
	_images = catalogue["images"]


func test_fuji_walks_and_prays_in_the_same_cell_height() -> void:
	var walk: Dictionary = _sheets["fuji"]
	var pray: Dictionary = _sheets["fuji_priere"]
	assert_eq([int(walk["colonnes"]), int(walk["lignes"])], [4, 4])
	assert_eq([int(pray["colonnes"]), int(pray["lignes"])], [4, 1])
	assert_eq(int(pray["cellule"][1]), int(walk["cellule"][1]), "même hauteur de cellule (ancrage aux pieds)")
	assert_eq(pray["ordre_colonnes"], ["dos", "dos_souffle", "gauche", "face"])


func test_mr_fuji_frames_have_walk_idle_and_pray() -> void:
	var frames := load("res://assets/sprites/characters/painted/mr_fuji_frames.tres") as SpriteFrames
	assert_not_null(frames)
	for dir: String in ["down", "left", "right", "up"]:
		assert_true(frames.has_animation("idle_" + dir), "idle_" + dir)
		assert_eq(frames.get_frame_count("walk_" + dir), 4, "walk_" + dir)
	assert_eq(frames.get_frame_count(&"pray"), 2, "deux images de dos (souffle)")
	assert_true(frames.get_animation_loop(&"pray"))
	assert_lt(frames.get_animation_speed(&"pray"), 1.0, "boucle lente")
	assert_eq(frames.get_frame_count(&"pray_left"), 1)
	assert_eq(frames.get_frame_count(&"pray_front"), 1)
	assert_false(frames.has_animation(&"run_down"), "il ne court pas")


func test_osselait_is_a_small_world_pokemon() -> void:
	var sheet: Dictionary = _sheets["osselait"]
	assert_eq(int(sheet["hauteur"]), 56)
	assert_lte(int(sheet["cellule"][1]), 64)
	var frames := load("res://assets/sprites/pokemon/painted/cubone_frames.tres") as SpriteFrames
	assert_not_null(frames)
	assert_true(frames.has_animation(&"idle_down"))
	assert_true(frames.has_animation(&"walk_left"))


func test_ronflex_back_is_a_battle_back_sized_like_the_others() -> void:
	var back := load("res://assets/sprites/pokemon/battle_proto/dos_ia_143.png") as Texture2D
	assert_not_null(back)
	var image := back.get_image()
	assert_eq(image.get_size(), Vector2i(1024, 1024))
	var box := image.get_used_rect()
	assert_between(box.size.y, 880, 910, "sujet ≈ 88 % de la hauteur")
	assert_between(box.position.y + box.size.y, 955, 965, "bas du sujet comme les autres dos")


func test_flute_notes_and_halo() -> void:
	for i in range(1, 5):
		var entry: Dictionary = _images["poke_flute_note_%d" % i]
		assert_eq(int(entry["taille"][1]), 120, "note %d : 1,25 case de haut" % i)
		assert_not_null(load(entry["fichier"]) as Texture2D)
	var halo: Dictionary = _images["spirit_halo"]
	assert_eq([int(halo["taille"][0]), int(halo["taille"][1])], [192, 192])
	var image := (load(halo["fichier"]) as Texture2D).get_image()
	assert_lt(image.get_pixel(0, 96).a, 0.2, "bord du halo fondu")
	assert_gt(image.get_pixel(96, 96).a, 0.5, "cœur du halo")


func test_poke_flute_icon_is_picked_by_the_bag() -> void:
	var icon := BagEntryView.icon_for(&"poke_flute")
	assert_not_null(icon)
	assert_ne(icon, BagEntryView.GENERIC_ICON, "icône propre, pas l'illustration neutre")
	# DAF.5 : l'icône peinte du Sac passe avant le pictogramme vectoriel de la série 23.
	assert_eq(icon.resource_path, "res://assets/ui/items/poke_flute.webp")
