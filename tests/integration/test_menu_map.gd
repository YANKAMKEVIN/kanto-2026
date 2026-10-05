extends GutTest
## La Carte jouable avec le vrai Boot (jalon-06.md §6.10, T21). L'écran est un faux
## ([FakeMenu]) : le vrai MapScreen (T20) est relié par Boot s'il existe.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_t21_map_save.json"

var _boot: Boot
var _menu: MenuDirector
var _screen: Node


func before_each() -> void:
	GameState.clock = FixedClock.new("2026-10-03T10:00:00")


func after_each() -> void:
	get_tree().paused = false
	GameState.clock = DeviceClock.new()


func _start(debug_unlock: bool = false) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	if debug_unlock:
		_boot.force_debug_unlocks = true
		_boot.debug_unlocks_path = "res://tests/fixtures/debug_unlocks/pokedex.json"
	add_child_autofree(_boot)
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	_boot.get_trainer_menu().speed_scale = 0.0
	await wait_until(func() -> bool: return _boot.is_stable(), 12.0)


func _ids(view: MapView) -> Array[StringName]:
	var ids: Array[StringName] = []
	for zone: MapZoneView in view.zones:
		ids.append(zone.zone_id)
	return ids


func _entry_ids(entries: Array[ZoneEntryView]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: ZoneEntryView in entries:
		ids.append(entry.id)
	return ids


func test_player_in_the_house_gets_pallet_town_portrait_and_panel() -> void:
	await _start()
	assert_eq(_boot.get_map().map_id, &"player_house_2f", "départ dans la chambre")
	assert_true(_menu.open(MenuRoute.map()))
	assert_eq(_screen.maps.size(), 1)
	var view: MapView = _screen.maps[0]
	assert_eq(view.player_zone, &"pallet_town")
	assert_eq(view.selected, &"pallet_town")
	assert_true(_ids(view).has(&"pallet_town"))
	assert_eq(_screen.map_zones.size(), 1, "un panneau")
	var panel: ZonePanelView = _screen.map_zones[0]
	assert_eq(panel.zone_id, &"pallet_town")
	assert_true(panel.current)
	assert_ne(panel.name, "")
	_menu.close()


func test_potion_found_on_route_1_is_listed_there_only() -> void:
	await _start()
	GameState.discover_map(&"route_1")
	GameState.record_item_found(&"potion", &"route_1")
	_menu.open(MenuRoute.map())
	_screen.map_zone_touched.emit(&"route_1")
	var route_panel: ZonePanelView = _screen.map_zones.back()
	assert_eq(route_panel.zone_id, &"route_1")
	assert_eq(_entry_ids(route_panel.items), [&"potion"] as Array[StringName])
	_screen.map_zone_touched.emit(&"pallet_town")
	var town_panel: ZonePanelView = _screen.map_zones.back()
	assert_eq(town_panel.zone_id, &"pallet_town")
	assert_eq(town_panel.items.size(), 0, "pas dans Bourg Palette")
	_menu.close()


func test_observed_pokemon_need_the_dex_to_be_visible() -> void:
	await _start()
	GameState.discover_map(&"route_1")
	GameState.record_seen(&"pidgey", &"route_1")
	_menu.open(MenuRoute.map(&"route_1"))
	assert_eq(_screen.map_zones.back().zone_id, &"route_1")
	assert_eq(_screen.map_zones.back().pokemon.size(), 0, "rien sans le Pokédex")
	_menu.close()


func test_observed_pokemon_are_listed_with_the_debug_flag() -> void:
	await _start(true)
	GameState.discover_map(&"route_1")
	GameState.record_seen(&"pidgey", &"route_1")
	_menu.open(MenuRoute.map(&"route_1"))
	var panel: ZonePanelView = _screen.map_zones.back()
	assert_eq(_entry_ids(panel.pokemon), [&"pidgey"] as Array[StringName])
	_menu.close()


func test_undiscovered_zone_gives_nothing() -> void:
	await _start()
	_menu.open(MenuRoute.map())
	var before: int = _screen.map_zones.size()
	_screen.map_zone_touched.emit(&"viridian_city")
	assert_eq(_screen.map_zones.size(), before, "aucun panneau")
	var view: MapView = _screen.maps[0]
	assert_false(_ids(view).has(&"viridian_city"), "ni vue ni nom")
	_menu.open_zone(&"zone_qui_n_existe_pas")
	assert_eq(_screen.map_zones.size(), before)
	_menu.close()


## Jalon 7 T4 : Jadielle découverte en y entrant ; l'Arène est dans ses services (vue depuis
## la ville), pas le Centre ni la Boutique tant qu'on n'y est pas entré (règle de déblocage).
func test_viridian_discovered_with_its_gym_only() -> void:
	await _start()
	GameState.discover_map(&"route_1")
	GameState.discover_map(&"viridian_city")
	_menu.open(MenuRoute.map(&"viridian_city"))
	var view: MapView = _screen.maps.back()
	assert_true(_ids(view).has(&"viridian_city"), "Jadielle sur la Carte")
	var panel: ZonePanelView = _screen.map_zones.back()
	assert_eq(panel.zone_id, &"viridian_city")
	assert_eq(panel.name, "Jadielle")
	assert_eq(_entry_ids(panel.services), [&"gym"] as Array[StringName])
	_menu.close()
	GameState.discover_map(&"viridian_center")
	_menu.open(MenuRoute.map(&"viridian_city"))
	panel = _screen.map_zones.back()
	assert_eq(_entry_ids(panel.services), [&"pokemon_center", &"gym"] as Array[StringName])
	_menu.close()


func test_habitat_link_arrives_on_the_chosen_zone_without_stacking() -> void:
	await _start(true)
	GameState.discover_map(&"route_1")
	_menu.open()
	assert_true(_menu.go(MenuRoute.pokedex()))
	var depth := _menu.get_navigator().depth()
	assert_true(_menu.go(MenuRoute.map(&"route_1")))
	assert_eq(_screen.maps.back().selected, &"route_1")
	assert_eq(_screen.map_zones.back().zone_id, &"route_1")
	assert_eq(_menu.get_navigator().depth(), depth + 1)
	assert_true(_menu.go(MenuRoute.pokedex()), "retour au Pokédex")
	assert_eq(_menu.get_navigator().depth(), depth, "pile inchangée")
	_menu.close()


func test_the_map_never_marks_the_game_as_changed() -> void:
	await _start()
	var changed: Array[bool] = []
	_menu.menu_closed.connect(changed.append)
	_menu.open(MenuRoute.map())
	_screen.map_zone_touched.emit(&"pallet_town")
	_menu.close()
	assert_eq(changed, [false] as Array[bool])
