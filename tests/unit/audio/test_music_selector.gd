extends GutTest
## MusicSelector (Son.0, T3) : carte, zone, exceptions, Surf / Vélo, Tour délivrée, combats,
## thème du « ! » (docs/tech/jalon-son.md §1.4, §2).

var _selector: MusicSelector
var _library: AudioLibrary


func before_all() -> void:
	_library = AudioLibrary.new()
	_library.load_dir()
	var zones := ZoneLibrary.new()
	zones.load_file()
	_selector = MusicSelector.new(_library, zones)


func test_a_map_takes_the_music_of_its_zone() -> void:
	assert_eq(_selector.track_for(&"pallet_town"), &"pallet_town")
	assert_eq(_selector.track_for(&"player_house_2f"), &"pallet_town", "maison : thème du bourg")
	assert_eq(_selector.track_for(&"route_1"), &"road_to_viridian")


func test_shared_rb_themes() -> void:
	# SON-4 : Jadielle, Argenta (et Safrania) partagent « Pewter City Theme ».
	assert_eq(_selector.track_for(&"viridian_city"), &"pewter_city")
	assert_eq(_selector.track_for(&"pewter_city"), &"pewter_city")
	assert_eq(_selector.track_for(&"fuchsia_city"), &"cerulean_city")
	assert_eq(_selector.track_for(&"route_22"), &"road_to_cerulean", "RB : thème des Routes 3+")


func test_map_exceptions_win_over_the_zone() -> void:
	assert_eq(_selector.track_for(&"oak_lab"), &"oaks_lab")
	assert_eq(_selector.track_for(&"viridian_center"), &"pokemon_center")
	assert_eq(_selector.track_for(&"celadon_dept_roof"), &"pokemon_center")
	assert_eq(_selector.track_for(&"pewter_gym"), &"pokemon_gym")
	assert_eq(_selector.track_for(&"celadon_game_corner"), &"game_corner")
	assert_eq(_selector.track_for(&"rocket_hideout_b2f"), &"rocket_hideout")
	assert_eq(_selector.track_for(&"route_5_daycare"), &"pewter_city", "poste : thème de ville")


func test_rb_oddities_follow_the_interior_rule() -> void:
	# SON-9 : les bizarreries RB sont ramenées à la règle « une ville = un son ».
	assert_eq(_selector.track_for(&"vermilion_fisher_house"), &"vermilion_city")
	assert_eq(_selector.track_for(&"route_12_rod_house"), &"road_to_lavender")
	assert_eq(_selector.track_for(&"route_16_fly_house"), &"road_to_cerulean")


func test_open_branch_maps_are_covered_in_advance() -> void:
	assert_eq(_selector.track_for(&"silph_co_7f"), &"silph_co", "J26")
	assert_eq(_selector.track_for(&"viridian_gym"), &"pokemon_gym", "J28")
	assert_eq(_selector.track_for(&"league_agatha"), &"pokemon_tower", "J30 (RB)")
	assert_eq(_selector.track_for(&"hall_of_fame"), &"hall_of_fame", "J30")


func test_unknown_map_is_silent() -> void:
	assert_eq(_selector.track_for(&"nowhere"), AudioLibrary.SILENCE)


func test_map_override_comes_first() -> void:
	var state := { MusicSelector.STATE_OVERRIDE: &"game_corner" }
	assert_eq(_selector.track_for(&"pallet_town", state), &"game_corner")
	state[MusicSelector.STATE_OVERRIDE] = &"unknown_track"
	assert_eq(_selector.track_for(&"pallet_town", state), &"pallet_town", "inconnue : ignorée")


func test_surf_and_bike_win_over_the_zone() -> void:
	var surf := { MusicSelector.STATE_MOVEMENT: AudioLibrary.MOVEMENT_SURF }
	assert_eq(_selector.track_for(&"route_19", surf), &"the_sea")
	assert_eq(_selector.track_for(&"route_19"), &"road_to_cerulean", "à pied sur la plage")
	var bike := { MusicSelector.STATE_MOVEMENT: AudioLibrary.MOVEMENT_BIKE }
	assert_eq(_selector.track_for(&"route_17", bike), &"pokemon_road", "SON-5 B, à confirmer")
	var walk := { MusicSelector.STATE_MOVEMENT: &"walk" }
	assert_eq(_selector.track_for(&"route_17", walk), &"road_to_cerulean")


func test_freed_tower_plays_lavender_town() -> void:
	# SON-10 B : une fois Fuji délivré, la Tour prend le thème de Lavanville.
	assert_eq(_selector.track_for(&"pokemon_tower_3f"), &"pokemon_tower")
	var freed := { MusicSelector.STATE_HAS_FLAG: func(flag: StringName) -> bool:
		return flag == &"fuji_rescued" }
	assert_eq(_selector.track_for(&"pokemon_tower_3f", freed), &"lavender_town")
	assert_eq(_selector.track_for(&"lavender_center", freed), &"pokemon_center", "hors de la Tour")


func test_purified_area_lowers_the_volume() -> void:
	assert_lt(_selector.volume_db_for({ MusicSelector.STATE_AREA: &"purified" }), 0.0)
	assert_eq(_selector.volume_db_for({}), 0.0)


func test_battle_music_by_category() -> void:
	assert_eq(_selector.battle_track(&""), &"battle_wild")
	assert_eq(_selector.victory_track(&""), &"victory_wild")
	assert_eq(_selector.battle_track(&"", &"mewtwo"), &"battle_wild", "SON-13 A")
	assert_eq(_selector.battle_category(&"", &"mewtwo"), AudioLibrary.BATTLE_LEGENDARY)
	assert_eq(_selector.battle_track(&"route_3_youngster_ben"), &"battle_trainer", "défaut")
	assert_eq(_selector.battle_track(&"rival_cerulean"), &"battle_trainer", "rival avant la Ligue")
	assert_eq(_selector.battle_track(&"pewter_gym_brock"), &"battle_gym_leader")
	assert_eq(_selector.victory_track(&"pewter_gym_brock"), &"victory_gym_leader")
	assert_eq(_selector.battle_track(&"giovanni_hideout"), &"battle_gym_leader")
	assert_eq(_selector.battle_track(&"rival_champion"), &"final_battle_rival")


func test_johto_battles_by_region_species_and_trainer() -> void:
	var johto := ZoneData.REGION_JOHTO
	assert_eq(_selector.battle_track(&"", &"pidgey", johto), &"johto_battle_wild")
	assert_eq(_selector.battle_track(&"", &"celebi", johto), &"johto_battle_wild", "JM-5")
	assert_eq(_selector.battle_track(&"route_40_swimmer_yanis", &"", johto),
		&"johto_battle_trainer")
	assert_eq(_selector.battle_track(&"mt_silver_1f_grunt_x", &"", johto),
		&"johto_battle_trainer", "JM-4 : Sbires en Trainer")
	assert_eq(_selector.battle_track(&"mahogany_hideout_b2f_scientifique", &"", johto),
		&"johto_battle_trainer", "JM-4 : Scientifiques en Trainer")
	for rocket: StringName in [&"slowpoke_well_admin_brace", &"mahogany_hideout_b3f_brace",
			&"goldenrod_radio_tower_admin_cenere", &"whirl_islands_cenere", &"den_cenere",
			&"bell_tower_dante_1", &"goldenrod_underground_boss", &"tide_hold_chief"]:
		assert_eq(_selector.battle_track(rocket, &"", johto), &"johto_battle_rocket", rocket)
	assert_eq(_selector.battle_track(&"mt_silver_dante_2", &"", johto),
		&"johto_battle_gym_leader")
	assert_eq(_selector.battle_track(&"mt_silver_rival_final", &"", johto),
		&"johto_battle_champion")
	for beast: StringName in [&"suicune", &"entei", &"raikou"]:
		assert_true(_library.is_legendary(beast), beast)
		assert_eq(_selector.battle_track(&"", beast, johto), &"johto_battle_suicune")
	assert_eq(_selector.battle_track(&"", &"lugia", johto), &"johto_battle_lugia")
	assert_eq(_selector.battle_track(&"", &"ho_oh", johto), &"johto_battle_ho_oh")
	assert_true(_library.is_legendary(&"ho_oh"))


func test_johto_keeps_the_lets_go_victories() -> void:
	var johto := ZoneData.REGION_JOHTO
	assert_eq(_selector.victory_track(&"", &"pidgey", johto), &"victory_wild", "JM-7")
	assert_eq(_selector.victory_track(&"", &"lugia", johto), &"victory_wild")
	assert_eq(_selector.victory_track(&"route_40_swimmer_yanis", &"", johto), &"victory_trainer")
	assert_eq(_selector.victory_track(&"bell_tower_dante_1", &"", johto), &"victory_trainer")
	assert_eq(_selector.victory_track(&"mt_silver_dante_2", &"", johto), &"victory_gym_leader")
	assert_eq(_selector.victory_track(&"mt_silver_rival_final", &"", johto),
		&"victory_gym_leader")


func test_kanto_battles_are_unchanged_by_the_johto_rules() -> void:
	var kanto := ZoneData.REGION_KANTO
	assert_eq(_selector.battle_track(&"", &"pidgey", kanto), &"battle_wild")
	assert_eq(_selector.battle_track(&"route_3_youngster_ben", &"", kanto), &"battle_trainer")
	assert_eq(_selector.battle_track(&"", &"mewtwo", kanto), &"battle_wild", "SON-13 A")
	assert_eq(_selector.battle_track(&"rival_champion", &"", kanto), &"final_battle_rival")


func test_johto_maps_play_hgss_and_centers_and_marts_have_their_track() -> void:
	assert_eq(_selector.track_for(&"olivine_city"), &"johto_olivine_lighthouse")
	assert_eq(_selector.track_for(&"olivine_house_1"), &"johto_olivine_lighthouse")
	assert_eq(_selector.track_for(&"route_36"), &"johto_route_29")
	assert_eq(_selector.track_for(&"lake_of_rage"), &"johto_route_38", "repli §8")
	assert_eq(_selector.track_for(&"mt_silver_summit"), &"johto_ice_path", "JM-10")
	assert_eq(_selector.track_for(&"alph_chamber"), &"johto_ruins_of_alph", "JM-8")
	assert_eq(_selector.track_for(&"goldenrod_radio_tower_elevator"), &"johto_radio_tower")
	assert_eq(_selector.track_for(&"dante_flashback_hq"), &"johto_rocket_hq")
	for shop: StringName in [&"azalea_center", &"azalea_mart", &"blackthorn_center",
			&"cianwood_center", &"ecruteak_center", &"ecruteak_mart", &"goldenrod_center",
			&"goldenrod_dept_store_1f", &"goldenrod_dept_store_roof", &"mahogany_center",
			&"mahogany_souvenir_shop", &"mt_silver_center", &"olivine_center",
			&"olivine_center_room", &"olivine_mart"]:
		assert_eq(_selector.track_for(shop), &"johto_pokemon_center", shop)


func test_no_johto_map_keeps_a_kanto_track() -> void:
	var zones := ZoneLibrary.new()
	zones.load_file()
	for zone_id: StringName in zones.zones_of_region(ZoneData.REGION_JOHTO):
		for map_id: StringName in zones.get_zone(zone_id).maps:
			assert_true(String(_selector.track_for(map_id)).begins_with("johto_"), map_id)


func test_surf_and_bike_follow_the_region() -> void:
	var surf := { MusicSelector.STATE_MOVEMENT: AudioLibrary.MOVEMENT_SURF }
	var bike := { MusicSelector.STATE_MOVEMENT: AudioLibrary.MOVEMENT_BIKE }
	assert_eq(_selector.track_for(&"route_40", surf), &"johto_surf")
	assert_eq(_selector.track_for(&"route_38", bike), &"johto_bicycle")
	assert_eq(_selector.track_for(&"route_19", surf), &"the_sea")
	assert_eq(_selector.track_for(&"route_16", bike), &"pokemon_road")


func test_johto_events_and_encounter_themes() -> void:
	assert_eq(_selector.event_track(&"awakening"), &"johto_dragons_den")
	assert_eq(_selector.event_track(&"heal"), &"pokemon_healed", "JM-7 : jingles de Let's Go")
	for rocket: StringName in [&"slowpoke_well_admin_brace", &"whirl_islands_cenere",
			&"bell_tower_dante_1", &"mt_silver_dante_2"]:
		assert_eq(_selector.encounter_track(rocket), &"trainer_appears_bad_guy", rocket)
	assert_eq(_selector.encounter_track(&"mt_silver_rival_final"), &"johto_rival", "JM-6")


func test_trainer_encounter_theme_by_trainer_then_name_prefix() -> void:
	assert_eq(_selector.encounter_track(&"x", "Gamin Ben"), &"trainer_appears_boy")
	assert_eq(_selector.encounter_track(&"x", "Fillette Lila"), &"trainer_appears_girl")
	assert_eq(_selector.encounter_track(&"x", "Jeune Dresseuse Apolline"),
		&"trainer_appears_girl", "le plus long préfixe gagne")
	assert_eq(_selector.encounter_track(&"x", "Jeune Dresseur Tom"), &"trainer_appears_boy")
	assert_eq(_selector.encounter_track(&"x", "Sbire Rocket"), &"trainer_appears_bad_guy")
	assert_eq(_selector.encounter_track(&"rival_lab", "{rival}"), &"blue_theme")
	assert_eq(_selector.encounter_track(&"x", "Inconnu"), &"trainer_appears_boy", "défaut")
	assert_eq(_selector.encounter_track(&"x", "Gamineries"), &"trainer_appears_boy",
		"un préfixe est un mot entier")


func test_event_tracks() -> void:
	assert_eq(_selector.event_track(&"title"), &"title_screen")
	assert_eq(_selector.event_track(&"nope"), AudioLibrary.SILENCE)
