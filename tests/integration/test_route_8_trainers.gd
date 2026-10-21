extends GutTest
## Les sept Dresseurs de la Route 8 (jalon 20 T17, jalon-20.md §2.10.6, §3 T17 ; dossier 23 §3.2,
## §20.1 et annexe A.6, textes 3 à 9 et 101 à 112) sur la **vraie scène avec ses PNJ**
## (`data/npcs/route_8.json`) :
## - cases, orientations et visions de la grille `tools/plans/route_8.txt` ; la vue réelle
##   (`TrainerRules.sight_distance` sur la vraie grille) = la vue de la grille ; aucun PNJ, objet
##   ni Pokémon d'ambiance sur une ligne de vue ;
## - **D1, D2, D4 et D5 inévitables** (avec tous les PNJ posés), **D3, D6 et D7 évitables** (un à
##   un et ensemble) ; un Dresseur arrêté à n'importe quelle distance ne ferme jamais la route ;
## - données : prénoms (valeur par défaut validée), équipes, récompenses (base × niveau du dernier
##   Pokémon), IA `random`, modèles peints, répliques mot pour mot ;
## - Boot réel : le **duo D4 / D5** — Margot (D5) voit le joueur la première, jamais deux scènes
##   à la fois ; battue, Iris (D4) défie au pas suivant ; deux combats successifs, jamais en duo.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const MemoryFs := preload("res://tests/helpers/memory_file_system.gd")
const FixedClock := preload("res://tests/helpers/fixed_clock.gd")
const BOOT_SCENE := preload("res://game/boot.tscn")
const MAP_PATH := "res://game/world/maps/route_8.tscn"
const PLAN_PATH := "res://tools/plans/route_8.txt"
const START := "res://tools/debug_start/route_8.json"
const SAVE_PATH := "user://test_route_8_trainers_save.json"
const SIZE := Vector2i(80, 26)
const EAST: Array[Vector2i] = [Vector2i(79, 10), Vector2i(79, 11), Vector2i(79, 12)]
const INF := 1 << 30
const FADE := 0.05
const TIMEOUT := 12.0
const SCENE_TIMEOUT_MS := 120000
## Identifiant de la grille → [clé du PNJ, Dresseur, modèle peint, nom, équipe, ₽, avant, battu, après].
const TRAINERS := {
	"d1_intello": ["anatole", &"route_8_nerd_anatole", "nerd", "Intello Anatole",
		[[&"voltorb", 20], [&"koffing", 20], [&"voltorb", 20], [&"voltorb", 20]], 500,
		["Mes calculs disaient que personne ne passerait aujourd'hui."],
		["Il faut que je revoie mes calculs."],
		["La probabilité de te revoir est faible.", "Mais pas nulle."]],
	"d2_joueur": ["rene", &"route_8_gambler_rene", "gambler", "Joueur René",
		[[&"horsea", 22], [&"horsea", 22], [&"goldeen", 22]], 1540,
		["On parie ? Non ? Tant pis, on se bat quand même."],
		["Je n'aurais pas misé sur moi."],
		["Au Casino, on ne gagne jamais contre la maison.",
			"Contre toi non plus, apparemment."]],
	"d3_intello": ["firmin", &"route_8_nerd_firmin", "nerd", "Intello Firmin",
		[[&"koffing", 22], [&"arbok", 22], [&"koffing", 22]], 550,
		["Mes Pokémon sont le résultat de longues expériences."],
		["L'expérience a échoué."],
		["Je note tout dans mon carnet. Même mes défaites."]],
	"d4_fillette": ["iris", &"route_8_lass_iris", "lass", "Fillette Iris",
		[[&"nidoran_f", 23], [&"nidorina", 23]], 345,
		["Toutes les deux, on ne perd jamais !"], ["D'accord, presque jamais."],
		["On va s'entraîner encore.", "Toutes les deux."]],
	"d5_fillette": ["margot", &"route_8_lass_margot", "lass", "Fillette Margot",
		[[&"meowth", 24], [&"meowth", 24], [&"meowth", 24]], 360,
		["Enfin… presque jamais."], ["D'accord, presque jamais."],
		["Mes Miaouss ont trouvé une pièce dans l'herbe.", "C'est toujours ça."]],
	"d6_joueur": ["fernand", &"route_8_gambler_fernand", "gambler", "Joueur Fernand",
		[[&"growlithe", 24], [&"vulpix", 24]], 1680,
		["Tu as l'air d'avoir de la chance.", "Voyons si elle tient."],
		["La chance a tourné."],
		["À Céladopole, tout le monde parle du Casino. Moi, je n'y mets plus les pieds."]],
	"d7_fillette": ["nina", &"route_8_lass_nina", "lass", "Fillette Nina",
		[[&"clefairy", 22], [&"clefairy", 22]], 330,
		["Mes Mélofée dansent mieux qu'elles ne se battent.",
			"Mais elles se battent quand même !"],
		["Elles ont perdu en dansant…"],
		["Lavanville est juste derrière.", "Moi, je n'aime pas trop y aller."]],
}
const INEVITABLE: Array[String] = ["d1_intello", "d2_joueur", "d4_fillette", "d5_fillette"]
const AVOIDABLE: Array[String] = ["d3_intello", "d6_joueur", "d7_fillette"]

var _plan: PlanGrid
var _map: GameMap
var _grid: GridWorld
var _fs: MemoryFs
var _boot: Boot
var _player: Player
var _saved_router: Array = []
var _scenes: Array[StringName] = []
var _pages: Array[String] = []


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
	GameState.clock = FixedClock.new("2026-10-20T15:00:00")
	_fs = MemoryFs.new()
	_scenes.clear()
	_pages.clear()


func after_each() -> void:
	SceneRouter.fade_out_duration = _saved_router[0]
	SceneRouter.fade_in_duration = _saved_router[1]
	GameState.clock = DeviceClock.new()
	for action: StringName in [&"move_up", &"move_down", &"move_left", &"move_right",
			&"interact"]:
		Input.action_release(action)


# --- Vraie scène et ses PNJ ----------------------------------------------------------------

func _spec(grid_id: String) -> NpcSpec:
	return _map.get_npc(StringName(TRAINERS[grid_id][0])).get_spec()


## Relief de la scène + case de chaque PNJ posé (les Dresseurs coupent le passage).
func _real_world() -> GridWorld:
	var grid := GridPaths.relief(_grid, SIZE)
	for npc: Npc in _map.get_npcs():
		grid.set_solid(npc.get_cell())
	for cell: Vector2i in _plan.blocking_cells():
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


func _steps(world: GridWorld, target: Vector2i) -> int:
	return int(GridPaths.distances(world, EAST).get(target, INF))


func _without(cells: Array) -> GridWorld:
	var world := _real_world()
	for cell: Vector2i in cells:
		world.set_solid(cell)
	return world


func test_seven_trainers_on_their_grid_cells() -> void:
	var count := 0
	for npc: Npc in _map.get_npcs():
		if npc.get_spec().is_trainer():
			count += 1
	assert_eq(count, 7, "sept Dresseurs")
	for id: String in TRAINERS:
		var npc := _map.get_npc(StringName(TRAINERS[id][0]))
		assert_not_null(npc, "%s posé" % id)
		if npc == null:
			continue
		var spec := npc.get_spec()
		assert_eq(spec.cell, _plan.cell_of(id), "%s : case de la grille" % id)
		assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(id, "facing")), id)
		assert_eq(spec.sight, int(_plan.attr(id, "sight")), "%s : vision" % id)
		assert_eq(spec.trainer_id, TRAINERS[id][1])
		assert_eq(spec.sprite, StringName(TRAINERS[id][2]), "%s : modèle peint" % id)
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


func test_inevitable_and_avoidable_with_every_npc() -> void:
	var underground := _plan.cell_of("porte_souterrain")
	var gate := _plan.cell_of("porte_poste")
	assert_lt(_steps(_real_world(), underground), INF, "souterrain atteignable avec tous les PNJ")
	assert_lt(_steps(_real_world(), gate), INF, "poste atteignable avec tous les PNJ")
	for id: String in INEVITABLE:
		var blocked := _real_sight(_spec(id)).keys()
		assert_eq(_steps(_without(blocked), underground), INF, "%s inévitable" % id)
	var seen: Array = []
	for id: String in AVOIDABLE:
		var blocked := _real_sight(_spec(id)).keys()
		assert_lt(_steps(_without(blocked), underground), INF, "%s évitable" % id)
		seen.append_array(blocked)
	assert_lt(_steps(_without(seen), underground), INF, "D3, D6 et D7 évitables ensemble")


func test_a_trainer_stopped_anywhere_never_closes_the_route() -> void:
	var underground := _plan.cell_of("porte_souterrain")
	for id: String in TRAINERS:
		var spec := _spec(id)
		for distance: int in range(1, spec.sight + 1):
			var stop := spec.cell + spec.facing * (distance - 1)
			var world := _real_world()
			world.set_solid(spec.cell, false)
			world.set_solid(stop, true)
			assert_lt(_steps(world, underground), INF, "%s arrêté en %s ferme la route" % [id, stop])


func test_the_duo_stands_side_by_side_and_each_covers_its_own_column() -> void:
	var iris := _spec("d4_fillette")
	var margot := _spec("d5_fillette")
	assert_eq(margot.cell - iris.cell, Vector2i(1, 0), "côte à côte")
	assert_eq(iris.facing, margot.facing)
	var iris_sight := _real_sight(iris)
	var margot_sight := _real_sight(margot)
	for cell: Vector2i in iris_sight:
		assert_eq(cell.x, iris.cell.x, "Iris ne voit que sa colonne")
		assert_false(margot_sight.has(cell), "les deux colonnes ne se recouvrent pas")


func test_trainer_data_teams_prizes_and_lines() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir(), "données Pokémon")
	var library := TrainerLibrary.new(data)
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	for id: String in TRAINERS:
		var row: Array = TRAINERS[id]
		var spec := _spec(id)
		var trainer := library.get_trainer(row[1])
		assert_not_null(trainer, "%s dans data/trainers" % row[1])
		if trainer == null:
			continue
		assert_eq(trainer.name, row[3])
		assert_eq(trainer.ai, &"random", "%s : débutant" % id)
		assert_eq(trainer.prize_money, row[5], "%s : récompense (base × dernier niveau)" % id)
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
		assert_eq(team, row[4], "%s : équipe du §2.10.6" % id)
		var expected: Dictionary[StringName, Array] = {
			spec.before_dialogue: row[6], spec.defeated_dialogue: row[7], spec.dialogue: row[8],
		}
		for dialogue_id: StringName in expected:
			var dialogue := dialogues.get_dialogue(dialogue_id)
			assert_not_null(dialogue, "%s : %s" % [id, dialogue_id])
			if dialogue == null:
				continue
			assert_eq(dialogue.speaker, row[3])
			var texts: Array = []
			for page: DialoguePage in dialogue.variants[0].pages:
				texts.append(page.text.replace("\n", " "))
			assert_eq(texts, expected[dialogue_id], "%s : texte validé" % dialogue_id)


# --- Boot réel : le duo D4 / D5 ------------------------------------------------------------

func _start(cell: Vector2i, facing: Vector2i) -> void:
	_boot = BOOT_SCENE.instantiate() as Boot
	_boot.save_system = SaveSystem.new(_fs, SAVE_PATH)
	_boot.start_map = &"route_8"
	_boot.start_spawn = &"from_lavender_c"
	_boot.start_facing = Vector2i.LEFT
	add_child_autofree(_boot)
	_player = _boot.get_player()
	_boot.get_dialogue_runner().chars_per_second = 0.0
	var start := DebugStart.new()
	assert_true(start.load_file(START, _boot.get_pokemon_data(), _boot.get_item_library()),
		"\n".join(start.get_errors()))
	start.apply(GameState, _boot.get_pokemon_data())
	GameState.rng = GameRng.new(7)
	_boot.get_battle_director().speed_scale = 0.0
	# Un champion de Nv. 60 : chaque combat se règle en quelques tours.
	var champion := PokemonFactory.create(_boot.get_pokemon_data(), &"charmander", 60,
		GameState.rng)
	champion.moves.clear()
	champion.moves.append(MoveSlot.new(&"ember", 25))
	while GameState.party.size() > 0:
		GameState.party.remove_at(0)
	GameState.party.add(champion)
	_boot.get_cutscene_director().cutscene_started.connect(
		func(id: StringName) -> void: _scenes.append(id))
	_boot.get_dialogue_runner().page_started.connect(func(_index: int) -> void:
		_pages.append(_boot.get_dialogue_box().get_text()))
	await wait_process_frames(3)
	_boot.get_map().spawn_player_at(_player, cell, facing)
	await wait_process_frames(3)


func _walk(direction: Vector2i, until: Vector2i) -> void:
	var action: StringName = &"move_left" if direction == Vector2i.LEFT else &"move_right"
	# Relâcher pendant le dernier pas : la touche encore enfoncée à l'arrivée enchaînerait un pas
	# de trop (comme _walk_to de test_rival_route22).
	var seen := _scenes.size()
	Input.action_press(action)
	await wait_until(func() -> bool: return _player.get_cell() == until \
		or (_player.is_moving() and _player.get_cell() + direction == until) \
		or _scenes.size() > seen, TIMEOUT)
	Input.action_release(action)
	await wait_until(func() -> bool: return not _player.is_moving(), TIMEOUT)


## Déroule la scène en cours : pages, carte, combat piloté (Attaque, première capacité).
func _play_scene() -> void:
	var director := _boot.get_cutscene_director()
	var runner := _boot.get_dialogue_runner()
	var box := _boot.get_dialogue_box()
	var battle_director := _boot.get_battle_director()
	var battle_hud := _boot.get_battle_hud()
	await wait_until(func() -> bool: return director.is_running(), TIMEOUT)
	var deadline := Time.get_ticks_msec() + SCENE_TIMEOUT_MS
	while (director.is_running() or runner.is_running() or SceneRouter.is_transitioning()) \
			and Time.get_ticks_msec() < deadline:
		if battle_director.is_running():
			var battle := battle_director.get_battle()
			if battle != null and battle.get_state() == Battle.State.CHOOSING:
				match battle_hud.get_zone():
					BattleHud.Zone.ACTIONS:
						battle_hud.action_selected.emit(ActionGrid.ATTACK)
					BattleHud.Zone.MOVES:
						battle_hud.move_selected.emit(0)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	await wait_process_frames(5)


func test_the_duo_fights_one_after_the_other_never_together() -> void:
	await _start(Vector2i(62, 12), Vector2i.LEFT)
	# Marcher vers l'ouest sur la rangée du goulet : Margot (D5, colonne 59) voit la première.
	await _walk(Vector2i.LEFT, Vector2i(59, 12))
	assert_eq(_scenes, [&"trainer_route_8_lass_margot"] as Array[StringName],
		"une seule scène, celle de Margot")
	await _play_scene()
	assert_true(GameState.flags.has_flag(&"beaten_route_8_lass_margot"), "Margot battue")
	assert_false(GameState.flags.has_flag(&"beaten_route_8_lass_iris"), "Iris pas encore")
	assert_eq(_scenes, [&"trainer_route_8_lass_margot"] as Array[StringName],
		"Iris n'a pas défié en même temps")
	assert_eq(_pages[0], "Enfin… presque jamais.", "réplique « avant » de Margot")
	assert_true(_pages.has("D'accord, presque jamais."), "réplique « vaincu » de Margot")
	# Un pas de plus vers l'ouest : la colonne d'Iris (D4).
	await _walk(Vector2i.LEFT, Vector2i(58, 12))
	await _play_scene()
	assert_true(GameState.flags.has_flag(&"beaten_route_8_lass_iris"), "Iris battue ensuite")
	assert_eq(_scenes, [&"trainer_route_8_lass_margot", &"trainer_route_8_lass_iris"]
		as Array[StringName], "deux scènes successives, jamais en duo")
	assert_true(_pages.has("Toutes les deux, on ne perd jamais !"), "réplique « avant » d'Iris")
	assert_eq(GameState.money, 6000 + 360 + 345, "deux récompenses (base × niveau)")
	# Battues, elles ne défient plus : le pas suivant ne lance rien.
	var count := _scenes.size()
	await _walk(Vector2i.LEFT, Vector2i(57, 12))
	await wait_process_frames(20)
	assert_eq(_scenes.size(), count, "plus de défi")
