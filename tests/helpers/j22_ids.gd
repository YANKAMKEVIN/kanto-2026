extends RefCounted
## Jalon 22 : identifiants définis dans les fichiers `j22_*.json` d'un dossier de données
## (dialogues, scènes). Les grands registres (`test_dialogue_data`, `test_cutscene_data`) les
## écartent ; `test_j22_data.gd` les vérifie à part, générés depuis les grilles
## (`tools/gen_j22_data.py`).
## Utilisation : [code]const J22Ids := preload("res://tests/helpers/j22_ids.gd")[/code].

const PREFIX: String = "j22_"
## Textes validés du J22 (§16) et recommandés validés d'avance (§16.8).
const DOSSIER_25: String = "res://docs/design/dossier-25-deux-chemins-parmanie.md"


static func in_dir(dir: String) -> Dictionary:
	var ids: Dictionary = {}
	for file: String in DirAccess.get_files_at(dir):
		if not file.begins_with(PREFIX) or not file.ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + file))
		if parsed is Dictionary:
			for key: String in parsed:
				ids[StringName(key)] = true
	return ids


## Texte à plat pour chercher une réplique dans le dossier 25 : sans guillemets, bulles (« / »)
## et retours à la ligne remplacés par des espaces, jeton {n} = {caught}.
static func flat_text(text: String) -> String:
	var flat := text.replace("«", " ").replace("»", " ").replace(" / ", " ").replace("\n", " ")
	flat = flat.replace("{n}", "{caught}").replace("*", "")
	while flat.contains("  "):
		flat = flat.replace("  ", " ")
	return flat.strip_edges()
