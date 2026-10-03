extends GutTest
## Écran Carte du menu (jalon 6, T20 ; §6.10) : une zone non découverte n'a ni étiquette ni
## toucher, une zone découverte touchée émet un seul signal, le panneau s'affiche sans changer
## d'écran, une section vide n'a pas de titre, un Pokémon touché = un seul lien vers le Pokédex,
## aucun total ni « ??? » ni « Se rendre », zones tactiles et marges à 1920 et 2340, animation
## à speed_scale = 0.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _data: PokemonData
var _zones: ZoneLibrary
var _items: ItemLibrary
var _art: MapIllustration
var _state: Node
var _touched: Array[StringName] = []
var _routes: Array[MenuRoute] = []
var _backs: int = 0
var _menu: TrainerMenu


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()
	_items = ItemLibrary.new()
	_items.load_dir()
	_art = MapIllustration.new()
	_art.load_file()


func before_each() -> void:
	_state = GameStateScript.new()
	_state.new_game(7)
	var clock := FixedClock.new("2026-09-30T10:03:00")
	_state.clock = clock
	_state.discover_map(&"pallet_town")
	clock.iso = "2026-10-02T18:00:00"
	_state.discover_map(&"route_1")
	_state.set_player_location(&"pallet_town", Vector2i.ZERO, Vector2i.DOWN)
	_state.record_seen(&"rattata", &"route_1")
	_state.record_seen(&"pidgey", &"route_1")
	_state.record_item_found(&"potion", &"route_1")
	_touched.clear()
	_routes.clear()
	_backs = 0


func after_each() -> void:
	_state.free()


func _view() -> MapView:
	return MapJournal.view(_state, _zones, _art)


func _panel(zone: StringName = &"route_1", pokedex_visible: bool = true) -> ZonePanelView:
	return MapJournal.panel(zone, _state, _data, _zones, _items, pokedex_visible)


func _screen_in(width: int, view: MapView, panel: ZonePanelView = null) -> MapScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.show_map(view)
	if panel != null:
		menu.show_map_zone(panel)
	menu.open_animated()
	_menu = menu
	await wait_process_frames(3)
	var screen := menu.get_map()
	screen.zone_touched.connect(func(z: StringName) -> void: _touched.append(z))
	screen.route_requested.connect(func(r: MenuRoute) -> void: _routes.append(r))
	screen.back_requested.connect(func() -> void: _backs += 1)
	return screen


func _mouse(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	return event


## Un toucher (appui puis relâchement) à [param pos] (repère de l'illustration).
func _tap(screen: MapScreen, pos: Vector2) -> void:
	var canvas := screen.get_map_canvas()
	canvas._gui_input(_mouse(true, pos))
	canvas._gui_input(_mouse(false, pos))


## Centre, sur l'illustration, du rectangle de [param zone] (même non découverte).
func _center_of(screen: MapScreen, zone: StringName) -> Vector2:
	var area := Rect2(_art.area_of(zone))
	return screen.get_map_canvas().image_to_local(area.get_center())


func _all_labels(node: Node, into: Array[Label]) -> void:
	for child: Node in node.get_children():
		var label := child as Label
		if label != null and label.is_visible_in_tree():
			into.append(label)
		_all_labels(child, into)


# --- Zones découvertes et non découvertes -----------------------------------------------------


func test_undiscovered_zone_has_no_label_and_no_touch() -> void:
	var screen := await _screen_in(2340, _view())
	var canvas := screen.get_map_canvas()
	var labels := canvas.get_label_texts()
	assert_eq(labels.keys(), [&"pallet_town", &"route_1"], "seulement les zones découvertes")
	assert_eq(labels[&"pallet_town"], "Bourg Palette")
	var names := PackedStringArray()
	for text: String in labels.values():
		names.append(text)
	assert_false(names.has("Jadielle"))
	assert_false(names.has("Argenta"))
	for zone: StringName in [&"viridian_city", &"pewter_city", &"cerulean_city", &"cinnabar_island"]:
		assert_null(canvas.get_label(zone), "pas d'étiquette pour %s" % zone)
		assert_eq(canvas.zone_at(_center_of(screen, zone)), &"", "pas de toucher pour %s" % zone)
		_tap(screen, _center_of(screen, zone))
	assert_true(_touched.is_empty(), "aucun signal")


func test_discovered_zone_touched_emits_one_signal() -> void:
	var screen := await _screen_in(2340, _view())
	_tap(screen, _center_of(screen, &"pallet_town"))
	assert_eq(_touched, [&"pallet_town"])
	_tap(screen, _center_of(screen, &"route_1"))
	assert_eq(_touched, [&"pallet_town", &"route_1"])


func test_touch_released_on_another_zone_emits_nothing() -> void:
	var screen := await _screen_in(2340, _view())
	var canvas := screen.get_map_canvas()
	canvas._gui_input(_mouse(true, _center_of(screen, &"pallet_town")))
	canvas._gui_input(_mouse(false, _center_of(screen, &"route_1")))
	assert_true(_touched.is_empty())
	canvas._gui_input(_mouse(true, Vector2(2, 2)))
	canvas._gui_input(_mouse(false, Vector2(2, 2)))
	assert_true(_touched.is_empty(), "l'eau ne répond pas")


func test_touch_areas_are_at_least_touch_min_and_never_steal_a_neighbour() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width, _view())
		var canvas := screen.get_map_canvas()
		var route := canvas.touch_rect(&"route_1")
		assert_gte(route.size.x, float(UiTokens.TOUCH_MIN), "Route 1 à %d : largeur" % width)
		assert_gte(route.size.y, float(UiTokens.TOUCH_MIN), "Route 1 à %d : hauteur" % width)
		assert_lt(canvas.zone_rect(&"route_1").size.x, float(UiTokens.TOUCH_MIN),
			"la Route 1 est fine sur l'illustration")
		assert_true(route.encloses(canvas.zone_rect(&"route_1")))
		# Un point dans le vrai rectangle d'une zone est toujours à elle.
		for zone: StringName in [&"pallet_town", &"route_1"]:
			var rect := canvas.zone_rect(zone)
			for corner: Vector2 in [rect.position + Vector2.ONE, rect.end - Vector2.ONE,
					rect.get_center()]:
				assert_eq(canvas.zone_at(corner), zone, "%s à %d" % [zone, width])
		# Dans la zone agrandie de la Route 1 mais hors de son rectangle : à elle, sauf si le
		# point est dans le vrai rectangle de Bourg Palette.
		var beside := Vector2(route.end.x - 2.0, route.position.y + 4.0)
		assert_eq(canvas.zone_at(beside), &"route_1")


# --- Panneau ----------------------------------------------------------------------------------


func test_show_zone_shows_panel_without_changing_screen() -> void:
	var view := _view()
	var screen := await _screen_in(2340, view)
	var menu := _menu
	assert_false(screen.get_panel().visible, "pas de panneau tant que le directeur n'a rien dit")
	menu.show_map_zone(_panel())
	assert_eq(menu.get_current_screen(), screen, "même écran")
	assert_true(screen.get_panel().visible)
	assert_eq(screen.get_map_canvas().get_selected(), &"route_1", "zone mise en avant")
	assert_eq(screen.get_panel().get_texts()[0], "Route 1")
	assert_true(_touched.is_empty() and _routes.is_empty(), "rien n'est émis par le panneau")


func test_panel_shows_name_subtitle_description_and_sections() -> void:
	var screen := await _screen_in(2340, _view(), _panel())
	var texts := screen.get_panel().get_texts()
	assert_true(texts.has("Route 1"))
	assert_true(texts.has("Bourg Palette — Jadielle"), "le sous-titre annonce Jadielle")
	assert_true(texts.has(ZonePanelView.POKEMON_TITLE))
	assert_true(texts.has("Rattata"))
	assert_true(texts.has("Roucool"))
	assert_true(texts.has(ZonePanelView.ITEMS_TITLE))
	assert_true(texts.has("Potion"))
	assert_false(texts.has(ZonePanelView.SERVICES_TITLE), "aucun service au J6")
	assert_eq(screen.get_panel().get_pokemon_entries().size(), 2)


func test_empty_sections_have_no_title() -> void:
	var screen := await _screen_in(2340, _view(), _panel(&"pallet_town", false))
	var texts := screen.get_panel().get_texts()
	assert_true(texts.has("Bourg Palette"))
	assert_false(texts.has(ZonePanelView.POKEMON_TITLE), "Pokédex pas visible : aucun Pokémon")
	assert_false(texts.has(ZonePanelView.ITEMS_TITLE))
	assert_false(texts.has(ZonePanelView.SERVICES_TITLE))
	assert_true(screen.get_panel().get_pokemon_entries().is_empty())
	var bare := ZonePanelView.new()
	bare.zone_id = &"route_1"
	bare.name = "Route 1"
	screen.get_panel().show_zone(bare)
	assert_eq(screen.get_panel().get_texts(), PackedStringArray(["Route 1"]),
		"texte vide = absent, liste vide = section absente")


func test_pokemon_touch_emits_one_pokedex_route() -> void:
	var screen := await _screen_in(2340, _view(), _panel())
	var cell := screen.get_panel().get_pokemon_entries()[0]
	cell.pressed.emit()
	assert_eq(_routes.size(), 1)
	assert_eq(_routes[0].screen, MenuRoute.POKEDEX)
	assert_eq(_routes[0].params["filter"], MenuRoute.DEX_FILTER_ALL)
	var first := _panel().pokemon[0].id
	assert_eq(_routes[0].params["species"], first)
	assert_true(_touched.is_empty())


func test_pokemon_without_sprite_shows_the_name_only() -> void:
	var view := _panel()
	view.pokemon.clear()
	view.pokemon.append(ZoneEntryView.new(&"missingno", "Inconnu au bataillon"))
	var screen := await _screen_in(2340, _view(), view)
	var cell := screen.get_panel().get_pokemon_entries()[0]
	var arts: Array[Node] = cell.find_children("*", "TextureRect", true, false)
	assert_true(arts.is_empty(), "jamais une silhouette")
	assert_true(screen.get_panel().get_texts().has("Inconnu au bataillon"))


func test_item_found_twice_shows_count_text() -> void:
	_state.record_item_found(&"potion", &"route_1")
	var screen := await _screen_in(2340, _view(), _panel())
	assert_true(screen.get_panel().get_texts().has("×2"))


func test_zone_change_replaces_panel_content() -> void:
	var screen := await _screen_in(2340, _view(), _panel())
	screen.show_zone(_panel(&"pallet_town"))
	var texts := screen.get_panel().get_texts()
	assert_true(texts.has("Bourg Palette"))
	assert_false(texts.has("Route 1"), "les anciens nœuds sont retirés tout de suite")
	assert_eq(screen.get_map_canvas().get_selected(), &"pallet_town")


# --- Texte, portrait, placement ---------------------------------------------------------------


func test_no_total_no_unknown_marker_no_travel_button() -> void:
	var screen := await _screen_in(2340, _view(), _panel())
	var labels: Array[Label] = []
	_all_labels(screen, labels)
	assert_gt(labels.size(), 4)
	var total := RegEx.create_from_string("/\\s*\\d")
	for label: Label in labels:
		assert_false(label.text.contains("???"), "« ??? » dans %s" % label.text)
		assert_false(label.text.contains("Se rendre"), label.text)
		assert_null(total.search(label.text), "total dans %s" % label.text)
	for button: Node in screen.find_children("*", "Button", true, false):
		assert_false((button as Button).text.contains("Se rendre"))


func test_player_portrait_is_centered_on_player_area() -> void:
	var view := _view()
	var screen := await _screen_in(2340, view)
	var canvas := screen.get_map_canvas()
	var portrait := canvas.get_portrait()
	assert_true(portrait.visible)
	var wanted := canvas.image_to_local(view.player_area().get_center())
	var got := portrait.position + portrait.size * 0.5
	assert_almost_eq(got.x, wanted.x, 1.0)
	assert_almost_eq(got.y, wanted.y, 1.0)
	assert_eq(view.player_zone, &"pallet_town")


func test_no_portrait_without_player_zone() -> void:
	var view := _view()
	view.player_zone = &""
	var screen := await _screen_in(2340, view)
	assert_false(screen.get_map_canvas().get_portrait().visible)


func test_illustration_is_whole_and_keeps_its_ratio() -> void:
	for width: int in WIDTHS:
		var view := _view()
		var screen := await _screen_in(width, view)
		var canvas := screen.get_map_canvas()
		var rect := canvas.get_image_rect()
		assert_almost_eq(rect.size.x / rect.size.y,
			float(view.image_size.x) / float(view.image_size.y), 0.01)
		assert_true(Rect2(Vector2.ZERO, canvas.size).encloses(rect.grow(-0.5)),
			"image entière à %d" % width)
		assert_gt(canvas.get_image_scale(), 0.5, "assez grande pour se lire")


func test_touch_targets_and_safe_margins_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width, _view(), _panel())
		var back := screen.get_back_button()
		assert_gte(back.size.y, float(UiTokens.TOUCH_MIN), "RETOUR à %d" % width)
		assert_gte(back.get_global_rect().position.x, float(UiTokens.SAFE_MARGIN))
		for cell: Button in screen.get_panel().get_pokemon_entries():
			assert_gte(cell.size.x, float(UiTokens.TOUCH_MIN))
			assert_gte(cell.size.y, float(UiTokens.TOUCH_MIN))
		for node: Control in [screen.get_map_canvas(), screen.get_panel(), back]:
			var rect := node.get_global_rect()
			assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN) - 0.5,
				"bord gauche à %d" % width)
			assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN) + 0.5,
				"bord droit à %d" % width)
			assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN) - 0.5)
			assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN) + 0.5,
				"bord bas à %d" % width)


func test_back_emits_one_signal() -> void:
	var screen := await _screen_in(2340, _view(), _panel())
	screen.get_back_button().pressed.emit()
	assert_eq(_backs, 1)


# --- Animation, mise à jour ---------------------------------------------------------------------


func test_instant_at_zero_speed_scale() -> void:
	var screen := await _screen_in(2340, _view(), _panel())
	assert_eq(screen.modulate.a, 1.0)
	assert_eq(screen.position, Vector2.ZERO)
	assert_eq(screen.get_panel().modulate.a, 1.0)


func test_show_map_again_updates_without_duplicating() -> void:
	var screen := await _screen_in(2340, _view(), _panel())
	var menu := _menu
	var more := _view()
	var extra := MapZoneView.new()
	extra.zone_id = &"mt_moon"
	extra.name = "Mont Sélénite"
	extra.kind = ZoneData.KIND_PLACE
	extra.area = Rect2(_art.area_of(&"mt_moon"))
	more.zones.append(extra)
	menu.show_map(more)
	await wait_process_frames(2)
	assert_eq(menu.get_current_screen(), screen)
	assert_eq(screen.get_map_canvas().get_label_texts().size(), 3)
	assert_eq(screen.get_map_canvas().get_selected(), &"route_1", "le panneau reste")
	assert_eq(screen.modulate.a, 1.0, "l'entrée n'est pas rejouée")
