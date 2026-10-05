extends GutTest
## Le directeur et le Stockage (jalon-07.md §6.9, T16), seul, signaux captés : ouverture en
## écran seul au Centre (sélection = tête d'équipe), jamais ailleurs ; depuis l'Équipe (retour =
## l'Équipe) ; déposer / reprendre (sélection qui suit, état changé, vue neuve) ; refus (dernier
## Pokémon, équipe pleine) = carte refusée + raison, rien ne change, pas de vue ; LIBÉRER :
## vérification sans rien changer, confirmation, puis libération ; favori protégé ; FAVORI ;
## sélection ; fermeture (sélection oubliée, autosave seulement si changé).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const PARTY := StorageRules.Place.PARTY
const STORAGE := StorageRules.Place.STORAGE

var _state: Node
var _data: PokemonData
var _zones: ZoneLibrary
var _unlocks: MenuUnlocks
var _director: MenuDirector
var _here: StringName = &"viridian_center"
var _views: Array[StorageView] = []
var _refusals: Array[Array] = []
var _asked: Array[Array] = []
var _closed: Array[bool] = []
var _placeholders: Array[StringName] = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.new_game(1)
	_here = &"viridian_center"
	_unlocks = MenuUnlocks.new(_state.flags, _state.party)
	_unlocks.set_location(_zones, func() -> StringName: return _here)
	_director = MenuDirector.new()
	add_child_autofree(_director)
	_director.setup(_state, _data, _zones, ObjectiveLibrary.new(), _unlocks,
		func() -> bool: return true)
	_views.clear()
	_refusals.clear()
	_asked.clear()
	_closed.clear()
	_placeholders.clear()
	_director.storage_shown.connect(_views.append)
	_director.storage_refused.connect(func(place: int, index: int, text: String) -> void:
		_refusals.append([place, index, text]))
	_director.storage_release_asked.connect(
		func(view: ChoiceView, place: int, index: int) -> void:
			_asked.append([view, place, index]))
	_director.menu_closed.connect(_closed.append)
	_director.placeholder_shown.connect(_placeholders.append)


func after_each() -> void:
	get_tree().paused = false


func _add(list: Object, species: StringName, level: int, hp: int = -1,
		favorite: bool = false) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, GameRng.new(level))
	if hp >= 0:
		pokemon.hp = hp
	pokemon.favorite = favorite
	list.add(pokemon)
	return pokemon


func _open() -> bool:
	return _director.open(MenuRoute.storage(), true)


func _last() -> StorageView:
	return _views.back() if not _views.is_empty() else null


func test_opens_alone_in_a_center_on_the_lead() -> void:
	_add(_state.party, &"charmander", 8)
	_add(_state.party, &"pidgey", 7)
	_add(_state.storage, &"rattata", 4)
	assert_true(_open())
	assert_true(_director.get_navigator().is_standalone(), "écran seul")
	assert_true(get_tree().paused, "monde en pause")
	assert_eq(_views.size(), 1)
	var view := _last()
	assert_eq(view.party.size(), 2)
	assert_eq(view.storage.size(), 1)
	assert_true(view.selection.equals(StorageSelection.new(PARTY, 0)), "tête d'équipe")
	assert_eq(view.actions[0].id, StorageViews.ACTION_DEPOSIT)
	assert_eq(_placeholders.size(), 0)


func test_never_opens_outside_a_center() -> void:
	_add(_state.party, &"charmander", 8)
	_here = &"viridian_city"
	assert_false(_open(), "pas dans la ville du Centre")
	assert_false(_director.is_open())
	assert_false(get_tree().paused)
	assert_true(_director.open(MenuRoute.team()))
	assert_false(_director.go(MenuRoute.storage()), "ni depuis l'Équipe")
	_director.close()
	_here = &"viridian_center"
	assert_true(_director.open(MenuRoute.team()))
	assert_true(_director.go(MenuRoute.storage()), "au Centre, depuis l'Équipe")
	assert_true(_director.handle_back())
	assert_eq(_director.get_navigator().current().screen, MenuRoute.TEAM, "retour = l'Équipe")
	_director.close()


func test_deposit_and_withdraw_follow_the_pokemon_and_mark_changed() -> void:
	var lead := _add(_state.party, &"charmander", 8)
	_add(_state.party, &"pidgey", 7)
	_add(_state.storage, &"rattata", 4)
	assert_true(_open())
	assert_true(_director.deposit_member(0))
	assert_eq(_state.party.size(), 1)
	assert_eq(_state.storage.get_at(1), lead, "à la fin du stockage, même instance")
	assert_true(_last().selection.equals(StorageSelection.new(STORAGE, 1)), "la sélection suit")
	assert_eq(_last().actions[0].id, StorageViews.ACTION_WITHDRAW)
	assert_true(_director.withdraw_member(1))
	assert_eq(_state.party.get_at(1), lead, "en fin d'équipe")
	assert_true(_last().selection.equals(StorageSelection.new(PARTY, 1)))
	assert_eq(_views.size(), 3)
	assert_eq(_refusals.size(), 0)
	_director.close()
	assert_eq(_closed, [true] as Array[bool], "autosave à la fermeture")


func test_refusals_change_nothing_and_show_no_view() -> void:
	_add(_state.party, &"charmander", 8)
	_add(_state.party, &"rattata", 4, 0)
	assert_true(_open())
	assert_false(_director.deposit_member(0), "le dernier valide, à côté d'un K.O.")
	assert_eq(_refusals, [[PARTY, 0, StorageViews.LAST_ABLE_TEXT]] as Array[Array])
	assert_eq(_state.party.size(), 2)
	assert_true(_director.deposit_member(1), "un K.O. à côté d'un valide se dépose")
	for i: int in 5:
		_add(_state.party, &"pidgey", 3 + i)
	_add(_state.storage, &"spearow", 3)
	var views := _views.size()
	assert_false(_director.withdraw_member(0), "équipe pleine")
	assert_eq(_refusals[1], [STORAGE, 0, StorageViews.PARTY_FULL_TEXT])
	assert_eq(_views.size(), views, "pas de vue neuve")
	assert_eq(_state.party.size(), 6)


func test_release_asks_then_releases_and_protects_favorites_and_the_last() -> void:
	_add(_state.party, &"charmander", 8)
	var kept := _add(_state.storage, &"spearow", 5, -1, true)
	_add(_state.storage, &"rattata", 4)
	assert_true(_open())
	var name := kept.display_name(_data)
	# Favori : refus et raison, aucune confirmation.
	assert_false(_director.request_release(STORAGE, 0))
	assert_eq(_refusals, [[STORAGE, 0, StorageViews.FAVORITE_TEXT % name]] as Array[Array])
	assert_eq(_asked.size(), 0, "aucune confirmation pour un favori")
	assert_false(_director.confirm_release(STORAGE, 0), "la règle est revérifiée")
	assert_eq(_state.storage.size(), 2)
	# Dernier Pokémon de l'équipe.
	assert_false(_director.request_release(PARTY, 0))
	assert_eq(_refusals[-1], [PARTY, 0, StorageViews.LAST_POKEMON_TEXT])
	# Permis : confirmation, rien ne change avant.
	var views := _views.size()
	assert_true(_director.request_release(STORAGE, 1))
	assert_eq(_asked.size(), 1)
	var choice: ChoiceView = _asked[0][0]
	assert_eq(choice.confirm_label, StorageViews.RELEASE_LABEL)
	assert_eq(choice.cancel_label, StorageViews.CANCEL_LABEL)
	assert_eq(choice.detail, StorageViews.RELEASE_DETAIL)
	assert_eq([_asked[0][1], _asked[0][2]], [STORAGE, 1])
	assert_eq(_state.storage.size(), 2, "rien avant LIBÉRER")
	assert_eq(_views.size(), views)
	assert_true(_director.confirm_release(STORAGE, 1))
	assert_eq(_state.storage.size(), 1)
	assert_eq(_state.storage.get_at(0), kept)
	assert_true(_last().selection.equals(StorageSelection.new(STORAGE, 0)),
		"celui qui prend la place")
	assert_eq(choice.title, StorageViews.RELEASE_TITLE % "Rattata")


func test_favorite_and_selection() -> void:
	var lead := _add(_state.party, &"charmander", 8)
	var stored := _add(_state.storage, &"rattata", 4)
	assert_true(_open())
	assert_true(_director.toggle_storage_favorite(PARTY, 0))
	assert_true(lead.favorite)
	assert_true(_last().actions[1].active, "FAVORI actif")
	_director.select_storage(STORAGE, 0)
	assert_true(_last().selection.equals(StorageSelection.new(STORAGE, 0)))
	var views := _views.size()
	_director.select_storage(STORAGE, 0)
	_director.select_storage(STORAGE, 7)
	assert_eq(_views.size(), views, "même carte ou place absente : rien")
	assert_true(_director.toggle_storage_favorite(STORAGE, 0))
	assert_true(stored.favorite)
	assert_false(_director.toggle_storage_favorite(STORAGE, 3), "place absente")


func test_actions_are_ignored_outside_the_storage_screen() -> void:
	_add(_state.party, &"charmander", 8)
	_add(_state.party, &"pidgey", 7)
	assert_false(_director.deposit_member(0), "menu fermé")
	assert_true(_director.open(MenuRoute.team()))
	assert_false(_director.deposit_member(0), "écran Équipe")
	assert_eq(_state.party.size(), 2)
	_director.close()
	assert_eq(_closed, [false] as Array[bool])


func test_closing_forgets_the_selection() -> void:
	_add(_state.party, &"charmander", 8)
	_add(_state.party, &"pidgey", 7)
	assert_true(_open())
	_director.select_storage(PARTY, 1)
	_director.close()
	assert_eq(_closed, [false] as Array[bool], "une sélection n'est pas un changement")
	assert_true(_open())
	assert_true(_last().selection.equals(StorageSelection.new(PARTY, 0)), "tête d'équipe")
	_director.close()


func test_release_view_carries_the_result_and_the_next_action_clears_it() -> void:
	_add(_state.party, &"charmander", 8)
	_add(_state.party, &"pidgey", 6)
	_add(_state.storage, &"rattata", 4)
	assert_true(_open())
	assert_true(_director.confirm_release(STORAGE, 0))
	assert_eq(_last().result_text, StorageViews.RELEASED_TEXT % "Rattata")
	assert_true(_director.deposit_member(1))
	assert_eq(_last().result_text, "", "déposer est muet et efface la ligne")
	assert_true(_director.withdraw_member(0))
	assert_eq(_last().result_text, "")
	assert_eq(_director.build_storage().result_text, "", "une vue sans résultat l'efface")
