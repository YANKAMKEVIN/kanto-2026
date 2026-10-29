extends GutTest
## BattleStage (jalon-04.md §14.4, §14.11 T6) sur une mini-carte : caméra enfant d'un
## « joueur », deux PNJ Pokémon posés au sol. Entrée : PNJ cachés, sprites de combat aux
## ancres du pilote (CB.1 : dos provisoire NEAREST à échelle entière, adversaire en artwork
## officiel linéaire et étalonné, tailles de BattleLayout), hors des zones de l'interface,
## caméra recadrée ; animations des
## temps qui se terminent ; sortie : PNJ réaffichés sur leur case, caméra rendue à
## l'identique ; reset ; entrée refusée pendant un combat ; aucun orphelin.
## Transition réelle (speed_scale = 1) : à mi-course, caméra et sprites avancent ensemble.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const STAGE_SCENE := "res://game/battle/battle_stage.tscn"
const NPC_SCENE := "res://game/world/npc/npc.tscn"
const PLAYER_CELL := Vector2i(11, 7)
const MINE_CELL := Vector2i(10, 7)
const FOE_CELL := Vector2i(8, 7)
const RIVAL_CELL := Vector2i(7, 7)
const LIMITS: Array[int] = [-213, -12, 1749, 1068]
const PLAYER_SIDE := BattleEvent.SideId.PLAYER
const FOE_SIDE := BattleEvent.SideId.FOE

var _stage: BattleStage
var _camera: Camera2D
var _mine: Npc
var _foe: Npc


func before_each() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var owner_node := Node2D.new()
	owner_node.position = Grid.cell_to_world(PLAYER_CELL)
	world.add_child(owner_node)
	_camera = Camera2D.new()
	_camera.limit_left = LIMITS[0]
	_camera.limit_top = LIMITS[1]
	_camera.limit_right = LIMITS[2]
	_camera.limit_bottom = LIMITS[3]
	owner_node.add_child(_camera)
	_camera.make_current()
	_mine = _npc(world, &"charmander", MINE_CELL, Vector2i.RIGHT)
	_foe = _npc(world, &"squirtle", FOE_CELL, Vector2i.LEFT)
	_stage = (load(STAGE_SCENE) as PackedScene).instantiate() as BattleStage
	_stage.speed_scale = 0.0
	add_child_autofree(_stage)
	await wait_process_frames(2)


func _npc(parent: Node, id: StringName, cell: Vector2i, facing: Vector2i) -> Npc:
	var spec := NpcSpec.new()
	spec.id = id
	spec.sprite = id
	spec.cell = cell
	spec.facing = facing
	var npc := (load(NPC_SCENE) as PackedScene).instantiate() as Npc
	npc.setup(spec)
	parent.add_child(npc)
	return npc


func _enter(foe: Npc = null) -> void:
	var rival: Array[Vector2i] = [RIVAL_CELL]
	await _stage.enter(_camera, _mine, foe if foe != null else _foe, &"charmander",
		&"squirtle", rival)


func _anchors() -> Dictionary:
	return BattleLayout.anchors(_view())


func _view() -> Vector2:
	return _stage.get_viewport().get_visible_rect().size


## Échelle attendue de [param species] (BattleArt + BattleLayout ; ton Pokémon en cadrage B).
func _scale(species: StringName, back: bool) -> float:
	var art := BattleArt.new()
	var image := art.image(species, back)
	var box: Rect2 = image["box"]
	if back:
		return BattleLayout.back_scale(box.size, art.height_m(species), _view().y, image["crop"],
			not image["official"])
	return BattleLayout.sprite_scale(box.size, art.height_m(species), back, _view().y,
		not image["official"])


## Pieds attendus du dos de [param species] (cadrage B) : bord bas de l'écran, enfoncés de la
## part coupée de l'image.
func _back_feet(species: StringName) -> Vector2:
	var image := BattleArt.new().image(species, true)
	var sink := BattleLayout.back_sink((image["box"] as Rect2).size, _scale(species, true),
		image["crop"])
	return (_anchors()["player_back"] as Vector2) + Vector2(0.0, sink)


## Fichier de l'image affichée par [param sprite] (l'artwork officiel est une AtlasTexture).
func _art_path(sprite: Sprite2D) -> String:
	var texture := sprite.texture
	if texture is AtlasTexture:
		return (texture as AtlasTexture).atlas.resource_path
	return texture.resource_path


## Le Pokémon de [param side] tient dans sa boîte maximale (BattleLayout), elle-même dans
## l'écran et hors de l'interface à 1920 et 2340 de large (test_battle_layout ; la vue de GUT
## n'a pas le format du téléphone).
## Ton Pokémon (cadrage B) : seule sa partie visible à l'écran compte.
func _assert_framed(side: BattleEvent.SideId) -> void:
	var rect := _stage.get_sprite_rect(side)
	var limit := BattleLayout.max_rect(side == PLAYER_SIDE, _view()).grow(0.5)
	if side == PLAYER_SIDE:
		var screen := Rect2(Vector2.ZERO, _view())
		rect = rect.intersection(screen)
		limit = limit.intersection(screen.grow(0.5))
	assert_true(limit.encloses(rect), "%s dans %s" % [rect, limit])


func test_idle_stage_shows_nothing() -> void:
	assert_false(_stage.is_active())
	assert_eq(_stage.layer, UiTokens.LAYER_BATTLE_STAGE)
	assert_false(_stage.get_sprite(PLAYER_SIDE).visible)
	assert_false(_stage.get_sprite(FOE_SIDE).visible)
	assert_false((_stage.get_node(^"%Backdrop") as CanvasItem).visible)


func test_enter_hides_world_pokemon_and_shows_battle_sprites_at_anchors() -> void:
	await _enter()
	var a := _anchors()
	assert_true(_stage.is_active())
	assert_false(_mine.visible, "PNJ du joueur caché")
	assert_false(_foe.visible, "PNJ adverse caché")
	var mine := _stage.get_sprite(PLAYER_SIDE)
	var foe := _stage.get_sprite(FOE_SIDE)
	for sprite: Sprite2D in [mine, foe]:
		assert_true(sprite.visible)
		assert_eq(sprite.modulate, Color.WHITE)
		assert_false(sprite.centered, "pieds sur l'origine (offset)")
	assert_eq(mine.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "dos peint (Salamèche)")
	assert_eq(foe.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "artwork officiel")
	assert_not_null(foe.material, "artwork étalonné dans la lumière du lieu")
	assert_eq(mine.position, _back_feet(&"charmander"), "dos coupé par le bord bas")
	assert_gt(mine.position.y, _view().y, "pieds sous le bord")
	assert_eq(foe.position, a["foe_feet"])
	assert_eq(mine.scale, Vector2.ONE * _scale(&"charmander", true), "taille de BattleLayout")
	assert_eq(foe.scale, Vector2.ONE * _scale(&"squirtle", false))
	assert_eq(mine.texture.resource_path, BattleArt.painted_back_path(4))
	assert_string_ends_with(mine.texture.resource_path, "dos_ia_004.png")
	assert_string_ends_with(_art_path(foe), "official/007.png", "Carapuce n° 7")
	assert_eq(mine.texture.get_size(), Vector2(1024, 1024))
	_assert_framed(PLAYER_SIDE)
	_assert_framed(FOE_SIDE)
	# Godot ramène une échelle nulle à 1e-5 : l'ombre ne dessine rien.
	assert_lt((_stage.get_node(^"%PlayerShadow") as Node2D).scale.x, 0.001,
		"cadrage B : pas d'ombre sous ton Pokémon")
	assert_gt((_stage.get_node(^"%FoeShadow") as Node2D).scale.x, 0.001, "ombre de l'adversaire")
	assert_true((_stage.get_node(^"%Backdrop") as CanvasItem).visible, "voile posé")


func test_enter_recomposes_the_camera_on_the_arena() -> void:
	await _enter()
	# Le parent de la caméra n'a pas de get_cell ici : cadrage sur le rival et les Pokémon.
	var cells: Array[Vector2i] = [RIVAL_CELL, MINE_CELL, FOE_CELL]
	assert_eq(_stage.get_focus(), BattleLayout.focus(cells))
	assert_eq(_camera.zoom, Vector2.ONE * BattleStage.ZOOM)
	assert_eq(_camera.global_position, _stage.get_focus().round())
	assert_eq(_camera.limit_left, -BattleStage.LIMIT_FREE, "limites levées")


func test_moves_hits_stats_and_faint_finish_and_come_back_to_the_anchor() -> void:
	await _enter()
	var a := _anchors()
	await _stage.play_move(PLAYER_SIDE, MoveData.Category.PHYSICAL)
	await _stage.play_move(FOE_SIDE, MoveData.Category.SPECIAL)
	await _stage.play_move(FOE_SIDE, MoveData.Category.STATUS)
	await _stage.play_hit(FOE_SIDE, false)
	await _stage.play_hit(PLAYER_SIDE, true)
	await _stage.play_stat(PLAYER_SIDE, true)
	await _stage.play_stat(FOE_SIDE, false)
	assert_eq(_stage.get_sprite(PLAYER_SIDE).position, _back_feet(&"charmander"))
	assert_eq(_stage.get_sprite(FOE_SIDE).position, a["foe_feet"])
	assert_eq(_stage.get_sprite(FOE_SIDE).modulate, Color.WHITE)
	assert_eq(_camera.offset, Vector2.ZERO, "retour immédiat au cadrage")
	assert_eq((_stage.get_node(^"%Flash") as ColorRect).color.a, 0.0)
	await _stage.play_faint(FOE_SIDE)
	assert_false(_stage.get_sprite(FOE_SIDE).visible, "K.O. : sprite tombé et effacé")
	assert_true(_stage.get_sprite(PLAYER_SIDE).visible)


## Combat vivant (CV.0, T3) : plan de [param move_id] avec l'issue [param result].
func _fx_plan(move_id: StringName, result: MoveFxOutcome.Result,
		mode: MoveFxPlan.Mode = MoveFxPlan.Mode.FULL) -> MoveFxPlan:
	var data := PokemonData.new()
	data.load_dir()
	var catalog := MoveFxCatalog.load_dir()
	var outcome := MoveFxOutcome.new()
	outcome.move_id = move_id
	outcome.result = result
	outcome.hits = 1 if result == MoveFxOutcome.Result.HIT else 0
	return MoveFxPlan.build(catalog, catalog.entry(move_id), data.get_move(move_id), outcome,
		mode)


func test_move_fx_plays_cues_in_order_and_gives_the_scene_back_at_rest() -> void:
	await _enter()
	var a := _anchors()
	var cues: Array[StringName] = []
	_stage.move_fx_cue.connect(func(cue: StringName, plan: MoveFxPlan) -> void:
		assert_not_null(plan, "le plan accompagne le repère")
		cues.append(cue))
	for case: Array in [[&"tackle", MoveFxOutcome.Result.HIT],
			[&"ember", MoveFxOutcome.Result.MISSED],
			[&"thunder_shock", MoveFxOutcome.Result.HIT],
			[&"swords_dance", MoveFxOutcome.Result.AFFECTED]]:
		await _stage.play_move_fx(PLAYER_SIDE, _fx_plan(case[0], case[1]))
		await _stage.finish_move_fx()
		await _stage.play_move_fx(FOE_SIDE, _fx_plan(case[0], case[1]))
		await _stage.finish_move_fx()
	assert_eq(cues.slice(0, 2), [&"launch", &"impact"] as Array[StringName], "Charge")
	assert_eq(cues.slice(4, 6), [&"launch", &"miss"] as Array[StringName], "Flammèche ratée")
	assert_eq(_stage.get_sprite(PLAYER_SIDE).position, _back_feet(&"charmander"))
	assert_eq(_stage.get_sprite(FOE_SIDE).position, a["foe_feet"])
	assert_eq(_stage.get_sprite(FOE_SIDE).modulate, Color.WHITE)
	assert_eq(_stage.offset, Vector2.ZERO, "caméra du combat revenue")
	assert_eq(_stage.scale, Vector2.ONE)
	assert_false(_stage.get_move_fx_player().get_light().is_lit(), "lumière éteinte")


func test_move_fx_hands_over_at_the_impact_and_drives_the_hit() -> void:
	await _enter()
	_stage.speed_scale = 1.0
	var plan := _fx_plan(&"tackle", MoveFxOutcome.Result.HIT)
	await _stage.play_move_fx(PLAYER_SIDE, plan)
	var fx := _stage.get_move_fx_player()
	assert_true(fx.is_playing(), "la fin de la chorégraphie se joue ensuite")
	assert_between(fx.elapsed(), plan.cue_time(MoveFxPlan.CUE_IMPACT),
		plan.cue_time(MoveFxPlan.CUE_IMPACT) + 0.1, "rend la main à l'impact")
	assert_true(_stage.is_move_fx_hitting(FOE_SIDE), "la chorégraphie porte le coup")
	assert_false(_stage.is_move_fx_hitting(PLAYER_SIDE))
	await _stage.play_hit(FOE_SIDE, false)
	await _stage.finish_move_fx()
	assert_false(_stage.is_move_fx_hitting(FOE_SIDE))
	assert_eq(_stage.get_sprite(FOE_SIDE).position, _anchors()["foe_feet"])


func test_move_fx_mode_follows_the_settings() -> void:
	assert_eq(_stage.move_fx_mode(), MoveFxPlan.Mode.FULL)
	_stage.battle_animations = GameSettings.BattleAnimations.FAST
	assert_eq(_stage.move_fx_mode(), MoveFxPlan.Mode.FAST)
	_stage.reduce_motion = true
	assert_eq(_stage.move_fx_mode(), MoveFxPlan.Mode.REDUCED, "Réduire les animations l'emporte")


func test_exit_gives_back_npcs_on_their_cell_and_the_camera_unchanged() -> void:
	var zoom := _camera.zoom
	var position := _camera.position
	var offset := _camera.offset
	await _enter()
	await _stage.play_faint(FOE_SIDE)
	await _stage.exit()
	assert_false(_stage.is_active())
	for pair: Array in [[_mine, MINE_CELL], [_foe, FOE_CELL]]:
		var npc: Npc = pair[0]
		assert_true(npc.visible, "%s réaffiché" % npc.name)
		assert_eq(npc.modulate, Color.WHITE)
		assert_eq(npc.get_cell(), pair[1])
		assert_eq(npc.position, Grid.cell_to_world(pair[1]))
	assert_eq(_camera.zoom, zoom)
	assert_eq(_camera.position, position)
	assert_eq(_camera.offset, offset)
	assert_eq([_camera.limit_left, _camera.limit_top, _camera.limit_right,
		_camera.limit_bottom] as Array[int], LIMITS)
	assert_false(_stage.get_sprite(PLAYER_SIDE).visible)
	assert_false(_stage.get_sprite(FOE_SIDE).visible)
	assert_false((_stage.get_node(^"%Backdrop") as CanvasItem).visible)


## QA S24 du J30 : le porteur de la caméra (le joueur) est prévenu que le combat la tient,
## puis qu'il la rend (une reprise de l'appli ne la recadre plus pendant le combat).
func test_camera_holder_is_told_while_the_battle_holds_the_camera() -> void:
	var holder := _camera.get_parent()
	var script := GDScript.new()
	script.source_code = "extends Node2D\nvar calls: Array = []\nfunc hold_camera(held: bool) -> void:\n\tcalls.append(held)\n"
	script.reload()
	var spy := Node2D.new()
	spy.set_script(script)
	spy.position = (holder as Node2D).position
	holder.get_parent().add_child(spy)
	_camera.reparent(spy, false)
	await _enter()
	assert_eq(spy.get(&"calls"), [true])
	await _stage.exit()
	assert_eq(spy.get(&"calls"), [true, false])


func test_reset_puts_everything_back_immediately() -> void:
	var position := _camera.position
	await _enter()
	_stage.reset()
	assert_false(_stage.is_active())
	assert_true(_mine.visible)
	assert_true(_foe.visible)
	assert_eq(_camera.zoom, Vector2.ONE)
	assert_eq(_camera.position, position)
	assert_eq(_camera.limit_right, LIMITS[2])
	assert_false(_stage.get_sprite(PLAYER_SIDE).visible)
	assert_null(_stage.get_sprite(PLAYER_SIDE).texture)


func test_enter_during_a_battle_is_refused() -> void:
	await _enter()
	await _stage.enter(_camera, _foe, _mine, &"bulbasaur", &"bulbasaur")
	assert_push_error("déjà affiché")
	assert_string_ends_with(_stage.get_sprite(PLAYER_SIDE).texture.resource_path,
		"dos_ia_004.png", "le combat affiché ne change pas")
	assert_eq(_camera.zoom, Vector2.ONE * BattleStage.ZOOM)


func test_show_pokemon_without_world_npc_and_no_effect_when_shown() -> void:
	var rival: Array[Vector2i] = [RIVAL_CELL]
	await _stage.enter(_camera, _mine, null, &"charmander", &"bulbasaur", rival)
	var foe := _stage.get_sprite(FOE_SIDE)
	assert_true(foe.visible, "sans PNJ : il apparaît à son ancre")
	assert_eq(foe.position, _anchors()["foe_feet"])
	_stage.show_pokemon(FOE_SIDE, &"bulbasaur")
	assert_eq(foe.position, _anchors()["foe_feet"], "déjà affiché : sans effet")
	assert_eq(foe.modulate, Color.WHITE)
	await _stage.play_faint(FOE_SIDE)
	_stage.show_pokemon(FOE_SIDE, &"squirtle")
	await wait_process_frames(2)
	assert_true(foe.visible, "le suivant entre en jeu")
	assert_string_ends_with(_art_path(foe), "official/007.png")
	await _stage.exit()
	assert_true(_mine.visible)


## Transition réelle : à mi-course, le décor est visible (jamais noir), la caméra est entre
## les deux cadrages et le sprite, entre la place du PNJ et son ancre, a une taille
## intermédiaire (effet de caméra, pas de gonflement sur place).
func test_real_transition_moves_camera_and_sprites_together() -> void:
	_stage.speed_scale = 1.0
	var rival: Array[Vector2i] = [RIVAL_CELL]
	# Temps simulé (TweenClock, speed_scale à 1) : relevé à 45 % de l'entrée exactement.
	var clock := TweenClock.new(get_tree())
	var entered: Array[bool] = [false]
	_stage.entered.connect(func() -> void: entered[0] = true, CONNECT_ONE_SHOT)
	# Tortank : dos provisoire (pixel art), la taille intermédiaire suit l'échelle entière.
	_stage.enter(_camera, _mine, _foe, &"blastoise", &"squirtle", rival)
	clock.run_until(func() -> bool: return false, BattleStage.ENTER_DURATION * 0.45)
	var mine := _stage.get_sprite(PLAYER_SIDE)
	assert_between(_camera.zoom.x, 1.01, BattleStage.ZOOM - 0.01, "caméra en mouvement")
	assert_between(mine.scale.x, 1.1, _scale(&"blastoise", true) - 0.1, "taille intermédiaire")
	assert_ne(mine.position, _back_feet(&"blastoise"), "en chemin")
	assert_true(mine.visible)
	assert_true((_stage.get_node(^"%Backdrop") as CanvasItem).visible)
	clock.run_until(func() -> bool: return entered[0], 2.0)
	clock.release()
	assert_true(entered[0], "entrée terminée")
	assert_eq(mine.position, _back_feet(&"blastoise"))
	_stage.exit()
	await wait_for_signal(_stage.exited, 2.0)
	assert_true(_mine.visible)
	assert_eq(_camera.zoom, Vector2.ONE)


func test_no_orphans_after_a_full_battle() -> void:
	await _enter()
	await _stage.play_hit(FOE_SIDE, true)
	await _stage.exit()
	assert_no_new_orphans()


## Avec une arène (tapis du labo) : le cadrage suit BattleLayout.arena_focus, puis set_frame
## est oublié à la sortie.
func test_set_frame_frames_the_arena() -> void:
	var arena := Rect2(576, 480, 384, 288)
	var bounds := Rect2(0, 0, 1536, 1056)
	_stage.set_frame(arena, bounds)
	await _enter()
	var view := _stage.get_viewport().get_visible_rect().size
	assert_eq(_stage.get_focus(), BattleLayout.arena_focus(arena, bounds, view, BattleStage.ZOOM))
	await _stage.exit()
	await _enter()
	var cells: Array[Vector2i] = [RIVAL_CELL, MINE_CELL, FOE_CELL]
	assert_eq(_stage.get_focus(), BattleLayout.focus(cells), "cadrage oublié après la sortie")


# --- Rencontre sauvage (jalon 5 §3.7) ------------------------------------------------

## Intro sauvage : recadrage + voile, le sauvage apparaît à son ancre (pas de PNJ du monde),
## puis le partenaire entre depuis la gauche jusqu'à sa place. Sortie : tout rendu.
func test_wild_intro_and_partner_enter_end_at_the_anchors() -> void:
	var origin := Grid.cell_to_world(FOE_CELL)
	await _stage.play_wild_intro(_camera, &"pidgey", origin)
	var a := _anchors()
	var foe := _stage.get_sprite(FOE_SIDE)
	assert_true(_stage.is_active())
	assert_true(foe.visible, "le sauvage apparaît")
	assert_eq(foe.position, a["foe_feet"], "à l'ancre adverse")
	assert_eq(foe.scale, Vector2.ONE * _scale(&"pidgey", false))
	assert_eq(foe.modulate, Color.WHITE)
	assert_string_ends_with(_art_path(foe), "official/016.png", "artwork de Roucool")
	_assert_framed(FOE_SIDE)
	assert_false(_stage.get_sprite(PLAYER_SIDE).visible, "partenaire pas encore entré")
	assert_eq(_camera.zoom, Vector2.ONE * BattleStage.ZOOM, "caméra recadrée")
	assert_true((_stage.get_node(^"%Backdrop") as CanvasItem).visible,
		"voile posé, pas d'écran noir")
	await _stage.play_partner_enter(&"charmander")
	var mine := _stage.get_sprite(PLAYER_SIDE)
	assert_true(mine.visible)
	assert_eq(mine.position, _back_feet(&"charmander"), "à l'ancre du joueur")
	assert_eq(mine.scale, Vector2.ONE * _scale(&"charmander", true))
	assert_string_ends_with(mine.texture.resource_path, "dos_ia_004.png")
	_assert_framed(PLAYER_SIDE)
	await _stage.exit()
	assert_false(_stage.is_active())
	assert_eq(_camera.zoom, Vector2.ONE, "caméra rendue")
	assert_false(foe.visible)
	assert_false(mine.visible)
	assert_false((_stage.get_node(^"%Backdrop") as CanvasItem).visible)


func test_wild_intro_during_a_battle_is_refused() -> void:
	await _enter()
	await _stage.play_wild_intro(_camera, &"rattata", Grid.cell_to_world(FOE_CELL))
	assert_push_error("déjà affiché")
	assert_string_ends_with(_art_path(_stage.get_sprite(FOE_SIDE)), "official/007.png",
		"le combat affiché ne change pas")


func test_reset_after_a_wild_intro_puts_everything_back() -> void:
	await _stage.play_wild_intro(_camera, &"rattata", Grid.cell_to_world(FOE_CELL))
	await _stage.play_partner_enter(&"squirtle")
	_stage.reset()
	assert_false(_stage.is_active())
	assert_eq(_camera.zoom, Vector2.ONE)
	assert_eq(_camera.limit_right, LIMITS[2])
	assert_false(_stage.get_sprite(FOE_SIDE).visible)
	assert_false(_stage.get_sprite(PLAYER_SIDE).visible)


func test_no_orphans_after_a_wild_intro() -> void:
	await _stage.play_wild_intro(_camera, &"pidgey", Grid.cell_to_world(FOE_CELL))
	await _stage.play_partner_enter(&"charmander")
	await _stage.exit()
	assert_no_new_orphans()


# --- Capture (jalon 5D, T15) ------------------------------------------------------------

func _wild() -> void:
	await _stage.play_wild_intro(_camera, &"rattata", Grid.cell_to_world(FOE_CELL))
	await _stage.play_partner_enter(&"charmander")


## Après le lancer : le dresseur est reparti, le Pokémon sauvage est absorbé (sprite et ombre
## cachés) et la Ball peinte (CV-11, LINEAR) est posée aux pieds de l'adversaire, à sa taille de
## repos ; la caméra s'est approchée d'elle et le décor s'est assombri.
func test_throw_absorbs_the_foe_and_leaves_the_ball_on_the_ground() -> void:
	await _wild()
	await _stage.play_throw()
	var a := _anchors()
	var foe := _stage.get_sprite(FOE_SIDE)
	assert_false(foe.visible, "le sauvage est absorbé")
	var ball := _stage.get_ball()
	assert_not_null(ball)
	assert_true(ball.visible, "la Ball est au sol")
	assert_eq(ball.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "Ball peinte")
	assert_eq(ball.scale, Vector2.ONE * BattleStage.BALL_REST_SCALE * BattleStage.BALL_ART)
	assert_almost_eq(ball.texture.get_width() * ball.scale.x,
		32.0 * BattleStage.BALL_REST_SCALE, 0.5, "même taille à l'écran que l'ancienne Ball")
	assert_almost_eq(_stage.scale.x, BattleStage.CAPTURE_ZOOM, 0.001, "la caméra s'approche")
	assert_true(_stage.get_move_fx_player().get_light().is_lit(), "le décor s'assombrit")
	var feet: Vector2 = a["foe_feet"]
	assert_eq(ball.position.x, feet.x, "sous le sauvage")
	assert_between(ball.position.y, feet.y - 200.0, feet.y, "posée sur le sol")
	assert_eq(ball.rotation, 0.0)
	assert_false(_stage.get_thrower().visible, "le dresseur est reparti")
	assert_true(_stage.is_capture_shown())
	assert_true(_stage.get_sprite(PLAYER_SIDE).visible, "le partenaire reste")


func test_throw_before_a_battle_is_ignored() -> void:
	await _stage.play_throw()
	assert_false(_stage.is_capture_shown())
	assert_null(_stage.get_ball())


func test_shake_rocks_the_ball_and_ends_upright() -> void:
	await _wild()
	await _stage.play_throw()
	var ball := _stage.get_ball()
	var rest := ball.position
	await _stage.play_ball_shake()
	assert_eq(ball.rotation, 0.0, "redressée")
	assert_eq(ball.position, rest, "elle n'a pas bougé")
	assert_true(ball.visible)


func test_shake_without_a_ball_is_ignored() -> void:
	await _wild()
	await _stage.play_ball_shake()
	assert_null(_stage.get_ball())


func test_catch_burst_leaves_the_ball_and_clears_the_effects() -> void:
	await _wild()
	await _stage.play_throw()
	await _stage.play_catch_burst()
	assert_true(_stage.get_ball().visible, "la Ball reste jusqu'à la sortie")
	assert_eq((_stage.get_node(^"%Flash") as ColorRect).color.a, 0.0, "voile doré retombé")
	assert_eq(_stage.scale, Vector2.ONE, "caméra revenue à l'éclat")
	assert_eq(_stage.offset, Vector2.ZERO)
	assert_false(_stage.get_move_fx_player().get_light().is_lit(), "lumière rendue")
	assert_false(_stage.get_sprite(FOE_SIDE).visible, "le sauvage ne revient pas")


func test_break_free_brings_the_foe_back_and_removes_the_ball() -> void:
	await _wild()
	await _stage.play_throw()
	await _stage.play_ball_shake()
	await _stage.play_break_free()
	var a := _anchors()
	var foe := _stage.get_sprite(FOE_SIDE)
	assert_true(foe.visible, "le Pokémon est ressorti")
	assert_eq(foe.position, a["foe_feet"], "à sa place de combat")
	assert_eq(foe.scale, Vector2.ONE * _scale(&"rattata", false), "à sa taille")
	assert_eq(foe.modulate, Color.WHITE)
	assert_false(_stage.get_ball().visible, "la Ball s'est ouverte")
	assert_false(_stage.is_capture_shown())
	assert_eq(_stage.scale, Vector2.ONE, "caméra revenue")
	assert_false(_stage.get_move_fx_player().get_light().is_lit(), "lumière rendue")


func test_exit_after_a_capture_hides_the_ball_and_never_brings_the_foe_back() -> void:
	await _wild()
	await _stage.play_throw()
	await _stage.play_catch_burst()
	await _stage.exit()
	assert_false(_stage.is_active())
	assert_false(_stage.is_capture_shown())
	assert_false(_stage.get_sprite(FOE_SIDE).visible)
	assert_eq(_camera.zoom, Vector2.ONE, "caméra rendue")
	assert_no_new_orphans()


func test_reduced_motion_capture_dims_without_moving_the_camera() -> void:
	_stage.reduce_motion = true
	await _wild()
	await _stage.play_throw()
	assert_eq(_stage.scale, Vector2.ONE, "Réduire les animations : pas de caméra")
	assert_true(_stage.get_move_fx_player().get_light().is_lit(), "le décor s'assombrit quand même")
	await _stage.play_catch_burst()
	assert_false(_stage.get_move_fx_player().get_light().is_lit())


## Coups multiples : la barre de chaque coup attend l'impact de ce coup (`impact_2`…).
func test_each_hit_of_a_multi_hit_waits_for_its_impact() -> void:
	await _enter()
	_stage.speed_scale = 1.0
	var catalog := MoveFxCatalog.load_dir()
	var data := PokemonData.new()
	data.load_dir()
	var outcome := MoveFxOutcome.new()
	outcome.move_id = &"double_kick"
	outcome.result = MoveFxOutcome.Result.HIT
	outcome.hits = 2
	var plan := MoveFxPlan.build(catalog, catalog.entry(&"double_kick"),
		data.get_move(&"double_kick"), outcome, MoveFxPlan.Mode.FULL)
	await _stage.play_move_fx(PLAYER_SIDE, plan)
	var fx := _stage.get_move_fx_player()
	await _stage.wait_move_fx_impact()
	assert_lt(fx.elapsed(), plan.cue_time(MoveFxPlan.impact_cue(1)), "le 1er coup tout de suite")
	await _stage.wait_move_fx_impact()
	assert_gte(fx.elapsed(), plan.cue_time(MoveFxPlan.impact_cue(1)), "le 2e à son impact")
	await _stage.finish_move_fx()
	await wait_process_frames(1)


func test_ultralaser_user_pants_then_rests() -> void:
	await _enter()
	var sprite := _stage.get_sprite(PLAYER_SIDE)
	var rest := sprite.scale
	await _stage.play_panting(PLAYER_SIDE)
	assert_eq(sprite.scale, rest, "rendu à sa taille")
	assert_eq(sprite.position, _back_feet(&"charmander"))


func test_reset_during_a_capture_puts_everything_back() -> void:
	await _wild()
	await _stage.play_throw()
	_stage.reset()
	assert_false(_stage.is_capture_shown())
	assert_false(_stage.get_sprite(FOE_SIDE).visible)
	assert_eq(_camera.zoom, Vector2.ONE)


## À vitesse réelle, le lancer dure de l'ordre d'une seconde et demie (jalon-05.md §3.10), la
## secousse 0,6 s : le dresseur est visible à mi-course.
func test_throw_takes_a_second_or_so_at_real_speed_and_shows_the_thrower() -> void:
	_stage.speed_scale = 1.0
	await _stage.play_wild_intro(_camera, &"rattata", Grid.cell_to_world(FOE_CELL))
	await _stage.play_partner_enter(&"charmander")
	# Temps simulé (TweenClock, speed_scale à 1) : la durée se compte en pas, quelle que soit
	# la charge de la machine.
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void: await _stage.play_throw()
	runner.call()
	var steps := clock.run_until(func() -> bool: return false, 0.4)
	assert_true(_stage.get_thrower().visible, "le dresseur est dans le cadrage")
	# Correctif QA S24 : le héros peint (LINEAR, 1:1) est entier à l'écran, plus coupé en bas.
	var thrower := _stage.get_thrower()
	var size := thrower.get_rect().size
	for view: Vector2 in [Vector2(1920, 1080), Vector2(2340, 1080)]:
		var feet := BattleStage.thrower_feet(view)
		var shown := Rect2(feet - Vector2(size.x / 2.0, size.y), size)
		assert_true(Rect2(Vector2.ZERO, view).encloses(shown),
			"dresseur entier dans %s (%s)" % [view, shown])
	assert_eq(thrower.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "héros peint")
	assert_eq(thrower.texture, BattleStage.THROWER_TEXTURE)
	assert_true(_stage.get_ball().visible, "la Ball vole")
	steps += clock.run_until(func() -> bool:
		return _stage.get_ball().position.y > 0.0 and not _stage.get_thrower().visible \
			and not _stage.get_sprite(FOE_SIDE).visible, 4.0)
	clock.release()
	var elapsed := steps * TweenClock.STEP
	gut.p("lancer : %.3f s (temps simulé)" % elapsed)
	assert_between(elapsed, 1.0, 3.0, "le lancer dure ~1,5 s")
	_stage.reset()


## Voile du poison (jalon 9, T5) : le sprite se fond vers le violet puis revient, STATUS_VEIL_DURATION
## (0,35 s) au total en temps simulé, sans déplacer le Pokémon.
func test_poison_veil_tints_violet_for_a_third_of_a_second_then_clears() -> void:
	await _enter()
	_stage.speed_scale = 1.0
	var sprite := _stage.get_sprite(FOE_SIDE)
	var feet := sprite.position
	var artwork := sprite.material as ShaderMaterial
	assert_not_null(artwork, "artwork officiel étalonné (CB.1)")
	var done: Array[bool] = [false]
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void:
		await _stage.play_poison(FOE_SIDE)
		done[0] = true
	runner.call()
	var half := roundi(UiTokens.STATUS_VEIL_DURATION / 2.0 / TweenClock.STEP)
	for i: int in half:
		clock.step()
	assert_false(done[0], "pas fini à mi-course")
	var material := sprite.material as ShaderMaterial
	assert_not_null(material, "le voile est posé sur le sprite")
	assert_ne(material, artwork, "copie : le matériau partagé de l'artwork n'est pas teinté")
	assert_eq(material.shader, artwork.shader, "l'étalonnage de l'artwork reste pendant le voile")
	assert_eq(float(artwork.get_shader_parameter(&"amount")), 0.0)
	assert_almost_eq(float(material.get_shader_parameter(&"amount")),
		UiTokens.STATUS_VEIL_AMOUNT, 0.02, "voile au pic à mi-course")
	assert_eq(material.get_shader_parameter(&"tint"), UiTokens.STATUS_VEIL)
	assert_gt(UiTokens.STATUS_VEIL.b, UiTokens.STATUS_VEIL.g, "violet : bleu et rouge > vert")
	assert_gt(UiTokens.STATUS_VEIL.r, UiTokens.STATUS_VEIL.g)
	assert_eq(sprite.position, feet, "le voile ne déplace pas le Pokémon")
	var steps := half
	steps += clock.run_until(func() -> bool: return done[0], 1.0)
	clock.release()
	var elapsed := steps * TweenClock.STEP
	assert_true(done[0])
	assert_gte(elapsed, UiTokens.STATUS_VEIL_DURATION - TweenClock.STEP, "pas avant 0,35 s")
	assert_lte(elapsed, UiTokens.STATUS_VEIL_DURATION + 2.0 * TweenClock.STEP,
		"au plus un pas de plus")
	assert_eq(sprite.modulate, Color.WHITE, "la teinte du sprite n'est pas touchée")
	assert_eq(sprite.material, artwork, "voile retiré, artwork étalonné rendu")
	_stage.speed_scale = 0.0


func test_poison_veil_is_softer_when_flashes_are_reduced() -> void:
	await _enter()
	_stage.reduce_flashes = true
	_stage.speed_scale = 1.0
	var sprite := _stage.get_sprite(PLAYER_SIDE)
	var base_material := sprite.material
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void: await _stage.play_poison(PLAYER_SIDE)
	runner.call()
	for i: int in roundi(UiTokens.STATUS_VEIL_DURATION / 2.0 / TweenClock.STEP):
		clock.step()
	assert_almost_eq(float((sprite.material as ShaderMaterial).get_shader_parameter(&"amount")),
		UiTokens.STATUS_VEIL_AMOUNT_REDUCED, 0.02)
	assert_lt(UiTokens.STATUS_VEIL_AMOUNT_REDUCED, UiTokens.STATUS_VEIL_AMOUNT)
	clock.run_until(func() -> bool: return false, 0.5)
	clock.release()
	assert_eq(sprite.material, base_material, "voile retiré, matériau d'origine rendu")
	_stage.speed_scale = 0.0


# --- Effets de statut (jalon 11, T7) ----------------------------------------------------------

## Chaque effet se pose au-dessus du sprite, sans toucher à son matériau ni à sa teinte (leçon du
## J9 × CB.1) ; le gel copie le sprite teinté par-dessus.
func test_status_effects_sit_above_the_sprite_without_touching_it() -> void:
	await _enter()
	for side: BattleEvent.SideId in [PLAYER_SIDE, FOE_SIDE]:
		var sprite := _stage.get_sprite(side)
		var material := sprite.material
		var aura := _stage.get_status_aura(side)
		assert_not_null(aura)
		assert_eq(aura.get_parent(), sprite.get_parent())
		assert_gt(aura.get_index(), sprite.get_index(), "dessiné après le sprite : au-dessus")
		var rect := aura.get_target_rect()
		var expected := _stage.get_sprite_rect(side)
		assert_lt(rect.position.distance_to(expected.position), 8.0,
			"l'effet suit la boîte visible du sprite (offset arrondi)")
		# La respiration (CV.3) étire le sprite de 2 % au plus, pieds fixes.
		assert_lt(rect.size.distance_to(expected.size), expected.size.y * 0.025 + 1.0)
		for status: StringName in StatusRules.KNOWN:
			_stage.set_status(side, status)
			await wait_process_frames(1)
			assert_eq(aura.get_status(), status)
			assert_eq(aura.is_ice_shown(), status == StatusRules.FREEZE, String(status))
			assert_eq(sprite.material, material, "%s : matériau du sprite intact" % status)
			assert_eq(sprite.modulate, Color.WHITE, "%s : teinte du sprite intacte" % status)
		_stage.set_status(side, StatusRules.NONE)
		await wait_process_frames(1)
		assert_false(aura.is_ice_shown())


func test_freeze_tint_follows_the_sprite_and_stays_with_reduced_motion() -> void:
	await _enter()
	_stage.reduce_motion = true
	_stage.set_status(FOE_SIDE, StatusRules.FREEZE)
	await wait_process_frames(1)
	var aura := _stage.get_status_aura(FOE_SIDE)
	assert_true(aura.reduce_motion)
	assert_true(aura.is_ice_shown(), "« Réduire les animations » garde la teinte")
	var ice := aura.get_node(^"Ice") as Sprite2D
	var sprite := _stage.get_sprite(FOE_SIDE)
	assert_eq([ice.texture, ice.position.x, ice.scale.x, ice.offset],
		[sprite.texture, sprite.position.x, sprite.scale.x, sprite.offset])
	# La copie de givre suit le corps, respiration comprise (CV.3 : 2 % au plus, pieds fixes).
	assert_almost_eq(ice.scale.y, sprite.scale.y, sprite.scale.y * 0.021)
	await aura.play_confusion()
	assert_false(aura.is_confusion_shown(), "pas d'étoiles avec « Réduire les animations »")


func test_confusion_stars_play_then_clear() -> void:
	await _enter()
	_stage.speed_scale = 1.0
	var aura := _stage.get_status_aura(PLAYER_SIDE)
	var done: Array[bool] = [false]
	var runner := func() -> void:
		await _stage.play_confusion(PLAYER_SIDE)
		done[0] = true
	runner.call()
	await wait_process_frames(2)
	assert_true(aura.is_confusion_shown())
	await wait_until(func() -> bool: return done[0], 3.0)
	assert_false(aura.is_confusion_shown())
	_stage.speed_scale = 0.0


func test_faint_and_reset_clear_the_status_effect() -> void:
	await _enter()
	_stage.set_status(FOE_SIDE, StatusRules.SLEEP)
	await _stage.play_faint(FOE_SIDE)
	assert_eq(_stage.get_status_aura(FOE_SIDE).get_status(), StatusRules.NONE, "K.O.")
	_stage.set_status(PLAYER_SIDE, StatusRules.BURN)
	_stage.reset()
	assert_eq(_stage.get_status_aura(PLAYER_SIDE).get_status(), StatusRules.NONE, "reset")


func test_burn_veil_is_orange() -> void:
	await _enter()
	_stage.speed_scale = 1.0
	var sprite := _stage.get_sprite(PLAYER_SIDE)
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void: await _stage.play_poison(PLAYER_SIDE, StatusRules.BURN)
	runner.call()
	clock.step()
	assert_eq((sprite.material as ShaderMaterial).get_shader_parameter(&"tint"),
		UiTokens.STATUS_BURN_VEIL)
	assert_gt(UiTokens.STATUS_BURN_VEIL.r, UiTokens.STATUS_BURN_VEIL.b, "orangé")
	clock.run_until(func() -> bool: return false, 0.5)
	clock.release()
	_stage.speed_scale = 0.0


# --- Réglages (jalon-06.md §6.12, T29) -------------------------------------------------------

func test_backdrop_blur_can_be_cut_and_restored() -> void:
	var material := _stage.get_node("%Backdrop").material as ShaderMaterial
	assert_eq(material.get_shader_parameter(&"blur_lod"), BattleStage.BLUR_LOD)
	_stage.backdrop_blur = false
	assert_eq(material.get_shader_parameter(&"blur_lod"), 0.0)
	_stage.backdrop_blur = true
	assert_eq(material.get_shader_parameter(&"blur_lod"), BattleStage.BLUR_LOD)


func test_reduced_flashes_soften_the_flash_and_still_end_clean() -> void:
	await _enter()
	_stage.reduce_flashes = true
	assert_almost_eq(_stage._flash_alpha(1.0), BattleStage.REDUCED_FLASH_GAIN, 0.0001)
	await _stage.play_hit(FOE_SIDE, true)
	assert_eq(_stage.get_sprite(FOE_SIDE).modulate, Color.WHITE, "retour à l etat de repos")
	_stage.reduce_flashes = false
	assert_eq(_stage._flash_alpha(1.0), 1.0)


func test_every_species_met_in_battle_has_its_sprites() -> void:
	# jalon-09.md §2.5 (T1) : sprites provisoires (tools/gen_placeholder_battlers.gd) pour
	# chaque espèce d'une table de rencontres ou d'une équipe de Dresseur, et pour les huit
	# espèces de la Forêt de Jade (les évolutions naissent en combat, Raichu au Pokédex).
	# Toutes les espèces des données (évolutions comprises) : test_battle_art.gd (QA 12A).
	var data := PokemonData.new()
	data.load_dir()
	var species: Array[StringName] = [&"caterpie", &"metapod", &"butterfree", &"weedle",
		&"kakuna", &"beedrill", &"pikachu", &"raichu"]
	var encounters := EncounterLibrary.new(data)
	encounters.load_dir()
	for map_id: StringName in [&"route_1", &"route_22", &"viridian_forest"]:
		for slot: EncounterSlot in encounters.get_table(map_id).slots:
			species.append(slot.species)
	var trainers := TrainerLibrary.new(data)
	trainers.load_dir()
	for trainer_id: StringName in trainers.get_ids():
		for starter: StringName in [&"bulbasaur", &"charmander", &"squirtle"]:
			species.append(starter)
			for slot: TrainerSlot in trainers.get_trainer(trainer_id).team_for(starter):
				species.append(slot.species)
	for id: StringName in species:
		assert_true(data.has_species(id), String(id))
		for back: bool in [false, true]:
			var path := BattleStage.sprite_path(id, back)
			assert_true(ResourceLoader.exists(path), path)


## Jalon 13 : un Dresseur rappelle son Pokémon (même mouvement que le joueur), puis le suivant
## entre à sa place, à sa taille.
func test_foe_withdraw_then_the_next_one_enters() -> void:
	await _enter()
	var sprite := _stage.get_sprite(FOE_SIDE)
	var scale := sprite.scale
	await _stage.play_withdraw(FOE_SIDE)
	assert_false(sprite.visible, "rappelé : caché")
	assert_true(_stage.get_sprite(PLAYER_SIDE).visible)
	_stage.show_pokemon(FOE_SIDE, &"pidgey")
	await wait_process_frames(1)
	assert_true(sprite.visible)
	assert_eq(sprite.position, _anchors()["foe_feet"])
	assert_almost_eq(sprite.scale.x, _scale(&"pidgey", false), 0.001)
	assert_ne(sprite.scale, scale * BattleStage.WITHDRAW_SCALE, "taille rendue")


## « Réduire les animations » : le rappel ne rétrécit pas, il s'efface seulement.
func test_withdraw_without_shrink_when_motion_is_reduced() -> void:
	await _enter()
	_stage.speed_scale = 1.0
	_stage.reduce_motion = true
	var sprite := _stage.get_sprite(FOE_SIDE)
	var scale := sprite.scale
	var done: Array[bool] = [false]
	var clock := TweenClock.new(get_tree())
	var runner := func() -> void:
		await _stage.play_withdraw(FOE_SIDE)
		done[0] = true
	runner.call()
	clock.run_until(func() -> bool: return false, BattleStage.WITHDRAW_DURATION * 0.5)
	assert_eq(sprite.scale, scale, "pas de rétrécissement")
	assert_between(sprite.modulate.a, 0.05, 0.95, "fondu en cours")
	clock.run_until(func() -> bool: return done[0], 1.0)
	clock.release()
	assert_true(done[0])
	assert_false(sprite.visible)
