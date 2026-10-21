extends GutTest
## Vol hors combat (passe systèmes 2, `systemes-2.md` §2.8, T24–T25) : [method FlyRules.can_fly_to],
## [FlyDirector] (conditions sur la carte courante, envol, arrivée) et bouton « S'ENVOLER » de la
## Carte ([ZonePanel], [MenuDirector]). Routeur et coureur de dialogues factices.

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const READY := FieldMoves.State.READY


class FakeRouter:
	extends Node
	var calls: Array[Array] = []

	func change_map(map_id: StringName, spawn: StringName, facing: Vector2i = Vector2i.ZERO) -> void:
		calls.append([map_id, spawn, facing])


var _rules: FlyRules
var _map: GameMap
var _player: Player
var _router: FakeRouter
var _caves: CaveLibrary
var _director: FlyDirector
var _state: FieldMoves.State = READY
var _discovered: Dictionary = {}


func before_each() -> void:
	_state = READY
	_discovered = {&"pallet_town": "", &"pewter_city": ""}
	_rules = FlyRules.new()
	assert_true(_rules.load_file())
	_caves = CaveLibrary.new()
	assert_true(_caves.load_file())
	_map = _make_map(&"route_1", false)
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_player.set_process(false)
	_router = FakeRouter.new()
	add_child_autofree(_router)
	_director = FlyDirector.new()
	add_child_autofree(_director)
	_director.setup(_rules, func() -> Dictionary: return _discovered,
		func(_move: StringName) -> FieldMoves.Result: return FieldMoves.Result.new(_state),
		_caves, func() -> GameMap: return _map, _player, null, _router)


func _make_map(map_id: StringName, interior: bool) -> GameMap:
	var map := GameMap.new()
	map.map_id = map_id
	map.interior = interior
	autofree(map)
	return map


# --- Règle -----------------------------------------------------------------------------

func test_can_fly_to_needs_an_open_destination() -> void:
	var outdoors := MapTraits.new()
	assert_eq(_rules.can_fly_to(&"pewter_city", READY, outdoors, _discovered), FlyRules.Check.OK)
	assert_eq(_rules.can_fly_to(&"cerulean_city", READY, outdoors, _discovered),
		FlyRules.Check.CLOSED, "ville pas encore visitée")
	assert_eq(_rules.can_fly_to(&"route_1", READY, outdoors, _discovered),
		FlyRules.Check.CLOSED, "une route n'est pas une destination")
	assert_eq(_rules.can_fly_to(&"pewter_city", FieldMoves.State.NO_BADGE, outdoors,
		_discovered), FlyRules.Check.NO_BADGE, "conditions d'abord")


func test_traits_of_a_cave_forbid_flying() -> void:
	assert_true(FlyRules.traits_of(false, true).no_fly)
	assert_true(FlyRules.traits_of(true, false).interior)
	assert_false(FlyRules.traits_of(false, false).no_fly)


# --- Directeur -------------------------------------------------------------------------

func test_director_checks_the_current_map() -> void:
	assert_eq(_director.check(&"pewter_city"), FlyRules.Check.OK)
	assert_true(_director.can_fly_to(&"pewter_city"))
	_map = _make_map(&"red_house_1f", true)
	assert_eq(_director.check(&"pewter_city"), FlyRules.Check.INDOORS)
	var cave: StringName = _caves.get_maps(_caves.get_caves()[0])[0]
	_map = _make_map(cave, false)
	assert_eq(_director.check(&"pewter_city"), FlyRules.Check.NO_FLY, "pas de Vol en grotte")
	_map = _make_map(&"route_1", false)
	_state = FieldMoves.State.NO_HM
	assert_eq(_director.check(&"pewter_city"), FlyRules.Check.NO_HM)


func test_fly_goes_to_the_arrival_point_and_frees_the_player() -> void:
	watch_signals(_director)
	await _director.fly(&"pewter_city")
	assert_eq(_router.calls, [[&"pewter_city", &"from_center", Vector2i.DOWN]] as Array[Array])
	assert_signal_emitted_with_parameters(_director, "flight_started", [&"pewter_city"])
	assert_signal_emitted_with_parameters(_director, "flight_finished", [&"pewter_city"])
	assert_true(_player.is_input_enabled())
	assert_eq(_player.modulate.a, 1.0, "joueur de nouveau visible")
	assert_false(_director.is_flying())


func test_fly_to_a_closed_town_does_nothing() -> void:
	await _director.fly(&"cerulean_city")
	assert_eq(_router.calls.size(), 0)
	assert_true(_player.is_input_enabled())


func test_pallet_town_arrives_in_front_of_the_house() -> void:
	await _director.fly(&"pallet_town")
	assert_eq(_router.calls[0][1], &"player_house_door")


func test_flight_texts_exist_with_the_field_variant() -> void:
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_true(dialogues.has_dialogue(FlyDirector.TAKEOFF_DIALOGUE))
	assert_true(dialogues.has_dialogue(FlyDirector.LANDING_DIALOGUE))


# --- Carte du menu ---------------------------------------------------------------------

func test_zone_panel_shows_the_fly_button_only_when_allowed() -> void:
	var panel := ZonePanel.new()
	add_child_autofree(panel)
	var view := ZonePanelView.new()
	view.zone_id = &"pewter_city"
	view.name = "Argenta"
	panel.show_zone(view)
	assert_null(panel.get_fly_button())
	view = ZonePanelView.new()
	view.zone_id = &"pewter_city"
	view.name = "Argenta"
	view.fly_available = true
	panel.show_zone(view)
	await get_tree().process_frame
	var button := panel.get_fly_button()
	assert_not_null(button)
	assert_eq(button.text, "S'ENVOLER")
	watch_signals(panel)
	button.pressed.emit()
	assert_signal_emitted_with_parameters(panel, "fly_requested", [&"pewter_city"])


func test_menu_director_rechecks_before_flying() -> void:
	var menu := MenuDirector.new()
	add_child_autofree(menu)
	var allowed := {&"pewter_city": true}
	menu.set_fly_check(func(zone: StringName) -> bool: return allowed.has(zone))
	watch_signals(menu)
	menu.request_fly(&"cerulean_city")
	assert_signal_not_emitted(menu, "fly_requested")
	menu.request_fly(&"pewter_city")
	assert_signal_emitted_with_parameters(menu, "fly_requested", [&"pewter_city"])
