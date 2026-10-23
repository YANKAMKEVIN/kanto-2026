extends GutTest
## Contrat des drapeaux du jalon 19 (T22, `jalon-19.md` §2.13 ; dossier 22 §16 n° 1 et 12) sur
## **toutes les données ajoutées ou touchées par le J19** (scènes, dialogues, PNJ, Dresseurs,
## rencontres, départs de débogage, cartes de la Tour) :
## - les données du J19 ne posent que les drapeaux du §2.13 (plus ceux déjà posés avant lui) ;
## - **aucun drapeau du J21** n'y est posé ni lu : le `unless` de `tower_6f_ghost` sur
##   `ghost_marowak_calmed` est la seule lecture permise ;
## - **aucun drapeau du J20** (dossier 23 §17, `origin/jalon-20`) n'y est posé ni lu ;
## - le mode spectre lit le Sac (`ghost_unless_item`), jamais un drapeau ; le SPECTRE du 6F est
##   `ghost: always`.
## Jalon 21 (T15, `jalon-21.md` §2.7, §2.9, §2.13) : le J21 ajoute des **blocs** dans des
## fichiers du J19 (variante A du 6F en tête de `tower_6f_ghost`, variantes `if [fuji_rescued]` en
## tête des dialogues de Lavanville, M. Fuji `if [fuji_rescued]` dans la Maison des Pokémon). Ils
## sont retirés ici avant le contrôle ([method _strip_j21_blocks], liste fermée) : ce contrat porte
## sur la donnée du J19, inchangée ; les blocs du J21 sont contrôlés par `test_j21_flags_contract`.

## Fichiers JSON créés ou modifiés par le J19.
const J19_JSON: Array[String] = [
	"res://data/cutscenes/pokemon_tower_floors.json",
	"res://data/dialogues/pokemon_tower_floors.json",
	"res://data/dialogues/pokemon_tower.json",
	"res://data/dialogues/lavender_houses.json",
	"res://data/dialogues/lavender_town.json",
	"res://data/npcs/lavender_center.json",
	"res://data/npcs/pokemon_house.json",
	"res://data/npcs/pokemon_tower_1f.json",
	"res://data/npcs/pokemon_tower_2f.json",
	"res://data/npcs/pokemon_tower_3f.json",
	"res://data/npcs/pokemon_tower_4f.json",
	"res://data/npcs/pokemon_tower_5f.json",
	"res://data/npcs/pokemon_tower_6f.json",
	"res://data/trainers/pokemon_tower.json",
	"res://data/encounters/pokemon_tower.json",
	"res://tools/debug_start/tower_ghost_qa.json",
	"res://tools/debug_start/tower_6f_block.json",
	"res://tools/debug_start/tower_exorcist_weak.json",
	"res://tools/debug_start/tower_rival.json",
	"res://tools/debug_start/tower_rival_weak.json",
	"res://tools/debug_start/tower_5f_zone.json",
]
## Cartes créées ou modifiées par le J19 (déclencheurs, objets, PNJ : lues en texte).
const J19_SCENES: Array[String] = [
	"res://game/world/maps/pokemon_tower_1f.tscn",
	"res://game/world/maps/pokemon_tower_2f.tscn",
	"res://game/world/maps/pokemon_tower_3f.tscn",
	"res://game/world/maps/pokemon_tower_4f.tscn",
	"res://game/world/maps/pokemon_tower_5f.tscn",
	"res://game/world/maps/pokemon_tower_6f.tscn",
	"res://game/world/maps/lavender_town.tscn",
]
## Clés qui posent des drapeaux (scènes : set, win, lose ; dialogues : set, confirm_set,
## cancel_set ; départs : flags).
const SETTING_KEYS: Array[String] = ["set", "win", "lose", "confirm_set", "cancel_set", "flags"]
## Drapeaux réservés au J21 (§2.13) ; `beaten_tower_rocket_*` par préfixe.
const J21_FLAGS: Array[String] = ["ghost_marowak_calmed", "fuji_rescued", "got_poke_flute"]
const J21_PREFIX: String = "beaten_tower_rocket_"
## Seule lecture permise d'un drapeau du J21 : la variante du SPECTRE du 6F.
const ALLOWED_J21_READ: String = "ghost_marowak_calmed"
## Jalon 21 : blocs du J21 attendus dans les fichiers du J19 (« fichier/identifiant » → nombre de
## variantes ou d'entrées retirées).
const J21_BLOCKS: Dictionary[String, int] = {
	"pokemon_tower_floors.json/tower_6f_ghost": 1,
	"pokemon_tower.json/pokemon_tower_exorcist": 1,
	"lavender_houses.json/pokemon_house_kid": 1,
	"lavender_houses.json/pokemon_house_man": 1,
	"lavender_houses.json/pokemon_house_girl": 1,
	"lavender_houses.json/lavender_center_gentleman": 1,
	"pokemon_house.json/mr_fuji": 1,
}
## Drapeaux du J20 (dossier 23 §17 sur `origin/jalon-20`, 2026-10-19) et Dresseurs du J20
## (`data/trainers/route_8.json`, `celadon_gym.json`, `rocket_hideout.json` de cette branche).
const J20_FLAGS: Array[String] = [
	"route_8_reached", "celadon_reached", "badge_rainbow", "tm21_received", "eevee_received",
	"rooftop_tm13", "game_corner_switch", "rocket_dropped_lift_key", "giovanni_hideout_won",
]
const J20_TRAINER_PREFIXES: Array[String] = [
	"beaten_route_8_", "beaten_celadon_", "beaten_rocket_hideout_", "beaten_giovanni",
]
## Drapeaux posés avant le J19 que ses fichiers posent encore (J18 et avant).
const EARLIER_FLAGS: Array[String] = [
	"mom_greeted", "rival_met", "oak_met", "oak_lab_reunion", "starter_offered",
	"starter_chosen", "taken_charmander", "taken_squirtle", "rival_lab_won", "rival_challenged",
	"rival_battle_done", "rival_left_lab", "viridian_arrived", "got_oak_parcel",
	"pokedex_activated", "poison_unlocked", "pewter_arrived", "beaten_pewter_gym_liam",
	"brock_met", "badge_boulder", "cerulean_reached", "badge_cascade", "route_9_entered",
	"route_10_reached", "dark_cave_crossed", "lavender_reached", "tower_medium_talked",
	"pokemon_house_kid_talked",
]

var _json: Dictionary[String, Variant] = {}


func before_all() -> void:
	for path: String in J19_JSON:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_not_null(parsed, "lisible : %s" % path)
		_json[path] = parsed
	_strip_j21_blocks()


## Jalon 21 : retire les blocs du J21 des fichiers du J19 (variante avec `if_items` en tête d'une
## scène, variante ou PNJ dont le `if` nomme un drapeau du J21) ; ils doivent être exactement
## ceux de [constant J21_BLOCKS].
func _strip_j21_blocks() -> void:
	var stripped: Dictionary[String, int] = {}
	for path: String in _json:
		var root: Variant = _json[path]
		if not root is Dictionary:
			continue
		for id: Variant in (root as Dictionary).keys():
			var entry: Variant = root[id]
			if not entry is Dictionary:
				continue
			var key := "%s/%s" % [path.get_file(), id]
			if _is_j21_block(entry):
				(root as Dictionary).erase(id)
				stripped[key] = stripped.get(key, 0) + 1
				continue
			var variants: Variant = (entry as Dictionary).get("variants")
			if not variants is Array:
				continue
			var kept: Array = []
			for variant: Variant in variants:
				if variant is Dictionary and _is_j21_block(variant):
					stripped[key] = stripped.get(key, 0) + 1
				else:
					kept.append(variant)
			(entry as Dictionary)["variants"] = kept
	assert_eq(stripped, J21_BLOCKS, "blocs du J21 dans les fichiers du J19")


func _is_j21_block(entry: Dictionary) -> bool:
	if entry.has("if_items"):
		return true
	for flag: String in _strings(entry.get("if")):
		if _is_j21(flag):
			return true
	return false


## Drapeaux du J19 (§2.13).
func _j19_flags() -> Array[String]:
	var flags: Array[String] = [
		"tower_stairs_open", "tower_ghost_met",
		"rival_tower_won", "rival_tower_lost_once", "rival_tower_retried",
		"got_tower_3f_objet_1", "got_tower_4f_objet_1", "got_tower_4f_objet_2",
		"got_tower_5f_objet_1", "got_tower_5f_cache_1", "got_tower_6f_objet_1",
	]
	for i: int in range(1, 10):
		flags.append("beaten_tower_channeler_%d" % i)
	return flags


## Chaînes d'une valeur de drapeau (chaîne ou liste de chaînes).
func _strings(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is String:
		out.append(value)
	elif value is Array:
		for entry: Variant in value:
			if entry is String:
				out.append(entry)
	return out


## Drapeaux posés : « fichier → drapeau », par les clés [constant SETTING_KEYS], plus
## `beaten_<id>` de chaque PNJ Dresseur (bloc `trainer.id`, levé par [TrainerEncounter]). Le rival
## n° 5 se bat par une scène, qui ne lève que ses `win` / `lose`.
func _set_flags() -> Array[String]:
	var found: Array[String] = []
	for path: String in _json:
		_collect_set(_json[path], path, found)
	return found


func _collect_set(value: Variant, path: String, out: Array[String]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			if SETTING_KEYS.has(str(key)):
				for flag: String in _strings(value[key]):
					out.append("%s → %s" % [path.get_file(), flag])
			if str(key) == "trainer" and value[key] is Dictionary:
				for id: String in _strings((value[key] as Dictionary).get("id")):
					out.append("%s → %s%s" % [path.get_file(), TrainerRules.BEATEN_PREFIX, id])
			_collect_set(value[key], path, out)
	elif value is Array:
		for entry: Variant in value:
			_collect_set(entry, path, out)


## Toutes les chaînes (clés et valeurs) de [param value], avec leur chemin.
func _all_strings(value: Variant, where: String, out: Array[String]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			out.append("%s|%s" % [where, key])
			_all_strings(value[key], "%s/%s" % [where, key], out)
	elif value is Array:
		for i: int in (value as Array).size():
			_all_strings(value[i], "%s/%d" % [where, i], out)
	elif value is String:
		out.append("%s|%s" % [where, value])


func _is_j21(flag: String) -> bool:
	return J21_FLAGS.has(flag) or flag.begins_with(J21_PREFIX)


func _is_j20(flag: String) -> bool:
	if J20_FLAGS.has(flag):
		return true
	for prefix: String in J20_TRAINER_PREFIXES:
		if flag.begins_with(prefix):
			return true
	return false


func _flag_of(entry: String) -> String:
	return entry.get_slice(" → ", 1)


func test_the_jalon_19_files_are_all_there() -> void:
	for path: String in J19_JSON + J19_SCENES:
		assert_true(FileAccess.file_exists(path), path)


func test_the_data_sets_every_flag_of_the_section_2_13() -> void:
	var set_flags: Array[String] = []
	for entry: String in _set_flags():
		set_flags.append(_flag_of(entry))
	for flag: String in _j19_flags():
		assert_has(set_flags, flag, "%s posé par une donnée du J19" % flag)


func test_the_data_sets_no_other_new_flag() -> void:
	var allowed := _j19_flags() + EARLIER_FLAGS
	for entry: String in _set_flags():
		assert_true(allowed.has(_flag_of(entry)), "drapeau hors §2.13 : %s" % entry)


func test_no_flag_of_the_jalon_21_is_set() -> void:
	for entry: String in _set_flags():
		assert_false(_is_j21(_flag_of(entry)), "drapeau du J21 posé : %s" % entry)


func test_the_only_read_of_a_jalon_21_flag_is_the_6f_ghost_unless() -> void:
	var reads: Array[String] = []
	for path: String in _json:
		var strings: Array[String] = []
		_all_strings(_json[path], path.get_file(), strings)
		for entry: String in strings:
			if _is_j21(entry.get_slice("|", 1)):
				reads.append(entry)
	assert_eq(reads, ["pokemon_tower_floors.json/tower_6f_ghost/variants/0/unless/0|%s"
		% ALLOWED_J21_READ] as Array[String], "une seule lecture : le `unless` du 6F")
	var scene: Dictionary = (_json["res://data/cutscenes/pokemon_tower_floors.json"]
		as Dictionary)["tower_6f_ghost"]
	var variants: Array = scene["variants"]
	assert_eq(variants.size(), 1, "une seule variante au J19")
	assert_eq(variants[0].get("unless"), [ALLOWED_J21_READ], "le `unless` attendu")
	assert_false((variants[0] as Dictionary).has("if"), "aucun `if` sur un drapeau du J21")


func test_the_maps_name_no_flag_of_the_jalon_21() -> void:
	for path: String in J19_SCENES:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.is_empty(), path)
		for flag: String in J21_FLAGS + [J21_PREFIX]:
			assert_false(text.contains(flag), "%s nomme %s" % [path.get_file(), flag])


func test_no_flag_of_the_jalon_20_is_set_or_read() -> void:
	for entry: String in _set_flags():
		assert_false(_is_j20(_flag_of(entry)), "drapeau du J20 posé : %s" % entry)
	for path: String in _json:
		var strings: Array[String] = []
		_all_strings(_json[path], path.get_file(), strings)
		for entry: String in strings:
			assert_false(_is_j20(entry.get_slice("|", 1)), "drapeau du J20 nommé : %s" % entry)
	for path: String in J19_SCENES:
		var text := FileAccess.get_file_as_string(path)
		for flag: String in J20_FLAGS + J20_TRAINER_PREFIXES:
			assert_false(text.contains("\"%s" % flag), "%s nomme %s" % [path.get_file(), flag])


func test_no_debug_start_gives_the_scope() -> void:
	for path: String in J19_JSON:
		if not path.begins_with("res://tools/debug_start/"):
			continue
		var bag: Variant = (_json[path] as Dictionary).get("bag", {})
		assert_false(bag is Dictionary and (bag as Dictionary).has("silph_scope"),
			"%s : pas de Scope au J19" % path.get_file())


func test_the_ghost_mode_reads_the_bag_never_a_flag() -> void:
	var tables: Dictionary = _json["res://data/encounters/pokemon_tower.json"]
	assert_eq(tables.size(), 3)
	for id: Variant in tables:
		var table: Dictionary = tables[id]
		assert_eq(table.get("ghost_unless_item"), "silph_scope", "%s : lu dans le Sac" % id)
		for key: Variant in table:
			assert_false(str(key).contains("flag"), "%s : aucune clé de drapeau (%s)" % [id, key])
	var step := _ghost_battle_step()
	assert_eq(step.get("ghost"), "always", "le SPECTRE du 6F reste un SPECTRE, Scope ou non")
	assert_true(GhostRule.is_known_mode(StringName(step["ghost"])))
	var bag := Bag.new()
	bag.add(&"silph_scope")
	assert_true(GhostRule.is_ghost_for(&"always", &"silph_scope", bag), "`always` ignore le Sac")


func _ghost_battle_step() -> Dictionary:
	var scene: Dictionary = (_json["res://data/cutscenes/pokemon_tower_floors.json"]
		as Dictionary)["tower_6f_ghost"]
	for step: Variant in (scene["variants"][0] as Dictionary)["steps"]:
		if step is Dictionary and (step as Dictionary).has("wild_battle"):
			return step
	fail_test("aucun combat dans tower_6f_ghost")
	return {}
