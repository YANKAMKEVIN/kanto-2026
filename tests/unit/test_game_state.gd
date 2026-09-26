extends GutTest
## Autoload GameState (jalon 3A §2.6) : drapeaux de la session, nouvelle partie, aucune
## dépendance à un autre autoload. Jalon 4 (§3.9, T1) : équipe, starter, aléatoire à graine.

const SCRIPT_PATH := "res://game/autoload/game_state.gd"


func _make() -> Node:
	return autofree((load(SCRIPT_PATH) as GDScript).new())


func test_starts_with_empty_flags() -> void:
	var state := _make()
	assert_true(state.flags is StoryFlags)
	assert_eq(state.flags.to_array().size(), 0)


func test_new_game_clears_flags() -> void:
	var state := _make()
	state.flags.set_flag(&"mom_greeted")
	state.flags.set_flag(&"rival_met")
	state.new_game()
	assert_false(state.flags.has_flag(&"mom_greeted"))
	assert_false(state.flags.has_flag(&"rival_met"))
	assert_eq(state.flags.to_array().size(), 0)


func test_new_game_keeps_same_flags_instance() -> void:
	# Les systèmes reçoivent GameState.flags par injection : l'instance ne change pas.
	var state := _make()
	var flags: StoryFlags = state.flags
	state.new_game()
	assert_same(state.flags, flags)


func test_does_not_reference_scene_router() -> void:
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	assert_false(source.contains("SceneRouter"), "aucune référence au routeur")
	assert_false(source.contains("scene_router"), "aucune référence au routeur")


func test_does_not_reference_any_other_autoload() -> void:
	var source := FileAccess.get_file_as_string(SCRIPT_PATH)
	for setting: Dictionary in ProjectSettings.get_property_list():
		var key: String = setting["name"]
		if not key.begins_with("autoload/") or key == "autoload/GameState":
			continue
		var autoload := key.trim_prefix("autoload/")
		assert_false(source.contains(autoload), "aucune référence à %s" % autoload)


func test_starts_with_empty_party_no_starter_and_a_rng() -> void:
	var state := _make()
	assert_true(state.party is Party)
	assert_eq(state.party.size(), 0)
	assert_eq(state.starter_species, &"")
	assert_true(state.rng is GameRng)


func test_new_game_clears_party_and_starter() -> void:
	var state := _make()
	var party: Party = state.party
	var data := PokemonData.new()
	assert_true(data.load_dir(), "données Pokémon")
	state.party.add(PokemonFactory.create(data, &"bulbasaur", 5, GameRng.new(1)))
	state.starter_species = &"bulbasaur"
	assert_eq(state.party.size(), 1)
	state.new_game()
	assert_eq(state.party.size(), 0, "équipe vide")
	assert_same(state.party, party, "même instance d'équipe (injectée)")
	assert_eq(state.starter_species, &"", "pas de starter")


func test_new_game_changes_the_seed() -> void:
	var state := _make()
	var seeds := {}
	var before: GameRng = state.rng
	for i: int in 5:
		state.new_game()
		seeds[state.rng.get_seed()] = true
	assert_ne(state.rng, before, "aléatoire neuf")
	assert_gt(seeds.size(), 1, "graines tirées au hasard")


func test_new_game_with_a_seed_is_reproducible() -> void:
	var state := _make()
	state.new_game(42)
	assert_eq(state.rng.get_seed(), 42)
	var first: Array[int] = []
	for i: int in 5:
		first.append(state.rng.roll(100))
	state.new_game(42)
	assert_eq(state.rng.get_seed(), 42, "même graine")
	var second: Array[int] = []
	for i: int in 5:
		second.append(state.rng.roll(100))
	assert_eq(second, first, "mêmes tirages")


func test_registered_as_autoload() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/GameState"), "*" + SCRIPT_PATH)
	assert_not_null(get_tree().root.get_node_or_null(^"GameState"))
