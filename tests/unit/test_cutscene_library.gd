extends GutTest
## CutsceneLibrary, Cutscene, CutsceneVariant, CutsceneStep : format des fichiers de
## data/cutscenes/, validation, choix de la variante selon les drapeaux (jalon 3B §2.3).
## Jalon 4 (§3.6, §13) : alias d'acteurs « $nom », étapes hop, lean et despawn.
## Jalon 4B (§14.3) : étapes battle et give, conditions d'étape, copie d'une étape.

const FIXTURES := "res://tests/fixtures/cutscenes/"

var _library: CutsceneLibrary


func before_each() -> void:
	_library = CutsceneLibrary.new()


func _flags(names: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for name: StringName in names:
		flags.set_flag(name)
	return flags


## Ajoute une scène d'une seule étape ; renvoie l'étape (null si refusée).
func _one_step(step: Variant, id: String = "s") -> CutsceneStep:
	if not _library.add_from_dict({id: {"steps": [step]}}, "test"):
		return null
	return _library.get_cutscene(StringName(id)).variants[0].steps[0]


# --- Chargement ---------------------------------------------------------------------

func test_load_dir_reads_every_json_file() -> void:
	assert_true(_library.load_dir(FIXTURES))
	assert_eq(_library.get_errors().size(), 0, str(_library.get_errors()))
	assert_eq(_library.get_ids(), [&"route1_grass", &"walk_to_desk"] as Array[StringName])
	assert_eq(_library.size(), 2)
	assert_eq(_library.get_cutscene(&"route1_grass").source, FIXTURES + "prologue.json")
	assert_eq(_library.get_cutscene(&"route1_grass").id, &"route1_grass")


func test_missing_dir_or_file_is_an_error() -> void:
	assert_false(_library.load_dir("res://tests/fixtures/nowhere/"))
	assert_push_error("dossier introuvable")
	assert_false(_library.load_file(FIXTURES + "nothing.json"))
	assert_push_error("fichier introuvable")
	assert_null(_library.get_cutscene(&"nothing"))
	assert_false(_library.has_cutscene(&"nothing"))


func test_invalid_json_file_reports_the_line() -> void:
	var path := "user://test_cutscene_invalid.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{\n\t\"a\": {\n\t\t\"steps\": [{ \"wait\": 1 }\n\t}\n}\n")
	file.close()
	assert_false(_library.load_file(path))
	assert_push_error("ligne 4")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_not_an_object_file_is_an_error() -> void:
	var path := "user://test_cutscene_list.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("[1, 2]")
	file.close()
	assert_false(_library.load_file(path))
	assert_push_error("un objet { identifiant: scène }")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# --- Contenu d'une scène ---------------------------------------------------------------

func test_every_step_type_of_the_prologue() -> void:
	_library.load_dir(FIXTURES)
	var variant := _library.get_cutscene(&"route1_grass").variants[0]
	var kinds: Array[CutsceneStep.Kind] = []
	for step: CutsceneStep in variant.steps:
		kinds.append(step.kind)
	var K := CutsceneStep.Kind
	assert_eq(kinds, [K.WAIT, K.DIALOGUE, K.FACE, K.SPAWN, K.MOVE, K.FACE, K.DIALOGUE,
		K.SET_FLAGS, K.MOVE, K.CHANGE_MAP, K.MOVE, K.FACE, K.DIALOGUE, K.SET_FLAGS]
		as Array[CutsceneStep.Kind])
	var steps := variant.steps
	assert_almost_eq(steps[0].seconds, 0.4, 0.0001)
	assert_eq(steps[1].dialogue_id, &"oak_route1_call")
	assert_eq(steps[2].actor, &"player")
	assert_eq(steps[2].target, &"down")
	assert_eq(steps[5].target, &"player")
	assert_eq(steps[7].flags, [&"oak_met"] as Array[StringName])


func test_spawn_step_carries_an_npc_spec() -> void:
	_library.load_dir(FIXTURES)
	var spawn := _library.get_cutscene(&"route1_grass").variants[0].steps[3]
	assert_eq(spawn.actor, &"oak")
	assert_not_null(spawn.spec)
	assert_eq(spawn.spec.id, &"oak")
	assert_eq(spawn.spec.cell, Vector2i(24, 13))
	assert_eq(spawn.spec.facing, Vector2i.UP)
	assert_eq(spawn.spec.sprite, &"oak")
	assert_false(spawn.spec.is_interactive())
	assert_true(spawn.spec.is_present(null), "pas de condition dans une étape")


func test_move_steps() -> void:
	_library.load_dir(FIXTURES)
	var steps := _library.get_cutscene(&"route1_grass").variants[0].steps
	var run: CutsceneStep = steps[4]
	assert_eq(run.actor, &"oak")
	assert_true(run.run)
	assert_true(run.has_destination())
	assert_eq(run.cell, CutsceneStep.NO_CELL)
	assert_eq(run.near, &"player")
	assert_eq(run.offsets, [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]
		as Array[Vector2i])
	assert_true(run.path.is_empty())
	var follow: CutsceneStep = steps[8]
	assert_false(follow.run, "marche par défaut")
	assert_false(follow.has_destination())
	assert_eq(follow.follower, &"player")
	assert_eq(follow.path, [Vector2i.DOWN, Vector2i.DOWN, Vector2i.DOWN] as Array[Vector2i])
	var desk := _library.get_cutscene(&"walk_to_desk").variants[0].steps[0]
	assert_true(desk.has_destination())
	assert_eq(desk.cell, Vector2i(8, 4))
	assert_eq(desk.near, &"")


func test_change_map_step() -> void:
	_library.load_dir(FIXTURES)
	var lab := _library.get_cutscene(&"route1_grass").variants[0].steps[9]
	assert_eq(lab.map_id, &"oak_lab")
	assert_eq(lab.spawn, &"entrance")
	assert_eq(lab.facing, Vector2i.UP)
	var town := _library.get_cutscene(&"walk_to_desk").variants[0].steps[1]
	assert_eq(town.facing, Vector2i.ZERO, "sans facing : garder l'orientation")


func test_kind_names() -> void:
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.WAIT), &"wait")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.SET_FLAGS), &"set")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.CHANGE_MAP), &"change_map")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.HOP), &"hop")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.LEAN), &"lean")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.DESPAWN), &"despawn")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.BATTLE), &"battle")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.GIVE), &"give")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size())
	assert_eq(CutsceneStep.Kind.DESPAWN, 9, "les étapes du 4A gardent leur valeur")
	assert_eq(CutsceneStep.Kind.CHANGE_MAP, 6, "les étapes du 3B gardent leur valeur")


# --- Variantes et drapeaux --------------------------------------------------------------

func test_first_matching_variant_wins() -> void:
	_library.load_dir(FIXTURES)
	var grass := _library.get_cutscene(&"route1_grass")
	assert_eq(grass.pick(_flags()), grass.variants[0], "d'abord l'interception de Chen")
	assert_eq(grass.pick(null), grass.variants[0])
	assert_eq(grass.pick(_flags([&"oak_met"])), grass.variants[1], "puis la pensée")
	assert_null(grass.pick(_flags([&"oak_met", &"starter_chosen"])), "désarmé avec un starter")
	assert_false(grass.matches(_flags([&"oak_met", &"starter_chosen"])))
	assert_true(grass.matches(_flags([&"oak_met"])))


func test_if_condition_requires_all_flags() -> void:
	_library.load_dir(FIXTURES)
	var desk := _library.get_cutscene(&"walk_to_desk")
	assert_false(desk.matches(null))
	assert_false(desk.matches(_flags()))
	assert_true(desk.matches(_flags([&"oak_met"])))


func test_flags_and_dialogues_are_listed() -> void:
	_library.load_dir(FIXTURES)
	assert_eq(_library.get_condition_flags(), [&"oak_met", &"starter_chosen"]
		as Array[StringName])
	assert_eq(_library.get_set_flags(), [&"oak_lab_reunion", &"oak_met"] as Array[StringName])
	assert_eq(_library.get_dialogue_ids(), [&"oak_lab_reunion", &"oak_route1_call",
		&"oak_route1_warning", &"route1_grass_thought"] as Array[StringName])


# --- Validation -----------------------------------------------------------------------

func test_duplicate_id_across_files_is_rejected() -> void:
	_library.load_dir(FIXTURES)
	assert_false(_library.add_from_dict({"walk_to_desk": {"steps": [{"wait": 1}]}}, "b.json"))
	assert_push_error("déjà défini")
	assert_eq(_library.get_cutscene(&"walk_to_desk").source, FIXTURES + "short.json")


func test_scene_level_errors() -> void:
	var bad: Dictionary = {
		"not_object": "wait",
		"no_steps": {"unless": ["x"]},
		"empty_steps": {"steps": []},
		"empty_variants": {"variants": []},
		"typo": {"step": [{"wait": 1}]},
		"bad_flags": {"if": "oak_met", "steps": [{"wait": 1}]},
		"beside_variants": {"variants": [{"steps": [{"wait": 1}]}], "unless": ["x"]},
	}
	for id: String in bad:
		assert_false(_library.add_from_dict({id: bad[id]}, "test"), id)
		assert_false(_library.has_cutscene(StringName(id)), id)
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size() + 1, "une erreur par scène, deux pour « typo »")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["un objet est attendu", "« steps » doit être une liste non vide",
			"« variants » doit être une liste non vide", "clé inconnue « step »",
			"« if » doit être une liste", "doit être dans une variante"]:
		assert_string_contains(errors, expected)


func test_step_type_must_be_unique_and_known() -> void:
	assert_null(_one_step({"sleep": 1}, "a"))
	assert_null(_one_step({"wait": 1, "dialogue": "x"}, "b"))
	assert_null(_one_step("wait", "c"))
	assert_null(_one_step({"change_map": "oak_lab", "at": "entrance", "spawn": "oak"}, "d"))
	assert_eq(_library.size(), 0)
	assert_push_error_count(4)
	assert_string_contains(_library.get_errors()[0], "exactement un type")


func test_invalid_step_parameters() -> void:
	var bad: Array[Dictionary] = [
		{"wait": -1},
		{"wait": "long"},
		{"wait": 1, "to": "up"},
		{"dialogue": ""},
		{"dialogue": 3},
		{"face": "oak"},
		{"face": "oak", "to": ""},
		{"face": "", "to": "up"},
		{"set": []},
		{"set": "oak_met"},
		{"set": [""]},
		{"move": "oak"},
		{"move": "oak", "path": ["down"], "to": [1, 1]},
		{"move": "oak", "path": []},
		{"move": "oak", "path": ["south"]},
		{"move": "oak", "to": [1]},
		{"move": "oak", "to": "player"},
		{"move": "oak", "to": {"near": "player"}},
		{"move": "oak", "to": {"near": "player", "offsets": [[0, 0]]}},
		{"move": "oak", "to": {"near": "player", "offsets": [[1.5, 0]]}},
		{"move": "oak", "to": {"near": "", "offsets": [[1, 0]]}},
		{"move": "oak", "to": {"near": "player", "offsets": [[1, 0]], "first": true}},
		{"move": "oak", "path": ["down"], "run": "yes"},
		{"move": "oak", "path": ["down"], "follower": "oak"},
		{"move": "oak", "path": ["down"], "follower": ""},
		{"change_map": "oak_lab"},
		{"change_map": "", "at": "entrance"},
		{"change_map": "oak_lab", "at": "entrance", "facing": "north"},
		{"change_map": "oak_lab", "at": "entrance", "fade": false},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par étape")


func test_invalid_spawn_steps() -> void:
	var bad: Array[Dictionary] = [
		{"spawn": "oak", "cell": [24, 13]},
		{"spawn": "oak", "sprite": "oak"},
		{"spawn": "oak", "sprite": "oak", "cell": [24, 13], "facing": "north"},
		{"spawn": "oak", "sprite": "oak", "cell": [24, 13], "dialog": "oak"},
		{"spawn": "oak", "sprite": "oak", "cell": [24, 13], "if": ["oak_met"]},
		{"spawn": "player", "sprite": "oak", "cell": [24, 13]},
		{"spawn": "", "sprite": "oak", "cell": [24, 13]},
		{"spawn": "oak", "sprite": "oak", "at": [24, 13]},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "spawn_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size() + 1, "une par étape, deux pour « at » sans « cell »")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["« sprite » est obligatoire", "« cell » doit être",
			"« facing » vaut", "clé inconnue « dialog »", "conditions : variante",
			"réservé au joueur", "spawn : identifiant attendu", "clé inconnue « at »"]:
		assert_string_contains(errors, expected)


func test_spawn_accepts_optional_npc_keys() -> void:
	var step := _one_step({"spawn": "starter", "sprite": "bulbasaur", "cell": [10, 5],
		"dialogue": "observe_bulbasaur", "verb": "observe", "lift": 56})
	assert_not_null(step)
	assert_eq(step.spec.verb, Interaction.Kind.OBSERVE)
	assert_eq(step.spec.lift, 56)
	assert_eq(step.spec.dialogue, &"observe_bulbasaur")


func test_one_invalid_scene_does_not_discard_the_others() -> void:
	assert_false(_library.add_from_dict({
		"good": {"steps": [{"wait": 0.5}]},
		"bad": {"steps": [{"wait": 0.5}, {"move": "oak"}]},
	}, "test"))
	assert_push_error_count(1)
	assert_true(_library.has_cutscene(&"good"))
	assert_false(_library.has_cutscene(&"bad"), "écartée entière, pas seulement l'étape")
	assert_eq(_library.get_errors().size(), 1)


# --- Jalon 4 : alias, hop, lean, despawn ---------------------------------------------

func test_alias_form() -> void:
	for ref: StringName in [&"$player_starter", &"$a", &"$rival_starter", &"$_"]:
		assert_true(CutsceneStep.is_alias(ref), String(ref))
	for ref: StringName in [&"$", &"player", &"$Player", &"$player-starter", &"$starter1",
			&"$ a", &"player_starter", &"", &"$é"]:
		assert_false(CutsceneStep.is_alias(ref), String(ref))
	assert_eq(CutsceneStep.alias_name(&"$player_starter"), &"player_starter")
	assert_eq(CutsceneStep.alias_name(&"rival"), &"")
	assert_eq(CutsceneStep.alias_name(&"$Bad"), &"")


func test_aliases_are_accepted_wherever_an_actor_is_expected() -> void:
	assert_true(_library.add_from_dict({"choice": {"unless": ["rival_challenged"], "steps": [
		{"hop": "$mine", "to": {"near": "$mine", "offsets": [[0, 1]]}},
		{"face": "player", "to": "$mine"},
		{"face": "$mine", "to": "player"},
		{"lean": "$mine", "to": "player"},
		{"move": "rival", "to": {"near": "$theirs", "offsets": [[0, 1]]}},
		{"move": "$theirs", "path": ["down"]},
		{"move": "rival", "to": [8, 8], "follower": "$theirs"},
		{"face": "rival", "to": "$mine"},
		{"despawn": "$theirs"},
	]}}, "test"), str(_library.get_errors()))
	assert_eq(_library.get_errors().size(), 0)
	assert_eq(_library.get_aliases(&"choice"), [&"mine", &"theirs"] as Array[StringName])
	assert_eq(_library.get_cutscene(&"choice").get_aliases(),
		[&"mine", &"theirs"] as Array[StringName])
	var steps := _library.get_cutscene(&"choice").variants[0].steps
	assert_eq(steps[1].target, &"$mine", "le directeur résout l'alias au début de l'étape")
	assert_eq(steps[4].near, &"$theirs")
	assert_eq(steps[6].follower, &"$theirs")
	assert_eq(steps[6].get_aliases(), [&"theirs"] as Array[StringName])
	assert_eq(_library.get_aliases(&"nothing"), [] as Array[StringName])


func test_scenes_without_alias_list_none() -> void:
	_library.load_dir(FIXTURES)
	assert_eq(_library.get_aliases(&"route1_grass"), [] as Array[StringName])


func test_malformed_aliases_are_rejected_everywhere() -> void:
	var bad: Array[Dictionary] = [
		{"face": "$", "to": "player"},
		{"face": "player", "to": "$Starter"},
		{"move": "$a-b", "path": ["down"]},
		{"move": "rival", "to": {"near": "$1", "offsets": [[0, 1]]}},
		{"move": "rival", "path": ["down"], "follower": "$ x"},
		{"hop": "$", "to": [1, 1]},
		{"hop": "$a", "to": {"near": "$B", "offsets": [[0, 1]]}},
		{"lean": "$a", "to": "$b c"},
		{"despawn": "$9"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "alias_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par étape")
	for message: String in _library.get_errors():
		assert_string_contains(message, "alias mal formé")


func test_spawn_cannot_create_an_alias() -> void:
	assert_null(_one_step({"spawn": "$starter", "sprite": "bulbasaur", "cell": [10, 5]}))
	assert_push_error("pas un alias")


func test_hop_step() -> void:
	var near := _one_step({"hop": "$mine", "to": {"near": "player",
		"offsets": [[0, 1], [-1, 0]]}}, "a")
	assert_eq(near.kind, CutsceneStep.Kind.HOP)
	assert_eq(near.actor, &"$mine")
	assert_true(near.has_destination())
	assert_eq(near.near, &"player")
	assert_eq(near.offsets, [Vector2i(0, 1), Vector2i(-1, 0)] as Array[Vector2i])
	assert_eq(near.cell, CutsceneStep.NO_CELL)
	var cell := _one_step({"hop": "charmander", "to": [11, 6]}, "b")
	assert_eq(cell.actor, &"charmander")
	assert_eq(cell.cell, Vector2i(11, 6))
	assert_eq(cell.near, &"")
	assert_true(cell.path.is_empty())


func test_lean_and_despawn_steps() -> void:
	var lean := _one_step({"lean": "charmander", "to": "player"}, "a")
	assert_eq(lean.kind, CutsceneStep.Kind.LEAN)
	assert_eq(lean.actor, &"charmander")
	assert_eq(lean.target, &"player")
	var toward := _one_step({"lean": "$mine", "to": "down"}, "b")
	assert_eq(toward.target, &"down", "une direction, comme « face »")
	var despawn := _one_step({"despawn": "$theirs"}, "c")
	assert_eq(despawn.kind, CutsceneStep.Kind.DESPAWN)
	assert_eq(despawn.actor, &"$theirs")


func test_invalid_hop_lean_and_despawn_steps() -> void:
	var bad: Array[Dictionary] = [
		{"hop": "charmander"},
		{"hop": "player", "to": [1, 1]},
		{"hop": "", "to": [1, 1]},
		{"hop": "charmander", "to": [1]},
		{"hop": "charmander", "to": "player"},
		{"hop": "charmander", "to": {"near": "player"}},
		{"hop": "charmander", "path": ["down"]},
		{"hop": "charmander", "to": [1, 1], "run": true},
		{"hop": "charmander", "to": [1, 1], "style": "calm"},
		{"lean": "charmander"},
		{"lean": "player", "to": "charmander"},
		{"lean": "charmander", "to": ""},
		{"lean": "charmander", "to": "player", "back": false},
		{"despawn": "player"},
		{"despawn": ""},
		{"despawn": 3},
		{"despawn": "rival", "to": [7, 9]},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	# « hop » avec « path » : clé inconnue et « to » manquant (deux erreurs).
	assert_push_error_count(bad.size() + 1, "une erreur par étape, deux pour « path »")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["« to » est obligatoire", "réservé aux PNJ",
			"clé inconnue « style »", "clé inconnue « run »", "clé inconnue « back »",
			"despawn : identifiant attendu"]:
		assert_string_contains(errors, expected)


## Jalon 4 : « keep_facing » (le joueur recule sans se retourner) et « optional » (sauté sans
## erreur si aucune case « near » ne convient).
func test_move_keep_facing_and_optional() -> void:
	assert_true(_library.add_from_dict({"back": {"steps": [
		{"move": "player", "to": {"near": "player", "offsets": [[0, 1]]},
			"keep_facing": true, "optional": true},
	]}}, "t"), str(_library.get_errors()))
	var step := _library.get_cutscene(&"back").variants[0].steps[0]
	assert_true(step.keep_facing)
	assert_true(step.optional)
	var bad := CutsceneLibrary.new()
	assert_false(bad.add_from_dict({
		"a": {"steps": [{"move": "oak", "path": ["down"], "keep_facing": true}]},
		"b": {"steps": [{"move": "player", "path": ["down"], "optional": true}]},
		"c": {"steps": [{"move": "player", "path": ["down"], "keep_facing": 1}]},
	}, "t"))
	assert_push_error_count(3)
	var errors := "\n".join(bad.get_errors())
	assert_string_contains(errors, "ne vaut que pour « player »")
	assert_string_contains(errors, "exige une destination « near »")
	assert_string_contains(errors, "« keep_facing » vaut true ou false")


# --- Jalon 4B : battle, give, conditions d'étape (jalon-04.md §14.3) --------------------

func test_battle_step() -> void:
	var step := _one_step({"battle": "rival_lab", "player_pokemon": "$player_starter",
		"foe_pokemon": "$rival_starter", "win": ["rival_lab_won"],
		"lose": ["rival_lab_lost"]})
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.kind, CutsceneStep.Kind.BATTLE)
	assert_eq(CutsceneStep.kind_name(step.kind), &"battle")
	assert_eq(step.trainer_id, &"rival_lab")
	assert_eq(step.player_pokemon, &"$player_starter")
	assert_eq(step.foe_pokemon, &"$rival_starter")
	assert_eq(step.win_flags, [&"rival_lab_won"] as Array[StringName])
	assert_eq(step.lose_flags, [&"rival_lab_lost"] as Array[StringName])
	assert_eq(step.get_aliases(), [&"player_starter", &"rival_starter"] as Array[StringName])
	assert_eq(_library.get_trainer_ids(), [&"rival_lab"] as Array[StringName])
	assert_eq(_library.get_set_flags(), [&"rival_lab_lost", &"rival_lab_won"]
		as Array[StringName], "les drapeaux de l'issue sont levés par l'étape")


func test_battle_step_minimal_form() -> void:
	var step := _one_step({"battle": "youngster"})
	assert_not_null(step)
	assert_eq(step.player_pokemon, &"")
	assert_eq(step.foe_pokemon, &"")
	assert_true(step.win_flags.is_empty())
	assert_true(step.get_aliases().is_empty())


func test_outcome_flags() -> void:
	var step := _one_step({"battle": "rival_lab", "win": ["won", "done_a"],
		"lose": ["lost"]})
	assert_eq(step.outcome_flags(Battle.Outcome.WIN), [&"won", &"done_a"]
		as Array[StringName])
	assert_eq(step.outcome_flags(Battle.Outcome.LOSS), [&"lost"] as Array[StringName])
	assert_true(step.outcome_flags(Battle.Outcome.NONE).is_empty())
	step.outcome_flags(Battle.Outcome.WIN).append(&"extra")
	assert_eq(step.win_flags.size(), 2, "copie : l'étape n'est pas modifiée")


func test_give_step() -> void:
	var five := _one_step({"give": "poke_ball", "count": 5}, "a")
	assert_eq(five.kind, CutsceneStep.Kind.GIVE)
	assert_eq(CutsceneStep.kind_name(five.kind), &"give")
	assert_eq(five.item_id, &"poke_ball")
	assert_eq(five.count, 5)
	assert_eq(_one_step({"give": "potion"}, "b").count, 1, "1 par défaut")
	assert_false(five.found, "reçu par défaut, pas trouvé")
	var found := _one_step({"give": "potion", "found": true}, "c")
	assert_true(found.found, "objet trouvé dans le monde (jalon 5C.5)")
	assert_true(found.copy().found, "copié")
	assert_eq(_library.get_item_ids(), [&"poke_ball", &"potion"] as Array[StringName])


func test_invalid_battle_and_give_steps() -> void:
	var bad: Array[Dictionary] = [
		{"battle": ""},
		{"battle": "rival_lab", "player_pokemon": "player"},
		{"battle": "rival_lab", "foe_pokemon": "$Bad"},
		{"battle": "rival_lab", "player_pokemon": "a", "foe_pokemon": "a"},
		{"battle": "rival_lab", "win": []},
		{"battle": "rival_lab", "lose": "lost"},
		{"battle": "rival_lab", "to": [1, 1]},
		{"give": ""},
		{"give": "poke_ball", "count": 0},
		{"give": "poke_ball", "count": 1.5},
		{"give": "poke_ball", "count": "5"},
		{"give": "poke_ball", "to": "player"},
		{"give": "potion", "found": "yes"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par étape")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["battle : identifiant attendu", "pas « player »",
			"alias mal formé", "le même PNJ", "« win » doit être une liste non vide",
			"« lose » doit être une liste non vide", "clé inconnue « to »",
			"give : identifiant attendu", "« count » doit être un entier ≥ 1",
			"« found » doit être un booléen"]:
		assert_string_contains(errors, expected)


func test_step_conditions() -> void:
	var step := _one_step({"dialogue": "rival_lab_won_1", "if": ["rival_lab_won"],
		"unless": ["skip"]}, "a")
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.if_flags, [&"rival_lab_won"] as Array[StringName])
	assert_eq(step.unless_flags, [&"skip"] as Array[StringName])
	assert_false(step.applies(_flags()))
	assert_false(step.applies(null))
	assert_true(step.applies(_flags([&"rival_lab_won"])))
	assert_false(step.applies(_flags([&"rival_lab_won", &"skip"])))
	var plain := _one_step({"wait": 0.2}, "b")
	assert_true(plain.applies(null), "sans condition : toujours jouée")
	assert_true(plain.applies(_flags([&"skip"])))
	assert_eq(_library.get_condition_flags(), [&"rival_lab_won", &"skip"]
		as Array[StringName], "conditions d'étape lues")


func test_invalid_step_conditions_and_spawn_keeps_refusing_them() -> void:
	var bad: Array[Dictionary] = [
		{"wait": 0.2, "if": "won"},
		{"wait": 0.2, "unless": [""]},
		{"spawn": "oak", "sprite": "oak", "cell": [1, 1], "unless": ["x"]},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_push_error_count(bad.size())
	var errors := "\n".join(_library.get_errors())
	assert_string_contains(errors, "« if » doit être une liste de drapeaux")
	assert_string_contains(errors, "drapeau invalide dans « unless »")
	assert_string_contains(errors, "conditions : variante")


func test_copy_is_independent() -> void:
	var step := _one_step({"battle": "rival_lab", "player_pokemon": "$mine",
		"win": ["won"], "if": ["ready"]})
	var other := step.copy()
	assert_eq(other.kind, step.kind)
	assert_eq(other.trainer_id, &"rival_lab")
	assert_eq(other.player_pokemon, &"$mine")
	assert_eq(other.if_flags, [&"ready"] as Array[StringName])
	other.win_flags.append(&"more")
	other.if_flags.clear()
	assert_eq(step.win_flags, [&"won"] as Array[StringName])
	assert_eq(step.if_flags, [&"ready"] as Array[StringName])


# --- Jalon 7 (T2) : étape scare -------------------------------------------------------

func test_scare_step() -> void:
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.SCARE), &"scare")
	var step := _one_step({"scare": "viridian_roof_pidgey"}, "a")
	assert_not_null(step, str(_library.get_errors()))
	assert_eq(step.kind, CutsceneStep.Kind.SCARE)
	assert_eq(step.actor, &"viridian_roof_pidgey")
	assert_eq(step.copy().kind, CutsceneStep.Kind.SCARE, "copiée")
	var aliased := _one_step({"scare": "$bird", "unless": ["calm"]}, "b")
	assert_not_null(aliased, str(_library.get_errors()))
	assert_eq(aliased.get_aliases(), [&"bird"] as Array[StringName], "alias permis")
	assert_eq(aliased.unless_flags, [&"calm"] as Array[StringName], "conditions d'étape")


func test_invalid_scare_steps() -> void:
	var bad: Array[Dictionary] = [
		{"scare": "player"},
		{"scare": ""},
		{"scare": 3},
		{"scare": "$Bad"},
		{"scare": "pidgey", "to": [1, 1]},
		{"scare": "pidgey", "despawn": "pidgey"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	assert_push_error_count(bad.size(), "une erreur par étape")
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["réservé aux PNJ", "scare : identifiant attendu",
			"alias mal formé", "clé inconnue « to »", "exactement un type"]:
		assert_string_contains(errors, expected)


# --- Retours T5 (jalon-07.md §15.21) : move en arrière-plan, étape react ------------------

func test_background_move_and_react_steps() -> void:
	var move := _one_step({"move": "kid", "background": true, "path": ["right", "right"]}, "a")
	assert_not_null(move, str(_library.get_errors()))
	assert_true(move.background)
	assert_true(move.copy().background, "copiée")
	var plain := _one_step({"move": "kid", "path": ["right"]}, "b")
	assert_false(plain.background, "faux par défaut")
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.REACT), &"react")
	var actors: Array[String] = ["player", "viridian_roof_pidgey", "$buddy"]
	for i: int in actors.size():
		var react := _one_step({"react": actors[i]}, "r_%d" % i)
		assert_not_null(react, str(_library.get_errors()))
		assert_eq(react.kind, CutsceneStep.Kind.REACT)
		assert_eq(react.actor, StringName(actors[i]))


func test_invalid_background_and_react_steps() -> void:
	var bad: Array[Dictionary] = [
		{"move": "player", "background": true, "path": ["up"]},
		{"move": "kid", "background": true, "follower": "rat", "path": ["up"]},
		{"move": "kid", "background": "yes", "path": ["up"]},
		{"react": ""},
		{"react": "kid", "to": "up"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["« background » ne vaut que pour un PNJ",
			"« background » sans « follower »", "« background » vaut true ou false",
			"clé inconnue « to »"]:
		assert_string_contains(errors, expected)
	assert_push_error_count(bad.size(), "une erreur par étape")


# --- Jalon 9 (jalon-09.md §2.4.4) : étape emote ---------------------------------------

func test_emote_step() -> void:
	assert_eq(CutsceneStep.kind_name(CutsceneStep.Kind.EMOTE), &"emote")
	# En fin d'enum au jalon 9 ; le jalon 10 (T9) ajoute CHAMPION_CARD et BADGE après lui.
	assert_eq(CutsceneStep.Kind.EMOTE, CutsceneStep.Kind.REACT + 1, "après REACT")
	assert_eq(CutsceneStep.Kind.EMOTE, 17, "valeur stable")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size())
	assert_eq(CutsceneStep.EMOTE_KINDS, [&"exclamation"] as Array[StringName])
	var actors: Array[String] = ["scout_theo", "$trainer"]
	for i: int in actors.size():
		var emote := _one_step({"emote": actors[i], "kind": "exclamation"}, "e_%d" % i)
		assert_not_null(emote, str(_library.get_errors()))
		assert_eq(emote.kind, CutsceneStep.Kind.EMOTE)
		assert_eq(emote.actor, StringName(actors[i]))
		assert_eq(emote.emote, &"exclamation")
		assert_eq(emote.copy().emote, &"exclamation", "copiée")
	var conditional := _one_step({"emote": "kid", "kind": "exclamation", "if": ["seen"]}, "c")
	assert_eq(conditional.if_flags, [&"seen"] as Array[StringName], "conditions permises")
	assert_eq(_library.get_aliases(&"e_1"), [&"trainer"] as Array[StringName])


func test_invalid_emote_steps() -> void:
	var bad: Array[Dictionary] = [
		{"emote": "player", "kind": "exclamation"},
		{"emote": "kid"},
		{"emote": "kid", "kind": "question"},
		{"emote": "kid", "kind": 1},
		{"emote": "", "kind": "exclamation"},
		{"emote": "kid", "kind": "exclamation", "to": "up"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0)
	var errors := "\n".join(_library.get_errors())
	for expected: String in ["réservé aux PNJ", "« kind » vaut exclamation",
			"emote : identifiant attendu", "clé inconnue « to »"]:
		assert_string_contains(errors, expected)
	assert_push_error_count(bad.size(), "une erreur par étape")


# --- Enchaînement « next » (jalon-13.md §2.9, T16) -------------------------------------------

func test_next_is_read_beside_variants_or_in_the_single_variant_form() -> void:
	assert_true(_library.add_from_dict({
		"first": {"next": "second", "variants": [{"steps": [{"wait": 0}]}]},
		"second": {"next": "third", "unless": ["done"], "steps": [{"set": ["done"]}]},
		"third": {"steps": [{"wait": 0}]},
	}, "test"))
	assert_true(_library.check_next_references(), "références connues")
	assert_eq(_library.get_next(&"first"), &"second")
	assert_eq(_library.get_next(&"second"), &"third")
	assert_eq(_library.get_cutscene(&"second").variants[0].unless_flags,
		[&"done"] as Array[StringName], "la forme courte garde ses conditions")
	assert_eq(_library.get_next(&"third"), &"", "pas de suite")
	assert_eq(_library.get_next(&"unknown"), &"", "scène inconnue : pas de suite")


func test_bad_next_is_rejected() -> void:
	for value: Variant in ["", "  ", 3, ["second"]]:
		assert_false(_library.add_from_dict({"s": {"next": value, "steps": [{"wait": 0}]}},
			"test"), str(value))
	assert_eq(_library.size(), 0)
	assert_push_error_count(4)


func test_next_must_name_another_known_scene() -> void:
	assert_true(_library.add_from_dict({
		"to_nowhere": {"next": "missing", "steps": [{"wait": 0}]},
		"to_itself": {"next": "to_itself", "steps": [{"wait": 0}]},
		"fine": {"next": "target", "steps": [{"wait": 0}]},
		"target": {"steps": [{"wait": 0}]},
	}, "test"), "références vérifiées après le chargement de tout le dossier")
	assert_false(_library.check_next_references())
	assert_push_error_count(2)
	assert_false(_library.has_cutscene(&"to_nowhere"), "scène écartée")
	assert_false(_library.has_cutscene(&"to_itself"), "pas de boucle sur elle-même")
	assert_true(_library.has_cutscene(&"fine"))
	assert_string_contains("\n".join(_library.get_errors()), "« next » vaut « missing »")


func test_real_cutscenes_have_valid_next_references() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), "\n".join(library.get_errors()))


# --- Jalon 19 (T13) : étape « wild_battle » ----------------------------------------------

func test_wild_battle_step_reads_species_level_ghost_and_flags() -> void:
	var step := _one_step({"wild_battle": "marowak", "level": 30, "ghost": "always",
		"ghost_unless_item": "silph_scope", "win": ["won"], "lose": ["lost"]})
	assert_not_null(step, str(_library.get_errors()))
	if step == null:
		return
	assert_eq(step.kind, CutsceneStep.Kind.WILD_BATTLE)
	assert_eq(step.species, &"marowak")
	assert_eq(step.level, 30)
	assert_eq(step.ghost_mode, GhostRule.ALWAYS)
	assert_eq(step.ghost_unless_item, &"silph_scope")
	assert_eq(step.win_flags, [&"won"] as Array[StringName])
	assert_eq(step.lose_flags, [&"lost"] as Array[StringName])
	assert_eq(_library.get_wild_species(), [&"marowak"] as Array[StringName])
	assert_has(_library.get_set_flags(), &"won")
	assert_has(_library.get_set_flags(), &"lost")
	var copy := step.copy()
	assert_eq([copy.species, copy.level, copy.ghost_mode, copy.ghost_unless_item],
		[step.species, step.level, step.ghost_mode, step.ghost_unless_item], "copie complète")


func test_wild_battle_minimal_step_has_no_ghost_rule_and_no_flags() -> void:
	var step := _one_step({"wild_battle": "cubone", "level": 1})
	assert_not_null(step, str(_library.get_errors()))
	if step == null:
		return
	assert_eq(step.ghost_mode, &"")
	assert_eq(step.ghost_unless_item, &"")
	assert_true(step.win_flags.is_empty())
	assert_true(step.lose_flags.is_empty())
	assert_eq(step.level, 1)


func test_wild_battle_kind_is_last_in_the_enum() -> void:
	assert_eq(CutsceneStep.Kind.WILD_BATTLE, CutsceneStep.Kind.GIFT_POKEMON - 1,
		"en fin d'enum avant le don du J20")
	assert_eq(CutsceneStep.Kind.WILD_BATTLE, CutsceneStep.Kind.ANIMATE + 1)
	assert_eq(CutsceneStep.TYPE_KEYS[CutsceneStep.Kind.WILD_BATTLE], "wild_battle")


func test_invalid_wild_battle_steps_are_refused() -> void:
	var bad: Array[Dictionary] = [
		{"wild_battle": "", "level": 30},
		{"wild_battle": 12, "level": 30},
		{"wild_battle": "marowak"},
		{"wild_battle": "marowak", "level": 0},
		{"wild_battle": "marowak", "level": 101},
		{"wild_battle": "marowak", "level": 30.5},
		{"wild_battle": "marowak", "level": "30"},
		{"wild_battle": "marowak", "level": 30, "ghost": "sometimes"},
		{"wild_battle": "marowak", "level": 30, "ghost": ""},
		{"wild_battle": "marowak", "level": 30, "ghost": true},
		{"wild_battle": "marowak", "level": 30, "ghost_unless_item": ""},
		{"wild_battle": "marowak", "level": 30, "win": []},
		{"wild_battle": "marowak", "level": 30, "lose": "lost"},
		{"wild_battle": "marowak", "level": 30, "trainer": "x"},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0, "toutes refusées")
	assert_push_error_count(bad.size())


func test_check_species_discards_scenes_with_unknown_species() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir(), "données Pokémon")
	assert_true(_library.add_from_dict({
		"known": {"steps": [{"wild_battle": "marowak", "level": 30}]},
		"unknown": {"steps": [{"wait": 0}, {"wild_battle": "missingno", "level": 30}]},
	}, "test"))
	assert_false(_library.check_species(data))
	assert_push_error_count(1)
	assert_true(_library.has_cutscene(&"known"))
	assert_false(_library.has_cutscene(&"unknown"), "scène écartée")
	assert_string_contains("\n".join(_library.get_errors()), "« missingno »")


func test_real_cutscenes_name_known_species() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var data := PokemonData.new()
	assert_true(data.load_dir())
	assert_true(library.check_species(data), "\n".join(library.get_errors()))


# --- Jalon 20 (T12) : étape « gift_pokemon » ---------------------------------------------

func test_gift_pokemon_step_reads_species_level_flag_and_dialogues() -> void:
	var step := _one_step({"gift_pokemon": "eevee", "level": 25, "flag": "eevee_received",
		"say": "received", "say_stored": "stored"})
	assert_not_null(step, str(_library.get_errors()))
	if step == null:
		return
	assert_eq(step.kind, CutsceneStep.Kind.GIFT_POKEMON)
	assert_eq([step.species, step.level, step.gift_flag], [&"eevee", 25, &"eevee_received"])
	assert_eq([step.dialogue_id, step.dialogue_stored], [&"received", &"stored"])
	assert_has(_library.get_set_flags(), &"eevee_received", "le drapeau est levé par l'étape")
	assert_eq(_library.get_dialogue_ids(), [&"received", &"stored"] as Array[StringName])
	assert_eq(_library.get_wild_species(), [] as Array[StringName], "pas un combat sauvage")
	var copy := step.copy()
	assert_eq([copy.species, copy.level, copy.gift_flag, copy.dialogue_id, copy.dialogue_stored],
		[step.species, step.level, step.gift_flag, step.dialogue_id, step.dialogue_stored],
		"copie complète")


func test_gift_pokemon_without_say_stored() -> void:
	var step := _one_step({"gift_pokemon": "eevee", "level": 25, "flag": "f", "say": "d"})
	assert_not_null(step, str(_library.get_errors()))
	if step != null:
		assert_eq(step.dialogue_stored, &"")


func test_gift_pokemon_kind_is_last_in_the_enum() -> void:
	# J23 : SAFARI après GIFT_POKEMON (fin d'enum).
	assert_eq(CutsceneStep.Kind.GIFT_POKEMON, CutsceneStep.Kind.size() - 2, "en fin d'enum")
	assert_eq(CutsceneStep.Kind.SAFARI, CutsceneStep.Kind.size() - 1, "J23 en fin d'enum")
	assert_eq(CutsceneStep.TYPE_KEYS[CutsceneStep.Kind.GIFT_POKEMON], "gift_pokemon")
	assert_eq(CutsceneStep.TYPE_KEYS.size(), CutsceneStep.Kind.size())


func test_invalid_gift_pokemon_steps_are_refused() -> void:
	var ok := {"gift_pokemon": "eevee", "level": 25, "flag": "f", "say": "d"}
	var bad: Array[Dictionary] = [
		{"gift_pokemon": "", "level": 25, "flag": "f", "say": "d"},
		{"gift_pokemon": 3, "level": 25, "flag": "f", "say": "d"},
		{"gift_pokemon": "eevee", "flag": "f", "say": "d"},
		{"gift_pokemon": "eevee", "level": 0, "flag": "f", "say": "d"},
		{"gift_pokemon": "eevee", "level": 101, "flag": "f", "say": "d"},
		{"gift_pokemon": "eevee", "level": 25.5, "flag": "f", "say": "d"},
		{"gift_pokemon": "eevee", "level": 25, "say": "d"},
		{"gift_pokemon": "eevee", "level": 25, "flag": "", "say": "d"},
		{"gift_pokemon": "eevee", "level": 25, "flag": "f"},
		{"gift_pokemon": "eevee", "level": 25, "flag": "f", "say": ""},
		{"gift_pokemon": "eevee", "level": 25, "flag": "f", "say": "d", "say_stored": ""},
		{"gift_pokemon": "eevee", "level": 25, "flag": "f", "say": "d", "count": 2},
	]
	for i: int in bad.size():
		assert_null(_one_step(bad[i], "bad_%d" % i), str(bad[i]))
	assert_eq(_library.size(), 0, "toutes refusées")
	assert_push_error_count(bad.size())
	assert_not_null(_one_step(ok, "fine"), "la forme minimale passe")


func test_check_species_covers_gift_steps() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir(), "données Pokémon")
	assert_true(_library.add_from_dict({
		"known": {"steps": [{"gift_pokemon": "eevee", "level": 25, "flag": "f", "say": "d"}]},
		"unknown": {"steps": [{"gift_pokemon": "missingno", "level": 5, "flag": "g",
			"say": "d"}]},
	}, "test"))
	assert_false(_library.check_species(data))
	assert_push_error_count(1)
	assert_true(_library.has_cutscene(&"known"))
	assert_false(_library.has_cutscene(&"unknown"), "scène écartée")


func test_real_eevee_gift_scene() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), "\n".join(library.get_errors()))
	var cutscene := library.get_cutscene(&"celadon_eevee_gift")
	assert_not_null(cutscene, "scène du don d'Évoli")
	if cutscene == null:
		return
	var steps := cutscene.pick(StoryFlags.new()).steps
	assert_eq(steps[0].kind, CutsceneStep.Kind.GIFT_POKEMON)
	assert_eq([steps[0].species, steps[0].level, steps[0].gift_flag],
		[&"eevee", 25, &"eevee_received"], "Évoli N25, drapeau du dossier 23 §15")
	assert_eq([steps[0].dialogue_id, steps[0].dialogue_stored],
		[&"celadon_eevee_received", &"celadon_eevee_stored"], "T-29, T-30")
	assert_eq([steps[1].kind, steps[1].actor], [CutsceneStep.Kind.DESPAWN, &"eevee_ball"],
		"la Poké Ball disparaît")
