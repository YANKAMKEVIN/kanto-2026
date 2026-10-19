extends GutTest
## Condition « au moins N espèces capturées » et jetons {caught} / {caught_missing} (jalon 17,
## T4 ; jalon-17.md §2.5, dossier 20 §8 et §16 T-1 à T-4) : lecture des clés
## « if_caught_at_least » / « unless_caught_at_least », refus, choix de la variante selon le
## compte (seuil exact), combinaison avec les drapeaux, valeurs des jetons.

## Même forme que le futur dialogue de l'assistant (jalon-17.md §2.6, T8), textes du §16.
const ASSISTANT := {
	"assistant": {
		"speaker": "Assistant",
		"variants": [
			{"if": ["got_hm05"], "pages": ["Avec Flash, plus besoin d'avancer à tâtons."]},
			{"if_caught_at_least": 10, "pages": ["Ton Pokédex compte {caught} espèces !"]},
			{"unless": ["hm05_assistant_met"], "unless_caught_at_least": 10,
				"set": ["hm05_assistant_met"],
				"pages": ["Je suis un assistant du Professeur Chen.",
					"Ton Pokédex en compte {caught}. Reviens me voir !"]},
			{"unless_caught_at_least": 2,
				"pages": ["Ton Pokédex compte 1 espèce capturée.",
					"Encore {caught_missing}, et c'est à toi."]},
			{"pages": ["Ton Pokédex compte {caught} espèces capturées.",
				"Encore {caught_missing}, et c'est à toi."]},
		],
	},
}


func _library(data: Dictionary) -> DialogueLibrary:
	var library := DialogueLibrary.new()
	library.add_from_dict(data, "test")
	return library


func _flags(names: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


func _assistant() -> Dialogue:
	var library := _library(ASSISTANT)
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	return library.get_dialogue(&"assistant")


## Index de la variante choisie (−1 : aucune).
func _picked(dialogue: Dialogue, flags: StoryFlags, caught: int) -> int:
	return dialogue.variants.find(dialogue.pick(flags, null, caught))


# --- Lecture --------------------------------------------------------------------------

func test_keys_are_read() -> void:
	var variants := _assistant().variants
	assert_eq(variants[1].caught_at_least, 10)
	assert_eq(variants[1].caught_below, 0)
	assert_eq(variants[2].caught_below, 10)
	assert_eq(variants[3].caught_below, 2)
	assert_eq(variants[4].caught_at_least, 0, "par défaut : sans condition")
	assert_eq(variants[4].caught_below, 0)


func test_keys_without_variants_list() -> void:
	var library := _library({"d": {"if_caught_at_least": 3, "pages": ["x"]}})
	assert_eq(library.get_dialogue(&"d").variants[0].caught_at_least, 3)


func test_invalid_values_are_refused() -> void:
	for key: String in ["if_caught_at_least", "unless_caught_at_least"]:
		for value: Variant in [0, -1, 2.5, "10", true, null]:
			var library := _library({"d": {key: value, "pages": ["x"]}})
			assert_false(library.has_dialogue(&"d"), "%s refusé : %s" % [key, value])
			assert_string_contains(", ".join(library.get_errors()), "doit être un entier ≥ 1")
	assert_push_error_count(12)


func test_empty_range_is_refused() -> void:
	for pair: Array in [[10, 10], [10, 2]]:
		var library := _library({"d": {"if_caught_at_least": pair[0],
			"unless_caught_at_least": pair[1], "pages": ["x"]}})
		assert_false(library.has_dialogue(&"d"), "plage vide : %s" % [pair])
		assert_string_contains(", ".join(library.get_errors()),
			"doit être < « unless_caught_at_least »")
	assert_push_error_count(2)
	var ok := _library({"d": {"if_caught_at_least": 5, "unless_caught_at_least": 6,
		"pages": ["x"]}})
	assert_true(ok.has_dialogue(&"d"), "plage d'une seule valeur permise")


# --- Choix de la variante -------------------------------------------------------------

func test_variant_matches_threshold_exactly() -> void:
	var variant := DialogueVariant.new()
	variant.caught_at_least = 10
	assert_false(variant.matches(_flags(), 9))
	assert_true(variant.matches(_flags(), 10))
	assert_true(variant.matches(_flags(), 11))
	assert_false(variant.matches(null, 9), "sans drapeaux, le compte compte toujours")
	assert_true(variant.matches(null, 10))
	variant.caught_at_least = 0
	variant.caught_below = 10
	assert_true(variant.matches(_flags(), 9))
	assert_false(variant.matches(_flags(), 10))
	assert_false(variant.matches(_flags(), 11))


func test_without_condition_any_count_matches() -> void:
	var variant := DialogueVariant.new()
	for caught: int in [0, 1, 10, 151]:
		assert_true(variant.matches(_flags(), caught))
	assert_true(variant.matches(_flags()), "compte absent : 0")


func test_default_count_is_zero() -> void:
	var dialogue := _assistant()
	assert_eq(dialogue.variants.find(dialogue.pick(_flags())), 2,
		"sans compte fourni (anciens appels) : 0, première visite")


func test_assistant_first_visit_below_the_goal() -> void:
	var dialogue := _assistant()
	for caught: int in [1, 2, 9]:
		assert_eq(_picked(dialogue, _flags(), caught), 2, "T-1 à %d espèces" % caught)


func test_assistant_next_visits_below_the_goal() -> void:
	var dialogue := _assistant()
	var met := _flags([&"hm05_assistant_met"])
	assert_eq(_picked(dialogue, met, 1), 3, "T-2 accordé au singulier")
	for caught: int in [2, 5, 9]:
		assert_eq(_picked(dialogue, met, caught), 4, "T-2 à %d espèces" % caught)


func test_assistant_gives_at_ten_or_more_met_or_not() -> void:
	var dialogue := _assistant()
	for flags: StoryFlags in [_flags(), _flags([&"hm05_assistant_met"])]:
		for caught: int in [10, 11, 151]:
			assert_eq(_picked(dialogue, flags, caught), 1, "T-3 à %d espèces" % caught)


func test_assistant_after_the_gift_ignores_the_count() -> void:
	var dialogue := _assistant()
	for caught: int in [1, 9, 10, 40]:
		assert_eq(_picked(dialogue, _flags([&"got_hm05", &"hm05_assistant_met"]), caught), 0,
			"T-4 à %d espèces" % caught)


# --- Jetons ---------------------------------------------------------------------------

func test_caught_tokens_are_known() -> void:
	assert_true(DialogueTokens.KNOWN.has(&"caught"))
	assert_true(DialogueTokens.KNOWN.has(&"caught_missing"))
	assert_false(DialogueTokens.CONTEXT.has(&"caught"), "pas un jeton de contexte")
	assert_eq(DialogueTokens.CAUGHT_GOAL, 10, "dossier 20 §8, H-9")


func test_caught_values() -> void:
	assert_eq(DialogueTokens.caught_values(1),
		{&"caught": "1", &"caught_missing": "9"} as Dictionary[StringName, String])
	assert_eq(DialogueTokens.caught_values(9),
		{&"caught": "9", &"caught_missing": "1"} as Dictionary[StringName, String])
	assert_eq(DialogueTokens.caught_values(10),
		{&"caught": "10"} as Dictionary[StringName, String], "objectif atteint : pas de reste")
	assert_eq(DialogueTokens.caught_values(12),
		{&"caught": "12"} as Dictionary[StringName, String])


func test_missing_page_is_omitted_at_the_goal() -> void:
	var pages: Array[DialoguePage] = [DialoguePage.new("Ton Pokédex compte {caught} espèces."),
		DialoguePage.new("Encore {caught_missing}, et c'est à toi.")]
	var below := DialogueTokens.resolve_pages(pages, DialogueTokens.caught_values(7))
	assert_eq(below.map(func(p: DialoguePage) -> String: return p.text),
		["Ton Pokédex compte 7 espèces.", "Encore 3, et c'est à toi."])
	var reached := DialogueTokens.resolve_pages(pages, DialogueTokens.caught_values(10))
	assert_eq(reached.map(func(p: DialoguePage) -> String: return p.text),
		["Ton Pokédex compte 10 espèces."])
