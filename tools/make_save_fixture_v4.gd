extends SceneTree
## Fabrique la fixture v4 de la sauvegarde v5 (OUV.1, docs/tech/ouverture.md §2) quand la vraie
## partie de Kevin n'a pas pu être relevée sur le téléphone (aucun S24 branché).
##
##   godot --headless --path . -s res://tools/make_save_fixture_v4.gd
##
## Point de départ : la **vraie** partie de Kevin relevée sur le S24 au J8 (v3,
## `tests/fixtures/save/v3_kevin_s24.json`). Elle est migrée en v4, chargée dans un GameState neuf
## puis réécrite par `to_dict()` : c'est exactement le fichier qu'une build du J10 (v4) écrirait au
## premier autosave de cette partie. Les champs de la v5 (« rival_name », « player_look ») sont
## retirés : ils n'existaient pas en v4. À remplacer par la vraie sauvegarde du téléphone
## (`adb exec-out run-as dev.kevin.kanto2026 cat files/save.json`) à la validation S24.

const SOURCE := "res://tests/fixtures/save/v3_kevin_s24.json"
const TARGET := "res://tests/fixtures/save/v4_kevin_depuis_s24_j8.json"
const V5_KEYS: Array[String] = ["rival_name", "player_look"]


func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
	if not parsed is Dictionary:
		push_error("fixture source illisible : %s" % SOURCE)
		quit(1)
		return
	var content := parsed as Dictionary
	var save_script: GDScript = load("res://game/systems/save/save_system.gd")
	if save_script.upgrade(content, 4) != OK:
		push_error("migration v3 → v4 impossible")
		quit(1)
		return
	var data: RefCounted = load("res://game/pokemon/pokemon_data.gd").new()
	data.load_dir()
	var state: Node = load("res://game/autoload/game_state.gd").new()
	if not state.load_dict(content, data):
		push_error("la partie source a des entrées écartées")
	var out: Dictionary = state.to_dict()
	for key: String in V5_KEYS:
		out.erase(key)
	out["version"] = 4
	var file := FileAccess.open(TARGET, FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "\t") + "\n")
	file.close()
	state.free()
	print("fixture v4 écrite : %s (%d clés)" % [TARGET, out.size()])
	quit()
