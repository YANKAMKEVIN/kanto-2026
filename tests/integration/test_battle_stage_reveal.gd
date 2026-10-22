extends GutTest
## [method BattleStage.dissolve_foe] (jalon 21, `jalon-21.md` §2.5, T11) : après l'intro sauvage
## sur la silhouette du SPECTRE, fondu croisé vers l'artwork d'Ossatueur en
## [constant BattleStage.REVEAL_DISSOLVE_DURATION] s (temps simulé, TweenClock) : silhouette pleine
## au départ, artwork plein à 1,0 s au pas près, silhouette libérée ; instantané avec « Réduire
## les animations » ; sans combat affiché : rien.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const STAGE_SCENE := "res://game/battle/battle_stage.tscn"
const PLAYER_CELL := Vector2i(11, 7)
const FOE_CELL := Vector2i(8, 7)
const FOE_SIDE := BattleEvent.SideId.FOE
const FOE := &"marowak"

var _stage: BattleStage
var _camera: Camera2D


func before_each() -> void:
	var world := Node2D.new()
	add_child_autofree(world)
	var owner_node := Node2D.new()
	owner_node.position = Grid.cell_to_world(PLAYER_CELL)
	world.add_child(owner_node)
	_camera = Camera2D.new()
	owner_node.add_child(_camera)
	_camera.make_current()
	_stage = (load(STAGE_SCENE) as PackedScene).instantiate() as BattleStage
	_stage.speed_scale = 0.0
	add_child_autofree(_stage)
	await wait_process_frames(2)
	await _stage.play_wild_intro(_camera, GhostDisguise.SPECIES, Grid.cell_to_world(FOE_CELL))


func _art_path(sprite: Sprite2D) -> String:
	var texture := sprite.texture
	if texture is AtlasTexture:
		return (texture as AtlasTexture).atlas.resource_path
	return texture.resource_path


func _foe_art() -> String:
	var art := BattleArt.new()
	var texture: Texture2D = art.image(FOE, false)["texture"]
	return (texture as AtlasTexture).atlas.resource_path if texture is AtlasTexture \
		else texture.resource_path


func test_the_intro_shows_the_silhouette() -> void:
	var foe := _stage.get_sprite(FOE_SIDE)
	assert_true(foe.visible)
	assert_eq(_art_path(foe), GhostDisguise.TEXTURE_PATH)


func test_cross_fade_lasts_one_second_in_simulated_time() -> void:
	_stage.speed_scale = 1.0
	var foe := _stage.get_sprite(FOE_SIDE)
	var feet := foe.position
	var clock := TweenClock.new(get_tree())
	var done: Array[bool] = [false]
	var run := func() -> void:
		await _stage.dissolve_foe(FOE)
		done[0] = true
	run.call()
	var overlay := _stage.get_reveal_overlay()
	assert_not_null(overlay, "silhouette gardée pour le fondu")
	assert_eq(_art_path(overlay), GhostDisguise.TEXTURE_PATH)
	assert_eq(overlay.modulate.a, 1.0, "silhouette pleine au départ")
	assert_eq(foe.modulate.a, 0.0, "Ossatueur invisible au départ")
	assert_eq(_art_path(foe), _foe_art(), "le sprite porte déjà Ossatueur")
	assert_eq(foe.position, feet, "à l'ancre")
	var steps := roundi(BattleStage.REVEAL_DISSOLVE_DURATION / TweenClock.STEP)
	for i: int in steps / 2:
		clock.step()
	assert_between(foe.modulate.a, 0.3, 0.7, "à mi-fondu")
	assert_between(overlay.modulate.a, 0.3, 0.7)
	for i: int in steps / 2 - 1:
		clock.step()
	assert_false(done[0], "pas fini avant 1,0 s")
	clock.step()
	if not done[0]:
		clock.step()
	await wait_process_frames(1)
	assert_true(done[0], "fini à 1,0 s (au plus un pas de plus)")
	assert_eq(foe.modulate.a, 1.0, "artwork plein")
	assert_null(_stage.get_reveal_overlay(), "silhouette libérée")
	clock.release()


func test_reduced_motion_is_instant() -> void:
	_stage.speed_scale = 1.0
	_stage.reduce_motion = true
	var foe := _stage.get_sprite(FOE_SIDE)
	_stage.dissolve_foe(FOE)
	assert_null(_stage.get_reveal_overlay(), "aucun fondu")
	assert_eq(_art_path(foe), _foe_art(), "remplacement immédiat")
	assert_eq(foe.modulate.a, 1.0)


func test_nothing_without_a_battle_shown() -> void:
	_stage.reset()
	await _stage.dissolve_foe(FOE)
	assert_null(_stage.get_reveal_overlay())
	assert_false(_stage.get_sprite(FOE_SIDE).visible)


func test_no_orphans_after_a_reveal() -> void:
	await _stage.dissolve_foe(FOE)
	await _stage.exit()
	assert_no_new_orphans()
