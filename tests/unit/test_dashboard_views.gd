extends GutTest
## DashboardViews : vue du tableau de bord (jalon-06.md §3.2, §4 ; dossier 08 §1).

const GameStateScript := preload("res://game/autoload/game_state.gd")

var _data: PokemonData
var _zones: ZoneLibrary
var _objectives: ObjectiveLibrary
var _state: Node
var _unlocks: MenuUnlocks


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_zones = ZoneLibrary.new()
	_zones.load_file()
	_objectives = ObjectiveLibrary.new()
	_objectives.load_file()


func before_each() -> void:
	_state = GameStateScript.new()
	_state.new_game(7)
	_unlocks = MenuUnlocks.new(_state.flags, _state.party)


func after_each() -> void:
	_state.free()


func _build() -> DashboardView:
	return DashboardViews.build(_state, _data, _zones, _objectives, _unlocks)


func _add(species: StringName, level: int) -> Pokemon:
	var pokemon := PokemonFactory.create(_data, species, level, _state.rng)
	_state.party.add(pokemon)
	return pokemon


func test_new_game_in_the_bedroom() -> void:
	_state.set_player_location(&"player_house_2f", Vector2i(3, 3), Vector2i.DOWN)
	var view := _build()
	assert_eq(view.zone_name, "Bourg Palette", "un intérieur : le nom de sa ville")
	assert_eq(view.player_name, "Kevin")
	assert_eq(view.player_title, "Dresseur Pokémon")
	assert_eq(view.play_time_text, "0 h 00")
	assert_eq(view.dex_text, "")
	assert_eq(view.badges_text, "", "Q-13 : pas de ligne avant le premier badge")
	assert_null(view.lead, "Q-2 : pas de Pokémon de tête avant le starter")
	assert_eq(view.card_screens(), [&"bag", &"map", &"trainer", &"settings"]
		as Array[StringName])
	assert_eq(view.objective_text, "", "Q-4 : aucune ligne avant le combat contre le rival")


func test_after_the_rival_battle_on_route_1() -> void:
	var lead := _add(&"charmander", 6)
	lead.hp = 13
	_add(&"pidgey", 3)
	_state.pokedex.mark_seen(&"rattata")
	_state.flags.set_flag(&"rival_battle_done")
	_state.set_player_location(&"route_1", Vector2i(24, 2), Vector2i.UP)
	_state.play_time = 45780.0
	var view := _build()
	assert_eq(view.zone_name, "Route 1")
	assert_eq(view.play_time_text, "12 h 43")
	assert_eq(view.card_screens(), [&"team", &"bag", &"map", &"trainer", &"settings"]
		as Array[StringName], "cinq cartes : POKÉDEX absente, pas grisée")
	assert_eq(view.dex_text, "", "pas de « vus · capturés » avant l'activation")
	assert_eq(view.objective_text, "Objectif : rejoindre Jadielle.")
	assert_not_null(view.lead)
	assert_eq(view.lead.display_name, "Salamèche")
	assert_eq(view.lead.species_id, &"charmander")
	assert_eq(view.lead.party_index, 0)
	assert_eq(view.lead.level, 6)
	assert_eq(view.lead.hp, 13)
	assert_eq(view.lead.max_hp, lead.max_hp())
	assert_eq(view.lead.status_text, "")
	assert_true(view.lead.is_valid())


func test_cards_carry_titles_and_captions() -> void:
	_add(&"bulbasaur", 5)
	_state.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	var view := _build()
	assert_eq(view.cards.size(), 6)
	var titles: Array[String] = []
	for card: MenuCardView in view.cards:
		titles.append(card.title)
		assert_false(card.caption.is_empty(), card.screen)
	assert_eq(titles, ["Équipe", "Pokédex", "Sac", "Carte", "Dresseur", "Paramètres"]
		as Array[String])
	assert_false(view.cards[5].caption.to_lower().contains("audio"), "Q-17 : pas d'AUDIO")


func test_pokedex_line_only_when_visible() -> void:
	_add(&"squirtle", 5)
	_state.pokedex.mark_caught(&"squirtle")
	_state.pokedex.mark_seen(&"pidgey")
	_state.pokedex.mark_seen(&"rattata")
	assert_eq(_build().dex_text, "")
	_unlocks.debug_pokedex = true
	assert_eq(_build().dex_text, "3 vus · 1 capturé")
	assert_false(_state.flags.has_flag(StoryFlags.POKEDEX_ACTIVATED))
	assert_eq(_build().card_screens().size(), 6)


func test_fainted_lead_says_so_in_text() -> void:
	var lead := _add(&"charmander", 5)
	lead.hp = 0
	lead.favorite = true
	var view := _build()
	assert_eq(view.lead.hp, 0)
	assert_eq(view.lead.status_text, "K.O.")
	assert_true(view.lead.favorite)


func test_nickname_and_gender() -> void:
	var lead := _add(&"pidgey", 3)
	lead.nickname = "Plume"
	lead.gender = Pokemon.Gender.FEMALE
	var view := _build()
	assert_eq(view.lead.display_name, "Plume")
	assert_eq(view.lead.gender, BattleCardView.Gender.FEMALE)


func test_unknown_map_and_missing_libraries() -> void:
	_state.set_player_location(&"nowhere", Vector2i.ZERO, Vector2i.DOWN)
	_state.flags.set_flag(&"rival_battle_done")
	assert_eq(_build().zone_name, "")
	var bare := DashboardViews.build(_state, _data, null, null, _unlocks)
	assert_eq(bare.zone_name, "")
	assert_eq(bare.objective_text, "")


func test_play_time_text() -> void:
	assert_eq(DashboardViews.play_time_text(0.0), "0 h 00")
	assert_eq(DashboardViews.play_time_text(59.9), "0 h 00")
	assert_eq(DashboardViews.play_time_text(420.0), "0 h 07")
	assert_eq(DashboardViews.play_time_text(3599.0), "0 h 59")
	assert_eq(DashboardViews.play_time_text(3600.0), "1 h 00")
	assert_eq(DashboardViews.play_time_text(45780.0), "12 h 43")
	assert_eq(DashboardViews.play_time_text(360000.0), "100 h 00")
	assert_eq(DashboardViews.play_time_text(-5.0), "0 h 00")


func test_dex_text_never_shows_a_total() -> void:
	assert_eq(DashboardViews.dex_text(27, 14), "27 vus · 14 capturés")
	assert_eq(DashboardViews.dex_text(1, 0), "1 vu · 0 capturé")
	assert_false(DashboardViews.dex_text(151, 151).contains("/"))


func test_seen_and_caught_texts_apart() -> void:
	assert_eq(DashboardViews.seen_text(0), "0 vu")
	assert_eq(DashboardViews.seen_text(1), "1 vu")
	assert_eq(DashboardViews.seen_text(27), "27 vus")
	assert_eq(DashboardViews.caught_text(1), "1 capturé")
	assert_eq(DashboardViews.caught_text(14), "14 capturés")
	assert_eq(DashboardViews.caught_text(1250),
		"1%s250 capturés" % MenuFormat.THOUSANDS_SEPARATOR, "milliers séparés (insécable)")


# --- MM.1 : badges préparés, artwork du Pokémon de tête -----------------------------------------


func test_badges_line_follows_the_obtained_badges() -> void:
	var badges := BadgeLibrary.new()
	assert_true(badges.load_file())
	var build := func() -> DashboardView:
		return DashboardViews.build(_state, _data, _zones, _objectives, _unlocks, badges)
	assert_eq(build.call().badges_text, "", "aucun badge : pas de ligne (jamais « 0 badge »)")
	_state.flags.set_flag(badges.flag(&"boulder"))
	assert_eq(build.call().badges_text, "1 badge")
	_state.flags.set_flag(badges.flag(&"cascade"))
	assert_eq(build.call().badges_text, "2 badges")
	assert_eq(_build().badges_text, "", "sans bibliothèque : pas de ligne")


func test_badges_text_rule() -> void:
	assert_eq(DashboardViews.badges_text(0), "")
	assert_eq(DashboardViews.badges_text(-1), "")
	assert_eq(DashboardViews.badges_text(1), "1 badge")
	assert_eq(DashboardViews.badges_text(8), "8 badges")


func test_member_carries_the_dex_number_for_the_artwork() -> void:
	_add(&"charmander", 5)
	_add(&"pidgey", 3)
	assert_eq(DashboardViews.member(_state.party.get_at(0), 0, _data).dex_number, 4)
	assert_eq(DashboardViews.member(_state.party.get_at(1), 1, _data).dex_number, 16)
