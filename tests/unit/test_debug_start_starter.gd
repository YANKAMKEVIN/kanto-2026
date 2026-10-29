extends GutTest
## Starter d'un départ de débogage (J33 T5, anomalie RP-266) : un starter évolué ou un autre
## Pokémon en tête ne doit pas laisser la partie sans starter connu (le rival n'aurait pas
## d'équipe : combat vide compté comme une défaite).

const STARTS := "res://tools/debug_start/"


func test_a_base_starter_in_the_lead_is_kept() -> void:
	assert_eq(DebugStart.starter_of(&"squirtle", [&"taken_charmander", &"taken_squirtle"]),
		&"squirtle", "le premier de l'équipe prime quand c'est un starter")


func test_the_taken_pair_names_the_starter_otherwise() -> void:
	assert_eq(DebugStart.starter_of(&"blastoise", [&"taken_bulbasaur", &"taken_squirtle"]),
		&"squirtle")
	assert_eq(DebugStart.starter_of(&"pikachu", [&"taken_charmander", &"taken_squirtle"]),
		&"charmander")
	assert_eq(DebugStart.starter_of(&"charizard", [&"taken_bulbasaur", &"taken_charmander"]),
		&"bulbasaur")


func test_without_a_pair_the_lead_stays() -> void:
	assert_eq(DebugStart.starter_of(&"pikachu", [] as Array[StringName]), &"pikachu")


## Tout départ dont le starter est choisi a un starter dont le rival a une équipe.
func test_every_start_after_the_choice_has_a_rival_team() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	var trainers := TrainerLibrary.new(data)
	assert_true(trainers.load_dir())
	var rival := trainers.get_trainer(&"rival_champion")
	var checked := 0
	for file: String in DirAccess.get_files_at(STARTS):
		if not file.ends_with(".json"):
			continue
		var start := DebugStart.new()
		if not start.load_file(STARTS + file, data, items):
			continue
		if not start.flags.has(&"starter_chosen") or start.party.is_empty():
			continue
		var starter := DebugStart.starter_of(StringName(start.party[0]["species"]), start.flags)
		checked += 1
		assert_false(rival.team_for(starter).is_empty(), "%s : starter %s" % [file, starter])
	assert_gt(checked, 150)
