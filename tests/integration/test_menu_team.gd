extends GutTest
## L'Équipe jouable (jalon-06.md §6.7, T8) avec la vraie scène Boot, un SaveSystem en mémoire
## et l'écran factice : réordonner, favori, sauvegarde, et le combat suivant qui envoie le
## nouveau premier Pokémon valide (sprite d'entrée compris).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const FakeMenu := preload("res://tests/helpers/fake_trainer_menu.gd")
const SAVE_PATH := "user://test_t8_save.json"
const DATE := "2026-10-03T10:00:00"
const FADE := 0.05
const TIMEOUT := 12.0
const SPECIES: Array[StringName] = [&"charmander", &"pidgey", &"rattata"]

var _fs: MemoryFs
var _save: SaveSystem
var _boot: Boot
var _menu: MenuDirector
var _screen: Node
var _player: Player
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new(DATE)
	_fs = MemoryFs.new()
	_save = SaveSystem.new(_fs, SAVE_PATH)
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = _save
	_boot.start_map = &"route_1"
	_boot.start_spawn = &"from_pallet_w"
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_dialogue_runner().chars_per_second = 0.0
	_player = _boot.get_player()
	_menu = _boot.get_menu_director()
	_screen = autofree(FakeMenu.new())
	_screen.wire(_menu)
	await wait_process_frames(2)
	_boot.get_battle_director().speed_scale = 0.0
	_boot.get_battle_stage().speed_scale = 0.0
	_boot.get_battle_hud().speed_scale = 0.0
	_boot.get_battle_hud().haptics_enabled = false
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


func after_each() -> void:
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"run"]:
		Input.action_release(action)


func _new_game(seed: int) -> void:
	GameState.new_game(seed)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.starter_species = &"charmander"
	var data := _boot.get_pokemon_data()
	for species: StringName in SPECIES:
		GameState.party.add(PokemonFactory.create(data, species, 5, GameRng.new(7)))


func _writes() -> int:
	var count := 0
	for entry: String in _fs.journal:
		if entry.begins_with("rename ") and entry.ends_with("-> " + SAVE_PATH):
			count += 1
	return count


func _species_order() -> Array[StringName]:
	var order: Array[StringName] = []
	for pokemon: Pokemon in GameState.party.get_all():
		order.append(pokemon.species_id)
	return order


## Graine dont le premier pas dans l'herbe déclenche une rencontre (tirage non nul).
func _encounter_seed() -> int:
	var table := _boot.get_encounter_library().get_table(&"route_1", &"grass")
	for seed: int in range(0, 4000):
		if table.roll(GameRng.new(seed)) != null:
			return seed
	return -1


func _walk_into_grass() -> void:
	var map := _boot.get_map()
	var grid := map.get_grid()
	var step: Array[Vector2i] = []
	for y: int in range(1, map.size.y - 1):
		for x: int in range(1, map.size.x - 1):
			var g := Vector2i(x, y)
			var below := g + Vector2i.DOWN
			if step.is_empty() and grid.is_tall_grass(g) and grid.is_free(g) \
					and grid.is_free(below) and not grid.is_tall_grass(below):
				step = [below, g]
	assert_false(step.is_empty(), "une case d'herbe avec un accès au sud")
	_player.enter_map(grid, step[0], Vector2i.UP, map.get_pixel_rect())
	var enc := _boot.get_encounter_director()
	Input.action_press(&"move_up")
	await wait_until(func() -> bool: return enc.is_running(), 5.0)
	Input.action_release(&"move_up")
	assert_true(enc.is_running(), "une rencontre s'est déclenchée")
	await wait_process_frames(3)


func _lead_sprite_path() -> String:
	var sprite := _boot.get_battle_stage().get_sprite(BattleEvent.SideId.PLAYER)
	return sprite.texture.resource_path if sprite.texture != null else ""


func _open_team() -> void:
	assert_true(_menu.open(MenuRoute.team()))
	await wait_process_frames(1)


# --- Affichage ----------------------------------------------------------------------------

func test_the_team_route_sends_the_team_view_and_not_a_placeholder() -> void:
	_new_game(1)
	await _open_team()
	assert_eq(_screen.teams.size(), 1)
	assert_eq(_screen.team_selections, [0] as Array[int])
	assert_eq(_screen.teams[0].size(), 3)
	assert_true(_screen.placeholders.is_empty(), "plus d'écran « À venir » pour l'Équipe")
	_menu.close()
	assert_true(_menu.go(MenuRoute.team(2)) == false, "fermé : aucune navigation")
	assert_true(_menu.open(MenuRoute.team(2)))
	assert_eq(_screen.team_selections[-1], 2, "l'index de la route est la sélection")
	_menu.close()


# --- Réordonner ---------------------------------------------------------------------------

func test_reordering_then_closing_saves_and_the_next_battle_sends_the_new_lead() -> void:
	var seed := _encounter_seed()
	assert_gt(seed, -1)
	_new_game(seed)
	await wait_process_frames(2)
	var writes := _writes()
	await _open_team()
	_screen.team_member_selected.emit(0)
	_screen.team_member_moved.emit(0, 2)
	assert_eq(_species_order(), [&"rattata", &"pidgey", &"charmander"] as Array[StringName])
	assert_eq(_screen.teams.size(), 2, "vue réémise après l'échange")
	assert_eq(_screen.team_selections[-1], 2, "la sélection suit le Pokémon")
	assert_eq(_screen.teams[-1].members[0].species_id, &"rattata")
	_menu.close()
	await wait_process_frames(4)
	assert_eq(_writes(), writes + 1, "autosave à la fermeture")
	var saved: Dictionary = _save.read()
	var order: Array[String] = []
	for entry: Variant in saved["party"]:
		order.append(String((entry as Dictionary)["species"]))
	assert_eq(order, ["rattata", "pidgey", "charmander"] as Array[String], "sauvegarde")
	await _walk_into_grass()
	assert_eq(GameState.party.get_lead().species_id, &"rattata")
	assert_eq(_lead_sprite_path(), BattleStage.sprite_path(&"rattata", true),
		"l'animation d'entrée montre le nouveau premier")


func test_the_next_battle_sends_the_first_able_pokemon_of_the_new_order() -> void:
	var seed := _encounter_seed()
	_new_game(seed)
	await _open_team()
	assert_true(_menu.move_member(0, 2))
	_menu.close()
	GameState.party.get_at(0).hp = 0
	await _walk_into_grass()
	assert_eq(_lead_sprite_path(), BattleStage.sprite_path(&"pidgey", true),
		"le premier K.O. est sauté : le suivant valide entre")


func test_invalid_moves_change_nothing() -> void:
	_new_game(1)
	await wait_process_frames(3)
	var writes := _writes()
	await _open_team()
	assert_false(_menu.move_member(1, 1))
	assert_false(_menu.move_member(0, 5))
	assert_false(_menu.move_member(-1, 0))
	assert_false(_menu.toggle_favorite(9))
	assert_eq(_screen.teams.size(), 1, "aucune vue réémise")
	_menu.close()
	await wait_process_frames(3)
	assert_eq(_writes(), writes, "rien n'a changé : pas d'autosave")


# --- Favori -------------------------------------------------------------------------------

func test_a_favorite_is_saved_and_read_back() -> void:
	_new_game(1)
	await wait_process_frames(3)
	var writes := _writes()
	await _open_team()
	_screen.team_favorite_toggled.emit(1)
	assert_true(GameState.party.get_at(1).favorite)
	assert_true(_screen.teams[-1].members[1].favorite, "vue réémise")
	_menu.close()
	await wait_process_frames(4)
	assert_eq(_writes(), writes + 1)
	var saved: Dictionary = _save.read()
	assert_false(saved.is_empty())
	GameState.new_game(2)
	assert_true(GameState.load_dict(saved, _boot.get_pokemon_data()))
	assert_eq(GameState.party.size(), 3)
	assert_false(GameState.party.get_at(0).favorite)
	assert_true(GameState.party.get_at(1).favorite, "favori relu")
	await _open_team()
	_screen.team_favorite_toggled.emit(1)
	assert_false(GameState.party.get_at(1).favorite, "inversé une seconde fois")
	_menu.close()
