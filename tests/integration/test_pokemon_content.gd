extends GutTest
## Contenu Pokémon réel du jalon 4 (jalon-04.md §4.4, T3) : data/pokemon/, l'offre du labo,
## les dresseurs et les messages de combat se chargent sans erreur ; chaque choix de l'offre
## est une espèce connue, représentée au labo par un PNJ de même apparence ; capacités de
## départ au niveau de l'offre (1 à 4, PP > 0 ; Rouge/Bleu : 2 chacune) ; légende et phrases
## de fiche reprises mot pour mot du dossier 02 ; le rival prend le starter avantagé.

const DOSSIER := "res://docs/design/dossier-02-prologue.md"
## Décision de Kevin n° 3 (tables de Rouge/Bleu) : capacités au niveau 5.
const START_MOVES: Dictionary[StringName, Array] = {
	&"bulbasaur": [&"tackle", &"growl"],
	&"charmander": [&"scratch", &"growl"],
	&"squirtle": [&"tackle", &"tail_whip"],
}

var _data: PokemonData
var _offer: StarterOffer


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_offer = StarterOffer.new()
	_offer.load_file()


func test_real_data_loads_without_error() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir(), "data/pokemon/ se charge")
	assert_eq(data.get_errors().size(), 0, str(data.get_errors()))
	var offer := StarterOffer.new()
	assert_true(offer.load_file(), "starters.json se charge")
	assert_true(offer.check_species(data))
	assert_eq(offer.get_errors().size(), 0, str(offer.get_errors()))
	var trainers := TrainerLibrary.new(data)
	assert_true(trainers.load_dir(), "data/trainers/ se charge")
	assert_eq(trainers.get_errors().size(), 0, str(trainers.get_errors()))
	var texts := BattleText.new()
	assert_true(texts.load_file(), "messages.json se charge")
	assert_eq(texts.get_errors().size(), 0, str(texts.get_errors()))


func test_offer_choices_are_lab_npcs_with_the_species_sprite() -> void:
	assert_eq(_offer.map_id, &"oak_lab")
	assert_eq(_offer.level, 5)
	assert_eq(_offer.get_species_ids(), [&"bulbasaur", &"charmander", &"squirtle"]
		as Array[StringName])
	var roster := NpcRoster.load_for_map(_offer.map_id)
	for option: StarterOption in _offer.get_choices():
		assert_true(_data.has_species(option.species), "espèce « %s »" % option.species)
		var spec := roster.get_spec(option.npc)
		assert_not_null(spec, "PNJ « %s » au labo" % option.npc)
		if spec == null:
			continue
		# DA.3 : starters peints (`pokemon/<espèce>`, CharacterLook).
		assert_eq(spec.sprite, StringName("pokemon/" + String(option.species)),
			"%s : apparence peinte de l'espèce" % option.npc)
		assert_eq(spec.unless_flags, [StarterChoice.taken_flag(option.species)]
			as Array[StringName], "%s : quitte la table une fois pris" % option.npc)
		assert_gt(spec.lift, 0, "%s : sur la table" % option.npc)


func test_starting_moves_at_the_offer_level() -> void:
	for option: StarterOption in _offer.get_choices():
		var species := _data.get_species(option.species)
		var moves := species.moves_at(_offer.level)
		assert_between(moves.size(), 1, SpeciesData.MAX_MOVES, "%s : 1 à 4" % option.species)
		assert_eq(Array(moves), START_MOVES[option.species], "%s : Rouge/Bleu" % option.species)
		for move_id: StringName in moves:
			assert_true(_data.has_move(move_id), "capacité « %s »" % move_id)
			if _data.has_move(move_id):
				assert_gt(_data.get_move(move_id).pp, 0, "%s : PP > 0" % move_id)


func test_created_starter_is_ready() -> void:
	for option: StarterOption in _offer.get_choices():
		var pokemon := PokemonFactory.create(_data, option.species, _offer.level, GameRng.new(7))
		assert_not_null(pokemon)
		if pokemon == null:
			continue
		assert_eq(pokemon.level, 5)
		assert_eq(pokemon.hp, pokemon.max_hp())
		assert_eq(pokemon.moves.size(), 2)
		for slot: MoveSlot in pokemon.moves:
			assert_eq(slot.pp, slot.max_pp)


func test_texts_are_the_dossier_02_texts() -> void:
	var dossier := FileAccess.get_file_as_string(DOSSIER)
	assert_true(dossier.contains(_offer.prompt), "légende « %s »" % _offer.prompt)
	for option: StarterOption in _offer.get_choices():
		assert_true(dossier.contains("*" + option.blurb + "*"), "phrase « %s »" % option.blurb)
		var view := StarterChoice.make_view(option, _data)
		assert_not_null(view)
		if view != null:
			assert_true(view.is_valid())
			assert_true(dossier.contains("**" + view.display_name.to_upper() + "**"),
				"nom « %s »" % view.display_name)


func test_rival_takes_the_advantaged_starter() -> void:
	var expected: Dictionary[StringName, StringName] = {
		&"bulbasaur": &"charmander", &"charmander": &"squirtle", &"squirtle": &"bulbasaur",
	}
	for species: StringName in expected:
		assert_eq(_offer.rival_pick(species, _data), expected[species], String(species))
