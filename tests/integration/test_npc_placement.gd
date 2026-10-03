extends GutTest
## Invariants du jalon 3A (jalon-03.md §3.1, §3.2, §3.4, T4) sur les vraies cartes et les
## vrais fichiers data/npcs/*.json :
## - chaque PNJ se charge, sur la case du plan, dans la carte, ni sur un warp ni sur un
##   spawn, sur une case praticable (sauf Pokémon posé sur un meuble, lift > 0) ;
## - aucune poche : les PNJ ne ferment l'accès à aucune case ;
## - chaque cible (PNJ interactif, point d'examen) est utilisable depuis une case voisine
##   atteignable, avec le vrai InteractionFinder, le bon dialogue et le bon verbe ;
## - chaque apparence a ses propres SpriteFrames (pas le générique).
## Jalon 3B (T4) : ces invariants valent pour deux états de drapeaux, nouvelle partie (état
## de 3A) et { oak_met } (Chen et le rival au labo, chambre du rival vide), cartes chargées
## puis GameMap.refresh_npcs comme le fait Boot.

const TALK := Interaction.Kind.TALK
const EXAMINE := Interaction.Kind.EXAMINE
const OBSERVE := Interaction.Kind.OBSERVE
## Spawn de référence de chaque carte (départ du test d'accessibilité).
const FROM: Dictionary = {
	&"player_house_2f": &"stairs",
	&"player_house_1f": &"entrance",
	&"rival_house": &"entrance",
	&"oak_lab": &"entrance",
	&"pallet_town": &"start",
}
## Plan §3.1 : carte → id → [case, orientation, apparence, dialogue, verbe, lift].
const PLAN: Dictionary = {
	&"player_house_2f": {},
	&"player_house_1f": {
		&"mom": [Vector2i(7, 4), Vector2i.DOWN, &"mom", &"mom", TALK, 0],
	},
	&"rival_house": {
		&"rival": [Vector2i(13, 4), Vector2i.RIGHT, &"rival", &"rival", TALK, 0],
	},
	&"oak_lab": {
		&"maya": [Vector2i(5, 3), Vector2i.UP, &"maya", &"maya", TALK, 0],
		&"bulbasaur": [Vector2i(10, 5), Vector2i.DOWN, &"bulbasaur", &"observe_bulbasaur",
			OBSERVE, 56],
		&"charmander": [Vector2i(11, 5), Vector2i.DOWN, &"charmander", &"observe_charmander",
			OBSERVE, 56],
		&"squirtle": [Vector2i(12, 5), Vector2i.DOWN, &"squirtle", &"observe_squirtle",
			OBSERVE, 56],
	},
	&"pallet_town": {
		&"aoki": [Vector2i(29, 13), Vector2i.LEFT, &"aoki", &"aoki", TALK, 0],
		&"aoki_pidgey_1": [Vector2i(27, 13), Vector2i.RIGHT, &"pidgey", &"observe_aoki_pidgey",
			OBSERVE, 0],
		&"aoki_pidgey_2": [Vector2i(28, 14), Vector2i.UP, &"pidgey", &"observe_aoki_pidgey",
			OBSERVE, 0],
		&"leo": [Vector2i(18, 9), Vector2i.LEFT, &"leo", &"leo", TALK, 0],
		&"leo_rattata": [Vector2i(17, 9), Vector2i.RIGHT, &"rattata",
			&"observe_leo_rattata", OBSERVE, 0],
		&"haru": [Vector2i(3, 29), Vector2i.LEFT, &"haru", &"haru", TALK, 0],
		# Prairie du Nord (jalon 3B §3.1) : Pokémon d'ambiance, non interactifs.
		&"prairie_pidgey": [Vector2i(20, 3), Vector2i.DOWN, &"pidgey", &"", TALK, 0],
		&"prairie_rattata": [Vector2i(27, 2), Vector2i.LEFT, &"rattata", &"", TALK, 0],
	},
}
## Plan après l'événement de la Route 1 (jalon 3B §3.2) : seules différences avec PLAN.
const PLAN_OAK_MET: Dictionary = {
	&"rival_house": {},
	&"oak_lab": {
		&"oak": [Vector2i(8, 4), Vector2i.DOWN, &"oak", &"oak_lab_waiting", TALK, 0],
		&"rival": [Vector2i(9, 6), Vector2i.RIGHT, &"rival", &"rival_lab_waiting", TALK, 0],
	},
}
## Plan §3.2 : carte → nœud → [ancre, taille, dialogue].
const POINTS: Dictionary = {
	&"player_house_1f": {
		&"BreakfastTable": [Vector2i(3, 5), Vector2i(3, 2), &"breakfast_table"],
	},
	&"rival_house": {
		&"KantoMap": [Vector2i(15, 4), Vector2i(2, 3), &"rival_kanto_map"],
	},
	&"pallet_town": {
		&"SignPallet": [Vector2i(21, 13), Vector2i(1, 1), &"sign_pallet_town"],
	},
}
const DIRECTIONS: Array[Vector2i] = [
	Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
]

## Cartes en nouvelle partie (état de 3A).
var _maps: Dictionary = {}
## Mêmes cartes après refresh_npcs({ oak_met }).
var _maps_met: Dictionary = {}
## [nom de l'état, cartes, plan] : chaque invariant est vérifié dans les deux états.
var _states: Array[Array] = []


func before_all() -> void:
	var met := StoryFlags.new()
	met.set_flag(&"oak_met")
	for map_id: StringName in FROM:
		_maps[map_id] = _load_map(map_id)
		var after := _load_map(map_id)
		after.refresh_npcs(met)
		_maps_met[map_id] = after
	var plan_met: Dictionary = PLAN.duplicate()
	for map_id: StringName in PLAN_OAK_MET:
		var rows: Dictionary = {}
		if not (PLAN_OAK_MET[map_id] as Dictionary).is_empty():
			rows = (PLAN[map_id] as Dictionary).duplicate()
		rows.merge(PLAN_OAK_MET[map_id], true)
		plan_met[map_id] = rows
	_states = [["nouvelle partie", _maps, PLAN], ["oak_met", _maps_met, plan_met]]


func after_all() -> void:
	for map: GameMap in _maps.values() + _maps_met.values():
		map.free()
	_maps.clear()
	_maps_met.clear()
	_states.clear()


func _load_map(map_id: StringName) -> GameMap:
	var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap
	add_child(map)
	return map


func _warp_cells(map: GameMap) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for warp: Warp in map.get_warps().get_all():
		cells.append(warp.cell)
	return cells


func _spawn_cells(map: GameMap) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for marker: Node in map.get_node(^"Spawns").get_children():
		cells.append(Grid.world_to_cell((marker as Node2D).position))
	return cells


## Cases atteignables depuis le spawn de référence, PNJ en place (ou retirés).
func _reachable(map: GameMap, with_npcs: bool) -> Dictionary[Vector2i, bool]:
	var grid := map.get_grid()
	var from := map.get_spawn_cell(FROM[map.map_id])
	if with_npcs:
		return grid.find_reachable(from)
	for npc: Npc in map.get_npcs():
		grid.release(npc.get_cell(), npc)
	var reached := grid.find_reachable(from)
	for npc: Npc in map.get_npcs():
		grid.occupy(npc.get_cell(), npc)
	return reached


func test_rosters_load_without_error_and_match_the_plan() -> void:
	for map_id: StringName in PLAN:
		var roster := NpcRoster.load_for_map(map_id)
		assert_eq(roster.get_errors().size(), 0, "%s : %s" % [map_id, roster.get_errors()])
		assert_eq(FileAccess.file_exists(NpcRoster.path_for_map(map_id)),
			not (PLAN[map_id] as Dictionary).is_empty(), "%s : fichier de PNJ" % map_id)
	for state: Array in _states:
		for map_id: StringName in PLAN:
			_check_plan(state[0], state[1][map_id], state[2][map_id])


func _check_plan(state: String, map: GameMap, plan: Dictionary) -> void:
	var map_id := map.map_id
	var roster := NpcRoster.load_for_map(map_id)
	assert_eq(map.get_npcs().size(), plan.size(), "%s, %s : PNJ présents" % [state, map_id])
	for id: StringName in plan:
		var spec := roster.get_spec(id)
		var npc := map.get_npc(id)
		assert_not_null(spec, "%s/%s dans le fichier" % [map_id, id])
		assert_not_null(npc, "%s, %s/%s créé" % [state, map_id, id])
		if spec == null or npc == null:
			continue
		var row: Array = plan[id]
		var label := "%s, %s/%s" % [state, map_id, id]
		assert_eq(spec.cell, row[0], label + " case")
		assert_eq(spec.facing, row[1], label + " orientation")
		assert_eq(spec.sprite, row[2], label + " apparence")
		assert_eq(spec.dialogue, row[3], label + " dialogue")
		if spec.is_interactive():
			assert_eq(spec.verb, row[4], label + " verbe")
		assert_eq(spec.lift, row[5], label + " élévation")
		assert_eq(map.get_grid().get_occupant(spec.cell), npc, label + " occupe sa case")


func test_rival_does_not_turn_until_face_player() -> void:
	var spec := NpcRoster.load_for_map(&"rival_house").get_spec(&"rival")
	assert_false(spec.turn_to_player, "il ne se tourne qu'à « T'as choisi ton jour… »")


func test_every_npc_has_its_own_frames() -> void:
	for state: Array in _states:
		for map_id: StringName in PLAN:
			for npc: Npc in (state[1][map_id] as GameMap).get_npcs():
				var sprite := npc.get_spec().sprite
				assert_true(Npc.has_frames(sprite), "%s : %s_frames.tres" % [npc.get_id(), sprite])
				var anim := npc.get_node(^"%Sprite") as AnimatedSprite2D
				assert_eq(anim.sprite_frames.resource_path, Npc.frames_path(sprite))
				assert_eq(anim.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
				assert_eq(anim.scale, Vector2(2, 2))


func test_sprite_sizes_and_animations() -> void:
	var people: Array[StringName] = [&"mom", &"rival", &"maya", &"aoki", &"haru", &"oak"]
	var pokemon: Array[StringName] = [
		&"bulbasaur", &"charmander", &"squirtle", &"rattata", &"pidgey",
	]
	var reacting: Array[StringName] = [&"bulbasaur", &"charmander", &"squirtle", &"rattata"]
	var sizes: Dictionary[StringName, Vector2] = {&"leo": Vector2(32, 48)}
	for id: StringName in people:
		sizes[id] = Vector2(32, 64)
	for id: StringName in pokemon:
		sizes[id] = Vector2(32, 32)
	for id: StringName in sizes:
		var frames := load(Npc.frames_path(id)) as SpriteFrames
		assert_not_null(frames, String(id))
		if frames == null:
			continue
		for dir: String in ["down", "up", "left", "right"]:
			var idle := StringName("idle_" + dir)
			assert_true(frames.has_animation(idle), "%s : %s" % [id, idle])
			assert_eq(frames.get_frame_count(idle), 2, "%s : %s en 2 images" % [id, idle])
			assert_true(frames.get_animation_loop(idle))
			assert_eq(frames.get_frame_texture(idle, 0).get_size(), sizes[id], String(id))
			var react := StringName("react_" + dir)
			assert_eq(frames.has_animation(react), reacting.has(id), "%s : %s" % [id, react])
			if frames.has_animation(react):
				assert_false(frames.get_animation_loop(react), "%s : réaction non bouclée" % id)


## Jalon 3B (T3) : Chen, créé par l'étape « spawn » de route1_grass, a ses propres
## SpriteFrames avec marche et course (4 images, bouclées, course plus rapide).
func test_oak_has_its_own_frames_with_walk_and_run() -> void:
	assert_true(Npc.has_frames(&"oak"), "oak_frames.tres")
	var frames := load(Npc.frames_path(&"oak")) as SpriteFrames
	assert_not_null(frames)
	if frames == null:
		return
	for dir: String in ["down", "up", "left", "right"]:
		for kind: String in ["walk_", "run_"]:
			var anim := StringName(kind + dir)
			assert_true(frames.has_animation(anim), "oak : %s" % anim)
			assert_eq(frames.get_frame_count(anim), 4, "oak : %s en 4 images" % anim)
			assert_true(frames.get_animation_loop(anim), "oak : %s bouclée" % anim)
			assert_eq(frames.get_frame_texture(anim, 0).get_size(), Vector2(32, 64))
		assert_gt(frames.get_animation_speed(StringName("run_" + dir)),
			frames.get_animation_speed(StringName("walk_" + dir)), "course plus rapide")
	var cutscenes := CutsceneLibrary.new()
	cutscenes.load_dir()
	var spawned: Array[StringName] = []
	for id: StringName in cutscenes.get_ids():
		for variant: CutsceneVariant in cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.SPAWN:
					spawned.append(step.spec.sprite)
	assert_true(spawned.has(&"oak"), "Chen apparaît par une étape « spawn »")
	for sprite: StringName in spawned:
		assert_true(Npc.has_frames(sprite), "%s_frames.tres (PNJ d'une scène)" % sprite)


func test_npc_cells_in_map_not_on_warp_or_spawn_and_walkable() -> void:
	for state: Array in _states:
		for map_id: StringName in PLAN:
			var map: GameMap = state[1][map_id]
			var grid := map.get_grid()
			var warps := _warp_cells(map)
			var spawns := _spawn_cells(map)
			for npc: Npc in map.get_npcs():
				var cell := npc.get_cell()
				var label := "%s, %s/%s en %s" % [state[0], map_id, npc.get_id(), cell]
				assert_true(grid.is_in_bounds(cell), label + " dans la carte")
				assert_false(warps.has(cell), label + " hors warp")
				assert_false(spawns.has(cell), label + " hors spawn")
				assert_false(grid.is_water(cell), label + " hors de l'eau")
				if npc.get_spec().lift > 0:
					assert_true(grid.is_solid(cell), label + " posé sur un meuble")
				else:
					assert_false(grid.is_solid(cell), label + " praticable")


func test_npcs_close_no_pocket() -> void:
	for state: Array in _states:
		for map_id: StringName in PLAN:
			var map: GameMap = state[1][map_id]
			var grid := map.get_grid()
			var without := _reachable(map, false)
			var with := _reachable(map, true)
			for cell: Vector2i in without:
				if grid.is_occupied(cell) and grid.get_occupant(cell) is Npc:
					continue
				assert_true(with.has(cell), "%s, %s : poche en %s à cause d'un PNJ" % [state[0],
					map_id, cell])


func test_interior_walkable_free_cells_all_reachable() -> void:
	for state: Array in _states:
		for map_id: StringName in [&"player_house_1f", &"rival_house", &"oak_lab"]:
			var map: GameMap = state[1][map_id]
			var grid := map.get_grid()
			var with := _reachable(map, true)
			for y: int in map.size.y:
				for x: int in map.size.x:
					var cell := Vector2i(x, y)
					if grid.is_solid(cell) or grid.is_water(cell) or grid.is_occupied(cell):
						continue
					assert_true(with.has(cell), "%s, %s : poche en %s" % [state[0], map_id, cell])


## Nouvelle partie seulement : avec oak_met, Chen occupe (8, 4) (test suivant).
func test_chen_cells_stay_free_and_reachable_in_the_lab() -> void:
	var map: GameMap = _maps[&"oak_lab"]
	var with := _reachable(map, true)
	for cell: Vector2i in [Vector2i(8, 4), Vector2i(11, 6)]:
		assert_false(map.get_grid().is_occupied(cell), "(%s) libre" % cell)
		assert_false(map.get_grid().is_solid(cell))
		assert_true(with.has(cell), "(%s) atteignable" % cell)


## Jalon 3B §3.6 : avec oak_met, Chen en (8, 4) et le rival en (9, 6) ; (11, 6) reste libre
## et atteignable (Salamèche s'observe) ; les deux pas vers le haut depuis l'entrée sont
## libres ; la chambre du rival est vide.
func test_after_oak_met_chen_and_the_rival_are_in_the_lab() -> void:
	var lab: GameMap = _maps_met[&"oak_lab"]
	var grid := lab.get_grid()
	assert_same(grid.get_occupant(Vector2i(8, 4)), lab.get_npc(&"oak"))
	assert_same(grid.get_occupant(Vector2i(9, 6)), lab.get_npc(&"rival"))
	assert_eq(lab.get_npc(&"oak").get_interaction().dialogue_id, &"oak_lab_waiting",
		"Chen : réplique d'attente jusqu'au jalon 4")
	assert_eq(lab.get_npc(&"rival").get_interaction().dialogue_id, &"rival_lab_waiting",
		"rival : réplique d'attente jusqu'au jalon 4")
	var with := _reachable(lab, true)
	assert_false(grid.is_occupied(Vector2i(11, 6)))
	assert_true(with.has(Vector2i(11, 6)), "(11, 6) atteignable")
	var entrance := lab.get_spawn_cell(&"entrance")
	assert_eq(entrance, Vector2i(7, 9))
	var up: Array[Vector2i] = [Vector2i.UP, Vector2i.UP]
	for cell: Vector2i in CutsceneMoves.path_cells(entrance, up):
		assert_true(grid.is_free(cell), "pas de la scène libre en %s" % cell)
		assert_false(_warp_cells(lab).has(cell), "pas un warp : %s" % cell)
	var rival_home: GameMap = _maps_met[&"rival_house"]
	assert_true(rival_home.get_npcs().is_empty(), "chambre du rival vide")
	assert_false(rival_home.get_grid().is_occupied(Vector2i(13, 4)))
	assert_null(_maps[&"oak_lab"].get_npc(&"oak"), "nouvelle partie : pas de Chen au labo")
	assert_null(_maps[&"oak_lab"].get_npc(&"rival"))
	assert_not_null(_maps[&"rival_house"].get_npc(&"rival"), "nouvelle partie : rival chez lui")


## Deux entrées d'une même case ne sont jamais présentes ensemble, pour chaque état.
func test_no_two_present_entries_share_a_cell() -> void:
	var met := StoryFlags.new()
	met.set_flag(&"oak_met")
	for flags: StoryFlags in [null, met]:
		for map_id: StringName in PLAN:
			var seen: Dictionary[Vector2i, StringName] = {}
			for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_present(flags):
				assert_false(seen.has(spec.cell), "%s : %s et %s en %s" % [map_id,
					seen.get(spec.cell, &""), spec.id, spec.cell])
				seen[spec.cell] = spec.id


func test_interact_points_match_the_plan() -> void:
	for map_id: StringName in FROM:
		var map: GameMap = _maps[map_id]
		var points: Dictionary = POINTS.get(map_id, {})
		assert_eq(map.get_node(^"Interactables").get_child_count(), points.size(),
			"%s : points d'examen" % map_id)
		for node_name: StringName in points:
			var point := map.get_node_or_null(NodePath("Interactables/" + String(node_name))) \
					as InteractPoint
			assert_not_null(point, "%s/%s" % [map_id, node_name])
			if point == null:
				continue
			var row: Array = points[node_name]
			assert_eq(point.get_cell(), row[0], "%s/%s ancre" % [map_id, node_name])
			assert_eq(point.size, row[1], "%s/%s taille" % [map_id, node_name])
			assert_eq(point.dialogue_id, row[2])
			assert_eq(point.kind, EXAMINE)
			assert_eq(point.facing, Vector2i.ZERO, "examinable de tous côtés")
		var expected_cells := 0
		for row: Array in points.values():
			expected_cells += (row[1] as Vector2i).x * (row[1] as Vector2i).y
		assert_eq(map.get_interactions().size(), expected_cells,
			"%s : table sans conflit" % map_id)


## Vrai si, depuis une case voisine atteignable, le vrai InteractionFinder rend
## [param dialogue] avec le verbe [param kind] pour une des cases [param cells].
func _usable(map: GameMap, cells: Array[Vector2i], dialogue: StringName, kind: int,
		reachable: Dictionary[Vector2i, bool]) -> bool:
	for cell: Vector2i in cells:
		for direction: Vector2i in DIRECTIONS:
			var from := cell - direction
			if not reachable.has(from):
				continue
			var found := InteractionFinder.find(map.get_grid(), map.get_interactions(), from,
				direction)
			if found != null and found.dialogue_id == dialogue and found.kind == kind:
				return true
	return false


func test_every_target_is_usable_from_a_reachable_cell() -> void:
	for state: Array in _states:
		for map_id: StringName in FROM:
			var map: GameMap = state[1][map_id]
			var reachable := _reachable(map, true)
			for npc: Npc in map.get_npcs():
				var interaction := npc.get_interaction()
				if interaction == null:
					continue
				var cells: Array[Vector2i] = [npc.get_cell()]
				assert_true(_usable(map, cells, interaction.dialogue_id, interaction.kind,
					reachable), "%s, %s/%s utilisable" % [state[0], map_id, npc.get_id()])
			for point: Node in map.get_node(^"Interactables").get_children():
				var ip := point as InteractPoint
				assert_true(_usable(map, ip.get_cells(), ip.dialogue_id, ip.kind, reachable),
					"%s/%s utilisable" % [map_id, ip.name])


func test_haru_is_talked_to_from_the_beach() -> void:
	# Haru est sur la plage (retouche de Kevin, jalon 3A §6) : on lui parle depuis l'est.
	var map: GameMap = _maps[&"pallet_town"]
	var found := InteractionFinder.find(map.get_grid(), map.get_interactions(),
		Vector2i(4, 29), Vector2i.LEFT)
	assert_not_null(found)
	if found != null:
		assert_eq(found.dialogue_id, &"haru")
	assert_true(_reachable(map, true).has(Vector2i(4, 29)))


func test_pidgeys_and_rattata_block_and_are_observable_except_the_meadow_ones() -> void:
	var map: GameMap = _maps[&"pallet_town"]
	# Jalon 6 §6.9 : les Pokémon de Mme Aoki et de Léo s'OBSERVENT (Pokédex, Q-7) ;
	# ceux des prés restent du décor au 6C.
	var observable: Dictionary[StringName, StringName] = {
		&"aoki_pidgey_1": &"pidgey", &"aoki_pidgey_2": &"pidgey", &"leo_rattata": &"rattata"}
	for id: StringName in observable:
		var observed := map.get_npc(id)
		assert_not_null(observed.get_interaction(), "%s interactif" % id)
		assert_eq(observed.get_interaction().kind, Interaction.Kind.OBSERVE, id)
		assert_eq(observed.get_spec().species, observable[id], id)
		assert_true(map.get_grid().is_occupied(observed.get_cell()), "%s bloque sa case" % id)
	for id: StringName in [&"prairie_pidgey", &"prairie_rattata"]:
		var npc := map.get_npc(id)
		assert_null(npc.get_interaction(), "%s non interactif" % id)
		assert_true(map.get_grid().is_occupied(npc.get_cell()), "%s bloque sa case" % id)
	# (28, 13) reste libre : les graines de Mme Aoki.
	assert_false(map.get_grid().is_occupied(Vector2i(28, 13)))
	assert_false(map.get_grid().is_solid(Vector2i(28, 13)))


func test_decor_props_on_furniture() -> void:
	var first: GameMap = _maps[&"player_house_1f"]
	var breakfast := first.get_entities().get_node_or_null(^"Breakfast") as WorldProp
	assert_not_null(breakfast, "petit-déjeuner sur la table")
	if breakfast != null:
		assert_eq(breakfast.get_anchor_cell(), Vector2i(3, 5))
		assert_true(breakfast.get_footprint().is_empty())
		assert_gt(breakfast.get_index(), first.get_entities().get_node(^"DiningTable").get_index(),
			"dessiné après la table")
	var rival: GameMap = _maps[&"rival_house"]
	var items := rival.get_entities().get_node_or_null(^"BedItems") as WorldProp
	assert_not_null(items, "carte, sac et affaires sur le lit")
	if items != null:
		assert_eq(items.get_anchor_cell(), Vector2i(15, 4))
		assert_true(items.get_footprint().is_empty())
		assert_gt(items.get_index(), rival.get_entities().get_node(^"Bed").get_index())
