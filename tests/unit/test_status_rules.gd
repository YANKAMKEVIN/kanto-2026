extends GutTest
## StatusRules (jalon 9 §2.1.1) : vocabulaire des statuts. Les règles du poison (T4) auront
## leurs tests ici.


func test_poison_is_the_only_known_status_at_j9() -> void:
	assert_eq(StatusRules.KNOWN, [&"poison"] as Array[StringName])
	assert_eq(StatusRules.POISON, &"poison")
	assert_eq(StatusRules.NONE, &"")


func test_is_known() -> void:
	assert_true(StatusRules.is_known(&"poison"))
	assert_false(StatusRules.is_known(StatusRules.NONE), "« aucun » n'est pas un statut")
	assert_false(StatusRules.is_known(&"paralysis"), "paralysie : J11")
