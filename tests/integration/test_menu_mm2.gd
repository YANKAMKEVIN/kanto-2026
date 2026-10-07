extends GutTest
## Menu rapproché des maquettes, MM.2 (docs/tech/menu-maquettes.md) : Carte (étiquettes des
## seules zones connues, lieu courant mis en avant, aperçu illustré, artworks, icônes peintes,
## frise des zones découvertes sans total) et Dresseur (portrait peint, badges en silhouette
## « ??? » via BadgeLibrary, équipe en artworks, frise illustrée) ; « ‹ » à la place du × ;
## cibles ≥ TOUCH_MIN dans la marge à 1920 et 2340. Vraies vues (MapJournal, TrainerSummary).

const MENU_SCENE := "res://game/ui/menu/trainer_menu.tscn"
const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FIXTURE_V1 := "res://tests/fixtures/save/v1_after_capture.json"
const WIDTHS: Array[int] = [1920, 2340]
const HEIGHT := 1080

var _data: PokemonData
var _zones: ZoneLibrary
var _items: ItemLibrary
var _art: MapIllustration
var _moments: MomentLibrary
var _badges: BadgeLibrary
var _state: Node
var _menu: TrainerMenu
var _touched: Array[StringName] = []


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()
	_items = ItemLibrary.new()
	_items.load_dir()
	_art = MapIllustration.new()
	_art.load_file()
	_moments = MomentLibrary.new()
	_moments.load_file()
	_badges = BadgeLibrary.new()
	_badges.load_file()


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


func after_each() -> void:
	_state.free()


func _menu_in(width: int) -> TrainerMenu:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, HEIGHT)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var menu := (load(MENU_SCENE) as PackedScene).instantiate() as TrainerMenu
	menu.speed_scale = 0.0
	viewport.add_child(menu)
	_menu = menu
	return menu


func _map_in(width: int, zone: StringName = &"route_1") -> MapScreen:
	var menu := _menu_in(width)
	menu.show_map(MapJournal.view(_state, _zones, _art))
	menu.show_map_zone(MapJournal.panel(zone, _state, _data, _zones, _items, true))
	menu.open_animated()
	await wait_process_frames(3)
	var screen := menu.get_map()
	screen.zone_touched.connect(func(z: StringName) -> void: _touched.append(z))
	return screen


func _trainer_state() -> Node:
	var state: Node = GameStateScript.new()
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V1))
	SaveSystem.upgrade(content)
	state.load_dict(content, _data)
	return state


func _trainer_in(width: int, state: Node) -> TrainerScreen:
	var menu := _menu_in(width)
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	menu.show_trainer(TrainerSummary.build(state, _data, _zones, _moments, unlocks, _badges))
	menu.open_animated()
	await wait_process_frames(3)
	return menu.get_trainer()


func _inside_safe_area(control: Control, width: int) -> void:
	var rect := control.get_global_rect()
	assert_gte(rect.position.x, float(UiTokens.SAFE_MARGIN) - 0.5, "%s à %d" % [control, width])
	assert_lte(rect.end.x, float(width - UiTokens.SAFE_MARGIN) + 0.5, "%s à %d" % [control, width])
	assert_gte(rect.position.y, float(UiTokens.SAFE_MARGIN) - 0.5)
	assert_lte(rect.end.y, float(HEIGHT - UiTokens.SAFE_MARGIN) + 0.5)


# --- Carte ------------------------------------------------------------------------------------


func test_map_back_replaces_the_close_button() -> void:
	var screen := await _map_in(2340)
	assert_true(screen.owns_back)
	assert_false(_menu.get_close_button().is_visible_in_tree(), "× caché")
	var back := screen.get_back_button()
	assert_almost_eq(back.get_global_rect().position.x, float(UiTokens.SAFE_MARGIN), 0.5)
	assert_eq(screen.get_title_label().text, "Carte")


func test_only_known_zones_are_named_anywhere() -> void:
	var screen := await _map_in(2340)
	var known: Array[String] = ["Bourg Palette", "Route 1"]
	var texts := screen.get_texts()
	for id: StringName in _zones.get_ids():
		var zone_name := _zones.get_zone(id).name
		if known.has(zone_name):
			continue
		for text: String in texts:
			assert_false(text == zone_name, "zone non découverte nommée : %s" % zone_name)
	assert_eq(screen.get_strip().get_thumbs().keys(), [&"pallet_town", &"route_1"],
		"frise : seulement les zones découvertes")
	for text: String in texts:
		assert_false(text.contains("???"), text)
		assert_false(text.contains("Se rendre"), text)
		assert_null(RegEx.create_from_string("\\d\\s*/\\s*\\d").search(text), "total : %s" % text)


func test_current_place_is_highlighted_and_the_panel_zone_is_circled() -> void:
	var screen := await _map_in(2340)
	var canvas := screen.get_map_canvas()
	assert_eq(canvas.get_current(), &"pallet_town")
	assert_eq(canvas.get_label(&"pallet_town").theme_type_variation, &"MapLabelOn")
	assert_eq(canvas.get_label(&"route_1").theme_type_variation, &"MapLabelSelected")
	assert_eq(screen.get_strip().get_selected(), &"route_1")


func test_painted_portrait_on_the_player_zone() -> void:
	var screen := await _map_in(2340)
	var portrait := screen.get_map_canvas().get_portrait()
	assert_true(portrait.visible)
	var head := portrait.get_child(0) as ZoneArt
	assert_not_null(head)
	assert_true(head.has_image(), "tête du buste peint")
	assert_eq(head.texture, MenuArt.hero_bust())


func test_zone_count_has_no_total_and_singular_plural() -> void:
	var screen := await _map_in(2340)
	assert_eq(screen.get_strip().get_count_text(), "2 zones découvertes")
	var view := MapJournal.view(_state, _zones, _art)
	view.zones.resize(1)
	screen.get_strip().setup(view, null)
	assert_eq(screen.get_strip().get_count_text(), "1 zone découverte")


func test_strip_thumbnail_touch_emits_one_zone_and_has_its_preview() -> void:
	var screen := await _map_in(2340)
	var thumb: Button = screen.get_strip().get_thumbs()[&"pallet_town"]
	var art := thumb.find_children("*", "ZoneArt", true, false)[0] as ZoneArt
	assert_true(art.has_image())
	assert_eq(art.texture, MenuArt.zone_preview(&"pallet_town"), "aperçu peint de la zone")
	thumb.pressed.emit()
	assert_eq(_touched, [&"pallet_town"])


func test_panel_hero_uses_the_preview_or_a_crop_of_the_illustration() -> void:
	var screen := await _map_in(2340)
	var hero := screen.get_panel().get_hero_art()
	assert_eq(hero.texture, MenuArt.zone_preview(&"route_1"))
	# Une zone sans aperçu peint : recadrage de l'illustration de Kanto autour d'elle.
	var panel := ZonePanelView.new()
	panel.zone_id = &"mt_moon"
	panel.name = "Mont Sélénite"
	var kanto := MenuArt.texture(_art.get_image_path())
	screen.get_panel().show_zone(panel, kanto, Rect2(_art.area_of(&"mt_moon")))
	hero = screen.get_panel().get_hero_art()
	assert_null(MenuArt.zone_preview(&"mt_moon"))
	assert_eq(hero.texture, kanto)


func test_here_badge_only_on_the_current_place() -> void:
	var screen := await _map_in(2340, &"pallet_town")
	assert_true(screen.get_panel().get_texts().has(ZonePanel.HERE_TEXT))
	screen.show_zone(MapJournal.panel(&"route_1", _state, _data, _zones, _items, true))
	assert_false(screen.get_panel().get_texts().has(ZonePanel.HERE_TEXT))


func test_observed_pokemon_are_official_artworks_and_items_painted_icons() -> void:
	var screen := await _map_in(2340)
	var entries := screen.get_panel().get_pokemon_entries()
	assert_eq(entries.size(), 2)
	for cell: Button in entries:
		var arts: Array[Node] = cell.find_children("*", "TextureRect", true, false)
		assert_eq(arts.size(), 1)
		assert_true((arts[0] as TextureRect).texture is AtlasTexture, "vignette de l'atlas")
	var icons: Array[Texture2D] = []
	for node: Node in screen.get_panel().find_children("*", "TextureRect", true, false):
		icons.append((node as TextureRect).texture)
	assert_true(icons.has(MenuArt.item_icon(&"potion")), "icône peinte de la Potion")


func test_map_targets_and_margins_at_both_widths() -> void:
	for width: int in WIDTHS:
		var screen := await _map_in(width)
		var targets: Array[Control] = [screen.get_back_button()]
		targets.append_array(screen.get_panel().get_pokemon_entries())
		for thumb: Button in screen.get_strip().get_thumbs().values():
			targets.append(thumb)
		for control: Control in targets:
			assert_gte(control.size.y, float(UiTokens.TOUCH_MIN) - 0.5, "%s à %d" % [control,
				width])
			assert_gte(control.size.x, float(UiTokens.TOUCH_MIN) - 0.5)
			_inside_safe_area(control, width)
		for node: Control in [screen.get_map_canvas(), screen.get_panel(), screen.get_strip()]:
			_inside_safe_area(node, width)
		var echo := screen.get_echo().get_global_rect()
		assert_true(echo.encloses(screen.get_map_canvas().get_global_rect().grow(-0.5)),
			"l'écho couvre tout le cadre")


# --- Dresseur ---------------------------------------------------------------------------------


func test_trainer_shows_the_painted_hero_and_no_close_button() -> void:
	var state := _trainer_state()
	var screen := await _trainer_in(2340, state)
	assert_true(screen.owns_back)
	assert_false(_menu.get_close_button().is_visible_in_tree())
	assert_eq(screen.get_portrait().texture, MenuArt.hero_bust())
	assert_gt(screen.get_portrait().size.y, 400.0, "grand portrait")
	assert_true(screen.get_backdrop().has_image(), "décor de la zone du joueur")
	state.free()


func test_badges_come_from_the_badge_library_in_silhouette() -> void:
	var state := _trainer_state()
	var screen := await _trainer_in(2340, state)
	for slot: BadgeSlot in screen.get_badge_slots():
		assert_eq(slot.get_text(), "???")
	state.flags.set_flag(&"badge_boulder")
	var unlocks := MenuUnlocks.new(state.flags, state.party)
	_menu.show_trainer(TrainerSummary.build(state, _data, _zones, _moments, unlocks, _badges))
	var slots := screen.get_badge_slots()
	assert_eq(slots[0].get_text(), "Roche", "badge obtenu = drapeau levé")
	assert_eq(slots[0].get_view().name, "Badge Roche")
	assert_false(slots[0].is_muted())
	assert_eq(slots[0].get_emblem().modulate, UiTokens.ACCENT)
	for i: int in range(1, 8):
		assert_eq(slots[i].get_text(), "???")
	for text: String in screen.get_texts():
		assert_false(text.contains("/ 8") or text.contains("/8"), text)
	state.free()


func test_current_team_in_official_artworks() -> void:
	var state := _trainer_state()
	var screen := await _trainer_in(2340, state)
	var cards := screen.get_team_cards()
	assert_eq(cards.size(), state.party.size())
	assert_gt(cards.size(), 0)
	for i: int in cards.size():
		var number := _data.get_species(state.party.get_at(i).species_id).dex
		var wanted := MenuArt.pokemon_portrait(number) as AtlasTexture
		var shown := cards[i].get_art().texture as AtlasTexture
		assert_not_null(shown, "grand artwork officiel")
		assert_eq(shown.atlas, wanted.atlas)
		assert_eq(shown.region, wanted.region)
	assert_true(screen.get_team_panel().visible)
	state.free()


func test_no_team_section_without_a_team() -> void:
	var screen := await _trainer_in(2340, _state)
	assert_true(screen.get_team_cards().is_empty())
	assert_false(screen.get_team_panel().visible, "liste vide = section absente")


func test_moments_show_the_place_preview_and_the_pokemon_artwork() -> void:
	var state := _trainer_state()
	var screen := await _trainer_in(2340, state)
	var with_art := 0
	for row: MomentRow in screen.get_moment_rows():
		var arts: Array[Node] = row.find_children("*", "ZoneArt", true, false)
		assert_eq(arts.size(), 1)
		if row.get_view().dex_number > 0:
			with_art += 1
			var wanted := MenuArt.pokemon_thumbnail(row.get_view().dex_number) as AtlasTexture
			var found := false
			for node: Node in row.find_children("*", "TextureRect", true, false):
				var shown := (node as TextureRect).texture as AtlasTexture
				if shown != null and shown.region == wanted.region:
					found = true
			assert_true(found, "artwork du Pokémon du moment")
	assert_gt(with_art, 0)
	state.free()


func test_no_out_of_scope_element_on_the_trainer_screen() -> void:
	var state := _trainer_state()
	var screen := await _trainer_in(2340, state)
	for text: String in screen.get_texts():
		for banned: String in ["Titres", "Apparence", "XP", "Pikachu", "Histoire principale",
				"N. 16"]:
			assert_false(text.contains(banned), "%s : %s" % [banned, text])
	state.free()


func test_trainer_targets_and_margins_at_both_widths() -> void:
	for width: int in WIDTHS:
		var state := _trainer_state()
		state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
		var screen := await _trainer_in(width, state)
		var controls := screen.get_touch_controls()
		assert_gt(controls.size(), 2)
		for control: Control in controls:
			assert_gte(control.get_global_rect().size.y, float(UiTokens.TOUCH_MIN) - 0.5)
			_inside_safe_area(control, width)
		for card: TrainerTeamCard in screen.get_team_cards():
			_inside_safe_area(card, width)
		for slot: BadgeSlot in screen.get_badge_slots():
			_inside_safe_area(slot, width)
		state.free()
