extends GutTest
## Jalon 12 (jalon-12.md §2.8, T17) : point d'examen conditionnel des objets cachés « face à un
## indice ». [member InteractPoint.unless_flags] est recopié dans chaque [Interaction] ;
## [method Interaction.is_available] est faux dès qu'un de ces drapeaux est levé.

const FOUND := &"got_route_3_hidden_awakening"


func _point(flags: Array[StringName], size: Vector2i = Vector2i.ONE) -> InteractPoint:
	var point := InteractPoint.new()
	point.position = Grid.cell_to_world(Vector2i(36, 18))
	point.dialogue_id = &"route_3_hidden_awakening"
	point.size = size
	point.unless_flags = flags
	return autofree(point)


func test_default_point_has_no_condition() -> void:
	var point := InteractPoint.new()
	autofree(point)
	assert_true(point.unless_flags.is_empty(), "points existants : toujours une cible")
	for interaction: Interaction in point.to_interactions():
		assert_true(interaction.unless_flags.is_empty())
		assert_true(interaction.is_available(StoryFlags.new()))


func test_unless_flags_are_copied_to_every_cell() -> void:
	var point := _point([FOUND] as Array[StringName], Vector2i(2, 1))
	var interactions := point.to_interactions()
	assert_eq(interactions.size(), 2)
	for interaction: Interaction in interactions:
		assert_eq(interaction.unless_flags, [FOUND] as Array[StringName])
		assert_eq(interaction.kind, Interaction.Kind.EXAMINE)
		assert_eq(interaction.facing, Vector2i.ZERO, "toutes orientations")
	interactions[0].unless_flags.append(&"other")
	assert_eq(point.unless_flags, [FOUND] as Array[StringName], "copie indépendante")
	assert_eq(interactions[1].unless_flags, [FOUND] as Array[StringName])


func test_is_available_follows_the_flags() -> void:
	var interaction := _point([FOUND] as Array[StringName]).to_interactions()[0]
	assert_true(interaction.is_available(null), "nouvelle partie")
	var flags := StoryFlags.new()
	assert_true(interaction.is_available(flags), "pas encore trouvé")
	flags.set_flag(&"unrelated")
	assert_true(interaction.is_available(flags))
	flags.set_flag(FOUND)
	assert_false(interaction.is_available(flags), "trouvé : plus de cible")


func test_any_unless_flag_hides_the_target() -> void:
	var interaction := _point([&"a", &"b"] as Array[StringName]).to_interactions()[0]
	var flags := StoryFlags.new()
	flags.set_flag(&"b")
	assert_false(interaction.is_available(flags))


func test_interaction_built_in_code_is_always_available() -> void:
	var interaction := Interaction.new(Interaction.Kind.TALK, Vector2i(1, 1), &"mom")
	var flags := StoryFlags.new()
	flags.set_flag(FOUND)
	assert_true(interaction.is_available(flags), "PNJ et Pokémon : inchangés")


func test_unless_all_flags_hide_the_target_only_when_every_flag_is_up() -> void:
	var point := _point([] as Array[StringName])
	point.unless_all_flags = [&"a", &"b"] as Array[StringName]
	var interaction := point.to_interactions()[0]
	assert_eq(interaction.unless_all_flags, [&"a", &"b"] as Array[StringName])
	assert_true(interaction.is_available(null))
	var flags := StoryFlags.new()
	assert_true(interaction.is_available(flags))
	flags.set_flag(&"a")
	assert_true(interaction.is_available(flags), "un seul : toujours une cible")
	flags.set_flag(&"b")
	assert_false(interaction.is_available(flags), "tous levés : plus de cible")
