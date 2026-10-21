extends GutTest
## Départs de débogage de la rencontre fixe de QA (passe systèmes 2, T30, session S2G) :
## `s2_legendary` (gagner ou capturer) et `s2_legendary_weak` (perdre). Fichiers valides, Route 1
## devant le Pokémon de QA (une case au nord du point d'apparition), présent seulement avec le
## drapeau de QA et tant que la rencontre n'est pas consommée ; scène de QA chargée par les vraies
## données (rencontre fixe, intro « legendary », espèce connue). Retirés à la clôture (S2Z).

const TOOL_STARTS := "res://tools/debug_start/"
const STARTS: Array[String] = ["s2_legendary", "s2_legendary_weak"]
const ACTOR := &"qa_s2_legendary"
const QA_FLAG := &"qa_s2_legendary"
const DONE := &"qa_s2_legendary_done"

var _data: PokemonData
var _items: ItemLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func test_starts_face_the_qa_pokemon_on_route_1() -> void:
	for name: String in STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file(TOOL_STARTS + name + ".json", _data, _items),
			"%s : %s" % [name, "\n".join(start.get_errors())])
		assert_eq([start.map, start.spawn, start.facing],
			[&"route_1", &"from_pallet_w", Vector2i.UP], name)
		assert_true(start.flags.has(QA_FLAG), name)
		assert_false(start.flags.has(DONE), name)
		var map := (load(MapCatalog.scene_path(start.map)) as PackedScene).instantiate() \
			as GameMap
		add_child_autofree(map)
		var flags := StoryFlags.new()
		for flag: StringName in start.flags:
			flags.set_flag(flag)
		map.refresh_npcs(flags)
		var npc := map.get_npc(ACTOR)
		assert_not_null(npc, "%s : Pokémon de QA présent" % name)
		if npc != null:
			assert_eq(npc.get_spec().cell, map.get_spawn_cell(start.spawn) + Vector2i.UP,
				"%s : juste devant le joueur" % name)


func test_the_qa_pokemon_needs_the_qa_flag_and_leaves_when_consumed() -> void:
	var roster := NpcRoster.load_for_map(&"route_1")
	assert_eq(roster.get_errors().size(), 0, str(roster.get_errors()))
	var present := func(flags: StoryFlags) -> bool:
		return roster.get_present(flags).any(func(s: NpcSpec) -> bool: return s.id == ACTOR)
	assert_false(present.call(null), "absent d'une nouvelle partie")
	var flags := StoryFlags.new()
	flags.set_flag(QA_FLAG)
	assert_true(present.call(flags))
	flags.set_flag(DONE)
	assert_false(present.call(flags), "caché quand la rencontre est consommée")


func test_the_qa_scene_is_a_legendary_static_encounter() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), str(library.get_errors()))
	assert_true(library.check_species(_data), str(library.get_errors()))
	var cutscene := library.get_cutscene(&"qa_s2_legendary")
	assert_not_null(cutscene)
	var battle: CutsceneStep = null
	for step: CutsceneStep in cutscene.variants[0].steps:
		if step.kind == CutsceneStep.Kind.WILD_BATTLE:
			battle = step
	assert_not_null(battle)
	assert_eq(battle.intro, CutsceneStep.INTRO_LEGENDARY)
	assert_eq(battle.actor, ACTOR)
	assert_eq(battle.static_encounter.done_flag, DONE)
	assert_eq(battle.static_encounter.caught_flag, &"qa_s2_legendary_caught")
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir(), str(dialogues.get_errors()))
	assert_true(dialogues.has_dialogue(&"qa_s2_legendary"))
