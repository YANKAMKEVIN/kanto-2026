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
