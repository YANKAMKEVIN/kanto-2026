extends GutTest
## Écran Pokédex du menu (jalon 6, T15) : une case inconnue n'a ni image ni toucher, une case
## connue ouvre une seule fiche, un filtre = un seul signal, une espèce seulement vue n'a ni
## types, ni taille, ni poids, ni description, aucun « ??? » ni total dans un habitat, une zone
## d'Habitat touchée = un seul lien vers la Carte, RETOUR qui quitte directement (refonte T3 :
## trois colonnes permanentes), zones tactiles et marges à 1920 et 2340, animation à
## speed_scale = 0.

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


func test_unknown_cell_has_no_image_and_no_touch() -> void:
	var screen := await _screen_in(2340, _grid())
	var unknown := screen.get_slot(2)
	assert_eq(unknown.get_texts(), PackedStringArray(["002"]), "numéro seul, jamais de nom")
	assert_true(unknown.has_silhouette(), "silhouette, pas d'image en clair")
	assert_eq(unknown.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	_tap(unknown)
	assert_true(_opened.is_empty(), "aucun toucher")


func test_known_cell_opens_one_sheet() -> void:
	var screen := await _screen_in(2340, _grid())
	var slot := screen.get_slot(4)
	assert_true(slot.has_image(), "Salamèche a son sprite")
	assert_eq(slot.get_texts(), PackedStringArray(["004", "Salamèche"]))
	assert_true(slot.has_ball(), "capturé : Poké Ball")
	_tap(slot)
	assert_eq(_opened, [&"charmander"])
	assert_false(screen.get_slot(7).has_ball(), "seulement vu : pas de Poké Ball")


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


func test_seen_only_species_has_no_types_size_weight_description_or_unknown_mark() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"squirtle"))
	var sheet := screen.get_sheet()
	var portrait := screen.get_portrait()
	assert_eq(sheet.get_type_row().get_child_count(), 0, "aucun type")
	assert_eq(portrait.get_type_row().get_child_count(), 0, "aucun type sous le nom")
	var texts := " | ".join(sheet.get_texts(PokedexSheet.Tab.OVERVIEW)
		+ portrait.get_texts())
	for absent: String in ["Taille", "Poids", "kg", "Capturé", "Types"]:
		assert_false(texts.contains(absent), "« %s » absent" % absent)
	assert_false(portrait.get_caught_card().visible, "pas de carte Capturé")
	assert_true(portrait.get_seen_card().visible)
	assert_eq(sheet.get_view().description, "")
	var facts := " | ".join(portrait.get_texts())
	assert_false(facts.contains("???"), "aucun « ??? » dans la colonne du portrait")


func test_caught_species_shows_everything() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"charmander"))
	var sheet := screen.get_sheet()
	var portrait := screen.get_portrait()
	assert_eq(sheet.get_type_row().get_child_count(), 1)
	assert_eq(portrait.get_type_row().get_child_count(), 1)
	var texts := " | ".join(sheet.get_texts(PokedexSheet.Tab.OVERVIEW))
	assert_true(texts.contains("0,6 m") and texts.contains("8,5 kg"), texts)
	assert_true(portrait.get_caught_card().visible)
	assert_eq(portrait.get_description().text, _lib.get_species(&"charmander").description)
	assert_true(screen.is_sheet_open())


func test_never_any_stats_or_abilities() -> void:
	var screen := await _screen_in(2340, _grid())
	for species: StringName in [&"charmander", &"squirtle", &"pidgey"]:
		screen.show_sheet(_sheet(species))
		var texts := " | ".join(screen.get_sheet().get_texts() + screen.get_portrait().get_texts())
		for word: String in ["PV", "Attaque", "Défense", "Vitesse", "Talent", "Statistiques"]:
			assert_false(texts.contains(word), "%s : « %s »" % [species, word])


func test_portrait_loads_official_art_and_breathes() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.speed_scale = 1.0
	screen.show_sheet(_sheet(&"charmander"))
	var portrait := screen.get_portrait()
	assert_eq(portrait.get_art_path(), "res://assets/sprites/pokemon/official/004.png")
	assert_true(portrait.is_breathing(), "respiration")
	screen.speed_scale = 0.0
	portrait.speed_scale = 0.0
	screen.show_sheet(_sheet(&"pidgey"))
	portrait.show_species(_sheet(&"squirtle"))
	assert_false(portrait.is_breathing(), "pas de respiration à speed_scale = 0")
	assert_eq(portrait.get_art_path(), "res://assets/sprites/pokemon/official/007.png")


func test_overview_habitat_preview_opens_the_habitat_tab() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"pidgey"))
	var sheet := screen.get_sheet()
	var preview := sheet.get_habitat_preview()
	assert_not_null(preview)
	assert_true(" | ".join(sheet.get_texts(PokedexSheet.Tab.OVERVIEW)).contains(
		"Zones observées : 2"))
	preview.pressed.emit()
	assert_eq(sheet.get_tab(), PokedexSheet.Tab.HABITAT)
	assert_true(_routes.is_empty(), "l'aperçu n'ouvre pas la Carte")


func test_evolution_unknown_stage_is_a_silhouette_with_no_name() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"charmander"))
	var sheet := screen.get_sheet()
	sheet.select_tab(PokedexSheet.Tab.EVOLUTION)
	var images := sheet.get_evolution_images()
	assert_eq(images.size(), 2, "Salamèche puis le stade pas encore vu")
	assert_null(images[0].material, "stade connu : vignette en couleur")
	assert_eq(images[1].material, PokedexArt.silhouette_material(), "stade inconnu : silhouette")
	assert_eq((images[1].texture as AtlasTexture).region, PokedexArt.thumb_region(5))
	var texts := " | ".join(sheet.get_texts(PokedexSheet.Tab.EVOLUTION))
	assert_true(texts.contains("???"))
	assert_false(texts.contains("Reptincel"), "jamais le nom d'un stade inconnu")


func test_evolution_stage_without_number_is_an_empty_circle() -> void:
	var screen := await _screen_in(2340, _grid())
	var view := _sheet(&"charmander")
	view.evolution[1].number = 0
	screen.show_sheet(view)
	var sheet := screen.get_sheet()
	assert_eq(sheet.get_evolution_circles().size(), 2)
	assert_eq(sheet.get_evolution_images().size(), 1, "le rond vide n'a pas de vignette")


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


func test_back_leaves_directly_and_the_sheet_is_permanent() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"charmander"))
	assert_false(screen.close_sheet(), "rien à refermer")
	screen.get_back_button().pressed.emit()
	assert_eq(_backs, 1, "RETOUR quitte directement")
	assert_true(screen.is_sheet_open())


func test_three_panels_visible_without_overlap_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _screen_in(width, _grid())
		screen.show_sheet(_sheet(&"charmander"))
		await wait_frames(3)
		var panels: Array[Control] = [screen.get_list_panel(), screen.get_portrait(),
			screen.get_sheet_panel()]
		for panel: Control in panels:
			assert_true(panel.is_visible_in_tree(), "%s visible à %d" % [panel.name, width])
		for i: int in 2:
			assert_lte(panels[i].get_global_rect().end.x,
				panels[i + 1].get_global_rect().position.x + 0.5, "pas de chevauchement")
		assert_lte(panels[2].get_global_rect().end.x, width - UiTokens.SAFE_MARGIN + 0.5)
		var menu_close := screen.get_parent().get_parent().get_parent().find_child(
			"CloseButton", true, false) as Control
		var header := screen.get_header().get_global_rect()
		assert_gte(header.position.x, menu_close.get_global_rect().end.x - 0.5,
			"l'en-tête ne recouvre pas le ×")
		assert_gte(header.position.y, UiTokens.SAFE_MARGIN - 0.5)
		for child: Control in screen.get_header().get_children():
			assert_lte(child.get_global_rect().end.x, header.end.x + 0.5, "dans l'en-tête")
		for label: Label in [screen.get_title_label(), screen.get_counts_label()]:
			assert_lte(label.get_minimum_size().x, label.size.x + 0.5, "texte non tronqué")
		for button: Button in screen.get_filter_buttons() + [screen.get_back_button()]:
			assert_lte(button.get_minimum_size().x, button.size.x + 0.5,
				"« %s » entier à %d" % [button.text, width])
		for tab: int in 4:
			var tab_button := screen.get_sheet().get_tab_button(tab as PokedexSheet.Tab)
			assert_lte(tab_button.get_minimum_size().x, tab_button.size.x + 0.5,
				"onglet « %s » entier à %d" % [tab_button.text, width])


func test_zone_pill_hidden_on_the_dex_and_back_on_the_dashboard() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	menu.set_zone_name("Route 1")
	var dash := DashboardView.new()
	dash.zone_name = "Route 1"
	menu.show_dashboard(dash)
	assert_true(menu.get_zone_pill().visible)
	menu.show_pokedex(_grid())
	assert_false(menu.get_zone_pill().visible, "cachée sur le Pokédex")
	menu.show_dashboard(dash)
	assert_true(menu.get_zone_pill().visible, "revient sur le tableau de bord")


func test_empty_pokedex_shows_the_sentence_in_both_columns() -> void:
	_dex = Pokedex.new()
	var screen := await _screen_in(2340, _grid())
	assert_eq(screen.get_sheet_empty_label().text, "Aucune espèce enregistrée.")
	assert_true(screen.get_sheet_empty_label().is_visible_in_tree())
	assert_eq(screen.get_portrait().get_empty_label().text, "Aucune espèce enregistrée.")


func test_species_change_is_instant_at_speed_scale_zero() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"charmander"))
	screen.show_sheet(_sheet(&"pidgey"))
	assert_eq(screen.get_portrait().modulate.a, 1.0)


func _interactive(node: Node, found: Array[Control]) -> void:
	var control := node as Control
	if control != null and control.is_visible_in_tree() and (control is BaseButton
			or control is LineEdit or (control is PokedexSlot
			and control.mouse_filter != Control.MOUSE_FILTER_IGNORE)):
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


# --- Toucher ou défilement (retour S24 de la validation J6) -------------------------------------

func test_swipe_from_a_known_slot_scrolls_the_grid_and_opens_nothing() -> void:
	var screen := await _screen_in(2340, _grid())
	var scroll := screen.get_scroll()
	var slot := screen.get_slots()[3]
	var from := slot.get_global_rect().get_center()
	assert_true(scroll.get_global_rect().has_point(from))
	var finger := TouchFinger.new(screen.get_viewport())
	finger.swipe(from, Vector2(0.0, -250.0))
	await wait_process_frames(2)
	assert_gt(scroll.scroll_vertical, 0, "la grille a défilé")
	assert_true(_opened.is_empty(), "aucune fiche ouverte")


func test_swipe_from_a_habitat_chip_opens_nothing_and_a_tap_opens_once() -> void:
	var screen := await _screen_in(2340, _grid())
	screen.show_sheet(_sheet(&"pidgey"))
	var sheet := screen.get_sheet()
	sheet.select_tab(PokedexSheet.Tab.HABITAT)
	await wait_process_frames(3)
	var from := sheet.get_chips()[1].get_global_rect().get_center()
	var finger := TouchFinger.new(screen.get_viewport())
	finger.swipe(from, Vector2(80.0, 0.0))
	finger.swipe(from, Vector2(0.0, -150.0))
	await wait_process_frames(2)
	assert_true(_routes.is_empty(), "un glissement n'ouvre pas la Carte")
	finger.tap(sheet.get_chips()[1].get_global_rect().get_center())
	await wait_process_frames(2)
	assert_eq(_routes.size(), 1)
