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
	assert_eq(plan.art.get(&"bolt"), &"eclair_fin")
	assert_eq(plan.art.get(&"cheeks"), &"arc_joue", "signature Éclair : les joues")
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
## cible ; Bulles d'O en envoie plus (refonte Eau : Écume, moins de bulles mais plus grandes).
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
				if piece.visible and piece.texture == FxArt.particle(plan.art.get(&"piece")).get("texture"):
					shown += 1
					assert_between(piece.position.x, stage.origin().x - 80.0,
						stage.target_rect.end.x + 80.0, "%s : entre les deux" % move_id)
			peak = maxi(peak, shown)
		peaks[move_id] = peak
		assert_gte(peak, 3, "%s : une volée de bulles" % move_id)
		_player.stop()
	assert_gt(_plan(&"bubble_beam").volley_count, _plan(&"bubble").volley_count, "Bulles d'O : plus nombreuses")


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
## au début de chaque temps). Refonte Plante : la liane est peinte (deux lianes torsadées).
func test_vine_whip_lashes_twice() -> void:
	var stage := _stage()
	var plan := _plan(&"vine_whip")
	assert_eq(plan.beats, 2, "deux claquements")
	assert_eq(plan.art.get(&"vine"), &"liane_fouet", "liane peinte")
	_player.play(plan, stage)
	var impact := plan.phase(MoveFxPlan.IMPACT)
	_player.pose(impact.start)
	var vine := _player.get_art(MoveFxPlayer.Flip.EXTRA_A)
	assert_true(vine.visible, "la liane est tendue")
	assert_false(_player.get_whip().visible, "plus de liane dessinée en code")
	assert_almost_eq(vine.position, stage.origin(), Vector2.ONE, "depuis le lanceur")
	var reach := vine.scale.x * float(FxArt.flipbook(&"liane_fouet")["size"])
	assert_almost_eq(reach, stage.origin().distance_to(stage.impact_point()), 2.0, "jusqu'à la cible")
	var rest_angle := vine.rotation
	var first := _target.modulate
	_player.pose(impact.start + impact.duration * 0.25)
	assert_lt(vine.rotation, rest_angle - 0.05, "elle se relève entre les deux coups")
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
	assert_eq(sprout.texture, FxArt.particle(&"feuille_double").get("texture"), "pousse peinte")
	assert_eq(seed_piece.texture, FxArt.particle(&"graine_vampi").get("texture"), "graine peinte")
	assert_true(_player.get_art(MoveFxPlayer.Flip.IMPACT).visible, "les lianes enserrent la cible")
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


# --- Vague 2 « Effets fidèles à Rouge » (2026-11-04) -------------------------------------

func _visible_pieces() -> int:
	var count := 0
	for i: int in MoveFxPlayer.VOLLEY_MAX:
		count += 1 if _player.get_piece(i).visible else 0
	return count


func _pose_at(plan: MoveFxPlan, phase_name: StringName, share: float, hit: int = 0) -> void:
	var phase := plan.phase(phase_name, hit)
	assert_not_null(phase, "%s : phase %s" % [plan.move_id, phase_name])
	if phase != null:
		_player.pose(phase.start + phase.duration * share)


## Aucune attaque de la vague 2 n'envoie la lueur ronde par défaut ni le rayon d'énergie.
func test_rouge_wave_2_never_sends_a_glow_or_a_beam() -> void:
	var stage := _stage()
	for move_id: StringName in [&"twineedle", &"pin_missile", &"spike_cannon", &"rock_throw",
			&"rock_slide", &"teleport", &"splash", &"explosion", &"self_destruct", &"pay_day",
			&"smokescreen", &"poison_gas", &"smog", &"flash", &"kinesis", &"swift", &"thunder",
			&"fire_punch", &"ice_punch", &"thunder_punch", &"lick", &"bone_club", &"bonemerang",
			&"confuse_ray", &"haze", &"clamp", &"crabhammer", &"waterfall", &"egg_bomb", &"barrage",
			&"seismic_toss", &"fissure", &"dig"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		for phase: MoveFxPlan.Phase in plan.phases:
			for part: float in [0.2, 0.5, 0.8]:
				_player.pose(phase.start + phase.duration * part)
				assert_false(_player.get_projectile().visible, "%s : pas de lueur" % move_id)
				assert_false(_player.get_beam().visible, "%s : pas de rayon" % move_id)
		_player.stop()
		_assert_at_rest(stage)


## Double-Dard : deux aiguilles peintes côte à côte ; Dard-Nuée : trois ; à chaque coup, sans
## que le lanceur ne fonce.
func test_needle_volleys_fly_side_by_side_each_hit() -> void:
	var stage := _stage()
	for pair: Array in [[&"twineedle", 2], [&"pin_missile", 3]]:
		var plan := _plan(pair[0], MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.HIT, 2))
		_player.play(plan, stage)
		for hit: int in 2:
			_pose_at(plan, MoveFxPlan.TRAVEL, 0.95, hit)
			var needles := 0
			for i: int in pair[1]:
				needles += 1 if _player.get_piece(3 * i).visible else 0
			assert_eq(needles, pair[1], "%s : %d aiguilles au coup %d" % [pair[0], pair[1], hit])
			assert_eq(_user.position, stage.user_rest, "%s : le lanceur reste à sa place" % pair[0])
		_player.stop()


## Jet-Pierres, Éboulement : les pierres tombent d'en haut sur la cible ; Éboulement en fait
## tomber plus, et plus grosses.
func test_rocks_fall_from_above_and_rock_slide_drops_more() -> void:
	var stage := _stage()
	var counts: Array[int] = []
	for move_id: StringName in [&"rock_throw", &"rock_slide"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_at(plan, MoveFxPlan.TRAVEL, 0.3)
		var rock := _player.get_piece(0)
		assert_true(rock.visible, "%s : la première pierre tombe" % move_id)
		var high := rock.position.y
		assert_lt(high, stage.target_rect.position.y, "%s : au-dessus de la cible" % move_id)
		_pose_at(plan, MoveFxPlan.TRAVEL, 0.9)
		assert_gt(rock.position.y, high, "%s : elle descend" % move_id)
		assert_lt(absf(rock.position.x - stage.impact_point().x), stage.target_rect.size.x,
			"%s : à la verticale de la cible" % move_id)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.95)
		counts.append(plan.volley_count)
		_player.stop()
		_assert_at_rest(stage)
	assert_gt(counts[1], counts[0], "Éboulement : plus de rochers")


## Téléport : le lanceur se resserre en un trait et file vers le haut ; réussi, il reste caché à
## la fin ; sinon il revient à sa place.
func test_teleport_zips_up_and_stays_gone_when_teleported() -> void:
	var stage := _stage()
	var gone := _outcome(MoveFxOutcome.Result.AFFECTED)
	gone.vanished = true
	var plan := _plan(&"teleport", MoveFxPlan.Mode.FULL, gone)
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.9)
	assert_lt(_user.scale.x, 0.5, "un trait")
	assert_lt(_user.position.y, stage.user_rest.y - 200.0, "il file vers le haut")
	_player.stop()
	assert_eq(_user.modulate.a, 0.0, "il ne revient pas")
	_user.modulate = Color.WHITE
	var stays := _plan(&"teleport", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.AFFECTED))
	_player.play(stays, stage)
	_player.stop()
	_assert_at_rest(stage)


## Trempette : il saute sur place (même quand « rien ne se passe »), rien ne part vers la cible.
func test_splash_hops_in_place_and_sends_nothing() -> void:
	var stage := _stage()
	var plan := _plan(&"splash", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.FAILED))
	_player.play(plan, stage)
	var highest := 0.0
	var anticipation := plan.phase(MoveFxPlan.ANTICIPATION)
	for i: int in 21:
		_player.pose(anticipation.start + anticipation.duration * i / 20.0)
		highest = maxf(highest, stage.user_rest.y - _user.position.y)
		assert_eq(_target.position, stage.target_rest, "la cible ne bouge pas")
		assert_eq(_visible_pieces(), 0, "rien ne part")
	assert_gt(highest, 40.0, "il saute")
	_player.stop()
	_assert_at_rest(stage)


## Explosion : le lanceur gonfle, puis plusieurs explosions peintes éclatent sur la cible (plus
## que pour Destruction), avec un éclair blanc plafonné par « Réduire les flashs ».
func test_explosions_burst_one_after_another_without_a_beam() -> void:
	var stage := _stage()
	var shown: Array[int] = []
	for move_id: StringName in [&"explosion", &"self_destruct"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_at(plan, MoveFxPlan.ANTICIPATION, 0.9)
		assert_gt(_user.scale.x, 2.0, "%s : il gonfle" % move_id)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.05)
		assert_true(_player.get_screen().visible, "%s : éclair blanc" % move_id)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.95)
		var count := 0
		for role: MoveFxPlayer.Flip in [MoveFxPlayer.Flip.IMPACT, MoveFxPlayer.Flip.EXTRA_A,
				MoveFxPlayer.Flip.EXTRA_B, MoveFxPlayer.Flip.WAVE_A, MoveFxPlayer.Flip.WAVE_B]:
			count += 1 if _player.get_art(role).visible else 0
		shown.append(count)
		assert_gt(count, 1, "%s : plusieurs explosions à la fois" % move_id)
		_player.stop()
		_assert_at_rest(stage)
	assert_gte(shown[0], shown[1], "Explosion : au moins autant que Destruction")
	var capped := MoveFxPlan.build(_catalog, _catalog.entry(&"explosion"),
		_data.get_move(&"explosion"), null, MoveFxPlan.Mode.FULL, true)
	_player.play(capped, stage)
	_pose_at(capped, MoveFxPlan.IMPACT, 0.02)
	assert_lte(_player.get_screen().color.a, 0.35 + EPS, "éclair plafonné")
	_player.stop()


## Flash : l'écran entier flashe en blanc (deux fois), la cible ne tremble pas.
func test_flash_whitens_the_whole_screen_and_never_shakes_the_target() -> void:
	var stage := _stage()
	var plan := _plan(&"flash")
	_player.play(plan, stage)
	var impact := plan.phase(MoveFxPlan.IMPACT)
	var peaks := 0
	var last := 0.0
	var rising := false
	for i: int in 41:
		_player.pose(impact.start + impact.duration * i / 40.0)
		var a := _player.get_screen().color.a if _player.get_screen().visible else 0.0
		if a < last and rising:
			peaks += 1
		rising = a > last
		last = a
		assert_eq(_target.position, stage.target_rest, "la cible ne tremble pas")
	assert_eq(peaks, 2, "deux éclairs blancs")
	_player.stop()
	_assert_at_rest(stage)


## Fatal-Foudre : la scène s'assombrit, puis la foudre tombe du haut de l'écran sur la cible.
func test_thunder_falls_from_the_sky() -> void:
	var stage := _stage()
	var plan := _plan(&"thunder")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.ANTICIPATION, 0.9)
	assert_true(_player.get_light().is_lit(), "la scène s'assombrit")
	assert_ne(_decor.modulate, Color(0.9, 0.95, 1.0, 1.0), "le décor change")
	_pose_at(plan, MoveFxPlan.IMPACT, 0.1)
	var bolt := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(bolt.visible, "la foudre")
	var top := bolt.position.y - bolt.scale.y * bolt.texture.get_height() / bolt.vframes * 0.5
	assert_lt(top, 0.0, "elle part du haut de l'écran")
	assert_almost_eq(bolt.position.x, stage.impact_point().x, 60.0, "à la verticale de la cible")
	assert_eq(bolt.rotation, 0.0, "verticale")
	_player.stop()
	_assert_at_rest(stage)


## Poings : course de Contact, poing peint sur la cible, lumière de l'élément.
func test_elemental_punches_hit_with_a_fist_then_their_element() -> void:
	var stage := _stage()
	for move_id: StringName in [&"fire_punch", &"ice_punch", &"thunder_punch"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_at(plan, MoveFxPlan.TRAVEL, 0.9)
		assert_gt(_user.position.distance_to(stage.user_rest), 40.0, "%s : il fonce" % move_id)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.3)
		var fist := _player.get_art(MoveFxPlayer.Flip.IMPACT)
		assert_true(fist.visible, "%s : le poing" % move_id)
		# Poing-Éclair (refonte Électrik) : pas de poing dessiné, un point de choc au contact.
		# Poing-Éclair et Poing de Feu (refontes Électrik et Feu) : pas de poing dessiné.
		var stamps := {&"thunder_punch": &"etoile_contact", &"fire_punch": &"contact_flamme"}
		var stamp: StringName = stamps.get(move_id, &"poing")
		assert_eq(fist.texture, FxArt.particle(stamp).get("texture"), "%s : marque peinte" % move_id)
		assert_true(_player.get_light().is_lit(), "%s : la lumière de l'élément" % move_id)
		_player.stop()
		_assert_at_rest(stage)


## Refonte Électrik : chaque attaque se reconnaît à sa forme.
func test_thunderbolt_is_a_braided_current_from_the_user() -> void:
	var stage := _stage()
	var plan := _plan(&"thunderbolt")
	assert_eq(plan.art.get(&"bolt"), &"courant_tresse")
	assert_false(plan.art.has(&"bolt_sky"), "jamais du ciel : c'est Fatal-Foudre")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.1)
	var current := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(current.visible, "le courant")
	assert_eq(current.position, stage.origin(), "part du lanceur")
	var frame := current.texture.get_width() / float(current.hframes)
	assert_almost_eq(current.scale.x * frame, stage.origin().distance_to(stage.impact_point()), 0.5,
		"atteint la cible")
	_player.stop()
	_assert_at_rest(stage)


func test_thunder_wave_cages_the_target_without_a_strike() -> void:
	var stage := _stage()
	var plan := _plan(&"thunder_wave")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
	var cage := _player.get_art(MoveFxPlayer.Flip.IMPACT)
	assert_true(cage.visible, "la cage")
	assert_eq(cage.position, stage.impact_point(), "autour de la cible")
	assert_false(_player.get_bolt().visible, "pas de trait")
	assert_false(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible, "pas de trait peint")
	_player.stop()
	_assert_at_rest(stage)


func test_spark_covers_the_charging_user_with_lightning() -> void:
	var stage := _stage()
	var plan := _plan(&"spark")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.9)
	assert_gt(_user.position.distance_to(stage.user_rest), 40.0, "il charge")
	assert_true(_player.get_art(MoveFxPlayer.Flip.AURA).visible, "corps couvert d'électricité")
	assert_true(_player.get_art(MoveFxPlayer.Flip.TRAIL).visible, "traînée de foudre")
	_player.stop()
	_assert_at_rest(stage)


func test_zap_cannon_orb_swells_travels_and_explodes() -> void:
	var stage := _stage()
	var plan := _plan(&"zap_cannon")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.ANTICIPATION, 0.9)
	var orb := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(orb.visible, "la sphère enfle devant le lanceur")
	var near_user := orb.position.distance_to(stage.origin())
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.9)
	assert_lt(orb.position.distance_to(stage.impact_point()), near_user, "elle va vers la cible")
	_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
	assert_true(_player.get_art(MoveFxPlayer.Flip.IMPACT).visible, "elle explose")
	_player.stop()
	_assert_at_rest(stage)


## Refonte Feu : chaque attaque se reconnaît à sa forme.
func test_ember_is_smaller_than_fire_blast() -> void:
	var ember := _plan(&"ember")
	var blast := _plan(&"fire_blast")
	assert_eq(ember.art.get(&"travel"), &"flammeches")
	assert_eq(blast.art.get(&"travel"), &"etoile_feu")
	assert_lt(ember.travel_scale, blast.travel_scale, "Flammèche la plus petite")
	assert_lt(ember.impact_size, blast.impact_size)


func test_flamethrower_is_a_continuous_jet_from_the_user() -> void:
	var stage := _stage()
	var plan := _plan(&"flamethrower")
	assert_eq(plan.art.get(&"bolt"), &"fleuve_flammes")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.1)
	var jet := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(jet.visible, "le jet")
	assert_eq(jet.position, stage.origin(), "part du lanceur")
	var frame := jet.texture.get_width() / float(jet.hframes)
	assert_almost_eq(jet.scale.x * frame, stage.origin().distance_to(stage.impact_point()), 0.5,
		"atteint la cible")
	_player.stop()
	_assert_at_rest(stage)


func test_fire_spin_encircles_the_target_without_a_projectile() -> void:
	var stage := _stage()
	var plan := _plan(&"fire_spin")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
	var vortex := _player.get_art(MoveFxPlayer.Flip.IMPACT)
	assert_true(vortex.visible, "le tourbillon")
	assert_eq(vortex.position, stage.impact_point(), "autour de la cible")
	assert_false(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible, "pas de projectile")
	_player.stop()
	_assert_at_rest(stage)


func test_flame_wheel_rolls_the_user_in_a_ring_of_fire() -> void:
	var stage := _stage()
	var plan := _plan(&"flame_wheel")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.9)
	assert_gt(_user.position.distance_to(stage.user_rest), 40.0, "il charge")
	assert_true(_player.get_art(MoveFxPlayer.Flip.AURA).visible, "la roue de feu")
	assert_true(_player.get_art(MoveFxPlayer.Flip.TRAIL).visible, "la traînée de flammes")
	_player.stop()
	_assert_at_rest(stage)


func test_sacred_fire_rises_from_the_ground_under_the_target() -> void:
	var stage := _stage()
	var plan := _plan(&"sacred_fire")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.3)
	var pillar := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(pillar.visible, "la colonne")
	var low := pillar.position.y
	_pose_at(plan, MoveFxPlan.IMPACT, 0.2)
	assert_lt(pillar.position.y, low, "elle monte")
	assert_almost_eq(pillar.position.x, stage.target_rect.get_center().x, 1.0, "sous la cible")
	_player.stop()
	_assert_at_rest(stage)


func test_sunny_day_lights_the_whole_field_not_the_target() -> void:
	var stage := _stage()
	var plan := _plan(&"sunny_day")
	assert_true(plan.on_self)
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
	var sun := _player.get_art(MoveFxPlayer.Flip.SKY)
	assert_true(sun.visible, "le soleil")
	assert_gt(sun.position.x, stage.view_size.x * 0.5, "dans le haut droit de l'écran")
	assert_false(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible, "rien ne part")
	_player.stop()
	_assert_at_rest(stage)


## Refonte Eau : chaque attaque se reconnaît à sa forme (Bulles d'O inchangée).
func test_water_gun_is_thin_and_hydro_pump_huge() -> void:
	var gun := _plan(&"water_gun")
	var pump := _plan(&"hydro_pump")
	assert_eq(gun.art.get(&"bolt"), &"jet_pistolet")
	assert_eq(pump.art.get(&"bolt"), &"torrent_spirale")
	assert_lt(gun.bolt_height * 3.0, pump.bolt_height, "Hydrocanon bien plus épais")
	assert_lt(gun.impact_size, pump.impact_size)
	assert_gt(pump.camera_shake, gun.camera_shake, "Hydrocanon secoue plus (signature)")
	assert_gt(_plan(&"crabhammer").camera_shake, _plan(&"tackle").camera_shake, "Pince-Masse secoue plus que Charge")


func test_surf_wave_sweeps_across_to_the_target() -> void:
	var stage := _stage()
	var plan := _plan(&"surf")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.1)
	var wave := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(wave.visible, "la vague")
	var early := wave.position.distance_to(stage.target_rect.get_center())
	_pose_at(plan, MoveFxPlan.IMPACT, 0.2)
	assert_lt(wave.position.distance_to(stage.target_rect.get_center()), early, "elle arrive sur la cible")
	_player.stop()
	_assert_at_rest(stage)


func test_withdraw_shells_the_user_only() -> void:
	var stage := _stage()
	var plan := _plan(&"withdraw")
	assert_true(plan.on_self)
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
	var shell := _player.get_art(MoveFxPlayer.Flip.AURA)
	assert_true(shell.visible, "la coque d'eau")
	# La coque suit le lanceur, qui se tasse un peu pendant sa posture.
	assert_almost_eq(shell.position, stage.user_rect.get_center(), Vector2.ONE * 20.0, "autour du lanceur")
	assert_false(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible, "rien ne part")
	_player.stop()
	_assert_at_rest(stage)


func test_rain_dance_covers_the_screen_with_rain() -> void:
	var stage := _stage()
	var plan := _plan(&"rain_dance")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
	var rain := _player.get_art(MoveFxPlayer.Flip.SKY)
	assert_true(rain.visible, "la pluie")
	# Quatre tuiles d'un quart d'écran ; la première dans le quart haut gauche.
	assert_almost_eq(rain.position, stage.view_size * 0.25, Vector2.ONE, "quart haut gauche")
	assert_true(_player.get_art(MoveFxPlayer.Flip.WAVE_C).visible, "jusqu'au quart bas droit")
	_player.stop()
	_assert_at_rest(stage)


## Météores : plusieurs étoiles en vol à la fois, chacune tournée dans son sens de vol.
func test_swift_stars_fly_head_first() -> void:
	var stage := _stage()
	var plan := _plan(&"swift")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.6)
	var flying := 0
	var toward := (stage.impact_point() - stage.origin()).normalized()
	for i: int in plan.volley_count:
		var star := _player.get_piece(i)
		if star.visible:
			flying += 1
			assert_gt(Vector2.from_angle(star.rotation).dot(toward), 0.5, "étoile %d vers la cible" % i)
	assert_gt(flying, 2, "un ruban d'étoiles")
	_player.stop()


## Osmerang : l'os part, frappe, puis revient vers le lanceur à chaque coup ; Massd'Os : il
## s'abat d'en haut sur la cible.
func test_bones_club_down_or_come_back() -> void:
	var stage := _stage()
	var plan := _plan(&"bonemerang", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.HIT, 2))
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.RETURN, 0.1)
	var near_target := _player.get_piece(0).position.distance_to(stage.impact_point())
	_pose_at(plan, MoveFxPlan.RETURN, 0.7)
	var bone := _player.get_piece(0)
	assert_true(bone.visible, "l'os revient")
	assert_gt(bone.position.distance_to(stage.impact_point()), near_target, "il s'éloigne de la cible")
	_player.stop()
	var club := _plan(&"bone_club")
	_player.play(club, stage)
	_pose_at(club, MoveFxPlan.IMPACT, 0.05)
	var before := _player.get_piece(0).position.y
	_pose_at(club, MoveFxPlan.IMPACT, 0.25)
	assert_gt(_player.get_piece(0).position.y, before, "il s'abat")
	assert_lt(before, stage.impact_point().y, "d'au-dessus de la cible")
	_player.stop()
	_assert_at_rest(stage)


## Brouillard : une boule de fumée en arc, puis la cible assombrie sous le nuage ; Gaz Toxik :
## des bouffées qui grossissent en chemin.
func test_smoke_and_gas_cover_the_target() -> void:
	var stage := _stage()
	var smoke := _plan(&"smokescreen")
	_player.play(smoke, stage)
	_pose_at(smoke, MoveFxPlan.TRAVEL, 0.5)
	var ball := _player.get_piece(0)
	assert_true(ball.visible, "la boule de fumée")
	assert_lt(ball.position.y, stage.origin().lerp(stage.impact_point(), 0.5).y, "en arc")
	_pose_at(smoke, MoveFxPlan.IMPACT, 0.6)
	assert_lt(_target.modulate.r, 0.9, "la cible s'assombrit")
	_player.stop()
	_assert_at_rest(stage)
	var gas := _plan(&"poison_gas")
	_player.play(gas, stage)
	_pose_at(gas, MoveFxPlan.TRAVEL, 0.2)
	var early := _player.get_piece(0).scale.x
	_pose_at(gas, MoveFxPlan.TRAVEL, 0.7)
	assert_gt(_player.get_piece(0).scale.x, early, "la bouffée gonfle")
	_player.stop()
	_assert_at_rest(stage)


## Frappe Atlas : la cible est soulevée, puis projetée au sol ; Abîme : elle s'enfonce dans la
## fissure ; Buée Noire : la brume traverse le terrain sans toucher à la cible.
func test_toss_fissure_and_haze_move_the_target_their_way() -> void:
	var stage := _stage()
	var toss := _plan(&"seismic_toss")
	_player.play(toss, stage)
	_pose_at(toss, MoveFxPlan.IMPACT, MoveFxPlayer.TOSS_SLAM * 0.5)
	assert_lt(_target.position.y, stage.target_rest.y - 100.0, "soulevée")
	_pose_at(toss, MoveFxPlan.IMPACT, 0.99)
	assert_almost_eq(_target.position.y, stage.target_rest.y, 1.0, "au sol")
	_player.stop()
	_assert_at_rest(stage)
	var fissure := _plan(&"fissure")
	_player.play(fissure, stage)
	_pose_at(fissure, MoveFxPlan.IMPACT, 0.5)
	assert_true(_player.get_art(MoveFxPlayer.Flip.IMPACT).visible, "la fissure")
	assert_gt(_target.position.y, stage.target_rest.y, "elle s'y enfonce")
	_player.stop()
	_assert_at_rest(stage)
	var haze := _plan(&"haze")
	_player.play(haze, stage)
	_pose_at(haze, MoveFxPlan.IMPACT, 0.5)
	assert_gt(_visible_pieces(), 2, "des nappes de brume")
	assert_eq(_target.position, stage.target_rest, "la cible ne bouge pas")
	_player.stop()
	_assert_at_rest(stage)


## Tunnel : au tour 1 il creuse sur place ; au tour 2, la traînée court sous le sol jusqu'à la
## cible, qui est soulevée.
func test_dig_burrows_then_erupts_under_the_target() -> void:
	var stage := _stage()
	var charge := _plan(&"dig", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.CHARGING))
	_player.play(charge, stage)
	_pose_at(charge, MoveFxPlan.CHARGE, 0.8)
	assert_gt(_user.position.y, stage.user_rest.y, "il creuse")
	_player.stop()
	var strike := _plan(&"dig")
	_player.play(strike, stage)
	_pose_at(strike, MoveFxPlan.TRAVEL, 0.5)
	assert_gt(_visible_pieces(), 2, "une traînée de terre")
	_pose_at(strike, MoveFxPlan.IMPACT, 0.3)
	assert_lt(_target.position.y, stage.target_rest.y, "le sol la soulève")
	_player.stop()
	_assert_at_rest(stage)


## Jackpot, Léchouille, Claquoir, Pince-Masse, Cascade : la marque peinte de la variante d'impact.
func test_contact_wave_2_stamps_their_own_art() -> void:
	var stage := _stage()
	for pair: Array in [[&"lick", &"langue"], [&"clamp", &"valve_eau"], [&"crabhammer", &"pince_eau"],
			[&"waterfall", &"chute_eau"], [&"pay_day", &"etoile_impact"]]:
		var plan := _plan(pair[0])
		_player.play(plan, stage)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.4)
		var stamp := _player.get_art(MoveFxPlayer.Flip.IMPACT)
		assert_true(stamp.visible, "%s : marque" % pair[0])
		var art := FxArt.particle(pair[1])
		if art.is_empty():
			art = FxArt.flipbook(pair[1])
		assert_eq(stamp.texture, art.get("texture"), "%s : %s" % pair)
		_player.stop()
		_assert_at_rest(stage)


## Refonte Psy (direction A, docs/tech/attaques-psy.md) : chaque attaque se reconnaît à sa forme.
func test_psychic_crushes_far_harder_than_confusion() -> void:
	var shock := _plan(&"confusion")
	var crush := _plan(&"psychic")
	assert_eq(String(shock.bricks.get("travel", "")), "", "Choc Mental : rien ne part du lanceur")
	assert_eq(shock.art.get(&"impact"), &"onde_choc_psy")
	assert_eq(crush.art.get(&"impact"), &"implosion_psy", "Psyko : la sphère qui écrase puis explose")
	assert_gt(crush.impact_size, shock.impact_size * 1.5, "Psyko bien plus gros")
	assert_gt(crush.camera_shake, shock.camera_shake, "Psyko secoue plus")


func test_psybeam_and_psywave_run_from_the_user_to_the_target() -> void:
	var stage := _stage()
	for pair: Array in [[&"psybeam", &"rayon_anneaux"], [&"psywave", &"onde_sinus"]]:
		var plan := _plan(pair[0])
		assert_eq(plan.art.get(&"bolt"), pair[1], "%s : son courant" % pair[0])
		_player.play(plan, stage)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.2)
		var beam := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
		assert_true(beam.visible, "%s : le courant" % pair[0])
		assert_almost_eq(beam.position, stage.origin(), Vector2.ONE, "%s : depuis le lanceur" % pair[0])
		_player.stop()
		_assert_at_rest(stage)


## Dévorêve, Yoga et Amnésie gardent leur effet d'avant la refonte (décision de Kevin du 2026-11-10).
func test_dream_eater_meditate_and_amnesia_keep_their_old_look() -> void:
	var dream := _plan(&"dream_eater")
	assert_eq(String(dream.bricks.get("travel", "")), "rings", "Dévorêve : les anneaux en série")
	assert_eq(dream.art.get(&"travel"), &"anneau_psy")
	assert_true(dream.has_modifier(&"drain"), "Dévorêve : le drain revient")
	for move_id: StringName in [&"meditate", &"amnesia"]:
		assert_eq(_catalog.entry(move_id).family, &"statut_plus", "%s : l'aura d'avant" % move_id)


func test_future_sight_opens_an_eye_then_drops_a_column() -> void:
	var stage := _stage()
	var plan := _plan(&"future_sight")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.ANTICIPATION, 0.8)
	var eye := _player.get_art(MoveFxPlayer.Flip.EXTRA_B)
	assert_true(eye.visible, "l'œil")
	assert_lt(eye.position.y, stage.user_rect.get_center().y, "au-dessus du lanceur")
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.6)
	var column := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(column.visible, "la colonne")
	assert_almost_eq(column.position.x, stage.target_rect.get_center().x, 1.0, "sur la cible")
	_player.stop()
	_assert_at_rest(stage)


func test_hypnosis_sends_rings_and_spins_spirals_on_the_target() -> void:
	var plan := _plan(&"hypnosis")
	assert_eq(String(plan.bricks.get("travel", "")), "rings")
	assert_eq(plan.art.get(&"travel"), &"anneau_hypnose")
	assert_eq(plan.art.get(&"impact"), &"spirale_hypnose")


func test_psychic_barriers_rise_in_front_of_the_user_and_differ() -> void:
	var stage := _stage()
	var walls: Dictionary = {}
	for move_id: StringName in [&"barrier", &"reflect", &"light_screen", &"mirror_coat"]:
		var plan := _plan(move_id)
		assert_true(plan.on_self, "%s : sur le lanceur" % move_id)
		walls[plan.art.get(&"wall")] = true
		_player.play(plan, stage)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
		var wall := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
		assert_true(wall.visible, "%s : la paroi" % move_id)
		assert_gt(wall.position.x, stage.user_rect.get_center().x, "%s : devant lui, côté adversaire" % move_id)
		_player.stop()
		_assert_at_rest(stage)
	assert_eq(walls.size(), 4, "quatre parois différentes")


func test_self_psychic_moves_glow_on_the_user_only() -> void:
	var stage := _stage()
	for pair: Array in [[&"agility", MoveFxPlayer.Flip.AURA], [&"rest", MoveFxPlayer.Flip.EXTRA_A]]:
		var plan := _plan(pair[0])
		assert_true(plan.on_self, "%s : sur le lanceur" % pair[0])
		_player.play(plan, stage)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
		var art := _player.get_art(pair[1])
		assert_true(art.visible, "%s : visible" % pair[0])
		assert_lt(absf(art.position.x - stage.user_rect.get_center().x), stage.user_rect.size.x * 0.5,
			"%s : sur le lanceur" % pair[0])
		if pair[1] == MoveFxPlayer.Flip.EXTRA_A:
			assert_lt(art.position.y, stage.user_rect.get_center().y, "%s : au-dessus de sa tête" % pair[0])
		_player.stop()
		_assert_at_rest(stage)


# --- Refonte Plante, direction A (2026-11-10, docs/tech/attaques-plante.md) ----------------

## Vol-Vie : la sève jaillit de la cible et un flot peint revient au lanceur ; Méga-Sangsue : flot
## plus épais et le lanceur s'illumine.
func test_absorb_siphons_sap_back_and_mega_drain_lights_the_user() -> void:
	var stage := _stage()
	var absorb := _plan(&"absorb")
	var mega := _plan(&"mega_drain")
	assert_gt(mega.bolt_height, absorb.bolt_height * 1.5, "Méga-Sangsue : flot plus épais")
	assert_gt(mega.impact_size, absorb.impact_size)
	_player.play(absorb, stage)
	_pose_at(absorb, MoveFxPlan.TRAVEL if absorb.phase(MoveFxPlan.TRAVEL) != null else MoveFxPlan.IMPACT, 0.2)
	assert_false(_player.get_projectile().visible, "rien ne part du lanceur")
	_pose_at(absorb, MoveFxPlan.RETURN, 0.3)
	var flow := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(flow.visible, "le flot de sève")
	assert_almost_eq(flow.position, stage.impact_point(), Vector2.ONE, "depuis la cible")
	assert_false(_player.get_art(MoveFxPlayer.Flip.AURA).visible, "Vol-Vie : pas d'aura")
	_player.stop()
	_player.play(mega, stage)
	_pose_at(mega, MoveFxPlan.ANTICIPATION, 0.8)
	assert_false(_player.get_art(MoveFxPlayer.Flip.AURA).visible, "pas d'aura avant le drain")
	_pose_at(mega, MoveFxPlan.RETURN, 0.3)
	assert_true(_player.get_art(MoveFxPlayer.Flip.AURA).visible, "le lanceur s'illumine")
	_player.stop()
	_assert_at_rest(stage)


## Tranch'Herbe : une volée de feuilles qui tournoient vers la cible.
func test_razor_leaf_sends_spinning_leaves() -> void:
	var stage := _stage()
	var plan := _plan(&"razor_leaf")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.6)
	assert_gte(_visible_pieces(), 4, "une volée")
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.5)
	var leaf := _player.get_piece(4)
	assert_true(leaf.visible, "une feuille en vol")
	assert_eq(leaf.texture, FxArt.particle(&"feuille_tranchante").get("texture"), "feuilles peintes")
	var spin := leaf.rotation
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.55)
	assert_ne(leaf.rotation, spin, "elle tournoie")
	_pose_at(plan, MoveFxPlan.IMPACT, 0.4)
	assert_true(_player.get_art(MoveFxPlayer.Flip.IMPACT).visible, "entailles")
	_player.stop()
	_assert_at_rest(stage)


## Danse Fleur : un tourbillon de pétales bien plus grand que la cage de Cage-Éclair.
func test_petal_dance_engulfs_the_target_in_a_huge_vortex() -> void:
	var stage := _stage()
	var sizes: Array[float] = []
	for move_id: StringName in [&"thunder_wave", &"petal_dance"]:
		var plan := _plan(move_id)
		_player.play(plan, stage)
		_pose_at(plan, MoveFxPlan.IMPACT, 0.6)
		var cage := _player.get_art(MoveFxPlayer.Flip.IMPACT)
		assert_true(cage.visible, "%s : autour de la cible" % move_id)
		assert_almost_eq(cage.position, stage.target_rect.get_center(), Vector2.ONE)
		sizes.append(cage.scale.x * float(FxArt.flipbook(plan.art[&"cage"])["size"]))
		_player.stop()
	assert_gt(sizes[1], sizes[0] * 1.5, "Danse Fleur engloutit la cible")
	_assert_at_rest(stage)


## Lance-Soleil : le lanceur absorbe la lumière (aura) au tour de charge, puis un rayon énorme.
func test_solar_beam_charges_sunlight_then_fires_a_huge_beam() -> void:
	var stage := _stage()
	var charge := _plan(&"solar_beam", MoveFxPlan.Mode.FULL, _outcome(MoveFxOutcome.Result.CHARGING, 0))
	_player.play(charge, stage)
	_pose_at(charge, MoveFxPlan.CHARGE, 0.6)
	assert_true(_player.get_art(MoveFxPlayer.Flip.AURA).visible, "il absorbe la lumière")
	var mouth := _player.get_art(MoveFxPlayer.Flip.TRAVEL)
	assert_true(not mouth.visible or mouth.texture == FxArt.particle(&"poussiere_or").get("texture"),
		"rien ne part encore : la lumière se rassemble à la bouche")
	_player.stop()
	var plan := _plan(&"solar_beam")
	assert_eq(plan.art.get(&"bolt"), &"rayon_solaire")
	assert_gt(plan.bolt_height, _plan(&"flamethrower").bolt_height, "plus épais que Lance-Flammes")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.8)
	assert_true(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible, "le rayon")
	_player.stop()
	_assert_at_rest(stage)


## Spore Coton : des flocons de coton flottent vers la cible et s'y collent.
func test_cotton_spore_floats_cotton_that_sticks() -> void:
	var stage := _stage()
	var plan := _plan(&"cotton_spore")
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.TRAVEL, 0.6)
	assert_gte(_visible_pieces(), 4, "des flocons")
	_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
	var cotton := _player.get_art(MoveFxPlayer.Flip.IMPACT)
	assert_true(cotton.visible, "le coton colle")
	assert_eq(cotton.texture, FxArt.flipbook(&"coton_colle").get("texture"))
	_player.stop()
	_assert_at_rest(stage)


## Synthèse : un rayon de soleil descend sur le lanceur, couvert d'une aura ; rien vers la cible.
func test_synthesis_bathes_the_user_in_a_sunshaft() -> void:
	var stage := _stage()
	var plan := _plan(&"synthesis")
	assert_true(plan.on_self)
	_player.play(plan, stage)
	_pose_at(plan, MoveFxPlan.IMPACT, 0.5)
	var shaft := _player.get_art(MoveFxPlayer.Flip.SKY)
	assert_true(shaft.visible, "le rayon de soleil")
	assert_almost_eq(shaft.position.x, stage.user_rect.get_center().x, 1.0, "sur le lanceur")
	assert_true(_player.get_art(MoveFxPlayer.Flip.AURA).visible, "aura de photosynthèse")
	assert_false(_player.get_art(MoveFxPlayer.Flip.TRAVEL).visible, "rien ne part")
	assert_eq(_target.position, stage.target_rest, "la cible ne bouge pas")
	_player.stop()
	_assert_at_rest(stage)
