extends GutTest
## Autoload GameState (jalon 3A §2.6) : drapeaux de la session, nouvelle partie, aucune
## dépendance à un autre autoload.

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


func test_registered_as_autoload() -> void:
	assert_eq(ProjectSettings.get_setting("autoload/GameState"), "*" + SCRIPT_PATH)
	assert_not_null(get_tree().root.get_node_or_null(^"GameState"))
