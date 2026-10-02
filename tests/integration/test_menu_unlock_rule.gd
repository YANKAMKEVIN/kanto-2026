extends GutTest
## Règle de déblocage du Menu Dresseur appliquée avec le vrai Boot (jalon-06.md §4), partie T4 :
## cartes du tableau de bord selon l'équipe et le Pokédex, route Pokédex refusée sans
## déblocage, déblocage de débogage sans drapeau d'histoire ni sauvegarde.
##
## RESTE APRÈS LA FUSION DU T3 (vrais écrans, §4) : ouvrir le menu, parcourir tous les écrans
## et relever le texte de tous les Label visibles (aucun « Pokédex », « vus », « capturés »,
## « habitat » sans déblocage) ; aucun toast Pokédex après une observation.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const SAVE_PATH := "user://test_t4_unlock_save.json"

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _menu: MenuDirector


func after_each() -> void:
	get_tree().paused = false


func _start(debug_unlock: bool = false) -> void:
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = _save
	if debug_unlock:
		_boot.force_debug_unlocks = true
		_boot.debug_unlocks_path = "res://tests/fixtures/debug_unlocks/pokedex.json"
	add_child_autofree(_boot)
	_menu = _boot.get_menu_director()
	await wait_until(func() -> bool: return _boot.is_stable(), 12.0)


func _cards() -> Array[StringName]:
	var screens: Array[StringName] = []
	for card: MenuCardView in _menu.build_dashboard().cards:
		screens.append(card.screen)
	return screens


func _give_starter() -> void:
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 5,
		GameRng.new(1)))


func test_new_game_has_four_cards_and_no_dex_line() -> void:
	await _start()
	assert_eq(_cards(), [&"bag", &"map", &"trainer", &"settings"] as Array[StringName])
	assert_eq(_menu.build_dashboard().dex_text, "", "pas de ligne vus · capturés")
	assert_null(_menu.build_dashboard().lead, "pas de Pokémon de tête")


func test_with_a_team_but_without_the_dex_five_cards() -> void:
	await _start()
	_give_starter()
	assert_eq(_cards(), [&"team", &"bag", &"map", &"trainer", &"settings"] as Array[StringName])
	assert_eq(_menu.build_dashboard().dex_text, "")
	assert_not_null(_menu.build_dashboard().lead)


func test_seen_and_caught_data_keeps_filling_silently() -> void:
	await _start()
	_give_starter()
	GameState.record_seen(&"pidgey", &"route_1")
	GameState.record_caught(&"charmander", &"oak_lab")
	assert_eq(GameState.pokedex.seen_count(), 2, "les données continuent")
	assert_eq(_menu.build_dashboard().dex_text, "", "mais rien n'est montré")
	assert_eq(_cards().size(), 5)


func test_the_dex_route_is_refused_without_unlock() -> void:
	await _start()
	_give_starter()
	assert_true(_menu.open())
	assert_false(_menu.go(MenuRoute.pokedex()), "aucun lien ne peut y mener")
	assert_eq(_menu.get_navigator().current().screen, MenuRoute.DASHBOARD)
	_menu.close()


func test_with_the_story_flag_six_cards_and_the_route_opens() -> void:
	await _start()
	_give_starter()
	GameState.flags.set_flag(StoryFlags.POKEDEX_ACTIVATED)
	assert_eq(_cards().size(), 6)
	assert_ne(_menu.build_dashboard().dex_text, "")
	assert_true(_menu.open())
	assert_true(_menu.go(MenuRoute.pokedex()))
	_menu.close()


func test_debug_unlock_shows_the_dex_without_the_story_flag_nor_in_the_save() -> void:
	await _start(true)
	_give_starter()
	assert_eq(_cards().size(), 6, "carte Pokédex débloquée par le débogage")
	assert_true(_menu.open())
	assert_true(_menu.go(MenuRoute.pokedex()), "l'écran s'ouvre")
	assert_false(GameState.flags.has_flag(StoryFlags.POKEDEX_ACTIVATED),
		"jamais un drapeau d'histoire")
	var flags: Array = GameState.to_dict().get("flags", [])
	assert_false(flags.has(String(StoryFlags.POKEDEX_ACTIVATED)), "pas dans la sauvegarde")
	_menu.close()
