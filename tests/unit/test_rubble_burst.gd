extends GutTest
## L'éboulis des gravats (jalon 12, T20 ; `jalon-12.md` §2.5, dossier 15 §6) : présentation pure
## sur le modèle de [GrassRustle] — quelques cailloux et un peu de poussière, ≈ 0,6 s en temps
## simulé (pas fini avant, au plus un pas de plus), instantané à la vitesse 0, nœud libéré à la
## fin, aucune texture.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")


func test_spawn_places_the_burst_under_the_feet() -> void:
	var parent: Node2D = add_child_autofree(Node2D.new())
	var burst := RubbleBurst.spawn(parent, Vector2(480, 288))
	assert_eq(burst.get_parent(), parent)
	assert_eq(burst.global_position, Vector2(480, 288))
	assert_eq(burst.get_piece_count(), RubbleBurst.PEBBLE_COUNT + RubbleBurst.DUST_COUNT)
	for child: Node in burst.get_children():
		assert_true(child is Polygon2D, "formes simples, sans texture")
	burst.free()


func test_lasts_about_six_tenths_of_a_second_in_simulated_time() -> void:
	var parent: Node2D = add_child_autofree(Node2D.new())
	var burst := RubbleBurst.spawn(parent, Vector2.ZERO)
	var clock := TweenClock.new(get_tree())
	burst.burst(1.0)
	var expected := roundi(RubbleBurst.DURATION / TweenClock.STEP)
	for i: int in expected - 1:
		clock.step()
	assert_false(burst.is_queued_for_deletion(), "pas fini avant 0,6 s")
	# Les cailloux ont quitté la case, la poussière a gonflé.
	var moved := false
	for child: Node in burst.get_children():
		var shape := child as Polygon2D
		if shape.position.length() > RubbleBurst.ROLL_DISTANCE * 0.8:
			moved = true
	assert_true(moved, "les cailloux roulent hors de la case")
	clock.step()
	if not burst.is_queued_for_deletion():
		clock.step()
	assert_true(burst.is_queued_for_deletion(), "fini à 0,6 s (au plus un pas de plus)")
	clock.release()
	assert_lte(RubbleBurst.DURATION, 2.0, "intro ≤ 2 s (dossier 04)")


func test_speed_zero_is_instant() -> void:
	var parent: Node2D = add_child_autofree(Node2D.new())
	var burst := RubbleBurst.spawn(parent, Vector2.ZERO)
	await burst.burst(0.0)
	assert_true(burst.is_queued_for_deletion(), "libéré tout de suite")
