extends GutTest
## Chorégraphie calculée (chantier Combat vivant, CV.0 T2 ; §2.6, §3.1, CV-2) : phases, repères
## sonores, modes Complètes / Rapides / Réduites, durée selon la puissance, issue de l'attaque.

const BANDS: Array[Vector2] = [Vector2(0.5, 0.8), Vector2(0.8, 1.3), Vector2(1.2, 1.8),
	Vector2(1.8, 2.5)]
const EPS: float = 0.0001

var _data: PokemonData
var _catalog: MoveFxCatalog


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_catalog = MoveFxCatalog.load_dir()


func _move(power: int, category: MoveData.Category = MoveData.Category.PHYSICAL) -> MoveData:
	var move := MoveData.new()
	move.id = &"test"
	move.power = power
	move.category = category
	return move


func _entry(family: StringName, modifiers: Array[StringName] = [],
		impact: StringName = &"") -> MoveFxEntry:
	var entry := MoveFxEntry.new()
	entry.move_id = &"test"
	entry.family = family
	entry.modifiers = modifiers
	entry.impact = impact
	return entry


func _outcome(result: MoveFxOutcome.Result, hits: int = 1, critical: bool = false) -> MoveFxOutcome:
	var outcome := MoveFxOutcome.new()
	outcome.result = result
	outcome.hits = hits
	outcome.critical = critical
	return outcome


func _plan(move_id: StringName, plan_mode: MoveFxPlan.Mode = MoveFxPlan.Mode.FULL,
		outcome: MoveFxOutcome = null) -> MoveFxPlan:
	var move := _data.get_move(move_id)
	return MoveFxPlan.build(_catalog, _catalog.entry(move_id), move, outcome, plan_mode)


## Ligne de CV-2 attendue, calculée à part du code (tableau du plan §2.6).
func _expected_band(move: MoveData, entry: MoveFxEntry) -> int:
	if entry.has_modifier(&"ko_un_coup") or entry.has_modifier(&"auto_ko"):
		return 3
	if entry.has_modifier(&"multi") or not move.is_damaging() or move.power <= 40:
		return 0
	if move.power <= 80:
		return 1
	return 2 if move.power <= 110 else 3


# --- Durées (CV-2) -----------------------------------------------------------------------

func test_every_move_within_its_cv2_line() -> void:
	for move_id: StringName in _data.get_move_ids():
		var move := _data.get_move(move_id)
		var entry := _catalog.entry(move_id)
		var plan := MoveFxPlan.build(_catalog, entry, move, null, MoveFxPlan.Mode.FULL)
		var band := BANDS[_expected_band(move, entry)]
		assert_eq(plan.band, _expected_band(move, entry), String(move_id))
		assert_between(plan.hit_duration, band.x - EPS, band.y + EPS,
			"%s (puissance %d) : %.2f s" % [move_id, move.power, plan.hit_duration])


func test_fast_and_reduced_at_most_half_a_second_for_every_move() -> void:
	for move_id: StringName in _data.get_move_ids():
		for plan_mode: MoveFxPlan.Mode in [MoveFxPlan.Mode.FAST, MoveFxPlan.Mode.REDUCED]:
			var outcome := _outcome(MoveFxOutcome.Result.HIT, 5)
			var plan := _plan(move_id, plan_mode, outcome)
			assert_lte(plan.duration, 0.5 + EPS, "%s : %.2f s" % [move_id, plan.duration])
			assert_null(plan.phase(MoveFxPlan.ANTICIPATION), "%s : pas d'anticipation" % move_id)
			assert_eq(plan.camera_zoom, 1.0, String(move_id))
			assert_eq(plan.camera_shake, 0.0, String(move_id))


func test_duration_follows_power_inside_a_line() -> void:
	var entry := _entry(&"energie")
	var low := MoveFxPlan.full_hit_duration(_catalog, entry, _move(45, MoveData.Category.SPECIAL))
	var high := MoveFxPlan.full_hit_duration(_catalog, entry, _move(80, MoveData.Category.SPECIAL))
	assert_almost_eq(low, 0.8, EPS)
	assert_almost_eq(high, 1.3, EPS)
	assert_almost_eq(MoveFxPlan.full_hit_duration(_catalog, entry, _move(150)), 2.0 - 0.0,
		0.2, "puissance 150 : dernière ligne")


func test_legendary_takes_the_last_line() -> void:
	var entry := _entry(&"energie")
	assert_eq(MoveFxPlan.band_for(_catalog, entry, _move(40), true), 3)
	assert_eq(MoveFxPlan.band_for(_catalog, entry, _move(40), false), 0)


func test_status_moves_take_the_first_line() -> void:
	var plan := _plan(&"growl")
	assert_eq(plan.band, 0)
	assert_between(plan.duration, 0.5, 0.8)


func test_multi_hit_each_hit_in_the_first_line() -> void:
	var plan := _plan(&"double_kick", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.HIT, 2))
	assert_eq(plan.hits, 2)
	assert_between(plan.hit_duration, 0.5, 0.8)
	assert_almost_eq(plan.duration, plan.hit_duration * 2, EPS)
	assert_not_null(plan.phase(MoveFxPlan.IMPACT, 1), "un impact par coup")
	assert_null(plan.phase(MoveFxPlan.ANTICIPATION, 1), "une seule anticipation")
	assert_has(plan.cue_names(), &"impact_2")
	assert_lt(plan.cue_time(&"impact"), plan.cue_time(&"impact_2"))


func test_single_hit_move_ignores_extra_hits() -> void:
	var plan := _plan(&"tackle", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.HIT, 3))
	assert_eq(plan.hits, 1)


# --- Phases et repères ---------------------------------------------------------------------

func test_full_plan_phases_in_order_and_cues() -> void:
	var plan := _plan(&"thunder_shock")
	var names: Array[StringName] = []
	for item: MoveFxPlan.Phase in plan.phases:
		names.append(item.name)
	assert_eq(names, [MoveFxPlan.ANTICIPATION, MoveFxPlan.TRAVEL, MoveFxPlan.IMPACT,
		MoveFxPlan.RETURN] as Array[StringName])
	for i: int in range(1, plan.phases.size()):
		assert_almost_eq(plan.phases[i].start, plan.phases[i - 1].end(), EPS, "phases contiguës")
	assert_almost_eq(plan.phases[-1].end(), plan.duration, EPS)
	assert_almost_eq(plan.cue_time(MoveFxPlan.CUE_LAUNCH), plan.phase(MoveFxPlan.TRAVEL).start, EPS)
	assert_almost_eq(plan.cue_time(MoveFxPlan.CUE_IMPACT), plan.phase(MoveFxPlan.IMPACT).start, EPS)
	assert_eq(plan.signature, &"eclair")
	assert_eq(plan.origin, &"joues", "CV-10 : Éclair part des joues")


func test_self_moves_play_on_the_user_and_launch_at_zero() -> void:
	var plan := _plan(&"swords_dance")
	assert_true(plan.on_self)
	assert_null(plan.phase(MoveFxPlan.TRAVEL))
	assert_eq(plan.cue_time(MoveFxPlan.CUE_LAUNCH), 0.0)
	assert_gt(plan.cue_time(MoveFxPlan.CUE_IMPACT), 0.0)


func test_origin_defaults() -> void:
	assert_eq(_plan(&"tackle").origin, &"centre")
	assert_eq(_plan(&"ember").origin, &"bouche")


# --- Issue de l'attaque ---------------------------------------------------------------------

func test_miss_and_dodge_replace_the_impact() -> void:
	for result: MoveFxOutcome.Result in [MoveFxOutcome.Result.MISSED, MoveFxOutcome.Result.DODGED]:
		var plan := _plan(&"ember", MoveFxPlan.Mode.FULL, _outcome(result, 0))
		assert_null(plan.phase(MoveFxPlan.IMPACT))
		assert_not_null(plan.phase(MoveFxPlan.MISS))
		assert_eq(plan.cue_time(MoveFxPlan.CUE_IMPACT), -1.0, "aucun son de coup")
		assert_gte(plan.cue_time(MoveFxPlan.CUE_MISS), 0.0)
		assert_eq(plan.camera_shake, 0.0)
		assert_eq(plan.flashes, 0)
		assert_eq(plan.world, [] as Array[StringName])


func test_no_effect() -> void:
	var plan := _plan(&"thunder_shock", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.NO_EFFECT, 0))
	assert_not_null(plan.phase(MoveFxPlan.NO_EFFECT))
	assert_eq(plan.cue_time(MoveFxPlan.CUE_IMPACT), -1.0)


func test_failed_keeps_only_anticipation_and_return() -> void:
	var plan := _plan(&"thunder_wave", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.FAILED, 0))
	assert_eq(plan.phases.size(), 2)
	assert_eq(plan.phases[0].name, MoveFxPlan.ANTICIPATION)
	assert_eq(plan.phases[1].name, MoveFxPlan.RETURN)
	assert_almost_eq(plan.duration, 0.5, EPS)
	assert_eq(plan.cues.size(), 0)


func test_charge_turn() -> void:
	var outcome := _outcome(MoveFxOutcome.Result.CHARGING, 0)
	var full := _plan(&"solar_beam", MoveFxPlan.Mode.FULL, outcome)
	assert_eq(full.band, -1)
	assert_eq(full.phases.size(), 1)
	assert_eq(full.phases[0].name, MoveFxPlan.CHARGE)
	assert_eq(full.cue_time(MoveFxPlan.CUE_CHARGE), 0.0)
	assert_almost_eq(full.duration, 0.6, EPS)
	assert_lte(_plan(&"solar_beam", MoveFxPlan.Mode.FAST, outcome).duration, 0.5)
	var second := _plan(&"solar_beam", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.HIT))
	assert_not_null(second.phase(MoveFxPlan.IMPACT), "tour 2 : l'attaque elle-même")


func test_metronome_and_the_called_move_have_their_own_plans() -> void:
	var events: Array[BattleEvent] = []
	for id: StringName in [&"metronome", &"flamethrower"]:
		var used := BattleEvent.new(BattleEvent.Kind.MOVE_USED, BattleEvent.SideId.PLAYER)
		used.move_id = id
		events.append(used)
	var hit := BattleEvent.new(BattleEvent.Kind.DAMAGE, BattleEvent.SideId.FOE)
	hit.amount = 50
	hit.max_hp = 100
	events.append(hit)
	var metronome := _plan(&"metronome", MoveFxPlan.Mode.FULL, MoveFxOutcome.read(events, 0))
	assert_eq(metronome.family, &"statut_plus")
	var called := _plan(&"flamethrower", MoveFxPlan.Mode.FULL, MoveFxOutcome.read(events, 1))
	assert_eq(called.signature, &"lance_flammes")
	assert_not_null(called.phase(MoveFxPlan.IMPACT))


# --- Caméra, lumière, Réduites ------------------------------------------------------------------

func test_critical_raises_the_camera_within_ceilings() -> void:
	var normal := _plan(&"thunder_shock")
	var critical := _plan(&"thunder_shock", MoveFxPlan.Mode.FULL,
		_outcome(MoveFxOutcome.Result.HIT, 1, true))
	assert_gt(critical.camera_zoom, normal.camera_zoom)
	assert_gt(critical.camera_shake, normal.camera_shake)
	for move_id: StringName in _data.get_move_ids():
		var plan := _plan(move_id, MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.HIT, 5, true))
		assert_lte(plan.camera_zoom, 1.06 + EPS, String(move_id))
		assert_lte(plan.camera_shake, 6.0 + EPS, String(move_id))


func test_never_more_than_three_flashes_per_second() -> void:
	for move_id: StringName in _data.get_move_ids():
		for plan_mode: MoveFxPlan.Mode in [MoveFxPlan.Mode.FULL, MoveFxPlan.Mode.FAST]:
			var plan := _plan(move_id, plan_mode, _outcome(MoveFxOutcome.Result.HIT, 5))
			assert_lte(float(plan.flashes), 3.0 * plan.duration + EPS,
				"%s : %d flashs en %.2f s" % [move_id, plan.flashes, plan.duration])


func test_thunder_shock_lights_the_scene() -> void:
	var plan := _plan(&"thunder_shock")
	assert_gt(plan.light_peak, 0.35)
	assert_gte(plan.flashes, 1)


func test_reduce_flashes_caps_the_light() -> void:
	var plan := MoveFxPlan.build(_catalog, _catalog.entry(&"thunder_shock"),
		_data.get_move(&"thunder_shock"), null, MoveFxPlan.Mode.FULL, true)
	assert_lte(plan.light_peak, 0.35 + EPS)


func test_reduced_mode_halves_particles_and_never_shakes() -> void:
	var plan := _plan(&"earthquake", MoveFxPlan.Mode.REDUCED)
	assert_almost_eq(plan.particle_scale, 0.5, EPS)
	assert_false(plan.target_shake)
	assert_eq(plan.camera_shake, 0.0)
	var fast := _plan(&"earthquake", MoveFxPlan.Mode.FAST)
	assert_almost_eq(fast.particle_scale, 1.0, EPS)
	assert_true(fast.target_shake)


func test_world_reactions_in_full_only() -> void:
	assert_has(_plan(&"earthquake").world, &"dust")
	assert_eq(_plan(&"earthquake", MoveFxPlan.Mode.FAST).world, [] as Array[StringName],
		"Rapides : monde réduit à la lumière")


func test_mode_from_settings() -> void:
	assert_eq(MoveFxPlan.mode_for(GameSettings.BattleAnimations.FULL, false), MoveFxPlan.Mode.FULL)
	assert_eq(MoveFxPlan.mode_for(GameSettings.BattleAnimations.FAST, false), MoveFxPlan.Mode.FAST)
	assert_eq(MoveFxPlan.mode_for(GameSettings.BattleAnimations.FULL, true),
		MoveFxPlan.Mode.REDUCED, "Réduire les animations l'emporte")
