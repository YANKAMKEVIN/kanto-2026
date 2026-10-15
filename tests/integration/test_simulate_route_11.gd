extends GutTest
## Scénario d'équilibrage du jalon 17 (T8 ; `jalon-17.md` §2.12.4) joué par l'outil commun
## `tools/simulate_mt_moon.gd` : le vrai scénario se valide avec les données (`--donnees`, rien
## de sauté : espèces, capacités et Dresseurs du J17 présents) et une courte simulation se joue
## sans erreur. Les pourcentages sont une information pour Kevin (`jalon-17.md` §2.12.4).

const TOOL := "res://tools/simulate_mt_moon.gd"
const REAL := "res://tools/sim/route_11_scenario.json"
const EXIT_OK := 0


func test_real_scenario_is_valid_with_data() -> void:
	var run := _run(["--scenario", REAL, "--donnees", "--valider"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(out.contains("=== Équilibrage de la Route 11 et de la Cave Taupiqueur"),
		"titre absent")
	for label: String in ["D2 Gamin Arthur (inévitable)", "D8 Ingénieur Victor",
			"Cave : G2 (7 cases obligatoires)", "Centre de Carmin (mi-parcours)"]:
		assert_true(out.contains(label), "étape absente : " + label)
	# Dresseurs et tables relus dans data/ (même identifiant, même carte et terrain).
	assert_true(out.contains("route_11_engineer_victor : Ingénieur Victor, IA random"),
		out.right(2000))
	assert_true(out.contains("Caninos N18 (Morsure, Groz'Yeux, Flammèche)"), "sans Hurlement")
	assert_true(out.contains("digletts_cave_rubble [rubble"), out.right(2000))
	assert_true(out.contains("Triopikeur 24–26 (5)"), "H-15")


func test_short_run_plays_the_cave_and_route_11() -> void:
	var run := _run(["--scenario", REAL, "--donnees", "--seeds", "10", "--equipe",
		"Carabaffe 22", "--variante", "soin après chaque Dresseur, puis Cave, attentif"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), out.right(2000))
	assert_false(out.contains("start impossible"), out.right(2000))
	assert_true(out.contains("niveaux à l'arrivée"), out.right(2000))


func _run(args: Array) -> Array:
	var output: Array = []
	var all: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s",
		TOOL, "--"]
	all.append_array(args)
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(all), output, true)
	return [code, "\n".join(PackedStringArray(output))]
