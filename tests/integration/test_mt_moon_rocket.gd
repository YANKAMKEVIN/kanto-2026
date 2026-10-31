extends GutTest
## La Team Rocket du Mont Sélénite (jalon 12, T25 ; `jalon-12.md` §2.11, §4 « 12C », dossier 15
## §8, §20 n° 16–19) :
## - sur les **vraies scènes** B1F et B2F et leurs PNJ : les trois Sbires sur les cases, les
##   orientations et les visions des grilles, reprise (`rematch`) et départ (`leave`) ; le
##   guetteur R1 et le gardien R3 **inévitables** (leurs vues coupent le seul passage), la
##   fouilleuse R2 **évitable** ;
## - sur le **vrai Boot** (départs `mt_moon_b1f`, `mt_moon_b2f`, `mt_moon_weak`), combats pilotés :
##   R1 « Hé, toi ! … » puis départ (fondu sur place) et absence au rechargement ; défaite du
##   joueur → réveil, R1 toujours là, réplique de reprise ; R2 qui attend en creusant puis part
##   vers la tranchée ; R3 : les trois bulles, le décor de combat « chambre », départ vers sa
##   niche, absence au rechargement.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const STARTS := "res://tools/debug_start/"
const SAVE_PATH := "user://test_mt_moon_rocket_save.json"
const PLANS := {
	&"mt_moon_b1f": "res://tools/plans/mont_selenite_b1f.txt",
	&"mt_moon_b2f": "res://tools/plans/mont_selenite_b2f.txt",
}
const SIZES := {&"mt_moon_b1f": Vector2i(40, 30), &"mt_moon_b2f": Vector2i(50, 38)}
## PNJ (identifiant de la grille) → [carte, Dresseur, apparence, cases de départ relatives].
const GRUNTS := {
	"rocket_guetteur": [&"mt_moon_b1f", &"mt_moon_rocket_1", &"rocket_grunt_m", []],
	"rocket_fouilleuse": [&"mt_moon_b1f", &"mt_moon_rocket_2", &"rocket_grunt_f",
		[Vector2i(0, -2), Vector2i(-4, -2)]],
	"rocket_gardien": [&"mt_moon_b2f", &"mt_moon_rocket_3", &"rocket_grunt_m", [Vector2i.ZERO]],
}
## Textes validés (§20 n° 16–18) : [avant…], vaincu, reprise.
const LINES := {
	&"mt_moon_rocket_1": [["Hé, toi ! Ce passage est interdit.\nFais demi-tour."],
		"Tch… Je préviens les autres.", "Encore toi ? Demi-tour."],
	&"mt_moon_rocket_2": [["Encore un curieux ? J'ai du travail."],
		"Ces fossiles valent plus\nque ce combat.", "Tu ne comprends pas\nquand on te dit non ?"],
	&"mt_moon_rocket_3": [["Les fossiles sont à nous.",
		"La Team Rocket ne laisse rien\nderrière elle.", "Et surtout pas un gamin curieux."],
		"La Team Rocket n'oublie pas\nles visages.", "Tu reviens perdre ?"],
}
## B1F : arrivée de l'échelle A → échelle B (suite du parcours principal) ; Potion du fond de la
## galerie de la fouilleuse. B2F : arrivée de l'échelle D → bas du couloir des lampes (seul accès
## à la chambre des fossiles, déclencheur du chercheur).
const B1F_START := Vector2i(4, 2)
const B1F_LADDER_B := Vector2i(35, 4)
const B1F_POTION_SIDES: Array[Vector2i] = [Vector2i(16, 20), Vector2i(16, 22), Vector2i(15, 21)]
const B2F_START := Vector2i(46, 3)
const B2F_CORRIDOR_END: Array[Vector2i] = [Vector2i(25, 27), Vector2i(26, 27)]
const FADE := 0.05
const TIMEOUT := 14.0
const SCENE_TIMEOUT_MS := 90000
const WALK_STOP := &"test_walk_stop"

var _maps: Dictionary = {}
var _plans: Dictionary = {}
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _pages: Array[String] = []
var _speakers: Array[String] = []
var _scenes: Array[StringName] = []
var _decors: Array[StringName] = []
var _saved_router: Array = []
var _stop_at := Vector2i(-1, -1)
var _held: StringName = &""


func before_all() -> void:
	for map_id: StringName in PLANS:
		var plan := PlanGrid.new()
		assert_true(plan.load_file(PLANS[map_id]), plan.error)
		_plans[map_id] = plan
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[map_id] = map


func after_all() -> void:
	for map_id: StringName in _maps:
		(_maps[map_id] as GameMap).free()


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-14T15:00:00")
	Haptics.sink = func(_ms: int) -> void: pass
	_fs = MemoryFs.new()
	_pages.clear()
	_speakers.clear()
	_scenes.clear()
	_decors.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	Haptics.reset()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Vraies scènes et leurs PNJ -----------------------------------------------------------

func _map(map_id: StringName) -> GameMap:
	return _maps[map_id]


func _spec(id: String) -> NpcSpec:
	var map_id: StringName = GRUNTS[id][0]
	return _map(map_id).get_npc(StringName(id)).get_spec()


## Relief de la scène + case de chaque PNJ posé + [param blocked].
func _real_world(map_id: StringName, blocked: Dictionary = {}) -> GridWorld:
	var grid := GridPaths.relief(_map(map_id).get_grid(), SIZES[map_id])
	for npc: Npc in _map(map_id).get_npcs():
		grid.set_solid(npc.get_cell())
	for cell: Vector2i in blocked:
		grid.set_solid(cell)
	return grid


## Cases d'où [param spec] voit le joueur, sur la vraie grille.
func _real_sight(map_id: StringName, spec: NpcSpec) -> Dictionary:
	var grid := _map(map_id).get_grid()
	var seen: Dictionary = {}
	var size: Vector2i = SIZES[map_id]
	for y: int in size.y:
		for x: int in size.x:
			var cell := Vector2i(x, y)
			if grid.is_solid(cell) or grid.is_occupied(cell):
				continue
			if TrainerRules.sight_distance(grid, spec.cell, spec.facing, spec.sight, cell) > 0:
				seen[cell] = true
	return seen


## Échelles (passages `STEP_ON`) : atteintes, jamais traversées.
func _stops(map_id: StringName) -> Dictionary:
	var stops: Dictionary = {}
	for warp: Node in _map(map_id).get_node(^"Warps").get_children():
		stops[(warp as WarpPoint).get_cell()] = true
	return stops


func _reaches(map_id: StringName, start: Vector2i, goals: Array[Vector2i],
		blocked: Dictionary = {}) -> bool:
	var dist := GridPaths.distances(_real_world(map_id, blocked), [start], _stops(map_id))
	for goal: Vector2i in goals:
		if dist.has(goal):
			return true
	return false


func test_three_grunts_on_their_grid_cells_with_rematch_and_leave() -> void:
	for id: String in GRUNTS:
		var map_id: StringName = GRUNTS[id][0]
		var plan: PlanGrid = _plans[map_id]
		var npc := _map(map_id).get_npc(StringName(id))
		assert_not_null(npc, "%s posé" % id)
		if npc == null:
			continue
		var spec := npc.get_spec()
		assert_eq(spec.cell, plan.cell_of(id), "%s : case de la grille" % id)
		assert_eq(spec.facing, Grid.direction_from_name(plan.attr(id, "facing")), id)
		assert_eq(spec.sight, int(plan.attr(id, "sight")), "%s : vision" % id)
		assert_eq(spec.trainer_id, StringName(plan.attr(id, "trainer")), id)
		assert_eq(spec.trainer_id, GRUNTS[id][1])
		assert_eq(spec.sprite, GRUNTS[id][2], "%s : apparence" % id)
		assert_true(CharacterLook.resolve(spec.sprite).painted, "%s : peint" % id)
		assert_true(spec.has_rematch(), "%s : réplique de reprise" % id)
		assert_true(spec.leaves, "%s : part après sa défaite" % id)
		var expected: Array[Vector2i] = []
		for offset: Vector2i in GRUNTS[id][3]:
			expected.append(spec.cell + offset)
		assert_eq(spec.get_leave_path_cells(), expected, "%s : chemin de départ" % id)
		assert_true(spec.unless_flags.has(TrainerRules.beaten_flag(spec.trainer_id)),
			"%s : absent une fois battu" % id)
		var seen := _real_sight(map_id, spec)
		assert_eq(seen.size(), spec.sight, "%s : vue dégagée" % id)


func test_lookout_and_guardian_are_unavoidable_the_digger_is_not() -> void:
	var ladder_b: Array[Vector2i] = [B1F_LADDER_B]
	assert_true(_reaches(&"mt_moon_b1f", B1F_START, ladder_b), "B1F : échelle B atteignable")
	assert_false(_reaches(&"mt_moon_b1f", B1F_START, ladder_b,
		_real_sight(&"mt_moon_b1f", _spec("rocket_guetteur"))), "R1 inévitable")
	var digger := _real_sight(&"mt_moon_b1f", _spec("rocket_fouilleuse"))
	assert_true(_reaches(&"mt_moon_b1f", B1F_START, ladder_b, digger), "R2 évitable (échelle B)")
	assert_true(_reaches(&"mt_moon_b1f", B1F_START, B1F_POTION_SIDES, digger),
		"R2 évitable (Potion du fond de sa galerie)")
	assert_true(_reaches(&"mt_moon_b2f", B2F_START, B2F_CORRIDOR_END),
		"B2F : bas du couloir atteignable")
	assert_false(_reaches(&"mt_moon_b2f", B2F_START, B2F_CORRIDOR_END,
		_real_sight(&"mt_moon_b2f", _spec("rocket_gardien"))), "R3 inévitable")


func test_grunt_lines_are_the_validated_texts() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir())
	var trainers := TrainerLibrary.new(_pokemon_data())
	assert_true(trainers.load_dir())
	for id: String in GRUNTS:
		var spec := _spec(id)
		var lines: Array = LINES[spec.trainer_id]
		assert_eq(_texts(library, spec.before_dialogue), lines[0], "%s : avant" % id)
		assert_eq(_texts(library, spec.defeated_dialogue), [lines[1]], "%s : vaincu" % id)
		assert_eq(_texts(library, spec.rematch_dialogue), [lines[2]], "%s : reprise" % id)
		assert_eq(library.get_dialogue(spec.before_dialogue).speaker, "Sbire Rocket")
		assert_eq(trainers.get_trainer(spec.trainer_id).name, "Sbire Rocket", "§20 n° 19")


func _pokemon_data() -> PokemonData:
	var data := PokemonData.new()
	data.load_dir()
	return data


func _texts(library: DialogueLibrary, id: StringName) -> Array:
	var texts: Array = []
	for page: DialoguePage in library.get_dialogue(id).variants[0].pages:
		texts.append(DialogueTokens.apply_agreements(page.text, {}))
	return texts


# --- Vrai Boot ---------------------------------------------------------------------------

## Boot sur le départ [param start] si [param fresh] (équipe forte si [param strong]), sinon la
## partie relue de la sauvegarde en mémoire.
func _start(start: String, fresh: bool = true, strong: bool = true) -> void:
	var json: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(STARTS + start + ".json"))
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = StringName(json["map"])
	_boot.start_spawn = StringName(json["spawn"])
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	if fresh:
		var data := DebugStart.new()
		assert_true(data.load_file(STARTS + start + ".json", _boot.get_pokemon_data(),
			_boot.get_item_library()), "\n".join(data.get_errors()))
		data.apply(GameState, _boot.get_pokemon_data())
		GameState.rng = GameRng.new(7)
		if strong:
			_strong_party()
		_boot.get_map().refresh_npcs(GameState.flags)
		_boot.get_companion_controller().refresh()
	_boot.get_battle_director().speed_scale = 0.0
	var runner := _boot.get_dialogue_runner()
	runner.page_started.connect(func(_index: int) -> void:
		_pages.append(runner.get_session().get_text())
		_speakers.append(runner.get_session().get_speaker()))
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	_player.moved.connect(_on_player_moved)
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	await wait_process_frames(2)


## Une Salamèche Nv. 40 (Flammèche) seule : chaque combat est gagné au premier coup.
func _strong_party() -> void:
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 40,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)
	GameState.companion_uid = ""


func _reload(start: String) -> void:
	_boot.request_autosave("test")
	await wait_process_frames(5)
	_boot.queue_free()
	await wait_process_frames(3)
	_pages.clear()
	_scenes.clear()
	await _start(start, false)


func _put(cell: Vector2i, facing: Vector2i) -> void:
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _action(direction: Vector2i) -> StringName:
	match direction:
		Vector2i.UP:
			return &"move_up"
		Vector2i.DOWN:
			return &"move_down"
		Vector2i.LEFT:
			return &"move_left"
	return &"move_right"


func _on_player_moved(cell: Vector2i) -> void:
	if cell == _stop_at and not _held.is_empty():
		Input.action_release(_held)
		_held = &""
		_player.set_input_enabled(false, WALK_STOP)


## Marche réelle vers [param until] (arrêt dès qu'un Dresseur prend la main).
func _walk(direction: Vector2i, until: Vector2i) -> void:
	_stop_at = until
	_held = _action(direction)
	Input.action_press(_held)
	await wait_until(func() -> bool:
		return _player.get_cell() == until or not _player.is_input_enabled() \
			or _boot.get_cutscene_director().is_running(), TIMEOUT)
	await wait_process_frames(1)
	if not _held.is_empty():
		Input.action_release(_held)
		_held = &""
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)
	_player.set_input_enabled(true, WALK_STOP)


## Déroule la scène en cours : pages avancées, combat piloté (première capacité à chaque tour),
## décor du combat noté.
func _finish_scene() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battles := _boot.get_battle_director()
	var hud := _boot.get_battle_hud()
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battles.is_running():
			var decor := _boot.get_battle_stage().get_decor()
			if decor != null and not _decors.has(decor.id):
				_decors.append(decor.id)
			var battle := battles.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match hud.get_zone():
					BattleHud.Zone.ACTIONS:
						hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	await wait_process_frames(5)
	assert_false(director.is_running(), "scène finie")


func test_the_lookout_says_hey_you_then_leaves_and_stays_gone() -> void:
	await _start("mt_moon_b1f")
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"rocket_guetteur"), "R1 à son poste")
	await _put(Vector2i(11, 4), Vector2i.RIGHT)
	await _walk(Vector2i.RIGHT, Vector2i(14, 4))
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_mt_moon_rocket_1"] as Array[StringName], "il voit le joueur")
	assert_eq(_pages.slice(0, 1), LINES[&"mt_moon_rocket_1"][0], "« Hé, toi ! … » (V-4)")
	assert_eq(_speakers[0], "Sbire Rocket")
	await _finish_scene()
	assert_true(GameState.flags.has_flag(&"beaten_mt_moon_rocket_1"), "battu")
	assert_true(_pages.has(LINES[&"mt_moon_rocket_1"][1]), "réplique « vaincu »")
	assert_null(map.get_npc(&"rocket_guetteur"), "parti (fondu sur place)")
	assert_eq(GridPaths.cut_by_occupants(map.get_grid(), _player.get_cell(), _player),
		[] as Array[Vector2i], "parti, rien ne bloque")
	assert_true(_player.is_input_enabled(), "joueur libre")
	await _reload("mt_moon_b1f")
	assert_null(_boot.get_map().get_npc(&"rocket_guetteur"), "absent au rechargement")
	_scenes.clear()
	await _put(Vector2i(13, 4), Vector2i.RIGHT)
	await _walk(Vector2i.RIGHT, Vector2i(15, 4))
	await wait_process_frames(10)
	assert_eq(_scenes, [] as Array[StringName], "plus de défi")


func test_a_defeat_wakes_the_player_and_the_lookout_says_his_rematch_line() -> void:
	await _start("mt_moon_weak", true, false)
	await _put(Vector2i(11, 4), Vector2i.RIGHT)
	await _walk(Vector2i.RIGHT, Vector2i(14, 4))
	await _finish_scene()
	assert_false(GameState.flags.has_flag(&"beaten_mt_moon_rocket_1"), "pas battu")
	assert_true(GameState.flags.has_flag(&"lost_mt_moon_rocket_1"), "défaite notée")
	assert_ne(_boot.get_map().map_id, &"mt_moon_b1f", "réveil au point de repos")
	# Retour au B1F : le guetteur est resté, il dit sa réplique de reprise.
	_pages.clear()
	_scenes.clear()
	await SceneRouter.change_map(&"mt_moon_b1f", &"arrivee_a", Vector2i.DOWN)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	assert_not_null(_boot.get_map().get_npc(&"rocket_guetteur"), "R1 toujours là")
	await _put(Vector2i(11, 4), Vector2i.RIGHT)
	await _walk(Vector2i.RIGHT, Vector2i(14, 4))
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	assert_eq(_pages[0], LINES[&"mt_moon_rocket_1"][2], "« Encore toi ? Demi-tour. »")
	assert_false(_pages.has(LINES[&"mt_moon_rocket_1"][0][0]), "pas la réplique « avant »")
	await _finish_scene()


func test_the_digger_waits_digging_then_walks_to_her_trench_and_fades() -> void:
	await _start("mt_moon_b1f")
	var map := _boot.get_map()
	var digger := map.get_npc(&"rocket_fouilleuse")
	assert_not_null(digger, "R2 au bord de la tranchée")
	if digger == null:
		return
	assert_eq(digger.get_facing(), Vector2i.RIGHT, "tournée vers sa fouille")
	var sprite := digger.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(sprite.animation, &"idle_right", "attente « creuse » (planche d'attente)")
	await _put(Vector2i(10, 18), Vector2i.DOWN)
	await _walk(Vector2i.DOWN, Vector2i(10, 20))
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_mt_moon_rocket_2"] as Array[StringName])
	assert_eq(_pages[0], LINES[&"mt_moon_rocket_2"][0][0])
	await _finish_scene()
	assert_true(GameState.flags.has_flag(&"beaten_mt_moon_rocket_2"))
	assert_true(_pages.has(LINES[&"mt_moon_rocket_2"][1]), "réplique « vaincu »")
	assert_null(map.get_npc(&"rocket_fouilleuse"), "partie vers la tranchée puis effacée")
	assert_eq(GridPaths.cut_by_occupants(map.get_grid(), _player.get_cell(), _player),
		[] as Array[Vector2i], "parti, rien ne bloque")
	await _reload("mt_moon_b1f")
	assert_null(_boot.get_map().get_npc(&"rocket_fouilleuse"), "absente au rechargement")


func test_the_guardian_speaks_three_bubbles_in_the_fossil_chamber() -> void:
	await _start("mt_moon_b2f")
	var map := _boot.get_map()
	assert_not_null(map.get_npc(&"rocket_gardien"), "R3 dans sa niche")
	await _put(Vector2i(25, 21), Vector2i.DOWN)
	await _walk(Vector2i.DOWN, Vector2i(25, 24))
	await wait_until(func() -> bool: return not _pages.is_empty(), TIMEOUT)
	assert_eq(_scenes, [&"trainer_mt_moon_rocket_3"] as Array[StringName])
	await _finish_scene()
	assert_eq(_pages.slice(0, 3), LINES[&"mt_moon_rocket_3"][0], "trois bulles au plus")
	assert_eq(_pages[3], LINES[&"mt_moon_rocket_3"][1], "puis, après le combat, « vaincu »")
	assert_eq(_decors, [&"mt_moon_chambre"] as Array[StringName], "décor « chambre »")
	assert_true(GameState.flags.has_flag(&"beaten_mt_moon_rocket_3"))
	assert_true(_pages.has(LINES[&"mt_moon_rocket_3"][1]), "réplique « vaincu »")
	assert_null(map.get_npc(&"rocket_gardien"), "retourné dans sa niche puis effacé")
	# Seul le chercheur, encore à son poste (13, 31), coupe la salle de l'échelle de sortie.
	for cell: Vector2i in GridPaths.cut_by_occupants(map.get_grid(), _player.get_cell(),
			_player):
		assert_true(cell.x <= 12 and cell.y >= 29, "%s : seulement derrière le chercheur" % cell)
	assert_false(GameState.flags.has_flag(&"beaten_mt_moon_researcher"), "chercheur après")
	await _reload("mt_moon_b2f")
	assert_null(_boot.get_map().get_npc(&"rocket_gardien"), "absent au rechargement")
	assert_not_null(_boot.get_map().get_npc(&"mt_moon_researcher"), "le chercheur garde le goulet")
