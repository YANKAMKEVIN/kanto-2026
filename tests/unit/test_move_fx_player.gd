extends GutTest
## Lecteur d'effets (chantier Combat vivant, CV.0 T3, partie hors scène ; §2.5, §2.7, §3.1) :
## repères sonores dans l'ordre et à l'heure du plan, retour au repos, plafonds de la caméra,
## Réduites sans caméra, budget de particules. Aucun combat ralenti : l'attaque est avancée à la
## main ([method MoveFxPlayer.advance]) ou jouée à `speed_scale` = 0.

const EPS: float = 0.0001
const VIEW := Vector2(1920, 1080)

var _data: PokemonData
var _catalog: MoveFxCatalog
var _layer: CanvasLayer
var _player: MoveFxPlayer
var _user: Sprite2D
var _target: Sprite2D
var _decor: Sprite2D
var _cues: Array[StringName] = []
var _cue_times: Array[float] = []
var _clock: float = 0.0


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_catalog = MoveFxCatalog.load_dir()


func before_each() -> void:
	_layer = CanvasLayer.new()
	add_child_autofree(_layer)
	_decor = Sprite2D.new()
	_decor.modulate = Color(0.9, 0.95, 1.0, 1.0)
	_layer.add_child(_decor)
	_user = Sprite2D.new()
	_user.scale = Vector2(2.0, 2.0)
	_layer.add_child(_user)
	_target = Sprite2D.new()
	_layer.add_child(_target)
	_player = MoveFxPlayer.new()
	_layer.add_child(_player)
	_player.setup(_layer)
	_player.fx_cue.connect(_on_cue)
	_cues.clear()
	_cue_times.clear()
	_clock = 0.0


func _on_cue(cue: StringName, _move_id: StringName) -> void:
	_cues.append(cue)
	_cue_times.append(_clock)


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
	stage.decor_back = _decor
	stage.view_size = VIEW
	return stage


func _plan(move_id: StringName, plan_mode: MoveFxPlan.Mode = MoveFxPlan.Mode.FULL,
		outcome: MoveFxOutcome = null) -> MoveFxPlan:
	return MoveFxPlan.build(_catalog, _catalog.entry(move_id), _data.get_move(move_id), outcome,
		plan_mode)


func _outcome(result: MoveFxOutcome.Result, hits: int = 1) -> MoveFxOutcome:
	var outcome := MoveFxOutcome.new()
	outcome.result = result
	outcome.hits = hits
	return outcome


## Joue [param plan] en l'avançant de [param step] s à la fois ; rend les poses relevées
## (zoom de la caméra à chaque pas).
func _step_through(plan: MoveFxPlan, stage: MoveFxStage, step: float = 1.0 / 60.0) -> Array[float]:
	var zooms: Array[float] = []
	_player.play(plan, stage)
	var guard := 0
	while _player.is_playing() and guard < 1000:
		_clock += step
		_player.advance(step)
		zooms.append(_player.camera.get_zoom())
		guard += 1
	return zooms


func _assert_at_rest(stage: MoveFxStage) -> void:
	assert_eq(_user.position, stage.user_rest, "lanceur rendu à sa place")
	assert_eq(_target.position, stage.target_rest, "cible rendue à sa place")
	assert_eq(_user.scale, Vector2(2.0, 2.0), "échelle du lanceur rendue")
	assert_eq(_user.modulate, Color.WHITE, "teinte du lanceur rendue")
	assert_eq(_target.modulate, Color.WHITE, "teinte de la cible rendue")
	assert_true(_player.camera.is_at_rest(), "caméra au repos")
	assert_eq(_layer.scale, Vector2.ONE, "calque sans zoom")
	assert_eq(_layer.offset, Vector2.ZERO, "calque sans décalage")
	assert_false(_player.get_light().is_lit(), "lumière éteinte")
	assert_eq(_decor.modulate, Color(0.9, 0.95, 1.0, 1.0), "décor rendu à sa teinte de repos")
	assert_false(_player.get_projectile().visible, "projectile caché")
	assert_false(_player.get_bolt().visible, "arc caché")


func test_instant_plays_all_cues_in_order_and_rests() -> void:
	for move_id: StringName in [&"tackle", &"thunder_shock", &"ember", &"growl",
			&"swords_dance", &"recover", &"water_gun", &"ice_beam"]:
		_cues.clear()
		var plan := _plan(move_id)
		var stage := _stage()
		_player.speed_scale = 0.0
		await _player.play(plan, stage)
		assert_eq(_cues, plan.cue_names(), "%s : tous les repères, dans l'ordre" % move_id)
		_assert_at_rest(stage)


func test_cues_fire_at_plan_times() -> void:
	for move_id: StringName in [&"tackle", &"thunder_shock", &"ember"]:
		_cues.clear()
		_cue_times.clear()
		_clock = 0.0
		var plan := _plan(move_id)
		_step_through(plan, _stage(), 0.01)
		assert_eq(_cues, plan.cue_names(), "%s : repères" % move_id)
		for i: int in plan.cues.size():
			assert_almost_eq(_cue_times[i], plan.cues[i].time, 0.011,
				"%s : « %s » à l'heure du plan" % [move_id, plan.cues[i].cue])


func test_launch_before_impact() -> void:
	var plan := _plan(&"thunder_shock")
	_step_through(plan, _stage(), 0.01)
	var launch := _cues.find(MoveFxPlan.CUE_LAUNCH)
	var impact := _cues.find(MoveFxPlan.CUE_IMPACT)
	assert_true(launch >= 0 and impact > launch, "le son de l'attaque part avant celui du coup")
	assert_true(_cue_times[impact] > _cue_times[launch], "après le trajet")


func test_multi_hit_cue_per_hit() -> void:
	var plan := _plan(&"double_slap", MoveFxPlan.Mode.FULL,
		_outcome(MoveFxOutcome.Result.HIT, 3))
	var stage := _stage()
	_player.speed_scale = 0.0
	await _player.play(plan, stage)
	assert_eq(_cues.count(MoveFxPlan.CUE_IMPACT), 1)
	assert_true(_cues.has(&"impact_2") and _cues.has(&"impact_3"), "un repère par coup")
	_assert_at_rest(stage)


func test_stepped_play_ends_at_rest() -> void:
	var stage := _stage()
	_step_through(_plan(&"tackle"), stage)
	_assert_at_rest(stage)


func test_camera_zooms_within_cap_full_mode() -> void:
	var plan := _plan(&"thunder_shock")
	var zooms := _step_through(plan, _stage())
	var peak := 1.0
	for zoom: float in zooms:
		peak = maxf(peak, zoom)
	assert_gt(peak, 1.0, "la caméra zoome à l'impact")
	assert_true(peak <= plan.camera_zoom + EPS, "pas plus que le plan")
	assert_true(peak <= JsonFields.get_float(_catalog.limits(), "zoom_max") + EPS, "plafond CV-3")


func test_reduced_mode_never_moves_camera() -> void:
	for move_id: StringName in [&"tackle", &"thunder_shock", &"ember"]:
		var zooms := _step_through(_plan(move_id, MoveFxPlan.Mode.REDUCED), _stage())
		for zoom: float in zooms:
			assert_almost_eq(zoom, 1.0, EPS, "%s : Réduites, aucun zoom" % move_id)
		assert_eq(_layer.offset, Vector2.ZERO)


func test_contact_dash_reaches_toward_target() -> void:
	var plan := _plan(&"tackle")
	var stage := _stage()
	_player.play(plan, stage)
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.start + impact.duration * 0.5)
	var moved := _user.position - stage.user_rest
	var toward := stage.target_rest - stage.user_rest
	assert_gt(moved.dot(toward.normalized()), 0.0, "le lanceur avance vers la cible")
	assert_true(moved.length() <= toward.length() * 0.36, "sur 25 à 35 % de la distance")
	assert_lt(_user.scale.x, 2.0, "ton Pokémon rétrécit en s'éloignant (profondeur)")
	_player.stop()
	_assert_at_rest(stage)


func test_bolt_shown_during_travel_with_fixed_ends() -> void:
	var plan := _plan(&"thunder_shock")
	plan.art.clear() # formes en code (repli sans art)
	var stage := _stage()
	_player.play(plan, stage)
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.start + 0.01)
	var bolt := _player.get_bolt()
	assert_true(bolt.visible, "l'arc électrique est là à l'impact")
	assert_eq(bolt.points[0], stage.origin(), "part de l'origine")
	assert_eq(bolt.points[bolt.points.size() - 1], stage.impact_point(), "arrive sur la cible")
	_player.stop()


func test_projectile_travels_for_fire() -> void:
	var plan := _plan(&"ember")
	plan.art.clear() # formes en code (repli sans art)
	var stage := _stage()
	_player.play(plan, stage)
	var travel := plan.phase(MoveFxPlan.TRAVEL)
	_player.pose(travel.start + travel.duration * 0.5)
	var projectile := _player.get_projectile()
	assert_true(projectile.visible, "un projectile part")
	var from := stage.origin()
	var to := stage.impact_point()
	assert_gt(projectile.position.distance_to(from), 1.0, "a quitté l'origine")
	assert_gt(projectile.position.distance_to(to), 1.0, "n'est pas encore arrivé")
	_player.stop()


func test_painted_bolt_stretches_from_origin_to_target_then_star_on_impact() -> void:
	# T7 : Éclair en art peint (arc tendu de l'origine à la cible, décharge en étoile à l'impact).
	var plan := _plan(&"thunder_shock")
	assert_eq(plan.art.get(&"bolt"), &"arc_electrique_a")
	assert_eq(plan.art.get(&"cheeks"), &"arc_electrique_b", "signature Éclair : les joues")
	var stage := _stage()
	_player.play(plan, stage)
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.start + 0.01)
	var arc := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(arc.visible, "l'arc peint est là à l'impact")
	assert_false(_player.get_bolt().visible, "l'art remplace la forme en code")
	assert_eq(arc.position, stage.origin(), "part de l'origine")
	var frame := arc.texture.get_width() / float(arc.hframes)
	assert_almost_eq(arc.scale.x * frame, stage.origin().distance_to(stage.impact_point()), 0.5,
		"arrive sur la cible")
	assert_true(_player.get_art(MoveFxPlayer.Flip.IMPACT).visible, "décharge en étoile")
	_player.stop()
	assert_false(arc.visible, "rangé à la fin")


func test_painted_fireball_travels_and_contact_stamps_its_variant() -> void:
	var plan := _plan(&"ember")
	var stage := _stage()
	_player.play(plan, stage)
	var travel := plan.phase(MoveFxPlan.TRAVEL)
	_player.pose(travel.start + travel.duration * 0.5)
	var ball := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(ball.visible, "la boule de feu peinte part")
	assert_gt(ball.position.distance_to(stage.origin()), 1.0)
	assert_gt(ball.position.distance_to(stage.impact_point()), 1.0)
	_player.stop()
	for case: Array in [[&"scratch", &"entailles_griffes"], [&"bite", &"machoires"],
			[&"tackle", &"onde_choc"]]:
		var contact := _plan(case[0])
		assert_eq(contact.art.get(&"stamp"), case[1], String(case[0]))
		_player.play(contact, stage)
		var hit := contact.phase(MoveFxPlan.IMPACT)
		_player.pose(hit.start + hit.duration * 0.2)
		assert_true(_player.get_art(MoveFxPlayer.Flip.IMPACT).visible, "marque peinte")
		_player.stop()


func test_every_art_id_of_the_data_exists() -> void:
	for move_id: StringName in _catalog.move_ids():
		if _data.get_move(move_id) == null:
			continue # attaque pas encore en données (annexe A)
		var plan := _plan(move_id)
		for role: StringName in plan.art:
			assert_true(FxArt.has(plan.art[role]), "%s : %s" % [move_id, plan.art[role]])


func test_miss_overshoots_target() -> void:
	var plan := _plan(&"ember", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.MISSED))
	var stage := _stage()
	_player.play(plan, stage)
	var miss := plan.phase(MoveFxPlan.MISS)
	assert_not_null(miss)
	_player.pose(miss.start + miss.duration * 0.5)
	assert_gt(_player.get_projectile().position.distance_to(stage.impact_point()), 20.0,
		"le projectile passe à côté")
	assert_eq(_target.position, stage.target_rest, "la cible ne bouge pas")
	_player.stop()


func test_light_respects_reduced_flash_cap() -> void:
	var plan := MoveFxPlan.build(_catalog, _catalog.entry(&"thunder_shock"),
		_data.get_move(&"thunder_shock"), null, MoveFxPlan.Mode.FULL, true)
	var stage := _stage()
	_player.play(plan, stage)
	var peak := 0.0
	var impact := plan.phase(MoveFxPlan.IMPACT)
	for i: int in 21:
		_player.pose(impact.start + impact.duration * i / 20.0)
		peak = maxf(peak, _player.get_light().get_amount())
	assert_gt(peak, 0.0, "la lumière monte")
	assert_true(peak <= JsonFields.get_float(_catalog.limits(), "reduced_flash_peak") + EPS,
		"plafond de « Réduire les flashs »")
	_player.stop()
	_assert_at_rest(stage)


func test_self_family_stays_on_user() -> void:
	var plan := _plan(&"swords_dance")
	var stage := _stage()
	_player.play(plan, stage)
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.start + impact.duration * 0.5)
	assert_eq(_target.position, stage.target_rest, "la cible n'est pas touchée")
	assert_false(_player.get_projectile().visible, "rien ne part vers l'adversaire")
	_player.stop()


## RP-286 : Groz'Yeux et Regard Médusant n'ont pas de trajet ; rien ne part du lanceur, même
## avant l'impact, et l'aura naît sur la cible. Jet de Sable garde son trajet.
func test_gaze_family_sends_nothing_toward_the_target() -> void:
	var stage := _stage()
	for move_id: StringName in [&"leer", &"glare"]:
		var plan := _plan(move_id)
		assert_null(plan.phase(MoveFxPlan.TRAVEL), "%s : pas de phase de trajet" % move_id)
		_player.play(plan, stage)
		for phase: MoveFxPlan.Phase in plan.phases:
			_player.pose(phase.start + phase.duration * 0.5)
			assert_false(_player.get_projectile().visible, "%s : rien ne part" % move_id)
			assert_false(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible,
				"%s : pas d'art de trajet (%s)" % [move_id, phase.name])
		var anticipation := plan.phase(MoveFxPlan.ANTICIPATION)
		_player.pose(anticipation.start + anticipation.duration * 0.5)
		var eye := _player.get_art(MoveFxPlayer.Flip.EXTRA_A)
		assert_true(eye.visible, "%s : le regard s'ouvre sur le lanceur" % move_id)
		assert_eq(eye.position, stage.origin(), "%s : sur le lanceur" % move_id)
		_player.stop()
		_assert_at_rest(stage)
	assert_not_null(_plan(&"sand_attack").phase(MoveFxPlan.TRAVEL), "Jet de Sable : trajet gardé")


## Jet de Sable (remarque de Kevin du 2026-11-02) : une gerbe de grains part vers la cible au
## début du trajet, aucun projectile rond ni art de trajet.
func test_sand_attack_sprays_grains_toward_the_target() -> void:
	var stage := _stage()
	var plan := _plan(&"sand_attack")
	_player.play(plan, stage)
	var travel := plan.phase(MoveFxPlan.TRAVEL)
	_player.advance(travel.start + 0.001)
	_player.pose(travel.start + travel.duration * 0.5)
	assert_false(_player.get_projectile().visible, "pas de boule")
	assert_false(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible, "pas de projectile peint")
	var spray: CPUParticles2D = null
	for emitter: CPUParticles2D in _player.get_pool().get_emitters():
		if emitter.visible and emitter.spread == FxParticlePool.SPRAY_SPREAD:
			spray = emitter
	assert_not_null(spray, "une gerbe en éventail")
	if spray != null:
		var toward := (stage.impact_point() - stage.origin()).normalized()
		assert_gt(spray.direction.dot(toward), 0.99, "vers la cible")
		assert_gte(spray.amount, 32, "nombreux grains")
		assert_eq(spray.texture, FxArt.particle(&"grain_sable").get("texture"), "grains peints")
	_player.stop()


## Vague 1 « Effets fidèles à Rouge » : rien ne part en lueur (ni projectile rond ni art de
## trajet) pour ces attaques, à aucun instant, et la scène revient au repos.
func test_rouge_wave_1_never_sends_a_glow() -> void:
	var stage := _stage()
	for move_id: StringName in [&"tail_whip", &"vine_whip", &"bubble", &"bubble_beam",
			&"string_shot", &"poison_sting", &"peck", &"drill_peck", &"sleep_powder",
			&"stun_spore", &"poison_powder", &"spore", &"leech_seed"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		for phase: MoveFxPlan.Phase in plan.phases:
			for part: float in [0.2, 0.5, 0.8]:
				_player.pose(phase.start + phase.duration * part)
				assert_false(_player.get_projectile().visible, "%s : pas de lueur" % move_id)
				assert_false(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible,
					"%s : pas d'art de trajet (%s)" % [move_id, phase.name])
		_player.stop()
		_assert_at_rest(stage)


## Mimi-Queue : plus d'œil ; le lanceur se dandine de côté (deux balancements et demi), puis
## revient à sa place.
func test_tail_whip_wags_the_user_without_an_eye() -> void:
	var stage := _stage()
	var plan := _plan(&"tail_whip")
	_player.play(plan, stage)
	var anticipation := plan.phase(MoveFxPlan.ANTICIPATION)
	var lefts := 0
	var rights := 0
	for i: int in 41:
		_player.pose(anticipation.start + anticipation.duration * i / 40.0)
		assert_false(_player.get_art(MoveFxPlayer.Flip.EXTRA_A).visible, "pas d'œil")
		var dx := _user.position.x - stage.user_rest.x
		assert_eq(_user.position.y, stage.user_rest.y, "de côté seulement")
		if dx < -2.0:
			lefts += 1
		elif dx > 2.0:
			rights += 1
	assert_gt(lefts, 0, "il se balance à gauche")
	assert_gt(rights, 0, "et à droite")
	_player.stop()
	_assert_at_rest(stage)


## Écume et Bulles d'O : plusieurs bulles peintes en vol en même temps, entre le lanceur et la
## cible ; Bulles d'O en montre plus.
func test_bubbles_float_toward_the_target_and_bubble_beam_sends_more() -> void:
	var stage := _stage()
	var peaks: Dictionary = {}
	for move_id: StringName in [&"bubble", &"bubble_beam"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		var travel := plan.phase(MoveFxPlan.TRAVEL)
		var peak := 0
		for i: int in 21:
			_player.pose(travel.start + travel.duration * i / 20.0)
			var shown := 0
			for index: int in MoveFxPlayer.VOLLEY_MAX:
				var piece := _player.get_piece(index)
				if piece.visible and piece.texture == FxArt.particle(&"bulle").get("texture"):
					shown += 1
					assert_between(piece.position.x, stage.origin().x - 80.0,
						stage.target_rect.end.x + 80.0, "%s : entre les deux" % move_id)
			peak = maxi(peak, shown)
		peaks[move_id] = peak
		assert_gte(peak, 3, "%s : une volée de bulles" % move_id)
		_player.stop()
	assert_gt(peaks[&"bubble_beam"], peaks[&"bubble"], "Bulles d'O : plus nombreuses")


## Dard-Venin : une aiguille peinte, pointe vers la cible, qui avance ; piqûre à l'impact.
func test_poison_sting_flies_a_needle_point_first() -> void:
	var stage := _stage()
	var plan := _plan(&"poison_sting")
	_player.play(plan, stage)
	var travel := plan.phase(MoveFxPlan.TRAVEL)
	_player.pose(travel.start + travel.duration * 0.3)
	var needle := _player.get_piece(0)
	assert_true(needle.visible, "l'aiguille vole")
	assert_eq(needle.texture, FxArt.particle(&"aiguille").get("texture"), "aiguille peinte")
	var first := needle.position
	var toward := (stage.impact_point() - stage.origin()).normalized()
	var point := Vector2.from_angle(needle.rotation + MoveFxPlayer.NEEDLE_POINT)
	assert_gt(point.dot(toward), 0.99, "pointe vers la cible")
	_player.pose(travel.start + travel.duration * 0.8)
	assert_gt((needle.position - first).dot(toward), 0.0, "elle avance")
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.start + impact.duration * 0.1)
	assert_true(_player.get_piece(1).visible, "piqûre")
	_player.stop()


## Sécrétion : des fils tendus du lanceur à la cible, puis des tours de fil autour d'elle.
func test_string_shot_stretches_threads_then_wraps_the_target() -> void:
	var stage := _stage()
	var plan := _plan(&"string_shot")
	_player.play(plan, stage)
	var travel := plan.phase(MoveFxPlan.TRAVEL)
	_player.pose(travel.end() - 0.001)
	for i: int in MoveFxPlayer.THREAD_COUNT:
		var thread := _player.get_thread(i)
		assert_true(thread.visible, "fil %d tendu" % i)
		assert_almost_eq(thread.points[0], stage.origin(), Vector2.ONE, "part du lanceur")
		assert_true(stage.target_rect.grow(20.0).has_point(thread.points[-1]), "jusqu'à la cible")
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.end() - 0.001)
	for i: int in MoveFxPlayer.THREAD_COUNT:
		var wrap := _player.get_thread(MoveFxPlayer.THREAD_COUNT + i)
		assert_true(wrap.visible, "tour de fil %d" % i)
		for point: Vector2 in wrap.points:
			assert_true(stage.target_rect.grow(stage.target_rect.size.x * 0.1).has_point(point),
				"autour de la cible")
	_player.stop()


## Fouet Lianes : une liane tendue du lanceur à la cible, qui frappe deux fois (la cible encaisse
## au début de chaque temps).
func test_vine_whip_lashes_twice() -> void:
	var stage := _stage()
	var plan := _plan(&"vine_whip")
	assert_eq(plan.beats, 2, "deux claquements")
	_player.play(plan, stage)
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.start)
	var whip := _player.get_whip()
	assert_true(whip.visible, "la liane est tendue")
	assert_almost_eq(whip.points[0], stage.origin(), Vector2.ONE, "depuis le lanceur")
	assert_almost_eq(whip.points[-1], stage.impact_point(), Vector2.ONE * 2.0, "jusqu'à la cible")
	var first := _target.modulate
	_player.pose(impact.start + impact.duration * 0.25)
	assert_true(whip.points[whip.points.size() / 2].y < stage.origin().lerp(stage.impact_point(),
		0.5).y, "elle se relève entre les deux coups")
	_player.pose(impact.start + impact.duration * 0.5 + 0.001)
	assert_eq(_target.modulate, first, "second claquement : la cible encaisse à nouveau")
	_player.stop()
	_assert_at_rest(stage)


## Poudres : une pluie de grains part d'au-dessus de la cible, vers le bas, de la couleur de la
## poudre.
func test_powders_fall_from_above_in_their_color() -> void:
	var stage := _stage()
	var colors: Dictionary = {}
	for move_id: StringName in [&"sleep_powder", &"stun_spore", &"poison_powder", &"spore"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		var travel := plan.phase(MoveFxPlan.TRAVEL)
		_player.advance(travel.start + 0.001)
		var rain: CPUParticles2D = null
		for emitter: CPUParticles2D in _player.get_pool().get_emitters():
			if emitter.visible and emitter.emission_shape == CPUParticles2D.EMISSION_SHAPE_RECTANGLE \
					and emitter.material.blend_mode == CanvasItemMaterial.BLEND_MODE_MIX:
				rain = emitter
		assert_not_null(rain, "%s : pluie de poudre" % move_id)
		if rain != null:
			assert_lt(rain.position.y - rain.emission_rect_extents.y, stage.target_rect.position.y,
				"%s : d'en haut" % move_id)
			assert_true(stage.target_rect.has_point(rain.position + Vector2(0.0,
				rain.emission_rect_extents.y)), "%s : jusque sur la cible" % move_id)
			assert_eq(rain.direction, Vector2.DOWN, "%s : vers le bas" % move_id)
			colors[move_id] = plan.palette[1]
		_player.stop()
	assert_eq(_plan(&"spore").art.get(&"powder"), &"spore", "Spore : grains peints")
	var unique: Dictionary = {}
	for move_id: StringName in colors:
		unique[colors[move_id]] = true
	assert_eq(unique.size(), 4, "une couleur par poudre")


## Vampigraine : des graines en arc (au-dessus de la ligne droite), puis des pousses sur la cible.
func test_leech_seed_arcs_seeds_that_sprout() -> void:
	var stage := _stage()
	var plan := _plan(&"leech_seed")
	_player.play(plan, stage)
	var travel := plan.phase(MoveFxPlan.TRAVEL)
	_player.pose(travel.start + travel.duration * 0.45)
	var seed_piece := _player.get_piece(0)
	assert_true(seed_piece.visible, "une graine vole")
	var straight_y := stage.origin().lerp(stage.impact_point(), 0.5).y
	assert_lt(seed_piece.position.y, straight_y, "en arc")
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.end() - 0.001)
	var sprout := _player.get_piece(plan.volley_count)
	assert_true(sprout.visible, "une pousse sort")
	assert_eq(sprout.texture, FxArt.particle(&"liane").get("texture"), "pousse peinte")
	assert_true(stage.target_rect.grow(40.0).has_point(sprout.position), "sur la cible")
	_player.stop()


## Picpic : deux marques rapides à deux endroits de la cible ; Bec Vrille : la marque tourne.
func test_peck_marks_twice_and_drill_peck_spins() -> void:
	var stage := _stage()
	var plan := _plan(&"peck")
	assert_eq(plan.beats, 2, "deux coups de bec")
	_player.play(plan, stage)
	var impact := plan.phase(MoveFxPlan.IMPACT)
	var mark := _player.get_art(MoveFxPlayer.Flip.IMPACT)
	_player.pose(impact.start + impact.duration * 0.1)
	assert_true(mark.visible, "premier coup")
	var first := mark.position
	_player.pose(impact.start + impact.duration * 0.6)
	assert_true(mark.visible, "second coup")
	assert_gt(mark.position.distance_to(first), 10.0, "à un autre endroit")
	_player.stop()
	plan = _plan(&"drill_peck")
	_player.play(plan, stage)
	impact = plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.start + impact.duration * 0.1)
	var angle := mark.rotation
	_player.pose(impact.start + impact.duration * 0.3)
	assert_ne(mark.rotation, angle, "la marque tourne")
	assert_true(_player.get_art(MoveFxPlayer.Flip.EXTRA_A).visible, "éclats en spirale")
	_player.stop()
	_assert_at_rest(stage)


# --- Caméra ----------------------------------------------------------------------------

func test_camera_zoom_keeps_pivot_fixed() -> void:
	var pivot := Vector2(1400, 400)
	var offset := BattleCamera.layer_offset(pivot, 1.05)
	assert_almost_eq((pivot * 1.05 + offset).distance_to(pivot), 0.0, 0.01,
		"le point d'impact ne bouge pas quand on zoome")


func test_camera_shake_bounded_and_ends_still() -> void:
	for i: int in 60:
		var shake := BattleCamera.shake_at(i / 100.0, 6.0, 0.6)
		assert_true(shake.length() <= 6.0 + EPS, "jamais plus que l'amplitude")
	assert_eq(BattleCamera.shake_at(0.6, 6.0, 0.6), Vector2.ZERO, "immobile à la fin")
	assert_eq(BattleCamera.shake_at(0.2, 0.0, 0.6), Vector2.ZERO, "aucun tremblement demandé")


func test_camera_safety_caps() -> void:
	var camera := BattleCamera.new(_layer)
	camera.set_pose(2.0, Vector2.ZERO, Vector2(50, 0))
	assert_almost_eq(camera.get_zoom(), BattleCamera.ZOOM_MAX, EPS)
	assert_almost_eq(camera.get_shake().length(), BattleCamera.SHAKE_MAX, EPS)
	camera.reset()
	assert_true(camera.is_at_rest())


# --- Arc électrique --------------------------------------------------------------------

func test_bolt_points_deterministic() -> void:
	var a := MoveFxPlayer.bolt_points(Vector2.ZERO, Vector2(800, -400), 9, 30.0, 7)
	var b := MoveFxPlayer.bolt_points(Vector2.ZERO, Vector2(800, -400), 9, 30.0, 7)
	var c := MoveFxPlayer.bolt_points(Vector2.ZERO, Vector2(800, -400), 9, 30.0, 8)
	assert_eq(a, b, "même graine, même arc")
	assert_ne(a, c, "autre graine, autre arc")
	assert_eq(a.size(), 10)
	assert_eq(a[0], Vector2.ZERO)
	assert_eq(a[9], Vector2(800, -400))


# --- Particules ------------------------------------------------------------------------

func test_particle_pool_budget() -> void:
	var pool := _player.get_pool()
	pool.speed_scale = 1.0
	assert_eq(pool.get_emitters().size(), FxParticlePool.SIZE, "émetteurs créés d'avance")
	for i: int in 8:
		var emitter := pool.burst(Vector2(100, 100), 500, PackedColorArray([Color.WHITE]))
		if emitter != null:
			assert_true(emitter.amount <= FxParticlePool.MAX_PER_EMITTER, "≤ 64 par émetteur")
	assert_true(pool.active_particles() <= FxParticlePool.MAX_ON_SCREEN, "≤ 200 à l'écran")
	assert_eq(pool.get_emitters().size(), FxParticlePool.SIZE, "aucun émetteur créé en jeu")
	pool.clear()
	assert_eq(pool.active_particles(), 0)


func test_particle_ramp_fades_out() -> void:
	var ramp := FxParticlePool.ramp(PackedColorArray([Color.WHITE, Color.ORANGE, Color.DARK_RED]))
	assert_eq(ramp.get_point_count(), 4)
	assert_almost_eq(ramp.sample(1.0).a, 0.0, EPS, "la particule finit en fondu")
	assert_eq(ramp.sample(0.0), Color.WHITE, "cœur presque blanc")


func test_plan_palette_and_particles_from_data() -> void:
	var full := _plan(&"ember")
	assert_eq(full.palette.size(), 3, "dégradé de la famille")
	assert_gt(full.particles, 0)
	var reduced := _plan(&"ember", MoveFxPlan.Mode.REDUCED)
	assert_eq(reduced.particles, roundi(full.particles * 0.5), "moitié en Réduites")
	for family: StringName in _catalog.family_ids():
		var fx := JsonFields.get_dict(_catalog.family(family), "fx")
		assert_true(JsonFields.get_int(fx, "particles") <= FxParticlePool.MAX_PER_EMITTER,
			"%s : un éclat tient dans un émetteur" % family)
		assert_eq(JsonFields.get_array(fx, "palette").size(), 3, "%s : palette" % family)


## Le jet d'eau (Pistolet à O) est nettement plus épais qu'un rayon, avec cœur et halo.
## Formes en code (repli sans art) : jets et rayons épais, avec halo (vidéos CV.3 et CV.1).
func test_water_jet_is_much_thicker_than_a_beam() -> void:
	var stage := _stage()
	for move_id: StringName in [&"water_gun", &"ice_beam", &"hyper_beam"]:
		var plan := _plan(move_id)
		plan.art.erase(&"bolt")
		_player.play(plan, stage)
		var peak := 0.0
		var halo_seen := false
		var guard := 0
		while _player.is_playing() and guard < 1000:
			_clock += 1.0 / 60.0
			_player.advance(1.0 / 60.0)
			var beam := _player.get_beam()
			if beam.visible:
				peak = maxf(peak, beam.width)
				halo_seen = halo_seen or (beam.get_node(^"Halo") as Line2D).visible
			guard += 1
		assert_gte(peak, MoveFxPlayer.JET_WIDTH * 0.9, "%s : épais" % move_id)
		assert_true(halo_seen, "%s : halo" % move_id)
	_assert_at_rest(stage)
