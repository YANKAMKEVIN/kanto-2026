extends GutTest
## [CutsceneVariant] et [Cutscene] selon le Sac (jalon 21, `jalon-21.md` §2.3) :
## « if_items » / « unless_items », même sémantique que les variantes de dialogue du J20.

const SCOPE := &"silph_scope"
const FLUTE := &"poke_flute"


func _variant(if_items: Array[StringName], unless_items: Array[StringName],
		if_flags: Array[StringName] = []) -> CutsceneVariant:
	var variant := CutsceneVariant.new()
	variant.if_items = if_items
	variant.unless_items = unless_items
	variant.if_flags = if_flags
	return variant


func _bag(items: Array[StringName]) -> Bag:
	var bag := Bag.new()
	for id: StringName in items:
		bag.add(id, 1)
	return bag


func test_if_items_needs_every_item() -> void:
	var variant := _variant([SCOPE, FLUTE], [])
	assert_true(variant.matches(StoryFlags.new(), _bag([SCOPE, FLUTE])))
	assert_false(variant.matches(StoryFlags.new(), _bag([SCOPE])))
	assert_false(variant.matches(StoryFlags.new(), _bag([])))


func test_unless_items_needs_none() -> void:
	var variant := _variant([], [SCOPE])
	assert_true(variant.matches(StoryFlags.new(), _bag([FLUTE])))
	assert_false(variant.matches(StoryFlags.new(), _bag([SCOPE])))


func test_without_a_bag() -> void:
	assert_false(_variant([SCOPE], []).matches(StoryFlags.new()), "objet exigé : faux")
	assert_true(_variant([], [SCOPE]).matches(StoryFlags.new()), "objet interdit : vrai")
	assert_true(_variant([], []).matches(StoryFlags.new()), "sans condition : vrai")
	assert_false(_variant([SCOPE], []).matches(null), "sans drapeaux ni Sac")
	assert_true(_variant([], [SCOPE]).matches(null))


func test_flags_and_items_both_count() -> void:
	var variant := _variant([SCOPE], [], [&"tower"])
	var flags := StoryFlags.new()
	assert_false(variant.matches(flags, _bag([SCOPE])), "drapeau manquant")
	flags.set_flag(&"tower")
	assert_true(variant.matches(flags, _bag([SCOPE])))
	assert_false(variant.matches(flags, _bag([])))


func test_cutscene_pick_uses_the_bag() -> void:
	var cutscene := Cutscene.new()
	var revealed := _variant([SCOPE], [])
	var ghost := _variant([], [])
	cutscene.variants = [revealed, ghost] as Array[CutsceneVariant]
	assert_same(cutscene.pick(StoryFlags.new(), _bag([SCOPE])), revealed)
	assert_same(cutscene.pick(StoryFlags.new(), _bag([])), ghost)
	assert_same(cutscene.pick(StoryFlags.new()), ghost, "sans Sac : la suivante")
	assert_true(cutscene.matches(StoryFlags.new(), _bag([])))
