extends GutTest
## L'écran Dresseur jouable avec le vrai Boot et la vraie partie de Kevin (jalon-06.md §6.11,
## T25). L'écran est un faux ([FakeMenu]) : le vrai TrainerScreen (T24) est relié par Boot
## s'il existe. Le Pokédex n'y est jamais montré avant l'activation (§4).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_t25_trainer_save.json"
const FIXTURE_V1 := "res://tests/fixtures/save/v1_after_capture.json"

var _boot: Boot
var _menu: MenuDirector
var _screen: Node


func before_each() -> void:
	GameState.clock = FixedClock.new("2026-10-03T10:00:00")


func after_each() -> void:
	get_tree().paused = false
	GameState.clock = DeviceClock.new()


## Partie de Kevin (sauvegarde v1 du S24, migrée par Boot) ; [param debug_unlock] : Pokédex
## visible par le déblocage de débogage.
func _start(debug_unlock: bool = false) -> void:
	var fs := MemoryFs.new()
	fs.files[SAVE_PATH] = FileAccess.get_file_as_string(FIXTURE_V1)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(fs, SAVE_PATH)
	if debug_unlock:
		_boot.force_debug_unlocks = true
		_boot.debug_unlocks_path = "res://tests/fixtures/debug_unlocks/pokedex.json"
	add_child_autofree(_boot)
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	_boot.get_trainer_menu().speed_scale = 0.0
	await wait_until(func() -> bool: return _boot.is_stable(), 12.0)


func _open_view() -> TrainerView:
	assert_true(_menu.open(MenuRoute.trainer()))
	assert_eq(_screen.trainers.size(), 1, "une vue à l'entrée")
	return _screen.trainers.back()


func _titles(view: TrainerView) -> Array[String]:
	var titles: Array[String] = []
	for moment: MomentView in view.moments:
		titles.append(moment.title)
	return titles


func test_kevins_save_tells_his_story_in_order() -> void:
	await _start()
	assert_true(_boot.has_resumed())
	var view := _open_view()
	assert_eq(view.player_name, GameState.player_name)
	assert_eq(view.started_text, "2 octobre 2026")
	assert_eq(_titles(view), ["Premier Pokémon", "Combat contre le rival", "Départ de Bourg Palette",
		"Première capture"] as Array[String])
	assert_false(_titles(view).has("Début de l'aventure"), "pas de moment de départ")
	var dates: Array[String] = []
	for moment: MomentView in view.moments:
		dates.append(moment.date)
	var sorted := dates.duplicate()
	sorted.sort()
	assert_eq(dates, sorted, "chronologie")
	_menu.close()


func test_eight_mute_badges_and_no_counter() -> void:
	await _start()
	var view := _open_view()
	assert_eq(view.badges.size(), 8)
	assert_eq(view.obtained_badges(), 0)
	for badge: BadgeSlotView in view.badges:
		assert_false(badge.obtained)
		assert_eq(badge.name, "", "emplacement muet")
	_menu.close()


func test_captures_are_the_career_captures() -> void:
	await _start()
	var view := _open_view()
	assert_eq(view.stat(&"captures").value_text, "2", "Roucool et Rattata, pas le starter")
	GameState.storage.add(GameState.party.get_at(2))
	GameState.party.clear()
	_menu.close()
	var after := _open_view_again()
	assert_eq(after.stat(&"captures").value_text, "2", "déposé ou relâché : inchangé")
	GameState.record_caught(&"caterpie", &"route_1")
	_menu.close()
	assert_eq(_open_view_again().stat(&"captures").value_text, "3", "une capture de plus")
	_menu.close()


func _open_view_again() -> TrainerView:
	var count: int = _screen.trainers.size()
	assert_true(_menu.open(MenuRoute.trainer()))
	assert_eq(_screen.trainers.size(), count + 1)
	return _screen.trainers.back()


func test_no_seen_nor_caught_without_the_dex() -> void:
	await _start()
	var view := _open_view()
	assert_eq(view.seen_text, "")
	assert_eq(view.caught_text, "")
	assert_null(view.seen_route)
	assert_null(view.caught_route)
	_menu.close()


func test_seen_and_caught_with_the_debug_flag_and_their_links() -> void:
	await _start(true)
	var view := _open_view()
	assert_ne(view.seen_text, "")
	assert_ne(view.caught_text, "")
	assert_not_null(view.seen_route)
	assert_true(_screen.route_requested.get_connections().size() > 0)
	_screen.route_requested.emit(view.caught_route)
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.POKEDEX)
	assert_eq(_screen.pokedex_grids.size(), 1)
	_menu.close()


func test_the_starter_moment_opens_his_team_sheet() -> void:
	await _start()
	var view := _open_view()
	var starter := view.moments[0]
	assert_eq(starter.species_id, &"charmander")
	assert_not_null(starter.route)
	_screen.route_requested.emit(starter.route)
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.TEAM)
	assert_eq(_screen.teams.size(), 1)
	_menu.close()


func test_the_starter_moment_falls_back_to_the_dex_sheet_when_visible() -> void:
	await _start(true)
	GameState.party.clear()
	var view := _open_view()
	var starter := view.moments[0]
	assert_not_null(starter.route)
	_screen.route_requested.emit(starter.route)
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.POKEDEX)
	assert_eq(_screen.pokedex_sheets.size(), 1)
	_menu.close()


func test_nothing_is_saved_by_looking_at_the_screen() -> void:
	await _start()
	_open_view()
	_menu.close()
	assert_false(_menu_changed(), "pas de mark_changed")


func _menu_changed() -> bool:
	var changed := [false]
	_menu.menu_closed.connect(func(c: bool) -> void: changed[0] = c)
	_menu.open(MenuRoute.trainer())
	_menu.close()
	return changed[0]
