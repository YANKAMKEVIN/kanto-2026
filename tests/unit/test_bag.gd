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
	var dict := bag.to_dict()
	assert_eq(dict, {"poke_ball": 5, "potion": 1})
	var copy := Bag.new()
	assert_true(copy.load_dict(JSON.parse_string(JSON.stringify(dict))))
	assert_eq(copy.to_dict(), dict, "aussi après un passage par le JSON (nombres flottants)")


func test_load_dict_drops_invalid_entries() -> void:
	var bag := Bag.new()
	bag.add(&"old", 3)
	assert_false(bag.load_dict({"poke_ball": 5, "bad": 0, "worse": "x", "half": 1.5}))
	assert_push_error_count(3)
	assert_eq(bag.to_dict(), {"poke_ball": 5}, "le contenu est remplacé, les bonnes gardées")
