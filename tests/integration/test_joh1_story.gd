extends GutTest
## Histoire du jalon JOH1 (`jalon-joh1.md` §2.5, §2.6, §2.8 ; dossier JOH-02) sur les vraies
## données : les textes O-1 à O-25 du dossier **mot pour mot** (tableau du §14), la lettre de Chen
## et le mot de la mère (variantes et drapeaux), la scène du Centre (soin, nuit, `confiscate_team`
## puis `johto_team_stolen` puis `save`, matin, offre), sa reprise par la variante `auto` de
## l'infirmière, l'offre d'Orme (`rival: false`, PNJ de la salle), la scène du choix (le drapeau
## avant la réplique au jeton `{pokemon}`, dons, départ d'Orme), le garde et les PNJ datés.

const DOSSIER := "res://docs/design/dossier-joh-02-oliville.md"
## N° du dossier → dialogues (dans l'ordre) dont les pages, mises bout à bout, font le texte.
const TEXTS: Dictionary = {
	"O-2": [&"johto_letter_1"], "O-3": [&"johto_letter_2"], "O-4": [&"johto_letter_3"],
	"O-5": [&"pallet_cave_mouth"],
	"O-6": [&"sea_cave_lugia_shadow_1", &"sea_cave_lugia_shadow_2"],
	"O-7": [&"sea_cave_current_back"],
	"O-8": [&"olivine_nurse_arrival_1", &"olivine_nurse_arrival_2"],
	"O-9": [&"olivine_night_1", &"olivine_night_2", &"olivine_night_3", &"olivine_night_4"],
	"O-10": [&"olivine_nurse_morning"], "O-11": [&"storage_offline"],
	"O-12": [&"olivine_orme_arrival"], "O-13": [&"olivine_orme_offer"],
	"O-14": [&"observe_chikorita"], "O-15": [&"observe_cyndaquil"], "O-16": [&"observe_totodile"],
	"O-17": [&"olivine_orme_chosen"], "O-18": [&"olivine_orme_leaving"],
	"O-20": [&"olivine_sailor"], "O-21": [&"olivine_old_woman"], "O-22": [&"olivine_kid"],
	"O-25": [&"olivine_city_sign"],
}

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _dossier: Dictionary = {}


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	assert_true(_dialogues.load_dir(), str(_dialogues.get_errors()))
	_cutscenes = CutsceneLibrary.new()
	assert_true(_cutscenes.load_dir(), str(_cutscenes.get_errors()))
	_dossier = _read_dossier()


## Tableau du §14 : « | O-n | où | bulle / bulle | » → n° → pages (sans gras ni italique, jetons
## du dossier traduits).
func _read_dossier() -> Dictionary:
	var texts: Dictionary = {}
	for line: String in FileAccess.get_file_as_string(DOSSIER).split("\n"):
		if not line.begins_with("| O-"):
			continue
		var cells := line.split("|")
		var number := cells[1].strip_edges()
		var pages: Array[String] = []
		for bubble: String in cells[3].split(" / "):
			var text := bubble.strip_edges().replace("**", "").replace("*", "")
			text = text.replace("{joueur}", "{player}")
			pages.append(text)
		texts[number] = pages
	return texts


func _pages(id: StringName, variant: int = 0) -> Array[String]:
	var dialogue := _dialogues.get_dialogue(id)
	assert_not_null(dialogue, String(id))
	var pages: Array[String] = []
	if dialogue == null:
		return pages
	for page: DialoguePage in dialogue.variants[variant].pages:
		pages.append(page.text)
	return pages


func _steps(id: StringName, variant: int = 0) -> Array[CutsceneStep]:
	var cutscene := _cutscenes.get_cutscene(id)
	assert_not_null(cutscene, String(id))
	return cutscene.variants[variant].steps if cutscene != null else ([] as Array[CutsceneStep])


func _kinds(steps: Array[CutsceneStep]) -> Array[CutsceneStep.Kind]:
	var kinds: Array[CutsceneStep.Kind] = []
	for step: CutsceneStep in steps:
		kinds.append(step.kind)
	return kinds


func test_the_dossier_table_is_read() -> void:
	assert_eq(_dossier.size(), 25, "O-1 à O-25")
	assert_eq(_dossier["O-1"], ["Bonjour, Maître de la Ligue !", "Le Professeur Chen est passé ce matin.",
		"Il voudrait te voir au labo, ça avait l'air important."] as Array[String])


func test_dialogue_texts_are_the_dossier_texts_word_for_word() -> void:
	for number: String in TEXTS:
		var pages: Array[String] = []
		for id: StringName in TEXTS[number]:
			pages.append_array(_pages(id))
		assert_eq(pages, _dossier[number], number)
	# O-1 : la mère, deuxième variante (après la Ligue, avant la lettre).
	var mom := _dialogues.get_dialogue(&"mom").variants[1]
	assert_eq(mom.if_flags, [&"league_champion_defeated"] as Array[StringName])
	assert_eq(mom.unless_flags, [&"johto_letter_read"] as Array[StringName])
	assert_eq(_pages(&"mom", 1), _dossier["O-1"])
	# O-19 : le garde avant le choix.
	var guard := _dialogues.get_dialogue(&"olivine_guard")
	assert_eq(guard.variants[0].unless_flags, [&"johto_starter_chosen"] as Array[StringName])
	assert_eq(_pages(&"olivine_guard", 0), _dossier["O-19"])
	assert_true(guard.variants[1].draft, "réplique après le choix : [D] à relire")
	# O-23, O-24 : descriptions des zones.
	var zones := ZoneLibrary.new()
	zones.load_file()
	assert_eq([zones.get_zone(&"olivine_city").description], _dossier["O-23"])
	assert_eq([zones.get_zone(&"sea_cave").description], _dossier["O-24"])
	# Locuteurs.
	assert_eq(_dialogues.get_dialogue(&"olivine_orme_arrival").speaker, "Prof. Orme")
	assert_eq(_dialogues.get_dialogue(&"olivine_nurse_morning").speaker, "Infirmière")
	assert_eq(_dialogues.get_dialogue(&"johto_letter_1").speaker, "Prof. Chen")


func test_chen_reads_the_letter_after_the_gifts_then_reminds_the_way() -> void:
	var waiting := _dialogues.get_dialogue(&"oak_lab_waiting").variants
	var letter: DialogueVariant = null
	var reminder: DialogueVariant = null
	for variant: DialogueVariant in waiting:
		if variant.cutscene == &"johto_letter":
			letter = variant
		elif variant.if_flags == ([&"johto_letter_read"] as Array[StringName]):
			reminder = variant
	assert_not_null(letter)
	assert_eq(letter.if_flags, [&"league_champion_defeated", &"oak_post_league_gifts_done"]
		as Array[StringName], "après les cadeaux du J32 [D]")
	assert_eq(letter.unless_flags, [&"johto_letter_read"] as Array[StringName])
	assert_not_null(reminder)
	assert_eq(reminder.unless_flags, [&"johto_arrived"] as Array[StringName])
	assert_true(waiting.find(letter) < waiting.find(reminder), "la lettre d'abord")
	var steps := _steps(&"johto_letter")
	var set_at := -1
	var last_dialogue := -1
	for i: int in steps.size():
		if steps[i].kind == CutsceneStep.Kind.SET_FLAGS:
			set_at = i
			assert_eq(steps[i].flags, [&"johto_letter_read"] as Array[StringName])
		if steps[i].kind == CutsceneStep.Kind.DIALOGUE:
			last_dialogue = i
	assert_true(set_at > 0 and set_at < last_dialogue, "drapeau posé avant O-4")


func test_center_arrival_scene_heals_steals_in_one_write_and_opens_the_offer() -> void:
	var cutscene := _cutscenes.get_cutscene(&"olivine_center_arrival")
	assert_eq(cutscene.variants[0].if_flags, [&"johto_arrived"] as Array[StringName])
	assert_eq(cutscene.variants[0].unless_flags, [&"johto_slept"] as Array[StringName])
	var steps := _steps(&"olivine_center_arrival")
	var kinds := _kinds(steps)
	var heal := _dialogues.get_dialogue(&"olivine_nurse_arrival_1").variants[0]
	assert_eq(heal.action, &"center_heal", "soin du Centre : point de repos enregistré")
	var slept := kinds.find(CutsceneStep.Kind.SET_FLAGS)
	assert_eq(steps[slept].flags, [&"johto_slept"] as Array[StringName])
	var first_map := kinds.find(CutsceneStep.Kind.CHANGE_MAP)
	assert_true(first_map > slept, "la chambre après le drapeau")
	assert_eq(steps[first_map].map_id, &"olivine_center_room")
	assert_eq(steps[first_map].spawn, &"lit")
	var theft := kinds.find(CutsceneStep.Kind.CONFISCATE_TEAM)
	var save := kinds.find(CutsceneStep.Kind.SAVE)
	# QA A17 (2026-11-04) : le drapeau du matin est posé AVANT l'écriture, sinon une coupure juste
	# après l'écriture reprend dans une chambre de nuit sans Orme ni infirmière (impasse).
	var stolen := theft + 1
	assert_true(theft > first_map, "le vol dans la chambre")
	assert_eq(steps[stolen].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(steps[stolen].flags, [&"johto_team_stolen"] as Array[StringName])
	assert_eq(save, stolen + 1, "vol, drapeau du matin, puis une seule écriture")
	var raised := 0
	for step: CutsceneStep in steps:
		if step.kind == CutsceneStep.Kind.SET_FLAGS and step.flags.has(&"johto_team_stolen"):
			raised += 1
	assert_eq(raised, 1, "drapeau du matin posé une seule fois")
	var second_map := kinds.rfind(CutsceneStep.Kind.CHANGE_MAP)
	assert_true(second_map > stolen, "la chambre recharge au matin")
	assert_eq(steps[-1].kind, CutsceneStep.Kind.SET_FLAGS)
	assert_eq(steps[-1].flags, [&"johto_starter_offered"] as Array[StringName])
	# Les silhouettes : deux Sbires créés puis retirés avant le vol.
	var spawned: Array[StringName] = []
	var despawned: Array[StringName] = []
	for i: int in theft:
		if steps[i].kind == CutsceneStep.Kind.SPAWN:
			spawned.append(steps[i].spec.id)
			assert_true(String(steps[i].spec.sprite).begins_with("rocket_grunt"), "silhouette de Sbire")
		if steps[i].kind == CutsceneStep.Kind.DESPAWN:
			despawned.append(steps[i].actor)
	assert_eq(spawned.size(), 2)
	assert_eq(despawned.size(), 2)


func test_the_morning_replays_from_the_nurse_auto_variant_after_a_cut() -> void:
	var wake := _dialogues.get_dialogue(&"olivine_nurse_wake").variants[0]
	assert_true(wake.auto)
	assert_eq(wake.cutscene, &"olivine_morning")
	assert_eq(wake.unless_flags, [&"johto_starter_offered"] as Array[StringName])
	var morning := _cutscenes.get_cutscene(&"olivine_morning")
	assert_eq(morning.variants[0].if_flags, [&"johto_team_stolen"] as Array[StringName])
	assert_eq(morning.variants[0].unless_flags, [&"johto_starter_offered"] as Array[StringName])
	# Les étapes du matin sont celles de la fin de la scène de l'arrivée (dupliquées [D]).
	var arrival := _steps(&"olivine_center_arrival")
	var tail := arrival.slice(arrival.size() - _steps(&"olivine_morning").size())
	var morning_steps := _steps(&"olivine_morning")
	for i: int in morning_steps.size():
		assert_eq(morning_steps[i].kind, tail[i].kind, "étape %d" % i)
		assert_eq(morning_steps[i].dialogue_id, tail[i].dialogue_id, "étape %d" % i)
	# PNJ de la salle : infirmière, Orme, les trois Pokémon, présents une fois l'équipe volée.
	var roster := NpcRoster.load_for_map(&"olivine_center_room")
	var ids: Array[StringName] = []
	for spec: NpcSpec in roster.get_all():
		ids.append(spec.id)
		assert_eq(spec.if_flags, [&"johto_team_stolen"] as Array[StringName], String(spec.id))
	assert_eq(ids, [&"chikorita", &"cyndaquil", &"totodile", &"orme", &"infirmiere"]
		as Array[StringName])
	assert_eq(roster.get_spec(&"infirmiere").unless_flags, [&"johto_starter_offered"]
		as Array[StringName])
	assert_eq(roster.get_spec(&"orme").unless_flags, [&"johto_orme_left"] as Array[StringName])


func test_orme_offer_has_no_rival_and_its_pokemon_stand_on_the_table() -> void:
	var offer := StarterOffer.new()
	assert_true(offer.load_file(StarterOffer.JOHTO_DATA_PATH), str(offer.get_errors()))
	var data := PokemonData.new()
	data.load_dir()
	assert_true(offer.check_species(data))
	assert_false(offer.rival, "aucun Pokémon pour le rival (cadre §5.7)")
	assert_eq(offer.map_id, &"olivine_center_room")
	assert_eq(offer.level, 5)
	assert_eq(offer.open_flag, &"johto_starter_offered")
	assert_eq(offer.done_flag, &"johto_starter_chosen")
	assert_eq(offer.chosen_scene, &"johto_starter_chosen")
	assert_eq(offer.female_flag, &"johto_starter_female")
	assert_eq(offer.get_species_ids(), [&"chikorita", &"cyndaquil", &"totodile"] as Array[StringName])
	var roster := NpcRoster.load_for_map(&"olivine_center_room")
	var map := (load(MapCatalog.scene_path(&"olivine_center_room")) as PackedScene).instantiate() \
		as GameMap
	for option: StarterOption in offer.get_choices():
		var spec := roster.get_spec(option.npc)
		assert_not_null(spec, String(option.npc))
		assert_eq(spec.species, option.species)
		assert_eq(spec.verb, Interaction.Kind.OBSERVE)
		assert_eq(spec.lift, 56, "sur la table, comme au labo")
		assert_eq(spec.unless_flags, [StarterChoice.taken_flag(option.species)] as Array[StringName])
		assert_true(map.get_grid().is_solid(spec.cell), "%s : sur la table" % option.npc)
	assert_true(map.has_spawn(&"lit"))
	assert_true(map.has_spawn(&"from_stairs"))
	assert_eq(map.light_profile, &"johto_auto", "nuit puis matin dans la chambre")
	map.free()
	assert_eq(StarterChoice.get_set_flags(offer), [&"taken_chikorita", &"taken_cyndaquil",
		&"taken_totodile", &"johto_starter_female"] as Array[StringName])


func test_choice_scene_sets_the_flag_before_orme_names_the_pokemon_then_orme_leaves() -> void:
	var steps := _steps(&"johto_starter_chosen")
	var kinds := _kinds(steps)
	var chosen := -1
	var named := -1
	var left := -1
	var gifts: Dictionary = {}
	for i: int in steps.size():
		var step := steps[i]
		if step.kind == CutsceneStep.Kind.SET_FLAGS and step.flags.has(&"johto_starter_chosen"):
			chosen = i
		if step.kind == CutsceneStep.Kind.DIALOGUE and step.dialogue_id == &"olivine_orme_chosen":
			named = i
		if step.kind == CutsceneStep.Kind.SET_FLAGS and step.flags.has(&"johto_orme_left"):
			left = i
		if step.kind == CutsceneStep.Kind.GIVE:
			gifts[step.item_id] = step.count
	assert_true(chosen >= 0 and named > chosen, "le Pokémon entre dans l'équipe avant {pokemon}")
	assert_eq(gifts, {&"poke_ball": 5, &"potion": 1})
	assert_eq(left, steps.size() - 1, "johto_orme_left ferme la scène (heure réelle)")
	assert_true(kinds.has(CutsceneStep.Kind.HOP), "le starter descend de la table")
	assert_eq(_cutscenes.get_cutscene(&"johto_starter_chosen").variants[0].unless_flags,
		[&"johto_orme_left"] as Array[StringName])
	assert_true(DialogueTokens.tokens_in(_pages(&"olivine_orme_chosen")[0]).has(DialogueTokens.POKEMON))


func test_guard_and_dated_townsfolk() -> void:
	var city := NpcRoster.load_for_map(&"olivine_city")
	var guard := city.get_spec(&"garde_est")
	assert_eq(guard.cell, Vector2i(47, 21))
	assert_eq(guard.moved_cell, Vector2i(47, 19), "rangé hors de l'avenue après le choix")
	assert_eq(guard.moved_if_flags, [&"johto_starter_chosen"] as Array[StringName])
	var sailor := city.get_spec(&"marin_port")
	assert_eq(sailor.if_periods, [&"day", &"night"] as Array[StringName], "en mer le matin [D]")
	var kid := NpcRoster.load_for_map(&"olivine_house_2").get_spec(&"enfant")
	assert_eq(kid.if_periods, [&"morning", &"day"] as Array[StringName], "couché la nuit [D]")
	assert_eq(NpcRoster.load_for_map(&"olivine_house_1").get_all().size(), 1)
	var block := _cutscenes.get_cutscene(&"olivine_guard_block")
	assert_eq(block.variants[0].unless_flags, [&"johto_starter_chosen"] as Array[StringName])
	var kinds := _kinds(_steps(&"olivine_guard_block"))
	assert_true(kinds.has(CutsceneStep.Kind.DIALOGUE) and kinds[-1] == CutsceneStep.Kind.MOVE,
		"O-19 puis un pas en arrière")
	var arrival := _cutscenes.get_cutscene(&"olivine_arrival")
	assert_eq(arrival.variants[0].unless_flags, [&"johto_arrived"] as Array[StringName])
	assert_eq(_steps(&"olivine_arrival")[0].flags, [&"johto_arrived"] as Array[StringName])
