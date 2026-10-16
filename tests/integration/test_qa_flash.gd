extends GutTest
## Carte de QA du voile d'obscurité (J17 T10, docs/tech/jalon-17.md §2.17 ; PROVISOIRE, retirée
## au T28 avec ses départs `flash_qa*`) : la grotte `qa_flash` est obscure (`caves.json`), sa
## pièce d'entrée ne l'est pas ; passages dans les deux sens ; départs de débogage chargés et posés
## sur un point d'apparition réel ; dans le vrai Boot, le voile se pose en entrant depuis la pièce
## et le trou suit le joueur au bord de la carte (caméra bornée), le départ « lit » ouvre le halo.

const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const DIR := "res://tools/debug_start/"
const STARTS: Array[String] = ["flash_qa", "flash_qa_dark", "flash_qa_lit", "flash_qa_no_hm",
	"flash_qa_no_pokemon", "flash_qa_ko"]
const FADE := 0.05
const TIMEOUT := 12.0

var _boot: Boot
var _fades: Array[float] = []


func before_each() -> void:
	_fades = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-15T10:00:00")


func after_each() -> void:
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right", &"interact"]:
		Input.action_release(action)
	get_tree().paused = false
	SceneRouter.fade_out_duration = _fades[0]
	SceneRouter.fade_in_duration = _fades[1]
	GameState.clock = DeviceClock.new()


func _scene(map_id: StringName) -> GameMap:
	return autofree((load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()) as GameMap


func _load_start(name: String) -> DebugStart:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	var start := DebugStart.new()
	assert_true(start.load_file(DIR + name + ".json", data, items), "\n".join(start.get_errors()))
	return start


func _start_boot(map_id: StringName, spawn: StringName, facing: Vector2i) -> void:
	_boot = (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	_boot.save_system = SaveSystem.new(MemoryFs.new(), "user://test_qa_flash_save.json")
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	await wait_process_frames(2)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)


# --- Données et scènes -------------------------------------------------------------------------

func test_qa_cave_is_dark_and_its_entry_is_not() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	assert_true(caves.is_dark(&"qa_flash"))
	assert_false(caves.is_cave(&"qa_flash_entry"), "pièce éclairée hors grotte")
	var exit := caves.escape_target(&"qa_flash")
	assert_eq(exit.map, &"qa_flash_entry", "Corde Sortie : retour dans la pièce")
	assert_true(_scene(&"qa_flash_entry").has_spawn(exit.spawn))


func test_maps_are_linked_both_ways_with_a_glow() -> void:
	var cave := _scene(&"qa_flash")
	var entry := _scene(&"qa_flash_entry")
	assert_eq(cave.size, Vector2i(32, 16))
	assert_false(cave.interior)
	for warp: Node in cave.get_node(^"Warps").get_children():
		assert_eq(warp.get(&"target_map"), &"qa_flash_entry")
		assert_true(entry.has_spawn(warp.get(&"target_spawn")), str(warp.get(&"target_spawn")))
	for warp: Node in entry.get_node(^"Warps").get_children():
		assert_eq(warp.get(&"target_map"), &"qa_flash")
		assert_true(cave.has_spawn(warp.get(&"target_spawn")), str(warp.get(&"target_spawn")))
	assert_eq(cave.get_node(^"Warps").get_child_count(), 2)
	assert_eq(entry.get_node(^"Warps").get_child_count(), 2)
	var glows := 0
	for node: Node in cave.find_children("*", "Sprite2D", true, false):
		if node is LightGlow:
			glows += 1
	assert_between(glows, 1, VeilMath.MAX_SOURCES, "une lampe qui perce le voile")


func test_debug_starts_load_on_real_spawns() -> void:
	for name: String in STARTS:
		var start := _load_start(name)
		assert_true(_scene(start.map).has_spawn(start.spawn), "%s : %s" % [name, start.spawn])
		var state: Node = autofree(GameStateScript.new())
		state.clock = FixedClock.new("2026-10-15T10:00:00")
		start.apply(state, _pokemon())
		if name in ["flash_qa_no_pokemon", "flash_qa_ko"]:
			continue
		assert_eq(state.get_companion().species_id, &"pikachu", name + " : Pikachu compagnon")
	assert_eq(_load_start("flash_qa").veil, &"")
	assert_eq(_load_start("flash_qa_dark").veil, &"")
	assert_eq(_load_start("flash_qa_lit").veil, DebugStart.VEIL_LIT)


func _pokemon() -> PokemonData:
	var data := PokemonData.new()
	data.load_dir()
	return data


# --- Vrai Boot ---------------------------------------------------------------------------------

func test_entering_from_the_lit_room_lays_the_veil() -> void:
	await _start_boot(&"qa_flash_entry", &"from_qa_flash_w", Vector2i.UP)
	var darkness := _boot.get_darkness()
	assert_false(darkness.is_dark(), "pièce éclairée : aucun voile")
	assert_false(darkness.get_veil().visible)
	var player := _boot.get_player()
	assert_true(player.script_step(Vector2i.UP), "pas vers le passage")
	var runner := _boot.get_dialogue_runner()
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"qa_flash" \
		and runner.is_running(), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"qa_flash")
	assert_eq(runner.get_dialogue_id(), FlashDirector.WARN_DIALOGUE, "sans CS05 : avertissement")
	await _close_dialogue()
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_true(darkness.is_dark(), "grotte obscure : voile posé")
	assert_true(darkness.get_veil().visible)
	assert_false(darkness.is_lit(), "Flash éteinte (partie neuve : pas de CS05)")
	await wait_process_frames(2)
	var body := VeilMath.body_center(player.global_position,
		darkness.get_profile().center_offset)
	assert_eq(darkness.get_veil().get_center(), body, "trou centré sur le joueur")
	# Joueur au bord de la carte (coin sud-ouest) : la caméra est bornée, le trou ne suit pas
	# l'écran.
	var viewport := get_viewport()
	var view := viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()
	assert_true(darkness.get_veil().get_view_rect().encloses(view), "la vue entière est voilée")
	assert_ne(view.get_center().round(), body.round(), "trou décentré à l'écran (bord)")
	# Retour dans la pièce : voile retiré.
	assert_true(player.script_step(Vector2i.DOWN))
	await wait_until(func() -> bool: return _boot.get_map().map_id == &"qa_flash_entry" \
		and _boot.is_stable(), TIMEOUT)
	assert_false(darkness.is_dark())
	assert_false(darkness.get_veil().visible)
	assert_false(darkness.is_processing())


func _close_dialogue() -> void:
	var runner := _boot.get_dialogue_runner()
	for i: int in 10:
		await wait_process_frames(3)
		if not runner.is_running():
			return
		Input.action_press(&"interact")
		await wait_process_frames(2)
		Input.action_release(&"interact")
