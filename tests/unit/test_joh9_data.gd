extends GutTest
## Chapitre Johto, JOH9 (`docs/tech/jalon-joh9.md`) : données générées depuis les grilles
## (`tools/gen_joh9_data.py`) : textes A-1 à A-54 du dossier joh-10 §16 mot pour mot, Dresseurs §6,
## Dante (2), rival final par starter (§9, JH-59), rencontres par moment §5, scènes du relais, du
## 2F, du sommet, du poste et de l'épilogue, générique de Johto, textes de Flash par grotte. Les
## grands registres écartent les fichiers `joh9_*` (préfixe dans `j22_ids.gd`).

const J22Ids := preload("res://tests/helpers/j22_ids.gd")

const PREFIX := "joh9_"
const DOSSIER := "res://docs/design/dossier-joh-10-mont-argente.md"
## Dossier §6 : Dresseur → (nom, équipe).
const TRAINERS: Dictionary = {
	&"silver_trail_hiker_baptiste": ["Montagnard Baptiste", [[&"golem", 64], [&"donphan", 64]]],
	&"silver_trail_cooltrainer_ines": ["Topdresseuse Inès", [[&"skarmory", 64], [&"ampharos", 64],
		[&"espeon", 65]]],
	&"silver_trail_blackbelt_hugo": ["Karatéka Hugo", [[&"machamp", 65], [&"ursaring", 65]]],
	&"mt_silver_1f_grunt_x": ["Sbire Rocket", [[&"houndoom", 66], [&"muk", 66]]],
	&"mt_silver_1f_grunt_y": ["Sbire Rocket", [[&"sneasel", 66], [&"weezing", 66], [&"arbok", 66]]],
	&"mt_silver_3f_hiker_lucas": ["Montagnard Lucas", [[&"steelix", 67], [&"ursaring", 67]]],
	&"route_28_topdresseur_jules": ["Topdresseur Jules", [[&"tyranitar", 68], [&"skarmory", 66],
		[&"arcanine", 66]]],
	&"mt_silver_dante_2": ["Dante", [[&"houndoom", 72], [&"sneasel", 73], [&"magmar", 74],
		[&"scizor", 74], [&"arcanine", 76], [&"tyranitar", 78]]],
}
## Dossier §5 : table → (moments, niveaux, poids).
const TABLES: Dictionary = {
	&"silver_trail_grass_day": [[&"morning", &"day"], [52, 56],
		{&"teddiursa": 25, &"phanpy": 20, &"skarmory": 15, &"golem": 20, &"machoke": 20}],
	&"silver_trail_grass_night": [[&"night"], [52, 56],
		{&"houndoom": 25, &"sneasel": 20, &"noctowl": 25, &"golem": 15, &"machoke": 15}],
	&"mt_silver_outside_grass_day": [[&"morning", &"day"], [56, 60],
		{&"ursaring": 25, &"donphan": 25, &"skarmory": 20, &"sneasel": 15}],
	&"mt_silver_outside_grass_night": [[&"night"], [56, 60],
		{&"ursaring": 25, &"donphan": 25, &"skarmory": 20, &"sneasel": 30, &"houndoom": 15}],
	&"mt_silver_1f_rubble": [[], [58, 62],
		{&"ursaring": 25, &"donphan": 20, &"onix": 20, &"golbat": 25, &"machoke": 10}],
	&"mt_silver_1f_water": [[], [58, 62],
		{&"tentacruel": 30, &"gyarados": 20, &"dewgong": 30, &"seel": 20}],
	&"mt_silver_2f_rubble": [[], [60, 64],
		{&"golbat": 30, &"ursaring": 25, &"donphan": 20, &"onix": 20, &"larvitar": 5}],
	&"mt_silver_3f_rubble": [[], [62, 65],
		{&"ursaring": 30, &"donphan": 25, &"golbat": 25, &"machamp": 15, &"pupitar": 5}],
	&"route_28_grass_day": [[&"morning", &"day"], [55, 60],
		{&"phanpy": 30, &"donphan": 20, &"skarmory": 20, &"ponyta": 15, &"rapidash": 15}],
}
## Nom affiché du starter du rival dans A-12 (« {pokemon} »).
const RIVAL_STARTER_NAMES: Array[String] = ["Dracaufeu", "Tortank", "Florizarre"]

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _pokemon: PokemonData
var _trainers: TrainerLibrary
var _encounters: EncounterLibrary
var _items: ItemLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()
	_encounters = EncounterLibrary.new(_pokemon)
	_encounters.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()


func _ids(dir: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(J22Ids.in_dir(dir, PREFIX).keys())
	ids.sort()
	return ids


func _flat_dossier() -> String:
	return J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER)).replace("{joueur}", "{player}")


func _scene_steps(scene: StringName, variant: int = 0) -> Array[CutsceneStep]:
	var cutscene := _cutscenes.get_cutscene(scene)
	assert_not_null(cutscene, String(scene))
	if cutscene == null or cutscene.variants.size() <= variant:
		return []
	return cutscene.variants[variant].steps


func _kinds(steps: Array[CutsceneStep]) -> Array[int]:
	var kinds: Array[int] = []
	for step: CutsceneStep in steps:
		kinds.append(step.kind)
	return kinds


func _dialogues_of(steps: Array[CutsceneStep]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for step: CutsceneStep in steps:
		if step.kind == CutsceneStep.Kind.DIALOGUE:
			ids.append(step.dialogue_id)
	return ids


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_encounters.get_errors(), PackedStringArray())
	assert_gt(_ids("res://data/dialogues/").size(), 60)
	assert_eq(_ids("res://data/cutscenes/").size(), 11)


## Chaque réplique non marquée « draft » est dans le dossier joh-10 §16, mot pour mot (le nom du
## starter du rival est le « {pokemon} » de A-12).
func test_every_validated_line_is_in_dossier_joh_10() -> void:
	var dossier := _flat_dossier()
	var checked := 0
	for id: StringName in _ids("res://data/dialogues/"):
		var dialogue := _dialogues.get_dialogue(id)
		if dialogue.draft:
			continue
		for variant: DialogueVariant in dialogue.variants:
			if variant.draft:
				continue
			for page: DialoguePage in variant.pages:
				var text := J22Ids.flat_text(page.text)
				for name: String in RIVAL_STARTER_NAMES:
					text = text.replace("Allez, %s !" % name, "Allez, {pokemon} !")
				checked += 1
				assert_true(dossier.contains(text), "%s : « %s »" % [id, text])
	assert_gt(checked, 120)


## A-17 (Flash du 2F) et A-16 (sans Flash) : textes propres à la grotte obscure du Mont Argenté.
func test_dark_floor_texts_are_a16_and_a17() -> void:
	var caves := CaveLibrary.new()
	assert_true(caves.load_file())
	assert_true(caves.is_dark(&"mt_silver_2f"))
	assert_false(caves.is_dark(&"mt_silver_1f"))
	assert_eq(caves.flash_cue(&"mt_silver_2f"), "{pokemon} éclaire la grotte avec Flash !")
	assert_true(_flat_dossier().contains(caves.flash_cue(&"mt_silver_2f")))
	assert_eq(caves.warn_dialogue(&"mt_silver_2f"), &"mt_silver_2f_dark")
	assert_eq(caves.flash_cue(&"dark_cave_1f"), "", "Grotte Sombre : le bandeau de la capacité")
	var warn := _dialogues.get_dialogue(&"mt_silver_2f_dark")
	assert_eq(J22Ids.flat_text(warn.variants[0].pages[0].text), "Il fait noir comme dans un four.")


func test_trainers_follow_the_dossier() -> void:
	for id: StringName in TRAINERS:
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.name, TRAINERS[id][0], String(id))
		var team: Array = []
		for member: TrainerSlot in trainer.team:
			team.append([member.species, member.level])
		assert_eq(team, TRAINERS[id][1], String(id))
	assert_eq(_trainers.get_trainer(&"mt_silver_dante_2").ai, &"smart")


## §9, JH-59 : rang 1 à 3 communs (Steelix à la place de Rhinoféros), 4 et 5 de la Ligue selon le
## starter, son starter évolué au niveau 80 ; 75 à 80.
func test_rival_final_team_by_starter() -> void:
	var rival := _trainers.get_trainer(&"mt_silver_rival_final")
	assert_not_null(rival)
	var finals := {&"bulbasaur": &"charizard", &"charmander": &"blastoise", &"squirtle": &"venusaur"}
	for starter: StringName in finals:
		var team := rival.team_for(starter)
		assert_eq(team.size(), 6, String(starter))
		var species: Array[StringName] = []
		var levels: Array[int] = []
		for member: TrainerSlot in team:
			species.append(member.species)
			levels.append(member.level)
		assert_eq(species.slice(0, 3), [&"pidgeot", &"alakazam", &"steelix"] as Array[StringName])
		assert_eq(species[5], finals[starter], String(starter))
		assert_false(species.has(&"rhydon"))
		assert_eq(levels, [75, 76, 76, 77, 77, 80] as Array[int], String(starter))
		var league := _trainers.get_trainer(&"rival_champion").team_for(starter)
		assert_eq([species[3], species[4]], [league[3].species, league[4].species], String(starter))


func test_encounter_tables_follow_the_dossier() -> void:
	for id: StringName in TABLES:
		var table := _encounters.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		var expected: Array = TABLES[id]
		var periods: Array[StringName] = []
		periods.assign(expected[0])
		assert_eq(table.periods, periods, String(id))
		var weights: Dictionary = {}
		for slot: EncounterSlot in table.slots:
			weights[slot.species] = slot.weight
			assert_eq([slot.min_level, slot.max_level], expected[1], "%s %s" % [id, slot.species])
		assert_eq(weights, expected[2], String(id))


func test_relay_scene_sets_its_flag_first_and_enters_the_cave() -> void:
	var steps := _scene_steps(&"mt_silver_relay")
	assert_eq(steps[0].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(steps[0].flags, [&"johto_rival_relay"] as Array[StringName])
	assert_eq(_dialogues_of(steps), [&"mt_silver_brace_block", &"mt_silver_cenere_block",
		&"mt_silver_rival_offscreen", &"mt_silver_rival_arrives", &"mt_silver_rival_relay",
		&"mt_silver_rival_to_admins", &"mt_silver_enter_cave"] as Array[StringName])
	assert_eq(steps[-1].kind, CutsceneStep.Kind.CHANGE_MAP)
	assert_eq(steps[-1].map_id, &"mt_silver_1f")


func test_second_floor_rival_heals_the_team() -> void:
	var steps := _scene_steps(&"mt_silver_2f_rival")
	assert_eq(steps[0].flags, [&"johto_rival_healed"] as Array[StringName])
	assert_has(_dialogues_of(steps), &"mt_silver_2f_rival_heal")
	assert_eq(_dialogues.get_dialogue(&"mt_silver_2f_rival_heal").variants[0].action, &"heal")


## Sommet : Dante (A-23, A-26 à A-28 ou A-25), Giovanni, Cenere, sauvegarde, puis le rival ; une
## variante pour la reprise après Dante, une pour le retour après une défaite contre le rival.
func test_summit_scene_order_and_resumes() -> void:
	var cutscene := _cutscenes.get_cutscene(&"mt_silver_summit")
	assert_eq(cutscene.variants.size(), 3)
	var first := _scene_steps(&"mt_silver_summit", 0)
	var dialogues := _dialogues_of(first)
	var order: Array[StringName] = [&"mt_silver_summit_arrival", &"mt_silver_dante_welcome",
		&"mt_silver_dante_before", &"mt_silver_dante_defeated", &"mt_silver_giovanni_hello",
		&"mt_silver_giovanni_to_player", &"mt_silver_cenere_stays",
		&"mt_silver_rival_arrives_summit", &"mt_silver_rival_defeated", &"mt_silver_rival_race"]
	var last := -1
	for id: StringName in order:
		var at := dialogues.find(id)
		assert_gt(at, last, String(id))
		last = at
	var battles: Array[StringName] = []
	var saves := 0
	for step: CutsceneStep in first:
		if step.kind == CutsceneStep.Kind.BATTLE:
			battles.append(step.trainer_id)
		elif step.kind == CutsceneStep.Kind.SAVE:
			saves += 1
	assert_eq(battles, [&"mt_silver_dante_2", &"mt_silver_rival_final"] as Array[StringName])
	assert_eq(saves, 1, "sauvegarde entre Giovanni et le rival (dossier §13)")
	var back := _scene_steps(&"mt_silver_summit", 2)
	assert_has(_dialogues_of(back), &"mt_silver_rival_return")
	assert_does_not_have(_dialogues_of(back), &"mt_silver_dante_welcome")


func test_route_28_gate_scenes() -> void:
	var check := _cutscenes.get_cutscene(&"route_28_gate_check")
	assert_eq(check.variants[0].unless_flags, [&"johto_route28_open"] as Array[StringName])
	var south := _cutscenes.get_cutscene(&"route_28_gate_south")
	assert_eq(south.variants.size(), 2)
	assert_eq(south.variants[0].unless_flags, [&"johto_rival_final_done"] as Array[StringName])
	assert_eq(south.variants[1].if_flags, [&"johto_rival_final_done"] as Array[StringName])
	assert_has(_dialogues_of(south.variants[1].steps), &"route_28_gate_opens")


func test_epilogue_gives_the_green_ball_and_plays_the_johto_credits() -> void:
	var cutscene := _cutscenes.get_cutscene(&"johto_epilogue")
	assert_eq(cutscene.variants[0].if_flags,
		[&"johto_giovanni_seen", &"johto_rival_final_done"] as Array[StringName])
	assert_eq(cutscene.variants[0].unless_flags, [&"johto_chapter_done"] as Array[StringName])
	var steps := cutscene.variants[0].steps
	var gives: Array[StringName] = []
	var credits := ""
	for step: CutsceneStep in steps:
		if step.kind == CutsceneStep.Kind.GIVE:
			gives.append(step.item_id)
		elif step.kind == CutsceneStep.Kind.CREDITS:
			credits = step.text
	assert_eq(gives, [&"green_ball"] as Array[StringName])
	assert_eq(credits, "johto")
	assert_eq(steps[-1].kind, CutsceneStep.Kind.SAVE)
	assert_not_null(_items.get_item(&"green_ball"))
	var data := CreditsData.new()
	assert_true(data.load_file(CreditsData.NAMED_PATH % "johto"), str(data.get_errors()))
	assert_gt(data.block_count(), 10)


func test_epilogue_leaves_nobody_in_front_of_the_lab_exit() -> void:
	# QA A17 : le rival, sur (7,9), bloquait la seule sortie du labo après le générique.
	var steps := _cutscenes.get_cutscene(&"johto_epilogue").variants[0].steps
	var present: Array[StringName] = []
	var credits_at := -1
	for i: int in steps.size():
		var step: CutsceneStep = steps[i]
		if step.kind == CutsceneStep.Kind.SPAWN:
			present.append(step.actor)
		elif step.kind == CutsceneStep.Kind.DESPAWN:
			present.erase(step.actor)
		elif step.kind == CutsceneStep.Kind.CREDITS:
			credits_at = i
			assert_eq(present, [] as Array[StringName], "personnages retirés avant le générique")
	assert_gt(credits_at, 0)


func test_celebi_scene_is_a_catchable_level_60_encounter() -> void:
	var steps := _scene_steps(&"ilex_altar_celebi")
	var battle := steps[-1]
	assert_eq(battle.kind, CutsceneStep.Kind.WILD_BATTLE)
	assert_eq(battle.species, &"celebi")
	assert_eq(battle.level, 60)
