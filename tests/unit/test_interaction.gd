extends GutTest
## Interaction, InteractionTable, InteractionFinder : cible devant le joueur, PNJ avant
## points fixes, orientation exigée, conflits (jalon 3 §2.2).


## PNJ minimal : occupe une case et expose get_interaction(), comme la scène Npc.
class FakeNpc:
	extends RefCounted
	var interaction: Interaction

	func get_interaction() -> Interaction:
		return interaction


## Occupant sans interaction (le joueur, un Roucool non interactif).
class Blocker:
	extends RefCounted


const PLAYER := Vector2i(5, 5)

var _grid: GridWorld
var _table: InteractionTable
## PNJ créés par le test : npc → interaction → npc est un cycle de références, rompu
## après chaque test (la vraie scène Npc est un Node, sans comptage de références).
var _npcs: Array[FakeNpc] = []


func before_each() -> void:
	_grid = GridWorld.new(Vector2i(10, 10))
	_table = InteractionTable.new()


func after_each() -> void:
	for npc: FakeNpc in _npcs:
		npc.interaction = null
	_npcs.clear()


func _examine(cell: Vector2i, id: StringName, facing: Vector2i = Vector2i.ZERO) -> Interaction:
	return Interaction.new(Interaction.Kind.EXAMINE, cell, id, facing)


func _npc_at(cell: Vector2i, id: StringName,
		kind: Interaction.Kind = Interaction.Kind.TALK) -> FakeNpc:
	var npc := FakeNpc.new()
	npc.interaction = Interaction.new(kind, cell, id, Vector2i.ZERO, npc)
	_grid.occupy(cell, npc)
	_npcs.append(npc)
	return npc


# --- Interaction ------------------------------------------------------------------------

func test_validity() -> void:
	assert_true(_examine(PLAYER, &"table").is_valid())
	assert_true(_examine(PLAYER, &"map", Vector2i.UP).is_valid())
	assert_false(_examine(PLAYER, &"").is_valid(), "dialogue obligatoire")
	assert_false(_examine(PLAYER, &"x", Vector2i(1, 1)).is_valid(), "diagonale")


func test_accepts_required_facing() -> void:
	var any := _examine(PLAYER, &"table")
	var from_below := _examine(PLAYER, &"map", Vector2i.UP)
	assert_true(any.accepts(Vector2i.LEFT))
	assert_true(from_below.accepts(Vector2i.UP))
	assert_false(from_below.accepts(Vector2i.LEFT))


func test_kind_names_round_trip() -> void:
	for kind: Interaction.Kind in [Interaction.Kind.TALK, Interaction.Kind.EXAMINE,
			Interaction.Kind.OBSERVE]:
		assert_eq(Interaction.kind_from_name(Interaction.kind_name(kind)), kind)
	assert_eq(Interaction.kind_from_name("jump"), -1)


# --- InteractionTable -------------------------------------------------------------------

func test_table_finds_by_cell_and_facing() -> void:
	assert_true(_table.add(_examine(Vector2i(3, 2), &"map", Vector2i.UP)))
	assert_eq(_table.find(Vector2i(3, 2), Vector2i.UP).dialogue_id, &"map")
	assert_null(_table.find(Vector2i(3, 2), Vector2i.RIGHT), "mauvais côté")
	assert_null(_table.find(Vector2i(4, 2), Vector2i.UP), "autre case")
	assert_eq(_table.size(), 1)


func test_table_accepts_different_sides_of_one_cell() -> void:
	assert_true(_table.add(_examine(Vector2i(3, 2), &"front", Vector2i.UP)))
	assert_true(_table.add(_examine(Vector2i(3, 2), &"side", Vector2i.LEFT)))
	assert_eq(_table.find(Vector2i(3, 2), Vector2i.LEFT).dialogue_id, &"side")
	assert_eq(_table.get_at(Vector2i(3, 2)).size(), 2)


func test_table_rejects_invalid_and_ambiguous() -> void:
	assert_false(_table.add(null))
	assert_false(_table.add(_examine(Vector2i(1, 1), &"")))
	assert_true(_table.add(_examine(Vector2i(1, 1), &"a", Vector2i.UP)))
	assert_false(_table.add(_examine(Vector2i(1, 1), &"b", Vector2i.UP)), "même côté")
	assert_false(_table.add(_examine(Vector2i(1, 1), &"c")), "tous côtés ∩ UP")
	assert_true(_table.add(_examine(Vector2i(2, 2), &"d")))
	assert_false(_table.add(_examine(Vector2i(2, 2), &"e", Vector2i.DOWN)), "∩ tous côtés")
	assert_eq(_table.size(), 2)
	assert_eq(_table.get_all().size(), 2)
	assert_false(_table.is_empty())


# --- InteractionFinder ------------------------------------------------------------------

func test_nothing_in_front_gives_null() -> void:
	assert_null(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP))
	assert_null(InteractionFinder.find(null, null, PLAYER, Vector2i.UP))


func test_npc_in_front_is_the_target() -> void:
	var npc := _npc_at(PLAYER + Vector2i.UP, &"mom")
	var target := InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP)
	assert_not_null(target)
	assert_eq(target.kind, Interaction.Kind.TALK)
	assert_eq(target.dialogue_id, &"mom")
	assert_eq(target.source, npc)


func test_only_the_cell_in_front_counts() -> void:
	_npc_at(PLAYER + Vector2i.LEFT, &"mom")
	_table.add(_examine(PLAYER + Vector2i.RIGHT, &"table"))
	_table.add(_examine(PLAYER + Vector2i.DOWN, &"rug"))
	assert_null(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP))
	assert_eq(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.LEFT).dialogue_id, &"mom")
	assert_eq(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.RIGHT).dialogue_id,
		&"table")


func test_npc_wins_over_a_point_on_the_same_cell() -> void:
	_table.add(_examine(PLAYER + Vector2i.UP, &"table"))
	_npc_at(PLAYER + Vector2i.UP, &"mom")
	assert_eq(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP).dialogue_id, &"mom")


func test_observed_pokemon_on_a_solid_table() -> void:
	# Les starters occupent le bord avant de la table (case solide) : on les observe.
	var cell := PLAYER + Vector2i.UP
	_grid.set_solid(cell)
	_npc_at(cell, &"observe_charmander", Interaction.Kind.OBSERVE)
	var target := InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP)
	assert_eq(target.kind, Interaction.Kind.OBSERVE)


func test_occupant_without_interaction_falls_back_to_the_table() -> void:
	var cell := PLAYER + Vector2i.UP
	_grid.occupy(cell, Blocker.new())
	assert_null(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP))
	_table.add(_examine(cell, &"flowers"))
	assert_eq(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP).dialogue_id,
		&"flowers")


func test_npc_that_is_not_interactive_falls_back() -> void:
	var npc := _npc_at(PLAYER + Vector2i.UP, &"pidgey")
	npc.interaction = null
	assert_null(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP))


func test_point_with_required_facing() -> void:
	_table.add(_examine(PLAYER + Vector2i.UP, &"map", Vector2i.UP))
	assert_not_null(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.UP))
	var below := PLAYER + Vector2i(0, -2)
	_table.add(_examine(below + Vector2i.DOWN, &"back", Vector2i.UP))
	assert_null(InteractionFinder.find(_grid, _table, below, Vector2i.DOWN),
		"de l'autre côté")


func test_non_cardinal_facing_gives_null() -> void:
	_npc_at(PLAYER + Vector2i.UP, &"mom")
	assert_null(InteractionFinder.find(_grid, _table, PLAYER, Vector2i.ZERO))
	assert_null(InteractionFinder.find(_grid, _table, PLAYER, Vector2i(1, -1)))


func test_edge_of_map_gives_null() -> void:
	assert_null(InteractionFinder.find(_grid, _table, Vector2i(0, 0), Vector2i.UP))
