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


## Déblocages de débogage (jalon 6 T4, [DebugUnlocks]) : même garde que le départ de débogage.
func test_boot_ignores_an_existing_debug_unlock_under_gut() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	boot.debug_unlocks_path = "res://tests/fixtures/debug_unlocks/pokedex.json"
	assert_true(FileAccess.file_exists(boot.debug_unlocks_path), "le fichier existe bien")
	add_child_autofree(boot)
	var menu := boot.get_menu_director()
	assert_false((menu.build_dashboard() as DashboardView).cards.any(
		func(card: MenuCardView) -> bool: return card.screen == MenuRoute.POKEDEX),
		"pas de carte Pokédex : le fichier n'est pas lu sous GUT")


func test_default_unlock_path_is_the_user_file() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	assert_eq(boot.debug_unlocks_path, DebugUnlocks.USER_PATH)
	boot.free()
