extends GutTest
## Jalon 21 (T13, `jalon-21.md` §2.8, dossier 24 §6, §15.2, §15.3) : le 7F de la Tour Pokémon sur
## la **vraie scène** : grille = plan, paire T67 aller-retour avec le 6F, budgets (nœuds, halos,
## aucune `Light2D`), trois Sbires inévitables dans l'ordre 1, 2, 3 (recherche de chemin avec les
## PNJ en place), textes mot pour mot, M. Fuji avant et après les Sbires, `fuji_rescued` posé
## **avant** le changement de carte (maison, `devant_fuji`), Corde Sortie, rencontres.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const PLAN_7F: String = "res://tools/plans/pokemon_tower_7f.txt"
const PLAN_6F: String = "res://tools/plans/pokemon_tower_6f.txt"
const SIZE := Vector2i(20, 18)
const NODE_BUDGET: int = 3000
const MAX_GLOWS: int = 16
const FADE := 0.05
const TIMEOUT := 25.0
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Sbire → [case, orientation, apparence, rangée barrée] (grille du 7F).
const ROCKETS: Dictionary = {
	1: [Vector2i(9, 11), Vector2i.RIGHT, &"rocket_grunt_m", 11],
	2: [Vector2i(12, 9), Vector2i.LEFT, &"rocket_grunt_f", 9],
	3: [Vector2i(9, 7), Vector2i.RIGHT, &"rocket_grunt_m", 7],
}
## Dossier 24 §15.2 : [avant, défaite, après] par Sbire (« / » = deux lignes d'une page).
const ROCKET_TEXTS: Dictionary = {
	1: ["Qu'est-ce que tu fais là, toi ?", "J'abandonne !", "Je ne vais pas oublier ta tête."],
	2: ["Ce vieux est venu nous faire la morale. / Comme si ces Pokémon valaient quelque chose.",
		"Arrête ! Ça suffit !",
		"Les Pokémon, ça sert à faire de l'argent. / Le reste, c'est du sentiment."],
	3: ["Le boss est parti, mais nous, on reste. / Tu ne sauveras personne, gamin !",
		"On ne se mesure pas à la Team Rocket…", "Tu ne t'en tireras pas comme ça."],
}
## Dossier 24 §15.3 n° 2 à 6 (une page chacun).
const FUJI_THANKS: Array[String] = [
	"Oh… Tu es venu me chercher ? / Merci, mon enfant.",
	"Mais je suis monté ici de mon plein gré. / Je voulais apaiser l'âme de la mère d'Osselait.",
	"Ces hommes m'ont empêché de redescendre. / Ils disaient que je les gênais.",
	"Je crois qu'elle a enfin trouvé la paix. / C'est grâce à toi, n'est-ce pas ?",
	"Viens chez moi, au pied de la Tour. / J'aimerais te remercier comme il se doit.",
]

var _boot: Boot
var _player: Player
var _runner: DialogueRunner
var _pages: Array[String] = []
var _saved_router: Array = []
var _dialogues := DialogueLibrary.new()
var _flag_at_transition: Dictionary = {}


func before_all() -> void:
	_dialogues.load_dir()


func before_each() -> void:
	_saved_router = [SceneRouter.fade_out_duration, SceneRouter.fade_in_duration]
	SceneRouter.fade_out_duration = FADE
	SceneRouter.fade_in_duration = FADE
	GameState.clock = FixedClock.new("2026-10-21T14:00:00")
	_pages.clear()
	_flag_at_transition.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


func _plan(path: String) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(path), plan.error)
	return plan


func _load_map(map_id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _count(node: Node) -> int:
	var total := 1
	for child: Node in node.get_children():
		total += _count(child)
	return total


func _find_all(node: Node, out: Array[Node], test: Callable) -> void:
	if test.call(node):
		out.append(node)
	for child: Node in node.get_children():
		_find_all(child, out, test)


func _warp_at(map: GameMap, cell: Vector2i) -> Warp:
	var warps := map.get_warps().get_at(cell)
	return warps[0] if not warps.is_empty() else null


func _lines(page_text: String) -> String:
	return page_text.replace("\n", " / ")


func _page_lines(id: StringName, variant: int = 0) -> Array[String]:
	var lines: Array[String] = []
	for page: DialoguePage in _dialogues.get_dialogue(id).variants[variant].pages:
		lines.append(_lines(page.text))
	return lines


# --- Carte : grille, passages, budgets ------------------------------------------------------


func test_grid_matches_the_plan() -> void:
	var plan := _plan(PLAN_7F)
	var map := _load_map(&"pokemon_tower_7f")
	assert_eq(map.map_id, &"pokemon_tower_7f")
	assert_eq(map.size, SIZE)
	assert_eq(map.display_name, "Tour Pokémon")
	assert_false(map.interior, "extérieure comme les étages du J19 (compagnon visible)")
	assert_eq(map.light_profile, &"tower")
	var wrong: Array[Vector2i] = []
	for y: int in plan.height:
		for x: int in plan.width:
			var cell := Vector2i(x, y)
			if map.get_grid().is_solid(cell) == ".V".contains(plan.at(cell)):
				wrong.append(cell)
	assert_eq(wrong, [] as Array[Vector2i], "cases différentes du plan")


func test_t67_pair_goes_both_ways() -> void:
	var seven := _load_map(&"pokemon_tower_7f")
	var six := _load_map(&"pokemon_tower_6f")
	var down := _warp_at(seven, Vector2i(9, 16))
	assert_not_null(down, "7F : escalier bas")
	assert_eq(down.target_map, &"pokemon_tower_6f")
	assert_eq(down.target_spawn, &"arrivee_T67")
	assert_eq(down.facing, Vector2i.RIGHT, "orientation de la grille du 6F")
	assert_false(down.is_coming_soon())
	var up := _warp_at(six, Vector2i(9, 16))
	assert_not_null(up, "6F : escalier du 7F")
	assert_eq(up.target_map, &"pokemon_tower_7f", "warp réel (Jalon 21)")
	assert_eq(up.target_spawn, &"arrivee_T67")
	assert_eq(up.facing, Vector2i.RIGHT)
	assert_false(up.is_coming_soon(), "plus de repli « à venir »")
	assert_eq(seven.get_spawn_cell(&"arrivee_T67"), Vector2i(10, 16))
	assert_eq(six.get_spawn_cell(&"arrivee_T67"), Vector2i(10, 16))
	assert_false(seven.get_grid().is_solid(Vector2i(10, 16)))
	assert_eq(down.trigger, Warp.Trigger.STEP_ON)
	assert_eq(down.direction, Vector2i.ZERO)


func test_budgets_and_no_light2d() -> void:
	var map := _load_map(&"pokemon_tower_7f")
	var nodes := _count(map)
	gut.p("pokemon_tower_7f : %d nœuds" % nodes)
	assert_lte(nodes, NODE_BUDGET)
	var glows: Array[Node] = []
	_find_all(map, glows, func(n: Node) -> bool: return n is LightGlow)
	assert_lte(glows.size(), MAX_GLOWS)
	var candles := glows.filter(func(n: Node) -> bool:
		return (n as LightGlow).glow_type == &"candle")
	assert_eq(candles.size(), _plan(PLAN_7F).cells_of("S").size(),
		"un halo « candle » par stèle et par case d'autel")
	var lights: Array[Node] = []
	_find_all(map, lights, func(n: Node) -> bool: return n is Light2D)
	assert_eq(lights.size(), 0, "aucune Light2D")
	var mists: Array[Node] = []
	_find_all(map, mists, func(n: Node) -> bool: return n is MistLayer)
	assert_eq(mists.size(), 1, "brume dense, sans variante")
	assert_gte((mists[0] as MistLayer).alpha, 0.18, "plus brumeux que le 6F")


func test_zone_cave_and_decor_data_include_the_seventh_floor() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file("res://data/world/caves.json"))
	var exit := caves.escape_target(&"pokemon_tower_7f")
	assert_not_null(exit, "Corde Sortie permise au 7F")
	assert_eq(exit.map, &"lavender_town", "devant la porte de la Tour")
	assert_eq(exit.spawn, &"retour_tour")
	var zones: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/world/zones.json"))
	assert_has(zones["zones"]["lavender_town"]["maps"], "pokemon_tower_7f")
	var decors: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/battle/decors.json"))
	assert_eq(decors["places"]["pokemon_tower_7f"][0]["decor"], "tour_pokemon")
	var lighting: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/world/lighting.json"))
	assert_eq(lighting["maps"]["pokemon_tower_7f"], "tower")


# --- Données : Sbires, Fuji, textes ----------------------------------------------------------


func test_rockets_and_fuji_stand_on_their_plan_cells() -> void:
	var plan := _plan(PLAN_7F)
	var specs: Dictionary = {}
	for spec: NpcSpec in NpcRoster.load_for_map(&"pokemon_tower_7f").get_present(null):
		specs[spec.id] = spec
	for n: int in ROCKETS:
		var id := StringName("tower_rocket_%d" % n)
		var info: Array = ROCKETS[n]
		assert_true(specs.has(id), "%s présent" % id)
		var spec: NpcSpec = specs[id]
		assert_eq(spec.cell, plan.cell_of(String(id)), "%s : case du plan" % id)
		assert_eq(spec.cell, info[0])
		assert_eq(spec.facing, info[1], "%s : orientation" % id)
		assert_eq(spec.sight, 3, "%s : vue 3" % id)
		assert_eq(spec.sprite, info[2], "%s : apparence" % id)
		assert_eq(spec.trainer_id, id)
		assert_eq(spec.unless_flags, [StringName("beaten_tower_rocket_%d" % n)])
		assert_true(spec.leaves, "%s quitte la carte après sa défaite" % id)
	var fuji: NpcSpec = specs[&"mr_fuji"]
	assert_eq(fuji.cell, Vector2i(10, 3))
	assert_eq(fuji.facing, Vector2i.UP, "en prière, tourné vers l'autel")
	assert_eq(fuji.sprite, &"mr_fuji")
	assert_eq(fuji.dialogue, &"tower_7f_fuji")
	assert_eq(fuji.unless_flags, [&"fuji_rescued"])
	assert_eq(specs.size(), 4)
	var gone := NpcRoster.load_for_map(&"pokemon_tower_7f").get_present(_flags(
		[&"fuji_rescued", &"beaten_tower_rocket_1", &"beaten_tower_rocket_2",
		&"beaten_tower_rocket_3"]))
	assert_eq(gone.size(), 0, "Fuji sauvé, Sbires battus : le 7F est vide")


func _flags(list: Array[StringName]) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in list:
		flags.set_flag(flag)
	return flags


func test_rocket_teams_and_lines_word_for_word() -> void:
	var library := TrainerLibrary.new(_pokemon_data())
	library.load_dir()
	for n: int in ROCKETS:
		var trainer := library.get_trainer(StringName("tower_rocket_%d" % n))
		assert_not_null(trainer, "Dresseur %d" % n)
		assert_eq(trainer.name, "Sbire Rocket")
		var texts: Array = ROCKET_TEXTS[n]
		for i: int in 3:
			var id := StringName("tower_rocket_%d_%s" % [n, ["before", "defeated", "after"][i]])
			var pages := _page_lines(id)
			assert_eq(pages.size(), 1, String(id))
			assert_eq(pages[0], texts[i], "%s : mot pour mot" % id)
			assert_eq(_dialogues.get_dialogue(id).speaker, "Sbire Rocket")


func _pokemon_data() -> PokemonData:
	var data := PokemonData.new()
	data.load_dir()
	return data


func test_fuji_dialogue_variants_and_thanks_word_for_word() -> void:
	var dialogue := _dialogues.get_dialogue(&"tower_7f_fuji")
	assert_eq(dialogue.variants.size(), 2)
	assert_eq(dialogue.variants[0].if_flags, [&"beaten_tower_rocket_1",
		&"beaten_tower_rocket_2", &"beaten_tower_rocket_3"] as Array[StringName])
	assert_eq(dialogue.variants[0].cutscene, &"tower_7f_fuji_rescue")
	assert_true(dialogue.variants[0].pages.is_empty(), "sans page")
	assert_eq(_page_lines(&"tower_7f_fuji", 1), ["…"] as Array[String], "§15.3 n° 1")
	assert_eq(_page_lines(&"tower_7f_fuji_thanks"), FUJI_THANKS)


func test_rescue_scene_sets_the_flag_before_the_map_change() -> void:
	var library := CutsceneLibrary.new()
	library.load_dir()
	var scene := library.get_cutscene(&"tower_7f_fuji_rescue")
	assert_not_null(scene)
	assert_eq(scene.next, &"pokemon_house_flute")
	var variant := scene.variants[0]
	assert_eq(variant.unless_flags, [&"fuji_rescued"] as Array[StringName])
	var kinds: Array[int] = []
	for step: CutsceneStep in variant.steps:
		kinds.append(step.kind)
	var set_at := kinds.find(CutsceneStep.Kind.SET_FLAGS)
	var move_at := kinds.find(CutsceneStep.Kind.CHANGE_MAP)
	assert_gt(set_at, -1)
	assert_gt(move_at, set_at, "le drapeau avant le fondu (L-8)")
	var change: CutsceneStep = variant.steps[move_at]
	assert_eq(change.map_id, &"pokemon_house")
	assert_eq(change.spawn, &"devant_fuji")
	assert_eq(change.facing, Vector2i.UP)


# --- Vraie scène : Boot ----------------------------------------------------------------------


func _start(map_id: StringName, spawn: StringName, facing: Vector2i,
		flags: Array[StringName] = []) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.start_map = map_id
	_boot.start_spawn = spawn
	_boot.start_facing = facing
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_runner = _boot.get_dialogue_runner()
	_runner.chars_per_second = 0.0
	await wait_process_frames(3)
	await wait_until(func() -> bool: return _boot.is_stable(), TIMEOUT)
	GameState.new_game(11)
	GameState.flags.set_flag(&"starter_chosen")
	GameState.rng = GameRng.new(11)
	GameState.party.add(PokemonFactory.create(_boot.get_pokemon_data(), &"rattata", 30,
		GameRng.new(5)))
	GameState.starter_species = GameState.party.get_at(0).species_id
	GameState.ensure_unique_uids()
	for flag: StringName in flags:
		GameState.flags.set_flag(flag)
	_runner.page_started.connect(func(_index: int) -> void:
		_pages.append(_lines(_boot.get_dialogue_box().get_text())))
	SceneRouter.transition_started.connect(func(target: StringName) -> void:
		_flag_at_transition[target] = GameState.flags.has_flag(&"fuji_rescued"))


func _seen_cells(grid: GridWorld, npc: Npc, sight: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for k: int in range(1, sight + 1):
		var cell := npc.get_cell() + npc.get_facing() * k
		if not grid.is_in_bounds(cell) or grid.is_solid(cell) or grid.is_water(cell) \
				or grid.is_occupied(cell):
			break
		cells.append(cell)
	return cells


## Rangée la plus au nord atteinte depuis l'arrivée quand les Sbires [param beaten] sont battus
## (ils ont quitté la carte) et que les autres barrent leur rangée (leur case et leur vue).
func _min_row_reached(beaten: Array[int]) -> Dictionary:
	var map := _boot.get_map()
	var relief := GridPaths.relief(map.get_grid(), SIZE)
	for npc: Npc in map.get_npcs():
		var id := String(npc.get_id())
		if not id.begins_with("tower_rocket_"):
			continue
		var n := int(id.trim_prefix("tower_rocket_"))
		if beaten.has(n):
			continue
		relief.set_solid(npc.get_cell())
		for cell: Vector2i in _seen_cells(map.get_grid(), npc, 3):
			relief.set_solid(cell)
	return GridPaths.distances(relief, [map.get_spawn_cell(&"arrivee_T67")])


func test_rockets_are_unavoidable_in_the_order_1_2_3() -> void:
	await _start(&"pokemon_tower_7f", &"arrivee_T67", Vector2i.RIGHT)
	var map := _boot.get_map()
	for n: int in ROCKETS:
		var npc := map.get_npc(StringName("tower_rocket_%d" % n))
		assert_not_null(npc, "Sbire %d posé" % n)
		assert_eq(npc.get_cell(), ROCKETS[n][0])
	var fuji_door := Vector2i(10, 4)
	# Aucun battu : rien au nord de la rangée du Sbire 1 (11), ni Fuji.
	var reach := _min_row_reached([])
	assert_false(reach.has(fuji_door), "Fuji inatteignable sans battre les Sbires")
	for cell: Vector2i in reach:
		assert_gt(cell.y, 11, "avant le Sbire 1 : %s" % cell)
	assert_true(reach.has(Vector2i(10, 12)), "la rangée juste avant le Sbire 1 est atteinte")
	# Sbire 1 battu : on atteint la rangée 10, mais le 2 barre la rangée 9.
	reach = _min_row_reached([1])
	assert_true(reach.has(Vector2i(10, 10)))
	for cell: Vector2i in reach:
		assert_gt(cell.y, 9, "Sbire 1 battu, le 2 barre : %s" % cell)
	# Sbires 1 et 2 battus : rangée 8 atteinte, le 3 barre la rangée 7.
	reach = _min_row_reached([1, 2])
	assert_true(reach.has(Vector2i(10, 8)))
	for cell: Vector2i in reach:
		assert_gt(cell.y, 7, "Sbires 1 et 2 battus, le 3 barre : %s" % cell)
	# Les trois battus : Fuji est à portée.
	reach = _min_row_reached([1, 2, 3])
	assert_true(reach.has(fuji_door), "les 3 Sbires battus : l'autel est à portée")
	assert_push_error_count(0)


func test_encounters_are_floor_cells_never_stairs_nor_npc_cells() -> void:
	await _start(&"pokemon_tower_7f", &"arrivee_T67", Vector2i.RIGHT)
	var map := _boot.get_map()
	var director := _boot.get_encounter_director()
	var table := _boot.get_encounter_library().get_table(&"pokemon_tower_7f", &"floor")
	assert_not_null(table, "table du 7F")
	assert_eq(table.rate, 15, "taux RB 15")
	assert_eq(director.terrain_at(Vector2i(9, 16)), &"", "jamais sur l'escalier")
	# Une case de PNJ est occupée : le joueur n'y entre jamais, donc aucun tirage n'y a lieu.
	for npc: Npc in map.get_npcs():
		assert_true(map.get_grid().is_occupied(npc.get_cell()), "%s occupée" % npc.get_id())
	var floor_cells := 0
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var cell := Vector2i(x, y)
			if director.terrain_at(cell) == &"floor":
				floor_cells += 1
				assert_false(map.get_grid().is_solid(cell), "%s praticable" % cell)
	assert_gt(floor_cells, 40, "tout le sol « . » de la nef")


func _talk_to(npc_id: StringName) -> void:
	var map := _boot.get_map()
	var npc := map.get_npc(npc_id)
	assert_not_null(npc, "%s posé" % npc_id)
	if npc == null:
		return
	for other: Npc in map.get_npcs():
		other.set_routine_held(true)
	for direction: Vector2i in DIRECTIONS:
		var from := npc.get_cell() + direction
		if map.get_grid().is_free(from):
			map.spawn_player_at(_player, from, -direction)
			break
	await wait_process_frames(3)
	Input.action_press(&"interact")
	await wait_process_frames(2)
	Input.action_release(&"interact")
	await wait_until(func() -> bool: return _runner.is_running(), TIMEOUT)
	await _play_through()


func _play_through() -> void:
	var director := _boot.get_cutscene_director()
	var box := _boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while (director.is_running() or _runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	await wait_process_frames(5)


func test_fuji_before_the_rockets_only_prays() -> void:
	await _start(&"pokemon_tower_7f", &"arrivee_T67", Vector2i.RIGHT)
	await _talk_to(&"mr_fuji")
	assert_eq(_pages, ["…"] as Array[String], "§15.3 n° 1")
	assert_false(GameState.flags.has_flag(&"fuji_rescued"))
	assert_eq(_boot.get_map().map_id, &"pokemon_tower_7f", "il reste au 7F")
	assert_push_error_count(0)


func test_fuji_after_the_rockets_thanks_then_teleports_to_his_house() -> void:
	await _start(&"pokemon_tower_7f", &"arrivee_T67", Vector2i.RIGHT, [&"tower_stairs_open",
		&"ghost_marowak_calmed", &"beaten_tower_rocket_1", &"beaten_tower_rocket_2",
		&"beaten_tower_rocket_3"])
	_boot.get_map().get_npc(&"mr_fuji").set_routine_held(true)
	await _talk_to(&"mr_fuji")
	assert_eq(_pages.slice(0, FUJI_THANKS.size()), FUJI_THANKS, "§15.3 n° 2 à 6")
	assert_true(_flag_at_transition.get(&"pokemon_house", false),
		"`fuji_rescued` est posé AVANT le changement de carte")
	await wait_until(func() -> bool: return (_boot.get_map().map_id == &"pokemon_house"
		and _boot.is_stable() and not SceneRouter.is_transitioning()), TIMEOUT)
	assert_eq(_boot.get_map().map_id, &"pokemon_house", "téléporté dans la maison")
	assert_true(GameState.flags.has_flag(&"fuji_rescued"))
	await _play_through()
	assert_eq(_player.get_cell(), Vector2i(7, 4), "devant Fuji (`devant_fuji`)")
	assert_eq(_player.get_facing(), Vector2i.UP, "tourné vers lui")
	assert_not_null(_boot.get_map().get_npc(&"mr_fuji"), "Fuji est chez lui")
	assert_push_error_count(0)
