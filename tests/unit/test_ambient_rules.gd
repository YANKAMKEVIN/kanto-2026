extends GutTest
## AmbientRules : rayon d'approche (Manhattan) et fuite d'un Pokémon d'ambiance (jalon 5
## §3.5). Classe pure, statique, reproductible : aucun aléatoire.

var _grid: GridWorld


func before_each() -> void:
	_grid = GridWorld.new(Vector2i(10, 10))


# --- Rayon (distance de Manhattan) ---------------------------------------------------

func test_is_within_uses_manhattan_distance() -> void:
	var npc := Vector2i(5, 5)
	assert_true(AmbientRules.is_within(npc, Vector2i(5, 5), 0), "même case")
	assert_true(AmbientRules.is_within(npc, Vector2i(5, 3), 2), "2 cases en ligne")
	assert_true(AmbientRules.is_within(npc, Vector2i(6, 6), 2), "diagonale = 2 en Manhattan")
	assert_false(AmbientRules.is_within(npc, Vector2i(6, 7), 2), "3 en Manhattan")
	assert_false(AmbientRules.is_within(npc, Vector2i(5, 2), 2), "3 cases en ligne")


# --- Fuite ---------------------------------------------------------------------------

func test_flee_path_moves_away_and_is_reproducible() -> void:
	# Joueur au sud, PNJ au nord : la fuite doit monter (UP essayé en premier et éloigne).
	var path := AmbientRules.flee_path(_grid, Vector2i(5, 4), Vector2i(5, 8), 3)
	assert_eq(path.size(), 3)
	for direction: Vector2i in path:
		assert_eq(direction, Vector2i.UP)
	# Déterministe : même appel, même chemin.
	var again := AmbientRules.flee_path(_grid, Vector2i(5, 4), Vector2i(5, 8), 3)
	assert_eq(again, path)


func test_flee_path_respects_max_steps() -> void:
	var path := AmbientRules.flee_path(_grid, Vector2i(5, 4), Vector2i(5, 8), 2)
	assert_eq(path.size(), 2)
	assert_eq(AmbientRules.flee_path(_grid, Vector2i(5, 4), Vector2i(5, 8), 0).size(), 0)


func test_flee_path_only_uses_free_cells() -> void:
	# Bloque la case juste au nord : la fuite doit contourner par un autre axe qui éloigne.
	_grid.set_solid(Vector2i(5, 3))
	var path := AmbientRules.flee_path(_grid, Vector2i(5, 4), Vector2i(5, 8), 1)
	assert_eq(path.size(), 1)
	assert_ne(path[0], Vector2i.UP, "case nord solide : autre direction")
	assert_true(path[0] == Vector2i.LEFT or path[0] == Vector2i.RIGHT,
		"gauche ou droite éloignent aussi du sud")


func test_flee_path_avoids_ledge_cells() -> void:
	# Un rebord n'est pas « libre » : la fuite ne s'y pose pas.
	_grid.set_ledge(Vector2i(5, 3), GridWorld.Ledge.DOWN)
	var path := AmbientRules.flee_path(_grid, Vector2i(5, 4), Vector2i(5, 8), 1)
	assert_eq(path.size(), 1)
	assert_ne(path[0], Vector2i.UP)


func test_flee_path_is_empty_when_cornered() -> void:
	# PNJ dans le coin (0, 0), joueur juste en (1, 0) et (0, 1) bloque tout éloignement utile :
	# on entoure de solides toutes les cases qui éloigneraient.
	var npc := Vector2i(0, 0)
	var player := Vector2i(2, 2)
	# Les seules cases qui éloignent de (2,2) depuis (0,0) sont hors carte (pas de x<0, y<0).
	var path := AmbientRules.flee_path(_grid, npc, player, 3)
	assert_eq(path.size(), 0, "acculé dans le coin : il reste")


func test_flee_path_stops_when_no_step_increases_distance() -> void:
	# Entoure la case de départ de solides : aucun pas possible.
	var from := Vector2i(5, 5)
	for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		_grid.set_solid(from + direction)
	assert_eq(AmbientRules.flee_path(_grid, from, Vector2i(0, 0), 3).size(), 0)


func test_flee_path_null_grid_is_empty() -> void:
	assert_eq(AmbientRules.flee_path(null, Vector2i(1, 1), Vector2i(4, 4), 3).size(), 0)


# --- Rattata de la Route 2 (jalon 8 T7) : grille de la vraie carte --------------------------

func _route_2_map() -> GameMap:
	var map := (load("res://game/world/maps/route_2.tscn") as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


## Le clairière du Rattata (cases 11..16 × 40..44) : la fuite n'en sort jamais.
func test_route_2_rattata_flees_to_its_niche_behind_the_bushes() -> void:
	var map := _route_2_map()
	var grid := map.get_grid()
	var rattata := NpcRoster.load_for_map(&"route_2").get_spec(&"rattata")
	assert_eq(rattata.cell, Vector2i(15, 44))
	assert_eq(rattata.shy_radius, 2)
	var niche := Vector2i(16, 44)
	var npc := map.get_npc(&"rattata")
	# Le joueur arrive de l'ouest vers la souche (14, 42) : il passe en (14, 43).
	var path := AmbientRules.flee_path(grid, rattata.cell, Vector2i(14, 43), 3, npc)
	var end := rattata.cell
	for direction: Vector2i in path:
		end += direction
	assert_eq(end, niche, "fuite finie sur la niche, contre les buissons du sud")
	assert_false(grid.is_free(niche + Vector2i.DOWN), "buissons au sud de la niche")
	assert_true(grid.is_solid(niche + Vector2i.RIGHT))


func test_route_2_rattata_never_leaves_its_clearing_whatever_the_approach() -> void:
	var map := _route_2_map()
	var grid := map.get_grid()
	var rattata := NpcRoster.load_for_map(&"route_2").get_spec(&"rattata")
	var npc := map.get_npc(&"rattata")
	var checked := 0
	for dy: int in range(-2, 3):
		for dx: int in range(-2, 3):
			var player := rattata.cell + Vector2i(dx, dy)
			if absi(dx) + absi(dy) > rattata.shy_radius or player == rattata.cell \
					or not grid.is_free(player):
				continue
			checked += 1
			var end := rattata.cell
			for direction: Vector2i in AmbientRules.flee_path(grid, end, player, 3, npc):
				end += direction
				assert_false(grid.is_tall_grass(end), "pas d'herbes hautes en %s" % end)
				assert_true(Rect2i(11, 40, 6, 5).has_point(end),
					"approche %s : %s reste dans la clairière" % [player, end])
	assert_gt(checked, 3)


# --- Jalon 9 (T18) : qui quitte la carte -----------------------------------------------

func test_only_notice_keeps_the_pokemon_on_the_map() -> void:
	assert_false(AmbientRules.leaves_map(&"notice"), "Chenipan relève la tête et reste")
	for action: StringName in [&"fly", &"flee", &"hide"]:
		assert_true(AmbientRules.leaves_map(action), String(action))
	for action: StringName in NpcSpec.SHY_ACTIONS:
		assert_true(action in [&"fly", &"flee", &"notice", &"hide"], String(action))
