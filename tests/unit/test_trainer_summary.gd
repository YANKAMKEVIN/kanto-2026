extends GutTest
## TrainerSummary : vue de l'écran Dresseur (jalon-06.md §3.7, §4, §6.11 ; dossier 08 §6 ;
## Q-13 badges muets, Q-14 grands moments).

const GameStateScript := preload("res://game/autoload/game_state.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FIXTURE_V1 := "res://tests/fixtures/save/v1_after_capture.json"

var _data: PokemonData
var _zones: ZoneLibrary
var _moments: MomentLibrary
var _state: Node
var _unlocks: MenuUnlocks


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()
	_moments = MomentLibrary.new()
	_moments.load_file()


func before_each() -> void:
	_state = GameStateScript.new()
	_state.clock = FixedClock.new("2026-10-02T19:05:17")
	_state.new_game(7)
	_unlocks = MenuUnlocks.new(_state.flags, _state.party)


func after_each() -> void:
	_state.free()


func _build() -> TrainerView:
	return TrainerSummary.build(_state, _data, _zones, _moments, _unlocks)


## La vraie partie de Kevin (sauvegarde v1 du S24, QA T16 du J5), migrée et chargée.
func _load_kevin() -> void:
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_V1))
	assert_eq(SaveSystem.upgrade(content), OK)
	assert_true(_state.load_dict(content, _data))


func _at(date: String) -> void:
	(_state.clock as FixedClock).iso = date


func _add(species: StringName, origin: Pokemon.Origin, to_storage: bool = false) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, 5, _state.rng)
	if origin != Pokemon.Origin.UNKNOWN:
		pokemon.record_meeting(origin, &"route_1", _state.now(), "Kevin")
	if to_storage:
		_state.storage.add(pokemon)
	else:
		_state.party.add(pokemon)
	return pokemon


func _titles(view: TrainerView) -> Array[String]:
	var titles: Array[String] = []
	for moment: MomentView in view.moments:
		titles.append(moment.title)
	return titles


func _stat_ids(view: TrainerView) -> Array[StringName]:
	var ids: Array[StringName] = []
	for line: TrainerStatView in view.stats:
		ids.append(line.stat_id)
	return ids


## Tous les textes de la vue (règle de déblocage).
func _all_texts(view: TrainerView) -> String:
	var texts := PackedStringArray([view.player_name, view.player_title, view.play_time_text,
		view.started_text, view.seen_text, view.caught_text, TrainerView.BADGES_TITLE,
		TrainerView.MOMENTS_TITLE, TrainerView.STATS_TITLE, TrainerView.STARTED_LABEL,
		TrainerView.MOMENTS_EMPTY_TEXT])
	for badge: BadgeSlotView in view.badges:
		texts.append_array([badge.name, badge.detail])
	for moment: MomentView in view.moments:
		texts.append_array([moment.title, moment.detail, moment.place, moment.date_text])
	for line: TrainerStatView in view.stats:
		texts.append_array([line.label, line.value_text])
	return " | ".join(texts)


# --- Début de partie -------------------------------------------------------------------------

func test_new_game_in_the_bedroom() -> void:
	_state.discover_map(&"player_house_2f")
	var view := _build()
	assert_eq(view.player_name, "Kevin")
	assert_eq(view.player_title, "Dresseur Pokémon")
	assert_eq(view.play_time_text, "0 h 00")
	assert_eq(view.started_text, "2 octobre 2026", "date de départ")
	assert_eq(view.seen_text, "")
	assert_eq(view.caught_text, "")
	assert_null(view.seen_route)
	assert_null(view.caught_route)
	assert_eq(view.moments.size(), 0, "l'arrivée dans la zone de départ n'est pas un moment")
	assert_eq(_stat_ids(view), [&"play_time", &"zones"] as Array[StringName],
		"pas de « 0 capture », pas de « 0 objet »")
	assert_eq(view.stat(&"zones").value_text, "1")


func test_q13_eight_silent_badge_slots_from_the_start() -> void:
	var view := _build()
	assert_eq(view.badges.size(), 8)
	for i: int in view.badges.size():
		var badge := view.badges[i]
		assert_eq(badge.index, i)
		assert_false(badge.obtained)
		assert_eq(badge.badge_id, &"", "ni apparence")
		assert_eq(badge.name, "", "ni nom")
		assert_eq(badge.detail, "", "ni ville ni champion")
	assert_eq(view.obtained_badges(), 0)
	var texts := _all_texts(view)
	assert_false(texts.contains("/"), "jamais « 0/8 »")
	assert_false(texts.contains("???"), "un badge inconnu est muet, pas « ??? »")


# --- La vraie partie de Kevin --------------------------------------------------------------

func test_kevin_real_save_tells_his_adventure_in_order() -> void:
	_load_kevin()
	var view := _build()
	assert_eq(_titles(view), ["Premier Pokémon", "Combat contre le rival",
		"Départ de Bourg Palette", "Première capture"] as Array[String])
	var starter := view.moments[0]
	assert_eq(starter.kind, MomentLibrary.STARTER)
	assert_eq(starter.detail, "Salamèche rejoint ton équipe.")
	assert_eq(starter.place, "Bourg Palette", "le labo : le nom de sa zone")
	assert_eq(starter.zone_id, &"pallet_town")
	assert_eq(starter.date_text, "2 octobre 2026")
	assert_eq(starter.species_id, &"charmander")
	var rival := view.moments[1]
	assert_eq(rival.kind, MomentLibrary.RIVAL_BATTLE)
	assert_eq(rival.detail, _moments.outcome_text(&"loss"), "l'issue enregistrée : défaite")
	assert_eq(rival.species_id, &"")
	assert_null(rival.route)
	var departure := view.moments[2]
	assert_eq(departure.kind, MomentLibrary.ZONE_ARRIVAL)
	assert_eq(departure.place, "Route 1")
	assert_eq(departure.date, "2026-10-02T19:10:04")
	var capture := view.moments[3]
	assert_eq(capture.detail, "Roucool rejoint l'aventure.")
	assert_eq(capture.place, "Bourg Palette")
	assert_eq(capture.species_id, &"pidgey")
	assert_null(capture.route, "§6.3 : seul le premier Pokémon a un lien")


func test_kevin_real_save_statistics() -> void:
	_load_kevin()
	var view := _build()
	assert_eq(view.play_time_text, "0 h 26")
	assert_eq(view.started_text, "2 octobre 2026")
	assert_eq(_stat_ids(view), [&"play_time", &"zones", &"captures", &"items_found"]
		as Array[StringName])
	assert_eq(view.stat(&"play_time").value_text, "0 h 26")
	assert_eq(view.stat(&"zones").value_text, "2", "Bourg Palette et la Route 1")
	assert_eq(view.stat(&"captures").value_text, "2", "Roucool et Rattata ; le starter non")
	assert_eq(view.stat(&"items_found").value_text, "1", "la Potion de la Route 1")
	assert_null(view.stat(&"battles_won"), "non enregistré")


func test_kevin_real_save_starter_links_to_his_team_sheet() -> void:
	_load_kevin()
	var route := _build().moments[0].route
	assert_not_null(route)
	assert_eq(route.screen, MenuRoute.TEAM)
	assert_eq(route.params["index"], 0)
	_state.party.swap(0, 2)
	route = _build().moments[0].route
	assert_eq(route.params["index"], 2, "il suit le Pokémon, pas la place")


func test_unlock_rule_nothing_from_the_pokedex_before_activation() -> void:
	_load_kevin()
	var view := _build()
	assert_eq(view.seen_text, "")
	assert_eq(view.caught_text, "")
	var texts := _all_texts(view).to_lower()
	for word: String in ["pokédex", "vus", "capturés", "habitat"]:
		assert_false(texts.contains(word), "« %s » avant l'activation" % word)


func test_seen_and_caught_once_the_pokedex_is_visible() -> void:
	_load_kevin()
	_unlocks.debug_pokedex = true
	var view := _build()
	assert_eq(view.seen_text, "4 vus")
	assert_eq(view.caught_text, "3 capturés")
	assert_eq(view.seen_route.screen, MenuRoute.POKEDEX)
	assert_eq(view.seen_route.params["filter"], MenuRoute.DEX_FILTER_SEEN)
	assert_eq(view.caught_route.params["filter"], MenuRoute.DEX_FILTER_CAUGHT)
	assert_false(_all_texts(view).contains("151"), "jamais de total")
	_state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	_unlocks.debug_pokedex = false
	assert_eq(_build().seen_text, "4 vus", "activé pour de vrai : pareil")


# --- Lien du premier Pokémon ---------------------------------------------------------------

func test_starter_link_falls_back_to_the_pokedex_then_to_nothing() -> void:
	_add(&"pidgey", Pokemon.Origin.CAPTURE)
	_add(&"bulbasaur", Pokemon.Origin.STARTER, true)
	_state.record_moment(&"starter", &"oak_lab",
		{"species": "bulbasaur"})
	assert_null(_build().moments[0].route, "ni dans l'équipe, ni Pokédex visible : pas de lien")
	_unlocks.debug_pokedex = true
	var route := _build().moments[0].route
	assert_eq(route.screen, MenuRoute.POKEDEX)
	assert_eq(route.params["filter"], MenuRoute.DEX_FILTER_ALL)
	assert_eq(route.params["species"], &"bulbasaur")


func test_starter_link_prefers_the_received_one_over_a_captured_twin() -> void:
	_add(&"bulbasaur", Pokemon.Origin.CAPTURE)
	_add(&"bulbasaur", Pokemon.Origin.STARTER)
	_state.record_moment(&"starter", &"oak_lab", {"species": "bulbasaur"})
	assert_eq(_build().moments[0].route.params["index"], 1)


func test_starter_link_accepts_a_pokemon_met_before_the_meeting_records() -> void:
	_add(&"squirtle", Pokemon.Origin.UNKNOWN)
	_state.record_moment(&"starter", &"oak_lab", {"species": "squirtle"})
	assert_eq(_build().moments[0].route.params["index"], 0, "partie d'avant le 5C.5")


# --- Arrivées dans les zones (Q-14) ----------------------------------------------------------

func test_first_arrival_per_zone_skips_interiors_and_the_start_zone() -> void:
	_at("2026-10-02T10:00:00")
	_state.discover_map(&"player_house_2f")
	_at("2026-10-02T10:05:00")
	_state.discover_map(&"pallet_town")
	_at("2026-10-02T10:20:00")
	_state.discover_map(&"route_1")
	_at("2026-10-03T08:00:00")
	_state.discover_map(&"oak_lab")
	var arrivals := TrainerSummary.first_arrivals(_state.discovered_maps, _zones)
	assert_eq(arrivals.keys(), [&"pallet_town", &"route_1"])
	assert_eq(arrivals[&"pallet_town"], "2026-10-02T10:00:00", "la plus ancienne de ses cartes")
	var view := _build()
	assert_eq(_titles(view), ["Départ de Bourg Palette"] as Array[String])
	assert_eq(view.moments[0].date_text, "2 octobre 2026")


func test_an_arrival_without_its_own_text_uses_the_zone_name() -> void:
	var zones := ZoneLibrary.new()
	zones.add_from_dict({"zones": {
		"pallet_town": {"name": "Bourg Palette", "kind": "town", "maps": ["pallet_town"]},
		"route_2": {"name": "Route 2", "kind": "route", "maps": ["route_2"]},
	}})
	_at("2026-10-02T10:00:00")
	_state.discover_map(&"pallet_town")
	_at("2026-10-04T10:00:00")
	_state.discover_map(&"route_2")
	_state.discover_map(&"secret_cave")
	var view := TrainerSummary.build(_state, _data, zones, _moments, _unlocks)
	assert_eq(view.moments.size(), 1, "une carte hors zone n'est jamais un moment")
	assert_eq(view.moments[0].title, "Route 2")
	assert_eq(view.moments[0].detail, _moments.get_text(&"zone_arrival").detail)
	assert_eq(view.moments[0].place, "Route 2")
	assert_eq(view.moments[0].zone_id, &"route_2")


func test_a_debug_start_on_route_1_has_no_departure() -> void:
	_state.discover_map(&"route_1")
	assert_eq(_build().moments.size(), 0, "la zone de départ n'a pas d'arrivée")


# --- Ordre et robustesse -----------------------------------------------------------------------

func test_moments_are_chronological_with_arrivals_first_on_a_tie() -> void:
	_at("2026-10-02T10:00:00")
	_state.discover_map(&"pallet_town")
	_at("2026-10-02T11:00:00")
	_state.record_moment(&"first_capture", &"route_1", {"species": "rattata"})
	_state.discover_map(&"route_1")
	_at("2026-10-02T09:00:00")
	_state.record_moment(&"starter", &"oak_lab", {"species": "charmander"})
	var view := _build()
	assert_eq(_titles(view), ["Premier Pokémon", "Départ de Bourg Palette",
		"Première capture"] as Array[String])


func test_unknown_or_broken_records_never_show_identifiers() -> void:
	_state.moments.append({"type": "first_badge", "date": "2026-10-02T10:00:00", "map": "x",
		"details": {}})
	_state.moments.append({"type": "starter", "date": "", "map": "nowhere",
		"details": {"species": "missingno"}})
	_state.moments.append({"type": "rival_battle", "date": "2026-10-02T11:00:00",
		"map": "oak_lab", "details": {"outcome": "fled"}})
	_state.moments.append({"type": "zone_arrival", "date": "2026-10-02T11:00:00",
		"map": "route_1", "details": {}})
	var view := _build()
	assert_eq(_titles(view), ["Combat contre le rival", "Premier Pokémon"] as Array[String],
		"type inconnu ignoré ; date vide à la fin ; arrivée seulement déduite des cartes")
	assert_eq(view.moments[0].detail, "", "issue sans texte : pas de ligne")
	var starter := view.moments[1]
	assert_eq(starter.detail, "", "espèce inconnue : pas de ligne, jamais « missingno »")
	assert_eq(starter.place, "", "carte hors zone : pas de lieu")
	assert_eq(starter.date_text, "")
	assert_eq(starter.species_id, &"")
	assert_null(starter.route)
	assert_false(_all_texts(view).contains("missingno"))
	assert_false(_all_texts(view).contains("nowhere"))


func test_captures_count_the_storage_but_not_the_starter() -> void:
	_add(&"charmander", Pokemon.Origin.STARTER)
	assert_null(_build().stat(&"captures"), "le starter n'est pas une capture")
	_add(&"pidgey", Pokemon.Origin.CAPTURE)
	_add(&"rattata", Pokemon.Origin.CAPTURE, true)
	assert_eq(_build().stat(&"captures").value_text, "2")
	assert_eq(TrainerSummary.capture_count(_state.party, _state.storage), 2)


func test_without_zones_or_moments() -> void:
	_state.discover_map(&"route_1")
	_state.record_moment(&"starter", &"oak_lab", {"species": "charmander"})
	var view := TrainerSummary.build(_state, _data, null, null, null)
	assert_eq(view.moments.size(), 0)
	assert_eq(view.badges.size(), 8)
	assert_eq(_stat_ids(view), [&"play_time"] as Array[StringName])
	assert_eq(view.seen_text, "")
	var no_zones := TrainerSummary.build(_state, _data, null, _moments, _unlocks)
	assert_eq(_titles(no_zones), ["Premier Pokémon"] as Array[String])
	assert_eq(no_zones.moments[0].place, "")
