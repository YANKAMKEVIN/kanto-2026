extends GutTest
## Série 22 intégrée (J20 T10, fiche `serie-22-celadopole.md`) : six personnages, neuf dos de
## combat, trois décors de combat.

const CATALOGUE := "res://assets/world/catalogue.json"
const LOOKS: Dictionary = {
	"erika": "erika", "giovanni": "giovanni", "rocket_civil": "rocket_civilian",
	"intello": "nerd", "beaute": "beauty", "topdresseuse": "cooltrainer_f",
}
const BACKS: Array[String] = [
	"133", "058", "037", "071", "045", "104", "059", "038", "134"]
const DECORS: Dictionary = {
	"route_7_8_urbaine": ["route_7", "route_8"],
	"celadon_gym_serre": ["celadon_gym"],
	"rocket_hideout_repaire": [
		"celadon_game_corner", "rocket_hideout_b1f", "rocket_hideout_b2f",
		"rocket_hideout_b3f", "rocket_hideout_b4f"],
}


func test_characters_have_walk_idle_and_frames() -> void:
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))
	for sheet: String in LOOKS:
		assert_true(catalogue["personnages"].has(sheet), "%s : marche" % sheet)
		assert_true(catalogue["personnages"].has(sheet + "_idle"), "%s : attente" % sheet)
		var path := "res://assets/sprites/characters/painted/%s_frames.tres" % LOOKS[sheet]
		assert_true(ResourceLoader.exists(path), path)
		var frames := load(path) as SpriteFrames
		assert_true(frames.has_animation(&"idle_down"), "%s : idle_down" % sheet)
		assert_true(frames.has_animation(&"walk_up"), "%s : walk_up" % sheet)


func test_battle_backs_exist() -> void:
	for number in BACKS:
		var path := "res://assets/sprites/pokemon/battle_proto/dos_ia_%s.png" % number
		assert_true(ResourceLoader.exists(path), path)


func test_combat_decors_are_wired_to_their_places() -> void:
	var catalog := BattleDecorCatalog.load_file()
	for id: String in DECORS:
		var decor := catalog.get_decor(StringName(id))
		assert_not_null(decor, id)
		assert_true(decor.is_valid(), id)
		for map_id: String in DECORS[id]:
			assert_eq(catalog.default_for(StringName(map_id)).back_path, decor.back_path, map_id)
