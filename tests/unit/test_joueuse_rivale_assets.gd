extends GutTest
## Chantier JR (`docs/design/dossier-joueuse-rivale.md`) : la joueuse et la rivale ont les mêmes
## animations que leurs homologues (héros, rival), à la même hauteur, et leurs images fixes
## (lancer de combat, portraits, buste du menu) existent au format des images du héros.

const CATALOGUE := "res://assets/world/catalogue.json"
const CHARACTERS := "res://assets/sprites/characters/painted/"
## Apparence nouvelle → apparence homologue (`<id>_frames.tres`).
const LOOKS: Dictionary = {
	"player_heroine": "player",
	"player_heroine_surf": "player_surf",
	"rival_heroine": "rival",
}
## Planche du catalogue → planche homologue.
const SHEETS: Dictionary = {
	"joueuse": "heros", "joueuse_run": "heros_run", "joueuse_idle": "heros_idle",
	"joueuse_bike": "heros_bike", "joueuse_bike_idle": "heros_bike_idle",
	"joueuse_fish_cast": "heros_fish_cast", "joueuse_fish_wait": "heros_fish_wait",
	"joueuse_surf": "heros_surf", "rivale": "rival", "rivale_idle": "rival_idle",
}
## Image fixe → hauteur de l'image homologue.
const IMAGES: Dictionary = {
	"joueuse_lancer.png": "heros_lancer.png",
	"joueuse_portrait.png": "heros_portrait.png",
	"rivale_portrait.png": "rival_portrait.png",
}

var _catalogue: Dictionary = {}


func before_all() -> void:
	_catalogue = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))


func _animations(look: String) -> Array:
	var frames := load(CHARACTERS + look + "_frames.tres") as SpriteFrames
	assert_not_null(frames, look)
	if frames == null:
		return []
	var names: Array = []
	for animation: StringName in frames.get_animation_names():
		names.append([String(animation), frames.get_frame_count(animation)])
	names.sort()
	return names


func test_looks_have_the_animations_of_their_counterpart() -> void:
	for look: String in LOOKS:
		var own := _animations(look)
		assert_gt(own.size(), 0, look)
		assert_eq(own, _animations(LOOKS[look]), "%s : animations de %s" % [look, LOOKS[look]])


func test_sheets_match_their_counterpart_layout_and_height() -> void:
	for id: String in SHEETS:
		var sheet: Dictionary = _catalogue["personnages"][id]
		var other: Dictionary = _catalogue["personnages"][SHEETS[id]]
		assert_eq(sheet["hauteur"], other["hauteur"], "%s : hauteur" % id)
		assert_eq(sheet.get("lignes"), other.get("lignes"), "%s : lignes" % id)
		assert_eq(sheet.get("colonnes"), other.get("colonnes"), "%s : colonnes" % id)
		var texture := load(sheet["fichier"]) as Texture2D
		assert_not_null(texture, id)
		var cell: Array = sheet["cellule"]
		assert_eq(texture.get_width(), int(cell[0]) * int(sheet["colonnes"]), "%s : largeur" % id)
		assert_eq(texture.get_height(), int(cell[1]) * int(sheet["lignes"]), "%s : hauteur" % id)


func test_still_images_have_the_height_of_their_counterpart() -> void:
	for image: String in IMAGES:
		var own := load(CHARACTERS + image) as Texture2D
		var other := load(CHARACTERS + IMAGES[image]) as Texture2D
		assert_not_null(own, image)
		assert_eq(own.get_height(), other.get_height(), image)


func test_heroine_menu_bust_exists() -> void:
	var bust := load("res://assets/ui/menu/heroine_bust.webp") as Texture2D
	var hero := load("res://assets/ui/menu/hero_bust.webp") as Texture2D
	assert_not_null(bust)
	assert_eq(bust.get_height(), hero.get_height())
