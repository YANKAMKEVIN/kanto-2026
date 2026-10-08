extends GutTest
## `tools/simulate_brock.gd -- --preparation` (jalon 10, mesure de la préparation contre Pierre
## après Q-6) : l'outil tourne sans erreur dans un processus à part (une graine) et décrit les
## équipes préparées comme en jeu (évolutions niveau par niveau, capacités apprises, Férosinge
## à la place du Rattata). Les pourcentages ne sont pas vérifiés (information pour Kevin).

const TOOL := "res://tools/simulate_brock.gd"

var _output: String = ""
var _exit_code: int = -1


func before_all() -> void:
	var output: Array = []
	_exit_code = OS.execute(OS.get_executable_path(), ["--headless", "--path",
		ProjectSettings.globalize_path("res://"), "-s", TOOL, "--", "--preparation",
		"--seeds", "1"], output, true)
	_output = "\n".join(PackedStringArray(output))


func test_tool_runs_without_error() -> void:
	assert_eq(_exit_code, 0, _output.right(2000))
	assert_false(_output.contains("SCRIPT ERROR"), "erreur de script dans l'outil")
	assert_true(_output.contains("=== Résumé : % de victoires contre Pierre"), "résumé absent")


func test_trained_team_evolves_and_learns_like_in_game() -> void:
	var line := _team_line("S14 R13 P12")
	assert_true(line.contains("Papilusion N12 (Charge, Sécrétion, Armure, Choc Mental)"), line)
	assert_true(line.contains("Roucool N13 (Tornade, Jet de Sable, Vive-Attaque)"), line)
	assert_true(line.contains("Salamèche N14 (Griffe, Rugissement, Flammèche)"), line)
	var evolved := _team_line("S16 R14")
	assert_true(evolved.contains("Reptincel N16 (Griffe, Rugissement, Flammèche, Groz'Yeux)"),
		evolved)


func test_mankey_takes_the_rattata_slot() -> void:
	var line := _team_line("tel quel + F15")
	assert_true(line.contains("Roucool N9 (Tornade, Jet de Sable), Férosinge N15 (Griffe, "
		+ "Groz'Yeux, Poing Karaté), Nidoran♂ N3"), line)
	assert_false(line.contains("Rattata"), line)
	assert_false(_team_line("tel quel + F14").contains("Poing Karaté"), "Poing Karaté au N15")


## Ligne « --- <équipe> : … » du rapport.
func _team_line(team: String) -> String:
	for line: String in _output.split("\n"):
		if line.begins_with("--- %s : " % team):
			return line
	return ""
