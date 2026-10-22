extends GutTest
## Portes électroniques de la Sylphe SARL (jalon 26, T7 ; `docs/tech/jalon-26.md` §2.2, §2.5 ;
## `docs/tech/systemes-2.md` §2.10), sur les vraies scènes :
## - chaque porte couvre deux cases et n'a qu'un drapeau `door_silph_co_<n>f_<id>_open` ; fermée,
##   ses deux cases sont occupées et portent un point OUVRIR ; le drapeau les libère toutes deux ;
## - vraie Boot (2F, porte d2) : sans la Carte → « Il faut une carte. », rien ne change ; avec →
##   ouverte, un seul drapeau, sauvegarde écrite ; après rechargement (application relancée),
##   toujours ouverte, OUVRIR disparu, on passe.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/silph_1f.json"
const SAVE_PATH := "user://test_silph_doors.json"
const FLOOR := &"silph_co_2f"
const DOOR_CELLS: Array[Vector2i] = [Vector2i(4, 10), Vector2i(5, 10)]
const IN_FRONT := Vector2i(4, 9)
const FLAG := &"door_silph_co_2f_d2_open"
const LOCKED := "Il faut une carte."
const TIMEOUT := 15.0

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


func test_every_door_is_two_cells_one_flag_and_two_open_points() -> void:
	var total := 0
	for n: int in range(1, 12):
		var map_id := StringName("silph_co_%df" % n)
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child_autofree(map)
		var flags := StoryFlags.new()
		map.apply_flag_gates(flags)
		for node: Node in map.find_children("*", "KeyDoor", true, false):
			var door := node as KeyDoor
			total += 1
			var label := "%s %s" % [map_id, door.door_id]
			assert_eq(door.blocking_cells.size(), 2, label)
			assert_eq(door.get_open_flag(), KeyDoor.open_flag(map_id, door.door_id), label)
			assert_eq(door.unless_flags.size(), 1, "%s : un seul drapeau" % label)
			for cell: Vector2i in door.blocking_cells:
				assert_true(map.get_grid().is_occupied(cell), "%s %s fermée" % [label, cell])
				var point := map.get_interactions().find(cell, Vector2i.DOWN)
				assert_not_null(point, "%s %s : OUVRIR" % [label, cell])
				if point != null:
					assert_eq(point.kind, Interaction.Kind.OPEN, label)
					assert_eq(point.dialogue_id, KeyDoor.LOCKED_DIALOGUE, label)
					assert_true(point.is_available(flags), label)
			flags.set_flag(door.get_open_flag())
			map.apply_flag_gates(flags)
			for cell: Vector2i in door.blocking_cells:
				assert_false(map.get_grid().is_occupied(cell), "%s %s ouverte" % [label, cell])
				assert_false(map.get_grid().is_solid(cell), "%s %s praticable" % [label, cell])
				var point := map.get_interactions().find(cell, Vector2i.DOWN)
				assert_true(point == null or not point.is_available(flags),
					"%s %s : OUVRIR retiré" % [label, cell])
	assert_eq(total, 20)


func test_without_the_card_refused_with_it_open_for_good_even_after_a_restart() -> void:
	await _play.start(START)
	assert_false(GameState.bag.has(&"card_key"), "départ sans Carte")
	await SceneRouter.change_map(FLOOR, &"from_1f", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	await _play.walk_to(IN_FRONT)
	assert_eq(_play.player.get_cell(), IN_FRONT)
	var grid := _play.boot.get_map().get_grid()
	# Sans la Carte.
	await _play.interact(Vector2i.DOWN)
	assert_eq(_play.pages(), [LOCKED] as Array[String], "refus et texte")
	assert_false(GameState.flags.has_flag(FLAG))
	for cell: Vector2i in DOOR_CELLS:
		assert_false(grid.is_free(cell), "%s fermée" % cell)
	# Avec la Carte.
	GameState.bag.add(&"card_key")
	_play.events.clear()
	await _play.interact(Vector2i.DOWN)
	await wait_until(func() -> bool: return GameState.flags.has_flag(FLAG), TIMEOUT)
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	await wait_process_frames(3)
	assert_eq(_play.pages(), [] as Array[String], "aucun texte à l'ouverture")
	assert_true(GameState.flags.has_flag(FLAG))
	assert_true(GameState.bag.has(&"card_key"), "la Carte est gardée")
	for cell: Vector2i in DOOR_CELLS:
		assert_true(grid.is_free(cell), "%s ouverte" % cell)
	var door_flags: Array = (_play.saved().get("flags", []) as Array).filter(
		func(flag: String) -> bool: return flag.begins_with("door_silph_co_2f_"))
	assert_eq(door_flags, [String(FLAG)], "un seul drapeau, sauvegardé")
	# Application relancée : la porte reste ouverte.
	await _play.resume()
	assert_eq(_play.map_id(), FLOOR)
	assert_true(GameState.flags.has_flag(FLAG), "drapeau rechargé")
	var map := _play.boot.get_map()
	for cell: Vector2i in DOOR_CELLS:
		assert_true(map.get_grid().is_free(cell), "%s ouverte après rechargement" % cell)
		var point := map.get_interactions().find(cell, Vector2i.DOWN)
		assert_true(point == null or not point.is_available(GameState.flags), "OUVRIR disparu")
	await _play.walk_to(DOOR_CELLS[0] + Vector2i.DOWN)
	assert_eq(_play.player.get_cell(), DOOR_CELLS[0] + Vector2i.DOWN, "on passe")
	assert_push_error_count(0)


func test_opening_one_door_leaves_the_other_doors_shut() -> void:
	# Chaque porte a son drapeau : ouvrir d2 avec la Carte ne touche pas d1.
	await _play.start(START, func() -> void: GameState.bag.add(&"card_key"))
	await SceneRouter.change_map(FLOOR, &"from_1f", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	await _play.walk_to(IN_FRONT)
	await _play.interact(Vector2i.DOWN)
	await wait_until(func() -> bool: return GameState.flags.has_flag(FLAG), TIMEOUT)
	assert_true(GameState.flags.has_flag(FLAG))
	assert_false(GameState.flags.has_flag(&"door_silph_co_2f_d1_open"), "d1 reste fermée")
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	for cell: Vector2i in [Vector2i(4, 4), Vector2i(5, 4)]:
		assert_false(_play.boot.get_map().get_grid().is_free(cell), "d1 %s" % cell)
