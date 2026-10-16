extends GutTest
## Scénarios d'équilibrage du jalon 16 (T18) joués par `tools/simulate_mt_moon.gd` (générés par
## `tools/sim/gen_ss_anne_scenarios.py`) : le parcours (fin du J13 → Major Bob) et les seuils
## (un combat) se valident avec les données (`--donnees`, rien de sauté) ; une courte partie se
## joue jusqu'à Major Bob sans erreur. Les pourcentages sont une information pour Kevin
## (`docs/tech/jalon-16-equilibrage.md`).

const TOOL := "res://tools/simulate_mt_moon.gd"
const PATH := "res://tools/sim/ss_anne_scenario.json"
const THRESHOLDS := "res://tools/sim/ss_anne_thresholds.json"
const RIVAL_40 := "res://tools/sim/ss_anne_rival_40.json"
const ORDINARY := "res://tools/sim/ss_anne_ordinary.json"
const EXIT_OK := 0


func test_path_scenario_is_valid_with_data() -> void:
	var run := _run(["--scenario", PATH, "--donnees", "--valider"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(out.contains("=== Équilibrage du S.S. Anne, du rival n° 4 et de Major Bob"),
		"titre absent")
	for label: String in ["J15 Route 6 : Chloé (inévitable)", "S.S. Anne : Marin Paul",
			"Centre de Carmin (retour au quai avant le rival)",
			"Rival n° 4 (couloir du capitaine)", "Arène de Carmin : Rockeur Axel",
			"Centre de Carmin (entre les Dresseurs et Major Bob)", "Major Bob (Arène de Carmin)"]:
		assert_true(out.contains(label), "étape absente : " + label)
	# Le rival et Major Bob sont relus dans data/ (même identifiant) et changent de Pokémon.
	assert_true(out.contains("rival_ss_anne : {rival}, IA smart qui change"), out.right(2000))
	assert_true(out.contains("vermilion_gym_surge : Major Bob, IA smart qui change"),
		out.right(2000))
	assert_true(out.contains("Rival n° 4 (couloir du capitaine) : rival_ss_anne [données]"),
		out.right(2000))


func test_thresholds_scenario_is_valid() -> void:
	var run := _run(["--scenario", THRESHOLDS, "--valider"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_true(out.contains("Major Bob (c) : Raichu N24 sans Tonnerre"), out.right(2000))
	assert_true(out.contains("Rival n° 4 sans changement"), out.right(2000))


func test_rival_40_and_ordinary_scenarios_are_valid() -> void:
	# Recalage du rival n° 4 à ~40 % et règle des 80 % (jalon-16-equilibrage.md §10).
	var run := _run(["--scenario", RIVAL_40, "--valider"])
	assert_eq(run[0], EXIT_OK, String(run[1]).right(2000))
	assert_true(String(run[1]).contains("Rival n° 4 17/15/20/20"), String(run[1]).right(2000))
	run = _run(["--scenario", ORDINARY, "--valider"])
	assert_eq(run[0], EXIT_OK, String(run[1]).right(2000))
	assert_true(String(run[1]).contains("[plus4_smart]"), String(run[1]).right(2000))


func test_short_run_reaches_major_bob() -> void:
	var run := _run(["--scenario", PATH, "--donnees", "--seeds", "10", "--equipe",
		"Carabaffe 21", "--variante", "directe, soin avant Major Bob, attentif"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), out.right(2000))
	assert_false(out.contains("non terminés"), out.right(2000))
	assert_true(out.contains("--- Sol : Carabaffe 21"), "équipe avec Racaillou absente")
	var report := out.substr(out.find("=== Simulation"))
	assert_true(report.contains("Major Bob (Arène de Carmin)"), out.right(2000))


func _run(args: Array) -> Array:
	var output: Array = []
	var all: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s",
		TOOL, "--"]
	all.append_array(args)
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(all), output, true)
	return [code, "\n".join(PackedStringArray(output))]
