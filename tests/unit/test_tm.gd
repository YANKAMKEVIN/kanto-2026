extends GutTest
## CT (jalon 11, T11 ; dossier 14 §6.1) : catégorie, objet permanent jamais vendu, compatibilités
## de Rouge/Bleu, apprentissage pur (TmTeach).


var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))


func _mon(species: StringName, level: int = 12) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(7))


func test_tm34_data() -> void:
	var tm := _items.get_item(&"tm34")
	assert_not_null(tm)
	# Textes n° 39 et 33 du §13 (validés le 2026-10-10).
	assert_eq([tm.name, tm.category, tm.tm_number, tm.teaches, tm.price],
		["CT34 — Patience", ItemData.Category.TM, 34, &"bide", 0])
	assert_eq(tm.description, "Encaisse deux tours, puis riposte avec le double des dégâts reçus.")
	assert_true(tm.is_tm())
	assert_true(tm.is_permanent())
	assert_false(tm.is_sellable(), "CT jamais vendue (dossier 14 §6.1)")
	assert_eq(tm.sell_price(), 0)
	assert_eq(tm.contexts(), [ItemData.CONTEXT_FIELD] as Array[StringName], "hors combat")
	assert_false(tm.targets_pokemon(), "pas un soin : parcours CT à part")
	assert_eq(tm.quantity_text(1), "CT34 — Patience", "permanente : pas de « ×1 »")
	assert_eq(_items.get_tm(34), &"tm34")
	assert_true(_items.check_moves(_data))
	assert_eq(_data.get_move(&"bide").name, "Patience")


func test_compatibilities_of_rouge_bleu() -> void:
	assert_eq(_data.tm_move(34), &"bide")
	assert_eq(_data.tm_move(1), &"mega_punch")
	assert_eq(_data.tm_move(99), &"")
	assert_true(_data.can_learn_tm(&"charmander", 34))
	assert_true(_data.can_learn_tm(&"onix", 34))
	for species: StringName in [&"caterpie", &"metapod", &"weedle", &"kakuna", &"magikarp"]:
		assert_false(_data.can_learn_tm(species, 34), "%s : aucune CT" % species)
	var count := 0
	for id: StringName in _data.get_species_ids():
		if _data.can_learn_tm(id, 34):
			count += 1
	# Jalon 15 (T12) : Miaouss et Persan, compatibles (Rouge/Bleu) ; jalon 17 (T7) : les huit.
	# Jalon 24 (T4) : 24 espèces, toutes compatibles sauf Magicarpe.
	assert_eq(count, 91, "91 espèces sur 96 (dossier 14 §6.1 ; + 12 du jalon 12, + 9 du jalon"
		+ " 13, + 3 du jalon 14, + 2 du jalon 15, + 8 du jalon 17, + 23 du jalon 24)")


## Jalon 14 (T5, jalon-14.md §2.4) : CT19 Frappe Atlas (Route 25) et CT28 Tunnel (Rocket).
func test_j14_tms() -> void:
	var rows := {
		&"tm19": ["CT19 — Frappe Atlas", 19, &"seismic_toss", "Projette la cible au sol."],
		&"tm28": ["CT28 — Tunnel", 28, &"dig", "Le Pokémon creuse au premier tour et frappe au"
			+ " second. Sous terre, il évite les attaques."],
	}
	for id: StringName in rows:
		var tm := _items.get_item(id)
		assert_not_null(tm, String(id))
		if tm == null:
			continue
		assert_eq([tm.name, tm.category, tm.tm_number, tm.teaches, tm.price, tm.description],
			[rows[id][0], ItemData.Category.TM, rows[id][1], rows[id][2], 0, rows[id][3]])
		assert_eq(_items.get_tm(rows[id][1]), id)
		assert_eq(_data.tm_move(rows[id][1]), rows[id][2], "même capacité que Rouge/Bleu")
	assert_true(_items.check_moves(_data))
	assert_false(_data.can_learn_tm(&"abra", 28), "Abra : pas de CT28")
	assert_true(_data.can_learn_tm(&"kadabra", 28))
	assert_true(_data.can_learn_tm(&"machop", 28))
	assert_true(_data.can_learn_tm(&"abra", 19))
	assert_eq(TmTeach.check(_mon(&"machop", 15), _items.get_item(&"tm28"), _data),
		TmTeach.Check.COMPATIBLE)
	assert_eq(TmTeach.check(_mon(&"abra", 15), _items.get_item(&"tm28"), _data),
		TmTeach.Check.INCOMPATIBLE)


func test_check_and_teach() -> void:
	var tm := _items.get_item(&"tm34")
	var charmander := _mon(&"charmander")
	assert_eq(TmTeach.check(charmander, tm, _data), TmTeach.Check.COMPATIBLE)
	var before := charmander.moves.size()
	assert_lt(before, 4)
	assert_eq(TmTeach.teach(charmander, tm, _data), Pokemon.LearnResult.LEARNED)
	assert_eq(charmander.moves.size(), before + 1)
	assert_eq(charmander.moves[-1].pp, _data.get_move(&"bide").pp, "PP pleins")
	assert_eq(TmTeach.check(charmander, tm, _data), TmTeach.Check.KNOWN)
	assert_eq(TmTeach.teach(charmander, tm, _data), Pokemon.LearnResult.INVALID)
	assert_eq(TmTeach.check(_mon(&"caterpie"), tm, _data), TmTeach.Check.INCOMPATIBLE)
	var full := _mon(&"rattata", 20)
	while full.moves.size() < 4:
		full.moves.append(MoveSlot.new(&"growl", 40))
	var moves_before := full.moves.duplicate()
	assert_eq(TmTeach.teach(full, tm, _data), Pokemon.LearnResult.NEEDS_FORGET)
	assert_eq(full.moves, moves_before, "rien ne change : la présentation fait oublier")
	assert_eq(TmTeach.LABELS.values(), ["COMPATIBLE", "DÉJÀ CONNUE", "INCOMPATIBLE"])


func test_tm_entries_are_validated() -> void:
	var lib := ItemLibrary.new()
	var base := {"name": "CT01", "plural": "CT01", "feminine": true, "category": "tm",
		"description": "x"}
	var cases := {
		"no_number": [{"teaches": "tackle"}, "« tm »"],
		"bad_number": [{"tm": 51, "teaches": "tackle"}, "« tm »"],
		"no_move": [{"tm": 2}, "« teaches »"],
		"priced": [{"tm": 3, "teaches": "tackle", "price": 3000}, "n'a pas de prix"],
	}
	for id: String in cases:
		var entry: Dictionary = base.duplicate()
		entry.merge(cases[id][0])
		assert_false(lib.add_from_dict({id: entry}, "t"), id)
		assert_string_contains("\n".join(lib.get_errors()), cases[id][1])
	var potion := {"name": "P", "plural": "P", "feminine": true, "category": "heal",
		"heal_amount": 20, "description": "x", "tm": 5}
	assert_false(lib.add_from_dict({"p": potion}, "t"))
	assert_string_contains("\n".join(lib.get_errors()), "réservé aux CT")
	var good: Dictionary = base.duplicate()
	good.merge({"tm": 4, "teaches": "unknown_move"})
	assert_true(lib.add_from_dict({"good": good}, "t"))
	var twin: Dictionary = good.duplicate()
	assert_false(lib.add_from_dict({"twin": twin}, "t"), "numéro unique")
	assert_false(lib.check_moves(_data), "capacité inconnue")
	assert_push_error_count(7)
