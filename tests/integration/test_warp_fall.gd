extends GutTest
## Chute du joueur (passe systèmes 2, `systemes-2.md` §2.7.3, T19) : [constant Warp.Trigger.FALL]
## et [member Warp.unless_flags] dans le routeur (instance fraîche, mini-cartes de
## `tests/helpers/strength_rig.gd`). Un pas libre fini sur un trou ouvert mène à l'étage du
## dessous ; un trou bouché (drapeau) est un sol ordinaire ; `unless_flags` coupe aussi un
## passage ordinaire.

const StrengthRig := preload("res://tests/helpers/strength_rig.gd")
const FRAME := 1.0 / 60.0
const TIMEOUT := 5.0
const ACTIONS: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]

var _rig: StrengthRig


func before_each() -> void:
	_rig = StrengthRig.new()
	_rig.build(self)


func after_each() -> void:
	for action: StringName in ACTIONS:
		Input.action_release(action)
	_rig.release()


## Un seul pas libre (entrée tenue jusqu'au départ du pas, joueur avancé à la main) vers
## [param action] ; faux si le joueur n'a pas fini sur [param cell].
func _step(action: StringName, cell: Vector2i) -> bool:
	_rig.player.set_process(false)
	Input.action_press(action)
	for i: int in 60:
		_rig.player._process(FRAME)
		if _rig.player.is_moving():
			break
	Input.action_release(action)
	for i: int in 60:
		if not _rig.player.is_moving():
			break
		_rig.player._process(FRAME)
	return _rig.player.get_cell() == cell


func _settle() -> void:
	await wait_until(func() -> bool: return not _rig.router.is_transitioning(), TIMEOUT)


func test_fall_warp_data_is_copied_and_coexists_with_a_door() -> void:
	var point := WarpPoint.new()
	point.trigger = Warp.Trigger.FALL
	point.target_map = &"d"
	point.target_spawn = &"chute_joueur"
	point.unless_flags.assign([StrengthRig.HOLE_FLAG])
	var warp := point.to_warp()
	point.free()
	assert_true(warp.is_valid())
	assert_eq(warp.unless_flags, [StrengthRig.HOLE_FLAG] as Array[StringName])
	assert_false(warp.matches_step(warp.cell, Vector2i.RIGHT), "pas un passage à pas")
	var table := WarpTable.new()
	assert_true(table.add(warp))
	assert_true(table.add(Warp.new(warp.cell, Warp.Trigger.STEP_ON, Vector2i.ZERO, &"x", &"y")),
		"une porte et un trou ne se gênent pas")


func test_stepping_into_an_open_hole_falls_to_the_floor_below() -> void:
	_rig.start()
	_rig.put_player(StrengthRig.HOLE + Vector2i.LEFT, Vector2i.RIGHT)
	assert_true(_step(&"move_right", StrengthRig.HOLE), "le trou ouvert n'arrête pas le joueur")
	assert_true(_rig.router.is_transitioning(), "chute lancée dans l'image du pas")
	_rig.player.set_process(true)
	await _settle()
	assert_eq(_rig.map().map_id, &"d", "étage du dessous")
	assert_eq(_rig.player.get_cell(), StrengthRig.LANDING, "point `chute_joueur`")
	assert_true(_rig.player.is_input_enabled())


func test_every_direction_falls() -> void:
	_rig.start()
	_rig.put_player(StrengthRig.HOLE + Vector2i.DOWN, Vector2i.UP)
	assert_true(_step(&"move_up", StrengthRig.HOLE))
	assert_true(_rig.router.is_transitioning())
	_rig.player.set_process(true)
	await _settle()
	assert_eq(_rig.map().map_id, &"d")


## Étage du dessous (ancien `qa_strength_b1`, retiré en S2Z) : le rocher tombé n'apparaît et ne
## bloque sa case (occupée, pas un mur) qu'une fois le trou bouché ; le point de chute reste libre.
func test_the_fallen_boulder_below_appears_once_the_hole_is_plugged() -> void:
	var map := _rig.make_map(&"d")
	add_child_autofree(map)
	var gate := map.get_node(^"Entities/FallenBoulder") as FlagGate
	map.apply_flag_gates(_rig.flags)
	assert_false(map.get_grid().is_occupied(StrengthRig.FALLEN), "trou ouvert : pas de rocher")
	assert_false(gate.visible)
	_rig.flags.set_flag(StrengthRig.HOLE_FLAG)
	map.apply_flag_gates(_rig.flags)
	assert_true(gate.visible, "rocher tombé dessiné")
	assert_true(map.get_grid().is_occupied(StrengthRig.FALLEN), "il bloque sa case")
	assert_false(map.get_grid().is_solid(StrengthRig.FALLEN), "ce n'est pas un mur")
	assert_false(map.get_grid().is_occupied(StrengthRig.LANDING), "le point de chute reste libre")


func test_a_plugged_hole_does_not_fall() -> void:
	_rig.flags.set_flag(StrengthRig.HOLE_FLAG)
	_rig.start()
	_rig.put_player(StrengthRig.HOLE + Vector2i.LEFT, Vector2i.RIGHT)
	assert_true(_step(&"move_right", StrengthRig.HOLE))
	assert_false(_rig.router.is_transitioning(), "unless_flags : trou bouché")
	assert_eq(_rig.map().map_id, &"s")


func test_a_scripted_step_onto_a_hole_does_not_fall() -> void:
	_rig.start()
	_rig.put_player(StrengthRig.HOLE + Vector2i.LEFT, Vector2i.RIGHT)
	_rig.player.set_input_enabled(false, &"scene")
	assert_true(_rig.player.script_step(Vector2i.RIGHT))
	await wait_until(func() -> bool: return not _rig.player.is_moving(), TIMEOUT)
	assert_false(_rig.router.is_transitioning(), "pas scripté : comme une porte, rien")
	_rig.player.set_input_enabled(true, &"scene")


func test_unless_flags_also_switch_off_an_ordinary_door() -> void:
	_rig.start()
	_rig.put_player(StrengthRig.DOOR + Vector2i.LEFT, Vector2i.RIGHT)
	_rig.flags.set_flag(StrengthRig.DOOR_FLAG)
	assert_true(_step(&"move_right", StrengthRig.DOOR))
	assert_false(_rig.router.is_transitioning(), "porte coupée par son drapeau")
	_rig.flags.set_flag(StrengthRig.DOOR_FLAG, false)
	assert_true(_step(&"move_left", StrengthRig.DOOR + Vector2i.LEFT))
	assert_true(_step(&"move_right", StrengthRig.DOOR))
	assert_true(_rig.router.is_transitioning(), "sans le drapeau, la porte mène à « d »")
	_rig.player.set_process(true)
	await _settle()
	assert_eq(_rig.map().map_id, &"d")
