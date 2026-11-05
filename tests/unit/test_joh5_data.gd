extends GutTest
## JOH5 (`docs/tech/jalon-joh5.md` §2.2, §2.7) : données générées de la Tour Radio
## (`tools/gen_joh5_data.py`) : Dresseurs du dossier JOH-06 §5, textes T-1 à T-34 mot pour mot
## (D-18 et D-19 du dossier JOH-04), drapeaux du §10, scènes et dialogues tous joués, variantes
## dont les drapeaux sont écrits quelque part.

const J22Ids := preload("res://tests/helpers/j22_ids.gd")
const DOSSIER := "res://docs/design/dossier-joh-06-tour-radio.md"
const DOSSIER_JOH3 := "res://docs/design/dossier-joh-04-doublonville.md"
## P-1, la légende d'Orme (suite de T-34), est écrite au dossier de l'arc (JOH-11 §17).
const DOSSIER_ARC := "res://docs/design/dossier-joh-11-arc-pierres.md"
const DIALOGUES := "res://data/dialogues/joh5_radio_tower.json"
const CUTSCENES := "res://data/cutscenes/joh5_radio_tower.json"
const NPC_FILE := "res://data/npcs/goldenrod_radio_tower_%df.json"
## Dialogues et scènes ouverts par les points de la carte (outil de construction).
const MAP_POINTS: Array[StringName] = [&"goldenrod_radio_elevator", &"goldenrod_radio_console",
	&"goldenrod_radio_emergency_stairs", &"goldenrod_radio_loudspeaker",
	&"goldenrod_radio_reserve_door", &"goldenrod_radio_office_locked",
	&"radio_3f_hidden_1", &"radio_4f_hidden_1",
	# T-38 : joué par la scène `sea_cave_current_back` du JOH1 (grotte marine).
	&"sea_cave_calm",
	# T-35, T-36 : la maison 1 de Doublonville (dialogues et PNJ du JOH3).
	&"goldenrod_husband_gift", &"goldenrod_radio_raphael_home"]
const MAP_TRIGGERS: Array[StringName] = [&"goldenrod_radio_impostor", &"goldenrod_radio_exit",
	&"goldenrod_radio_cenere", &"goldenrod_radio_office"]
## Drapeaux venus d'autres jalons ou systèmes (lus, jamais posés ici).
const EXTERNAL_FLAGS: Array[StringName] = [&"johto_radio_pass", &"johto_team_returned",
	&"johto_act2"]
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
		+ J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER_JOH3)) + " " \
		+ J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER_ARC))
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
			&"johto_radio_office_done", &"johto_stones_quest", &"johto_radio_reserve_key",
			&"johto_radio_staff_talked"]:
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


## `jalon-joh-pierres.md` §5.3 : le bureau n'a plus ni retour de l'équipe ni écriture ; le papier
## et la Multi Exp restent, `johto_radio_office_done` ferme la scène.
func test_office_scene_gives_the_paper_and_the_exp_share_without_the_team() -> void:
	var office := _cutscenes.get_cutscene(&"goldenrod_radio_office")
	assert_eq(office.variants.size(), 2, "Multi Exp déjà possédée ou non")
	for variant: CutsceneVariant in office.variants:
		var kinds: Array = []
		for step: CutsceneStep in variant.steps:
			kinds.append(step.kind)
		assert_eq(kinds.find(CutsceneStep.Kind.RETURN_TEAM), -1, "pas de retour de l'équipe")
		assert_eq(kinds.count(CutsceneStep.Kind.SAVE), 0, "pas d'écriture dédiée")
		assert_gt(kinds.find(CutsceneStep.Kind.GIVE), -1, "le cadeau du directeur")
	var flags := StoryFlags.new()
	flags.set_flag(&"johto_dante_revealed")
	var bag := Bag.new()
	assert_same(office.pick(flags, bag), office.variants[1], "sans Multi Exp : la Multi Exp")
	bag.add(&"exp_all", 1)
	assert_same(office.pick(flags, bag), office.variants[0], "avec : 3 Super Bonbons")
	flags.set_flag(&"johto_radio_office_done")
	assert_null(office.pick(flags, bag), "jouée une seule fois")


## JH-75 : une partie passée par l'ancien bureau n'entre jamais dans l'arc.
func test_saves_past_the_old_office_never_open_the_arc() -> void:
	var exit := _cutscenes.get_cutscene(&"goldenrod_radio_exit")
	var flags := StoryFlags.new()
	flags.set_flag(&"johto_team_returned")
	flags.set_flag(&"johto_act2")
	assert_null(exit.pick(flags, Bag.new()), "la scène du hall ne se joue pas")
	flags.set_flag(&"johto_radio_office_done")
	assert_not_null(exit.pick(flags, Bag.new()), "elle se joue après le nouveau bureau")


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


## Raccords de Doublonville (dossier §4, étapes 1 et 10 ; §11) : le haut-parleur passe D-10 (JOH3),
## T-1 tant que Cenere tient la Tour, T-37 ensuite ; la femme de D-37 remercie dès la Tour libérée.
func test_goldenrod_speaker_and_the_husband_follow_the_story() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir())
	var flags := StoryFlags.new()
	var speaker := library.get_dialogue(&"goldenrod_speaker")
	assert_eq(speaker.pick(flags).pages[0].text, "Ici Radio Doublonville…\nbonne jour…", "D-10")
	flags.set_flag(&"johto_slowpoke_well_cleared")
	assert_eq(speaker.pick(flags).pages[0].text, "Ici Radio Rocket.", "T-1")
	flags.set_flag(&"johto_cenere_defeated")
	assert_eq(speaker.pick(flags).pages[0].text,
		"Ici Radio Doublonville ! Les programmes reprennent.", "T-37")
	var woman := library.get_dialogue(&"goldenrod_house_1_woman")
	assert_eq(woman.pick(flags).pages[0].text, "Mon mari travaille à la Tour Radio.", "D-37")
	flags.set_flag(&"johto_stones_quest")
	assert_eq(woman.pick(flags).cutscene, &"goldenrod_husband_gift", "T-35")
	flags.set_flag(&"goldenrod_husband_gift")
	assert_true(woman.pick(flags).pages[0].text.begins_with("Il dort depuis hier soir."))
	var house := NpcRoster.load_for_map(&"goldenrod_house_1")
	assert_eq(house.get_spec(&"raphael").if_flags, [&"johto_stones_quest"] as Array[StringName], "T-36")
	var third := NpcRoster.load_for_map(&"goldenrod_radio_tower_3f")
	assert_true(third.get_spec(&"raphael").unless_flags.has(&"johto_stones_quest"),
		"il ne reste pas à la réserve une fois la Tour libérée")
