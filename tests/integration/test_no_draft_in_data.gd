extends GutTest
## Aucun texte provisoire dans les données : le lot de textes en brouillon a été validé tel quel
## par Kevin le 2026-10-06 (docs/design/textes/textes-brouillon-j7.md). Un nouveau texte marqué
## « draft » (dialogue, message de combat, objet, Pokédex, zone, capacité, objectif, moment…)
## fait échouer ce test : il doit être relu par Kevin, puis ce test (ou le texte) mis à jour.

const DATA_DIR := "res://data"
## Brouillons en attente de validation, nommés un par un (chemin relevé par [method _collect_drafts]).
## Une fois validés, retirer leur « draft » et les sortir d'ici (le test vérifie qu'ils sont
## encore en brouillon). Vide depuis la validation de l'annexe A du jalon 17 (Q-2, 2026-10-16) :
## fiches de Pokédex, accord de T-2 à une espèce, sous-titres (en attente de leurs cartes dans
## `tools/pending_data/j17/zones.json`, sans « draft »).
## Jalon 16 (T11) : description de la zone du S.S. Anne sur la Carte, validée le 2026-10-16.
## Jalon 16 (décisions du 2026-10-16) : indice du guide de l'Arène de Carmin (type Sol contre
## Major Bob), validé par Kevin le 2026-10-16.
## Jalon 19 (T3) : descriptions des capacités ajoutées pour les learnsets complets, hors du lot
## §15.7 du dossier 22 : validées par Kevin le 2026-10-15. Jalon 19 (effets de capacités) :
## messages d'Ultralaser et de Hurlement validés par Kevin le 2026-10-16.
## Jalon 21 : Poké Flûte, CT39, Constriction, Bouclier et les fiches de Pokédex d'Ossatueur, de
## Ronflex, de Ptitard et de Tentacool validés par Kevin le 2026-10-16 (dossier 24 §15), « draft »
## retiré.
## Jalon 30 (T16) : bloc « Pokémon © … / projet personnel » du générique, validé par Kevin le
## 2026-10-26, « draft » retiré.
## Jalon 30 : texte du Grand moment « champion » validé par Kevin le 2026-10-26, « draft » retiré.
## Jalon 26 (T6) : description de Safrania sur la Carte [D], à relire par Kevin.
## Jalon 32 (N-11, N-13, N-14) : textes d'Électhor, de Porygon et des échanges PNJ validés par
## Kevin le 2026-10-27, « draft » retiré.
## Jalon 32 (N-14, après la fusion du J30) : échange Têtarte → Lippoutou [D], à relire par Kevin.
const PENDING_DRAFTS: Array[String] = ["world/zones.json/zones/saffron_city",
	# Jalon 32 (RP §2.13) : fiches de Pokédex [D] de la Ligue.
	"pokedex/kanto.json/species/jynx",
	"pokedex/kanto.json/species/machamp",
	"pokedex/kanto.json/species/gengar",
	"pokedex/kanto.json/species/dragonair",
	"pokedex/kanto.json/species/dragonite",
	"dialogues/j32_trades.json/j32_trade_coline_offer/variants/0",
	"dialogues/j32_trades.json/j32_trade_coline_refuse/variants/0",
	"dialogues/j32_trades.json/j32_trade_coline_wrong/variants/0",
	"dialogues/j32_trades.json/j32_trade_coline_thanks/variants/0",
	"dialogues/j32_trades.json/j32_trade_coline_after/variants/0",
	"dialogues/j32_trades.json/j32_trade_coline_done/variants/0",
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
