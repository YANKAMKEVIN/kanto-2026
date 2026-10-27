extends GutTest
## MusicStack (Son.0, T3) : couches zone < scène < combat < jingle, reprise à la position,
## changement de carte pendant un combat, évolution annulée (docs/tech/jalon-son.md §1.5).

const L := MusicStack.Layer

var _stack: MusicStack


func before_each() -> void:
	_stack = MusicStack.new()


func test_empty_stack_is_silent() -> void:
	assert_eq(_stack.top_layer(), -1)
	assert_eq(_stack.current_track(), AudioLibrary.SILENCE)


func test_a_new_zone_track_plays_from_the_start() -> void:
	var change := _stack.set_layer(L.ZONE, &"pallet_town")
	assert_true(change.changed)
	assert_eq(change.track, &"pallet_town")
	assert_eq(change.position, 0.0)
	assert_false(change.resumed)
	assert_eq(change.layer, L.ZONE)


func test_the_same_track_keeps_playing() -> void:
	_stack.set_layer(L.ZONE, &"pallet_town")
	var change := _stack.set_layer(L.ZONE, &"pallet_town", 12.0)
	assert_false(change.changed, "entrer dans une maison ne relance pas le thème")
	assert_eq(change.track, &"pallet_town")


func test_another_zone_track_replaces_the_first() -> void:
	_stack.set_layer(L.ZONE, &"pallet_town")
	var change := _stack.set_layer(L.ZONE, &"road_to_viridian", 30.0)
	assert_true(change.changed)
	assert_eq(change.track, &"road_to_viridian")
	assert_eq(change.position, 0.0)


func test_a_jingle_resumes_the_zone_where_it_was() -> void:
	_stack.set_layer(L.ZONE, &"pewter_city")
	var start := _stack.set_layer(L.JINGLE, &"pokemon_healed", 42.5)
	assert_eq(start.track, &"pokemon_healed")
	assert_eq(start.previous_layer, L.ZONE)
	assert_almost_eq(_stack.position_of(L.ZONE), 42.5, 0.001)
	var end := _stack.clear_layer(L.JINGLE, 3.0)
	assert_true(end.changed)
	assert_true(end.resumed)
	assert_eq(end.track, &"pewter_city")
	assert_almost_eq(end.position, 42.5, 0.001, "comportement RB du Centre")


func test_battle_then_victory_then_zone_resumes() -> void:
	_stack.set_layer(L.ZONE, &"road_to_viridian")
	_stack.set_layer(L.BATTLE, &"battle_wild", 20.0)
	var victory := _stack.set_layer(L.BATTLE, &"victory_wild", 55.0)
	assert_true(victory.changed)
	assert_eq(victory.track, &"victory_wild")
	assert_almost_eq(_stack.position_of(L.ZONE), 20.0, 0.001, "la position de la zone reste")
	var back := _stack.clear_layer(L.BATTLE)
	assert_true(back.resumed)
	assert_eq(back.track, &"road_to_viridian")
	assert_almost_eq(back.position, 20.0, 0.001, "SON-6 : là où elle s'était arrêtée")


func test_map_change_during_battle_starts_the_new_track_from_the_beginning() -> void:
	_stack.set_layer(L.ZONE, &"road_to_viridian")
	_stack.set_layer(L.BATTLE, &"battle_trainer", 20.0)
	var covered := _stack.set_layer(L.ZONE, &"pokemon_center", 33.0)
	assert_false(covered.changed, "le combat continue")
	assert_eq(covered.track, &"battle_trainer")
	var back := _stack.clear_layer(L.BATTLE)
	assert_eq(back.track, &"pokemon_center")
	assert_eq(back.position, 0.0, "défaite → Centre : le morceau part du début")


func test_level_up_jingle_over_the_battle() -> void:
	_stack.set_layer(L.ZONE, &"route")
	_stack.set_layer(L.BATTLE, &"battle_wild", 5.0)
	_stack.set_layer(L.JINGLE, &"level_up", 18.0)
	var back := _stack.clear_layer(L.JINGLE)
	assert_eq(back.track, &"battle_wild")
	assert_almost_eq(back.position, 18.0, 0.001)
	assert_almost_eq(_stack.position_of(L.ZONE), 5.0, 0.001, "la zone garde la sienne")


func test_evolution_then_congratulations_then_back() -> void:
	_stack.set_layer(L.ZONE, &"route")
	_stack.set_layer(L.JINGLE, &"evolution", 10.0)
	var evolved := _stack.set_layer(L.JINGLE, &"evolved", 7.0)
	assert_true(evolved.changed)
	assert_eq(evolved.track, &"evolved")
	var back := _stack.clear_layer(L.JINGLE)
	assert_eq(back.track, &"route")
	assert_almost_eq(back.position, 10.0, 0.001)


func test_cancelled_evolution_goes_straight_back() -> void:
	_stack.set_layer(L.ZONE, &"route")
	_stack.set_layer(L.JINGLE, &"evolution", 4.0)
	var back := _stack.clear_layer(L.JINGLE, 2.0)
	assert_true(back.resumed)
	assert_eq(back.track, &"route")
	assert_almost_eq(back.position, 4.0, 0.001)


func test_scene_music_over_the_zone() -> void:
	_stack.set_layer(L.ZONE, &"pallet_town")
	var scene := _stack.set_layer(L.SCENE, &"blue_theme", 9.0)
	assert_eq(scene.track, &"blue_theme")
	var under := _stack.set_layer(L.BATTLE, &"battle_trainer", 14.0)
	assert_eq(under.previous_layer, L.SCENE)
	_stack.clear_layer(L.BATTLE)
	var back := _stack.clear_layer(L.SCENE)
	assert_eq(back.track, &"pallet_town")
	assert_almost_eq(back.position, 9.0, 0.001)


func test_same_track_above_and_below_keeps_playing() -> void:
	_stack.set_layer(L.ZONE, &"blue_theme")
	var scene := _stack.set_layer(L.SCENE, &"blue_theme", 3.0)
	assert_false(scene.changed)
	var back := _stack.clear_layer(L.SCENE, 8.0)
	assert_false(back.changed, "même morceau : il continue sans reprise")


func test_clearing_a_covered_layer_changes_nothing() -> void:
	_stack.set_layer(L.ZONE, &"route")
	_stack.set_layer(L.SCENE, &"blue_theme")
	_stack.set_layer(L.BATTLE, &"battle_trainer")
	var change := _stack.clear_layer(L.SCENE)
	assert_false(change.changed)
	assert_eq(_stack.current_track(), &"battle_trainer")
	assert_false(_stack.clear_layer(L.JINGLE).changed, "couche déjà vide")


func test_silence_is_a_track_and_clearing_everything_stops() -> void:
	_stack.set_layer(L.ZONE, &"route")
	var silent := _stack.set_layer(L.ZONE, AudioLibrary.SILENCE)
	assert_true(silent.changed)
	assert_eq(silent.track, AudioLibrary.SILENCE)
	var stop := _stack.clear_layer(L.ZONE)
	assert_true(stop.changed)
	assert_eq(stop.track, AudioLibrary.SILENCE)
	assert_eq(stop.layer, -1)


func test_reset_empties_every_layer() -> void:
	_stack.set_layer(L.ZONE, &"route")
	_stack.set_layer(L.BATTLE, &"battle_wild", 3.0)
	_stack.reset()
	assert_eq(_stack.top_layer(), -1)
	assert_eq(_stack.position_of(L.ZONE), 0.0)
