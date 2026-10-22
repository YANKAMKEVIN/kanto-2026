extends GutTest
## Contrat des drapeaux du jalon 21 (T15, T23, `jalon-21.md` §2.14, §5 n° 13 ; dossier 24 §16) sur
## **toutes** les données qui posent des drapeaux (`data/cutscenes`, `data/dialogues`, `data/npcs`,
## `data/trainers`, `data/story`, `tools/debug_start`) :
## - toute donnée qui pose un drapeau du J21 est dans un **fichier du J21** ([constant J21_FILES])
##   ou dans le seul **bloc du J21** d'un fichier plus ancien : la variante A de `tower_6f_ghost`
##   (`pokemon_tower_floors.json`, révélation, `if_items: [silph_scope]`) ;
## - aucune donnée du J19 ni du J20 n'en pose (cette variante exceptée) ;
## - chaque drapeau du J21 est posé par au moins une donnée du J21 ;
## - les drapeaux d'un Ronflex ne sont posés que par les fichiers de ce Ronflex (§5 n° 12).
## Clés qui posent : « set », « win », « lose », « flee », « catch », « confirm_set »,
## « cancel_set », « flags » (départs), « flag » ; `beaten_<id>` du bloc `trainer` d'un PNJ.

const DIRS: Array[String] = [
	"res://data/cutscenes/", "res://data/dialogues/", "res://data/npcs/", "res://data/trainers/",
	"res://data/story/", "res://tools/debug_start/",
]
const SETTING_KEYS: Array[String] = ["set", "win", "lose", "flee", "catch", "confirm_set",
	"cancel_set", "flags", "flag"]
## Drapeaux du J21 (§2.14). `snorlax_route_12_seen` vient du J17 (T-6), repris par la Route 12 :
## il n'en fait pas partie.
const J21_FLAGS: Array[String] = [
	"ghost_marowak_calmed", "tower_6f_mist_lifted",
	"beaten_tower_rocket_1", "beaten_tower_rocket_2", "beaten_tower_rocket_3",
	"fuji_rescued", "got_poke_flute",
	"snorlax_route_12_awake", "snorlax_route_12_woken", "snorlax_route_12_caught",
	"snorlax_route_12_done",
	"snorlax_route_16_awake", "snorlax_route_16_woken", "snorlax_route_16_caught",
	"snorlax_route_16_done", "snorlax_route_16_seen",
	"got_tm39", "route_12_visited", "route_16_visited",
]
## Fichiers du J21 (données des T5, T12 à T14, T20 à T22 ; départs de débogage du plan §2.15).
const J21_FILES: Array[String] = [
	"res://data/cutscenes/j21_tower.json", "res://data/cutscenes/j21_snorlax.json",
	"res://data/cutscenes/j21_snorlax_16.json", "res://data/cutscenes/route_12.json",
	"res://data/dialogues/j21_tower.json", "res://data/dialogues/j21_snorlax.json",
	"res://data/dialogues/j21_snorlax_16.json",
	"res://data/npcs/pokemon_tower_7f.json", "res://data/trainers/pokemon_tower_7f.json",
	"res://tools/debug_start/tower_marowak_qa.json",
	"res://tools/debug_start/tower_marowak_noscope.json",
	"res://tools/debug_start/tower_marowak_weak.json", "res://tools/debug_start/tower_7f_qa.json",
	"res://tools/debug_start/fuji_flute_qa.json", "res://tools/debug_start/j21_full_qa.json",
	"res://tools/debug_start/route_12_qa.json", "res://tools/debug_start/snorlax_16_qa.json",
]
## Préfixes de fichiers du J21 (Route 12 et son poste, Route 16 : cartes nouvelles du J21).
const J21_PREFIXES: Array[String] = ["route_12", "route_16"]
## Le seul bloc du J21 permis dans un fichier plus ancien.
const BLOCK_FILE: String = "res://data/cutscenes/pokemon_tower_floors.json"
const BLOCK_SCENE: String = "tower_6f_ghost"
const BLOCK_FLAGS: Array[String] = ["ghost_marowak_calmed", "tower_6f_mist_lifted"]

## Fichier → drapeaux du J21 posés (« fichier → drapeau »).
var _set: Array[String] = []
## Drapeaux du J21 posés par la variante A du 6F.
var _block_set: Array[String] = []


func before_all() -> void:
	for dir: String in DIRS:
		for file: String in DirAccess.get_files_at(dir):
			if file.get_extension() != "json":
				continue
			var path := dir + file
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			assert_not_null(parsed, "lisible : %s" % path)
			if path == BLOCK_FILE:
				parsed = _split_block(parsed)
			_collect(parsed, path, _set)


## Retire la variante A (`if_items`) de `tower_6f_ghost` et range ses drapeaux à part.
func _split_block(parsed: Variant) -> Variant:
	var scene: Dictionary = (parsed as Dictionary).get(BLOCK_SCENE, {})
	var kept: Array = []
	var blocks := 0
	for variant: Variant in scene.get("variants", []):
		if variant is Dictionary and (variant as Dictionary).has("if_items"):
			blocks += 1
			var found: Array[String] = []
			_collect(variant, BLOCK_FILE, found)
			for entry: String in found:
				_block_set.append(entry.get_slice(" → ", 1))
		else:
			kept.append(variant)
	assert_eq(blocks, 1, "une seule variante A du J21 dans %s" % BLOCK_FILE.get_file())
	scene["variants"] = kept
	return parsed


func _strings(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is String:
		out.append(value)
	elif value is Array:
		for entry: Variant in value:
			if entry is String:
				out.append(entry)
	return out


func _collect(value: Variant, path: String, out: Array[String]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			if SETTING_KEYS.has(str(key)):
				for flag: String in _strings(value[key]):
					out.append("%s → %s" % [path, flag])
			if str(key) == "trainer" and value[key] is Dictionary:
				for id: String in _strings((value[key] as Dictionary).get("id")):
					out.append("%s → %s%s" % [path, TrainerRules.BEATEN_PREFIX, id])
			_collect(value[key], path, out)
	elif value is Array:
		for entry: Variant in value:
			_collect(entry, path, out)


func _is_j21_file(path: String) -> bool:
	if J21_FILES.has(path):
		return true
	var file := path.get_file()
	for prefix: String in J21_PREFIXES:
		if file.begins_with(prefix):
			return true
	return false


func test_the_jalon_21_files_are_all_there() -> void:
	for path: String in J21_FILES + [BLOCK_FILE]:
		assert_true(FileAccess.file_exists(path), path)


func test_only_jalon_21_data_sets_a_jalon_21_flag() -> void:
	assert_gt(_set.size(), 200, "les données sont bien lues")
	for entry: String in _set:
		var flag := entry.get_slice(" → ", 1)
		if not J21_FLAGS.has(flag):
			continue
		var path := entry.get_slice(" → ", 0)
		assert_true(_is_j21_file(path), "drapeau du J21 posé hors du J21 : %s" % entry)


func test_the_6f_variant_a_is_the_only_jalon_21_block_in_an_older_file() -> void:
	_block_set.sort()
	var expected := BLOCK_FLAGS.duplicate()
	expected.sort()
	assert_eq(_block_set, expected, "la variante A pose `ghost_marowak_calmed` et la brume")
	var scenes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BLOCK_FILE))
	var variants: Array = (scenes[BLOCK_SCENE] as Dictionary)["variants"]
	assert_eq(variants.size(), 2, "variante A (J21) en tête, variante du J19 ensuite")
	assert_eq((variants[0] as Dictionary).get("if_items"), ["silph_scope"])
	assert_false((variants[1] as Dictionary).has("if_items"), "le J19 reste tel quel")


func test_every_jalon_21_flag_is_set_by_jalon_21_data() -> void:
	var set_flags: Array[String] = _block_set.duplicate()
	for entry: String in _set:
		if _is_j21_file(entry.get_slice(" → ", 0)) \
				and not entry.get_slice(" → ", 0).begins_with("res://tools/debug_start/"):
			set_flags.append(entry.get_slice(" → ", 1))
	for flag: String in J21_FLAGS:
		assert_has(set_flags, flag, "%s posé par une donnée du J21" % flag)


func test_each_snorlax_sets_only_its_own_flags() -> void:
	for entry: String in _set:
		var path := entry.get_slice(" → ", 0)
		var flag := entry.get_slice(" → ", 1)
		if path.ends_with("j21_snorlax.json"):
			assert_false(flag.begins_with("snorlax_route_16"), "Ronflex 12 : %s" % entry)
		elif path.ends_with("j21_snorlax_16.json"):
			assert_false(flag.begins_with("snorlax_route_12"), "Ronflex 16 : %s" % entry)
