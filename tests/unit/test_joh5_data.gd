extends GutTest
## JOH5 (`docs/tech/jalon-joh5.md` §2.2, §2.7) : données générées de la Tour Radio
## (`tools/gen_joh5_data.py`) : Dresseurs du dossier JOH-06 §5, textes T-1 à T-34 mot pour mot
## (D-18 et D-19 du dossier JOH-04), drapeaux du §10, scènes et dialogues tous joués, variantes
## dont les drapeaux sont écrits quelque part.

const J22Ids := preload("res://tests/helpers/j22_ids.gd")
const DOSSIER := "res://docs/design/dossier-joh-06-tour-radio.md"
const DOSSIER_JOH3 := "res://docs/design/dossier-joh-04-doublonville.md"
const DIALOGUES := "res://data/dialogues/joh5_radio_tower.json"
const CUTSCENES := "res://data/cutscenes/joh5_radio_tower.json"
const NPC_FILE := "res://data/npcs/goldenrod_radio_tower_%df.json"
## Dialogues et scènes ouverts par les points de la carte (outil de construction).
const MAP_POINTS: Array[StringName] = [&"goldenrod_radio_elevator", &"goldenrod_radio_console",
	&"goldenrod_radio_emergency_stairs", &"goldenrod_radio_loudspeaker",
	&"goldenrod_radio_reserve_door", &"goldenrod_radio_office_locked",
	&"radio_3f_hidden_1", &"radio_4f_hidden_1"]
const MAP_TRIGGERS: Array[StringName] = [&"goldenrod_radio_impostor", &"goldenrod_radio_exit",
	&"goldenrod_radio_cenere", &"goldenrod_radio_office"]
## Drapeaux venus d'autres jalons ou systèmes (lus, jamais posés ici).
const EXTERNAL_FLAGS: Array[StringName] = [&"johto_radio_pass", &"johto_team_returned"]
## Dossier §5 : équipes.
const TEAMS: Dictionary = {
	&"goldenrod_radio_tower_impostor": [[&"arbok", 26], [&"raticate", 26]],
	&"goldenrod_radio_tower_grunt_h": [[&"golbat", 26], [&"koffing", 26]],
	&"goldenrod_radio_tower_grunt_i": [[&"houndour", 27], [&"murkrow", 27]],
	&"goldenrod_radio_tower_grunt_j": [[&"magneton", 27]],
	&"goldenrod_radio_tower_grunt_k": [[&"muk", 28], [&"ekans", 27]],
	&"goldenrod_radio_tower_grunt_l": [[&"raticate", 28], [&"golbat", 28]],
	&"goldenrod_radio_tower_keeper": [[&"houndour", 28], [&"koffing", 28], [&"murkrow", 29]],
	&"goldenrod_radio_tower_grunt_m": [[&"arbok", 29], [&"muk", 29]],
	&"goldenrod_radio_tower_grunt_n": [[&"magneton", 29], [&"weezing", 29]],
	&"goldenrod_radio_tower_grunt_o": [[&"houndour", 30], [&"golbat", 30]],
	&"goldenrod_radio_tower_admin_cenere": [[&"weezing", 33], [&"wobbuffet", 33],
		[&"sneasel", 35]],
}

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	assert_true(_dialogues.load_file(DIALOGUES), "\n".join(_dialogues.get_errors()))
	_cutscenes = CutsceneLibrary.new()
	assert_true(_cutscenes.load_file(CUTSCENES), "\n".join(_cutscenes.get_errors()))


func test_trainers_follow_the_dossier() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var trainers := TrainerLibrary.new(data)
	assert_true(trainers.load_dir())
	for id: StringName in TEAMS:
		var trainer := trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		var team: Array = []
		for slot: TrainerSlot in trainer.team:
			team.append([slot.species, slot.level])
		assert_eq(team, TEAMS[id], "%s : équipe du §5" % id)
	var cenere := trainers.get_trainer(&"goldenrod_radio_tower_admin_cenere")
	assert_eq(cenere.name, "Cenere")


func test_texts_are_the_validated_ones_word_for_word() -> void:
	var corpus := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER)) + " " \
		+ J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER_JOH3))
	var checked := 0
	for id: StringName in _dialogues.get_ids():
		var dialogue := _dialogues.get_dialogue(id)
		for variant: DialogueVariant in dialogue.variants:
			if variant.draft:
				continue
			for page: DialoguePage in variant.pages:
				var text := page.text.replace("{player}", "{joueur}") \
					.replace("{returning_pokemon}", "{pokemon}")
				checked += 1
				assert_true(corpus.contains(J22Ids.flat_text(text)),
					"%s : « %s » dans le dossier" % [id, text])
	assert_gt(checked, 90, "textes T-1 à T-34")


func test_dossier_flags_are_set() -> void:
	var set_flags: Array[StringName] = _cutscenes.get_set_flags() + _dialogues.get_set_flags()
	for flag: StringName in [&"johto_radio_impostor_defeated", &"johto_radio_staff_freed",
			&"johto_cenere_defeated", &"johto_dante_revealed", &"radio_exp_share_given",
			&"johto_act2", &"johto_radio_reserve_key", &"johto_radio_staff_talked"]:
		assert_true(set_flags.has(flag), "%s posé par la Tour" % flag)


func test_every_condition_flag_is_written() -> void:
	var written: Array[StringName] = _cutscenes.get_set_flags() + _dialogues.get_set_flags()
	written.append_array(EXTERNAL_FLAGS)
	for floor_number: int in range(1, 6):
		var roster := NpcRoster.new()
		assert_true(roster.load_file(NPC_FILE % floor_number))
		for spec: NpcSpec in roster.get_all():
			for flag: StringName in spec.if_flags + spec.unless_flags:
				if String(flag).begins_with("got_") or String(flag).begins_with("beaten_"):
					continue
				assert_true(written.has(flag), "%s : %s écrit quelque part" % [spec.id, flag])
	for id: StringName in _cutscenes.get_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			for flag: StringName in variant.if_flags + variant.unless_flags:
				if String(flag).begins_with("got_"):
					continue
				assert_true(written.has(flag), "%s : %s écrit quelque part" % [id, flag])


func test_every_scene_and_dialogue_is_used() -> void:
	var used: Dictionary = {}
	for id: StringName in MAP_POINTS + MAP_TRIGGERS:
		used[id] = true
	for floor_number: int in range(1, 6):
		var roster := NpcRoster.new()
		assert_true(roster.load_file(NPC_FILE % floor_number))
		for spec: NpcSpec in roster.get_all():
			used[spec.dialogue] = true
			if spec.is_trainer():
				used[spec.before_dialogue] = true
				used[spec.defeated_dialogue] = true
	for id: StringName in _dialogues.get_ids():
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				used[variant.cutscene] = true
	for id: StringName in _cutscenes.get_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.DIALOGUE:
					used[step.dialogue_id] = true
	for id: StringName in _dialogues.get_ids():
		assert_true(used.has(id), "dialogue « %s » joué" % id)
	for id: StringName in _cutscenes.get_ids():
		assert_true(used.has(id), "scène « %s » lancée" % id)


## Plan §2.5 : une seule écriture, juste après le retour ; T-31 après l'écriture.
func test_office_scene_returns_the_team_then_saves_once() -> void:
	var office := _cutscenes.get_cutscene(&"goldenrod_radio_office")
	assert_eq(office.variants.size(), 2, "Multi Exp déjà possédée ou non")
	for variant: CutsceneVariant in office.variants:
		var kinds: Array = []
		for step: CutsceneStep in variant.steps:
			kinds.append(step.kind)
		var back := kinds.find(CutsceneStep.Kind.RETURN_TEAM)
		var save := kinds.find(CutsceneStep.Kind.SAVE)
		assert_gt(back, -1, "retour de l'équipe")
		assert_eq(kinds.count(CutsceneStep.Kind.SAVE), 1, "une seule écriture")
		assert_gt(save, back, "écriture après le retour")
		var gift := -1
		for i: int in variant.steps.size():
			if variant.steps[i].kind == CutsceneStep.Kind.GIVE:
				gift = i
		assert_gt(gift, save, "le cadeau du directeur vient après l'écriture")
	var flags := StoryFlags.new()
	flags.set_flag(&"johto_dante_revealed")
	var bag := Bag.new()
	assert_same(office.pick(flags, bag), office.variants[1], "sans Multi Exp : la Multi Exp")
	bag.add(&"exp_all", 1)
	assert_same(office.pick(flags, bag), office.variants[0], "avec : 3 Super Bonbons")
	flags.set_flag(&"johto_team_returned")
	assert_null(office.pick(flags, bag), "jouée une seule fois")


func test_returning_pokemon_token() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var confiscated := ConfiscatedTeam.new()
	assert_eq(DialogueTokens.returning_name(confiscated, data), "", "rien de confisqué")
	var rng := GameRng.new(3)
	var first := PokemonFactory.create(data, &"charizard", 50, rng)
	var second := PokemonFactory.create(data, &"pidgeot", 50, rng)
	first.ensure_uid()
	second.ensure_uid()
	confiscated.party.append(first)
	confiscated.party.append(second)
	assert_eq(DialogueTokens.returning_name(confiscated, data), "Dracaufeu", "le premier")
	confiscated.companion_uid = second.uid
	assert_eq(DialogueTokens.returning_name(confiscated, data), "Roucarnage",
		"le compagnon d'avant le vol")
	assert_true(DialogueTokens.KNOWN.has(DialogueTokens.RETURNING_POKEMON))
