extends GutTest
## Pokedex : espèces vues et capturées (jalon 5, décision de Kevin 2026-09-29). Données
## collectées dès le jalon 5, sérialisées pour la sauvegarde ; l'écran arrive au jalon 6.

var _dex: Pokedex


func before_each() -> void:
	_dex = Pokedex.new()


func test_new_pokedex_is_empty() -> void:
	assert_eq(_dex.seen_count(), 0)
	assert_eq(_dex.caught_count(), 0)
	assert_false(_dex.is_seen(&"pidgey"))
	assert_false(_dex.is_caught(&"pidgey"))


func test_mark_seen_is_true_only_the_first_time() -> void:
	assert_true(_dex.mark_seen(&"pidgey"), "première fois")
	assert_false(_dex.mark_seen(&"pidgey"), "déjà vue")
	assert_true(_dex.is_seen(&"pidgey"))
	assert_false(_dex.is_caught(&"pidgey"))
	assert_eq(_dex.seen_count(), 1)


func test_mark_caught_implies_seen() -> void:
	assert_true(_dex.mark_caught(&"rattata"), "première capture")
	assert_true(_dex.is_seen(&"rattata"), "capturer implique voir")
	assert_true(_dex.is_caught(&"rattata"))
	assert_eq(_dex.seen_count(), 1)
	assert_eq(_dex.caught_count(), 1)


func test_mark_caught_is_true_only_the_first_capture() -> void:
	_dex.mark_seen(&"rattata")
	assert_true(_dex.mark_caught(&"rattata"), "première capture d'une espèce déjà vue")
	assert_false(_dex.mark_caught(&"rattata"), "déjà capturée")


func test_empty_species_is_ignored() -> void:
	assert_false(_dex.mark_seen(&""))
	assert_false(_dex.mark_caught(&""))
	assert_eq(_dex.seen_count(), 0)


func test_ids_are_sorted() -> void:
	_dex.mark_seen(&"rattata")
	_dex.mark_seen(&"pidgey")
	_dex.mark_caught(&"charmander")
	assert_eq(_dex.seen_ids(), [&"charmander", &"pidgey", &"rattata"] as Array[StringName])
	assert_eq(_dex.caught_ids(), [&"charmander"] as Array[StringName])


func test_clear_empties_everything() -> void:
	_dex.mark_caught(&"pidgey")
	_dex.clear()
	assert_eq(_dex.seen_count(), 0)
	assert_eq(_dex.caught_count(), 0)


func test_to_dict_and_from_dict_round_trip() -> void:
	_dex.mark_seen(&"pidgey")
	_dex.mark_seen(&"rattata")
	_dex.mark_caught(&"rattata")
	var dict := _dex.to_dict()
	assert_eq(dict["seen"], ["pidgey", "rattata"])
	assert_eq(dict["caught"], ["rattata"])
	var loaded := Pokedex.new()
	assert_true(loaded.from_dict(dict))
	assert_true(loaded.is_seen(&"pidgey"))
	assert_true(loaded.is_caught(&"rattata"))
	assert_true(loaded.is_seen(&"rattata"))
	assert_eq(loaded.seen_count(), 2)
	assert_eq(loaded.caught_count(), 1)


func test_from_dict_marks_caught_as_seen_even_when_seen_omits_it() -> void:
	var loaded := Pokedex.new()
	assert_true(loaded.from_dict({"seen": [], "caught": ["pidgey"]}))
	assert_true(loaded.is_seen(&"pidgey"), "capturé sans être listé vu → vu quand même")
	assert_true(loaded.is_caught(&"pidgey"))


func test_from_dict_discards_invalid_entries() -> void:
	var loaded := Pokedex.new()
	assert_false(loaded.from_dict({"seen": [42, ""], "caught": "pas une liste"}))
	assert_eq(loaded.seen_count(), 0)
	# 42 écarté, "" écarté, « caught » n'est pas une liste : trois push_error attendus.
	assert_push_error_count(3)
