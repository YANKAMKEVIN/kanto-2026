extends GutTest
## Compagnon et destination « à venir » (bug de la QA finale 12D sur S21, `etat-projet.md` J12) :
## vraie scène Boot. Le joueur pousse le bord est → écran « … — À venir »
## → retour sur la case de sortie. L'écran ouvrait une transition ([signal SceneRouter.transition_started] :
## le compagnon rentre) sans jamais la fermer (ni [signal SceneRouter.map_entered], aucune carte ne
## change) : le compagnon restait caché jusqu'au changement de carte suivant. Il doit être visible
## derrière le joueur au plus tard au premier pas qui libère une case (règle J11).
## Vérifié aux raccords ouest et est du bord sud d'Azuria (jalon 14 T20b : « ROUTE 5 — À venir »,
## couloir de 3 cases, spawns `from_route_5_w|c|e`) ; jusqu'au T15 du J14 c'était le bord est de
## la Route 24 (« ROUTE 25 »).

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const SAVE_PATH := "user://test_companion_coming_soon_save.json"
const FADE := 0.05
const TIMEOUT := 12.0
const MAP := &"cerulean_city"

var _boot: Boot
var _saved_router: Array = []


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration,
		SceneRouter.coming_soon_enabled]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	SceneRouter.coming_soon_enabled = true
	GameState.clock = FixedClock.new("2026-10-14T10:00:00")


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right"]:
		Input.action_release(action)
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	SceneRouter.coming_soon_enabled = _saved_router[2]
	GameState.clock = DeviceClock.new()


func test_west_gate_companion_follows_again_after_the_screen() -> void:
	await _check_gate(&"from_route_5_w")


func test_east_gate_companion_follows_again_after_the_screen() -> void:
	await _check_gate(&"from_route_5_e")


func test_the_companion_follows_again_after_two_visits() -> void:
	await _check_gate(&"from_route_5_c", 2)


## Boot sur [param spawn] (case du raccord, tourné vers le nord), compagnon choisi ; un pas vers
## l'ouest (il suit), retour au bord, poussée → écran → retour ; [param visits] fois. Puis un pas
## vers l'ouest : il est montré, juste derrière le joueur.
func _check_gate(spawn: StringName, visits: int = 1) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), SAVE_PATH)
	_boot.start_map = MAP
	_boot.start_spawn = spawn
	_boot.start_facing = Vector2i.UP
	add_child_autofree(_boot)
	_boot.get_coming_soon_screen().hold_duration = 0.2
	_boot.get_coming_soon_screen().fade_duration = 0.05
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	var companion := _boot.get_companion_controller()
	var player := _boot.get_player()
	GameState.flags.set_flag(&"starter_chosen")
	var lead := PokemonFactory.create(_boot.get_pokemon_data(), &"pikachu", 12, GameRng.new(3))
	GameState.party.add(lead)
	GameState.set_companion(lead)
	companion.refresh()
	var gate := player.get_cell()
	# Un pas vers le nord : le compagnon suit (extérieur).
	await _step(player, companion, &"move_up")
	assert_true(companion.is_shown(), "%s : il suit avant l'écran" % spawn)
	var screen := _boot.get_coming_soon_screen()
	for visit: int in visits:
		if player.get_cell() != gate:
			await _step(player, companion, &"move_down")
		player.face(Vector2i.DOWN)
		Input.action_press(&"move_down")
		await wait_until(func() -> bool: return screen.is_showing(), TIMEOUT)
		Input.action_release(&"move_down")
		assert_true(screen.is_showing(), "visite %d : écran « à venir »" % visit)
		await wait_until(func() -> bool: return not screen.is_showing() \
			and not SceneRouter.is_transitioning(), TIMEOUT)
		await wait_process_frames(2)
		assert_eq(_boot.get_map().map_id, MAP, "toujours à Azuria")
		assert_eq(player.get_cell(), gate, "retour sur la case de sortie")
		assert_eq(player.get_facing(), Vector2i.UP)
	# Premier pas qui libère une case : il est de nouveau là, derrière le joueur.
	await _step(player, companion, &"move_up")
	assert_true(companion.is_shown(), "%s : le compagnon suit de nouveau après l'écran" % spawn)
	assert_eq(companion.get_node_2d().get_cell(), player.get_cell() + Vector2i.DOWN,
		"juste derrière le joueur")
	assert_push_error_count(0)


## Un pas dans la direction de [param action], attendu jusqu'à l'arrêt du joueur et du compagnon.
func _step(player: Player, companion: CompanionController, action: StringName) -> void:
	var steps := [0]
	var count := func(_cell: Vector2i) -> void: steps[0] += 1
	player.moved.connect(count)
	Input.action_press(action)
	await wait_until(func() -> bool: return steps[0] >= 1, TIMEOUT)
	Input.action_release(action)
	player.moved.disconnect(count)
	await wait_until(func() -> bool: return not player.is_moving() \
		and not companion.get_node_2d().is_moving(), TIMEOUT)
	await wait_process_frames(2)
