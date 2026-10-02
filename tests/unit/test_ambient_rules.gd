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
