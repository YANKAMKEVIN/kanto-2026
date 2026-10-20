extends GutTest
## Aucun drapeau du jalon 21 posé par les données (jalon 20 T21, `jalon-20.md` §2.7.5 ; dossier 23
## §14 ; passation du J19, `jalon-19.md` §9.3) : dans `data/cutscenes`, `data/dialogues`,
## `data/npcs` et les départs de débogage, aucune clé qui pose un drapeau (« set », « win »,
## « lose », « confirm_set », « cancel_set », « flags », « flag » d'un don) ne vaut `fuji_*`,
## `marowak_*`, `ghost_marowak_*`, `poke_flute*`, `got_poke_flute`, ni `beaten_tower_rocket_*`.
## Le Scope Sylphe n'est qu'un objet : la Tour lit le Sac (J19), aucune donnée ne pose de drapeau
## « scope ». La seule lecture d'un drapeau du J21 reste le `unless` du SPECTRE du 6F (J19).

const DIRS: Array[String] = [
	"res://data/cutscenes/", "res://data/dialogues/", "res://data/npcs/",
	"res://tools/debug_start/",
]
const SETTING_KEYS: Array[String] = ["set", "win", "lose", "confirm_set", "cancel_set", "flags",
	"flag"]
const J21_PREFIXES: Array[String] = ["fuji_", "marowak_", "ghost_marowak_", "poke_flute",
	"got_poke_flute", "beaten_tower_rocket_"]
## Données du J20 (T17, T21, T25) : elles ne lisent aucun drapeau du J21 non plus.
const J20_FILES: Array[String] = [
	"res://data/cutscenes/game_corner.json", "res://data/cutscenes/rocket_hideout.json",
	"res://data/cutscenes/celadon_gym.json", "res://data/cutscenes/celadon_city_life.json",
	"res://data/dialogues/game_corner.json", "res://data/dialogues/rocket_hideout.json",
	"res://data/dialogues/celadon_gym.json", "res://data/npcs/celadon_game_corner.json",
	"res://data/npcs/rocket_hideout_b1f.json", "res://data/npcs/rocket_hideout_b2f.json",
	"res://data/npcs/rocket_hideout_b3f.json", "res://data/npcs/rocket_hideout_b4f.json",
	"res://data/story/objectives.json",
]


func _is_j21(flag: String) -> bool:
	for prefix: String in J21_PREFIXES:
		if flag.begins_with(prefix):
			return true
	return false


func _strings(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is String:
		out.append(value)
	elif value is Array:
		for entry: Variant in value:
			if entry is String:
				out.append(entry)
	return out


func _collect_set(value: Variant, where: String, out: Array[String]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			if SETTING_KEYS.has(str(key)):
				for flag: String in _strings(value[key]):
					out.append("%s → %s" % [where, flag])
			_collect_set(value[key], where, out)
	elif value is Array:
		for entry: Variant in value:
			_collect_set(entry, where, out)


func _all_strings(value: Variant, out: Array[String]) -> void:
	if value is Dictionary:
		for key: Variant in value:
			out.append(str(key))
			_all_strings(value[key], out)
	elif value is Array:
		for entry: Variant in value:
			_all_strings(entry, out)
	elif value is String:
		out.append(value)


func _parse(path: String) -> Variant:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_not_null(parsed, "lisible : %s" % path)
	return parsed


func test_no_data_sets_a_flag_of_the_jalon_21() -> void:
	var set_flags: Array[String] = []
	var files := 0
	for dir: String in DIRS:
		for file: String in DirAccess.get_files_at(dir):
			if file.get_extension() != "json":
				continue
			files += 1
			_collect_set(_parse(dir + file), file, set_flags)
	assert_gt(files, 100, "les quatre dossiers sont lus")
	assert_gt(set_flags.size(), 100, "des drapeaux sont bien posés")
	for entry: String in set_flags:
		assert_false(_is_j21(entry.get_slice(" → ", 1)), "drapeau du J21 posé : %s" % entry)


func test_the_jalon_20_data_reads_no_flag_of_the_jalon_21_nor_a_scope_flag() -> void:
	for path: String in J20_FILES:
		var strings: Array[String] = []
		_all_strings(_parse(path), strings)
		for text: String in strings:
			assert_false(_is_j21(text), "%s : « %s »" % [path.get_file(), text])
			assert_false(text in ["silph_scope_obtained", "got_silph_scope", "silph_scope_got"],
				"%s : le Scope est un objet du Sac, pas un drapeau" % path.get_file())


func test_the_scope_is_given_once_as_a_key_item_and_never_taken_back() -> void:
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	var gives := 0
	var takes := 0
	for id: StringName in cutscenes.get_ids():
		for variant: CutsceneVariant in cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.item_id != &"silph_scope":
					continue
				if step.kind == CutsceneStep.Kind.GIVE:
					gives += 1
				elif step.kind == CutsceneStep.Kind.TAKE:
					takes += 1
	assert_eq(gives, 1, "une seule remise : la Poké Ball du B4F")
	assert_eq(takes, 0, "jamais repris")
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	var scope := items.get_item(&"silph_scope")
	assert_true(scope.is_key(), "objet clé")
	assert_eq(scope.field_use, &"", "sans action UTILISER")
