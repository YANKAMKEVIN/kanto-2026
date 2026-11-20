extends GutTest
## Le jeu tutoie le joueur partout dans l'interface (« Personnalise tes contrôles », « Touche
## l'écran pour continuer ») : aucun texte d'interface ne lui parle à l'impératif en « -ez »
## (« Touchez », « Désactivez-la »).
##
## Sont relus : les textes des données hors paroles de personnages (messages de combat, titre,
## nouveautés, objets, Pokédex, zones, objectifs…) et les chaînes écrites dans le code du jeu
## (Paramètres, Boutique…). Les personnages, eux, parlent comme ils veulent (« Vous voulez tous
## les deux découvrir Kanto. ») : dialogues, scènes, PNJ et Dresseurs ne sont pas relus.

const DATA_DIR := "res://data"
const CODE_DIR := "res://game"
## Paroles de personnages : jamais relues.
const SPOKEN: Array[String] = ["res://data/dialogues", "res://data/cutscenes", "res://data/npcs",
	"res://data/trainers", "res://data/opening/oak_intro.json"]
## Mots en « -ez » qui ne sont pas des verbes adressés au joueur.
const ALLOWED: Array[String] = ["assez", "chez", "nez", "rez"]

var _word: RegEx = RegEx.create_from_string("(?<![\\p{L}])[\\p{L}]+ez(?![\\p{L}])")
var _literal: RegEx = RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"")


func test_the_rule_catches_the_imperative_and_spares_ordinary_words() -> void:
	assert_eq(_offenders("Touchez l'écran pour continuer"), ["Touchez"] as Array[String])
	assert_eq(_offenders("Désactivez-la pour plus de fluidité."), ["Désactivez"] as Array[String])
	assert_eq(_offenders("Touche l'écran pour continuer"), [] as Array[String])
	assert_eq(_offenders("Tu n'as pas assez d'argent, va chez Chen."), [] as Array[String])


func test_no_interface_text_in_the_data_addresses_the_player_formally() -> void:
	var found: Array[String] = []
	var files := _files(DATA_DIR, "json")
	assert_gt(files.size(), 10, "les fichiers de données sont trouvés")
	for path: String in files:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		_collect(parsed, path, found)
	assert_eq(found, [] as Array[String], "textes d'interface à tutoyer")


func test_no_text_written_in_the_code_addresses_the_player_formally() -> void:
	var found: Array[String] = []
	var files := _files(CODE_DIR, "gd")
	assert_gt(files.size(), 100, "les scripts du jeu sont trouvés")
	for path: String in files:
		var number := 0
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			number += 1
			if line.strip_edges().begins_with("#"):
				continue
			for literal: RegExMatch in _literal.search_all(line):
				for word: String in _offenders(literal.get_string(1)):
					found.append("%s:%d « %s »" % [path, number, word])
	assert_eq(found, [] as Array[String], "textes du code à tutoyer")


func test_the_two_texts_that_used_to_be_formal() -> void:
	var texts := BattleText.new()
	assert_true(texts.load_file())
	assert_eq(texts.get_template(&"summary_continue"), "Touche l'écran pour continuer")
	assert_eq(SettingsViews.ECONOMY_DETAIL,
		"Désactive-la pour plus de fluidité sur les petits téléphones.")


## Mots de [param text] à l'impératif en « -ez » (hors [constant ALLOWED]).
func _offenders(text: String) -> Array[String]:
	var words: Array[String] = []
	for found: RegExMatch in _word.search_all(text):
		if not ALLOWED.has(found.get_string().to_lower()):
			words.append(found.get_string())
	return words


func _collect(value: Variant, where: String, out: Array[String]) -> void:
	if value is String:
		for word: String in _offenders(value):
			out.append("%s « %s »" % [where, word])
	elif value is Dictionary:
		for key: Variant in value:
			# Les notes (« _note ») s'adressent à qui maintient le fichier, pas au joueur.
			if str(key).begins_with("_"):
				continue
			_collect(value[key], "%s/%s" % [where, key], out)
	elif value is Array:
		for i: int in (value as Array).size():
			_collect(value[i], "%s/%d" % [where, i], out)


func _files(dir_path: String, extension: String) -> Array[String]:
	var files: Array[String] = []
	if SPOKEN.has(dir_path):
		return files
	for file: String in DirAccess.get_files_at(dir_path):
		var path := dir_path.path_join(file)
		if file.get_extension() == extension and not SPOKEN.has(path):
			files.append(path)
	for dir: String in DirAccess.get_directories_at(dir_path):
		files.append_array(_files(dir_path.path_join(dir), extension))
	return files
