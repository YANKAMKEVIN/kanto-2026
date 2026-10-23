extends GutTest
## Prénom du rival ≠ rôle du rival (OUV.2, dossier 13 §3.5) : seule la **couche 1** (nom affiché)
## passe par le jeton `{rival}`, sur une **liste fermée** ; les identifiants techniques (couche 2)
## et le mot commun « rival » (couche 3) ne changent pas.

const DIALOGUES_DIR := "res://data/dialogues/"
const TRAINERS_DIR := "res://data/trainers/"
const RIVAL_TOKEN := "{rival}"
## Littéraux interdits comme locuteur ou nom de dresseur (couche 1).
const FORBIDDEN: Array[String] = ["Rival", "Le Rival", "rival", "le rival"]
## Liste fermée de la couche 1 (§3.5) : locuteurs `{rival}` par fichier, noms de dresseur.
const SPEAKERS_BY_FILE: Dictionary[String, int] = {
	"oak_lab.json": 14, "route_22.json": 4, "rival_house.json": 1,
	"route_24.json": 5,
	# Jalon 16 (T13) : le rival n° 4 (introduction, défaite, reprise, victoire).
	"ss_anne_captain_corridor.json": 4,
	# Jalon 19 (T17) : le rival n° 5 (introduction, reprise, victoire, défaite).
	"pokemon_tower_floors.json": 4,
	# Jalon 30 (T4, T9) : le rival Champion (avant, vaincu, victoire du rival).
	"league.json": 3,
}
## Jalon 30 : répliques qui nomment le rival dans leur texte (T30-14, Chen au rival, texte validé du
## plan `jalon-30.md` §3), par fichier.
const TEXT_TOKENS_BY_FILE: Dictionary[String, int] = {"league.json": 1}
const RIVAL_TRAINERS: Array[String] = ["rival_lab", "rival_route22"]


func test_no_literal_rival_as_speaker_in_the_dialogues() -> void:
	for file: String in _json_files(DIALOGUES_DIR):
		for speaker: String in _values_of(_read(DIALOGUES_DIR + file), "speaker"):
			assert_false(FORBIDDEN.has(speaker.strip_edges()),
				"%s : locuteur « %s » écrit en dur (jeton {rival} attendu)" % [file, speaker])


func test_no_literal_rival_as_trainer_name() -> void:
	for file: String in _json_files(TRAINERS_DIR):
		var data := _read(TRAINERS_DIR + file)
		for id: Variant in data:
			var name: String = str((data[id] as Dictionary).get("name", ""))
			assert_false(FORBIDDEN.has(name.strip_edges()),
				"%s %s : nom « %s » écrit en dur" % [file, id, name])


func test_the_closed_list_of_speakers_uses_the_rival_token() -> void:
	var total := 0
	for file: String in _json_files(DIALOGUES_DIR):
		var count := _values_of(_read(DIALOGUES_DIR + file), "speaker").count(RIVAL_TOKEN)
		assert_eq(count, SPEAKERS_BY_FILE.get(file, 0), "%s : locuteurs {rival}" % file)
		total += count
	assert_eq(total, 35, "19 étiquettes du rival (§3.5) + 5 du rival n° 3 (J13 T19) + 4 du "
		+ "rival n° 4 (J16 T13) + 4 du rival n° 5 (J19 T17) + 3 du rival Champion (J30), "
		+ "pas une de plus")


func test_the_rival_trainers_are_named_by_the_token() -> void:
	var data := _read(TRAINERS_DIR + "rival.json")
	for id: String in RIVAL_TRAINERS:
		assert_eq((data[id] as Dictionary)["name"], RIVAL_TOKEN, id)


func test_no_other_text_carries_the_rival_token() -> void:
	# Le prénom n'apparaît que comme locuteur et nom de dresseur : aucune réplique n'est réécrite.
	for file: String in _json_files(DIALOGUES_DIR):
		var text := FileAccess.get_file_as_string(DIALOGUES_DIR + file)
		var speakers := _values_of(_read(DIALOGUES_DIR + file), "speaker").count(RIVAL_TOKEN)
		assert_eq(text.count(RIVAL_TOKEN), speakers + TEXT_TOKENS_BY_FILE.get(file, 0),
			"%s : {rival} hors locuteur" % file)


func test_technical_identifiers_are_unchanged() -> void:
	# Couche 2 : identifiants de dresseur, PNJ et apparence, drapeaux, Grand moment.
	var trainers := _read(TRAINERS_DIR + "rival.json")
	for id: String in RIVAL_TRAINERS:
		assert_true(trainers.has(id), "dresseur %s" % id)
	for map: String in ["oak_lab", "rival_house", "route_22"]:
		var npcs := _read("res://data/npcs/%s.json" % map)
		assert_true(npcs.has("rival"), "PNJ « rival » de %s" % map)
		assert_eq((npcs["rival"] as Dictionary)["sprite"], "rival", "apparence « rival »")
	assert_true(ResourceLoader.exists(
		"res://assets/sprites/characters/painted/rival_frames.tres"))
	var moments := _read("res://data/trainer/moments.json")["moments"] as Dictionary
	assert_true(moments.has("rival_battle"), "Grand moment « rival_battle »")
	# Couche 3 : le rôle reste un mot commun.
	assert_eq((moments["rival_battle"] as Dictionary)["title"], "Combat contre le rival")
	var dialogues := FileAccess.get_file_as_string(DIALOGUES_DIR + "oak_lab.json")
	assert_true(dialogues.contains("\"rival_battle_done\""), "drapeau inchangé")


func test_the_real_rival_dialogues_show_the_chosen_name() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir(), str(library.get_errors()))
	var values := DialogueTokens.values_for(&"", null, "Sacha", "Gary")
	var labels: Array[String] = []
	for id: StringName in library.get_ids():
		var dialogue := library.get_dialogue(id)
		for variant: DialogueVariant in dialogue.variants:
			for page: DialoguePage in DialogueTokens.resolve_pages(variant.pages, values):
				var speaker := page.speaker if not page.speaker.is_empty() \
					else DialogueTokens.resolve_speaker(dialogue.speaker, values)
				assert_false(speaker.contains("{"), "%s : locuteur non résolu" % id)
				if speaker == "Gary":
					labels.append(String(id))
	assert_gt(labels.size(), 0, "le prénom choisi est l'étiquette du rival")


func _json_files(dir: String) -> PackedStringArray:
	var files := PackedStringArray()
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".json"):
			files.append(file)
	return files


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, path)
	return parsed if parsed is Dictionary else {}


## Toutes les valeurs (textes) de la clé [param key], à toute profondeur.
func _values_of(value: Variant, key: String) -> Array[String]:
	var found: Array[String] = []
	if value is Dictionary:
		for k: Variant in value:
			if str(k) == key and value[k] is String:
				found.append(value[k])
			else:
				found.append_array(_values_of(value[k], key))
	elif value is Array:
		for item: Variant in value:
			found.append_array(_values_of(item, key))
	return found
