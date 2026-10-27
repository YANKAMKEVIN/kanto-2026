extends GutTest
## Tables de rencontres du Parc Safari (J23, T13 ; dossier 26 §6.2, `jalon-23.md` §2.4) : une
## table d'herbe par zone, poids RB 20/20/15/10/10/10/5/5/4/1 (doublés, emplacements partagés à
## parts égales entre Rouge et Bleu, N-4), taux 30/256 sans montée, Insécateur et Scarabrute tous
## les deux présents, espèces existantes ; cartes listées par `data/safari/safari.json`.

const ZONES: Array[StringName] = [
	&"safari_zone_center", &"safari_zone_east", &"safari_zone_north", &"safari_zone_west",
]
## Poids RB des dix emplacements, dans l'ordre.
const RB_WEIGHTS: Array[int] = [20, 20, 15, 10, 10, 10, 5, 5, 4, 1]
## Tables RB (dossier 26 §6.2) : par emplacement, les espèces (partagées) et le niveau.
const RB_TABLES: Dictionary = {
	&"safari_zone_center": [
		[["nidoran_m", "nidoran_f"], 22], [["rhyhorn"], 25], [["venonat"], 22],
		[["exeggcute"], 24], [["nidorino", "nidorina"], 31], [["exeggcute"], 25],
		[["nidorina", "nidorino"], 31], [["parasect"], 30], [["scyther", "pinsir"], 23],
		[["chansey"], 23],
	],
	&"safari_zone_east": [
		[["nidoran_m", "nidoran_f"], 24], [["doduo"], 26], [["paras"], 22],
		[["exeggcute"], 25], [["nidorino", "nidorina"], 33], [["exeggcute"], 23],
		[["nidoran_f", "nidoran_m"], 24], [["parasect"], 25], [["kangaskhan"], 25],
		[["scyther", "pinsir"], 28],
	],
	&"safari_zone_north": [
		[["nidoran_m", "nidoran_f"], 22], [["rhyhorn"], 26], [["paras"], 23],
		[["exeggcute"], 25], [["nidorino", "nidorina"], 30], [["exeggcute"], 27],
		[["nidorina", "nidorino"], 30], [["venomoth"], 32], [["chansey"], 26],
		[["tauros"], 28],
	],
	&"safari_zone_west": [
		[["nidoran_m", "nidoran_f"], 25], [["doduo"], 26], [["venonat"], 23],
		[["exeggcute"], 24], [["nidorino", "nidorina"], 33], [["exeggcute"], 26],
		[["nidoran_f", "nidoran_m"], 25], [["venomoth"], 31], [["tauros"], 26],
		[["kangaskhan"], 28],
	],
}

var _data: PokemonData
var _lib: EncounterLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_lib = EncounterLibrary.new(_data)
	_lib.load_dir()


func test_real_encounters_load_without_error() -> void:
	assert_eq(_lib.get_errors().size(), 0, "\n".join(_lib.get_errors()))


func test_one_grass_table_per_zone_at_the_rb_rate_without_ramp() -> void:
	for zone: StringName in ZONES:
		var table := _lib.get_table(zone, &"grass")
		assert_not_null(table, String(zone))
		if table == null:
			continue
		assert_eq(table.rate, 30, "%s : 30/256 par pas" % zone)
		assert_eq(table.ramp_from, 0, "%s : sans montée" % zone)
		assert_eq(table.ramp_max, 0, "%s : sans montée" % zone)
		assert_eq(table.ghost_unless_item, &"", String(zone))


func test_tables_follow_rb_weights_levels_and_version_sharing() -> void:
	for zone: StringName in ZONES:
		var table := _lib.get_table(zone, &"grass")
		if table == null:
			fail_test(String(zone))
			continue
		var expected: Dictionary = {}
		var total := 0
		for i: int in RB_WEIGHTS.size():
			var slot: Array = RB_TABLES[zone][i]
			var species: Array = slot[0]
			for id: String in species:
				var key := "%s:%d" % [id, slot[1]]
				expected[key] = int(expected.get(key, 0)) + RB_WEIGHTS[i] * 2 / species.size()
			total += RB_WEIGHTS[i] * 2
		var actual: Dictionary = {}
		var actual_total := 0
		for slot: EncounterSlot in table.slots:
			assert_eq(slot.min_level, slot.max_level, "%s : niveau fixe (RB)" % zone)
			var key := "%s:%d" % [slot.species, slot.min_level]
			actual[key] = int(actual.get(key, 0)) + slot.weight
			actual_total += slot.weight
		assert_eq(actual_total, total, "%s : poids RB ×2" % zone)
		assert_eq(actual, expected, "%s : espèces, niveaux, poids" % zone)


func test_scyther_and_pinsir_are_both_present() -> void:
	var found: Dictionary = {}
	for zone: StringName in ZONES:
		var table := _lib.get_table(zone, &"grass")
		if table == null:
			continue
		for slot: EncounterSlot in table.slots:
			found[slot.species] = true
	for id: StringName in [&"scyther", &"pinsir", &"chansey", &"tauros", &"kangaskhan"]:
		assert_true(found.has(id), "%s rencontrable dans le Parc" % id)


func test_every_species_exists() -> void:
	for zone: StringName in ZONES:
		var table := _lib.get_table(zone, &"grass")
		if table == null:
			continue
		for slot: EncounterSlot in table.slots:
			assert_not_null(_data.get_species(slot.species), String(slot.species))


func test_new_park_species_have_one_observation_note() -> void:
	var dex := PokedexLibrary.new()
	dex.load_file()
	var pokedex := Pokedex.new()
	for id: StringName in [&"chansey", &"scyther", &"pinsir", &"tauros"]:
		pokedex.mark_seen(id)
	var unlocked := PokedexNotes.refresh(pokedex, dex, StoryFlags.new())
	assert_eq(unlocked.size(), 4, "Q-6 : une note par forme de base du Parc, au premier regard")


func test_the_park_maps_are_safari_maps() -> void:
	var config := SafariConfig.load_default()
	for zone: StringName in ZONES:
		assert_true(config.is_safari_map(zone), String(zone))
