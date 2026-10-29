extends GutTest
## StorageQuery (jalon 32, T7 ; N-21) : recherche par nom d'espèce, tri par espèce, type et
## niveau, tri stable ; seul l'affichage change (index réels conservés, liste jamais modifiée) ;
## déplacer / favori visent le bon individu filtre et tri actifs (via le directeur).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const STORAGE := StorageRules.Place.STORAGE
const Sort := StorageQuery.Sort

var _data: PokemonData
var _zones: ZoneLibrary
var _state: Node
var _director: MenuDirector
var _views: Array[StorageView] = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.new_game(1)
	_views.clear()


func _mk(species: StringName, level: int) -> Pokemon:
	return PokemonFactory.create(_data, species, level, GameRng.new(level))


## Stockage : 0 rattata 5, 1 pidgey 9, 2 charmander 7, 3 pidgey 3, 4 squirtle 7, 5 bulbasaur 4.
func _fill() -> Array[Pokemon]:
	for spec: Array in [[&"rattata", 5], [&"pidgey", 9], [&"charmander", 7], [&"pidgey", 3],
			[&"squirtle", 7], [&"bulbasaur", 4]]:
		_state.storage.add(_mk(spec[0], spec[1]))
	return _state.storage.get_all()


func _director_open() -> void:
	var unlocks := MenuUnlocks.new(_state.flags, _state.party)
	unlocks.set_location(_zones, func() -> StringName: return &"viridian_center")
	_director = MenuDirector.new()
	add_child_autofree(_director)
	_director.setup(_state, _data, _zones, ObjectiveLibrary.new(), unlocks,
		func() -> bool: return true)
	_director.storage_shown.connect(_views.append)
	assert_true(_director.open(MenuRoute.storage(), true))


func test_arrival_order_by_default() -> void:
	var all := _fill()
	assert_eq(StorageQuery.order(all, _data), [0, 1, 2, 3, 4, 5] as Array[int])


func test_search_by_species_name_ignores_case_and_accents() -> void:
	var all := _fill()
	assert_eq(StorageQuery.order(all, _data, "rouc"), [1, 3] as Array[int])
	assert_eq(StorageQuery.order(all, _data, "  RATTA "), [0] as Array[int])
	assert_eq(StorageQuery.order(all, _data, "salameche"), [2] as Array[int], "accents")
	assert_eq(StorageQuery.order(all, _data, "zzz"), [] as Array[int])


func test_sort_by_species_is_pokedex_order_and_stable() -> void:
	var all := _fill()
	# bulbasaur 1, charmander 4, squirtle 7, pidgey 16 (index 1 puis 3), rattata 19.
	assert_eq(StorageQuery.order(all, _data, "", Sort.SPECIES),
		[5, 2, 4, 1, 3, 0] as Array[int])


func test_sort_by_level_is_descending_and_stable() -> void:
	var all := _fill()
	# 9 (1), 7 (2 puis 4, arrivée conservée), 5 (0), 4 (5), 3 (3).
	assert_eq(StorageQuery.order(all, _data, "", Sort.LEVEL), [1, 2, 4, 0, 5, 3] as Array[int])


func test_sort_by_type_groups_same_primary_type() -> void:
	var all := _fill()
	var result := StorageQuery.order(all, _data, "", Sort.TYPE)
	assert_eq(result.size(), 6)
	var ranks := {}
	var ids := _data.get_type_chart().get_type_ids()
	for i: int in ids.size():
		ranks[ids[i]] = i
	var last := -1
	for i: int in result:
		var rank: int = ranks[_data.get_species(all[i].species_id).types[0]]
		assert_gte(rank, last, "types regroupés dans l'ordre du tableau des types")
		last = rank
	# Même type principal (les deux Roucool, index 1 et 3) : arrivée conservée.
	assert_lt(result.find(1), result.find(3))


func test_search_and_sort_combine() -> void:
	var all := _fill()
	assert_eq(StorageQuery.order(all, _data, "roucool", Sort.LEVEL), [1, 3] as Array[int])


func test_query_never_changes_the_real_list() -> void:
	var all := _fill()
	var before: Array[Pokemon] = _state.storage.get_all()
	StorageQuery.order(all, _data, "rouc", Sort.LEVEL)
	assert_eq(_state.storage.get_all(), before, "ordre réel intact")


func test_next_sort_cycles() -> void:
	var seen: Array[int] = []
	var sort := Sort.ARRIVAL
	for i: int in 4:
		seen.append(sort)
		sort = StorageQuery.next_sort(sort)
	assert_eq(seen, [0, 1, 2, 3] as Array[int])
	assert_eq(sort, Sort.ARRIVAL)
	assert_eq(StorageQuery.sort_label(Sort.SPECIES), "Tri : Espèce")


func test_view_keeps_real_indices_and_texts() -> void:
	_fill()
	_state.party.add(_mk(&"charmander", 10))
	var view := StorageViews.build(_state, _data, null, _zones, null, null, "rouc", Sort.LEVEL)
	assert_eq(view.storage.size(), 2)
	assert_eq(view.storage[0].index, 1)
	assert_eq(view.storage[0].member.party_index, 1)
	assert_eq(view.storage[1].index, 3)
	assert_eq(view.storage_total, 6)
	assert_eq(view.empty_text, "")
	var none := StorageViews.build(_state, _data, null, _zones, null, null, "zzz")
	assert_eq(none.empty_text, StorageQuery.NO_MATCH_TEXT)
	assert_eq(none.storage_total, 6)


func test_withdraw_targets_right_individual_while_filtered_and_sorted() -> void:
	var all := _fill()
	_state.party.add(_mk(&"charmander", 10))
	_director_open()
	_director.set_storage_query("rouc", Sort.LEVEL)
	assert_eq(_views.back().storage.size(), 2, "filtre actif")
	var target: Pokemon = all[3]  # Roucool 3, 2e carte affichée
	_director.select_storage(STORAGE, 3)
	assert_true(_director.withdraw_member(3))
	assert_eq(_state.party.get_all().back(), target, "le bon individu est repris")
	assert_eq(_state.storage.size(), 5)
	assert_false(_state.storage.get_all().has(target))
	var view: StorageView = _views.back()
	assert_eq(view.query_text, "rouc", "le filtre reste actif")
	assert_eq(view.storage.size(), 1)
	assert_eq(view.storage[0].index, 0 if all[1] == _state.storage.get_all()[0] else 1)


func test_favorite_targets_right_individual_while_sorted() -> void:
	var all := _fill()
	_state.party.add(_mk(&"charmander", 10))
	_director_open()
	_director.set_storage_query("", Sort.SPECIES)
	# Première carte affichée = Bulbizarre (index réel 5).
	assert_eq(_views.back().storage[0].index, 5)
	assert_true(_director.toggle_storage_favorite(STORAGE, _views.back().storage[0].index))
	assert_true(all[5].favorite)
	for i: int in 5:
		assert_false(all[i].favorite, "aucun autre Pokémon touché")


func test_query_resets_on_reopen_and_is_not_saved() -> void:
	_fill()
	_state.party.add(_mk(&"charmander", 10))
	_director_open()
	_director.set_storage_query("rat", Sort.TYPE)
	assert_eq(_views.back().storage.size(), 1)
	_director.close()
	assert_true(_director.open(MenuRoute.storage(), true))
	assert_eq(_views.back().query_text, "")
	assert_eq(_views.back().sort, Sort.ARRIVAL)
	assert_eq(_views.back().storage.size(), 6)
