extends GutTest
## Table de rencontres du 7F de la Tour Pokémon (jalon 21, T5 ; jalon-21.md §2.8, §0.4 n° 4) :
## poids RB (PokemonTower7F.asm : Fantominus 191 N20–24, Spectrum 39 N28–30, Osselait 26
## N22–24), taux 15, terrain « floor », « ghost_unless_item » = « silph_scope », sans « ramp ».
##
## Dépend du J19 (espèces de la Tour, terrain « floor », clé « ghost_unless_item ») : ne passe
## qu'après la fusion de main (T9).

const PATH: String = "res://data/encounters/pokemon_tower_7f.json"
const SLOTS: Dictionary = {
	&"gastly": [20, 24, 191], &"haunter": [28, 30, 39], &"cubone": [22, 24, 26],
}

var _lib: EncounterLibrary


func before_all() -> void:
	var data := PokemonData.new()
	data.load_dir()
	_lib = EncounterLibrary.new(data)
	_lib.load_file(PATH)


func test_file_loads_without_error() -> void:
	assert_eq(_lib.get_errors().size(), 0, "\n".join(_lib.get_errors()))
	assert_eq(_lib.get_ids(), [&"pokemon_tower_top"] as Array[StringName])


func test_table_follows_red_blue() -> void:
	var table := _lib.get_table_by_id(&"pokemon_tower_top")
	assert_not_null(table)
	if table == null:
		return
	assert_eq(table.terrain, &"floor")
	assert_eq(table.ghost_unless_item, &"silph_scope")
	assert_eq(table.rate, 15)
	assert_eq(str(table.maps), str([&"pokemon_tower_7f"]))
	assert_eq(table.total_weight(), 256)
	assert_false(table.has_ramp(), "pas de montée (règle du J19)")
	assert_eq(table.slots.size(), SLOTS.size())
	for slot: EncounterSlot in table.slots:
		assert_true(SLOTS.has(slot.species), String(slot.species))
		if SLOTS.has(slot.species):
			assert_eq([slot.min_level, slot.max_level, slot.weight], SLOTS[slot.species],
				String(slot.species))
