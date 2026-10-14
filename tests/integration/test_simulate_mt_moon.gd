extends GutTest
## `tools/simulate_mt_moon.gd` (jalon 12 T10) : l'outil tourne dans un processus à part sur le
## scénario réduit (espèces existantes), saute proprement ce qui manque aux données (code 3,
## message clair), refuse un scénario invalide (code 1) et valide le vrai scénario du J12 sans
## erreur de script. Les pourcentages ne sont pas vérifiés (information pour Kevin).

const TOOL := "res://tools/simulate_mt_moon.gd"
const DEMO := "res://tools/sim/mt_moon_scenario_demo.json"
const REAL := "res://tools/sim/mt_moon_scenario.json"
const ABSENT := "res://tests/fixtures/sim/mt_moon_absent.json"
const INVALID := "res://tests/fixtures/sim/mt_moon_invalid.json"
const EXIT_OK := 0
const EXIT_ERROR := 1
const EXIT_SKIPPED := 3


func test_demo_scenario_runs_to_the_end() -> void:
	var run := _run(["--scenario", DEMO, "--seeds", "2"])
	assert_eq(run[0], EXIT_OK, run[1].right(2000))
	assert_false(run[1].contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(run[1].contains("=== Simulation : 2 graine(s) par ligne ==="), "simulation absente")
	assert_true(run[1].contains("--- Salamèche 15, Férosinge 15, Roucool 13 | attentif, "
		+ "sans soins"), "ligne équipe | variante absente")
	assert_true(run[1].contains("R3 Sbire gardien (B2F)"), "dernière étape absente")
	assert_true(run[1].contains("rien n'a été sauté (code 0)"), "fin absente")


## T26 : reprises au Centre après une défaite (« retries ») et déroulé des combats (`--trace`).
func test_retries_and_trace() -> void:
	var run := _run(["--scenario", DEMO, "--seeds", "2", "--variante", "reprise", "--trace",
		"R1"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(out.contains("--- Salamèche 15, Férosinge 15, Roucool 13 | naïf, Centre, "
		+ "1 reprise"), out)
	assert_true(out.contains("avec reprises au Centre : arrivée après 0 défaite(s) "), out)
	assert_true(out.contains(", 1 défaite(s) "), out)
	assert_true(out.contains(">>> graine 0, R1 Sbire guetteur (B1F)"), out)
	assert_true(out.contains("Sbire Rocket veut se battre !"), "déroulé absent")
	assert_false(out.contains(">>> graine 2,"), "seules les premières graines sont racontées")


func test_absent_ids_are_skipped_with_a_distinct_code() -> void:
	var run := _run(["--scenario", ABSENT])
	var out: String = run[1]
	assert_eq(run[0], EXIT_SKIPPED, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(out.contains("SAUTÉ table « absent_grass » — espèces absentes des données : "
		+ "t10_absent_species"), out)
	assert_true(out.contains("SAUTÉ équipe « Équipe sans capacité » — capacités absentes des "
		+ "données : t10_absent_move"), out)
	assert_true(out.contains("SAUTÉ variante « objet absent » — objets absents des données : "
		+ "t10_absent_item"), out)
	assert_true(out.contains("SAUTÉ étape 2 « Sbire absent »"), out)
	# Le reste du parcours est joué.
	assert_true(out.contains("--- Équipe valide | attentif, Centre"), out)
	assert_false(out.contains("--- Équipe sans capacité |"), "équipe sautée simulée")
	assert_true(out.contains("6 élément(s) SAUTÉ(S) (code 3)"), out)


func test_validate_only_runs_no_battle() -> void:
	var run := _run(["--scenario", ABSENT, "--valider"])
	assert_eq(run[0], EXIT_SKIPPED, run[1].right(2000))
	assert_false(run[1].contains("=== Simulation"), "--valider ne simule rien")


func test_invalid_scenario_is_refused() -> void:
	var run := _run(["--scenario", INVALID, "--valider"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_ERROR, out.right(2000))
	assert_true(out.contains("=== Scénario invalide"), out)
	assert_true(out.contains("table inconnue « unknown_table »"), out)
	assert_true(out.contains("clé inconnue « typo »"), out)
	assert_true(out.contains("« player » vaut naif, attentif"), out)


## Le vrai scénario du J12 : valide aujourd'hui (espèces du J12 sautées, code 3) comme après
## le T12 (code 0).
func test_real_scenario_is_valid() -> void:
	var run := _run(["--scenario", REAL, "--valider"])
	assert_true(run[0] in [EXIT_OK, EXIT_SKIPPED], run[1].right(2000))
	assert_false(run[1].contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(run[1].contains("Chercheur Gaspard (B2F)"), "parcours incomplet")


## [code de sortie, sortie] de l'outil lancé avec [param args].
func _run(args: Array) -> Array:
	var output: Array = []
	var all: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s",
		TOOL, "--"]
	all.append_array(args)
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(all), output, true)
	return [code, "\n".join(PackedStringArray(output))]
