extends GutTest
## Scénario d'équilibrage du jalon 14 (T21) joué par `tools/simulate_mt_moon.gd` : le vrai
## scénario se valide avec les données (`--donnees`, rien de sauté) ; une courte simulation se
## joue sans erreur et compte à part les fuites d'Abra (Téléport : « fuites adverses », et non
## « non terminés »). Les pourcentages sont une information pour Kevin (`jalon-14.md` T21).

const TOOL := "res://tools/simulate_mt_moon.gd"
const REAL := "res://tools/sim/route_25_scenario.json"
const EXIT_OK := 0


func test_real_scenario_is_valid_with_data() -> void:
	var run := _run(["--scenario", REAL, "--donnees", "--valider"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(out.contains("=== Équilibrage de la Route 25 et du Rocket d'Azuria"),
		"titre absent")
	for label: String in ["D1 Gamin Jules (inévitable)", "D2 Montagnard Gaston (inévitable)",
			"Route 25 : H3 (4 cases obligatoires)", "D6 Gamin Yanis",
			"Sbire Rocket (Azuria, avant Léo)", "Sbire Rocket (Azuria, après Léo)"]:
		assert_true(out.contains(label), "étape absente : " + label)
	# Dresseurs relus dans data/ (même identifiant).
	assert_true(out.contains("cerulean_rocket : Sbire Rocket, IA smart, 510"), out.right(2000))
	assert_true(out.contains("route_25_hiker_gaston : Montagnard Gaston, IA random, 525"),
		out.right(2000))


func test_short_run_counts_abra_teleport_apart() -> void:
	var run := _run(["--scenario", REAL, "--donnees", "--seeds", "20", "--equipe",
		"Carabaffe 21", "--variante", "tous les Dresseurs, attentif"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), out.right(2000))
	assert_false(out.contains("start impossible"), out.right(2000))
	assert_true(out.contains("fuites adverses"), out.right(2000))
	assert_false(out.contains("non terminés"), out.right(2000))


func _run(args: Array) -> Array:
	var output: Array = []
	var all: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s",
		TOOL, "--"]
	all.append_array(args)
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(all), output, true)
	return [code, "\n".join(PackedStringArray(output))]
