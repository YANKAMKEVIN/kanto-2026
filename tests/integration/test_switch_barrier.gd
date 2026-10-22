extends GutTest
## Interrupteurs et barrières (passe systèmes 2, `systemes-2.md` §2.7.4, T20) sur les mini-cartes
## de `tests/helpers/strength_rig.gd` : un rocher poussé sur l'interrupteur pose son drapeau une
## fois pour toutes (sauvegarde forcée), la barrière ([FlagGate] `blocking_cells`, sauf ce
## drapeau) s'ouvre pendant la visite ; à la visite suivante, le rocher est revenu à son origine,
## l'interrupteur reste enfoncé et la barrière ouverte.

const StrengthRig := preload("res://tests/helpers/strength_rig.gd")
const TIMEOUT := 5.0

var _rig: StrengthRig


func before_each() -> void:
	_rig = StrengthRig.new()
	_rig.build(self)


func after_each() -> void:
	_rig.release()


func _gate(gate_name: String) -> FlagGate:
	return _rig.map().get_node(NodePath("Entities/" + gate_name)) as FlagGate


func _push_d() -> BoulderRules.Outcome:
	_rig.put_player(StrengthRig.D + Vector2i.LEFT, Vector2i.RIGHT)
	await _rig.director.activate()
	var outcome: BoulderRules.Outcome = await _rig.director.push(
		_rig.director.boulder_at(StrengthRig.D), Vector2i.RIGHT)
	await wait_until(func() -> bool: return not _rig.player.is_moving(), TIMEOUT)
	return outcome


func test_the_barrier_blocks_before_the_switch() -> void:
	_rig.start()
	assert_true(_gate("Barrier").visible)
	assert_true(_rig.map().get_grid().is_occupied(StrengthRig.BARRIER), "barrière fermée")
	assert_false(_gate("SwitchPressed").visible)


func test_a_boulder_on_the_switch_opens_the_barrier() -> void:
	_rig.start()
	assert_eq(await _push_d(), BoulderRules.Outcome.ON_SWITCH)
	assert_true(_rig.flags.has_flag(StrengthRig.SWITCH_FLAG), "drapeau de l'interrupteur")
	assert_eq(_rig.saves, ["force"] as Array[String], "sauvegarde forcée")
	assert_eq(_rig.director.boulder_at(StrengthRig.SWITCH).get_cell(), StrengthRig.SWITCH,
		"le rocher s'arrête sur l'interrupteur")
	assert_eq(_rig.player.get_cell(), StrengthRig.D, "le joueur a suivi")
	assert_false(_gate("Barrier").visible, "barrière ouverte pendant la visite")
	assert_false(_rig.map().get_grid().is_occupied(StrengthRig.BARRIER), "case libérée")
	assert_true(_gate("SwitchPressed").visible, "dessin « enfoncé »")
	assert_true(_rig.player.is_input_enabled())


func test_pushing_off_the_switch_does_not_set_the_flag_twice() -> void:
	_rig.start()
	await _push_d()
	var boulder := _rig.director.boulder_at(StrengthRig.SWITCH)
	assert_eq(await _rig.director.push(boulder, Vector2i.RIGHT), BoulderRules.Outcome.MOVED)
	await wait_until(func() -> bool: return not _rig.player.is_moving(), TIMEOUT)
	assert_eq(_rig.saves.size(), 1, "drapeau déjà posé : aucune nouvelle sauvegarde")
	assert_true(_rig.flags.has_flag(StrengthRig.SWITCH_FLAG), "l'interrupteur reste enfoncé")
	assert_false(_gate("Barrier").visible)
	assert_eq(await _rig.director.push(boulder, Vector2i.RIGHT), BoulderRules.Outcome.MOVED,
		"la case de la barrière ouverte accepte un rocher")


func test_next_visit_boulder_back_switch_still_pressed() -> void:
	_rig.start()
	await _push_d()
	_rig.router.change_map(&"s", &"start", Vector2i.RIGHT)
	await wait_until(func() -> bool: return not _rig.router.is_transitioning(), TIMEOUT)
	assert_not_null(_rig.director.boulder_at(StrengthRig.D), "rocher revenu à son origine")
	assert_null(_rig.director.boulder_at(StrengthRig.SWITCH))
	assert_true(_rig.director.get_field().is_switch_pressed(StrengthRig.SWITCH, _rig.flags))
	assert_false(_gate("Barrier").visible, "barrière toujours ouverte")
	assert_false(_rig.map().get_grid().is_occupied(StrengthRig.BARRIER))
	assert_true(_gate("SwitchPressed").visible)
