extends GutTest
## Répliques du Conseil des Quatre et du rival quand le joueur est déjà Champion (demande de Kevin,
## 2026-11-21) : chaque texte de la Ligue a une variante « _champion », jouée seulement après le
## titre (`league_champion_defeated`) ; la première tentative garde les textes d'origine.

const CHAMPION := "league_champion_defeated"
const CALLS: Array[String] = ["league_lorelei_call", "league_bruno_call", "league_agatha_call",
	"league_lance_call", "rival_champion_call"]


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


func test_each_league_line_has_a_champion_twin_gated_by_the_title() -> void:
	var dialogues := _json("res://data/dialogues/league.json")
	var cutscenes := _json("res://data/cutscenes/league.json")
	var twins := 0
	for call_id: String in CALLS:
		for variant: Dictionary in cutscenes[call_id]["variants"]:
			var by_key := {}
			for step: Dictionary in variant["steps"]:
				if step.has("dialogue"):
					by_key[step["dialogue"]] = step
			for key: String in by_key:
				if key.ends_with("_champion"):
					continue
				var twin_key := key + "_champion"
				assert_true(by_key.has(twin_key), "%s : variante %s" % [call_id, twin_key])
				assert_true(dialogues.has(twin_key), "texte %s présent" % twin_key)
				if not by_key.has(twin_key):
					continue
				var original: Dictionary = by_key[key]
				var twin: Dictionary = by_key[twin_key]
				assert_has(original.get("unless", []), CHAMPION, "%s : avant le titre" % key)
				assert_has(twin.get("if", []), CHAMPION, "%s : après le titre" % twin_key)
				assert_eq(original.get("if", []), twin.get("if", []).filter(
					func(f: String) -> bool: return f != CHAMPION), "%s : mêmes conditions" % key)
				twins += 1
	assert_eq(twins, 11, "4 × 2 répliques du Conseil + 3 du rival")
