extends GutTest
## PokedexLibrary : data/pokedex/kanto.json (jalon-06.md §3.5 ; Q-5 taille et poids officiels,
## descriptions provisoires ; Q-6 une note par espèce rencontrable).

## Formes de base rencontrables (J6 Q-6, + Route 22 au J7, + Forêt de Jade au J9) : une note
## chacune, débloquée à la première observation. Les évolutions n'en ont pas, même
## rencontrables (Chrysacier, Coconfort : lot de textes du J9, n° 41, 45, 49).
const ENCOUNTERABLE: Array[StringName] = [
	&"bulbasaur", &"charmander", &"squirtle", &"pidgey", &"rattata",
	&"spearow", &"mankey", &"nidoran_f", &"nidoran_m", &"caterpie", &"weedle", &"pikachu",
]

var _data: PokemonData
var _lib: PokedexLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()


func before_each() -> void:
	_lib = PokedexLibrary.new()


func _valid() -> Dictionary:
	return {
		"size": 151,
		"species": {
			"pidgey": {
				"height": 0.3, "weight": 1.8, "description": "Un oiseau.", "draft": true,
				"notes": [{"id": "pidgey_a", "text": "Note A.", "unlock": {"seen": 1}}],
			},
		},
	}


# --- Données réelles -----------------------------------------------------------------------

func test_real_data_loads_without_error() -> void:
	assert_true(_lib.load_file(), "\n".join(_lib.get_errors()))
	assert_true(_lib.check_references(_data), "\n".join(_lib.get_errors()))
	assert_eq(_lib.get_errors().size(), 0)
	assert_eq(_lib.size(), 151)


func test_every_species_of_the_data_has_an_entry_and_the_reverse() -> void:
	_lib.load_file()
	_lib.check_references(_data)
	for id: StringName in _data.get_species_ids():
		assert_true(_lib.has_species(id), "%s a sa fiche de Pokédex" % id)
		var info := _lib.get_species(id)
		assert_gt(info.height, 0.0)
		assert_gt(info.weight, 0.0)
		assert_false(info.description.is_empty())
	assert_eq(_lib.get_species_ids().size(), _data.get_species_ids().size())


func test_real_heights_and_weights_are_the_official_ones() -> void:
	_lib.load_file()
	var official := {
		&"bulbasaur": [0.7, 6.9], &"charmander": [0.6, 8.5], &"squirtle": [0.5, 9.0],
		&"charizard": [1.7, 90.5], &"venusaur": [2.0, 100.0], &"pidgey": [0.3, 1.8],
		&"rattata": [0.3, 3.5], &"raticate": [0.7, 18.5],
		&"spearow": [0.3, 2.0], &"fearow": [1.2, 38.0], &"mankey": [0.5, 28.0],
		&"primeape": [1.0, 32.0], &"nidoran_f": [0.4, 7.0], &"nidorina": [0.8, 20.0],
		&"nidoqueen": [1.3, 60.0], &"nidoran_m": [0.5, 9.0], &"nidorino": [0.9, 19.5],
		&"nidoking": [1.4, 62.0],
		&"caterpie": [0.3, 2.9], &"metapod": [0.7, 9.9], &"butterfree": [1.1, 32.0],
		&"weedle": [0.3, 3.2], &"kakuna": [0.6, 10.0], &"beedrill": [1.0, 29.5],
		&"pikachu": [0.4, 6.0], &"raichu": [0.8, 30.0],
	}
	for id: StringName in official:
		assert_almost_eq(_lib.get_species(id).height, float(official[id][0]), 0.001, id)
		assert_almost_eq(_lib.get_species(id).weight, float(official[id][1]), 0.001, id)


func test_real_texts_are_validated_and_never_spoil() -> void:
	_lib.load_file()
	for id: StringName in _lib.get_species_ids():
		var info := _lib.get_species(id)
		assert_false(info.draft, "%s : description validée (2026-10-06)" % id)
		var texts: Array[String] = [info.description]
		for note: PokedexNoteData in info.notes:
			assert_false(note.draft, "%s : note validée (2026-10-06)" % note.id)
			texts.append(note.text)
		for text: String in texts:
			var lower := text.to_lower()
			for word: String in ["évolu", "niveau", "pokédex"]:
				assert_false(lower.contains(word), "« %s » dans « %s »" % [word, text])
			for other: StringName in _data.get_species_ids():
				assert_false(other != id and text.contains(_data.get_species(other).name),
					"%s ne nomme pas une autre espèce" % id)


func test_real_notes_one_per_encounterable_species_unlocked_at_first_sighting() -> void:
	_lib.load_file()
	for id: StringName in _lib.get_species_ids():
		var notes := _lib.get_notes(id)
		if ENCOUNTERABLE.has(id):
			assert_eq(notes.size(), 1, "%s : une note (Q-6)" % id)
			assert_eq(notes[0].seen, 1, "%s : à la première observation" % id)
			assert_eq(notes[0].caught, 0)
			assert_eq(notes[0].map, &"")
			assert_eq(notes[0].flag, &"")
			assert_eq(notes[0].species, id)
			assert_eq(_lib.get_note(notes[0].id), notes[0])
		else:
			assert_eq(notes.size(), 0, "%s : pas encore de note" % id)


func test_real_note_maps_exist() -> void:
	_lib.load_file()
	var unknown: Array[StringName] = []
	for id: StringName in _lib.get_species_ids():
		for note: PokedexNoteData in _lib.get_notes(id):
			if not note.map.is_empty() and not MapCatalog.has_map(note.map):
				unknown.append(note.map)
	assert_eq(unknown, [] as Array[StringName], "cartes des conditions « map »")


# --- Format ---------------------------------------------------------------------------------

func test_valid_entry_is_read() -> void:
	assert_true(_lib.add_from_dict(_valid(), "test"))
	var info := _lib.get_species(&"pidgey")
	assert_eq(info.id, &"pidgey")
	assert_almost_eq(info.height, 0.3, 0.0001)
	assert_almost_eq(info.weight, 1.8, 0.0001)
	assert_eq(info.description, "Un oiseau.")
	assert_true(info.draft)
	assert_eq(info.notes.size(), 1)
	assert_eq(info.notes[0].id, &"pidgey_a")
	assert_eq(info.notes[0].seen, 1)
	assert_false(info.notes[0].draft, "draft faux par défaut")
	assert_null(_lib.get_species(&"rattata"))
	assert_eq(_lib.get_notes(&"rattata").size(), 0)


func test_all_unlock_conditions_are_read() -> void:
	var data := _valid()
	data["species"]["pidgey"]["notes"] = [{"id": "n", "text": "T.", "unlock": {
		"seen": 3, "caught": 2, "map": "route_1", "flag": "pokedex_activated"}}]
	assert_true(_lib.add_from_dict(data, "test"))
	var note := _lib.get_note(&"n")
	assert_eq(note.seen, 3)
	assert_eq(note.caught, 2)
	assert_eq(note.map, &"route_1")
	assert_eq(note.flag, &"pokedex_activated")


func test_invalid_species_entries_are_rejected() -> void:
	var data := {"size": 151, "species": {
		"a": "pas un objet",
		"b": {"height": 0.3, "weight": 1.0},
		"c": {"height": -1, "weight": 1.0, "description": "x"},
		"d": {"height": 0.3, "weight": "lourd", "description": "x"},
		"e": {"height": 0.3, "weight": 1.0, "description": "  "},
		"f": {"height": 0.3, "weight": 1.0, "description": "x", "stats": {}},
		"g": {"height": 0.3, "weight": 1.0, "description": "x", "draft": "oui"},
		"h": {"height": 0.3, "weight": 1.0, "description": "x", "notes": {}},
		"ok": {"height": 0.3, "weight": 1.0, "description": "x"},
	}}
	assert_false(_lib.add_from_dict(data, "test"))
	assert_eq(_lib.get_species_ids(), [&"ok"] as Array[StringName], "les valides restent")
	assert_push_error_count(8, "une erreur par entrée invalide")


func test_invalid_notes_are_rejected() -> void:
	var data := _valid()
	data["species"]["pidgey"]["notes"] = [
		{"id": "a", "text": "T.", "unlock": {}},
		{"id": "b", "text": "T.", "unlock": {"seen": 0}},
		{"id": "c", "text": "T.", "unlock": {"seen": 1.5}},
		{"id": "d", "text": "T.", "unlock": {"weather": "rain"}},
		{"id": "e", "text": "", "unlock": {"seen": 1}},
		{"text": "T.", "unlock": {"seen": 1}},
		{"id": "g", "text": "T.", "unlock": {"map": ""}},
		{"id": "h", "text": "T.", "unlock": {"seen": 1}, "hint": "x"},
	]
	assert_false(_lib.add_from_dict(data, "test"))
	assert_null(_lib.get_species(&"pidgey"), "une note invalide écarte l'espèce")
	assert_push_error_count(8)


func test_note_ids_are_unique_in_the_whole_file() -> void:
	var data := _valid()
	data["species"]["rattata"] = {"height": 0.3, "weight": 3.5, "description": "x",
		"notes": [{"id": "pidgey_a", "text": "T.", "unlock": {"seen": 1}}]}
	assert_false(_lib.add_from_dict(data, "test"))
	assert_true(_lib.has_species(&"pidgey"))
	assert_false(_lib.has_species(&"rattata"))
	assert_push_error("déjà définie")


func test_root_is_strict() -> void:
	assert_false(_lib.add_from_dict({"size": 0, "species": {}, "region": "kanto"}, "test"))
	assert_push_error_count(2, "taille hors bornes et clé inconnue")
	assert_false(PokedexLibrary.new().add_from_dict({"size": 151}, "test"))
	assert_push_error("« species »")


func test_check_references_rejects_unknown_species_and_numbers_beyond_size() -> void:
	var data := _valid()
	data["size"] = 10
	data["species"]["missingno"] = {"height": 1.0, "weight": 1.0, "description": "x",
		"notes": [{"id": "m", "text": "T.", "unlock": {"seen": 1}}]}
	assert_true(_lib.add_from_dict(data, "test"))
	assert_false(_lib.check_references(_data))
	assert_false(_lib.has_species(&"missingno"), "espèce inconnue de PokemonData")
	assert_null(_lib.get_note(&"m"), "ses notes partent avec elle")
	assert_false(_lib.has_species(&"pidgey"), "n° 16 hors d'une grille de 10")
	assert_push_error_count(2)


func test_missing_file_and_bad_json() -> void:
	assert_false(_lib.load_file("res://tests/fixtures/pokedex/absent.json"))
	assert_push_error("fichier introuvable")


func test_forest_texts_are_the_locked_ones() -> void:
	# Lot de textes du jalon 9 (docs/design/textes/textes-brouillon-j9.md, verrouillé par
	# Kevin le 2026-10-07), n° 40 à 50, mot pour mot.
	_lib.load_file()
	var lot := FileAccess.get_file_as_string("res://docs/design/textes/textes-brouillon-j9.md")
	assert_false(lot.is_empty(), "lot de textes lisible")
	for id: StringName in [&"caterpie", &"metapod", &"butterfree", &"weedle", &"kakuna",
			&"beedrill", &"pikachu", &"raichu"]:
		var info := _lib.get_species(id)
		assert_not_null(info, String(id))
		if info == null:
			continue
		assert_true(lot.contains("« %s »" % info.description), "%s : description" % id)
		for note: PokedexNoteData in info.notes:
			assert_true(lot.contains("« %s »" % note.text), "%s : note" % note.id)
	var ids: Array[StringName] = []
	for id: StringName in [&"caterpie", &"weedle", &"pikachu"]:
		ids.append(_lib.get_notes(id)[0].id)
	assert_eq(ids, [&"caterpie_leaf", &"weedle_curl", &"pikachu_scorch"] as Array[StringName])
