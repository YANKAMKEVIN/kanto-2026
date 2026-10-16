extends GutTest
## Choix des répliques de la Pension (J15, T4 ; jalon-15.md §2.5.2, §0.2 n° 3) : l'état de la
## Pension → l'identifiant du dialogue (T-2, T-7, T-8, T-9, T-10, T-11) ; jetons `{pokemon}`,
## `{levels}`, `{price}` ; vue de l'écran du dépôt (raisons du Stockage).

var _data: PokemonData
var _config: DaycareConfig
var _party: Party
var _daycare: Daycare
var _library: DialogueLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_library = DialogueLibrary.new()
	_library.load_dir()


func before_each() -> void:
	_config = DaycareConfig.load_default()
	_party = Party.new()
	_daycare = Daycare.new()


func _mon(species: StringName = &"rattata", level: int = 5) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(8))


func _preview(money: int = 5000) -> DaycarePreview:
	return DaycareRules.preview(_daycare, _party, money, _config, _data)


func test_an_empty_daycare_offers_to_keep_one() -> void:
	_party.add(_mon())
	assert_eq(DaycareLines.for_visit(_preview()), DaycareLines.OFFER, "T-2")


func test_a_visit_without_level_then_with_levels() -> void:
	_party.add(_mon())
	var kept := _mon(&"rattata", 10)
	_daycare.put(kept, _data)
	assert_eq(DaycareLines.for_visit(_preview()), DaycareLines.VISIT, "T-7 : aucun niveau")
	var rate := _data.get_species(&"rattata").growth_rate
	_daycare.pending_exp = ExpCurve.exp_for_level(rate, 12) - kept.experience
	assert_eq(DaycareLines.for_visit(_preview()), DaycareLines.VISIT_LEVELS, "T-8")


func test_a_full_party_is_told_to_make_room() -> void:
	for i: int in 6:
		_party.add(_mon())
	_daycare.put(_mon(), _data)
	assert_eq(DaycareLines.for_visit(_preview()), DaycareLines.PARTY_FULL, "T-9")


func test_withdrawal_line_depends_on_the_money() -> void:
	var plan := DaycareWithdrawal.new()
	plan.price = 300
	plan.paid = 300
	assert_eq(DaycareLines.for_withdrawal(plan), DaycareLines.RETURNED, "T-10")
	plan.paid = 120
	assert_eq(DaycareLines.for_withdrawal(plan), DaycareLines.RETURNED_SHORT, "T-11")
	plan.paid = 0
	assert_eq(DaycareLines.for_withdrawal(plan), DaycareLines.RETURNED_SHORT, "T-11 avec 0 ₽")


func test_refusal_lines() -> void:
	assert_eq(DaycareLines.for_refusal(DaycareRules.Status.LAST_ABLE), DaycareLines.LAST_ABLE)
	assert_eq(DaycareLines.for_refusal(DaycareRules.Status.LAST_POKEMON), DaycareLines.LAST_ABLE)
	assert_eq(DaycareLines.for_refusal(DaycareRules.Status.PARTY_FULL), DaycareLines.PARTY_FULL)
	assert_eq(DaycareLines.for_refusal(DaycareRules.Status.OK), &"")


func test_token_values() -> void:
	var values := DaycareLines.token_values(_mon(&"rattata"), 3, 1400, _data)
	assert_eq(values, {&"pokemon": "Rattata", &"levels": "3",
		&"price": MenuFormat.number(1400)} as Dictionary[StringName, String],
		"{price} sans « ₽ » (le texte le porte)")
	assert_eq(DaycareLines.token_values(null, 0, 100, _data).size(), 0)


func test_the_pick_view_keeps_the_storage_reasons() -> void:
	var fainted := _mon()
	fainted.hp = 0
	_party.add(_mon())
	_party.add(fainted)
	var view := DaycareLines.pick_view(_daycare, _party, "T-5")
	assert_true(view.can_pick(1), "un K.O. peut être confié")
	assert_false(view.can_pick(0), "jamais le dernier apte")
	assert_eq(view.refusal_text(0), StorageViews.LAST_ABLE_TEXT)
	assert_eq(view.refused_title, "T-5")
	var alone := Party.new()
	alone.add(_mon())
	assert_eq(DaycareLines.pick_view(_daycare, alone, "").refusal_text(0),
		StorageViews.LAST_POKEMON_TEXT)


## Chaque réplique choisie existe dans les données, avec un choix là où il en faut un.
func test_every_line_exists_in_the_data() -> void:
	assert_eq(_library.get_errors().size(), 0, str(_library.get_errors()))
	for id: StringName in DaycareLines.PLAYED_BY_DIRECTOR + [DaycareLines.KEEPER]:
		assert_true(_library.has_dialogue(id), String(id))
	for id: StringName in [DaycareLines.OFFER, DaycareLines.VISIT, DaycareLines.VISIT_LEVELS]:
		var choice := _library.get_dialogue(id).variants[0].choice
		assert_not_null(choice, "%s : OUI / NON" % id)
		if choice != null:
			assert_eq([choice.confirm_label, choice.cancel_label], ["OUI", "NON"])
	var keeper := _library.get_dialogue(DaycareLines.KEEPER).variants[0]
	assert_eq(keeper.action, &"open_daycare")
	assert_eq(keeper.pages.size(), 0, "le gardien n'a pas de réplique à lui")
