extends GutTest
## Notes de la Poké Flûte (jalon 21, `jalon-21.md` §2.3, T19) : présentation pure sur le modèle
## de [RubbleBurst] — trois notes peintes (série 23) au-dessus du joueur, ≈ 1,5 s en temps simulé
## (pas fini avant, au plus un pas de plus), instantané à la vitesse 0, nœud libéré à la fin.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")


func _player_stub() -> Node2D:
	var parent: Node2D = add_child_autofree(Node2D.new())
	var player := Node2D.new()
	player.position = Vector2(480, 288)
	parent.add_child(player)
	return player


func test_three_painted_notes_above_the_player() -> void:
	var player := _player_stub()
	var notes := FluteNotes.spawn_over(player)
	assert_eq(notes.get_parent(), player.get_parent(), "frère du joueur")
	assert_eq(notes.global_position, player.global_position)
	assert_eq(notes.get_notes().size(), FluteNotes.NOTE_COUNT)
	assert_eq(FluteNotes.NOTE_COUNT, 3)
	for i: int in notes.get_notes().size():
		var note := notes.get_notes()[i]
		assert_not_null(note.texture, "image peinte")
		assert_eq(note.texture.resource_path,
			"res://assets/sprites/effects/poke_flute_note_%d.png" % (i + 1))
		assert_lt(note.position.y, -100.0, "au-dessus de la tête")
	assert_eq(notes.z_index, WorldLighting.Z_ABOVE_VEIL)
	notes.free()


func test_without_parent_nothing_is_spawned() -> void:
	var lonely := Node2D.new()
	assert_null(FluteNotes.spawn_over(lonely))
	lonely.free()


func test_lasts_one_and_a_half_second_in_simulated_time() -> void:
	var notes := FluteNotes.spawn_over(_player_stub())
	watch_signals(notes)
	var clock := TweenClock.new(get_tree())
	notes.play(1.0)
	var expected := roundi(FluteNotes.DURATION / TweenClock.STEP)
	for i: int in expected / 2:
		clock.step()
	var shown := notes.get_notes().filter(func(n: Sprite2D) -> bool: return n.modulate.a > 0.0)
	assert_gt(shown.size(), 0, "des notes visibles à mi-parcours")
	for i: int in expected / 2 - 1:
		clock.step()
	assert_false(notes.is_queued_for_deletion(), "pas fini avant 1,5 s")
	clock.step()
	if not notes.is_queued_for_deletion():
		clock.step()
	assert_true(notes.is_queued_for_deletion(), "fini à 1,5 s (au plus un pas de plus)")
	assert_signal_emitted(notes, "finished")
	clock.release()


func test_speed_zero_is_instant() -> void:
	var notes := FluteNotes.spawn_over(_player_stub())
	await notes.play(0.0)
	assert_true(notes.is_queued_for_deletion(), "libéré tout de suite")
