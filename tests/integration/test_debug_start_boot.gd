extends GutTest
## Départ de débogage (jalon 5 T9) : sous GUT, Boot ne l'applique jamais, même quand le
## fichier existe (Boot n'est pas la scène principale lancée par le moteur).


func test_boot_ignores_an_existing_debug_start_under_gut() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	boot.debug_start_path = "res://tests/fixtures/debug_start/valid.json"
	assert_true(FileAccess.file_exists(boot.debug_start_path), "le fichier existe bien")
	add_child_autofree(boot)
	assert_eq(boot.get_map().map_id, &"player_house_2f", "départ normal, dans la chambre")
	assert_eq(GameState.party.size(), 0, "nouvelle partie : équipe vide")
	assert_false(GameState.flags.has_flag(&"starter_chosen"))
	assert_eq(GameState.bag.count_of(&"poke_ball"), 0)


func test_default_path_is_the_user_file() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	assert_eq(boot.debug_start_path, DebugStart.USER_PATH)
	boot.free()
