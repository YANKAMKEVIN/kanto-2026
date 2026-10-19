extends GutTest
## CS (jalon 17, T2 ; `jalon-17.md` §2.7) : interface partagée avec le J16, code repris tel quel
## de la branche du J16 (`ItemData.hm_number`, `ItemLibrary` « hm », `PokemonData.can_learn_hm`,
## `TmTeach`). Ce fichier ne dépend d'aucun objet CS des données (la CS01 est au J16, la CS05 au
## T7) : objets construits par le test, compatibilités lues dans le vrai fichier généré.


var _data: PokemonData


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))


func _hm_entry(number: int, teaches: String = "thunder_shock") -> Dictionary:
	return {"name": "CS%02d" % number, "plural": "CS%02d" % number, "feminine": true,
		"category": "tm", "hm": number, "teaches": teaches, "description": "x"}


func _mon(species: StringName, level: int = 20) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(7))


## Les cinq CS de Rouge/Bleu : Coupe, Vol, Surf, Force, Flash (machines 101 à 105 de PokeAPI).
func test_generated_file_has_five_hms() -> void:
	assert_eq([_data.hm_move(1), _data.hm_move(2), _data.hm_move(3), _data.hm_move(4),
		_data.hm_move(5)], [&"cut", &"fly", &"surf", &"strength", &"flash"])
	assert_eq(_data.hm_move(6), &"")
	assert_eq(_data.hm_move(0), &"")


## CS05 Flash (Rouge/Bleu) : Pikachu, Mélofée, Abra, Stari… compatibles ; Rattata, Carapuce,
## Salamèche, Bulbizarre non.
func test_flash_compatibilities() -> void:
	for species: StringName in [&"pikachu", &"raichu", &"clefairy", &"jigglypuff", &"abra",
			&"voltorb", &"staryu"]:
		assert_true(_data.can_learn_hm(species, 5), "%s peut apprendre Flash" % species)
	for species: StringName in [&"rattata", &"squirtle", &"charmander", &"bulbasaur",
			&"pidgey"]:
		assert_false(_data.can_learn_hm(species, 5), "%s ne peut pas apprendre Flash" % species)
	assert_false(_data.can_learn_hm(&"pikachu", 0), "numéro 0 : jamais")
	assert_false(_data.can_learn_hm(&"missingno", 5), "espèce inconnue : jamais")


## Les clés « hms » et « hm_species » sont facultatives ; les numéros des CT ne se mélangent pas
## avec ceux des CS.
func test_hm_keys_are_optional_and_separate() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir(), "\n".join(data.get_errors()))
	assert_true(data.add_tm_from_dict({"tms": {}, "species": {}}, "test"), "sans CS")
	assert_true(data.add_tm_from_dict({"hms": {"05": "flash"}, "hm_species": {"rattata": [5]}},
		"test"))
	assert_true(data.can_learn_hm(&"rattata", 5))
	assert_eq(data.can_learn_tm(&"rattata", 5), _data.can_learn_tm(&"rattata", 5),
		"la CS05 ne touche pas la CT05")
	assert_false(data.add_tm_from_dict({"hms": {"06": "x"}}, "test"), "CS de 1 à 5")
	assert_false(data.add_tm_from_dict({"hm_species": {"rattata": [9]}}, "test"),
		"numéro de CS inconnu")
	assert_false(data.add_tm_from_dict({"hm_species": {"nobody": [5]}}, "test"),
		"espèce inconnue")
	assert_push_error_count(3)


func test_item_library_reads_an_hm() -> void:
	var lib := ItemLibrary.new()
	assert_true(lib.add_from_dict({"cs": _hm_entry(5)}, "test"), "\n".join(lib.get_errors()))
	var hm := lib.get_item(&"cs")
	assert_eq([hm.category, hm.hm_number, hm.tm_number, hm.teaches],
		[ItemData.Category.TM, 5, 0, &"thunder_shock"])
	assert_true(hm.is_tm(), "rangée avec les CT")
	assert_true(hm.is_hm())
	assert_true(hm.is_permanent(), "jamais consommée")
	assert_false(hm.is_sellable(), "jamais vendue")
	assert_eq(lib.get_hm(5), &"cs")
	assert_eq(lib.get_tm(5), &"", "la CS05 n'occupe pas le numéro de la CT05")
	assert_eq(lib.get_hm(4), &"")


func test_item_library_rejects_bad_hms() -> void:
	var lib := ItemLibrary.new()
	var both := _hm_entry(1)
	both["tm"] = 1
	assert_false(lib.add_from_dict({"a": both}, "test"), "« tm » et « hm » exclusifs")
	assert_false(lib.add_from_dict({"b": _hm_entry(6)}, "test"), "CS de 1 à 5")
	assert_false(lib.add_from_dict({"c": _hm_entry(0)}, "test"), "CS de 1 à 5")
	var priced := _hm_entry(2)
	priced["price"] = 100
	assert_false(lib.add_from_dict({"d": priced}, "test"), "une CS n'a pas de prix")
	var no_move := _hm_entry(3)
	no_move.erase("teaches")
	assert_false(lib.add_from_dict({"e": no_move}, "test"), "une CS enseigne une capacité")
	var on_potion := {"name": "P", "plural": "P", "feminine": true, "category": "heal",
		"heal_amount": 20, "hm": 1, "description": "x"}
	assert_false(lib.add_from_dict({"f": on_potion}, "test"), "« hm » réservé aux CT")
	assert_true(lib.add_from_dict({"g": _hm_entry(5)}, "test"))
	assert_false(lib.add_from_dict({"h": _hm_entry(5)}, "test"), "numéro de CS unique")
	assert_eq(lib.get_hm(5), &"g")
	assert_push_error_count(7, "une erreur par entrée refusée")


## TmTeach : une CS s'apprend comme une CT, compatibilité lue dans « hm_species ».
func test_teach_reads_hm_compatibility() -> void:
	var lib := ItemLibrary.new()
	assert_true(lib.add_from_dict({"cs": _hm_entry(5)}, "test"))
	var hm := lib.get_item(&"cs")
	assert_eq(TmTeach.check(_mon(&"clefairy"), hm, _data), TmTeach.Check.COMPATIBLE,
		"Mélofée compatible CS05")
	assert_eq(TmTeach.check(_mon(&"rattata"), hm, _data), TmTeach.Check.INCOMPATIBLE)
	assert_eq(TmTeach.check(_mon(&"pikachu"), hm, _data), TmTeach.Check.KNOWN,
		"Pikachu connaît déjà Éclair : « déjà connue » passe avant")
