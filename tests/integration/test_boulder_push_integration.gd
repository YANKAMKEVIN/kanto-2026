extends GutTest
## Poussée des rochers de Force (passe systèmes 2, `systemes-2.md` §2.7.2, T18) : [Boulder],
## [StrengthDirector], sur les mini-cartes de `tests/helpers/strength_rig.gd` (sans Boot).
## Rochers posés à l'origine, appui tenu 0,25 s (en images simulées), glissade et pas du joueur,
## refus (mur, eau, rocher, case interdite), chute dans le trou (drapeau, sauvegarde forcée,
## trou désormais praticable), Force qui retombe au changement de carte, EXAMINER.

const StrengthRig := preload("res://tests/helpers/strength_rig.gd")
const FrameSim := preload("res://tests/helpers/frame_sim.gd")
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


func _director() -> StrengthDirector:
	return _rig.director


func _grid() -> GridWorld:
	return _rig.map().get_grid()


func _push_and_wait(boulder: Boulder, direction: Vector2i) -> BoulderRules.Outcome:
	var outcome: BoulderRules.Outcome = await _director().push(boulder, direction)
	await wait_until(func() -> bool: return not _rig.player.is_moving(), TIMEOUT)
	return outcome


# --- Mise en place ---------------------------------------------------------------------

func test_boulders_are_placed_at_their_origins_and_occupy_the_grid() -> void:
	_rig.start()
	assert_eq(_director().get_boulders().size(), 4)
	for cell: Vector2i in [StrengthRig.A, StrengthRig.B, StrengthRig.C, StrengthRig.D]:
		var boulder := _director().boulder_at(cell)
		assert_not_null(boulder, "rocher en %s" % cell)
		assert_eq(_grid().get_occupant(cell), boulder, "occupant de la grille")
		assert_eq(boulder.position, Grid.cell_to_world(cell), "origine aux pieds")
		assert_eq(boulder.get_parent(), _rig.map().get_entities(), "trié avec les entités")
	assert_false(_director().is_active(), "Force inactive à l'arrivée")


func test_a_boulder_origin_taken_by_the_player_is_skipped_for_the_visit() -> void:
	_rig.router.start_at(&"s", StrengthRig.A, Vector2i.RIGHT)
	assert_eq(_rig.player.get_cell(), StrengthRig.A)
	assert_null(_director().boulder_at(StrengthRig.A), "pas de rocher sous le joueur")
	assert_eq(_director().get_boulders().size(), 3)


func test_examine_faces_the_boulder_until_strength_is_active() -> void:
	_rig.start()
	var target := InteractionFinder.find(_grid(), null, StrengthRig.START, Vector2i.RIGHT)
	assert_not_null(target, "EXAMINER face au rocher")
	assert_eq(target.kind, Interaction.Kind.EXAMINE)
	assert_eq(target.dialogue_id, &"strength_boulder")
	assert_eq(target.source, _director().boulder_at(StrengthRig.A))
	assert_true(await _director().activate())
	assert_true(_director().is_active())
	assert_null(InteractionFinder.find(_grid(), null, StrengthRig.START, Vector2i.RIGHT),
		"Force active : rien à proposer, on pousse [D]")
	assert_false(await _director().activate(), "déjà active")


# --- Appui tenu --------------------------------------------------------------------------

func test_without_strength_holding_against_a_boulder_does_nothing() -> void:
	_rig.start()
	var sim := FrameSim.new(get_tree(), [_rig.player, _director()])
	Input.action_press(&"move_right")
	for i: int in 60:
		await sim.frame()
	Input.action_release(&"move_right")
	sim.finish()
	assert_eq(_director().boulder_at(StrengthRig.A).get_cell(), StrengthRig.A)
	assert_eq(_rig.player.get_cell(), StrengthRig.START)


func test_the_push_starts_after_a_quarter_second_held() -> void:
	_rig.start()
	await _director().activate()
	var sim := FrameSim.new(get_tree(), [_rig.player, _director()])
	var marks := {"bump": -1, "push": -1}
	_rig.player.bumped.connect(func(_d: Vector2i) -> void:
		if marks["bump"] < 0:
			marks["bump"] = sim.frames)
	_director().push_started.connect(func() -> void: marks["push"] = sim.frames)
	Input.action_press(&"move_right")
	await sim.run_until(func() -> bool: return marks["push"] >= 0, 2.0)
	var held: int = marks["push"] - marks["bump"]
	assert_gte(marks["bump"], 0, "le joueur bute contre le rocher")
	assert_gte(held, roundi(StrengthDirector.HOLD_TIME / FrameSim.STEP),
		"pas de poussée avant 0,25 s")
	assert_lte(held, roundi(StrengthDirector.HOLD_TIME / FrameSim.STEP) + 2, "au plus un pas de plus")
	assert_false(_rig.player.is_input_enabled(), "entrées bloquées pendant la glissade")
	await sim.run_until(func() -> bool: return _rig.player.is_input_enabled(), 2.0)
	Input.action_release(&"move_right")
	sim.finish()
	assert_eq(_director().boulder_at(StrengthRig.A + Vector2i.RIGHT).get_cell(),
		StrengthRig.A + Vector2i.RIGHT, "le rocher a glissé d'une case")
	assert_eq(_rig.player.get_cell(), StrengthRig.A, "le joueur a suivi")
	assert_true(_grid().is_free(StrengthRig.START), "case de départ rendue")


func test_a_short_bump_does_not_push() -> void:
	_rig.start()
	await _director().activate()
	var sim := FrameSim.new(get_tree(), [_rig.player, _director()])
	Input.action_press(&"move_right")
	for i: int in 8:
		await sim.frame()
	Input.action_release(&"move_right")
	for i: int in 40:
		await sim.frame()
	sim.finish()
	assert_eq(_director().boulder_at(StrengthRig.A).get_cell(), StrengthRig.A)


func test_holding_pushes_again_and_again_until_the_hole() -> void:
	_rig.start()
	await _director().activate()
	var sim := FrameSim.new(get_tree(), [_rig.player, _director()])
	var outcomes: Array[BoulderRules.Outcome] = []
	var cells: Array[Vector2i] = []
	_director().push_finished.connect(func(o: BoulderRules.Outcome) -> void:
		outcomes.append(o)
		cells.append(_rig.player.get_cell()))
	Input.action_press(&"move_right")
	await sim.run_until(func() -> bool: return outcomes.size() >= 3, 6.0)
	Input.action_release(&"move_right")
	await sim.run_until(func() -> bool: return not _rig.player.is_moving(), 1.0)
	sim.finish()
	assert_eq(outcomes, [BoulderRules.Outcome.MOVED, BoulderRules.Outcome.MOVED,
		BoulderRules.Outcome.FELL] as Array[BoulderRules.Outcome])
	assert_eq(cells, [StrengthRig.A, StrengthRig.A + Vector2i.RIGHT,
		StrengthRig.A + Vector2i.RIGHT] as Array[Vector2i],
		"le joueur suit chaque glissade, pas la chute")
	assert_eq(_rig.map().map_id, &"s", "trou bouché aussitôt : il continue sans tomber")
	assert_false(_rig.router.is_transitioning())


# --- Résultats ----------------------------------------------------------------------------

func test_refusals_shake_without_moving_nor_flag() -> void:
	_rig.start()
	await _director().activate()
	var boulder := _director().boulder_at(StrengthRig.B)
	# Mur, eau, rocher, case interdite : le pousseur est de l'autre côté (non vérifié ici).
	for direction: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT]:
		var outcome: BoulderRules.Outcome = await _director().push(boulder, direction)
		assert_eq(outcome, BoulderRules.Outcome.REFUSED, "refus vers %s" % direction)
		assert_eq(boulder.get_cell(), StrengthRig.B)
		assert_true(boulder.is_animating(), "il tremble")
	assert_eq(_grid().get_occupant(StrengthRig.B), boulder)
	assert_true(_rig.player.is_input_enabled(), "un refus ne bloque rien")
	assert_eq(_rig.saves.size(), 0)


func test_a_boulder_pushed_into_the_hole_plugs_it() -> void:
	_rig.start()
	await _director().activate()
	var boulder := _director().boulder_at(StrengthRig.A)
	assert_eq(await _push_and_wait(boulder, Vector2i.RIGHT), BoulderRules.Outcome.MOVED)
	assert_eq(await _push_and_wait(boulder, Vector2i.RIGHT), BoulderRules.Outcome.MOVED)
	assert_eq(_rig.saves.size(), 0, "aucun drapeau, aucune sauvegarde")
	assert_false(_rig.map().get_node(^"Entities/HoleFilled").visible)
	assert_eq(await _push_and_wait(boulder, Vector2i.RIGHT), BoulderRules.Outcome.FELL)
	assert_true(_rig.flags.has_flag(StrengthRig.HOLE_FLAG), "drapeau du trou posé")
	assert_eq(_rig.saves, ["force"] as Array[String], "sauvegarde forcée, une fois")
	assert_false(is_instance_valid(boulder) and boulder.is_inside_tree() and boulder.visible,
		"le rocher a disparu")
	assert_null(_director().boulder_at(StrengthRig.HOLE))
	assert_true(_grid().is_free(StrengthRig.HOLE + Vector2i.LEFT), "case quittée rendue")
	assert_true(_grid().is_free(StrengthRig.HOLE), "trou bouché : un sol libre")
	assert_true(_rig.map().get_node(^"Entities/HoleFilled").visible, "dessin « trou bouché »")
	assert_false(_rig.map().get_node(^"Entities/HoleOpen").visible)
	assert_true(_rig.player.is_input_enabled())
	# Le joueur marche dessus sans tomber.
	_rig.player.set_process(false)
	Input.action_press(&"move_right")
	for i: int in 120:
		_rig.player._process(1.0 / 60.0)
		if _rig.player.get_cell() == StrengthRig.HOLE + Vector2i.RIGHT:
			break
	Input.action_release(&"move_right")
	assert_eq(_rig.player.get_cell(), StrengthRig.HOLE + Vector2i.RIGHT, "il a traversé")
	assert_false(_rig.router.is_transitioning(), "aucune chute")
	assert_eq(_rig.map().map_id, &"s")


func test_strength_resets_on_map_change_and_boulders_go_back() -> void:
	_rig.start()
	await _director().activate()
	var boulder := _director().boulder_at(StrengthRig.A)
	assert_eq(await _push_and_wait(boulder, Vector2i.RIGHT), BoulderRules.Outcome.MOVED)
	_rig.router.change_map(&"s", &"start", Vector2i.RIGHT)
	await wait_until(func() -> bool: return not _rig.router.is_transitioning(), TIMEOUT)
	assert_false(_director().is_active(), "Force retombe à chaque carte")
	assert_not_null(_director().boulder_at(StrengthRig.A), "retour à l'origine")
	assert_null(_director().boulder_at(StrengthRig.A + Vector2i.RIGHT))
	assert_eq(_director().get_boulders().size(), 4)
	assert_eq(await _director().push(_director().boulder_at(StrengthRig.A), Vector2i.RIGHT),
		BoulderRules.Outcome.REFUSED, "sans Force, rien ne bouge")


func test_a_plugged_hole_stays_plugged_on_the_next_visit() -> void:
	_rig.flags.set_flag(StrengthRig.HOLE_FLAG)
	_rig.start()
	assert_true(_rig.map().get_node(^"Entities/HoleFilled").visible)
	await _director().activate()
	var boulder := _director().boulder_at(StrengthRig.A)
	for i: int in 3:
		assert_eq(await _push_and_wait(boulder, Vector2i.RIGHT), BoulderRules.Outcome.MOVED,
			"poussée n° %d" % (i + 1))
	assert_eq(boulder.get_cell(), StrengthRig.HOLE, "il roule sur le trou bouché")
	assert_eq(_rig.saves.size(), 0)


func test_a_battle_does_not_reset_strength() -> void:
	# Seul SceneRouter.map_changed remet Force à zéro (Boot n'y branche rien d'autre) : un combat
	# ne change pas de carte. Les signaux de transition sans changement de carte non plus.
	_rig.start()
	await _director().activate()
	_rig.router.transition_started.emit(&"s")
	_rig.router.map_entered.emit(_rig.map())
	assert_true(_director().is_active())
