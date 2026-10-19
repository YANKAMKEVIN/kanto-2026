extends GutTest
## Les 9 cartes du S.S. Anne et l'Arène de Carmin (jalon 16 T11, `jalon-16.md` §2.10, dossier 19
## §0.4) sur les vraies scènes : métadonnées, lumière, zone et liste des intérieurs ; cases solides
## = grille validée (`tools/plans/ss_anne_*.txt`, `carmin_arene.txt`) ; raccords internes (chaque
## porte, escalier et sortie de la grille porte un passage vers la bonne pièce, arrivée à côté du
## passage retour) ; raccord à Carmin par identifiants (`from_ss_anne_w|e`, `from_gym`, `entrance`) ;
## vision des Dresseurs des grilles sur la vraie carte (aucun regard à travers un mur, 0 Dresseur
## inévitable sur le pont principal, rival inévitable dans le couloir) ; puzzle des interrupteurs
## sur la vraie Arène (15 poubelles, voisins de la grille 5 × 3 = voisins sur la carte, barrière
## fermée puis ouverte) ; budget de nœuds.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GridPaths := preload("res://tests/helpers/grid_paths.gd")
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
## Carte → [grille, taille, intérieur].
const MAPS := {
	&"ss_anne_main_deck": ["ss_anne_pont_principal.txt", Vector2i(26, 13), true],
	&"ss_anne_captain_corridor": ["ss_anne_couloir_capitaine.txt", Vector2i(18, 7), true],
	&"ss_anne_captain_room": ["ss_anne_cabine_capitaine.txt", Vector2i(14, 10), true],
	&"ss_anne_restaurant": ["ss_anne_restaurant.txt", Vector2i(18, 11), true],
	&"ss_anne_lower_deck": ["ss_anne_pont_inferieur.txt", Vector2i(22, 11), true],
	&"ss_anne_outer_deck": ["ss_anne_pont_exterieur.txt", Vector2i(26, 11), false],
	&"ss_anne_cabin_a": ["ss_anne_cabine_a.txt", Vector2i(12, 9), true],
	&"ss_anne_cabin_b": ["ss_anne_cabine_b.txt", Vector2i(12, 9), true],
	&"ss_anne_cabin_c": ["ss_anne_cabine_c.txt", Vector2i(12, 9), true],
	&"vermilion_gym": ["carmin_arene.txt", Vector2i(17, 15), true],
}
## Passages attendus : carte → { position de la grille : [carte cible, spawn d'arrivée] }.
const LINKS := {
	&"ss_anne_main_deck": {
		"sortie": [&"vermilion_city", &""], "porte_cabine_a": [&"ss_anne_cabin_a", &"entrance"],
		"porte_cabine_c": [&"ss_anne_cabin_c", &"entrance"],
		"porte_capitaine": [&"ss_anne_captain_corridor", &"entrance"],
		"porte_restaurant": [&"ss_anne_restaurant", &"entrance"],
		"porte_exterieur": [&"ss_anne_outer_deck", &"entrance"],
		"escalier_bas": [&"ss_anne_lower_deck", &"entrance"],
	},
	&"ss_anne_captain_corridor": {
		"sortie": [&"ss_anne_main_deck", &"from_corridor"],
		"porte_capitaine": [&"ss_anne_captain_room", &"entrance"],
	},
	&"ss_anne_captain_room": {"sortie": [&"ss_anne_captain_corridor", &"from_captain_room"]},
	&"ss_anne_restaurant": {"porte": [&"ss_anne_main_deck", &"from_restaurant"]},
	&"ss_anne_lower_deck": {
		"escalier_haut": [&"ss_anne_main_deck", &"from_lower_deck"],
		"porte_cabine_b": [&"ss_anne_cabin_b", &"entrance"],
	},
	&"ss_anne_outer_deck": {"porte": [&"ss_anne_main_deck", &"from_outer_deck"]},
	&"ss_anne_cabin_a": {"sortie": [&"ss_anne_main_deck", &"from_cabin_a"]},
	&"ss_anne_cabin_b": {"sortie": [&"ss_anne_lower_deck", &"from_cabin_b"]},
	&"ss_anne_cabin_c": {"sortie": [&"ss_anne_main_deck", &"from_cabin_c"]},
	&"vermilion_gym": {"sortie": [&"vermilion_city", &"from_gym"]},
}
const DIRECTIONS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}
## Budget du plan (§2.13).
const MAX_NODES := 3000

var _maps: Dictionary = {}
var _plans: Dictionary = {}


func before_all() -> void:
	for id: StringName in MAPS:
		var map := (load(MapCatalog.scene_path(id)) as PackedScene).instantiate() as GameMap
		add_child(map)
		_maps[id] = map
		var plan := PlanGrid.new()
		assert_true(plan.load_file("res://tools/plans/" + MAPS[id][0]), plan.error)
		_plans[id] = plan


func after_all() -> void:
	for map: GameMap in _maps.values():
		map.free()
	_maps.clear()


func test_metadata_light_zone_and_interiors() -> void:
	var lighting := LightingLibrary.new()
	lighting.load_file()
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	var interiors := MapCatalog.load_interiors()
	for id: StringName in MAPS:
		var map: GameMap = _maps[id]
		var ship := String(id).begins_with("ss_anne_")
		assert_eq(map.map_id, id)
		assert_eq(map.size, MAPS[id][1], String(id))
		assert_eq(map.interior, MAPS[id][2], String(id))
		assert_eq(interiors.has(id), MAPS[id][2], "%s : liste des intérieurs" % id)
		assert_eq(map.light_profile, &"golden_hour" if id == &"ss_anne_outer_deck"
			else &"interior_warm", String(id))
		assert_eq(lighting.get_map_profile(id), map.light_profile, String(id))
		assert_eq(zones.zone_of(id), &"ss_anne" if ship else &"vermilion_city", String(id))
		assert_eq(map.display_name, "S.S. Anne" if ship else "Carmin-sur-Mer", String(id))
		if ship:
			assert_eq(map.region, "Le grand paquebot de Kanto", "lot de textes §0.5 n° 1")
	var zone := zones.get_zone(&"ss_anne")
	assert_eq(zone.name, "S.S. Anne")
	assert_eq(zone.subtitle, "Le grand paquebot de Kanto")
	# Décision de Kevin du 2026-10-16 : titre de zone dès le pont principal (intérieur).
	assert_true(zone.interior_title)
	assert_true(zones.interior_title_of(&"ss_anne_main_deck"))
	assert_false(zones.interior_title_of(&"vermilion_gym"), "l'Arène reste sans titre")
	for id: StringName in zones.get_ids():
		assert_eq(zones.get_zone(id).interior_title, id == &"ss_anne",
			"%s : titre à l'intérieur" % id)


func test_solid_cells_follow_the_grid() -> void:
	for id: StringName in MAPS:
		var plan: PlanGrid = _plans[id]
		var grid := (_maps[id] as GameMap).get_grid()
		assert_eq(Vector2i(plan.width, plan.height), MAPS[id][1], String(id))
		for y: int in plan.height:
			for x: int in plan.width:
				var cell := Vector2i(x, y)
				assert_eq(grid.is_solid(cell), not plan.is_walkable(cell),
					"%s %s « %s »" % [id, cell, plan.at(cell)])


## Chaque case `D`, `S` ou `X` de la grille porte exactement un passage, et chaque passage est
## sur une telle case ; la position de la grille mène à la pièce attendue.
func test_every_door_stair_and_exit_of_the_grid_is_a_warp() -> void:
	for id: StringName in MAPS:
		var plan: PlanGrid = _plans[id]
		var map: GameMap = _maps[id]
		var cells := plan.cells_of("DSX")
		assert_eq(map.get_warps().size(), cells.size(), String(id))
		for cell: Vector2i in cells:
			assert_eq(map.get_warps().get_at(cell).size(), 1, "%s %s" % [id, cell])
		for position: String in LINKS[id]:
			for cell: Vector2i in plan.cells_at(position):
				var found := map.get_warps().get_at(cell)
				if found.size() != 1:
					continue
				var expected: Array = LINKS[id][position]
				assert_eq(found[0].target_map, expected[0], "%s/%s" % [id, position])
				if expected[1] != &"":
					assert_eq(found[0].target_spawn, expected[1], "%s/%s" % [id, position])
				assert_false(found[0].is_coming_soon(), "%s/%s" % [id, position])


## Raccords internes dans les deux sens : l'arrivée est praticable et voisine (ou sur la case)
## d'un passage qui ramène à la pièce d'origine.
func test_internal_links_are_reversible() -> void:
	for id: StringName in MAPS:
		for warp: Warp in (_maps[id] as GameMap).get_warps().get_all():
			if not _maps.has(warp.target_map):
				continue
			var target: GameMap = _maps[warp.target_map]
			var label := "%s %s → %s/%s" % [id, warp.cell, warp.target_map, warp.target_spawn]
			assert_true(target.has_spawn(warp.target_spawn), label)
			var arrival := target.get_spawn_cell(warp.target_spawn)
			assert_true(target.get_grid().is_free(arrival), "%s : arrivée libre" % label)
			var back := false
			for other: Warp in target.get_warps().get_all():
				if other.target_map == id and (other.cell == arrival
						or Grid.is_cardinal(other.cell - arrival)):
					back = true
			assert_true(back, "%s : passage retour à côté de l'arrivée" % label)


## Carmin (vraie carte du J15, branchée au T15) : la passerelle du navire ramène sur
## `from_ss_anne_w|e` (31..32, 27), juste au-dessus de l'embarquement `BoardingW|E`, qui mène au
## pont principal (`from_ss_anne_w|e`, juste au-dessus de la passerelle) ; l'Arène ramène sur
## `from_gym`, la porte `DoorGymW|E` mène à son `entrance`.
func test_links_to_carmin_by_identifiers() -> void:
	var city := (load(MapCatalog.scene_path(&"vermilion_city")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(city)
	var deck: GameMap = _maps[&"ss_anne_main_deck"]
	for pair: Array in [[Vector2i(12, 11), &"from_ss_anne_w", Vector2i(31, 27), &"BoardingW"],
			[Vector2i(13, 11), &"from_ss_anne_e", Vector2i(32, 27), &"BoardingE"]]:
		var exit := deck.get_warps().find_on_push(pair[0], Vector2i.DOWN)
		assert_not_null(exit, "passerelle %s" % pair[0])
		if exit != null:
			assert_eq([exit.target_map, exit.target_spawn], [&"vermilion_city", pair[1]])
		assert_eq(city.get_spawn_cell(pair[1]), pair[2], "quai de Carmin")
		var boarding := city.get_node(NodePath("Warps/" + String(pair[3]))) as WarpPoint
		assert_eq(boarding.target_spawn, pair[1])
		assert_eq(boarding.target_map, &"ss_anne_main_deck", "embarquement branché (T15)")
		assert_eq(boarding.coming_soon, "", "plus « à venir »")
		assert_true(deck.has_spawn(boarding.target_spawn), "arrivée de l'embarquement à bord")
		assert_true(Grid.is_cardinal(deck.get_spawn_cell(pair[1]) - (pair[0] as Vector2i)),
			"arrivée à bord juste au-dessus de la passerelle")
	var gym: GameMap = _maps[&"vermilion_gym"]
	for x: int in [7, 8, 9]:
		var exit := gym.get_warps().find_on_push(Vector2i(x, 13), Vector2i.DOWN)
		assert_not_null(exit)
		if exit != null:
			assert_eq([exit.target_map, exit.target_spawn], [&"vermilion_city", &"from_gym"])
	assert_true(city.has_spawn(&"from_gym"))
	assert_eq(gym.get_spawn_cell(&"entrance"), Vector2i(8, 12))
	for door: String in ["DoorGymW", "DoorGymE"]:
		var point := city.get_node(NodePath("Warps/" + door)) as WarpPoint
		assert_eq([point.target_map, point.target_spawn, point.coming_soon],
			[&"vermilion_gym", &"entrance", ""], "porte de l'Arène branchée (T15)")


## Vue de chaque Dresseur des grilles sur la vraie carte (occupants : les positions `bloque` des
## grilles) : il voit au moins sa première case, jamais à travers un mur.
func test_trainer_sight_lines_on_the_real_maps() -> void:
	var count := 0
	for id: StringName in MAPS:
		var grid := _occupied_relief(id)
		for trainer: Dictionary in _trainers(id):
			count += 1
			var seen: Array[Vector2i] = trainer["seen"]
			assert_gt(seen.size(), 0, "%s/%s voit devant lui" % [id, trainer["id"]])
			for cell: Vector2i in seen:
				assert_false(grid.is_solid(cell), "%s/%s : %s" % [id, trainer["id"], cell])
	assert_eq(count, 13, "10 Dresseurs du navire et 3 de l'Arène (dossier 19 §3)")


## Pont principal (G-9) : depuis la passerelle, toutes les portes et l'escalier s'atteignent sans
## entrer dans aucune vue (0 Dresseur inévitable).
func test_main_deck_avoids_every_trainer() -> void:
	var id := &"ss_anne_main_deck"
	var plan: PlanGrid = _plans[id]
	var grid := _occupied_relief(id)
	for trainer: Dictionary in _trainers(id):
		for cell: Vector2i in trainer["seen"]:
			grid.set_solid(cell)
	var stops := _stops(plan)
	var reached := GridPaths.distances(grid, [plan.cell_of("entree")], stops)
	for position: String in ["porte_capitaine", "porte_cabine_a", "porte_cabine_c",
			"porte_restaurant", "porte_exterieur", "escalier_bas", "sortie"]:
		assert_true(reached.has(plan.cell_of(position)), "%s sans être vu" % position)


## Couloir : le déclencheur du rival (colonne 7) barre toute la largeur ; sans lui, la porte du
## capitaine s'atteint (le rival, PNJ du T13, est relu à part : test_ss_anne_rival_captain).
func test_corridor_trigger_column_spans_the_corridor() -> void:
	var id := &"ss_anne_captain_corridor"
	var plan: PlanGrid = _plans[id]
	var grid := GridPaths.relief((_maps[id] as GameMap).get_grid(), Vector2i(plan.width,
		plan.height))
	var start := plan.cell_of("entree")
	var door := plan.cell_of("porte_capitaine")
	assert_true(GridPaths.distances(grid, [start], _stops(plan)).has(door))
	for cell: Vector2i in plan.cells_at("declencheur_rival"):
		grid.set_solid(cell)
	assert_false(GridPaths.distances(grid, [start], _stops(plan)).has(door),
		"on ne contourne pas le rival")


## Arène : 15 poubelles du puzzle `vermilion_gym`, emplacement = index de la grille ; deux
## emplacements voisins dans la grille 5 × 3 de `SwitchPuzzle` sont des poubelles voisines sur la
## carte (3 colonnes ou 2 rangées d'écart, sans rien entre elles).
func test_gym_bins_are_the_puzzle_slots() -> void:
	var map: GameMap = _maps[&"vermilion_gym"]
	var plan: PlanGrid = _plans[&"vermilion_gym"]
	var cells: Dictionary = {}
	for position: String in plan.positions:
		if plan.positions[position]["kind"] != "interactif":
			continue
		var cell := plan.cell_of(position)
		var found := map.get_interactions().get_at(cell)
		assert_eq(found.size(), 1, position)
		if found.size() != 1:
			continue
		assert_true(map.get_grid().is_solid(cell))
		assert_eq(found[0].puzzle, &"vermilion_gym")
		assert_eq(found[0].puzzle_slot, int(plan.attr(position, "index")), position)
		assert_eq(found[0].dialogue_id, &"vermilion_gym_trash")
		cells[found[0].puzzle_slot] = cell
	assert_eq(cells.size(), 15)
	var puzzle := SwitchPuzzle.new(GameRng.new(1))
	for a: int in range(1, 16):
		for b: int in range(1, 16):
			var offset: Vector2i = cells[b] - cells[a]
			var adjacent := offset.abs() == Vector2i(3, 0) or offset.abs() == Vector2i(0, 2)
			assert_eq(puzzle.neighbors(a).has(b), adjacent, "%d, %d" % [a, b])


func test_gym_puzzle_data_and_barrier() -> void:
	var library := SwitchPuzzleLibrary.new()
	assert_true(library.load_file(), "\n".join(library.get_errors()))
	var spec := library.get_spec(&"vermilion_gym")
	assert_not_null(spec)
	if spec == null:
		return
	assert_eq([spec.columns, spec.rows, spec.solved_flag], [5, 3,
		&"vermilion_gym_puzzle_solved"])
	var dialogues := DialogueLibrary.new()
	dialogues.load_dir()
	assert_eq(dialogues.get_dialogue(spec.nothing).variants[0].pages[0].text,
		"Rien… juste des papiers froissés.", "GYM-01")
	assert_eq(dialogues.get_dialogue(spec.first).variants[0].pages[0].text,
		"Un interrupteur !\nLe premier verrou cède.", "GYM-02")
	assert_eq(dialogues.get_dialogue(spec.reset).variants[0].pages[0].text,
		"Mauvais interrupteur !\nLes verrous se referment.", "GYM-04")
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	var steps := cutscenes.get_cutscene(spec.solved_cutscene).variants[0].steps
	assert_eq(steps[0].dialogue_id, &"vermilion_gym_switch_solved")
	assert_eq(dialogues.get_dialogue(steps[0].dialogue_id).variants[0].pages[0].text,
		"Le second interrupteur !\nLa barrière s'ouvre !", "GYM-03")
	assert_eq(steps[-1].flags, [spec.solved_flag] as Array[StringName], "drapeau en dernier")
	var despawned: Array[StringName] = []
	for step: CutsceneStep in steps:
		if step.kind == CutsceneStep.Kind.DESPAWN:
			despawned.append(step.actor)
	var map: GameMap = _maps[&"vermilion_gym"]
	var barrier: Array[StringName] = []
	for npc: Npc in map.get_npcs():
		if not String(npc.get_id()).begins_with("vermilion_gym_barrier_"):
			continue  # Major Bob, ses Dresseurs et le guide (T14)
		barrier.append(npc.get_id())
		assert_eq(npc.get_cell().y, 5)
	assert_eq(despawned, barrier, "la scène retire les trois segments")
	assert_eq(barrier.size(), 3)


## Barrière fermée : Major Bob (8, 3) hors d'atteinte, les 15 poubelles fouillables ; une partie
## du puzzle sur la vraie carte (premier tiré, second voisin), drapeau levé : la barrière
## disparaît et Major Bob s'atteint.
func test_gym_puzzle_played_on_the_real_map() -> void:
	var map := (load(MapCatalog.scene_path(&"vermilion_gym")) as PackedScene).instantiate() \
		as GameMap
	add_child_autofree(map)
	var plan: PlanGrid = _plans[&"vermilion_gym"]
	var start := plan.cell_of("entree")
	var bob_front := plan.cell_of("major_bob") + Vector2i.DOWN
	var reach := map.get_grid().find_reachable(start)
	assert_false(reach.has(bob_front), "barrière fermée")
	for position: String in plan.positions:
		if plan.positions[position]["kind"] == "interactif":
			var cell := plan.cell_of(position)
			var near := false
			for direction: Vector2i in DIRECTIONS.values():
				near = near or reach.has(cell + direction)
			assert_true(near, "%s fouillable" % position)
	var puzzle := SwitchPuzzle.new(ScriptedRng.new([8, 1]))
	puzzle.start()
	assert_eq(puzzle.search(1), SwitchPuzzle.Result.NOTHING)
	assert_eq(puzzle.search(8), SwitchPuzzle.Result.FIRST_FOUND)
	assert_eq(puzzle.search(puzzle.second()), SwitchPuzzle.Result.SOLVED)
	var flags := StoryFlags.new()
	flags.set_flag(&"vermilion_gym_puzzle_solved")
	map.refresh_npcs(flags)
	for npc: Npc in map.get_npcs():
		assert_false(String(npc.get_id()).begins_with("vermilion_gym_barrier_"), "barrière ouverte")
	assert_true(map.get_grid().find_reachable(start).has(bob_front), "Major Bob accessible")


## Départs de débogage des vraies cartes (T11) : chargés sans erreur, posés sur une case libre.
func test_debug_starts_land_on_the_real_maps() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var items := ItemLibrary.new()
	items.load_dir()
	for pair: Array in [["ss_anne", &"ss_anne_main_deck"], ["vermilion_gym_map",
			&"vermilion_gym"], ["vermilion_gym_solved", &"vermilion_gym"],
			["surge_weak", &"vermilion_gym"], ["thunder_no_tm", &"vermilion_gym"]]:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % pair[0], data, items),
			"\n".join(start.get_errors()))
		assert_eq(start.map, pair[1])
		assert_false(start.autosave, "ne remplace jamais la sauvegarde")
		var map: GameMap = _maps[pair[1]]
		assert_true(map.has_spawn(start.spawn), pair[0])
		assert_true(map.get_grid().is_free(map.get_spawn_cell(start.spawn)), pair[0])


func test_node_budget() -> void:
	for id: StringName in MAPS:
		var count := GridPaths.count_nodes(_maps[id])
		assert_lt(count, MAX_NODES, "%s : %d nœuds" % [id, count])


# --- Outils -----------------------------------------------------------------------------------

## Relief de la vraie carte, positions `bloque` de la grille occupées (PNJ, objets, Dresseurs).
func _occupied_relief(id: StringName) -> GridWorld:
	var plan: PlanGrid = _plans[id]
	var grid := GridPaths.relief((_maps[id] as GameMap).get_grid(), Vector2i(plan.width,
		plan.height))
	for cell: Vector2i in plan.blocking_cells():
		if not grid.is_solid(cell):
			grid.occupy(cell, RefCounted.new())
	return grid


## Dresseurs de la grille : id, case, cases vues sur la vraie carte ([TrainerRules]).
func _trainers(id: StringName) -> Array[Dictionary]:
	var plan: PlanGrid = _plans[id]
	var grid := _occupied_relief(id)
	var result: Array[Dictionary] = []
	for position: String in plan.positions:
		if plan.positions[position]["kind"] != "dresseur":
			continue
		var from := plan.cell_of(position)
		var facing: Vector2i = DIRECTIONS[plan.attr(position, "facing")]
		var sight := int(plan.attr(position, "sight"))
		var seen: Array[Vector2i] = []
		for k: int in range(1, sight + 1):
			var cell := from + facing * k
			if TrainerRules.sight_distance(grid, from, facing, sight, cell) == k:
				seen.append(cell)
		result.append({"id": position, "cell": from, "seen": seen})
	return result


## Portes et escaliers : passages terminaux (on y entre, on ne les traverse pas).
func _stops(plan: PlanGrid) -> Dictionary:
	var stops: Dictionary = {}
	for cell: Vector2i in plan.cells_of("DS"):
		stops[cell] = true
	return stops
