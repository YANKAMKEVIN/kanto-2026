extends GutTest
## DAF.5, 2e partie (`tools/art/daf5_reliquats.py`) : série 25 intégrée (héros à vélo et qui pêche,
## Motard, Ornithologue, Loubard, deux frères pêcheurs, Kangourex et Ramoloss de l'enclos de
## Parmanie) et Chenipan d'ambiance de la Forêt de Jade.

const CATALOGUE := "res://assets/world/catalogue.json"
const CHARACTERS := "res://assets/sprites/characters/painted/"
const POKEMON := "res://assets/sprites/pokemon/painted/"
const DIRS: Array[String] = ["down", "left", "right", "up"]
## Planche du catalogue → identifiant de données (`<id>_frames.tres`).
const LOOKS: Dictionary = {
	"motard": "biker", "ornithologue": "bird_keeper", "loubard": "cue_ball",
	"pecheur_parmanie": "fisher_fuchsia", "pecheur_route_12": "fisher_route_12",
}
const FIXED: Dictionary = {"kangourex": "kangaskhan", "ramoloss": "slowpoke", "chenipan": "caterpie"}
## Classe (début du nom du Dresseur) → apparence peinte.
const CLASS_LOOKS: Dictionary = {"Motard": "biker", "Ornithologue": "bird_keeper", "Loubard": "cue_ball"}

var _catalogue: Dictionary = {}


func before_all() -> void:
	_catalogue = JSON.parse_string(FileAccess.get_file_as_string(CATALOGUE))


func test_walking_sheets_are_whole_grids_with_an_idle_sheet() -> void:
	for id: String in LOOKS.keys() + ["heros_bike"]:
		var sheet: Dictionary = _catalogue["personnages"][id]
		var texture := load(sheet["fichier"]) as Texture2D
		var cell: Array = sheet["cellule"]
		assert_eq(texture.get_width(), int(cell[0]) * 4, "%s : 4 colonnes" % id)
		assert_eq(texture.get_height(), int(cell[1]) * 4, "%s : 4 lignes" % id)
		var idle: Dictionary = _catalogue["personnages"][id + "_idle"]
		assert_eq(int(idle["cellule"][1]), int(cell[1]), "%s : attente au même ancrage" % id)


func test_trainer_frames_have_walk_and_idle() -> void:
	for id: String in LOOKS:
		var frames := load("%s%s_frames.tres" % [CHARACTERS, LOOKS[id]]) as SpriteFrames
		assert_not_null(frames, LOOKS[id])
		for dir: String in DIRS:
			assert_true(frames.has_animation(StringName("idle_" + dir)), "%s idle_%s" % [id, dir])
			assert_eq(frames.get_frame_count(StringName("walk_" + dir)), 4, "%s walk_%s" % [id, dir])


func test_player_rides_and_fishes_with_painted_frames() -> void:
	var frames := load(CHARACTERS + "player_frames.tres") as SpriteFrames
	var walk_h := frames.get_frame_texture(&"idle_down", 0).get_height()
	for dir: String in DIRS:
		assert_eq(frames.get_frame_count(StringName("bike_walk_" + dir)), 4, "bike_walk_" + dir)
		assert_eq(frames.get_frame_count(StringName("bike_idle_" + dir)), 1, "bike_idle_" + dir)
		assert_eq(frames.get_frame_texture(StringName("bike_walk_" + dir), 0).get_height(), walk_h,
			"vélo : même ancrage que la marche")
		for pose: String in ["fish_cast_", "fish_wait_"]:
			var anim := StringName(pose + dir)
			assert_eq(frames.get_frame_count(anim), 1, String(anim))
			# Cellule plus haute (la canne), centrée : hauteur paire, au moins celle de la marche.
			var h := frames.get_frame_texture(anim, 0).get_height()
			assert_true(h >= walk_h and (h - walk_h) % 2 == 0, "%s : %d px centrés" % [anim, h])


func test_fixed_pokemon_frames_react() -> void:
	for id: String in FIXED:
		var frames := load("%s%s_frames.tres" % [POKEMON, FIXED[id]]) as SpriteFrames
		assert_not_null(frames, FIXED[id])
		for dir: String in DIRS:
			assert_true(frames.has_animation(StringName("react_" + dir)), "%s react_%s" % [id, dir])


func test_trainer_classes_use_their_painted_looks() -> void:
	var names := {}
	for file: String in DirAccess.get_files_at("res://data/trainers"):
		var trainers: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/trainers/" + file))
		for id: String in trainers:
			if trainers[id] is Dictionary and trainers[id].has("name"):
				names[id] = String(trainers[id]["name"])
	var seen := 0
	for file: String in DirAccess.get_files_at("res://data/npcs"):
		var npcs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/npcs/" + file))
		for key: String in npcs:
			var trainer: Variant = npcs[key].get("trainer") if npcs[key] is Dictionary else null
			var tid: String = String(trainer["id"]) if trainer is Dictionary else ""
			var trainer_class: String = String(names.get(tid, "")).get_slice(" ", 0)
			if CLASS_LOOKS.has(trainer_class):
				seen += 1
				assert_eq(npcs[key]["sprite"], CLASS_LOOKS[trainer_class], "%s/%s" % [file, key])
	assert_gt(seen, 20, "Motards, Ornithologues, Loubards des Routes 13 à 20")


func test_rod_brothers_and_fuchsia_pens() -> void:
	var good: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/npcs/fuchsia_good_rod_house.json"))
	assert_eq(good["fisher"]["sprite"], "fisher_fuchsia")
	var super_rod: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/npcs/route_12_rod_house.json"))
	assert_eq(super_rod["fisher"]["sprite"], "fisher_route_12")
	var fuchsia: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/npcs/fuchsia_city.json"))
	assert_eq(fuchsia["enclos_kangourex"]["sprite"], "pokemon/kangaskhan")
	assert_eq(fuchsia["enclos_ramoloss"]["sprite"], "pokemon/slowpoke")
	for id: String in ["kangaskhan", "slowpoke", "caterpie"]:
		assert_true(CharacterLook.resolve(StringName("pokemon/" + id)).painted, id + " peint")
