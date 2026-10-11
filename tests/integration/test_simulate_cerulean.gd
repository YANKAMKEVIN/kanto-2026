extends GutTest
## Scénario d'équilibrage du jalon 13 (T9) joué par `tools/simulate_mt_moon.gd` : le vrai
## scénario se valide (espèces du J12 et du J13 absentes = étapes sautées, code 3 ; code 0 une
## fois les données complètes) ; le starter par équipe choisit l'équipe du rival
## (« team_by_starter ») ; les groupes d'étapes (« optional » nommé) sont joués seulement si la
## variante les demande. Le vrai passage (pourcentages) est au T20 : information pour Kevin.

const TOOL := "res://tools/simulate_mt_moon.gd"
const REAL := "res://tools/sim/cerulean_scenario.json"
const GROUPS := "res://tests/fixtures/sim/cerulean_groups.json"
const NO_STARTER := "res://tests/fixtures/sim/cerulean_no_starter.json"
const EXIT_OK := 0
const EXIT_ERROR := 1
const EXIT_SKIPPED := 3


func test_real_scenario_is_valid() -> void:
	var run := _run(["--scenario", REAL, "--valider"])
	var out: String = run[1]
	assert_true(run[0] in [EXIT_OK, EXIT_SKIPPED], out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_false(out.contains("=== Scénario invalide"), out.right(2000))
	assert_false(out.contains("=== Simulation"), "--valider ne simule rien")
	assert_true(out.contains("=== Équilibrage de la Route 4, d'Azuria"), "titre absent")
	# Parcours complet : rival, Ondine, pont et recruteur avant et après Ondine.
	for label: String in ["Route 4 : H2 (4 cases)", "Rival n° 3 (Route 24)",
			"Ondine (Arène d'Azuria)", "Recruteur Rocket (avant Ondine)",
			"Recruteur Rocket (après Ondine)", "Route 24 nord : herbes (40 cases)"]:
		assert_true(out.contains(label), "étape absente : " + label)
	# Les deux familles de variantes.
	assert_true(out.contains("directe, attentif, Centre :"), out.right(2000))
	assert_true(out.contains("avec Route 24 nord, attentif, Centre :"), out.right(2000))


## Le rival du scénario est complet (ses espèces existent) : une équipe par starter.
func test_real_rival_has_one_team_per_starter() -> void:
	var out: String = _run(["--scenario", REAL, "--valider"])[1]
	if out.contains("SAUTÉ Dresseur « rival_cerulean »"):
		fail_test("rival sauté : " + out.right(2000))
		return
	for starter: String in ["Bulbizarre", "Salamèche", "Carapuce"]:
		assert_true(out.contains("contre %s : Roucoups N18" % starter), starter)


func test_groups_and_team_starter() -> void:
	var run := _run(["--scenario", GROUPS])
	var out: String = run[1]
	assert_eq(run[0], EXIT_OK, out.right(2000))
	assert_false(out.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(out.contains("=== Fixture des groupes d'étapes (jalon 13 T9) ==="), out)
	assert_true(out.contains("contre Salamèche : Aspicot N3"), out)
	assert_true(out.contains("Étape du groupe B : t9_trainer [b]"), out)
	assert_true(out.contains("Étape détour : t9_trainer [détour]"), out)
	var report := out.substr(out.find("=== Simulation"))
	assert_true(report.contains("--- Équipe Salamèche | groupe A seul"), out)
	assert_true(report.contains("Rival à team_by_starter"), out)
	assert_true(report.contains("Étape du groupe A"), out)
	assert_false(report.contains("Étape du groupe B"), "groupe non demandé joué")
	assert_false(report.contains("Étape détour"), "détour non demandé joué")


func test_bad_groups_and_missing_starter_are_refused() -> void:
	var run := _run(["--scenario", NO_STARTER, "--valider"])
	var out: String = run[1]
	assert_eq(run[0], EXIT_ERROR, out.right(2000))
	assert_true(out.contains("« optional » vaut true, false ou un nom de groupe"), out)
	assert_true(out.contains("« optional » vaut true, false ou une liste de groupes"), out)
	assert_true(out.contains("équipe « Sans starter » : « starter » requis"), out)


## [code de sortie, sortie] de l'outil lancé avec [param args].
func _run(args: Array) -> Array:
	var output: Array = []
	var all: Array = ["--headless", "--path", ProjectSettings.globalize_path("res://"), "-s",
		TOOL, "--"]
	all.append_array(args)
	var code := OS.execute(OS.get_executable_path(), PackedStringArray(all), output, true)
	return [code, "\n".join(PackedStringArray(output))]
