extends GutTest
## Jalon 17 (T4, jalon-17.md §2.5) : Boot branche le compte d'espèces capturées du Pokédex sur
## le DialogueRunner (variantes « if_caught_at_least ») et sur les jetons {caught} /
## {caught_missing}.


func after_each() -> void:
	GameState.pokedex.clear()


func test_boot_wires_the_pokedex_count() -> void:
	var boot := (load("res://game/boot.tscn") as PackedScene).instantiate() as Boot
	add_child_autofree(boot)
	var runner := boot.get_dialogue_runner()
	assert_true(runner.caught_count.is_valid())
	GameState.pokedex.clear()
	for species: StringName in [&"charmander", &"pidgey", &"rattata"]:
		GameState.record_caught(species, &"route_1")
	GameState.record_seen(&"spearow", &"route_1")
	assert_eq(int(runner.caught_count.call()), 3, "espèces capturées seulement")
	GameState.record_evolved(&"pidgeotto")
	assert_eq(int(runner.caught_count.call()), 4, "une évolution compte (dossier 20 §8)")
	var values: Dictionary = runner.token_values.call()
	assert_eq(values.get(&"caught"), "4")
	assert_eq(values.get(&"caught_missing"), "6")
