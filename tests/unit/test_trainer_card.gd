extends GutTest
## TrainerLibrary : bloc « card » d'un Dresseur, la carte de présentation d'un Champion
## (jalon-10.md §2.7, T9 ; dossier 12 arbitrage 13).

var _fixture_data: PokemonData
var _library: TrainerLibrary


func before_all() -> void:
	_fixture_data = PokemonData.new()
	_fixture_data.load_dir("res://tests/fixtures/pokemon/valid/")


func before_each() -> void:
	_library = TrainerLibrary.new(_fixture_data)


func _entry(card: Variant = null) -> Dictionary:
	var entry := {
		"name": "Test", "ai": "smart", "can_lose": false, "heal_after": false,
		"gives_exp": true, "prize_money": 10, "team": [{"species": "sprout", "level": 5}],
	}
	if card != null:
		entry["card"] = card
	return entry


func test_card_is_read() -> void:
	assert_true(_library.add_from_dict({"t": _entry({"name": "PIERRE",
		"title": "Champion d'Arène d'Argenta"})}, "test"), str(_library.get_errors()))
	var trainer := _library.get_trainer(&"t")
	assert_true(trainer.has_card())
	assert_eq([trainer.card_name, trainer.card_title], ["PIERRE", "Champion d'Arène d'Argenta"])


func test_without_card_no_card() -> void:
	assert_true(_library.add_from_dict({"t": _entry()}, "test"))
	var trainer := _library.get_trainer(&"t")
	assert_false(trainer.has_card())
	assert_eq([trainer.card_name, trainer.card_title], ["", ""])


func test_invalid_cards_reject_the_trainer() -> void:
	var bad: Array = [
		"PIERRE",
		{},
		{"name": "PIERRE"},
		{"title": "Champion"},
		{"name": "", "title": "Champion"},
		{"name": "PIERRE", "title": "   "},
		{"name": 3, "title": "Champion"},
		{"name": "PIERRE", "title": "Champion", "portrait": "brock"},
	]
	for i: int in bad.size():
		var library := TrainerLibrary.new(_fixture_data)
		assert_false(library.add_from_dict({"t": _entry(bad[i])}, "test"), str(bad[i]))
		assert_false(library.has_trainer(&"t"), str(bad[i]))
	assert_push_error_count(bad.size() + 1, "une erreur par carte, deux pour {}")


## Données réelles : Pierre a sa carte (texte verrouillé du dossier 12), Liam n'en a pas.
func test_real_brock_card() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var trainers := TrainerLibrary.new(data)
	assert_true(trainers.load_dir(), str(trainers.get_errors()))
	var brock := trainers.get_trainer(&"pewter_gym_brock")
	assert_eq([brock.card_name, brock.card_title], ["PIERRE", "Champion d'Arène d'Argenta"])
	assert_false(trainers.get_trainer(&"pewter_gym_liam").has_card())
	var with_card: Array[StringName] = []
	for id: StringName in trainers.get_ids():
		if trainers.get_trainer(id).has_card():
			with_card.append(id)
	assert_eq(with_card, [&"cerulean_gym_misty", &"pewter_gym_brock", &"vermilion_gym_surge"]
		as Array[StringName],
		"les Champions (Ondine au jalon 13)")
