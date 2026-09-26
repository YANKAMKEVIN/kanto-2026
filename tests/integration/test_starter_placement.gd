extends GutTest
## Invariants de mise en scène du choix dans le labo réel (jalon-04.md §13.4, §13.6), pour
## chacun des 3 choix : grille de oak_lab, PNJ présents pour
## { oak_met, oak_lab_reunion, starter_offered }. On rejoue les résolutions de la scène
## starter_chosen (data/cutscenes/starter.json : offsets lus dans les données) avec
## CutsceneMoves.resolve_near et GridWorld.find_path, en déplaçant les occupants comme le
## directeur :
## - chaque starter est rencontrable depuis (x, 6) (libre, atteignable depuis l'entrée ;
##   InteractionFinder renvoie la surcharge MEET) ;
## - pas du joueur (10, 7) / (11, 7) / (11, 6) ; le starter se pose sur la case quittée, et le
##   joueur le regarde (il est devant lui) ;
## - atterrissage du Pokémon du rival (9, 5) / (10, 6) / (10, 6), voisin du rival, saut d'au
##   plus 2 cases par axe ;
## - chemin du rival vers (8, 7) avec suiveur : existe, sans warp ni déclencheur ;
## - après la scène : joueur pas enfermé (tapis atteignable), toute cible interactive
##   utilisable depuis une case atteignable ; (7, 8) libre et praticable tout du long ;
## - les acteurs finissent au plus en rangée 7 (rien sous la boîte de dialogue) ;
## - aucune case de la scène n'est un warp ni un déclencheur (le tapis n'est jamais emprunté).

const FLAGS: Array[StringName] = [&"oak_met", &"oak_lab_reunion", &"starter_offered"]
const ENTRANCE := Vector2i(7, 9)
const ABOVE_MAT := Vector2i(7, 8)
## Dernière rangée entièrement visible au-dessus de la boîte de dialogue (labo fixe à l'écran).
const MAX_ROW := 7
## Espèce choisie → [case de rencontre, pas du joueur, atterrissage du Pokémon du rival].
const EXPECTED: Dictionary[StringName, Array] = {
	&"bulbasaur": [Vector2i(10, 6), Vector2i(10, 7), Vector2i(9, 5)],
	&"charmander": [Vector2i(11, 6), Vector2i(11, 7), Vector2i(10, 6)],
	&"squirtle": [Vector2i(12, 6), Vector2i(11, 6), Vector2i(10, 6)],
}

var _offer: StarterOffer
var _data: PokemonData
var _steps: Array[CutsceneStep] = []
var _map: GameMap
var _grid: GridWorld
var _player := RefCounted.new()
var _forbidden: Array[Vector2i] = []
## Cases simulées des PNJ déplacés (le nœud garde sa case : seule la grille est rejouée).
var _moved: Dictionary[Npc, Vector2i] = {}


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_offer = StarterOffer.new()
	_offer.load_file()
	var scenes := CutsceneLibrary.new()
	scenes.load_dir()
	_steps = scenes.get_cutscene(_offer.chosen_scene).variants[0].steps


func before_each() -> void:
	_map = (load(MapCatalog.scene_path(_offer.map_id)) as PackedScene).instantiate() as GameMap
	add_child_autofree(_map)
	var flags := StoryFlags.new()
	for flag: StringName in FLAGS:
		flags.set_flag(flag)
	_map.refresh_npcs(flags)
	_grid = _map.get_grid()
	_forbidden.clear()
	_moved.clear()
	for warp: Warp in _map.get_warps().get_all():
		_forbidden.append(warp.cell)
	for trigger: EventTrigger in _map.get_triggers().get_all():
		_forbidden.append(trigger.cell)


## Étapes de la scène, dans l'ordre, de type [param kind] et d'acteur [param actor].
func _step(kind: CutsceneStep.Kind, actor: StringName) -> CutsceneStep:
	for step: CutsceneStep in _steps:
		if step.kind == kind and step.actor == actor:
			return step
	return null


func test_forbidden_cells_are_only_the_mat() -> void:
	assert_eq(_forbidden, [ENTRANCE, ENTRANCE] as Array[Vector2i], "warp PUSH + LabExit")


func test_bulbasaur() -> void:
	_check_choice(&"bulbasaur")


func test_charmander() -> void:
	_check_choice(&"charmander")


func test_squirtle() -> void:
	_check_choice(&"squirtle")


func _check_choice(species: StringName) -> void:
	var option := _offer.get_choice(species)
	var rival_option := _offer.get_choice(_offer.rival_pick(species, _data))
	var mine := _map.get_npc(option.npc)
	var theirs := _map.get_npc(rival_option.npc)
	var rival := _map.get_npc(&"rival")
	assert_not_null(mine)
	assert_not_null(theirs)
	assert_not_null(rival)
	if mine == null or theirs == null or rival == null:
		return
	var expected: Array = EXPECTED[species]
	var scene_cells: Array[Vector2i] = []
	_assert_above_mat_free("début")
	# Rencontre depuis (x, 6).
	var meet: Vector2i = expected[0]
	assert_eq(meet, mine.get_cell() + Vector2i.DOWN)
	assert_true(_grid.is_free(meet), "case de rencontre libre")
	assert_true(_grid.find_reachable(ENTRANCE).has(meet), "atteignable depuis l'entrée")
	mine.set_interaction_override(Interaction.new(Interaction.Kind.MEET, mine.get_cell(), &"",
		Vector2i.ZERO, mine))
	var target := InteractionFinder.find(_grid, _map.get_interactions(), meet, Vector2i.UP)
	assert_not_null(target)
	if target != null:
		assert_eq(target.kind, Interaction.Kind.MEET)
		assert_eq(target.source, mine)
	mine.clear_interaction_override()
	assert_true(_grid.occupy(meet, _player))
	# 1. Le joueur s'écarte (étape move player / near player).
	var step_aside := _step(CutsceneStep.Kind.MOVE, &"player")
	var aside := CutsceneMoves.resolve_near(_grid, meet, step_aside.offsets, _player)
	assert_eq(aside, expected[1], "pas du joueur")
	assert_eq(_grid.find_path(meet, aside, _player).size(), 1, "un seul pas")
	assert_true(_grid.move_occupant(_player, meet, aside))
	scene_cells.append(aside)
	# 2. Le starter descend sur la case quittée.
	var hop := _step(CutsceneStep.Kind.HOP, &"$player_starter")
	var landing := CutsceneMoves.resolve_near(_grid, mine.get_cell(), hop.offsets, mine)
	assert_eq(landing, meet, "le starter se pose sur la case quittée par le joueur")
	assert_true(_grid.move_occupant(mine, mine.get_cell(), landing))
	_moved[mine] = landing
	scene_cells.append(landing)
	# 3. Le joueur le regarde : il est devant lui.
	var facing := Grid.dominant_direction(aside, landing)
	assert_eq(aside + facing, landing, "le Pokémon est devant le joueur")
	_assert_above_mat_free("après le saut du starter")
	# 4. Le Pokémon du rival vient vers lui.
	var rival_hop := _step(CutsceneStep.Kind.HOP, &"$rival_starter")
	var rival_cell := rival.get_cell()
	var rival_landing := CutsceneMoves.resolve_near(_grid, rival_cell, rival_hop.offsets, theirs)
	assert_eq(rival_landing, expected[2], "atterrissage du Pokémon du rival")
	var gap := rival_landing - rival_cell
	assert_eq(absi(gap.x) + absi(gap.y), 1, "voisin du rival")
	var jump := rival_landing - theirs.get_cell()
	assert_lte(absi(jump.x), 2, "saut ≤ 2 cases en x")
	assert_lte(absi(jump.y), 2, "saut ≤ 2 cases en y")
	assert_true(_grid.move_occupant(theirs, theirs.get_cell(), rival_landing))
	scene_cells.append(rival_landing)
	# 5. Le rival part vers la sortie, son Pokémon derrière lui.
	var leave := _step(CutsceneStep.Kind.MOVE, &"rival")
	assert_eq(leave.follower, &"$rival_starter")
	assert_eq(leave.cell, Vector2i(8, 7), "arrêt du rival")
	var path := _grid.find_path(rival_cell, leave.cell, rival)
	assert_false(path.is_empty(), "chemin du rival vers %s" % leave.cell)
	var follow := CutsceneMoves.follow_path(rival_landing, rival_cell, path)
	assert_eq(follow.size(), path.size(), "suiveur voisin du rival")
	var leader_cells := CutsceneMoves.path_cells(rival_cell, path)
	var follower_cells := CutsceneMoves.path_cells(rival_landing, follow)
	for cell: Vector2i in leader_cells + follower_cells:
		assert_true(_grid.is_free(cell, rival) or _grid.get_occupant(cell) == theirs,
			"libre : %s" % cell)
		scene_cells.append(cell)
	assert_true(_grid.move_occupant(rival, rival_cell, leader_cells.back()))
	assert_true(_grid.move_occupant(theirs, rival_landing, follower_cells.back()))
	_moved[rival] = leader_cells.back()
	_moved[theirs] = follower_cells.back()
	# Rien sous la boîte de dialogue (bas de l'écran, rangées 8 et plus) pendant les dernières
	# répliques : le joueur, le rival et les deux Pokémon s'arrêtent au plus en rangée 7.
	for cell: Vector2i in [aside, landing, leader_cells.back(), follower_cells.back()]:
		assert_lte(cell.y, MAX_ROW, "au-dessus de la boîte de dialogue : %s" % cell)
	# Aucune case de la scène n'est un warp ni un déclencheur.
	for cell: Vector2i in scene_cells:
		assert_false(_forbidden.has(cell), "ni warp ni déclencheur : %s" % cell)
	_assert_above_mat_free("fin de la scène")
	# Après : le joueur n'est pas enfermé, chaque cible est utilisable.
	var reachable := _grid.find_reachable(aside, _player)
	assert_true(reachable.has(ENTRANCE), "le tapis de sortie reste atteignable")
	for npc: Npc in _map.get_npcs():
		if npc.get_interaction() == null:
			continue
		var cell: Vector2i = _moved.get(npc, npc.get_cell())
		assert_eq(_grid.get_occupant(cell), npc, "%s en %s" % [npc.get_id(), cell])
		var usable := false
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if reachable.has(cell + direction):
				usable = true
		assert_true(usable, "%s utilisable depuis une case atteignable" % npc.get_id())


func _assert_above_mat_free(moment: String) -> void:
	assert_false(_grid.is_solid(ABOVE_MAT), "(7, 8) praticable (%s)" % moment)
	assert_false(_grid.is_occupied(ABOVE_MAT), "(7, 8) libre (%s)" % moment)
