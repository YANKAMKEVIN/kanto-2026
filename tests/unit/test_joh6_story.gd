extends GutTest
## Chapitre Johto, JOH6 : l'histoire (`tools/gen_joh6_story.py`, `docs/tech/jalon-joh6.md` §2.5 à
## §2.7) : variante rouge (Pokémon, sauvegarde, rencontre fixe), étape « flashback » et son
## filtre, textes du dossier mot pour mot, structure des scènes (drapeaux, combats, souvenir).

const STORY_DIALOGUES := "res://data/dialogues/joh6_story.json"
const STORY_CUTSCENES := "res://data/cutscenes/joh6_story.json"

var _data: PokemonData
var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_file(STORY_DIALOGUES)
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_file(STORY_CUTSCENES)


func _join(pages: Array[DialoguePage]) -> String:
	var texts: PackedStringArray = []
	for page: DialoguePage in pages:
		texts.append(page.text)
	return " / ".join(texts)


func _text(id: StringName) -> String:
	var dialogue := _dialogues.get_dialogue(id)
	assert_not_null(dialogue, String(id))
	if dialogue == null:
		return ""
	var pages: Array[String] = []
	for variant: DialogueVariant in dialogue.variants:
		for page: DialoguePage in variant.pages:
			pages.append(page.text.replace("\n", " "))
	return " / ".join(pages)


func _steps(id: StringName) -> Array[CutsceneStep]:
	var cutscene := _cutscenes.get_cutscene(id)
	assert_not_null(cutscene, String(id))
	if cutscene == null:
		return []
	return cutscene.variants[0].steps


func _kinds(id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for step: CutsceneStep in _steps(id):
		out.append(CutsceneStep.kind_name(step.kind))
	return out


# --- Variante rouge (JH-46) ---------------------------------------------------------------------

func test_variant_is_saved_only_when_set_and_read_back() -> void:
	var gyarados := PokemonFactory.create(_data, &"gyarados", 50, GameRng.new())
	assert_false(gyarados.to_dict().has("variant"), "forme normale : pas de clé")
	gyarados.variant = &"red"
	var dict := gyarados.to_dict()
	assert_eq(dict.get("variant"), "red")
	var back := Pokemon.from_dict(dict, _data)
	assert_eq(back.variant, &"red")
	# Sauvegarde d'avant le JOH6 (pas de clé) et variante inconnue : forme normale.
	dict.erase("variant")
	assert_eq(Pokemon.from_dict(dict, _data).variant, &"")
	dict["variant"] = "gold"
	assert_eq(Pokemon.from_dict(dict, _data).variant, &"")
	assert_push_warning("variante inconnue")


func test_variant_material_only_for_known_variants() -> void:
	assert_true(PokemonVariant.is_known(&"red"))
	assert_false(PokemonVariant.is_known(&""))
	assert_null(PokemonVariant.material_for(&""))
	var material := PokemonVariant.material_for(&"red")
	assert_not_null(material)
	assert_almost_eq(float(material.get_shader_parameter(&"hue_shift")), 0.42, 0.001)


func test_wild_request_carries_the_variant_into_the_foe() -> void:
	var encounter := WildEncounter.new(&"gyarados", 50, &"test")
	encounter.variant = &"red"
	var request := BattleRequest.wild(encounter, _data, GameRng.new(), Vector2i.ZERO)
	assert_eq(request.foe_party.get_lead().variant, &"red")


func test_red_gyarados_is_a_fixed_red_encounter() -> void:
	var steps := _steps(&"lake_red_gyarados")
	assert_eq(steps.size(), 1)
	var battle := steps[0]
	assert_eq(battle.kind, CutsceneStep.Kind.WILD_BATTLE)
	assert_eq(battle.species, &"gyarados")
	assert_eq(battle.level, 50)
	assert_eq(battle.variant, &"red")
	assert_eq(battle.actor, &"leviator_rouge")
	assert_eq(battle.static_encounter.done_flag, &"johto_red_gyarados_done")
	assert_eq(battle.static_encounter.caught_flag, &"johto_red_gyarados_caught")


func test_unknown_variant_is_refused_by_the_library() -> void:
	var library := CutsceneLibrary.new()
	var ok := library.add_from_dict({"x": {"variants": [{"steps": [
		{"wild_battle": "gyarados", "level": 50, "variant": "gold"}]}]}}, "test")
	assert_false(ok)
	assert_push_error("« variant »")


# --- Souvenir de Dante (§2.7) ---------------------------------------------------------------------

func test_flashback_step_values() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.add_from_dict({"ok": {"variants": [{"steps": [
		{"flashback": "start"}, {"flashback": "end"}]}]}}, "test"))
	assert_eq(library.get_cutscene(&"ok").variants[0].steps[0].text, "start")
	var bad := CutsceneLibrary.new()
	assert_false(bad.add_from_dict({"ko": {"variants": [{"steps": [{"flashback": true}]}]}},
		"test"))
	assert_push_error("« flashback »")


func test_flashback_filter_fades() -> void:
	var filter := FlashbackFilter.new()
	add_child_autofree(filter)
	assert_eq(filter.layer, UiTokens.LAYER_WORLD_GRADE + 1)
	assert_lt(filter.layer, UiTokens.LAYER_HUD)
	assert_eq(filter.get_amount(), 0.0)
	await filter.fade_to(1.0, 0.05)
	assert_almost_eq(filter.get_amount(), 1.0, 0.001)
	filter.set_amount(2.0)
	assert_eq(filter.get_amount(), 1.0)


func test_deserter_scene_plays_the_sepia_memory_and_comes_back() -> void:
	var steps := _steps(&"hideout_deserter")
	var kinds := _kinds(&"hideout_deserter")
	var start := kinds.find(&"flashback")
	var end := kinds.rfind(&"flashback")
	assert_lt(start, end)
	assert_eq(steps[start].text, "start")
	assert_eq(steps[end].text, "end")
	assert_eq(steps[start + 1].kind, CutsceneStep.Kind.CHANGE_MAP)
	assert_eq(steps[start + 1].map_id, &"dante_flashback_hq")
	assert_eq(steps[end - 1].map_id, &"mahogany_hideout_b2f")
	assert_eq(steps[end - 1].spawn, &"devant_deserteur")
	var last := steps[steps.size() - 1]
	assert_eq(last.kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(last.flags, [&"johto_dante_flashback_seen"] as Array[StringName])


# --- Textes (dossier §16, mot pour mot) -----------------------------------------------------------

func test_texts_word_for_word() -> void:
	var expected: Dictionary = {
		&"joh6_beasts_sleep": "Trois Pokémon dorment au milieu des cendres. / …",
		&"joh6_beasts_wake": "Ils ouvrent les yeux !",
		&"joh6_beasts_flee": "Ils bondissent hors de la tour, chacun dans une direction !",
		&"joh6_brace_arrives": "Ha ! Je savais que tu les réveillerais pour moi ! / Merci du coup de main, le gamin !",
		&"joh6_brace_cage_thrown": "Brace lance une cage métallique !",
		&"joh6_brace_cage_caught": "Raikou est pris dans un filet d'éclairs !",
		&"joh6_brace_leaves_tower": "Un sur trois, c'est déjà pas mal. / Le patron s'occupera des deux autres. / À plus, le gamin !",
		&"joh6_doyen_plan": "Ils sont réveillés… et l'un d'eux est captif. / Écoute. La légende dit que Ho-Oh veille sur ces trois-là. / Si un homme les tient tous les trois, Ho-Oh descendra à la Tour Carillon pour les sauver. / C'est donc ça, son plan : forcer Ho-Oh à descendre. / Et s'emparer de sa flamme. La flamme qui a fait renaître la tour… / Entre de mauvaises mains, elle peut tout réduire en cendres. / L'homme qui a pris Raikou est parti vers l'est. Vers Acajou.",
		&"joh6_red_gyarados": "Un Léviator rouge surgit des eaux ! / Il est furieux !",
		&"joh6_shop_stairs": "Un courant d'air froid sort de sous une étagère. / … / Un escalier !",
		&"joh6_hideout_alarm": "Les yeux de la statue s'allument ! / Une alarme retentit !",
		&"joh6_deserter_story": "Dante était notre chef. Le premier. / Giovanni était son bras droit. Son élève. Presque son fils. / Et puis il y a eu l'incendie…",
		&"joh6_flashback_dante": "Giovanni ! La porte est bloquée ! Ouvre !",
		&"joh6_flashback_giovanni": "Tu m'as tout appris, Dante. / Même ça. Surtout ça.",
		&"joh6_flashback_leaves": "(Giovanni s'éloigne avec Persian. Les flammes montent.)",
		&"joh6_deserter_after": "Tout le monde l'a cru mort. Giovanni a pris la Team Rocket. / Mais Dante a survécu. Brûlé, défiguré. / Il a attendu vingt ans. Et maintenant, il veut tout brûler à son tour.",
		&"joh6_deserter_password": "La porte du fond a un mot de passe. / Avant, c'était « Vive Giovanni ». Maintenant, c'est « Gloire à Dante ». / Ça me brûle la langue de le dire.",
		&"joh6_password": "{player} : Gloire à Dante. / La porte s'ouvre.",
		&"joh6_brace_leaves": "Ta victoire ne change rien. / Cenere est déjà partie chercher le deuxième. / Et le patron ira chercher le troisième lui-même. / On se reverra au sommet, le gamin !",
		&"joh6_brace_escape": "Brace s'enfuit par un passage secret !",
	}
	for id: StringName in expected:
		assert_eq(_text(id), expected[id], String(id))
	# Variantes : C-32, C-33, C-43, C-44, C-45 en tête des dialogues à variantes.
	var deserter := _dialogues.get_dialogue(&"joh6_deserter")
	assert_eq(_join(deserter.variants[0].pages),
		"Hé, toi ! Le gamin de la radio ! Sors-moi de là. / Je ne suis pas avec eux. Plus maintenant.")
	assert_eq(_join(deserter.variants[1].pages),
		"Merci. / Après la Tour Radio, j'ai dit non. Je suis venu pour Giovanni, pas pour lui. / Brace m'a jeté ici. / Tu veux savoir qui est Dante ? J'étais là, moi. Il y a vingt ans.")
	assert_eq(_join(_dialogues.get_dialogue(&"mahogany_hideout_b3f_arret_generateur")
		.variants[0].pages), "{player} coupe le générateur. / … / Le bourdonnement s'arrête. La cage s'ouvre !")
	assert_eq(_dialogues.get_dialogue(&"joh6_raikou").variants[1].pages[0].text, "Raikou rugit !")
	assert_eq(_join(_dialogues.get_dialogue(&"joh6_deserter_center").variants[0].pages),
		"Le lac est calme, la machine est morte. Merci. / Écoute : Cenere est partie vers la mer, à l'ouest. / Le Pokémon bleu, celui qui court sur l'eau… / Elle le cherche aux Îles Tourbillon. Les Sbires en parlaient.")


# --- Scènes -----------------------------------------------------------------------------------

func test_beasts_scene_sets_its_flags_once() -> void:
	# Drapeaux posés à la fin : les chiens (PNJ `unless johto_beasts_awakened`) restent pendant la
	# scène.
	var steps := _steps(&"burned_tower_beasts")
	assert_eq(steps[steps.size() - 1].flags,
		[&"johto_beasts_awakened", &"johto_raikou_taken"] as Array[StringName])
	var cutscene := _cutscenes.get_cutscene(&"burned_tower_beasts")
	assert_eq(cutscene.variants[0].unless_flags, [&"johto_beasts_awakened"] as Array[StringName])


func test_brace_fight_is_mandatory_and_a_defeat_wakes_up_at_the_center() -> void:
	var steps := _steps(&"hideout_brace")
	var battle_found := false
	for step: CutsceneStep in steps:
		if step.kind == CutsceneStep.Kind.BATTLE:
			battle_found = true
			assert_eq(step.trainer_id, &"mahogany_hideout_b3f_brace")
			assert_true(step.win_flags.has(&"beaten_mahogany_hideout_b3f_brace"))
		if step.kind == CutsceneStep.Kind.SET_FLAGS:
			assert_eq(step.flags, [&"johto_brace_defeated_2"] as Array[StringName])
			assert_eq(step.if_flags, [&"beaten_mahogany_hideout_b3f_brace"] as Array[StringName])
	assert_true(battle_found)
	var last := steps[steps.size() - 1]
	assert_eq(last.kind, CutsceneStep.Kind.WAKE_UP)
	assert_eq(last.unless_flags, [&"beaten_mahogany_hideout_b3f_brace"] as Array[StringName])


func test_raikou_flight_consumes_the_encounter() -> void:
	var battle := _steps(&"hideout_raikou")[0]
	assert_eq(battle.species, &"raikou")
	assert_eq(battle.level, 60)
	assert_eq(battle.static_encounter.done_flag, &"johto_raikou_done")
	assert_true(battle.flee_flags.has(&"johto_raikou_done"))
	# QA A17 : Raikou restait sur la carte après une fuite.
	var leave := _steps(&"hideout_raikou")[1]
	assert_eq(leave.kind, CutsceneStep.Kind.DESPAWN)
	assert_eq(leave.if_flags, [&"johto_raikou_fled"] as Array[StringName])
	assert_eq(_cutscenes.get_cutscene(&"hideout_raikou").variants[0].if_flags,
		[&"johto_generator_off"] as Array[StringName])


func test_alarms_ring_once_per_statue_and_force_a_battle() -> void:
	for number: int in [1, 2, 3]:
		var id := StringName("hideout_alarm_%d" % number)
		var cutscene := _cutscenes.get_cutscene(id)
		var flag := StringName("johto_alarm_%d" % number)
		assert_eq(cutscene.variants[0].unless_flags, [flag] as Array[StringName])
		var steps := _steps(id)
		assert_eq(steps[0].flags, [flag] as Array[StringName], "drapeau en tête")
		assert_true(_kinds(id).has(&"battle"), String(id))
		assert_eq(steps[steps.size() - 1].kind, CutsceneStep.Kind.WAKE_UP)


func test_shop_stairs_need_the_lake() -> void:
	var variant := _cutscenes.get_cutscene(&"souvenir_shop_stairs").variants[0]
	assert_eq(variant.if_flags, [&"johto_red_gyarados_done"] as Array[StringName])
	assert_eq(variant.unless_flags, [&"johto_hideout_found"] as Array[StringName])


func test_story_npcs_of_the_memory() -> void:
	var roster := NpcRoster.load_for_map(&"dante_flashback_hq")
	assert_eq(roster.get_errors(), PackedStringArray())
	for id: StringName in [&"dante_jeune", &"giovanni_jeune", &"persian"]:
		assert_not_null(roster.get_spec(id), String(id))
