extends GutTest
## Chapitre Johto (JOH0, jalon-joh0.md §2.6) : variantes de dialogue datées (« if_period »,
## « if_weekday ») : lecture, refus, choix selon le moment et le jour fournis par
## [member DialogueRunner.time_source] ; sans heure (Kanto), une variante datée ne s'applique
## pas ; PNJ datés ([NpcSpec] : « if_period », « if_weekday », [method NpcSpec.is_present]).

const SAGE := {
	"sage": {
		"speaker": "Sage",
		"variants": [
			{"if_period": "night", "pages": ["La nuit, les cloches se taisent."]},
			{"if_period": ["morning", "day"], "if_weekday": ["saturday", "sunday"],
				"pages": ["Le week-end, la tour ouvre à midi."]},
			{"if_weekday": "monday", "pages": ["Lundi : jour de ménage."]},
			{"pages": ["Bienvenue à Rosalia."]},
		],
	},
}


func _library(data: Dictionary) -> DialogueLibrary:
	var library := DialogueLibrary.new()
	assert_true(library.add_from_dict(data, "test"), str(library.get_errors()))
	return library


func _picked(library: DialogueLibrary, period: StringName, weekday: StringName) -> String:
	var variant := library.get_dialogue(&"sage").pick(StoryFlags.new(), null, 0, Callable(),
		Callable(), Callable(), period, weekday)
	return variant.pages[0].text if variant != null else ""


func test_dated_variants_are_read() -> void:
	var library := _library(SAGE)
	var variants := library.get_dialogue(&"sage").variants
	assert_eq(variants[0].if_periods, [&"night"] as Array[StringName])
	assert_eq(variants[1].if_periods, [&"morning", &"day"] as Array[StringName])
	assert_eq(variants[1].if_weekdays, [&"saturday", &"sunday"] as Array[StringName])
	assert_eq(variants[2].if_weekdays, [&"monday"] as Array[StringName])
	assert_true(variants[3].if_periods.is_empty() and variants[3].if_weekdays.is_empty())


func test_the_first_matching_variant_follows_period_then_weekday() -> void:
	var library := _library(SAGE)
	assert_eq(_picked(library, &"night", &"tuesday"), "La nuit, les cloches se taisent.")
	assert_eq(_picked(library, &"night", &"monday"), "La nuit, les cloches se taisent.",
		"la première variante qui s'applique gagne")
	assert_eq(_picked(library, &"day", &"saturday"), "Le week-end, la tour ouvre à midi.")
	assert_eq(_picked(library, &"morning", &"sunday"), "Le week-end, la tour ouvre à midi.")
	assert_eq(_picked(library, &"day", &"monday"), "Lundi : jour de ménage.")
	assert_eq(_picked(library, &"day", &"tuesday"), "Bienvenue à Rosalia.")


func test_without_an_hour_no_dated_variant_applies() -> void:
	var library := _library(SAGE)
	assert_eq(_picked(library, &"", &""), "Bienvenue à Rosalia.", "Kanto : pas d'heure")
	var variant := library.get_dialogue(&"sage").pick(StoryFlags.new())
	assert_eq(variant.pages[0].text, "Bienvenue à Rosalia.", "les appels d'avant le JOH0")
	assert_false(variant.if_periods.size() > 0)
	var night := library.get_dialogue(&"sage").variants[0]
	assert_false(night.matches_time(&"", &"monday"))
	assert_true(night.matches_time(&"night", &""), "le jour n'est pas exigé sans « if_weekday »")


func test_invalid_moments_are_refused() -> void:
	var bad := [
		{"x": {"pages": ["a"], "if_period": "dusk"}},
		{"x": {"pages": ["a"], "if_period": []}},
		{"x": {"pages": ["a"], "if_period": ["day", "day"]}},
		{"x": {"pages": ["a"], "if_weekday": "funday"}},
		{"x": {"pages": ["a"], "if_weekday": 3}},
	]
	for data: Dictionary in bad:
		var library := DialogueLibrary.new()
		assert_false(library.add_from_dict(data, "bad"), str(data))
	assert_push_error_count(bad.size())


func test_runner_time_source_feeds_the_pick() -> void:
	var runner := DialogueRunner.new()
	add_child_autofree(runner)
	assert_eq(runner._time(), [&"", &""] as Array[StringName], "sans source : pas d'heure")
	runner.time_source = func() -> Array: return [&"night", &"friday"]
	assert_eq(runner._time(), [&"night", &"friday"] as Array[StringName])
	runner.time_source = func() -> Array: return ["day"]
	assert_eq(runner._time(), [&"", &""] as Array[StringName], "forme inattendue : pas d'heure")


# --- PNJ datés -------------------------------------------------------------------------------------

func test_dated_npcs_are_present_only_at_their_moment() -> void:
	var roster := NpcRoster.new()
	assert_true(roster.add_from_dict({
		"owl_fan": {"cell": [3, 4], "sprite": "youngster", "if_period": "night"},
		"monday_sister": {"cell": [5, 4], "sprite": "lass", "if_weekday": ["monday"],
			"if_period": ["morning", "day"]},
		"always": {"cell": [7, 4], "sprite": "mom"},
	}, "test"), str(roster.get_errors()))
	var owl := roster.get_spec(&"owl_fan")
	assert_true(owl.is_conditional())
	assert_false(owl.is_present(null), "sans heure : absent")
	assert_false(owl.is_present(null, &"day"))
	assert_true(owl.is_present(null, &"night"))
	var sister := roster.get_spec(&"monday_sister")
	assert_true(sister.is_present(null, &"day", &"monday"))
	assert_false(sister.is_present(null, &"night", &"monday"))
	assert_false(sister.is_present(null, &"day", &"tuesday"))
	assert_false(sister.is_present(null, &"day"), "le jour est exigé")
	assert_true(roster.get_spec(&"always").is_present(null))
	assert_eq(roster.get_present(null).size(), 1, "Kanto : les PNJ datés manquent")
	assert_eq(roster.get_present(null, &"night", &"monday").size(), 2)
	assert_eq(roster.get_present(null, &"morning", &"monday").size(), 2)
	assert_eq(roster.get_present(null, &"day", &"sunday").size(), 1)


func test_invalid_npc_moments_are_refused() -> void:
	var roster := NpcRoster.new()
	assert_false(roster.add_from_dict({
		"a": {"cell": [1, 1], "sprite": "x", "if_period": "noon"},
		"b": {"cell": [1, 1], "sprite": "x", "if_weekday": []},
		"c": {"cell": [1, 1], "sprite": "x", "if_period": ["day", "day"]},
	}, "test"))
	assert_eq(roster.size(), 0)
	assert_push_error_count(3)
