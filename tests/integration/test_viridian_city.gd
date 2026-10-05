extends GutTest
## Carte de Jadielle (jalon 7 T4, docs/tech/jalon-07.md §8 ; dossier 09 §1 à §3, §11, §19) :
## métadonnées et sol peint, passages dans les deux sens (Route 1, Centre, Boutique, Route 22,
## sortie nord « à venir »), habitants sur des cases libres et routines possibles, chemin entre
## les trois entrées, porte de l'Arène qui répond, micro-scène d'arrivée sur le seul passage
## vers le nord, présence des habitants selon l'arrivée.

const MAP_PATH := "res://game/world/maps/viridian_city.tscn"
const SIZE := Vector2i(56, 36)
const SOUTH := [Vector2i(27, 35), Vector2i(28, 35), Vector2i(29, 35)]
const NORTH := [Vector2i(27, 1), Vector2i(28, 1), Vector2i(29, 1)]
const WEST := [Vector2i(0, 22), Vector2i(0, 23)]
const CENTER_DOORS := [Vector2i(21, 21), Vector2i(22, 21)]
const MART_DOORS := [Vector2i(35, 21), Vector2i(36, 21)]
const GYM_DOOR := [Vector2i(9, 9), Vector2i(10, 9)]
const ARRIVAL_CELLS := [Vector2i(27, 23), Vector2i(28, 23), Vector2i(29, 23)]

var _map: GameMap
var _grid: GridWorld
## Grille du relief seul (sans les PNJ) : solides de la carte.
var _terrain: GridWorld
var _roster: NpcRoster


func before_all() -> void:
	_map = (load(MAP_PATH) as PackedScene).instantiate() as GameMap
	add_child(_map)
	_grid = _map.get_grid()
	_terrain = GridWorld.new(SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _grid.is_solid(Vector2i(x, y)):
				_terrain.set_solid(Vector2i(x, y))
	_roster = NpcRoster.load_for_map(&"viridian_city")


func after_all() -> void:
	_map.free()


func _load_map(map_id: StringName) -> GameMap:
	return (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate() as GameMap


func test_metadata_and_painted_ground() -> void:
	assert_eq(_map.map_id, &"viridian_city")
	assert_eq(_map.display_name, "Jadielle")
	assert_eq(_map.region, "", "aucun sous-titre (décision du 2026-10-03)")
	assert_eq(_map.size, SIZE)
	assert_eq(_map.light_profile, &"golden_hour")
	assert_false(_map.interior)
	var ground := _map.get_node_or_null(^"PaintedGround") as PaintedGround
	assert_not_null(ground, "sol peint")
	if ground != null:
		assert_eq(ground.size, SIZE)
		assert_not_null(ground.mask, "masque du sol")
		if ground.mask != null:
			assert_eq(Vector2i(ground.mask.get_size()), SIZE, "1 pixel = 1 case")
	assert_not_null(_map.get_node_or_null(^"GroundDecals"))
	assert_true(_map.get_entities().y_sort_enabled)
	for child: Node in _map.get_children():
		assert_false(child is TileMapLayer, "aucune couche de tuiles visible (%s)" % child.name)
	var library := LightingLibrary.new()
	library.load_file()
	assert_true(library.has_profile(_map.light_profile), "profil de lumière connu")


func test_landmarks_are_painted_props() -> void:
	for spec: Array in [["PokemonCenter", Vector2i(22, 21)], ["PokeMart", Vector2i(36, 21)],
			["Gym", Vector2i(10, 9)], ["CentralTree", Vector2i(29, 20)],
			["NorthGate", Vector2i(28, 2)]]:
		var prop := _map.get_entities().get_node_or_null(NodePath(spec[0])) as WorldProp
		assert_not_null(prop, spec[0])
		if prop != null:
			assert_eq(prop.get_anchor_cell(), spec[1], spec[0])
	for cell: Vector2i in CENTER_DOORS + MART_DOORS:
		assert_false(_grid.is_solid(cell), "porte franchissable %s" % cell)
	for cell: Vector2i in GYM_DOOR:
		assert_true(_grid.is_solid(cell), "Arène fermée : porte solide %s" % cell)


func test_south_entrance_links_both_ways_with_route_1() -> void:
	var route := _load_map(&"route_1")
	add_child(route)
	var expected := {Vector2i(27, 35): &"from_viridian_w", Vector2i(28, 35): &"from_viridian_w",
		Vector2i(29, 35): &"from_viridian_e"}
	for cell: Vector2i in SOUTH:
		var warp := _map.get_warps().find_on_push(cell, Vector2i.DOWN)
		assert_not_null(warp, "sortie sud %s" % cell)
		if warp == null:
			continue
		assert_eq(warp.target_map, &"route_1")
		assert_eq(warp.target_spawn, expected[cell])
		assert_true(route.has_spawn(warp.target_spawn))
		var back := route.get_warps().find_on_push(route.get_spawn_cell(warp.target_spawn),
			Vector2i.UP)
		assert_not_null(back, "la Route 1 ramène à Jadielle depuis %s" % warp.target_spawn)
		if back != null:
			assert_eq(back.target_map, &"viridian_city")
			assert_true(_map.has_spawn(back.target_spawn))
			assert_true(SOUTH.has(_map.get_spawn_cell(back.target_spawn)), "arrivée au sud")
	route.free()


func test_doors_lead_to_the_interiors_and_back() -> void:
	for spec: Array in [[CENTER_DOORS, &"viridian_center", &"from_center"],
			[MART_DOORS, &"viridian_mart", &"from_mart"]]:
		var inside := _load_map(spec[1])
		add_child(inside)
		for cell: Vector2i in spec[0]:
			var door := _map.get_warps().find_on_step(cell, Vector2i.UP)
			assert_not_null(door, "%s : porte %s" % [spec[1], cell])
			if door != null:
				assert_eq(door.target_map, spec[1])
				assert_true(inside.has_spawn(door.target_spawn))
		var mat := inside.get_spawn_cell(&"entrance")
		var exit := inside.get_warps().find_on_push(mat, Vector2i.DOWN)
		assert_not_null(exit, "%s : sortie sur le paillasson" % spec[1])
		if exit != null:
			assert_eq(exit.target_map, &"viridian_city")
			assert_eq(exit.target_spawn, spec[2])
			assert_true((spec[0] as Array).has(_map.get_spawn_cell(spec[2])),
				"retour sur la porte")
		assert_true(inside.interior)
		assert_eq(inside.light_profile, &"interior_warm")
		inside.free()


## Contrat avec la Route 22 (T22, en parallèle) : la sortie ouest mène à `route_22` /
## `from_viridian` ; Jadielle offre `from_route_22` sur son bord ouest.
func test_west_exit_is_the_route_22_contract() -> void:
	for cell: Vector2i in WEST:
		var warp := _map.get_warps().find_on_push(cell, Vector2i.LEFT)
		assert_not_null(warp, "sortie ouest %s" % cell)
		if warp != null:
			assert_eq(warp.target_map, &"route_22")
			assert_eq(warp.target_spawn, &"from_viridian")
	var arrival := _map.get_spawn_cell(&"from_route_22")
	assert_eq(arrival.x, 0, "sur le bord ouest")
	assert_true(WEST.has(arrival))
	if not MapCatalog.has_map(&"route_22"):
		pending("route_22 pas encore construite (T22) : retour vérifié plus tard")
		return
	var route := _load_map(&"route_22")
	assert_true(route.has_spawn(&"from_viridian"), "spawn de la Route 22")
	var back_ok := false
	for warp: Warp in route.get_warps().get_all():
		if warp.target_map == &"viridian_city":
			assert_eq(warp.target_spawn, &"from_route_22")
			back_ok = true
	assert_true(back_ok, "la Route 22 ramène à Jadielle")
	route.free()


func test_north_exit_is_route_2_coming_soon() -> void:
	for cell: Vector2i in NORTH:
		var warp := _map.get_warps().find_on_push(cell, Vector2i.UP)
		assert_not_null(warp, "sortie nord %s" % cell)
		if warp == null:
			continue
		assert_true(warp.is_coming_soon())
		assert_eq(warp.coming_soon, "Route 2")
		assert_eq(warp.facing, Vector2i.DOWN)
		var back := _map.get_spawn_cell(warp.target_spawn)
		assert_false(_grid.is_solid(back), "retour praticable")
		assert_true(_grid.is_solid(cell + Vector2i.UP), "bord nord bloqué")


func test_a_path_links_the_three_entrances_and_the_doors() -> void:
	var reach := _terrain.find_reachable(SOUTH[1])
	for cell: Vector2i in SOUTH + NORTH + WEST + CENTER_DOORS + MART_DOORS:
		assert_true(reach.has(cell), "atteignable depuis l'entrée sud : %s" % cell)
	for cell: Vector2i in GYM_DOOR:
		assert_true(reach.has(cell + Vector2i.DOWN), "devant la porte de l'Arène %s" % cell)
	# Avec les habitants à leur place de départ, rien n'est bloqué non plus.
	var crowded := _grid.find_reachable(SOUTH[1])
	for cell: Vector2i in NORTH + WEST + CENTER_DOORS + MART_DOORS:
		assert_true(crowded.has(cell), "habitants : passage libre vers %s" % cell)


func test_the_gym_door_answers_and_is_locked() -> void:
	var interactions := _map.get_interactions()
	for cell: Vector2i in GYM_DOOR:
		var found := InteractionFinder.find(_grid, interactions, cell + Vector2i.DOWN,
			Vector2i.UP)
		assert_not_null(found, "porte examinée depuis %s" % (cell + Vector2i.DOWN))
		if found != null:
			assert_eq(found.kind, Interaction.Kind.EXAMINE)
			assert_eq(found.dialogue_id, &"viridian_gym_door")
	var library := DialogueLibrary.new()
	library.load_dir()
	var pages := library.get_dialogue(&"viridian_gym_door").variants[0].pages
	assert_eq(pages.size(), 1)
	assert_eq(pages[0].text, "La porte est verrouillée.")


## Micro-scène d'arrivée (Jadielle agrandie) : le premier pas sur la place, en haut du grand
## escalier sud, seul passage vers le nord ; la Boutique (et son Roucool) dans le champ.
func test_arrival_trigger_is_the_only_way_north() -> void:
	var cells: Array[Vector2i] = []
	for trigger: EventTrigger in _map.get_triggers().get_all():
		if trigger.cutscene_id == &"viridian_arrival":
			cells.append(trigger.cell)
	assert_eq(cells.size(), ARRIVAL_CELLS.size(), "trois cases, la largeur de l'escalier")
	for cell: Vector2i in ARRIVAL_CELLS:
		assert_true(cells.has(cell), "déclencheur en %s" % cell)
		assert_false(_terrain.is_solid(cell + Vector2i.DOWN), "en haut des marches %s" % cell)
		# ≈ 11 cases de haut à l'écran, caméra aux pieds : 5 rangées visibles au-dessus.
		assert_lte(cell.y - MART_DOORS[0].y, 2, "la façade de la Boutique est dans le champ")
	var blocked := GridWorld.new(SIZE)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			if _terrain.is_solid(Vector2i(x, y)) or ARRIVAL_CELLS.has(Vector2i(x, y)):
				blocked.set_solid(Vector2i(x, y))
	var reach := blocked.find_reachable(SOUTH[1])
	assert_false(reach.has(MART_DOORS[0]), "impossible de contourner le déclencheur")
	assert_false(reach.has(WEST[0]), "ni par l'ouest")


## Trois niveaux (référence `jadielle-vue-generale-v1`) : les murs de soutènement ne se
## franchissent que par les escaliers ; la falaise du sud seulement par le chemin.
func test_terraces_are_crossed_only_by_the_stairs() -> void:
	for row: int in [12, 24]:
		var open: Array[int] = []
		for x: int in SIZE.x:
			if not _terrain.is_solid(Vector2i(x, row)):
				open.append(x)
		var expected: Array = [9, 10, 11, 27, 28, 29] if row == 12 else [27, 28, 29]
		assert_eq(Array(open), expected, "mur de la rangée %d : seulement les escaliers" % row)
	var cliff: Array[int] = []
	for x: int in SIZE.x:
		if not _terrain.is_solid(Vector2i(x, 32)):
			cliff.append(x)
	assert_eq(Array(cliff), [27, 28, 29], "falaise : le chemin de la Route 1")
	var decals := _map.get_node(^"GroundDecals")
	for stair: String in ["StairGym", "StairNorth", "StairSouth"]:
		assert_not_null(decals.get_node_or_null(NodePath(stair)), stair)
	# La place est au centre : l'arbre est entre le Centre (ouest) et la Boutique (est).
	var tree := _map.get_entities().get_node(^"CentralTree") as Node2D
	var center := _map.get_entities().get_node(^"PokemonCenter") as Node2D
	var mart := _map.get_entities().get_node(^"PokeMart") as Node2D
	assert_between(tree.position.x, center.position.x, mart.position.x)
	assert_between(tree.position.y / Grid.TILE_SIZE, SIZE.y * 0.4, SIZE.y * 0.6, "au centre")


## Passe 2 (Kevin) : chaque maison a son jardin clos, ouvert par un portail atteignable ; au
## moins quatre modèles de maisons, aucun plus de deux fois.
func test_every_house_has_a_closed_garden_with_a_gate() -> void:
	var gates: Array[Vector2i] = [Vector2i(19, 9), Vector2i(37, 9), Vector2i(7, 21),
		Vector2i(47, 21), Vector2i(20, 30), Vector2i(38, 30)]
	var reach := _terrain.find_reachable(SOUTH[1])
	for gate: Vector2i in gates:
		assert_true(reach.has(gate), "portail atteignable %s" % gate)
		assert_true(_terrain.is_solid(gate + Vector2i.LEFT), "clôture à gauche de %s" % gate)
		assert_true(_terrain.is_solid(gate + Vector2i.RIGHT), "clôture à droite de %s" % gate)
	var models: Dictionary = {}
	for child: Node in _map.get_entities().get_children():
		var path := child.scene_file_path
		if path.contains("bldg_maison_"):
			models[path] = int(models.get(path, 0)) + 1
	assert_gte(models.size(), 4, "au moins quatre modèles de maisons")
	for path: String in models:
		assert_lte(int(models[path]), 2, "%s au plus deux fois" % path.get_file())


## Retours de Kevin au T5 (jalon-07.md §15.21) : « on ne peut pas accéder aux portes des
## maisons ». Chaque porte de maison (six) est atteignable **à pied depuis l'entrée sud** sur la
## vraie grille de collisions (relief et habitants), par une allée droite qui part du portail
## (clôture de part et d'autre) ; rien n'est posé sur l'allée ni devant la porte ; examinée de
## face, la porte répond « C'est fermé. ».
func test_every_house_door_is_reachable_from_the_south_entrance_and_closed() -> void:
	var interactions := _map.get_interactions()
	var doors: Array[Vector2i] = []
	for point: Node in _map.get_node(^"Interactables").get_children():
		if point.get(&"dialogue_id") == &"viridian_house_door":
			doors.append(Grid.world_to_cell((point as Node2D).position))
	assert_eq(doors.size(), 6, "une porte par maison")
	var reach := _terrain.find_reachable(SOUTH[1])
	var crowded := _grid.find_reachable(SOUTH[1])
	var props := _prop_cells()
	for door: Vector2i in doors:
		var front := door + Vector2i.DOWN
		assert_true(_terrain.is_solid(door), "la porte %s est dans la maison" % door)
		assert_true(reach.has(front), "devant la porte %s : atteignable" % door)
		assert_true(crowded.has(front), "devant la porte %s : habitants à leur place" % door)
		# Allée droite jusqu'au portail : la première case flanquée de clôtures.
		var cell := front
		while not (_terrain.is_solid(cell + Vector2i.LEFT)
				and _terrain.is_solid(cell + Vector2i.RIGHT)):
			assert_false(_terrain.is_solid(cell), "allée libre en %s" % cell)
			assert_false(props.has(cell), "rien posé sur l'allée en %s" % cell)
			cell += Vector2i.DOWN
			if cell.y >= SIZE.y:
				break
		assert_lte(cell.y - front.y, 3, "portail à trois cases au plus de la porte %s" % door)
		assert_false(props.has(cell), "portail ouvert en %s" % cell)
		assert_true(reach.has(cell + Vector2i.DOWN), "chemin public devant le portail %s" % cell)
		var found := InteractionFinder.find(_grid, interactions, front, Vector2i.UP)
		assert_not_null(found, "porte %s examinée de face" % door)
		if found != null:
			assert_eq(found.kind, Interaction.Kind.EXAMINE)
			assert_eq(found.dialogue_id, &"viridian_house_door")
		assert_null(InteractionFinder.find(_grid, interactions, front + Vector2i.LEFT,
			Vector2i.UP), "pas de côté : seulement de face (%s)" % door)
	var library := DialogueLibrary.new()
	library.load_dir()
	var dialogue := library.get_dialogue(&"viridian_house_door")
	assert_true(dialogue.draft, "texte provisoire (draft)")
	assert_eq(dialogue.variants[0].pages[0].text, "C'est fermé.")


## Cases occupées par l'emprise ou le pied d'un objet posé (sauf portails, clôtures et maisons
## elles-mêmes, et les reliefs de la couche du sol).
func _prop_cells() -> Dictionary:
	var cells := {}
	for child: Node in _map.get_entities().get_children():
		var prop := child as WorldProp
		if prop == null or child.scene_file_path.contains("bldg_maison_") \
				or child.scene_file_path.contains("prop_portail_"):
			continue
		for cell: Vector2i in prop.get_solid_cells():
			cells[cell] = true
		if not child.scene_file_path.is_empty():
			cells[prop.get_anchor_cell()] = true
	return cells


## Retours T5 (§15.21) : le Rattata de l'enfant suit son maître **au même rythme** (même boucle,
## même pause, une case derrière) : il ne trottine pas puis s'arrête net contre lui.
func test_the_kid_rattata_follows_at_the_kid_pace() -> void:
	var kid := _roster.get_spec(&"kid")
	var rattata := _roster.get_spec(&"kid_rattata")
	assert_eq(rattata.route_cells, kid.route_cells, "même boucle")
	assert_eq(rattata.route_pause, kid.route_pause, "même pause")
	assert_eq(kid.route_start, (rattata.route_start + 1) % kid.route_cells.size(),
		"une case devant son Rattata")


## Aucun habitant figé (Kevin, T5) : chacun marche, ou regarde autour de lui.
func test_no_inhabitant_stands_frozen() -> void:
	for spec: NpcSpec in _roster.get_all():
		assert_true(spec.has_route() or spec.has_look(), "%s vit (route ou look)" % spec.id)


func test_npcs_stand_on_free_cells_and_routines_are_possible() -> void:
	var warp_cells: Dictionary = {}
	for warp: Warp in _map.get_warps().get_all():
		warp_cells[warp.cell] = true
	var trigger_cells: Dictionary = {}
	for trigger: EventTrigger in _map.get_triggers().get_all():
		trigger_cells[trigger.cell] = true
	assert_eq(_roster.get_errors().size(), 0, str(_roster.get_errors()))
	assert_gt(_roster.get_all().size(), 8)
	for spec: NpcSpec in _roster.get_all():
		assert_true(_grid.is_in_bounds(spec.cell), String(spec.id))
		if spec.lift > 0:
			# Le Roucool sur l'auvent de la Boutique : sur l'emprise du bâtiment, dessiné haut.
			assert_true(_terrain.is_solid(spec.cell), "%s posé sur un toit" % spec.id)
		else:
			assert_false(_terrain.is_solid(spec.cell), "%s sur une case libre" % spec.id)
		assert_false(warp_cells.has(spec.cell), "%s pas sur un passage" % spec.id)
		assert_false(trigger_cells.has(spec.cell), "%s pas sur le déclencheur" % spec.id)
		for cell: Vector2i in spec.route_cells:
			assert_false(_terrain.is_solid(cell), "%s : routine praticable %s" % [spec.id, cell])
			assert_false(trigger_cells.has(cell), "%s : routine hors déclencheur" % spec.id)
			if warp_cells.has(cell):
				assert_eq(cell, spec.route_enter_cell, "%s : seule la porte est un passage"
					% spec.id)
	var courier: NpcSpec = null
	for spec: NpcSpec in _roster.get_all():
		if spec.id == &"courier":
			courier = spec
	assert_not_null(courier)
	if courier != null:
		assert_true(courier.enters_building(), "le livreur entre à la Boutique")
		assert_true(MART_DOORS.has(courier.route_enter_cell))
		assert_eq(courier.route_enter_seconds, 8.0)


func test_presence_before_and_after_the_arrival() -> void:
	var before := StoryFlags.new()
	before.set_flag(&"rival_battle_done")
	var after := StoryFlags.new()
	after.set_flag(&"rival_battle_done")
	after.set_flag(&"viridian_arrived")
	var ids_before := _ids(_roster.get_present(before))
	var ids_after := _ids(_roster.get_present(after))
	for id: StringName in [&"arrival_kid", &"arrival_rattata", &"arrival_traveler"]:
		assert_true(ids_before.has(id), "%s à la première arrivée" % id)
		assert_false(ids_after.has(id), "%s seulement pour la scène" % id)
	for id: StringName in [&"kid", &"kid_rattata", &"traveler"]:
		assert_false(ids_before.has(id), id)
		assert_true(ids_after.has(id), "%s ensuite" % id)
	for id: StringName in [&"courier", &"lass", &"lass_pidgey", &"old_man", &"gym_watcher",
			&"viridian_roof_pidgey"]:
		assert_true(ids_before.has(id) and ids_after.has(id), "%s toujours là" % id)
	# Aucune case partagée entre deux PNJ présents ensemble.
	for present: Array[StringName] in [ids_before, ids_after]:
		var cells: Dictionary = {}
		for spec: NpcSpec in _roster.get_all():
			if present.has(spec.id):
				assert_false(cells.has(spec.cell), "%s : case %s partagée" % [spec.id, spec.cell])
				cells[spec.cell] = true


func test_painted_looks_of_the_inhabitants() -> void:
	var expected := {&"courier": &"courier", &"lass": &"lass", &"old_man": &"old_man",
		&"kid": &"kid", &"arrival_kid": &"kid", &"traveler": &"traveler",
		&"arrival_traveler": &"traveler", &"lass_pidgey": &"pokemon/pidgey",
		&"viridian_roof_pidgey": &"pokemon/pidgey", &"kid_rattata": &"pokemon/rattata",
		&"arrival_rattata": &"pokemon/rattata"}
	for spec: NpcSpec in _roster.get_all():
		if expected.has(spec.id):
			assert_eq(spec.sprite, expected[spec.id], String(spec.id))
		var look := CharacterLook.resolve(spec.sprite)
		assert_true(look.painted, "%s : apparence peinte (%s)" % [spec.id, spec.sprite])
	for id: StringName in [&"lass_pidgey"]:
		for spec: NpcSpec in _roster.get_all():
			if spec.id == id:
				assert_eq(spec.idle_react_every, 6.0, "petite animation toutes les 6 s")
				assert_false(spec.is_interactive(), "pas observable au J7 (Q-6)")


static func _ids(specs: Array[NpcSpec]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for spec: NpcSpec in specs:
		ids.append(spec.id)
	return ids
