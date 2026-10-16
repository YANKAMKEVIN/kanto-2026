extends GutTest
## Aucun texte provisoire dans les données : le lot de textes en brouillon a été validé tel quel
## par Kevin le 2026-10-06 (docs/design/textes/textes-brouillon-j7.md). Un nouveau texte marqué
## « draft » (dialogue, message de combat, objet, Pokédex, zone, capacité, objectif, moment…)
## fait échouer ce test : il doit être relu par Kevin, puis ce test (ou le texte) mis à jour.

const DATA_DIR := "res://data"
## Brouillons en attente de validation, nommés un par un (chemin relevé par [method _collect_drafts]).
## Une fois validés, retirer leur « draft » et les sortir d'ici (le test vérifie qu'ils sont
## encore en brouillon). Vide depuis la validation de l'annexe A du jalon 15 (2026-10-14).
const PENDING_DRAFTS: Array[String] = [
	# Jalon 24 (T4) : capacités et objets nouveaux, fiches de Pokédex (hors du lot §15 du
	# dossier 27).
	"pokemon/moves/j24.json/vise_grip", "pokemon/moves/j24.json/guillotine",
	"pokemon/moves/j24.json/crabhammer", "pokemon/moves/j24.json/spike_cannon",
	"pokemon/moves/j24.json/blizzard", "pokemon/moves/j24.json/splash",
	"items/items_j24.json/ultra_ball", "items/items_j24.json/hyper_potion",
	"items/items_j24.json/full_heal",
	"pokedex/kanto.json/species/psyduck", "pokedex/kanto.json/species/golduck",
	"pokedex/kanto.json/species/poliwhirl", "pokedex/kanto.json/species/poliwrath",
	"pokedex/kanto.json/species/tentacruel", "pokedex/kanto.json/species/slowpoke",
	"pokedex/kanto.json/species/slowbro", "pokedex/kanto.json/species/seel",
	"pokedex/kanto.json/species/dewgong", "pokedex/kanto.json/species/cloyster",
	"pokedex/kanto.json/species/krabby", "pokedex/kanto.json/species/kingler",
	"pokedex/kanto.json/species/seadra", "pokedex/kanto.json/species/seaking",
	"pokedex/kanto.json/species/magikarp", "pokedex/kanto.json/species/omanyte",
	"pokedex/kanto.json/species/omastar", "pokedex/kanto.json/species/kabuto",
	"pokedex/kanto.json/species/kabutops", "pokedex/kanto.json/species/articuno",
]


func test_data_has_json_files() -> void:
	assert_gt(_json_files(DATA_DIR).size(), 10, "les fichiers de données sont trouvés")


func test_no_draft_text_in_data() -> void:
	var drafts: Array[String] = []
	for path: String in _json_files(DATA_DIR):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_not_null(parsed, "%s : JSON valide" % path)
		_collect_drafts(parsed, path.trim_prefix(DATA_DIR + "/"), drafts)
	for pending: String in PENDING_DRAFTS:
		assert_true(drafts.has(pending), "%s : plus en brouillon, à retirer de la liste" % pending)
		drafts.erase(pending)
	assert_eq(drafts, [] as Array[String], "textes provisoires à faire relire par Kevin")


## Ajoute à [param out] le chemin de chaque objet de [param value] qui porte une clé « draft »
## (quelle que soit sa valeur : un « draft » à false n'a pas lieu d'être non plus).
func _collect_drafts(value: Variant, where: String, out: Array[String]) -> void:
	if value is Dictionary:
		var dict: Dictionary = value
		if dict.has("draft"):
			out.append(where)
		for key: Variant in dict:
			_collect_drafts(dict[key], "%s/%s" % [where, key], out)
	elif value is Array:
		var list: Array = value
		for i: int in list.size():
			_collect_drafts(list[i], "%s/%d" % [where, i], out)


func _json_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(dir_path):
		if file.get_extension() == "json":
			files.append(dir_path.path_join(file))
	for dir: String in DirAccess.get_directories_at(dir_path):
		files.append_array(_json_files(dir_path.path_join(dir)))
	return files
