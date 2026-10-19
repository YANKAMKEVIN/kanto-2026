extends GutTest
## Flash, capacité de terrain (jalon 17, T3 ; `jalon-17.md` §2.8 réaligné au §0.4) : règle de
## `data/world/field_moves.json` lue par le [FieldMoves] du J16 (CS05 dans le Sac, aucun badge,
## un Pokémon compatible dans l'équipe ; compagnon d'abord, K.O. accepté). La CS05 est construite
## par le test (l'objet des données arrive au T7).

var _data: PokemonData
var _items: ItemLibrary
var _rules: FieldMoves


func before_all() -> void:
	_data = PokemonData.new()
	assert_true(_data.load_dir(), "\n".join(_data.get_errors()))
	_items = ItemLibrary.new()
	assert_true(_items.add_from_dict({"hm05": {"name": "CS05 — Flash", "plural": "CS05 — Flash",
		"feminine": true, "category": "tm", "hm": 5, "teaches": "flash", "description": "x"}},
		"test"), "\n".join(_items.get_errors()))
	_rules = FieldMoves.new()
	assert_true(_rules.load_file(), "\n".join(_rules.get_errors()))


func _party(species: Array[StringName]) -> Party:
	var party := Party.new()
	for id: StringName in species:
		party.add(PokemonFactory.create(_data, id, 20, GameRng.new(3)))
	return party


func _bag(with_hm: bool) -> Bag:
	var bag := Bag.new()
	if with_hm:
		bag.add(&"hm05")
	return bag


func _check(party: Party, with_hm: bool = true, companion: Pokemon = null) -> FieldMoves.Result:
	return _rules.check(&"flash", party, _bag(with_hm), StoryFlags.new(), _items, _data, companion)


func test_flash_rule_is_data() -> void:
	assert_true(_rules.has_move(&"flash"))
	assert_eq(_rules.hm_of(&"flash"), &"hm05")
	assert_eq(_data.hm_move(5), &"flash", "la CS05 des compatibilités est bien Flash")


## Sans CS05 : rien, même avec un Pokémon compatible.
func test_without_hm05_nothing() -> void:
	var r := _check(_party([&"pikachu"]), false)
	assert_eq([r.state, r.pokemon_index], [FieldMoves.State.NO_HM, -1])
	assert_eq(r.key(&"flash"), "flash:no_hm")


## Dossier 20 §13 : CS05 sans Pokémon compatible → « rien ne se passe ».
func test_hm05_without_compatible_pokemon() -> void:
	var r := _check(_party([&"squirtle", &"rattata"]))
	assert_eq([r.state, r.pokemon_index, r.pokemon_name], [FieldMoves.State.NO_POKEMON, -1, ""])
	var empty := _check(Party.new())
	assert_eq(empty.state, FieldMoves.State.NO_POKEMON, "équipe vide")


## H-6 : aucune condition de badge (aucun drapeau, même pas `null`).
func test_no_badge_needed() -> void:
	var r := _rules.check(&"flash", _party([&"pikachu"]), _bag(true), null, _items, _data)
	assert_eq([r.state, r.pokemon_index, r.pokemon_name], [FieldMoves.State.READY, 0, "Pikachu"])
	assert_eq(r.key(&"flash"), "flash:ready")


func test_first_compatible_then_companion() -> void:
	var party := _party([&"squirtle", &"pikachu", &"clefairy"])
	var r := _check(party)
	assert_eq([r.state, r.pokemon_index, r.pokemon_name],
		[FieldMoves.State.READY, 1, "Pikachu"], "premier compatible dans l'ordre de l'équipe")
	var with_companion := _check(party, true, party.get_at(2))
	assert_eq([with_companion.pokemon_index, with_companion.pokemon_name], [2, "Mélofée"],
		"le compagnon compatible éclaire")
	var squirtle_out := _check(party, true, party.get_at(0))
	assert_eq(squirtle_out.pokemon_index, 1, "compagnon incompatible : le premier compatible")


## Défaut du J16 (repris au §2.8) : un Pokémon K.O. peut éclairer, aucun blocage possible.
func test_fainted_pokemon_can_flash() -> void:
	var party := _party([&"rattata", &"abra"])
	party.get_at(1).hp = 0
	var r := _check(party)
	assert_eq([r.state, r.pokemon_index], [FieldMoves.State.READY, 1])


## T24 (dossier 20 T-17) : texte de la mise en scène, jeton {pokemon}.
func test_cue_text_names_the_pokemon() -> void:
	assert_eq(_rules.cue_text(&"flash", "Pikachu"), "Pikachu utilise Flash !")
	assert_eq(_rules.cue_text(&"flash", ""), "", "sans nom : rien")
	assert_eq(_rules.cue_text(&"cut", "Pikachu"), "", "sans texte : rien")


## « cue » : facultatif, un texte dont le seul jeton est {pokemon}.
func test_cue_is_validated() -> void:
	var rules := FieldMoves.new()
	assert_true(rules.add_from_dict({"a": {"hm": "hm05", "badge": ""}}, "test"), "facultatif")
	assert_eq(rules.cue_text(&"a", "Pikachu"), "")
	assert_false(rules.add_from_dict({"b": {"hm": "hm05", "cue": 3}}, "test"), "texte")
	assert_false(rules.add_from_dict({"c": {"hm": "hm05", "cue": "{joueur} !"}}, "test"),
		"jeton inconnu")
	assert_push_error_count(2)
