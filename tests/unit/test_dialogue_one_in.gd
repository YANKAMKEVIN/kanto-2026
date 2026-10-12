extends GutTest
## Clé « one_in » d'une variante de dialogue (jalon-14.md §2.8 : « une fois sur trois » de
## Léo) : lecture, refus, et tirage de Dialogue.pick après les drapeaux.

const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const BILL := {
	"bill": {
		"speaker": "Léo",
		"variants": [
			{"one_in": 3, "pages": ["A", "Rare"]},
			{"unless": ["cerulean_rocket_beaten"], "pages": ["A", "Rocket"]},
			{"pages": ["A"]},
		],
	},
}


func _library(data: Dictionary) -> DialogueLibrary:
	var library := DialogueLibrary.new()
	library.add_from_dict(data, "test")
	return library


func _last_page(variant: DialogueVariant) -> String:
	return variant.pages.back().text


func test_one_in_is_read() -> void:
	var library := _library(BILL)
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	var variants := library.get_dialogue(&"bill").variants
	assert_eq(variants[0].one_in, 3)
	assert_true(variants[0].is_random())
	assert_eq(variants[1].one_in, 0, "par défaut : aucun tirage")
	assert_false(variants[1].is_random())


func test_invalid_one_in_is_refused() -> void:
	for value: Variant in [1, 0, -2, 2.5, "3", true]:
		var library := _library({"d": {"one_in": value, "pages": ["x"]}})
		assert_false(library.has_dialogue(&"d"), "refusé : %s" % [value])
		assert_string_contains(", ".join(library.get_errors()), "« one_in » doit être")
	assert_push_error_count(6)


func test_one_in_with_auto_is_refused() -> void:
	var library := _library({"d": {"auto": true, "one_in": 2, "pages": ["x"]}})
	assert_false(library.has_dialogue(&"d"))
	assert_push_error("« one_in » interdit avec « auto »")


func test_without_rng_a_random_variant_is_skipped() -> void:
	var bill := _library(BILL).get_dialogue(&"bill")
	assert_eq(_last_page(bill.pick(StoryFlags.new())), "Rocket")
	assert_eq(_last_page(bill.pick(null)), "Rocket")


func test_winning_draw_picks_the_random_variant() -> void:
	var bill := _library(BILL).get_dialogue(&"bill")
	var rng := ScriptedRng.new([1])
	assert_eq(_last_page(bill.pick(StoryFlags.new(), rng)), "Rare")
	assert_eq(rng.calls, 1, "un seul tirage")


func test_losing_draw_falls_through_to_the_next_variant() -> void:
	var bill := _library(BILL).get_dialogue(&"bill")
	var flags := StoryFlags.new()
	assert_eq(_last_page(bill.pick(flags, ScriptedRng.new([2]))), "Rocket")
	assert_eq(_last_page(bill.pick(flags, ScriptedRng.new([3]))), "Rocket")
	flags.set_flag(&"cerulean_rocket_beaten")
	assert_eq(_last_page(bill.pick(flags, ScriptedRng.new([3]))), "A")
	assert_push_error_count(0)


func test_flags_are_checked_before_the_draw() -> void:
	var library := _library({"d": {"variants": [
		{"if": ["bill_restored"], "one_in": 3, "pages": ["Rare"]},
		{"pages": ["Normal"]},
	]}})
	var rng := ScriptedRng.new([])
	var picked := library.get_dialogue(&"d").pick(StoryFlags.new(), rng)
	assert_eq(_last_page(picked), "Normal")
	assert_eq(rng.calls, 0, "aucun tirage quand les drapeaux ne s'appliquent pas")
	assert_push_error_count(0)


func test_draw_is_uniform_over_n() -> void:
	var bill := _library(BILL).get_dialogue(&"bill")
	var rng := GameRng.new(1234)
	var rare := 0
	for i: int in 3000:
		if _last_page(bill.pick(StoryFlags.new(), rng)) == "Rare":
			rare += 1
	assert_between(rare, 850, 1150, "≈ 1 sur 3 (%d / 3000)" % rare)
