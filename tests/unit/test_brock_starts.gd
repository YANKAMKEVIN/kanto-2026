extends GutTest
## Départs de débogage `brock_<starter>` et `brock_kevin` (jalon 10 T16, docs/tech/jalon-10.md
## §2.14) : devant la porte de l'Arène, fin du J9, Liam pas encore battu, niveaux mesurés par
## `tools/simulate_brock.gd` (niveau moyen du starter devant Pierre après la Route 2 nord et
## Liam). Fichier séparé de `test_pewter_data` (T8) pour ne pas toucher ses listes.

const TOOL_STARTS := "res://tools/debug_start/"
const GameStateScript := preload("res://game/autoload/game_state.gd")
const J9_FLAGS: Array[StringName] = [&"pokedex_activated", &"poison_unlocked",
	&"beaten_forest_scout_theo", &"pewter_arrived"]
const ABSENT_FLAGS: Array[StringName] = [&"beaten_pewter_gym_liam", &"brock_met",
	&"badge_boulder"]
## [nom, starter, starter pris par le rival, équipe [espèce, niveau], Potions].
const STARTS: Array = [
	["brock_charmander", &"charmander", &"squirtle",
		[[&"charmander", 12], [&"butterfree", 10], [&"pidgey", 10]], 3],
	["brock_squirtle", &"squirtle", &"bulbasaur", [[&"squirtle", 12], [&"pidgey", 10]], 3],
	["brock_bulbasaur", &"bulbasaur", &"charmander", [[&"bulbasaur", 12], [&"pidgey", 10]], 3],
	["brock_kevin", &"charmander", &"squirtle", [[&"charmander", 11], [&"pidgey", 9],
		[&"caterpie", 6], [&"caterpie", 5], [&"rattata", 3], [&"nidoran_m", 3]], 1],
]

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func test_brock_starts_stand_before_the_gym() -> void:
	for row: Array in STARTS:
		var start := DebugStart.new()
		var name := String(row[0])
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		assert_eq([start.map, start.spawn, start.facing],
			[&"pewter_city", &"from_gym", Vector2i.UP], name)
		assert_false(start.autosave, "%s : ne touche jamais la sauvegarde" % name)
		for flag: StringName in J9_FLAGS:
			assert_true(start.flags.has(flag), "%s : %s" % [name, flag])
		for flag: StringName in ABSENT_FLAGS:
			assert_false(start.flags.has(flag), "%s : sans %s" % [name, flag])
		# Paire du labo (dossier 02 §9) : le starter du joueur et celui du rival.
		var taken: Array[StringName] = []
		for flag: StringName in start.flags:
			if String(flag).begins_with("taken_"):
				taken.append(flag)
		taken.sort()
		var expected: Array[StringName] = [StringName("taken_" + String(row[1])),
			StringName("taken_" + String(row[2]))]
		expected.sort()
		assert_eq(taken, expected, name)
		if MapCatalog.has_map(start.map):
			var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
					as GameMap
			assert_true(map.has_spawn(start.spawn), "%s : point d'apparition" % name)
			map.free()


func test_brock_starts_have_the_measured_teams() -> void:
	for row: Array in STARTS:
		var start := DebugStart.new()
		var name := String(row[0])
		start.load_file(TOOL_STARTS + name + ".json", _data, _items)
		var state: Node = autofree(GameStateScript.new())
		start.apply(state, _data)
		var team: Array = []
		for pokemon: Pokemon in state.party.get_all():
			team.append([pokemon.species_id, pokemon.level])
		assert_eq(team, row[3], name)
		assert_eq(state.party.get_at(0).species_id, row[1], "%s : le starter en tête" % name)
		assert_eq(start.bag.get(&"potion", 0), row[4], "%s : Potions" % name)


func test_charmander_start_has_the_butterfree_answer() -> void:
	var start := DebugStart.new()
	start.load_file(TOOL_STARTS + "brock_charmander.json", _data, _items)
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	var butterfree: Pokemon = state.party.get_at(1)
	assert_true(butterfree.knows_move(&"confusion"), "Choc Mental (dossier 12, arbitrage 3)")


func test_kevin_start_matches_his_end_of_j9_game() -> void:
	# Sauvegarde de la QA T22 du J9 (jalon-10.md §0.3 n° 8) : 1 396 ₽, 1 Potion, Salamèche
	# avec ses trois capacités (sans Groz'Yeux, appris au N15), après la Route 2 nord (N11).
	var start := DebugStart.new()
	start.load_file(TOOL_STARTS + "brock_kevin.json", _data, _items)
	var state: Node = autofree(GameStateScript.new())
	start.apply(state, _data)
	assert_eq(state.money, 1396)
	var moves: Array[StringName] = []
	for slot: MoveSlot in state.party.get_at(0).moves:
		moves.append(slot.move_id)
	assert_eq(moves, [&"scratch", &"growl", &"ember"] as Array[StringName])
