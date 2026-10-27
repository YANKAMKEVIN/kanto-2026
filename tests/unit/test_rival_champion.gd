extends GutTest
## Rival Champion (jalon 30, `jalon-30.md` §2.7, §5) : trois équipes selon
## `GameState.starter_species` (le starter **choisi**), jamais selon l'équipe du joueur ; les
## départs `league_champion_<starter>` (§2.8) tombent chacun sur sa variante.

const STARTS := "res://tools/debug_start/league_champion_%s.json"
## Dernier Pokémon du rival (son starter, évolué) contre chaque starter du joueur.
const ACE: Dictionary[StringName, StringName] = {
	&"bulbasaur": &"charizard", &"charmander": &"blastoise", &"squirtle": &"venusaur",
}

var _pokemon: PokemonData
var _trainers: TrainerLibrary


func before_all() -> void:
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()


func _species(party: Party) -> Array[StringName]:
	var result: Array[StringName] = []
	for member: Pokemon in party.get_all():
		result.append(member.species_id)
	return result


func test_three_teams_by_starter() -> void:
	for starter: StringName in ACE:
		var team := _species(_trainers.build_team(&"rival_champion", starter, GameRng.new(1)))
		assert_eq(team.size(), 6, String(starter))
		assert_eq(team[0], &"pidgeot", "Roucarnage en tête (%s)" % starter)
		assert_eq(team.back(), ACE[starter], "starter du rival en dernier (%s)" % starter)
	assert_null(_trainers.build_team(&"rival_champion", &"pikachu", GameRng.new(1)),
		"aucune équipe hors des trois starters")
	assert_push_error_count(1, "Pikachu : pas d'équipe, erreur signalée")


func test_the_variant_follows_the_chosen_starter_not_the_party() -> void:
	# Le joueur a choisi Bulbizarre mais n'a plus qu'un Tortank : l'équipe reste « Bulbizarre ».
	var state: Node = preload("res://game/autoload/game_state.gd").new()
	state.new_game()
	state.starter_species = &"bulbasaur"
	state.party.add(PokemonFactory.create(_pokemon, &"blastoise", 60, GameRng.new(2)))
	var team := _species(_trainers.build_team(&"rival_champion", state.starter_species,
		GameRng.new(1)))
	assert_eq(team.back(), &"charizard")
	state.free()


func test_each_champion_start_picks_its_variant() -> void:
	var items := ItemLibrary.new()
	items.load_dir()
	for starter: StringName in ACE:
		var start := DebugStart.new()
		assert_true(start.load_file(STARTS % starter, _pokemon, items),
			"\n".join(start.get_errors()))
		var state: Node = preload("res://game/autoload/game_state.gd").new()
		start.apply(state, _pokemon)
		assert_eq(state.starter_species, starter)
		assert_eq(LeagueAttempt.current_stage(state.flags), 4, "Champion à affronter")
		var team := _species(_trainers.build_team(&"rival_champion", state.starter_species,
			GameRng.new(1)))
		assert_eq(team.back(), ACE[starter])
		state.free()
