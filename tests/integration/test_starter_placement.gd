extends GutTest
## Invariants de mise en scène du choix dans le labo réel (jalon-04.md §13.4, §13.6, décision
## de Kevin n° 16), pour chacun des 3 choix : grille de oak_lab, PNJ présents pour
## { oak_met, oak_lab_reunion, starter_offered }. On rejoue les résolutions de la scène
## starter_chosen (data/cutscenes/starter.json : offsets lus dans les données) avec
## CutsceneMoves.resolve_near / resolve_landing et GridWorld.find_path, en déplaçant les
## occupants comme le directeur :
## - chaque starter est rencontrable depuis (x, 6) (libre, atteignable depuis l'entrée ;
##   InteractionFinder renvoie la surcharge MEET) ;
## - le joueur recule d'un pas **sans se retourner** quand la case derrière lui est libre
##   (Bulbizarre, Salamèche), sinon il reste (Carapuce : tabouret) ; il ne tourne jamais le
##   dos à son Pokémon ;
## - le starter atterrit sur une case **libre à côté ou légèrement devant** le joueur,
##   choisie sur la grille : jamais sur sa case ni au-dessus de lui (derrière sa tête) ;
##   ni caché par un meuble qui dépasse (paillasse) ; puis le joueur se tourne vers lui :
##   (11, 6) en diagonale / (10, 7) / (13, 6) ;
## - même règle pour le Pokémon du rival, autour du rival : (9, 7) / (10, 6) / (10, 6) ;
## - **aucun saut ne traverse la case d'un personnage** (décision de Kevin sur le 4A) : ni
##   la case de départ, ni celle d'arrivée, ni les cases survolées
##   (CutsceneMoves.hop_crossed_cells) ne sont celles du joueur, de Chen, de Maya, du rival
##   ou d'un autre Pokémon ;
## - chemin du rival vers (7, 7) avec suiveur : existe, sans warp ni déclencheur, et son
##   Pokémon finit **à côté** de lui (même rangée), pas derrière sa tête ;
## - fin de la séquence : les deux Pokémon rejoignent leur Poké Ball (despawn), pas de faux
##   compagnon ; après la scène : joueur pas enfermé (tapis atteignable), toute cible
##   interactive utilisable depuis une case atteignable ; (7, 8) libre et praticable ;
## - les acteurs finissent au plus en rangée 7 (rien sous la boîte de dialogue) ;
## - aucune case de la scène n'est un warp ni un déclencheur (le tapis n'est jamais emprunté).

const FLAGS: Array[StringName] = [&"oak_met", &"oak_lab_reunion", &"starter_offered"]
const ENTRANCE := Vector2i(7, 9)
const ABOVE_MAT := Vector2i(7, 8)
## Dernière rangée entièrement visible au-dessus de la boîte de dialogue (labo fixe à l'écran).
const MAX_ROW := 7
## Arrêt du rival quand il commence à partir.
const RIVAL_STOP := Vector2i(7, 7)
## Espèce choisie → [case de rencontre, case du joueur après son recul, atterrissage du
## starter, atterrissage du Pokémon du rival, case finale du Pokémon du rival].
const EXPECTED: Dictionary[StringName, Array] = {
	&"bulbasaur": [Vector2i(10, 6), Vector2i(10, 7), Vector2i(11, 6), Vector2i(9, 7),
		Vector2i(8, 7)],
	&"charmander": [Vector2i(11, 6), Vector2i(11, 7), Vector2i(10, 7), Vector2i(10, 6),
		Vector2i(8, 7)],
	&"squirtle": [Vector2i(12, 6), Vector2i(12, 6), Vector2i(13, 6), Vector2i(10, 6),
		Vector2i(8, 7)],
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


## Les cases candidates des deux sauts (données) : voisines de l'ancre (côtés ou diagonale),
## jamais l'ancre elle-même ni une case au-dessus d'elle (derrière la tête du personnage).
func test_landing_offsets_are_beside_or_slightly_in_front() -> void:
	for alias: StringName in [&"$player_starter", &"$rival_starter"]:
		var hop := _step(CutsceneStep.Kind.HOP, alias)
		assert_not_null(hop, "saut de %s" % alias)
		if hop == null:
			continue
		assert_false(hop.near.is_empty(), "%s : case calculée autour d'un personnage" % alias)
		assert_false(hop.offsets.is_empty())
		for offset: Vector2i in hop.offsets:
			assert_ne(offset, Vector2i.ZERO, "%s : pas sur la case du personnage" % alias)
			assert_ne(offset, Vector2i.UP, "%s : jamais derrière sa tête" % alias)
			assert_lte(maxi(absi(offset.x), absi(offset.y)), 1, "%s : voisin" % alias)
	# Le seul déplacement du joueur : un pas en arrière sans se retourner, s'il y a la place.
	var back := _step(CutsceneStep.Kind.MOVE, &"player")
	assert_not_null(back)
	if back != null:
		assert_true(back.keep_facing, "sans se retourner")
		assert_true(back.optional, "sauté s'il n'y a pas la place")
		assert_eq(back.offsets, [Vector2i.DOWN] as Array[Vector2i])


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
	# 0. Le joueur recule d'un pas sans se retourner, si la case derrière lui est libre.
	var back := _step(CutsceneStep.Kind.MOVE, &"player")
	var player_cell := meet
	var behind := CutsceneMoves.resolve_near(_grid, meet, back.offsets, _player)
	if behind != CutsceneStep.NO_CELL:
		assert_true(_grid.move_occupant(_player, meet, behind))
		player_cell = behind
		scene_cells.append(behind)
	assert_eq(player_cell, expected[1], "case du joueur")
	# 1. Le starter descend à côté du joueur (case d'atterrissage de la grille).
	var hop := _step(CutsceneStep.Kind.HOP, &"$player_starter")
	assert_eq(hop.near, NpcRoster.PLAYER_ID, "case calculée autour du joueur")
	var landing := CutsceneMoves.resolve_landing(_grid, mine.get_cell(), player_cell,
		hop.offsets, mine, _tall_cells(player_cell))
	assert_eq(landing, expected[2], "atterrissage du starter")
	_assert_beside(landing, player_cell, "starter / joueur")
	_assert_hop_crosses_nobody(mine, mine.get_cell(), landing, player_cell, "starter")
	assert_true(_grid.move_occupant(mine, mine.get_cell(), landing))
	_moved[mine] = landing
	scene_cells.append(landing)
	# 2. Le joueur se tourne vers lui ; en diagonale, ils se regardent de profil.
	var toward := landing - player_cell
	assert_ne(toward.x, 0, "à côté du joueur (colonne voisine) : ils se voient de profil")
	_assert_above_mat_free("après le saut du starter")
	# 3. Le Pokémon du rival vient à côté de lui, sans survoler personne.
	var rival_hop := _step(CutsceneStep.Kind.HOP, &"$rival_starter")
	assert_eq(rival_hop.near, &"rival")
	var rival_cell := rival.get_cell()
	var rival_landing := CutsceneMoves.resolve_landing(_grid, theirs.get_cell(), rival_cell,
		rival_hop.offsets, theirs, _tall_cells(player_cell))
	assert_eq(rival_landing, expected[3], "atterrissage du Pokémon du rival")
	_assert_beside(rival_landing, rival_cell, "Pokémon du rival / rival")
	var gap := rival_landing - rival_cell
	assert_eq(absi(gap.x) + absi(gap.y), 1, "voisin du rival (il pourra le suivre)")
	assert_ne(rival_landing, player_cell + Vector2i.UP, "pas derrière la tête du joueur")
	_assert_hop_crosses_nobody(theirs, theirs.get_cell(), rival_landing, player_cell,
		"Pokémon du rival")
	assert_true(_grid.move_occupant(theirs, theirs.get_cell(), rival_landing))
	scene_cells.append(rival_landing)
	# 4. Le rival commence à partir, son Pokémon derrière lui ; à l'arrêt, côte à côte.
	var leave := _step(CutsceneStep.Kind.MOVE, &"rival")
	assert_eq(leave.follower, &"$rival_starter")
	assert_eq(leave.cell, RIVAL_STOP, "arrêt du rival")
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
	assert_eq(follower_cells.back(), expected[4], "Pokémon du rival à l'arrêt")
	assert_eq(follower_cells.back().y, leader_cells.back().y, "côte à côte, même rangée")
	_assert_beside(follower_cells.back(), leader_cells.back(), "à l'arrêt")
	# Rien sous la boîte de dialogue (bas de l'écran, rangées 8 et plus) pendant les dernières
	# répliques : le joueur, le rival et les deux Pokémon s'arrêtent au plus en rangée 7.
	for cell: Vector2i in [player_cell, landing, leader_cells.back(), follower_cells.back()]:
		assert_lte(cell.y, MAX_ROW, "au-dessus de la boîte de dialogue : %s" % cell)
	# Aucune case de la scène n'est un warp ni un déclencheur.
	for cell: Vector2i in scene_cells:
		assert_false(_forbidden.has(cell), "ni warp ni déclencheur : %s" % cell)
	_assert_above_mat_free("fin de la scène")
	# 5. Fin de la séquence (4B) : les deux Pokémon rejoignent leur Poké Ball (despawn) et le
	# rival quitte le labo (despawn) ; aucun Pokémon ne reste comme un faux compagnon.
	var gone: Array[Npc] = []
	var rival_gone := false
	for step: CutsceneStep in _steps:
		if step.kind != CutsceneStep.Kind.DESPAWN:
			continue
		if step.actor == &"rival":
			var rcell: Vector2i = _moved.get(rival, rival.get_cell())
			if _grid.get_occupant(rcell) == rival:
				_grid.release(rcell, rival)
			rival_gone = true
			continue
		var npc: Npc = mine if step.actor == &"$player_starter" else theirs
		assert_true(step.actor in [&"$player_starter", &"$rival_starter"], str(step.actor))
		var cell: Vector2i = _moved.get(npc, npc.get_cell())
		assert_same(_grid.get_occupant(cell), npc, "%s en %s" % [step.actor, cell])
		_grid.release(cell, npc)
		gone.append(npc)
	assert_eq(gone.size(), 2, "les deux Pokémon rentrent dans leur Poké Ball")
	assert_true(rival_gone, "le rival quitte le labo après le combat (rival_left_lab)")
	# Après : le joueur n'est pas enfermé, chaque cible restante est utilisable.
	var reachable := _grid.find_reachable(player_cell, _player)
	assert_true(reachable.has(ENTRANCE), "le tapis de sortie reste atteignable")
	for npc: Npc in _map.get_npcs():
		if npc.get_interaction() == null or gone.has(npc) or npc == rival:
			continue
		var cell: Vector2i = _moved.get(npc, npc.get_cell())
		assert_eq(_grid.get_occupant(cell), npc, "%s en %s" % [npc.get_id(), cell])
		var usable := false
		for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if reachable.has(cell + direction):
				usable = true
		assert_true(usable, "%s utilisable depuis une case atteignable" % npc.get_id())


## Cases des grands personnages (joueur en [param player_cell], humains de la carte) : comme
## CutsceneDirector._tall_cells.
func _tall_cells(player_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [player_cell]
	cells.append_array(_map.get_overhang_cells())
	for npc: Npc in _map.get_npcs():
		if npc.is_tall():
			cells.append(_moved.get(npc, npc.get_cell()))
	return cells


## Le saut de [param npc] de [param from] à [param to] : ni le départ, ni l'arrivée, ni aucune
## case survolée n'est la case d'un personnage (joueur en [param player_cell], PNJ de la
## carte, lui excepté).
func _assert_hop_crosses_nobody(npc: Npc, from: Vector2i, to: Vector2i,
		player_cell: Vector2i, what: String) -> void:
	var people: Dictionary[Vector2i, String] = {player_cell: "joueur"}
	for other: Npc in _map.get_npcs():
		if other != npc:
			people[_moved.get(other, other.get_cell())] = String(other.get_id())
	var path: Array[Vector2i] = [from]
	path.append_array(CutsceneMoves.hop_crossed_cells(from, to))
	path.append(to)
	for cell: Vector2i in path:
		assert_false(people.has(cell), "%s : le saut %s → %s passe par %s (%s)" % [what,
			from, to, cell, people.get(cell, "")])


## [param cell] (un Pokémon) est à côté de [param anchor] (son dresseur) ou légèrement devant :
## case voisine (diagonale comprise), jamais la même, jamais juste au-dessus (derrière la
## tête).
func _assert_beside(cell: Vector2i, anchor: Vector2i, what: String) -> void:
	var delta := cell - anchor
	assert_ne(delta, Vector2i.ZERO, "%s : pas sur la même case" % what)
	assert_lte(maxi(absi(delta.x), absi(delta.y)), 1, "%s : voisin" % what)
	assert_ne(delta, Vector2i.UP, "%s : jamais derrière la tête" % what)


func _assert_above_mat_free(moment: String) -> void:
	assert_false(_grid.is_solid(ABOVE_MAT), "(7, 8) praticable (%s)" % moment)
	assert_false(_grid.is_occupied(ABOVE_MAT), "(7, 8) libre (%s)" % moment)


## La paillasse (rangée 8) dépasse sur la rangée 7 : un Pokémon posé devant elle serait en
## partie caché (capture fix2 du 4A) ; la règle d'atterrissage le sait.
func test_lab_bench_hides_the_cells_in_front_of_it() -> void:
	var overhang := _map.get_overhang_cells()
	assert_true(overhang.has(Vector2i(11, 8)), str(overhang))
	assert_false(overhang.has(Vector2i(10, 5)), "la table des starters ne cache rien : %s"
		% str(overhang))
