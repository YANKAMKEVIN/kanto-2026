extends GutTest
## Écran Pokédex du menu (jalon 6, T15) : une case inconnue n'a ni image ni toucher, une case
## connue ouvre une seule fiche, un filtre = un seul signal, une espèce seulement vue n'a ni
## types, ni taille, ni poids, ni description, aucun « ??? » ni total dans un habitat, une zone
## d'Habitat touchée = un seul lien vers la Carte, retour qui ferme d'abord la fiche, zones
## tactiles et marges à 1920 et 2340, animation à speed_scale = 0.

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080
const Filter := PokedexQuery.Filter

var _data: PokemonData
var _lib: PokedexLibrary
var _zones: ZoneLibrary
var _dex: Pokedex
var _filters: Array = []
var _opened: Array[StringName] = []
var _routes: Array[MenuRoute] = []
var _backs: int = 0


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_lib = PokedexLibrary.new()
	_lib.load_file()
	_lib.check_references(_data)
	_zones = ZoneLibrary.new()
	_zones.load_file()


func before_each() -> void:
	_dex = Pokedex.new()
	_dex.mark_caught(&"charmander", &"oak_lab")
	_dex.mark_seen(&"squirtle", &"oak_lab")
	_dex.mark_seen(&"pidgey", &"pallet_town")
	_dex.mark_caught(&"pidgey", &"pallet_town")
	_dex.mark_seen(&"pidgey", &"route_1")
	PokedexNotes.refresh(_dex, _lib, null)
	_filters.clear()
	_opened.clear()
	_routes.clear()
	_backs = 0


func _grid(filter: int = Filter.ALL, zone: StringName = &"", type: StringName = &"",
		text: String = "") -> PokedexGridView:
	return PokedexQuery.grid(_dex, _data, _lib, _zones, filter, zone, type, text)


func _sheet(species: StringName) -> PokedexSheetView:
	return PokedexQuery.sheet(species, _dex, _data, _lib, _zones)


func _screen_in(width: int, view: PokedexGridView) -> PokedexScreen:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.show_pokedex(view)
	menu.open_animated()
	await wait_frames(3)
	var screen := menu.get_pokedex()
	screen.filter_changed.connect(func(f: int, z: StringName, t: StringName, x: String) -> void:
		_filters.append([f, z, t, x]))
	screen.species_opened.connect(func(s: StringName) -> void: _opened.append(s))
	screen.route_requested.connect(func(r: MenuRoute) -> void: _routes.append(r))
	screen.back_requested.connect(func() -> void: _backs += 1)
	return screen


func _mouse(pressed: bool, pos: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	return event


func _tap(tile: BagTile) -> void:
	var pos := tile.size * 0.5
	tile._gui_input(_mouse(true, pos))
	tile._gui_input(_mouse(false, pos))


func test_grid_has_151_cells_with_title_and_counts() -> void:
	var screen := await _screen_in(2340, _grid())
	assert_eq(screen.get_slots().size(), 151)
	assert_eq(screen.get_title_label().text, "POKÉDEX — KANTO")
	assert_eq(screen.get_counts_label().text, "3 vus · 2 capturés · 151 espèces")
	assert_false(screen.is_sheet_open())


func test_unknown_cell_has_no_image_and_no_touch() -> void:
	var screen := await _screen_in(2340, _grid())
	var unknown := screen.get_slot(2)
	assert_eq(unknown.get_texts(), PackedStringArray(["002", "???"]))
	assert_false(unknown.has_image(), "ni image ni silhouette")
	assert_eq(unknown.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_tap(unknown)
	assert_true(_opened.is_empty(), "aucun toucher")


func test_known_cell_opens_one_sheet() -> void:
	var screen := await _screen_in(2340, _grid())
	var slot := screen.get_slot(4)
	assert_true(slot.has_image(), "Salamèche a son sprite")
	assert_eq(slot.get_texts(), PackedStringArray(["004", "Salamèche", "Capturé"]))
	_tap(slot)
	assert_eq(_opened, [&"charmander"])
	assert_eq(screen.get_slot(7).get_texts()[2], "Vu", "vu : texte, pas seulement une couleur")


func test_filter_buttons_emit_one_signal_each() -> void:
	var screen := await _screen_in(2340, _grid())
	var buttons := screen.get_filter_buttons()
	assert_eq(buttons[0].text, "TOUS")
	assert_eq(buttons[3].text, "HABITATS")
	buttons[2].pressed.emit()
	assert_eq(_filters, [[Filter.CAUGHT, &"", &"", ""]])
	buttons[0].pressed.emit()
	assert_eq(_filters.size(), 1, "le filtre actif ne réémet rien")


func test_search_and_type_each_emit_one_signal() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.get_search().text_changed.emit("sal")
	assert_eq(_filters, [[Filter.ALL, &"", &"", "sal"]])
	_filters.clear()
	assert_true(screen.get_type_button().visible, "types des capturées")
	screen.get_type_button().pressed.emit()
	assert_eq(_filters.size(), 1)
	assert_ne(_filters[0][2], &"")


func test_filter_view_keeps_screen_and_updates_cells() -> void:
	var screen := await _screen_in(2340, _grid())
	var pool := screen.get_pool_size()
	screen.show_grid(_grid(Filter.CAUGHT))
	assert_eq(screen.get_slots().size(), 2)
	assert_eq(screen.get_pool_size(), pool, "cases réutilisées, pas recréées")
	assert_true(screen.get_filter_buttons()[2].button_pressed)
	assert_eq(screen.modulate.a, 1.0, "pas de nouvelle entrée")


func test_empty_search_shows_the_phrase_not_cells() -> void:
	var screen := await _screen_in(2340, _grid(Filter.ALL, &"", &"", "zzz"))
	assert_true(screen.get_empty_label().visible)
	assert_eq(screen.get_empty_label().text, "Aucune espèce ne correspond.")
	assert_true(screen.get_slots().is_empty())
	assert_false(screen.get_scroll().visible)


func test_seen_only_sheet_has_no_types_size_weight_or_description() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"squirtle"))
	var sheet := screen.get_sheet()
	assert_eq(sheet.get_type_row().get_child_count(), 0, "aucun type")
	var texts := " | ".join(sheet.get_texts(PokedexSheet.Tab.OVERVIEW))
	for absent: String in ["Taille", "Poids", "kg"]:
		assert_false(texts.contains(absent), "« %s » absent" % absent)
	assert_eq(sheet.get_view().description, "")
	assert_false(" | ".join(sheet.get_texts()).contains("???"), "aucun « ??? » sur une fiche vue")


func test_caught_sheet_shows_full_overview() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"charmander"))
	var sheet := screen.get_sheet()
	assert_eq(sheet.get_type_row().get_child_count(), 1)
	var texts := " | ".join(sheet.get_texts(PokedexSheet.Tab.OVERVIEW))
	assert_true(texts.contains("0,6 m") and texts.contains("8,5 kg"), texts)
	assert_true(screen.is_sheet_open())


func test_habitat_has_no_total_nor_unknown_and_one_route_per_touch() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"pidgey"))
	var sheet := screen.get_sheet()
	sheet.select_tab(PokedexSheet.Tab.HABITAT)
	var texts := " | ".join(sheet.get_texts(PokedexSheet.Tab.HABITAT))
	assert_false(texts.contains("???"))
	assert_eq(sheet.get_chips().size(), 2, "seulement les deux zones observées")
	assert_eq(sheet.get_map().get_zone_ids(), [&"pallet_town", &"route_1"])
	sheet.get_chips()[1].pressed.emit()
	assert_eq(_routes.size(), 1)
	assert_eq(_routes[0].screen, MenuRoute.MAP)
	assert_eq(_routes[0].params["zone"], &"route_1")


func test_tabs_keep_one_pressed_and_stay_open_on_new_species() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"charmander"))
	var sheet := screen.get_sheet()
	sheet.select_tab(PokedexSheet.Tab.EVOLUTION)
	screen.show_sheet(_sheet(&"pidgey"))
	assert_eq(sheet.get_tab(), PokedexSheet.Tab.EVOLUTION)
	var pressed := 0
	for tab: int in 4:
		pressed += 1 if sheet.get_tab_button(tab as PokedexSheet.Tab).button_pressed else 0
	assert_eq(pressed, 1)
	assert_eq(screen.modulate.a, 1.0)


func test_back_closes_sheet_first_then_leaves() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"charmander"))
	screen.get_back_button().pressed.emit()
	assert_false(screen.is_sheet_open())
	assert_eq(_backs, 0, "le premier retour ferme la fiche")
	screen.get_back_button().pressed.emit()
	assert_eq(_backs, 1)
	assert_false(screen.close_sheet())


func test_sheet_entry_is_instant_at_speed_scale_zero() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"charmander"))
	assert_eq(screen.get_sheet_panel().modulate.a, 1.0)


func _interactive(node: Node, found: Array[Control]) -> void:
	var control := node as Control
	if control != null and control.is_visible_in_tree() and (control is BaseButton
			or control is LineEdit or (control is PokedexSlot
			and control.mouse_filter == Control.MOUSE_FILTER_STOP)):
		found.append(control)
	for child: Node in node.get_children():
		_interactive(child, found)


func test_touch_targets_and_margins_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width, _grid())
		screen.show_sheet(_sheet(&"pidgey"))
		screen.get_sheet().select_tab(PokedexSheet.Tab.HABITAT)
		await wait_frames(3)
		var found: Array[Control] = []
		_interactive(screen, found)
		assert_gt(found.size(), 12, "des éléments interactifs à %d" % width)
		for control: Control in found:
			var rect := control.get_global_rect()
			assert_gte(rect.size.y, UiTokens.TOUCH_MIN - 0.5,
				"%s ≥ TOUCH_MIN à %d" % [control.name, width])
			assert_gte(rect.position.x, UiTokens.SAFE_MARGIN - 0.5, "marge gauche %d" % width)
			assert_lte(rect.end.x, width - UiTokens.SAFE_MARGIN + 0.5, "marge droite %d" % width)
			if not control is PokedexSlot:
				assert_gte(rect.position.y, UiTokens.SAFE_MARGIN - 0.5)
				assert_lte(rect.end.y, HEIGHT - UiTokens.SAFE_MARGIN + 0.5, "marge basse")
