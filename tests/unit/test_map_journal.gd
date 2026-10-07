extends GutTest
## MapJournal : zones découvertes, zone du joueur, vue de la Carte et panneau d'une zone
## (dossier 08 §5 ; jalon-06.md §3.6). Un journal, pas un guide : une zone non découverte n'a
## ni nom ni toucher ni panneau (Q-15) ; aucun total, aucun « ??? » ; Pokémon observés
## seulement si le Pokédex est visible.

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")

var _data: PokemonData
var _zones: ZoneLibrary
var _items: ItemLibrary
var _art: MapIllustration
var _state: Node
var _clock: FixedClock


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
	_clock = FixedClock.new("2026-09-30T10:00:00")
	_state.clock = _clock


func after_each() -> void:
	_state.free()


## Arrivée sur [param map] à la date [param iso], le joueur y reste.
func _arrive(map: StringName, iso: String) -> void:
	_clock.iso = iso
	_state.discover_map(map)
	_state.set_player_location(map, Vector2i.ZERO, Vector2i.DOWN)


## La partie de Kevin à la fin du J5 : chambre, labo, Bourg Palette, Route 1, Potion trouvée.
func _kevin() -> void:
	_arrive(&"player_house_2f", "2026-09-30T10:00:00")
	_arrive(&"player_house_1f", "2026-09-30T10:02:00")
	_arrive(&"pallet_town", "2026-09-30T10:03:00")
	_arrive(&"oak_lab", "2026-09-30T10:05:00")
	_state.record_caught(&"charmander", &"oak_lab")
	_state.record_seen(&"squirtle", &"oak_lab")
	_arrive(&"route_1", "2026-10-02T18:00:00")
	_state.record_seen(&"rattata", &"route_1")
	_state.record_seen(&"pidgey", &"route_1")
	_state.record_item_found(&"potion", &"route_1")


func _ids(entries: Array[ZoneEntryView]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry: ZoneEntryView in entries:
		ids.append(entry.id)
	return ids


## Tous les textes d'une vue de panneau (pour chercher un total ou un « ??? »).
func _panel_texts(panel: ZonePanelView) -> PackedStringArray:
	var texts := PackedStringArray([panel.name, panel.subtitle, panel.description])
	for list: Array[ZoneEntryView] in [panel.pokemon, panel.items, panel.services]:
		for entry: ZoneEntryView in list:
			texts.append(entry.name)
			texts.append(entry.count_text())
	return texts


# --- Zones découvertes -------------------------------------------------------------------

func test_discovered_zones_with_first_visit_date() -> void:
	_kevin()
	var found := MapJournal.discovered_zones(_state.discovered_maps, _zones)
	assert_eq(found.keys(), [&"pallet_town", &"route_1"], "ordre du voyage")
	assert_eq(found[&"pallet_town"], "2026-09-30T10:00:00", "la chambre date Bourg Palette")
	assert_eq(found[&"route_1"], "2026-10-02T18:00:00")


func test_earliest_map_dates_the_zone_whatever_the_order() -> void:
	var maps := {&"oak_lab": "2026-09-30T10:05:00", &"pallet_town": "2026-09-30T10:03:00",
		&"rival_house": "", &"nowhere": "2026-01-01T00:00:00"}
	var found := MapJournal.discovered_zones(maps, _zones)
	assert_eq(found.keys(), [&"pallet_town"], "une carte hors zone est ignorée")
	assert_eq(found[&"pallet_town"], "2026-09-30T10:03:00", "date vide ignorée")
	assert_eq(MapJournal.discovered_zones({&"rival_house": ""}, _zones)[&"pallet_town"], "")


func test_nothing_discovered_at_the_start() -> void:
	assert_true(MapJournal.discovered_zones({}, _zones).is_empty())
	assert_true(MapJournal.discovered_zones({&"route_1": "x"}, null).is_empty())


func test_player_zone_inside_is_the_town() -> void:
	for map: StringName in [&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab",
			&"pallet_town"]:
		assert_eq(MapJournal.player_zone(map, _zones), &"pallet_town", map)
	assert_eq(MapJournal.player_zone(&"route_1", _zones), &"route_1")
	assert_eq(MapJournal.player_zone(&"", _zones), &"")
	assert_eq(MapJournal.player_zone(&"route_1", null), &"")


# --- Vue de la Carte -----------------------------------------------------------------------

func test_view_lists_only_discovered_zones_with_their_area() -> void:
	_kevin()
	var view := MapJournal.view(_state, _zones, _art)
	assert_eq(view.title, "CARTE — KANTO")
	assert_eq(view.image_path, "res://assets/ui/map/kanto_placeholder.webp")
	assert_eq(view.image_size, Vector2i(1586, 992))
	assert_eq(view.zones.size(), 2, "ni Jadielle ni aucune zone non découverte")
	assert_eq(view.zones[0].zone_id, &"pallet_town")
	assert_eq(view.zones[0].name, "Bourg Palette")
	assert_eq(view.zones[0].kind, ZoneData.KIND_TOWN)
	assert_eq(view.zones[0].area, Rect2(715, 595, 200, 110))
	assert_true(view.zones[0].is_touchable())
	assert_false(view.zones[0].current)
	assert_eq(view.zones[1].zone_id, &"route_1")
	assert_true(view.zones[1].current)
	assert_null(view.zone(&"viridian_city"), "non découverte : pas de vue")
	assert_null(view.zone(&""))


func test_player_portrait_inside_a_house() -> void:
	_kevin()
	_state.set_player_location(&"player_house_1f", Vector2i.ZERO, Vector2i.DOWN)
	var view := MapJournal.view(_state, _zones, _art)
	assert_eq(view.player_zone, &"pallet_town", "un intérieur : sa ville")
	assert_eq(view.player_area(), Rect2(715, 595, 200, 110))
	assert_eq(view.selected, &"pallet_town", "sans zone demandée : celle du joueur")
	assert_true(view.zone(&"pallet_town").current)
	assert_false(view.zone(&"route_1").current)


func test_route_zone_selected_only_if_discovered() -> void:
	_kevin()
	assert_eq(MapJournal.view(_state, _zones, _art, &"pallet_town").selected, &"pallet_town",
		"lien Habitat du Pokédex")
	assert_eq(MapJournal.view(_state, _zones, _art, &"viridian_city").selected, &"route_1",
		"zone non découverte demandée : celle du joueur")
	assert_eq(MapJournal.view(_state, _zones, _art, &"nowhere").selected, &"route_1")


func test_player_zone_counts_as_discovered() -> void:
	_state.set_player_location(&"route_1", Vector2i.ZERO, Vector2i.DOWN)
	var view := MapJournal.view(_state, _zones, _art)
	assert_eq(view.zones.size(), 1)
	assert_eq(view.player_zone, &"route_1")
	assert_true(MapJournal.is_discovered(&"route_1", _state, _zones))
	assert_false(MapJournal.is_discovered(&"pallet_town", _state, _zones))


func test_new_game_before_any_map() -> void:
	var view := MapJournal.view(_state, _zones, _art)
	assert_true(view.zones.is_empty())
	assert_eq(view.player_zone, &"")
	assert_eq(view.selected, &"")
	assert_eq(view.player_area(), Rect2())


func test_zone_without_area_is_not_touchable() -> void:
	_kevin()
	var art := MapIllustration.new()
	assert_true(art.add_from_dict({"image": "res://x.webp", "image_size": [100, 100],
		"zones": {"route_1": {"area": [1, 2, 3, 4]}}}, "t"))
	var view := MapJournal.view(_state, _zones, art)
	assert_false(view.zone(&"pallet_town").is_touchable(), "pas de rectangle")
	assert_eq(view.zone(&"pallet_town").name, "Bourg Palette", "mais découverte")
	assert_eq(view.zone(&"route_1").area, Rect2(1, 2, 3, 4))
	assert_eq(MapJournal.view(_state, _zones, null).zones.size(), 2, "sans illustration")


# --- Panneau d'une zone --------------------------------------------------------------------

func test_undiscovered_zone_has_no_panel() -> void:
	_kevin()
	assert_null(MapJournal.panel(&"viridian_city", _state, _data, _zones, _items, true))
	assert_null(MapJournal.panel(&"nowhere", _state, _data, _zones, _items, true))
	assert_null(MapJournal.panel(&"route_1", null, _data, _zones, _items, true))


func test_route_1_panel_with_pokedex_visible() -> void:
	_kevin()
	var panel := MapJournal.panel(&"route_1", _state, _data, _zones, _items, true)
	assert_eq(panel.zone_id, &"route_1")
	assert_eq(panel.name, "Route 1")
	assert_eq(panel.subtitle, "Bourg Palette — Jadielle")
	assert_false(panel.description.is_empty())
	assert_true(panel.current)
	assert_eq(_ids(panel.pokemon), [&"pidgey", &"rattata"] as Array[StringName],
		"par numéro du Pokédex")
	assert_eq(panel.pokemon[0].name, "Roucool")
	assert_eq(_ids(panel.items), [&"potion"] as Array[StringName])
	assert_eq(panel.items[0].name, "Potion")
	assert_eq(panel.items[0].count_text(), "")
	assert_true(panel.services.is_empty(), "aucun service au J6")


func test_pokemon_hidden_until_the_pokedex_is_visible() -> void:
	_kevin()
	var panel := MapJournal.panel(&"route_1", _state, _data, _zones, _items, false)
	assert_true(panel.pokemon.is_empty(), "règle de déblocage")
	assert_eq(_ids(panel.items), [&"potion"] as Array[StringName], "les objets restent")
	assert_eq(_state.pokedex.seen_count(), 4, "les données, elles, sont là")


func test_interior_observations_belong_to_the_town() -> void:
	_kevin()
	var panel := MapJournal.panel(&"pallet_town", _state, _data, _zones, _items, true)
	assert_eq(_ids(panel.pokemon), [&"charmander", &"squirtle"] as Array[StringName],
		"vus au labo = Bourg Palette")
	assert_true(panel.items.is_empty(), "la Potion est sur la Route 1")
	assert_eq(panel.subtitle, "", "pas de sous-titre : absent")
	assert_false(panel.current)


func test_found_items_of_the_zone_only_one_line_per_item() -> void:
	_kevin()
	_state.record_item_found(&"poke_ball", &"route_1")
	_state.record_item_found(&"potion", &"route_1")
	_state.record_item_found(&"potion", &"pallet_town")
	_state.record_item_found(&"mystery_item", &"route_1")
	_state.record_item_found(&"potion", &"nowhere")
	var panel := MapJournal.panel(&"route_1", _state, _data, _zones, _items, true)
	assert_eq(_ids(panel.items), [&"potion", &"poke_ball"] as Array[StringName],
		"ordre de la première trouvaille ; objet inconnu jamais affiché")
	assert_eq(panel.items[0].count, 2)
	assert_eq(panel.items[0].count_text(), "×2")
	assert_eq(panel.items[1].count_text(), "")
	var town := MapJournal.panel(&"pallet_town", _state, _data, _zones, _items, true)
	assert_eq(_ids(town.items), [&"potion"] as Array[StringName])
	assert_true(MapJournal.panel(&"route_1", _state, _data, _zones, null, true).items.is_empty())


func test_items_received_from_someone_are_not_listed() -> void:
	_kevin()
	_state.bag.add(&"poke_ball", 5)
	var panel := MapJournal.panel(&"pallet_town", _state, _data, _zones, _items, true)
	assert_true(panel.items.is_empty(), "les Poké Balls de Chen ne sont pas « trouvées »")


func test_no_total_and_no_question_marks() -> void:
	_kevin()
	for zone: StringName in [&"pallet_town", &"route_1"]:
		for visible: bool in [true, false]:
			var panel := MapJournal.panel(zone, _state, _data, _zones, _items, visible)
			for text: String in _panel_texts(panel):
				assert_false(text.contains("???"), "%s : « %s »" % [zone, text])
				assert_false(text.contains("/"), "%s : pas de total « %s »" % [zone, text])
	for zone: MapZoneView in MapJournal.view(_state, _zones, _art).zones:
		assert_false(zone.name.contains("???"))


func test_services_listed_once_discovered() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.add_from_dict({
		"services": {"pokemon_center": {"name": "Centre Pokémon"},
			"poke_mart": {"name": "Boutique"}},
		"zones": {"viridian_city": {"name": "Jadielle", "kind": "town",
			"maps": ["viridian_city", "viridian_center", "viridian_mart"],
			"services": [{"id": "pokemon_center", "found_on": "viridian_center"},
				{"id": "poke_mart", "found_on": "viridian_mart"}]}},
	}, "t"))
	_arrive(&"viridian_city", "2026-10-04T09:00:00")
	var panel := MapJournal.panel(&"viridian_city", _state, _data, zones, _items, true)
	assert_true(panel.services.is_empty(), "ni Centre ni Boutique avant d'y être entré")
	_arrive(&"viridian_mart", "2026-10-04T09:05:00")
	panel = MapJournal.panel(&"viridian_city", _state, _data, zones, _items, true)
	assert_eq(_ids(panel.services), [&"poke_mart"] as Array[StringName])
	assert_eq(panel.services[0].name, "Boutique")
	_arrive(&"viridian_center", "2026-10-04T09:10:00")
	panel = MapJournal.panel(&"viridian_city", _state, _data, zones, _items, true)
	assert_eq(_ids(panel.services), [&"pokemon_center", &"poke_mart"] as Array[StringName],
		"ordre des données")


func test_observed_pokemon_ignores_unknown_species() -> void:
	_state.pokedex.mark_seen(&"missingno", &"route_1", "")
	_state.pokedex.mark_seen(&"rattata", &"route_1", "")
	var found := MapJournal.observed_pokemon(&"route_1", _state.pokedex, _data, _zones)
	assert_eq(_ids(found), [&"rattata"] as Array[StringName])
	assert_true(MapJournal.observed_pokemon(&"route_1", null, _data, _zones).is_empty())


# --- MM.2 : numéro du Pokédex des Pokémon observés ------------------------------------------


func test_observed_pokemon_carry_their_dex_number_for_the_artwork() -> void:
	_kevin()
	var panel := MapJournal.panel(&"route_1", _state, _data, _zones, _items, true)
	assert_eq(_ids(panel.pokemon), [&"pidgey", &"rattata"])
	assert_eq(panel.pokemon[0].dex_number, 16)
	assert_eq(panel.pokemon[1].dex_number, 19)
	for entry: ZoneEntryView in panel.items:
		assert_eq(entry.dex_number, 0, "un objet n'a pas de numéro")
