extends GutTest
## StorageViews : la vue de l'écran Stockage et les textes des refus (dossier 09 §8, §19 ;
## jalon-07.md §3.5).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

const PARTY := StorageRules.Place.PARTY
const STORAGE := StorageRules.Place.STORAGE

var _data: PokemonData
var _zones: ZoneLibrary
var _state: Node
var _unlocks: MenuUnlocks


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_state = GameStateScript.new()
	_state.new_game(7)
	_state.clock = FixedClock.new("2026-10-05T10:00:00")
	_unlocks = MenuUnlocks.new(_state.flags, _state.party)


func after_each() -> void:
	_state.free()


func _add(species: StringName, level: int, to_storage: bool = false) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, _state.rng)
	_state.stamp_meeting(pokemon, Pokemon.Origin.CAPTURE, &"route_1")
	if to_storage:
		_state.storage.add(pokemon)
	else:
		_state.party.add(pokemon)
	return pokemon


func _build(selection: StorageSelection = null) -> StorageView:
	return StorageViews.build(_state, _data, selection, _zones, _unlocks)


func _ids(actions: Array[StorageActionView]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for action: StorageActionView in actions:
		ids.append(action.id)
	return ids


func test_validated_labels() -> void:
	_add(&"charmander", 5)
	var view := _build()
	assert_eq(view.party_title, "ÉQUIPE")
	assert_eq(view.storage_title, "STOCKAGE")
	assert_eq(view.back_label, "RETOUR")
	assert_eq(StorageViews.DEPOSIT_LABEL, "DÉPOSER")
	assert_eq(StorageViews.WITHDRAW_LABEL, "REPRENDRE")
	assert_eq(StorageViews.FAVORITE_LABEL, "FAVORI")
	assert_eq(StorageViews.RELEASE_LABEL, "LIBÉRER")
	assert_eq(StorageView.PARTY_SLOTS, 6)


func test_party_and_storage_in_order() -> void:
	_add(&"charmander", 7)
	_add(&"pidgey", 4)
	var first := _add(&"rattata", 3, true)
	first.take_damage(first.hp)
	_add(&"pidgey", 2, true)
	var view := _build()
	assert_eq(view.party.size(), 2)
	assert_eq(view.storage.size(), 2)
	assert_eq(view.party[1].member.display_name, "Roucool")
	assert_eq(view.party[1].place, PARTY)
	assert_eq(view.party[1].index, 1)
	assert_eq(view.storage[0].place, STORAGE)
	assert_eq(view.storage[0].index, 0)
	assert_eq(view.storage[0].member.display_name, "Rattata", "ordre d'arrivée")
	assert_eq(view.storage[0].member.status_text, TeamMemberView.STATUS_FAINTED)
	assert_eq(view.storage[1].member.party_index, 1, "index dans sa propre liste")
	assert_eq(view.empty_text, "")
	assert_same(view.card_at(STORAGE, 1), view.storage[1])
	assert_null(view.card_at(STORAGE, 2))


func test_default_selection_is_the_lead_with_deposit_and_favorite() -> void:
	_add(&"charmander", 7)
	var view := _build()
	assert_true(view.selection.equals(StorageSelection.new(PARTY, 0)))
	assert_true(view.party[0].selected)
	assert_not_null(view.sheet)
	assert_eq(view.sheet.species_name, "Salamèche")
	assert_eq(_ids(view.actions), [StorageViews.ACTION_DEPOSIT, StorageViews.ACTION_FAVORITE]
		as Array[StringName])
	assert_eq(view.actions[0].label, "DÉPOSER")
	assert_false(view.actions[1].active)
	assert_eq(_ids(view.more_actions), [StorageViews.ACTION_RELEASE] as Array[StringName],
		"LIBÉRER seulement dans le menu secondaire")


func test_storage_selection_offers_withdraw_and_shows_the_favorite() -> void:
	_add(&"charmander", 7)
	var stored := _add(&"pidgey", 3, true)
	stored.favorite = true
	var view := _build(StorageSelection.new(STORAGE, 0))
	assert_true(view.storage[0].selected)
	assert_false(view.party[0].selected)
	assert_eq(view.actions[0].id, StorageViews.ACTION_WITHDRAW)
	assert_eq(view.actions[0].label, "REPRENDRE")
	assert_true(view.actions[1].active, "FAVORI enfoncé")
	assert_true(view.storage[0].member.favorite)
	assert_eq(view.sheet.member.party_index, 0)


func test_selection_out_of_range_is_clamped() -> void:
	_add(&"charmander", 7)
	_add(&"pidgey", 3, true)
	var view := _build(StorageSelection.new(STORAGE, 9))
	assert_true(view.selection.equals(StorageSelection.new(STORAGE, 0)))


func test_empty_storage_text() -> void:
	_add(&"charmander", 7)
	var view := _build()
	assert_eq(view.storage.size(), 0)
	assert_eq(view.empty_text, "Le stockage est vide.")


func test_nothing_at_all_gives_no_selection_and_no_action() -> void:
	var view := _build()
	assert_true(view.selection.is_empty())
	assert_null(view.sheet)
	assert_eq(view.actions.size(), 0)
	assert_eq(view.more_actions.size(), 0)


func test_no_pokedex_trace_before_activation() -> void:
	_add(&"charmander", 7)
	var hidden := _build()
	assert_eq(hidden.sheet.evolution_text, EvolutionReveal.text(
		EvolutionReveal.chain(&"charmander", _data, _state.pokedex, false)),
		"un seul « ??? » sans le Pokédex (règle de l'Équipe)")
	_state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	var shown := _build()
	assert_eq(shown.sheet.evolution_text, EvolutionReveal.text(
		EvolutionReveal.chain(&"charmander", _data, _state.pokedex, true)))
	assert_ne(shown.sheet.evolution_text, hidden.sheet.evolution_text)


func test_release_choice_uses_validated_texts() -> void:
	var choice := StorageViews.release_choice("Roucool")
	assert_eq(choice.title, "Libérer Roucool ?")
	assert_eq(choice.detail, "Il quittera définitivement ton équipe et ton stockage.")
	assert_eq(choice.confirm_label, "LIBÉRER")
	assert_eq(choice.cancel_label, "ANNULER")


func test_status_texts() -> void:
	assert_eq(StorageViews.status_text(StorageRules.Status.LAST_POKEMON, "Salamèche"),
		"Tu dois garder au moins un Pokémon avec toi.")
	assert_eq(StorageViews.status_text(StorageRules.Status.LAST_ABLE, "Salamèche"),
		"Tu dois garder au moins un Pokémon en état de combattre.")
	assert_eq(StorageViews.status_text(StorageRules.Status.FAVORITE, "Roucool"),
		"Retire d'abord Roucool de tes favoris pour pouvoir le libérer.")
	assert_eq(StorageViews.status_text(StorageRules.Status.PARTY_FULL, "Roucool"),
		"Ton équipe est déjà complète.")
	assert_eq(StorageViews.status_text(StorageRules.Status.OK, "Roucool"), "")
	assert_eq(StorageViews.status_text(StorageRules.Status.NOT_FOUND, "Roucool"), "")


func test_result_text_names_the_refused_pokemon() -> void:
	_add(&"charmander", 7)
	var stored := _add(&"pidgey", 3, true)
	stored.favorite = true
	stored.nickname = "Plume"
	var result := StorageRules.release(_state.party, _state.storage, STORAGE, 0)
	assert_eq(StorageViews.result_text(result, _data),
		"Retire d'abord Plume de tes favoris pour pouvoir le libérer.")
	var deposit := StorageRules.deposit(_state.party, _state.storage, 0)
	assert_eq(StorageViews.result_text(deposit, _data),
		"Tu dois garder au moins un Pokémon avec toi.")
	var withdraw := StorageRules.withdraw(_state.party, _state.storage, 0)
	assert_true(withdraw.is_ok())
	assert_eq(StorageViews.result_text(withdraw, _data), "", "un succès n'a pas de texte")
	assert_eq(StorageViews.result_text(null, _data), "")


func test_result_text_explains_all_fainted_apart_from_empty() -> void:
	_add(&"charmander", 7)
	var fainted := _add(&"pidgey", 3)
	fainted.take_damage(fainted.hp)
	var refused := StorageRules.deposit(_state.party, _state.storage, 0)
	assert_eq(StorageViews.result_text(refused, _data),
		"Tu dois garder au moins un Pokémon en état de combattre.")


func test_only_a_release_has_a_success_text() -> void:
	_add(&"charmander", 7)
	_add(&"rattata", 4)
	var stored := _add(&"pidgey", 3, true)
	stored.nickname = "Plume"
	var favorite := StorageRules.toggle_favorite(_state.party, _state.storage, PARTY, 0)
	assert_eq(StorageViews.result_text(favorite, _data), "", "favori : pas de texte")
	var deposit := StorageRules.deposit(_state.party, _state.storage, 1)
	assert_eq(StorageViews.result_text(deposit, _data), "", "déposer : pas de texte")
	var released := StorageRules.release(_state.party, _state.storage, STORAGE, 0)
	assert_true(released.is_ok())
	assert_eq(StorageViews.result_text(released, _data), "Plume a été libéré.")


func test_view_carries_the_release_line_only_after_a_release() -> void:
	_add(&"charmander", 7)
	_add(&"pidgey", 3, true)
	assert_eq(_build().result_text, "", "à l'entrée de l'écran : pas de ligne")
	var released := StorageRules.release(_state.party, _state.storage, STORAGE, 0)
	var view := StorageViews.build(_state, _data, released.selection, _zones, _unlocks,
		released)
	assert_eq(view.result_text, "Roucool a été libéré.")
	var refused := StorageRules.deposit(_state.party, _state.storage, 0)
	view = StorageViews.build(_state, _data, refused.selection, _zones, _unlocks, refused)
	assert_eq(view.result_text, "", "un refus ne passe pas par la vue")
