extends GutTest
## Plancher du chantier Combat vivant (CV.1 T9, `docs/tech/combat-vivant.md` §3.2, §5.1) : chaque
## attaque des données joue sans erreur, dans chaque issue et chaque mode, et rend la scène à son
## repos ; les 17 familles ont leur art peint ; les briques propres (Psy, Son, effets sur soi) et
## les 9 modificateurs se voient. Aucun combat ralenti : l'attaque est avancée à la main.

const VIEW := Vector2(1920, 1080)
const STEP: float = 1.0 / 20.0
const FAMILIES: int = 17

var _data: PokemonData
var _catalog: MoveFxCatalog
var _layer: CanvasLayer
var _player: MoveFxPlayer
var _user: Sprite2D
var _target: Sprite2D


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_catalog = MoveFxCatalog.load_dir()


func before_each() -> void:
	_layer = CanvasLayer.new()
	add_child_autofree(_layer)
	_user = Sprite2D.new()
	_user.scale = Vector2(2.0, 2.0)
	_layer.add_child(_user)
	_target = Sprite2D.new()
	_layer.add_child(_target)
	_player = MoveFxPlayer.new()
	_layer.add_child(_player)
	_player.setup(_layer)


func _stage() -> MoveFxStage:
	var stage := MoveFxStage.new()
	stage.user = _user
	stage.target = _target
	stage.user_rest = Vector2(560, 1080)
	stage.target_rest = Vector2(1400, 520)
	_user.position = stage.user_rest
	_target.position = stage.target_rest
	stage.user_rect = Rect2(360, 640, 400, 440)
	stage.target_rect = Rect2(1250, 260, 300, 260)
	stage.view_size = VIEW
	return stage


func _outcome(result: MoveFxOutcome.Result, hits: int = 1) -> MoveFxOutcome:
	var outcome := MoveFxOutcome.new()
	outcome.result = result
	outcome.hits = hits
	return outcome


func _plan(move_id: StringName, outcome: MoveFxOutcome = null,
		plan_mode: MoveFxPlan.Mode = MoveFxPlan.Mode.FULL) -> MoveFxPlan:
	return MoveFxPlan.build(_catalog, _catalog.entry(move_id), _data.get_move(move_id), outcome,
		plan_mode)


## Joue [param plan] pas à pas jusqu'au bout ; vrai s'il a fini.
func _run(plan: MoveFxPlan, stage: MoveFxStage) -> bool:
	_player.speed_scale = 1.0
	_player.play(plan, stage)
	var guard := 0
	while _player.is_playing() and guard < 400:
		_player.advance(STEP)
		guard += 1
	return not _player.is_playing()


func _at_rest(stage: MoveFxStage) -> bool:
	if _user.position != stage.user_rest or _target.position != stage.target_rest:
		return false
	if _user.scale != Vector2(2.0, 2.0) or _user.modulate != Color.WHITE \
			or _target.modulate != Color.WHITE or _target.scale != Vector2.ONE:
		return false
	for role: int in MoveFxPlayer.Flip.size():
		if _player.get_art(role as MoveFxPlayer.Flip).visible:
			return false
	return _player.camera.is_at_rest() and not _player.get_light().is_lit()


## Instant [param share] (0..1) de la phase [param phase_name] du coup [param hit].
func _pose_in(plan: MoveFxPlan, phase_name: StringName, share: float, hit: int = 0) -> void:
	var phase := plan.phase(phase_name, hit)
	assert_not_null(phase, "%s : phase %s" % [plan.move_id, phase_name])
	if phase != null:
		_player.pose(phase.start + phase.duration * share)


func _shown(role: MoveFxPlayer.Flip) -> bool:
	return _player.get_art(role).visible


func _waves_shown() -> int:
	var count := 0
	for role: MoveFxPlayer.Flip in [MoveFxPlayer.Flip.WAVE_A, MoveFxPlayer.Flip.WAVE_B,
			MoveFxPlayer.Flip.WAVE_C]:
		count += 1 if _shown(role) else 0
	return count


# --- Toutes les attaques ---------------------------------------------------------------

func test_every_move_plays_every_outcome_in_every_mode() -> void:
	var stage := _stage()
	var played := 0
	var failures: Array[String] = []
	for move_id: StringName in _catalog.move_ids():
		var move := _data.get_move(move_id)
		if move == null:
			continue # attaque pas encore en données (annexe A)
		var entry := _catalog.entry(move_id)
		var outcomes: Array[MoveFxOutcome] = [null, _outcome(MoveFxOutcome.Result.MISSED),
			_outcome(MoveFxOutcome.Result.NO_EFFECT), _outcome(MoveFxOutcome.Result.FAILED),
			_outcome(MoveFxOutcome.Result.AFFECTED)]
		if entry.has_modifier(&"multi"):
			outcomes.append(_outcome(MoveFxOutcome.Result.HIT, 3))
		if entry.has_modifier(&"charge"):
			outcomes.append(_outcome(MoveFxOutcome.Result.CHARGING))
		var ohko := _outcome(MoveFxOutcome.Result.HIT)
		ohko.ohko = true
		ohko.critical = true
		outcomes.append(ohko)
		for outcome: MoveFxOutcome in outcomes:
			for plan_mode: MoveFxPlan.Mode in MoveFxPlan.Mode.values():
				var plan := _plan(move_id, outcome, plan_mode)
				if not _run(plan, stage) or not _at_rest(stage):
					failures.append("%s %s %s" % [move_id,
						"hit" if outcome == null else MoveFxOutcome.Result.find_key(outcome.result),
						MoveFxPlan.Mode.find_key(plan_mode)])
		played += 1
	assert_gte(played, 159, "toutes les attaques des données (159 au moins)")
	assert_eq(failures, [] as Array[String], "chaque attaque finit et rend la scène au repos")


func test_every_move_instant_at_speed_zero() -> void:
	var stage := _stage()
	_player.speed_scale = 0.0
	for move_id: StringName in _catalog.move_ids():
		if _data.get_move(move_id) == null:
			continue
		await _player.play(_plan(move_id), stage)
		assert_false(_player.is_playing(), "%s : instantané" % move_id)
	assert_true(_at_rest(stage), "repos")


func test_every_family_has_painted_art() -> void:
	var families: Dictionary = {}
	for move_id: StringName in _catalog.move_ids():
		var entry := _catalog.entry(move_id)
		families[entry.family] = true
	assert_eq(families.size(), FAMILIES, "les 17 familles sont employées")
	for family: StringName in families:
		var art := JsonFields.get_dict(JsonFields.get_dict(_catalog.family(family), "fx"), "art")
		assert_false(art.is_empty(), "%s : art peint" % family)
		for role: String in art:
			assert_true(FxArt.has(StringName(art[role])), "%s : %s" % [family, art[role]])


func test_manifests_never_share_an_id() -> void:
	var seen: Dictionary = {}
	for manifest: String in FxArt.MANIFESTS:
		var ids := FxArt.ids_of(manifest)
		assert_gt(ids.size(), 0, manifest)
		for id: StringName in ids:
			assert_false(seen.has(id), "%s : déjà dans %s" % [id, seen.get(id, "")])
			seen[id] = manifest
			assert_true(FxArt.has(id), "%s chargé" % id)


# --- Briques propres -------------------------------------------------------------------

func test_painted_core_on_every_damaging_family() -> void:
	var stage := _stage()
	for move_id: StringName in [&"water_gun", &"vine_whip", &"poison_sting", &"rock_throw",
			&"gust", &"lick", &"dragon_rage", &"sludge"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_in(plan, MoveFxPlan.TRAVEL, 0.5)
		assert_true(_shown(MoveFxPlayer.Flip.TRAVEL), "%s : trajet peint" % move_id)
		_player.stop()


func test_code_beams_still_get_a_painted_impact() -> void:
	var stage := _stage()
	for move_id: StringName in [&"hyper_beam", &"psybeam", &"confusion"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_in(plan, MoveFxPlan.IMPACT, 0.4)
		assert_true(_shown(MoveFxPlayer.Flip.IMPACT), "%s : impact peint" % move_id)
		_player.stop()


func test_psychic_and_sound_send_waves_in_series() -> void:
	var stage := _stage()
	for move_id: StringName in [&"confusion", &"growl", &"supersonic"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_in(plan, MoveFxPlan.TRAVEL, 0.7)
		assert_gte(_waves_shown(), 2, "%s : plusieurs ondes à la suite" % move_id)
		_player.stop()


func test_psychic_target_wobbles_in_place() -> void:
	var stage := _stage()
	var plan := _plan(&"confusion")
	_player.play(plan, stage)
	var squashed := false
	for share: float in [0.2, 0.35, 0.5, 0.65]:
		_pose_in(plan, MoveFxPlan.IMPACT, share)
		assert_eq(_target.position, stage.target_rest, "la cible reste en place")
		squashed = squashed or absf(_target.scale.x - _target.scale.y) > 0.05
	assert_true(squashed, "la cible ondule")
	_player.stop()


func test_self_effects_play_on_the_user() -> void:
	var stage := _stage()
	for move_id: StringName in [&"swords_dance", &"recover", &"harden"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_in(plan, MoveFxPlan.IMPACT, 0.4)
		var aura := _player.get_art(MoveFxPlayer.Flip.IMPACT)
		assert_true(aura.visible, "%s : aura peinte" % move_id)
		assert_eq(aura.position, stage.user_rect.get_center(), "%s : sur le lanceur" % move_id)
		_player.stop()


func test_family_tint_colours_its_flipbooks() -> void:
	var stage := _stage()
	var plan := _plan(&"lick")
	assert_ne(plan.art_tint, Color.WHITE, "Spectre teinté")
	_player.play(plan, stage)
	_pose_in(plan, MoveFxPlan.TRAVEL, 0.5)
	var orb := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_eq(Color(orb.modulate, 1.0), Color(plan.art_tint, 1.0))
	_player.stop()


# --- Modificateurs ---------------------------------------------------------------------

func test_drain_streams_back_to_the_user() -> void:
	var stage := _stage()
	var plan := _plan(&"absorb")
	_player.play(plan, stage)
	_pose_in(plan, MoveFxPlan.RETURN, 0.4)
	assert_gt(_waves_shown(), 0, "flux visible au retour")
	_player.stop()
	plan = _plan(&"absorb", _outcome(MoveFxOutcome.Result.MISSED))
	_player.play(plan, stage)
	_pose_in(plan, MoveFxPlan.RETURN, 0.4)
	assert_eq(_waves_shown(), 0, "rien ne revient d'un raté")
	_player.stop()


func test_trap_ring_turns_around_the_target() -> void:
	var stage := _stage()
	for move_id: StringName in [&"wrap", &"fire_spin", &"clamp"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_in(plan, MoveFxPlan.IMPACT, 0.6)
		assert_eq(_waves_shown(), MoveFxPlayer.WAVE_COUNT, "%s : anneau" % move_id)
		var element := _player.get_art(MoveFxPlayer.Flip.WAVE_A)
		assert_lt(element.position.distance_to(stage.impact_point()),
			stage.target_rect.size.x, "%s : autour de la cible" % move_id)
		_player.stop()


func test_recoil_shakes_and_dims_the_user() -> void:
	var stage := _stage()
	var plan := _plan(&"double_edge")
	_player.play(plan, stage)
	_pose_in(plan, MoveFxPlan.RETURN, 0.1)
	assert_lt(_user.modulate.r, 0.99, "le lanceur encaisse")
	_player.stop()


func test_crash_drops_the_user_on_a_miss() -> void:
	var stage := _stage()
	var move_id := &"jump_kick" if _data.get_move(&"jump_kick") != null else &"hi_jump_kick"
	var plain := _plan(move_id, _outcome(MoveFxOutcome.Result.MISSED))
	plain.modifiers.erase(&"chute")
	_player.play(plain, stage)
	_pose_in(plain, MoveFxPlan.RETURN, 0.3)
	var plain_y := _user.position.y
	_player.stop()
	var plan := _plan(move_id, _outcome(MoveFxOutcome.Result.MISSED))
	_player.play(plan, stage)
	_pose_in(plan, MoveFxPlan.RETURN, 0.3)
	assert_gt(_user.position.y, plain_y + 20.0, "il retombe")
	assert_lt(_user.scale.y, _user.scale.x, "écrasé")
	_player.stop()


func test_self_ko_lights_and_shakes_the_user() -> void:
	var stage := _stage()
	var plan := _plan(&"explosion")
	_player.play(plan, stage)
	_pose_in(plan, MoveFxPlan.IMPACT, 0.2)
	assert_gt(_user.modulate.r, 1.0, "le lanceur s'illumine")
	assert_ne(_user.position.x, stage.user_rest.x, "et tremble")
	_player.stop()


func test_one_hit_ko_holds_the_impact_longer() -> void:
	var stage := _stage()
	var plain := _plan(&"horn_drill")
	var ohko := _outcome(MoveFxOutcome.Result.HIT)
	ohko.ohko = true
	var heavy := _plan(&"horn_drill", ohko)
	var share := MoveFxPlayer.HIT_STOP * 1.5 / plain.phase(MoveFxPlan.IMPACT).duration
	_player.play(plain, stage)
	_pose_in(plain, MoveFxPlan.IMPACT, share)
	var plain_scale := _target.scale
	_player.stop()
	_player.play(heavy, stage)
	_pose_in(heavy, MoveFxPlan.IMPACT, share)
	assert_gt(_target.scale.x, plain_scale.x, "encore figé sur l'impact")
	_player.stop()
