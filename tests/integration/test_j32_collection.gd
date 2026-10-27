extends GutTest
## Jalon 32, voies de collection en données (N-11 à N-14, validés par Kevin le 2026-10-24) :
## Minidraco à la Super Canne du Parc Safari, Porygon de la Sylphe, échanges PNJ de Rouge/Bleu,
## Centrale (Élektek, Électhor ; la carte attend sa grille).

const TRADES := {
	&"route_2_trade_mr_mime": [&"route_2_east_gate", &"abra", &"mr_mime"],
	&"vermilion_trade_farfetchd": [&"vermilion_house_2", &"spearow", &"farfetchd"],
	&"route_18_trade_lickitung": [&"route_18_gate", &"slowbro", &"lickitung"],
	&"route_5_trade_nidoran_f": [&"route_5_underground_gate", &"nidoran_m", &"nidoran_f"],
	&"route_11_trade_nidorina": [&"route_12_gate_2f", &"nidorino", &"nidorina"],
	&"cerulean_trade_jynx": [&"cerulean_house", &"poliwhirl", &"jynx"],
}

var _data: PokemonData
var _cutscenes: CutsceneLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()


func test_new_species_follow_red_and_blue() -> void:
	for row: Array in [[&"electabuzz", 125, 45], [&"porygon", 137, 45], [&"zapdos", 145, 3],
			[&"dratini", 147, 45]]:
		var species := _data.get_species(row[0])
		assert_not_null(species, String(row[0]))
		assert_eq(species.dex, row[1], String(row[0]))
		assert_eq(species.catch_rate, row[2], String(row[0]))
	assert_eq(_data.get_species(&"zapdos").types, [&"electric", &"flying"] as Array[StringName])


func test_dratini_bites_the_super_rod_in_the_safari_zone_only() -> void:
	var tables := WaterRodTables.new()
	assert_true(tables.load_file())
	var safari := 0
	for id: StringName in tables.get_ids():
		var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/fishing/water_rod.json"))[String(id)]
		var species: Array = (json["slots"] as Array).map(func(s: Dictionary) -> String:
			return s["species"])
		if species.has("dratini"):
			safari += 1
			assert_eq(json["rod"], "super_rod", String(id))
			assert_eq(json["maps"], ["safari_zone_center", "safari_zone_east",
				"safari_zone_north", "safari_zone_west"])
			assert_eq(species, ["dratini", "krabby", "psyduck", "slowpoke"], "groupe 6 de RB")
	assert_eq(safari, 1)


func test_porygon_is_given_once_after_giovanni() -> void:
	var gift := _cutscenes.get_cutscene(&"silph_co_porygon_gift")
	assert_not_null(gift)
	var step: CutsceneStep = gift.variants[0].steps[0]
	assert_eq(step.kind, CutsceneStep.Kind.GIFT_POKEMON)
	assert_eq(step.species, &"porygon")
	assert_eq(gift.variants[0].unless_flags, [&"silph_porygon_received"] as Array[StringName])
	var spec := NpcRoster.load_for_map(&"silph_co_1f").get_spec(&"silph_co_porygon_giver")
	assert_not_null(spec)
	assert_eq(spec.if_flags, [&"silph_giovanni_defeated"] as Array[StringName])


func test_rb_trades_have_their_npc_and_scene() -> void:
	var trades := InGameTrade.load_default()
	assert_eq(trades.get_errors().size(), 0, str(trades.get_errors()))
	for id: StringName in TRADES:
		var row: Array = TRADES[id]
		var trade := trades.get_trade(id)
		assert_false(trade.is_empty(), String(id))
		assert_eq(StringName(str(trade["wants"])), row[1], String(id))
		assert_eq(StringName(str(trade["gives"])), row[2], String(id))
		assert_true(_data.has_species(row[1]) and _data.has_species(row[2]), String(id))
		var scene := StringName("j32_trade_" + str(trade["lines"]))
		assert_true(_cutscenes.has_cutscene(scene), String(scene))
		var spec := NpcRoster.load_for_map(row[0]).get_spec(StringName(str(trade["npc"])))
		assert_not_null(spec, "%s : PNJ sur %s" % [id, row[0]])
		if spec != null:
			assert_eq(spec.dialogue, scene, String(id))


func test_an_rb_trade_runs_like_the_cinnabar_ones() -> void:
	var trades := InGameTrade.load_default()
	var party := Party.new()
	party.add(PokemonFactory.create(_data, &"abra", 12, GameRng.new(1)))
	var flags := StoryFlags.new()
	var pokedex := Pokedex.new()
	var result := trades.execute(&"route_2_trade_mr_mime", 0, party, pokedex, flags, _data,
		GameRng.new(2))
	assert_eq(result["status"], InGameTrade.Status.DONE)
	assert_eq(party.get_at(0).species_id, &"mr_mime")
	assert_eq(party.get_at(0).level, 12)
	assert_true(pokedex.is_caught(&"mr_mime"))
	assert_true(flags.has_flag(&"route_2_trade_mr_mime_done"))


func test_power_plant_waits_for_its_map() -> void:
	var lib := EncounterLibrary.new(_data)
	lib.load_dir()
	var table := lib.get_table(&"power_plant", &"floor")
	assert_not_null(table)
	assert_gt(table.chance_of(&"electabuzz"), 0.0, "Élektek (Rouge)")
	assert_gt(table.chance_of(&"raichu"), 0.0, "Raichu (Bleu)")
	assert_gt(table.chance_of(&"magnemite"), 0.0)
	var zapdos: StaticEncounter = null
	for encounter: StaticEncounter in _cutscenes.get_static_encounters():
		if encounter.species == &"zapdos":
			zapdos = encounter
	assert_not_null(zapdos)
	assert_eq(zapdos.level, 50)
	assert_eq(zapdos.done_flag, &"zapdos_done")
	assert_false(MapCatalog.has_map(&"power_plant"), "retirer ce test quand la carte arrive")


func test_power_plant_grid_proposal_is_readable() -> void:
	# Lot 32G : proposition de grille (RB 1:1), à valider par Kevin avant toute carte.
	var plan := preload("res://tests/helpers/plan_grid.gd").new()
	assert_true(plan.load_file("res://tools/plans/power_plant.txt"), plan.error)
	assert_eq([plan.width, plan.height], [40, 36])
	assert_eq(plan.cell_of("zapdos"), Vector2i(4, 9))
	assert_eq(plan.attr("zapdos", "niveau"), "50")
	assert_eq(plan.cells_at("sortie_sud"), [Vector2i(4, 35), Vector2i(5, 35)] as Array[Vector2i])
	assert_true(plan.is_walkable(Vector2i(4, 34)))
