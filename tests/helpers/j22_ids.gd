extends RefCounted
## Jalon 22 : identifiants définis dans les fichiers `j22_*.json` d'un dossier de données
## (dialogues, scènes). Les grands registres (`test_dialogue_data`, `test_cutscene_data`) les
## écartent ; `test_j22_data.gd` les vérifie à part, générés depuis les grilles
## (`tools/gen_j22_data.py`).
## Utilisation : [code]const J22Ids := preload("res://tests/helpers/j22_ids.gd")[/code].

const PREFIX: String = "j22_"
## Jalon 23 : mêmes règles pour ses fichiers générés (`tools/gen_j23_data.py`), vérifiés par
## `test_j23_data.gd`. Chapitre Johto : fichiers `joh2_*` (`tools/gen_joh2_data.py`,
## `test_joh2_data.gd`), `joh3_*` (`test_joh3_data.gd`), `joh4_*` (`tools/gen_joh4_data.py`,
## `test_joh4_data.gd`), `joh5_*` (`tools/gen_joh5_data.py`, `test_joh5_data.gd`), `joh6_*`
## (`tools/gen_joh6_data.py`, `tools/gen_joh6_story.py`, `test_joh6_data.gd`) `joh7_*`
## (`tools/gen_joh7_data.py`, `test_joh7_data.gd`), `joh8_*` (`test_joh8_data.gd`) et `joh9_*`
## (`tools/gen_joh9_data.py`, `test_joh9_data.gd`).
const PREFIXES: Array[String] = ["j22_", "j23_", "joh2_", "joh3_", "joh4_", "joh5_", "joh6_", "joh7_", "joh8_", "joh9_", "johp2_"]
## Textes validés du J22 (§16) et recommandés validés d'avance (§16.8).
const DOSSIER_25: String = "res://docs/design/dossier-25-deux-chemins-parmanie.md"


## Identifiants des fichiers générés des J22 et J23 ([constant PREFIXES]) : les grands registres
## les écartent.
static func generated_in_dir(dir: String) -> Dictionary:
	var ids: Dictionary = {}
	for prefix: String in PREFIXES:
		ids.merge(in_dir(dir, prefix))
	return ids


static func in_dir(dir: String, prefix: String = PREFIX) -> Dictionary:
	var ids: Dictionary = {}
	for file: String in DirAccess.get_files_at(dir):
		if not file.begins_with(prefix) or not file.ends_with(".json"):
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
