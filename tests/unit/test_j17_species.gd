extends GutTest
## Jalon 17 (T7 ; `jalon-17.md` §2.9, §2.12.1, §2.12.2) : les huit espèces (types et
## statistiques actuels, apprentissages de Rouge/Bleu), les capacités ajoutées, la CS05 et les
## fiches de Pokédex (annexe A, validée le 2026-10-16). Q-1 « tout J17 » (2026-10-16) : la CS05
## s'apprend comme une CT réutilisable (Flash en combat, `test_battle_flash`).

const SPECIES: Dictionary[StringName, Array] = {
	# espèce: [n°, nom, types, PV, Att, Déf, AttSp, DéfSp, Vit]
	&"diglett": [50, "Taupiqueur", [&"ground"], 10, 55, 25, 35, 45, 95],
	&"dugtrio": [51, "Triopikeur", [&"ground"], 35, 100, 50, 50, 70, 120],
	&"growlithe": [58, "Caninos", [&"fire"], 55, 70, 45, 70, 50, 60],
	&"vulpix": [37, "Goupix", [&"fire"], 38, 41, 40, 50, 65, 65],
	&"magnemite": [81, "Magnéti", [&"electric", &"steel"], 25, 35, 70, 95, 55, 45],
	&"magneton": [82, "Magnéton", [&"electric", &"steel"], 50, 60, 95, 120, 70, 70],
	&"drowzee": [96, "Soporifik", [&"psychic"], 60, 48, 45, 43, 90, 42],
	&"hypno": [97, "Hypno", [&"psychic"], 85, 73, 70, 73, 115, 67],
}

var _data: PokemonData
var _items: ItemLibrary
var _dex: PokedexLibrary


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_items = ItemLibrary.new()
	assert_true(_items.load_dir(), "\n".join(_items.get_errors()))
	_dex = PokedexLibrary.new()
	assert_true(_dex.load_file(), "\n".join(_dex.get_errors()))


func _mon(species: StringName, level: int = 20) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(7))


func test_species_values() -> void:
	for id: StringName in SPECIES:
		var row: Array = SPECIES[id]
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		assert_eq([species.dex, species.name], [row[0], row[1]], String(id))
		var types: Array[StringName] = []
		types.assign(row[2])
		assert_eq(species.types, types, String(id))
		assert_eq(species.base_stats, {&"hp": row[3], &"atk": row[4], &"def": row[5],
			&"spa": row[6], &"spd": row[7], &"spe": row[8]} as Dictionary[StringName, int],
			String(id))
	assert_true(_data.get_species(&"magnemite").is_genderless())
	assert_eq(_data.get_species(&"growlithe").growth_rate, ExpCurve.Rate.SLOW)


## Évolutions par niveau de Rouge/Bleu. Caninos et Goupix n'évoluaient pas au J17 (Pierre Feu
## absente) ; le J20 (T7, `jalon-20.md` §2.10.1) leur ajoute la Pierre Feu : vérifiée dans
## test_celadon_data.gd.
func test_evolutions() -> void:
	var expected := {&"diglett": [&"dugtrio", 26], &"drowzee": [&"hypno", 26],
		&"magnemite": [&"magneton", 30]}
	for id: StringName in expected:
		var rules := _data.get_species(id).evolutions
		assert_eq(rules.size(), 1, String(id))
		assert_eq([rules[0].into, rules[0].level], expected[id], String(id))
	for id: StringName in [&"dugtrio", &"hypno", &"magneton"]:
		assert_eq(_data.get_species(id).evolutions.size(), 0, String(id))


## Apprentissages de Rouge/Bleu aux niveaux du jalon : Taupiqueur apprend Tunnel au N19,
## Soporifik a Hypnose d'office et Coup d'Boule au N24.
func test_learnsets_at_the_levels_of_the_milestone() -> void:
	assert_true(_mon(&"diglett", 19).knows_move(&"dig"))
	assert_false(_mon(&"diglett", 18).knows_move(&"dig"))
	assert_true(_mon(&"dugtrio", 24).knows_move(&"dig"))
	var drowzee := _mon(&"drowzee", 24)
	for move: StringName in [&"hypnosis", &"disable", &"confusion", &"headbutt"]:
		assert_true(drowzee.knows_move(move), "Soporifik N24 : %s" % move)
	assert_true(_mon(&"growlithe", 5).knows_move(&"roar"))


func test_new_moves() -> void:
	var flash := _data.get_move(&"flash")
	assert_eq([flash.name, flash.type, flash.accuracy, flash.pp], ["Flash", &"normal", 70, 20],
		"H-6 : précision 70 %")
	assert_eq([flash.effects[0].kind, flash.effects[0].stat, flash.effects[0].stages],
		[MoveEffect.Kind.STAT_STAGE, &"acc", -1], "Précision de l'adversaire −1 (H-6)")
	assert_eq(flash.description, "Une lumière aveuglante qui baisse la précision de l'ennemi.",
		"T-16")
	var hypnosis := _data.get_move(&"hypnosis")
	assert_eq([hypnosis.accuracy, hypnosis.effects[0].kind, hypnosis.effects[0].status],
		[60, MoveEffect.Kind.STATUS, &"sleep"])
	var headbutt := _data.get_move(&"headbutt")
	assert_eq([headbutt.power, headbutt.accuracy, headbutt.pp, headbutt.effects[0].kind,
		headbutt.effects[0].chance], [70, 100, 15, MoveEffect.Kind.FLINCH, 30])
	var gas := _data.get_move(&"poison_gas")
	assert_eq([gas.accuracy, gas.pp, gas.effects[0].status], [55, 40, &"poison"])
	var meditate := _data.get_move(&"meditate")
	assert_eq([meditate.effects[0].stat, meditate.effects[0].stages], [&"atk", 1])
	# Sans effet dans le moteur actuel (règle du J12) : la mention est dans la description.
	for id: StringName in [&"roar", &"take_down"]:
		var move := _data.get_move(id)
		assert_eq(move.effects.size(), 0, String(id))
		assert_false(move.pending_effects.is_empty(), String(id))
		assert_true(move.description.ends_with("Sans effet dans le moteur actuel."), String(id))


## CS05 : objet de la catégorie CT, numéro de CS 5, jamais consommée ni vendue ; T-15.
func test_hm05_item() -> void:
	var hm := _items.get_item(&"hm05")
	assert_not_null(hm)
	if hm == null:
		return
	assert_eq([hm.name, hm.category, hm.hm_number, hm.tm_number, hm.teaches, hm.price],
		["CS05 — Flash", ItemData.Category.TM, 5, 0, &"flash", 0])
	assert_eq(hm.description, "Éclaire les grottes obscures si un Pokémon compatible est dans "
		+ "l'équipe. Peut aussi apprendre Flash pour le combat.", "T-15")
	assert_true(hm.is_hm())
	assert_true(hm.is_permanent())
	assert_false(hm.is_sellable())
	assert_eq(_items.get_hm(5), &"hm05")
	assert_true(_items.check_moves(_data))


## Q-1 « tout J17 » (2026-10-16) : la CS05 s'apprend comme une CT réutilisable, aux
## compatibles seulement, sans jamais être consommée.
func test_hm05_teaches_flash_to_compatible_pokemon() -> void:
	var hm := _items.get_item(&"hm05")
	assert_eq(hm.contexts(), [ItemData.CONTEXT_FIELD] as Array[StringName], "bouton APPRENDRE")
	assert_eq(TmTeach.check(_mon(&"pikachu"), hm, _data), TmTeach.Check.COMPATIBLE)
	assert_eq(TmTeach.check(_mon(&"diglett"), hm, _data), TmTeach.Check.INCOMPATIBLE)
	var drowzee := _mon(&"drowzee")
	if drowzee.moves.size() >= SpeciesData.MAX_MOVES:
		drowzee.moves.resize(SpeciesData.MAX_MOVES - 1)
	assert_eq(TmTeach.teach(drowzee, hm, _data), Pokemon.LearnResult.LEARNED)
	assert_true(drowzee.knows_move(&"flash"))
	assert_eq(TmTeach.check(drowzee, hm, _data), TmTeach.Check.KNOWN)
	assert_true(hm.is_permanent(), "jamais consommée")


## Flash sur le terrain avec la vraie CS05 (règle de field_moves.json) : Soporifik éclaire.
func test_real_hm05_unlocks_flash_on_the_field() -> void:
	var rules := FieldMoves.new()
	assert_true(rules.load_file())
	var party := Party.new()
	party.add(_mon(&"diglett"))
	party.add(_mon(&"drowzee"))
	var bag := Bag.new()
	bag.add(&"hm05")
	var result := rules.check(&"flash", party, bag, StoryFlags.new(), _items, _data)
	assert_eq([result.state, result.pokemon_index, result.pokemon_name],
		[FieldMoves.State.READY, 1, "Soporifik"])


## CS05 de Rouge/Bleu : Soporifik, Hypno, Magnéti, Magnéton compatibles ; Taupiqueur,
## Triopikeur, Caninos, Goupix non.
func test_hm05_compatibilities_of_the_new_species() -> void:
	for id: StringName in [&"drowzee", &"hypno", &"magnemite", &"magneton"]:
		assert_true(_data.can_learn_hm(id, 5), "%s peut apprendre Flash" % id)
	for id: StringName in [&"diglett", &"dugtrio", &"growlithe", &"vulpix"]:
		assert_false(_data.can_learn_hm(id, 5), "%s ne peut pas apprendre Flash" % id)


## Annexe A.1 (validée le 2026-10-16) : tailles et poids officiels, textes mot pour mot.
func test_pokedex_entries_are_validated() -> void:
	var official := {&"diglett": [0.2, 0.8], &"dugtrio": [0.7, 33.3], &"drowzee": [1.0, 32.4],
		&"hypno": [1.6, 75.6], &"magnemite": [0.3, 6.0], &"magneton": [1.0, 60.0],
		&"growlithe": [0.7, 19.0], &"vulpix": [0.6, 9.9]}
	for id: StringName in official:
		var info := _dex.get_species(id)
		assert_not_null(info, String(id))
		if info == null:
			continue
		assert_almost_eq(info.height, float(official[id][0]), 0.001, String(id))
		assert_almost_eq(info.weight, float(official[id][1]), 0.001, String(id))
		assert_false(info.draft, "%s : annexe A validée (Q-2)" % id)
	for id: StringName in [&"diglett", &"drowzee"]:
		var notes := _dex.get_notes(id)
		assert_eq(notes.size(), 1, "%s : une note (annexe A.2)" % id)
		assert_false(notes[0].draft, "%s : note validée (Q-2)" % id)


## Q-1 tranché : la clé provisoire « teachable » n'existe plus (clé inconnue refusée).
func test_teachable_key_is_gone() -> void:
	var lib := ItemLibrary.new()
	var hm := {"name": "CS", "plural": "CS", "feminine": true, "category": "tm", "hm": 4,
		"teaches": "tackle", "description": "x", "teachable": false}
	assert_false(lib.add_from_dict({"a": hm}, "test"))
	assert_push_error_count(1)
