extends GutTest
## Tables de rencontres de la Tour Pokémon (jalon 19, T5 ; dossier 22 §5, `jalon-19.md` §2.2) :
## terrain « floor », clé « ghost_unless_item » = « silph_scope », taux RB 10 / 10 / 15, poids
## RB sur 256, [b]sans « ramp »[/b] (K-10), aucune table pour le 2F ni le 7F.
##
## Les espèces (gastly, haunter, cubone) arrivent par T3, en parallèle. Tant qu'elles manquent,
## le fichier attend dans `data/encounters/pending/` (non lu par [method EncounterLibrary.load_dir])
## et ce test le lit avec des espèces de test aux mêmes identifiants. Dès que les espèces
## existent, [method test_file_leaves_pending_once_species_exist] exige le déplacement.

const FINAL_PATH: String = "res://data/encounters/pokemon_tower.json"
const PENDING_PATH: String = "res://data/encounters/pending/pokemon_tower.json"
const TOWER_SPECIES: Array[StringName] = [&"gastly", &"haunter", &"cubone"]
## Identifiant → numéro, pour les espèces de test (seulement si T3 n'est pas encore là).
const _STUB_DEX: Dictionary = { &"gastly": 92, &"haunter": 93, &"cubone": 104 }

## Table → [taux, cartes, { espèce: [min, max, poids] }] (dossier 22 §5).
const EXPECTED: Dictionary = {
	&"pokemon_tower_low": [10, [&"pokemon_tower_3f"], {
		&"gastly": [18, 24, 229], &"haunter": [25, 25, 3], &"cubone": [20, 22, 24]}],
	&"pokemon_tower_mid": [10, [&"pokemon_tower_4f", &"pokemon_tower_5f"], {
		&"gastly": [18, 24, 219], &"haunter": [25, 25, 13], &"cubone": [20, 22, 24]}],
	&"pokemon_tower_high": [15, [&"pokemon_tower_6f"], {
		&"gastly": [19, 24, 216], &"haunter": [26, 28, 16], &"cubone": [22, 24, 24]}],
}

var _data: PokemonData
var _species_ready: bool = false
var _lib: EncounterLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_species_ready = TOWER_SPECIES.all(func(id: StringName) -> bool:
		return _data.has_species(id))
	if not _species_ready:
		_add_stub_species()
	_lib = EncounterLibrary.new(_data)
	_lib.load_file(_path())


func _path() -> String:
	return FINAL_PATH if FileAccess.file_exists(FINAL_PATH) else PENDING_PATH


func _add_stub_species() -> void:
	var stubs := {}
	for id: StringName in TOWER_SPECIES:
		if _data.has_species(id):
			continue
		stubs[String(id)] = {
			"dex": _STUB_DEX[id], "name": String(id), "types": ["ghost"],
			"base_stats": { "hp": 30, "atk": 35, "def": 30, "spa": 100, "spd": 35, "spe": 80 },
			"male_ratio": 0.5, "growth_rate": "medium_slow", "base_exp": 95,
			"catch_rate": 190, "learnset": [[1, "tackle"]],
		}
	assert_true(_data.add_species_from_dict(stubs, "espèces de test"),
		"\n".join(_data.get_errors()))


func test_file_loads_without_error() -> void:
	assert_true(FileAccess.file_exists(_path()), _path())
	assert_eq(_lib.get_errors().size(), 0, "\n".join(_lib.get_errors()))
	assert_eq(_lib.get_ids(), [&"pokemon_tower_high", &"pokemon_tower_low",
		&"pokemon_tower_mid"] as Array[StringName])


func test_file_leaves_pending_once_species_exist() -> void:
	if not _species_ready:
		pass_test("T3 pas encore fusionné : le fichier attend dans data/encounters/pending/")
		return
	assert_false(FileAccess.file_exists(PENDING_PATH),
		"les espèces de la Tour existent : déplacer %s dans data/encounters/ (LISEZ-MOI)"
		% PENDING_PATH)
	assert_true(FileAccess.file_exists(FINAL_PATH))


func test_tables_follow_the_dossier() -> void:
	for id: StringName in EXPECTED:
		var expected: Array = EXPECTED[id]
		var table := _lib.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		assert_eq(table.terrain, &"floor", String(id))
		assert_eq(table.ghost_unless_item, &"silph_scope", String(id))
		assert_eq(table.rate, expected[0], "%s : taux RB" % id)
		assert_eq(str(table.maps), str(expected[1]), String(id))
		assert_eq(table.total_weight(), 256, "%s : poids sur 256" % id)
		var slots: Dictionary = expected[2]
		assert_eq(table.slots.size(), slots.size(), String(id))
		for slot: EncounterSlot in table.slots:
			assert_true(slots.has(slot.species), "%s : %s hors du bestiaire" % [id, slot.species])
			if slots.has(slot.species):
				assert_eq([slot.min_level, slot.max_level, slot.weight], slots[slot.species],
					"%s : %s" % [id, slot.species])


func test_no_ramp_rb_rate() -> void:
	for id: StringName in _lib.get_ids():
		var table := _lib.get_table_by_id(id)
		assert_false(table.has_ramp(), "%s : pas de montée (K-10)" % id)
		assert_eq(table.effective_rate(40), table.rate, "%s : taux fixe" % id)


func test_no_table_for_the_2f_nor_the_7f() -> void:
	for map: StringName in [&"pokemon_tower_1f", &"pokemon_tower_2f", &"pokemon_tower_7f"]:
		for terrain: StringName in EncounterTable.TERRAINS:
			assert_false(_lib.has_table(map, terrain), "%s (%s)" % [map, terrain])
	for map: StringName in [&"pokemon_tower_3f", &"pokemon_tower_4f", &"pokemon_tower_5f",
			&"pokemon_tower_6f"]:
		assert_true(_lib.has_table(map, &"floor"), String(map))
		assert_false(_lib.has_table(map, &"grass"), "%s : sol seulement" % map)


func test_relative_frequencies_over_ten_thousand_picks() -> void:
	# Graine fixe : ≈ 89 %, 86 %, 84 % de Fantominus (229, 219, 216 sur 256).
	var expected := { &"pokemon_tower_low": 229.0 / 256.0,
		&"pokemon_tower_mid": 219.0 / 256.0, &"pokemon_tower_high": 216.0 / 256.0 }
	for id: StringName in expected:
		var table := _lib.get_table_by_id(id)
		if table == null:
			fail_test(String(id))
			continue
		var rng := GameRng.new(1919)
		var gastly := 0
		var ghosts := 0
		for i: int in 10000:
			var encounter := table.pick(rng)
			if encounter.species == &"gastly":
				gastly += 1
			if encounter.ghost:
				ghosts += 1
		assert_eq(ghosts, 0, "le tirage ne décide pas du SPECTRE")
		assert_almost_eq(gastly / 10000.0, float(expected[id]), 0.015, String(id))


func test_every_tower_encounter_is_a_ghost_without_the_scope() -> void:
	var bag := Bag.new()
	bag.add(&"poke_ball", 10)
	for id: StringName in _lib.get_ids():
		var item := _lib.get_table_by_id(id).ghost_unless_item
		assert_true(GhostRule.is_ghost(item, bag), String(id))
	bag.add(&"silph_scope")
	for id: StringName in _lib.get_ids():
		var item := _lib.get_table_by_id(id).ghost_unless_item
		assert_false(GhostRule.is_ghost(item, bag), String(id))
