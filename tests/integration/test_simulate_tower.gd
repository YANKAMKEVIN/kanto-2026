extends GutTest
## Scénario d'équilibrage du jalon 19 (T4, joué au T21) par `tools/simulate_mt_moon.gd` : le vrai
## scénario se valide avec les données (`--donnees`, rien de sauté) ; une courte simulation se
## joue sans erreur. Les pourcentages sont une information pour Kevin (`jalon-19.md` T21).

const TOOL := "res://tools/simulate_mt_moon.gd"
const REAL := "res://tools/sim/tower_scenario.json"
const T21 := "res://tools/sim/tower_t21.json"
const EXIT_OK := 0


func test_real_scenario_is_valid_with_data() -> void:
	var run := _run(["--scenario", REAL, "--donnees", "--valider"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(out.contains("=== Équilibrage de la Tour Pokémon"), "titre absent")
	assert_true(out.contains("rien n'a été sauté"), out.right(2000))
	for label: String in ["Rival n° 5 (2F, inévitable)", "E3 Exorciste Solange (4F, inévitable)",
			"E8 Exorciste Paulette (6F, inévitable)", "E9 Exorciste Clémence (6F, inévitable)",
			"E1 Exorciste Hortense (3F)", "Zone purifiée (5F, soin complet)"]:
		assert_true(out.contains(label), "étape absente : " + label)
	# Dresseurs relus dans data/ (même identifiant) ; aucune étape « wild ».
	assert_true(out.contains("rival_tower : {rival}, IA smart qui change, 35 ₽ × niveau"),
		out.right(2000))
	assert_true(out.contains("tower_channeler_3 : Exorciste Solange, IA random, 30 ₽ × niveau"),
		out.right(2000))
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(REAL))
	for step: Dictionary in scenario["steps"]:
		assert_false(step.has("wild"), "les SPECTRES ne donnent rien : %s" % step["label"])
	var starters: Array = []
	for team: Dictionary in scenario["teams"]:
		if not starters.has(team["starter"]):
			starters.append(team["starter"])
	starters.sort()
	assert_eq(starters, ["bulbasaur", "charmander", "squirtle"], "les trois variantes du rival")


## T21 : réglages du rival n° 5 sur les sorties réelles du J18 (`tools/sim/gen_tower_t21.py`).
func test_t21_scenario_is_valid_and_keeps_the_data_rival() -> void:
	var run := _run(["--scenario", T21, "--valider"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_true(out.contains("rien n'a été sauté"), out.right(2000))
	var scenario: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(T21))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/trainers/pokemon_tower.json"))
	assert_eq(scenario["trainers"]["rival_tower"], data["rival_tower"],
		"le réglage « retenu » est celui de data/ (relancer gen_tower_t21.py)")


func test_short_run_plays_without_error() -> void:
	var run := _run(["--scenario", REAL, "--donnees", "--seeds", "3", "--equipe",
		"bas : Carabaffe", "--variante", "tous les Exorcistes, attentif"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), out.right(2000))
	assert_false(out.contains("start impossible"), out.right(2000))


func _run(args: Array) -> Array:
	var output: Array = []
	var all: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s",
		TOOL, "--"]
	all.append_array(args)
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(all), output, true)
	return [code, "\n".join(PackedStringArray(output))]
