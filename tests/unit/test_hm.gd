extends GutTest
## CS (jalon 16, T5 ; dossier 19 §0 R-17, `jalon-16.md` §2.1) : la CS01 est une CT de numéro de
## CS, permanente, jamais vendue ; compatibilités de Rouge/Bleu (« hms », « hm_species ») ;
## apprentissage par TmTeach comme une CT. Données du J16 : Coupe, Tonnerre, CT24, Super Potion.


var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))


func _mon(species: StringName, level: int = 20) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(7))


func test_hm01_data() -> void:
	var hm := _items.get_item(&"hm01")
	assert_not_null(hm)
	if hm == null:
		return
	assert_eq([hm.name, hm.category, hm.hm_number, hm.tm_number, hm.teaches, hm.price],
		["CS01 — Coupe", ItemData.Category.TM, 1, 0, &"cut", 0])
	assert_true(hm.is_tm(), "rangée avec les CT (onglet CT)")
	assert_true(hm.is_hm())
	assert_true(hm.is_permanent(), "jamais consommée")
	assert_false(hm.is_sellable(), "jamais vendue")
	assert_eq(hm.quantity_text(1), "CS01 — Coupe")
	assert_eq(_items.get_hm(1), &"hm01")
	assert_eq(_items.get_tm(1), &"tm01", "la CS01 ne prend pas le numéro de la CT01")
	assert_true(_items.check_moves(_data))


func test_cut_and_thunderbolt_moves() -> void:
	var cut := _data.get_move(&"cut")
	assert_not_null(cut)
	assert_eq([cut.name, cut.power, cut.accuracy, cut.pp], ["Coupe", 50, 95, 30],
		"valeurs actuelles (dossier 19 §0)")
	var bolt := _data.get_move(&"thunderbolt")
	assert_not_null(bolt)
	assert_eq([bolt.name, bolt.power, bolt.accuracy, bolt.pp], ["Tonnerre", 90, 100, 15])


func test_tm24_and_super_potion() -> void:
	var tm := _items.get_item(&"tm24")
	assert_not_null(tm)
	assert_eq([tm.tm_number, tm.teaches, tm.is_hm()], [24, &"thunderbolt", false])
	assert_eq(_items.get_tm(24), &"tm24")
	assert_eq(_data.tm_move(24), &"thunderbolt", "même capacité que Rouge/Bleu")
	var potion := _items.get_item(&"super_potion")
	assert_not_null(potion)
	assert_eq([potion.category, potion.heal_amount, potion.price],
		[ItemData.Category.HEAL, 50, 700], "R-6 : 50 PV, 700 ₽")


## G-6 : les cinq espèces garanties avant Carmin et les lignées Bulbizarre et Salamèche peuvent
## couper ; Carapuce et Pikachu non (Rouge/Bleu).
func test_cut_compatibilities() -> void:
	assert_eq(_data.hm_move(1), &"cut")
	assert_eq(_data.hm_move(9), &"")
	for species: StringName in [&"beedrill", &"sandshrew", &"paras", &"bellsprout", &"oddish",
			&"bulbasaur", &"charmander"]:
		assert_true(_data.can_learn_hm(species, 1), "%s peut apprendre Coupe" % species)
	for species: StringName in [&"squirtle", &"wartortle", &"pikachu", &"pidgey"]:
		assert_false(_data.can_learn_hm(species, 1), "%s ne peut pas apprendre Coupe" % species)


func test_teach_hm_like_a_tm() -> void:
	var hm := _items.get_item(&"hm01")
	var mon := _mon(&"sandshrew")
	assert_eq(TmTeach.check(mon, hm, _data), TmTeach.Check.COMPATIBLE)
	assert_eq(TmTeach.check(_mon(&"squirtle"), hm, _data), TmTeach.Check.INCOMPATIBLE)
	while mon.moves.size() > 3:
		mon.moves.pop_back()
	assert_eq(TmTeach.teach(mon, hm, _data), Pokemon.LearnResult.LEARNED)
	assert_true(mon.knows_move(&"cut"))
	assert_eq(TmTeach.check(mon, hm, _data), TmTeach.Check.KNOWN)


func test_library_rejects_bad_hms() -> void:
	var lib := ItemLibrary.new()
	var base := {"name": "CS", "plural": "CS", "feminine": true, "category": "tm",
		"teaches": "cut", "description": "x"}
	var both := base.duplicate()
	both["hm"] = 1
	both["tm"] = 1
	assert_false(lib.add_from_dict({"a": both}, "test"), "« hm » et « tm » exclusifs")
	var out_of_range := base.duplicate()
	out_of_range["hm"] = 6
	assert_false(lib.add_from_dict({"b": out_of_range}, "test"), "CS de 1 à 5")
	var on_potion := {"name": "P", "plural": "P", "feminine": true, "category": "heal",
		"heal_amount": 20, "hm": 1, "description": "x"}
	assert_false(lib.add_from_dict({"c": on_potion}, "test"), "« hm » réservé aux CT")
	var ok := base.duplicate()
	ok["hm"] = 2
	assert_true(lib.add_from_dict({"d": ok}, "test"))
	var dup := base.duplicate()
	dup["hm"] = 2
	assert_false(lib.add_from_dict({"e": dup}, "test"), "numéro de CS unique")
	assert_eq(lib.get_hm(2), &"d")
	assert_push_error_count(4, "une erreur par entrée refusée")
