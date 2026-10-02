extends GutTest
## Bag (jalon-04.md §14.6) : ajout, retrait, quantités, ordre, aller-retour de sauvegarde.


func test_starts_empty() -> void:
	var bag := Bag.new()
	assert_true(bag.is_empty())
	assert_eq(bag.count_of(&"poke_ball"), 0)
	assert_false(bag.has(&"poke_ball"))
	assert_eq(bag.get_ids(), [] as Array[StringName])


func test_add_accumulates() -> void:
	var bag := Bag.new()
	assert_true(bag.add(&"poke_ball", 5))
	assert_true(bag.add(&"poke_ball"))
	assert_eq(bag.count_of(&"poke_ball"), 6)
	assert_true(bag.has(&"poke_ball"))
	assert_false(bag.is_empty())


func test_add_refuses_empty_id_and_non_positive_count() -> void:
	var bag := Bag.new()
	assert_false(bag.add(&"", 1))
	assert_false(bag.add(&"poke_ball", 0))
	assert_false(bag.add(&"poke_ball", -3))
	assert_true(bag.is_empty())


func test_remove() -> void:
	var bag := Bag.new()
	bag.add(&"poke_ball", 5)
	assert_true(bag.remove(&"poke_ball"))
	assert_eq(bag.count_of(&"poke_ball"), 4)
	assert_false(bag.remove(&"poke_ball", 5), "pas assez")
	assert_eq(bag.count_of(&"poke_ball"), 4, "rien ne change")
	assert_false(bag.remove(&"poke_ball", 0))
	assert_false(bag.remove(&"potion"))
	assert_true(bag.remove(&"poke_ball", 4))
	assert_false(bag.has(&"poke_ball"))
	assert_true(bag.is_empty(), "un objet à 0 disparaît")


func test_ids_are_sorted() -> void:
	var bag := Bag.new()
	bag.add(&"potion")
	bag.add(&"great_ball", 2)
	bag.add(&"poke_ball", 5)
	assert_eq(bag.get_ids(), [&"great_ball", &"poke_ball", &"potion"] as Array[StringName])


func test_clear() -> void:
	var bag := Bag.new()
	bag.add(&"poke_ball", 5)
	bag.clear()
	assert_true(bag.is_empty())


func test_dict_round_trip() -> void:
	var bag := Bag.new()
	bag.add(&"poke_ball", 5)
	bag.add(&"potion", 1)
	bag.set_favorite(&"potion", true)
	var dict := bag.to_dict()
	assert_eq(dict, {
		"items": {"poke_ball": 5, "potion": 1},
		"favorites": ["potion"],
		"acquired": {"poke_ball": 1, "potion": 2},
	}, "forme v2 de la sauvegarde (jalon-06.md §5.1)")
	var copy := Bag.new()
	assert_true(copy.load_dict(JSON.parse_string(JSON.stringify(dict))))
	assert_eq(copy.to_dict(), dict, "aussi après un passage par le JSON (nombres flottants)")


func test_load_dict_drops_invalid_entries() -> void:
	var bag := Bag.new()
	bag.add(&"old", 3)
	assert_false(bag.load_dict({"items": {"poke_ball": 5, "bad": 0, "worse": "x", "half": 1.5}}))
	assert_push_error_count(3)
	assert_eq(bag.to_dict()["items"], {"poke_ball": 5},
		"le contenu est remplacé, les bonnes gardées")
	assert_eq(bag.acquired_rank(&"old"), 0, "l'ancien contenu est oublié")


# --- Forme v2 (jalon 6, T0) : favoris et ordre d'obtention ------------------------------------

func test_the_old_flat_shape_is_still_read() -> void:
	# Sac d'une sauvegarde v1 (jalon 5) : { objet → quantité }.
	var bag := Bag.new()
	assert_true(bag.load_dict({"potion": 1.0, "poke_ball": 3.0}))
	assert_eq(bag.count_of(&"poke_ball"), 3)
	assert_eq(bag.count_of(&"potion"), 1)
	assert_eq(bag.favorite_ids(), [] as Array[StringName], "aucun favori")
	assert_eq([bag.acquired_rank(&"poke_ball"), bag.acquired_rank(&"potion")], [1, 2],
		"ordre d'obtention alphabétique (la v1 ne le connaissait pas)")


func test_the_old_flat_shape_still_drops_invalid_entries() -> void:
	var bag := Bag.new()
	assert_false(bag.load_dict({"poke_ball": 5, "bad": 0, "worse": "x"}))
	assert_push_error_count(2)
	assert_eq(bag.to_dict(), {"items": {"poke_ball": 5}, "favorites": [],
		"acquired": {"poke_ball": 1}}, "seules les quantités valides reçoivent un rang")


func test_upgrade_flat_is_the_v2_shape_with_alphabetical_ranks() -> void:
	assert_eq(Bag.upgrade_flat({"potion": 1, "poke_ball": 4}), {
		"items": {"potion": 1, "poke_ball": 4}, "favorites": [],
		"acquired": {"poke_ball": 1, "potion": 2},
	})
	assert_eq(Bag.upgrade_flat({}), {"items": {}, "favorites": [], "acquired": {}})


func test_each_acquisition_makes_the_item_the_most_recent() -> void:
	var bag := Bag.new()
	assert_eq(bag.acquired_rank(&"potion"), 0, "jamais obtenu")
	bag.add(&"poke_ball", 5)
	bag.add(&"potion")
	assert_gt(bag.acquired_rank(&"potion"), bag.acquired_rank(&"poke_ball"))
	bag.add(&"poke_ball")
	assert_gt(bag.acquired_rank(&"poke_ball"), bag.acquired_rank(&"potion"), "racheté : récent")
	assert_false(bag.add(&"potion", 0))
	assert_gt(bag.acquired_rank(&"poke_ball"), bag.acquired_rank(&"potion"),
		"un ajout refusé ne change rien")


func test_favorites_are_kept_in_order_and_survive_an_empty_stack() -> void:
	var bag := Bag.new()
	bag.add(&"potion", 1)
	bag.add(&"poke_ball", 2)
	assert_true(bag.set_favorite(&"potion", true))
	assert_true(bag.set_favorite(&"poke_ball", true))
	assert_false(bag.set_favorite(&"potion", true), "déjà favori : rien ne change")
	assert_false(bag.set_favorite(&"", true))
	assert_eq(bag.favorite_ids(), [&"potion", &"poke_ball"] as Array[StringName])
	assert_true(bag.remove(&"potion"))
	assert_false(bag.has(&"potion"))
	assert_true(bag.is_favorite(&"potion"), "retiré à 0 : reste favori")
	assert_gt(bag.acquired_rank(&"potion"), 0, "et garde son rang")
	assert_true(bag.set_favorite(&"potion", false))
	assert_eq(bag.favorite_ids(), [&"poke_ball"] as Array[StringName])
	bag.clear()
	assert_eq(bag.favorite_ids(), [] as Array[StringName], "nouvelle partie : plus de favoris")
	assert_eq(bag.acquired_rank(&"poke_ball"), 0)


func test_v2_round_trip_keeps_a_favorite_absent_from_the_bag() -> void:
	var bag := Bag.new()
	bag.add(&"potion")
	bag.set_favorite(&"potion", true)
	bag.remove(&"potion")
	var copy := Bag.new()
	assert_true(copy.load_dict(JSON.parse_string(JSON.stringify(bag.to_dict()))))
	assert_true(copy.is_empty())
	assert_true(copy.is_favorite(&"potion"))
	assert_eq(copy.acquired_rank(&"potion"), 1)


func test_malformed_favorites_and_ranks_are_ignored_without_error() -> void:
	var bag := Bag.new()
	assert_true(bag.load_dict({"items": {"potion": 1, "poke_ball": 2},
		"favorites": "potion", "acquired": {"potion": "deux", "": 3, "poke_ball": -1}}))
	assert_eq(bag.favorite_ids(), [] as Array[StringName])
	assert_eq([bag.acquired_rank(&"poke_ball"), bag.acquired_rank(&"potion")], [1, 2],
		"objet présent sans rang valide : rang après les autres, ordre alphabétique")
	assert_true(bag.load_dict({"items": {"potion": 1}, "favorites": [3, "", "potion", "potion"],
		"acquired": {"potion": 7}}))
	assert_eq(bag.favorite_ids(), [&"potion"] as Array[StringName], "doublons écartés")
	assert_eq(bag.acquired_rank(&"potion"), 7)


func test_items_that_are_not_an_object_are_an_error() -> void:
	var bag := Bag.new()
	assert_false(bag.load_dict({"items": [1, 2]}))
	assert_push_error_count(1)
	assert_true(bag.is_empty())
