extends GutTest
## FishingRules et WaterRodTables (jalon 22 T3, §2.5, §2.6) : meilleure canne, chances de
## touche 100 / 50 / 75 %, table globale / par carte / par défaut, ordre des tirages, données.
## Les tables sont construites en mémoire : les espèces de pêche n'existent pas toutes encore
## (le test « aucune espèce sans données » viendra en T12).

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")

const DRAWS: int = 10000
## Tolérance des fréquences : ± 2 points de pourcentage.
const TOLERANCE: float = 0.02


func _dict() -> Dictionary:
	return {
		"old_any": {"maps": ["*"], "terrain": "water_rod", "rod": "old_rod", "rate": 100,
			"slots": [{"species": "magikarp", "level": 5, "weight": 1}]},
		"good_any": {"maps": ["*"], "terrain": "water_rod", "rod": "good_rod", "rate": 50,
			"slots": [{"species": "goldeen", "level": 10, "weight": 1},
				{"species": "poliwag", "level": 10, "weight": 1}]},
		"super_default": {"maps": ["*"], "default": true, "terrain": "water_rod",
			"rod": "super_rod", "rate": 75,
			"slots": [{"species": "krabby", "level": 15, "weight": 1},
				{"species": "magikarp", "level": 15, "weight": 1}]},
		"super_fuchsia": {"maps": ["fuchsia_city"], "terrain": "water_rod",
			"rod": "super_rod", "rate": 75,
			"slots": [{"species": "seaking", "level": 23, "weight": 1}]},
	}


func _tables() -> WaterRodTables:
	var tables := WaterRodTables.new()
	assert_true(tables.add_from_dict(_dict(), "test"), "tables de test valides")
	return tables


func _bag(items: Array[StringName]) -> Bag:
	var bag := Bag.new()
	for item: StringName in items:
		bag.add(item)
	return bag


# --- Meilleure canne ---------------------------------------------------------------------

func test_best_rod_without_rod_is_empty() -> void:
	assert_eq(FishingRules.best_rod(Bag.new()), &"")
	assert_eq(FishingRules.best_rod(_bag([&"potion", &"poke_ball"])), &"")
	assert_eq(FishingRules.best_rod(null), &"")


func test_best_rod_picks_the_best_owned() -> void:
	assert_eq(FishingRules.best_rod(_bag([&"old_rod"])), &"old_rod")
	assert_eq(FishingRules.best_rod(_bag([&"old_rod", &"good_rod"])), &"good_rod")
	# Chemin est : la Méga Canne avant la Super Canne (dossier 25 §7.1).
	assert_eq(FishingRules.best_rod(_bag([&"old_rod", &"super_rod"])), &"super_rod")
	assert_eq(FishingRules.best_rod(_bag([&"good_rod", &"super_rod", &"old_rod"])),
		&"super_rod")


func test_rod_removed_from_bag_no_longer_counts() -> void:
	var bag := _bag([&"old_rod", &"good_rod"])
	bag.remove(&"good_rod")
	assert_eq(FishingRules.best_rod(bag), &"old_rod")


# --- Chances de touche -------------------------------------------------------------------

func test_bite_chance_per_rod() -> void:
	assert_eq(FishingRules.bite_chance(&"old_rod"), 100)
	assert_eq(FishingRules.bite_chance(&"good_rod"), 50)
	assert_eq(FishingRules.bite_chance(&"super_rod"), 75)
	assert_eq(FishingRules.bite_chance(&""), 0)
	assert_eq(FishingRules.bite_chance(&"potion"), 0)


func test_old_rod_always_bites() -> void:
	assert_eq(_bites(&"old_rod", 11), DRAWS)


func test_good_rod_bites_half_the_time() -> void:
	assert_almost_eq(float(_bites(&"good_rod", 22)) / DRAWS, 0.50, TOLERANCE)


func test_super_rod_bites_three_times_in_four() -> void:
	assert_almost_eq(float(_bites(&"super_rod", 33)) / DRAWS, 0.75, TOLERANCE)


func _bites(rod: StringName, rng_seed: int) -> int:
	var tables := _tables()
	var rng := GameRng.new(rng_seed)
	var bites := 0
	for i: int in DRAWS:
		if FishingRules.roll(rng, tables, rod, &"route_12") != null:
			bites += 1
	return bites


# --- Tables ------------------------------------------------------------------------------

func test_old_and_good_rod_use_global_table_everywhere() -> void:
	var tables := _tables()
	for map: StringName in [&"route_12", &"fuchsia_city", &"vermilion_city"]:
		assert_eq(FishingRules.table_for(tables, &"old_rod", map).id, &"old_any")
		assert_eq(FishingRules.table_for(tables, &"good_rod", map).id, &"good_any")


func test_super_rod_uses_map_table_when_present() -> void:
	var table := FishingRules.table_for(_tables(), &"super_rod", &"fuchsia_city")
	assert_eq(table.id, &"super_fuchsia")
	assert_eq(table.terrain, WaterRodTables.TERRAIN)


func test_super_rod_falls_back_to_default_table() -> void:
	for map: StringName in [&"route_12", &"route_13", &"route_18", &"cerulean_city"]:
		assert_eq(FishingRules.table_for(_tables(), &"super_rod", map).id, &"super_default")


func test_no_rod_or_unknown_rod_has_no_table() -> void:
	var tables := _tables()
	assert_null(FishingRules.table_for(tables, &"", &"route_12"))
	assert_null(FishingRules.table_for(tables, &"potion", &"route_12"))
	assert_null(FishingRules.table_for(null, &"old_rod", &"route_12"))


func test_rod_without_table_gives_nothing() -> void:
	var tables := WaterRodTables.new()
	var rng := ScriptedRng.new([])
	assert_null(FishingRules.roll(rng, tables, &"old_rod", &"route_12"))
	assert_eq(rng.calls, 0, "aucun tirage sans table")


# --- Tirage ------------------------------------------------------------------------------

func test_no_rod_gives_nothing_without_drawing() -> void:
	var rng := ScriptedRng.new([])
	assert_null(FishingRules.roll(rng, _tables(), &"", &"route_12"))
	assert_eq(rng.calls, 0, "aucun tirage sans canne")


func test_roll_order_bite_then_pick() -> void:
	# chance(50, 100) avec 50 → touche ; roll(2) = 2 → poliwag ; range_int(10, 10) → roll(1).
	var rng := ScriptedRng.new([50, 2, 1])
	var encounter := FishingRules.roll(rng, _tables(), &"good_rod", &"route_12")
	assert_not_null(encounter)
	assert_eq(encounter.species, &"poliwag")
	assert_eq(encounter.level, 10)
	assert_eq(encounter.table_id, &"good_any")
	assert_eq(rng.remaining(), 0)


func test_no_bite_draws_only_once() -> void:
	# chance(75, 100) avec 76 → rien ne mord, pas d'autre tirage.
	var rng := ScriptedRng.new([76])
	assert_null(FishingRules.roll(rng, _tables(), &"super_rod", &"route_12"))
	assert_eq(rng.calls, 1)


func test_map_table_species_and_level() -> void:
	var rng := ScriptedRng.new([1, 1, 1])
	var encounter := FishingRules.roll(rng, _tables(), &"super_rod", &"fuchsia_city")
	assert_eq(encounter.species, &"seaking")
	assert_eq(encounter.level, 23)


# --- Données : data/fishing/water_rod.json -----------------------------------------------

func test_data_file_loads() -> void:
	var tables := WaterRodTables.new()
	assert_true(tables.load_file(), "water_rod.json valide")
	assert_eq(tables.get_errors().size(), 0)
	# Jalon 31 (T4) : Super Canne de la Grotte Azurée (groupe 9 de RB).
	assert_eq(tables.get_ids(), [&"good_rod_any", &"old_rod_any", &"super_rod_cerulean_cave",
		&"super_rod_default", &"super_rod_fuchsia"] as Array[StringName])


func test_data_rates_match_bite_chances() -> void:
	var tables := WaterRodTables.new()
	tables.load_file()
	for id: StringName in tables.get_ids():
		var rod := tables.rod_of(id)
		assert_true(FishingRules.RODS.has(rod), "%s : canne connue" % id)
		assert_eq(tables.bite_percent_of(id), FishingRules.bite_chance(rod),
			"%s : « rate » = chance de touche de la canne" % id)


func test_data_tables_by_rod_and_map() -> void:
	var tables := WaterRodTables.new()
	tables.load_file()
	var old := FishingRules.table_for(tables, &"old_rod", &"route_12")
	assert_eq(old.slots.size(), 1)
	assert_eq(old.slots[0].species, &"magikarp")
	assert_eq(old.slots[0].min_level, 5)
	assert_eq(FishingRules.table_for(tables, &"good_rod", &"fuchsia_city").id, &"good_rod_any")
	assert_eq(FishingRules.table_for(tables, &"super_rod", &"route_13").id,
		&"super_rod_default")
	assert_eq(FishingRules.table_for(tables, &"super_rod", &"fuchsia_city").id,
		&"super_rod_fuchsia")


# --- Validation du chargeur --------------------------------------------------------------

func test_unknown_rod_is_rejected() -> void:
	var dict := _dict()
	dict["old_any"]["rod"] = "net"
	var tables := WaterRodTables.new()
	assert_false(tables.add_from_dict(dict, "test"))
	assert_push_error("« rod »")


func test_wrong_terrain_is_rejected() -> void:
	var dict := _dict()
	dict["old_any"]["terrain"] = "grass"
	assert_false(WaterRodTables.new().add_from_dict(dict, "test"))
	assert_push_error("« terrain »")


func test_two_tables_for_same_map_and_rod_are_rejected() -> void:
	var dict := _dict()
	dict["old_bis"] = (dict["old_any"] as Dictionary).duplicate(true)
	var tables := WaterRodTables.new()
	assert_false(tables.add_from_dict(dict, "test"))
	assert_push_error("a déjà la table")


func test_default_needs_star_map() -> void:
	var dict := _dict()
	dict["super_fuchsia"]["default"] = true
	assert_false(WaterRodTables.new().add_from_dict(dict, "test"))
	assert_push_error("« default »")


func test_star_cannot_mix_with_maps() -> void:
	var dict := _dict()
	dict["old_any"]["maps"] = ["*", "route_12"]
	assert_false(WaterRodTables.new().add_from_dict(dict, "test"))
	assert_push_error("ne se mélange pas")


func test_rate_out_of_range_is_rejected() -> void:
	var dict := _dict()
	dict["old_any"]["rate"] = 101
	assert_false(WaterRodTables.new().add_from_dict(dict, "test"))
	assert_push_error("« rate »")
