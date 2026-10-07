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


## Échelle attendue de [param species] (BattleArt + BattleLayout).
func _scale(species: StringName, back: bool) -> float:
	var art := BattleArt.new()
	var image := art.image(species, back)
	return BattleLayout.sprite_scale((image["box"] as Rect2).size, art.height_m(species), back,
		_view().y, not image["official"])


## Fichier de l'image affichée par [param sprite] (l'artwork officiel est une AtlasTexture).
func _art_path(sprite: Sprite2D) -> String:
	var texture := sprite.texture
	if texture is AtlasTexture:
		return (texture as AtlasTexture).atlas.resource_path
	return texture.resource_path


## Le Pokémon de [param side] tient dans sa boîte maximale (BattleLayout), elle-même dans
## l'écran et hors de l'interface à 1920 et 2340 de large (test_battle_layout ; la vue de GUT
## n'a pas le format du téléphone).
func _assert_framed(side: BattleEvent.SideId) -> void:
	var rect := _stage.get_sprite_rect(side)
	var limit := BattleLayout.max_rect(side == PLAYER_SIDE, _view()).grow(0.5)
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
	assert_eq(mine.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "dos provisoire net")
	assert_eq(foe.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR, "artwork officiel")
	assert_not_null(foe.material, "artwork étalonné dans la lumière du lieu")
	assert_null(mine.material)
	assert_eq(mine.position, a["player_feet"])
	assert_eq(foe.position, a["foe_feet"])
	assert_eq(mine.scale, Vector2.ONE * _scale(&"charmander", true), "taille de BattleLayout")
	assert_eq(mine.scale.x, floorf(mine.scale.x), "pixel art : échelle entière")
	assert_eq(foe.scale, Vector2.ONE * _scale(&"squirtle", false))
	assert_eq(mine.texture.resource_path, BattleStage.sprite_path(&"charmander", true))
	assert_string_ends_with(mine.texture.resource_path, "charmander_back.png")
	assert_string_ends_with(_art_path(foe), "official/007.png", "Carapuce n° 7")
	assert_eq(mine.texture.get_size(), Vector2(64, 64))
	_assert_framed(PLAYER_SIDE)
	_assert_framed(FOE_SIDE)
	assert_true((_stage.get_node(^"%PlayerShadow") as CanvasItem).visible, "ombre au sol")
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
	assert_eq(_stage.get_sprite(PLAYER_SIDE).position, a["player_feet"])
	assert_eq(_stage.get_sprite(FOE_SIDE).position, a["foe_feet"])
	assert_eq(_stage.get_sprite(FOE_SIDE).modulate, Color.WHITE)
	assert_eq(_camera.offset, Vector2.ZERO, "retour immédiat au cadrage")
	assert_eq((_stage.get_node(^"%Flash") as ColorRect).color.a, 0.0)
	await _stage.play_faint(FOE_SIDE)
	assert_false(_stage.get_sprite(FOE_SIDE).visible, "K.O. : sprite tombé et effacé")
	assert_true(_stage.get_sprite(PLAYER_SIDE).visible)


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
		"charmander_back.png", "le combat affiché ne change pas")
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
	_stage.enter(_camera, _mine, _foe, &"charmander", &"squirtle", rival)
	clock.run_until(func() -> bool: return false, BattleStage.ENTER_DURATION * 0.45)
	var mine := _stage.get_sprite(PLAYER_SIDE)
	assert_between(_camera.zoom.x, 1.01, BattleStage.ZOOM - 0.01, "caméra en mouvement")
	assert_between(mine.scale.x, 1.1, _scale(&"charmander", true) - 0.1, "taille intermédiaire")
	assert_ne(mine.position, _anchors()["player_feet"], "en chemin")
	assert_true(mine.visible)
	assert_true((_stage.get_node(^"%Backdrop") as CanvasItem).visible)
	clock.run_until(func() -> bool: return entered[0], 2.0)
	clock.release()
	assert_true(entered[0], "entrée terminée")
	assert_eq(mine.position, _anchors()["player_feet"])
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
	assert_eq(mine.position, a["player_feet"], "à l'ancre du joueur")
	assert_eq(mine.scale, Vector2.ONE * _scale(&"charmander", true))
	assert_string_ends_with(mine.texture.resource_path, "charmander_back.png")
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
## cachés) et la Ball est posée aux pieds de l'adversaire, nette (NEAREST), à sa taille de repos.
func test_throw_absorbs_the_foe_and_leaves_the_ball_on_the_ground() -> void:
	await _wild()
	await _stage.play_throw()
	var a := _anchors()
	var foe := _stage.get_sprite(FOE_SIDE)
	assert_false(foe.visible, "le sauvage est absorbé")
	var ball := _stage.get_ball()
	assert_not_null(ball)
	assert_true(ball.visible, "la Ball est au sol")
	assert_eq(ball.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST, "pixel art net")
	assert_eq(ball.scale, Vector2.ONE * BattleStage.BALL_REST_SCALE)
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
	assert_true(_stage.get_ball().visible, "la Ball vole")
	steps += clock.run_until(func() -> bool:
		return _stage.get_ball().position.y > 0.0 and not _stage.get_thrower().visible \
			and not _stage.get_sprite(FOE_SIDE).visible, 4.0)
	clock.release()
	var elapsed := steps * TweenClock.STEP
	gut.p("lancer : %.3f s (temps simulé)" % elapsed)
	assert_between(elapsed, 1.0, 3.0, "le lancer dure ~1,5 s")
	_stage.reset()


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
