extends GutTest
## Les sept Dresseurs de la Route 9 (jalon 18 T18, jalon-18.md §4.3 ; dossier 21 §3.3) sur la
## **vraie scène avec ses PNJ** (`data/npcs/route_9.json`) :
## - cases, orientations et visions de la grille `tools/plans/route_9.txt` ; la vue réelle
##   (`TrainerRules.sight_distance` sur la vraie grille) = la vue de la grille ; aucun PNJ, objet
##   ni Pokémon d'ambiance sur une ligne de vue ;
## - **Lou (R9-1) et Benoît (R9-5) inévitables** : avec tous les PNJ posés, aucun chemin hors de
##   leur vue ne mène d'Azuria à la Route 10 ; **R9-2, 3, 4, 6 et 7 évitables**, un par un et tous
##   ensemble ; un Dresseur arrêté à n'importe quelle distance de son approche ne ferme jamais la
##   route ;
## - données : équipes et récompenses du §3.3, IA `random`, modèles peints, répliques en données ;
## - Boot réel : Lou voit le joueur au goulet et lance sa scène (réplique « avant ») ; un Dresseur
##   battu ne défie plus et dit sa réplique « après ».

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const MAP_PATH := "res://game/world/maps/route_9.tscn"
const PLAN_PATH := "res://tools/plans/route_9.txt"
const START := "res://tools/debug_start/route_9.json"
const SAVE_PATH := "user://test_route_9_trainers_save.json"
const SIZE := Vector2i(80, 36)
const WEST: Array[Vector2i] = [Vector2i(0, 22), Vector2i(0, 23), Vector2i(0, 24)]
const EAST: Array[Vector2i] = [Vector2i(79, 12), Vector2i(79, 13), Vector2i(79, 14)]
const INF := 1 << 30
const FADE := 0.05
const TIMEOUT := 12.0
## Identifiant de grille → [Dresseur, modèle peint, nom, équipe, ₽] (dossier 21 §3.3, niveaux
## recalés au T22).
const TRAINERS := {
	"lou": [&"route_9_lass_lou", "lass", "Jeune Dresseuse Lou",
		[[&"oddish", 18], [&"bellsprout", 18], [&"oddish", 18], [&"bellsprout", 18]], 360],
	"adam": [&"route_9_camper_adam", "camper", "Campeur Adam",
		[[&"mankey", 20], [&"charmander", 21]], 420],
	"jules": [&"route_9_camper_jules", "camper", "Campeur Jules",
		[[&"rattata", 26], [&"ekans", 26], [&"sandshrew", 26]], 520],
	"zoe": [&"route_9_lass_zoe", "lass", "Jeune Dresseuse Zoé", [[&"meowth", 26]], 520],
	"benoit": [&"route_9_hiker_benoit", "hiker", "Montagnard Benoît",
		[[&"machop", 25], [&"onix", 23]], 805],
	"gilles": [&"route_9_hiker_gilles", "hiker", "Montagnard Gilles",
		[[&"geodude", 16], [&"machop", 16], [&"geodude", 16]], 560],
	"noa": [&"route_9_scout_noa", "scout", "Scout Noa",
		[[&"beedrill", 19], [&"beedrill", 19]], 228],
}
const UNAVOIDABLE: Array[String] = ["lou", "benoit"]
const AVOIDABLE: Array[String] = ["adam", "jules", "zoe", "gilles", "noa"]

var _plan: PlanGrid
var _map: GameMap
var _grid: GridWorld
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _scenes: Array[StringName] = []
var _saved_router: Array = []


func before_all() -> void:
	_plan = PlanGrid.new()
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()


func after_all() -> void:
	_map.free()


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-13T15:00:00")
	_fs = MemoryFs.new()
	_pages.clear()
	_speakers.clear()
	_scenes.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Vraie scène et ses PNJ ----------------------------------------------------------------

func _spec(grid_id: String) -> NpcSpec:
	return _map.get_npc(StringName(grid_id)).get_spec()


## Relief de la scène + case de chaque PNJ posé + [param blocked].
func _real_world(blocked: Dictionary = {}) -> GridWorld:
	var grid := GridPaths.relief(_grid, SIZE)
	for npc: Npc in _map.get_npcs():
		grid.set_solid(npc.get_cell())
	for cell: Vector2i in blocked:
		grid.set_solid(cell)
	return grid


## Cases d'où [param spec] voit le joueur, sur la vraie grille (les PNJ coupent la vue).
func _real_sight(spec: NpcSpec) -> Dictionary:
	var seen: Dictionary = {}
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if _grid.is_solid(cell) or _grid.is_occupied(cell):
				continue
			if TrainerRules.sight_distance(_grid, spec.cell, spec.facing, spec.sight, cell) > 0:
				seen[cell] = true
	return seen


## Ligne de vue de la grille (s'arrête au premier obstacle).
func _planned_sight(id: String) -> Dictionary:
	var facing := Grid.direction_from_name(_plan.attr(id, "facing"))
	var origin := _plan.cell_of(id)
	var cells: Dictionary = {}
	for k: int in range(1, int(_plan.attr(id, "sight")) + 1):
		var cell := origin + facing * k
		if _grid.is_solid(cell):
			break
		cells[cell] = true
	return cells


func _nearest(dist: Dictionary, cells: Array[Vector2i]) -> int:
	var best := INF
	for cell: Vector2i in cells:
		best = mini(best, int(dist.get(cell, INF)))
	return best


func _reaches(blocked: Dictionary) -> bool:
	return _nearest(GridPaths.distances(_real_world(blocked), WEST), EAST) < INF


func test_seven_trainers_on_their_grid_cells() -> void:
	var count := 0
	for npc: Npc in _map.get_npcs():
		if npc.get_spec().is_trainer():
			count += 1
	assert_eq(count, 7, "sept Dresseurs")
	for id: String in TRAINERS:
		var npc := _map.get_npc(StringName(id))
		assert_not_null(npc, "%s posé" % id)
		if npc == null:
			continue
		var spec := npc.get_spec()
		assert_eq(spec.cell, _plan.cell_of(id), "%s : case de la grille" % id)
		assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(id, "facing")), id)
		assert_eq(spec.sight, int(_plan.attr(id, "sight")), "%s : vision" % id)
		assert_eq(spec.trainer_id, TRAINERS[id][0])
		assert_eq(String(_plan.attr(id, "trainer")), String(TRAINERS[id][0]), id)
		assert_false(spec.has_rematch(), "%s : aucune reprise (Sbires seulement)" % id)
		assert_false(spec.leaves, "%s : reste après sa défaite" % id)


func test_real_sight_is_the_grid_sight_and_stays_clear() -> void:
	for id: String in TRAINERS:
		var spec := _spec(id)
		var real := _real_sight(spec)
		var planned := _planned_sight(id)
		assert_eq(real.size(), spec.sight, "%s : vue dégagée" % id)
		var real_cells: Array = real.keys()
		var planned_cells: Array = planned.keys()
		real_cells.sort()
		planned_cells.sort()
		assert_eq(real_cells, planned_cells, "%s : vue réelle = vue de la grille" % id)
		for npc: Npc in _map.get_npcs():
			assert_false(real.has(npc.get_cell()), "%s sur la vue de %s" % [npc.get_id(), id])


func test_the_route_is_open_with_every_npc() -> void:
	assert_true(_reaches({}), "la Route 10 est atteignable avec tous les PNJ")


func test_lou_and_benoit_are_unavoidable_with_the_npcs() -> void:
	for id: String in UNAVOIDABLE:
		var seen := _real_sight(_spec(id))
		assert_false(_reaches(seen), "%s inévitable" % id)


func test_the_five_others_are_avoidable_one_by_one_and_together() -> void:
	# Les deux inévitables ne comptent pas : on contourne seulement la vue des cinq autres, et on
	# laisse passer la vue de Lou et de Benoît (qu'on affronte).
	var all: Dictionary = {}
	for id: String in AVOIDABLE:
		var seen := _real_sight(_spec(id))
		assert_true(_reaches(seen), "%s évitable" % id)
		all.merge(seen)
	assert_true(_reaches(all), "R9-2, 3, 4, 6 et 7 évitables ensemble")


func test_a_trainer_stopped_anywhere_never_closes_the_route() -> void:
	for id: String in TRAINERS:
		var spec := _spec(id)
		for distance: int in range(1, spec.sight + 1):
			var stop := spec.cell + spec.facing * (distance - 1)
			var world := _real_world()
			world.set_solid(spec.cell, false)
			world.set_solid(stop, true)
			var dist := GridPaths.distances(world, WEST)
			assert_lt(_nearest(dist, EAST), INF, "%s arrêté en %s ferme la route" % [id, stop])


func test_trainer_data_teams_prizes_and_lines() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir(), "données Pokémon")
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	for id: String in TRAINERS:
		var row: Array = TRAINERS[id]
		var spec := _spec(id)
		var trainer := library.get_trainer(row[0])
		assert_not_null(trainer, "%s dans data/trainers" % row[0])
		if trainer == null:
			continue
		assert_eq(trainer.name, row[2])
		assert_eq(trainer.ai, &"random", "%s : débutant" % id)
		assert_eq(trainer.prize_money, row[4], "%s : récompense du §3.3" % id)
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
		assert_eq(team, row[3], "%s : équipe du §3.3" % id)
		assert_eq(spec.sprite, StringName(row[1]), "%s : modèle peint" % id)
		var before := dialogues.get_dialogue(spec.before_dialogue)
		var after := dialogues.get_dialogue(spec.dialogue)
		assert_not_null(before, "%s : réplique avant" % id)
		assert_not_null(after, "%s : réplique après" % id)
		if before != null and after != null:
			assert_eq(before.speaker, row[2])
			assert_eq(after.speaker, row[2])
			assert_false(_texts(before).is_empty(), "%s : avant non vide" % id)
			assert_false(_texts(after).is_empty(), "%s : après non vide" % id)
		assert_not_null(dialogues.get_dialogue(spec.defeated_dialogue), "%s : réplique de défaite"
			% id)


func _texts(dialogue: Dialogue) -> Array:
	var texts: Array = []
	for page: DialoguePage in dialogue.pick(StoryFlags.new()).pages:
		texts.append(page.text)
	return texts


# --- Boot réel -----------------------------------------------------------------------------

func _start(cell: Vector2i, facing: Vector2i, flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_9"
	_boot.start_spawn = &"from_cerulean"
	_boot.start_facing = Vector2i.RIGHT
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	_boot.get_map().refresh_npcs(GameState.flags)
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_runner.get_session().get_text())
		_speakers.append(_runner.get_session().get_speaker()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action: StringName = &"move_right"
	match direction:
		Vector2i.UP:
			action = &"move_up"
		Vector2i.DOWN:
			action = &"move_down"
		Vector2i.LEFT:
			action = &"move_left"
	# Relâcher pendant le dernier pas : la touche encore enfoncée à l'arrivée enchaînerait un pas
	# de trop (comme _walk_to de test_rival_route22).
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until \
		or (_player.is_moving() and _player.get_cell() + direction == until), TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


func test_lou_sees_the_player_in_the_pass_and_challenges() -> void:
	await _start(Vector2i(7, 23), Vector2i.RIGHT)
	await _walk(Vector2i.RIGHT, Vector2i(10, 23))
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_route_9_lass_lou"] as Array[StringName], "elle a vu le joueur")
	assert_eq(_pages, ["Tu viens d'Azuria ? La route est\nlongue. Je vais t'échauffer !"]
		as Array[String], "réplique « avant »")
	assert_eq(_speakers, ["Jeune Dresseuse Lou"] as Array[String])
	assert_false(GameState.flags.has_flag(&"beaten_route_9_lass_lou"), "pas encore battue")


func test_beaten_lou_no_longer_challenges_and_says_her_after_line() -> void:
	await _start(Vector2i(10, 24), Vector2i.UP, [&"beaten_route_9_lass_lou"])
	await _walk(Vector2i.UP, Vector2i(10, 21))
	await wait_process_frames(30)
	assert_eq(_scenes, [] as Array[StringName], "battue : plus de défi")
	await _walk(Vector2i.UP, Vector2i(10, 20))
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	assert_eq(_pages, ["La Route 9 grimpe un peu.\nGarde des Potions."] as Array[String],
		"réplique « après »")
	assert_eq(_speakers, ["Jeune Dresseuse Lou"] as Array[String])
	assert_eq(_scenes, [] as Array[StringName], "pas de combat à la parole")
