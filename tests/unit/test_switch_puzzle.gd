extends GutTest
## Puzzle des interrupteurs de l'Arène de Carmin (jalon 16, T9 ; dossier 19 §9, G-8 « Rouge/Bleu
## strict », `jalon-16.md` §2.6) : premier au hasard, second voisin, erreur → tout à zéro et
## nouveau tirage ; exhaustif sur les 15 premiers possibles et tous leurs voisins.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")


func test_neighbors_of_the_5x3_grid() -> void:
	var puzzle := SwitchPuzzle.new(GameRng.new(1))
	assert_eq(puzzle.neighbors(1), [6, 2] as Array[int], "coin haut gauche")
	assert_eq(puzzle.neighbors(8), [3, 13, 7, 9] as Array[int], "centre")
	assert_eq(puzzle.neighbors(15), [10, 14] as Array[int], "coin bas droite")
	for index: int in range(1, 16):
		assert_false(puzzle.neighbors(index).is_empty(), "chaque objet a un voisin")


func test_every_first_and_every_neighbor_solves() -> void:
	for first: int in range(1, 16):
		var count := SwitchPuzzle.new(GameRng.new(1)).neighbors(first).size()
		for k: int in range(1, count + 1):
			var rng := ScriptedRng.new([first, k])
			var puzzle := SwitchPuzzle.new(rng)
			puzzle.start()
			assert_eq(puzzle.first(), first)
			for other: int in range(1, 16):
				if other != first:
					assert_eq(puzzle.search(other), SwitchPuzzle.Result.NOTHING)
			assert_eq(puzzle.search(first), SwitchPuzzle.Result.FIRST_FOUND)
			var second := puzzle.second()
			assert_true(puzzle.neighbors(first).has(second), "%d → %d voisin" % [first, second])
			assert_eq(puzzle.search(second), SwitchPuzzle.Result.SOLVED)
			assert_true(puzzle.is_solved())
			assert_eq(puzzle.search(first), SwitchPuzzle.Result.NOTHING, "résolu : plus rien")


func test_error_after_the_first_resets_with_a_new_draw() -> void:
	var rng := ScriptedRng.new([8, 1, 14])
	var puzzle := SwitchPuzzle.new(rng)
	puzzle.start()
	assert_eq(puzzle.search(8), SwitchPuzzle.Result.FIRST_FOUND)
	assert_eq(puzzle.second(), 3, "voisin n° 1 de 8 : en haut")
	assert_eq(puzzle.search(9), SwitchPuzzle.Result.RESET, "mauvais voisin")
	assert_false(puzzle.is_first_found())
	assert_eq(puzzle.first(), 14, "nouveau tirage")
	assert_eq(rng.remaining(), 0)


func test_searching_the_first_again_also_resets() -> void:
	var puzzle := SwitchPuzzle.new(ScriptedRng.new([5, 1, 2]))
	puzzle.start()
	puzzle.search(5)
	assert_eq(puzzle.search(5), SwitchPuzzle.Result.RESET, "le premier deux fois : erreur")
