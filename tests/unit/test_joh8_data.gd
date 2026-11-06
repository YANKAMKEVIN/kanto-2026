extends GutTest
## Chapitre Johto, JOH8 (`docs/tech/jalon-joh8.md`) : données générées depuis les grilles
## (`tools/gen_joh8_data.py`) : textes H-1 à H-38 du dossier joh-09 §15 mot pour mot, Dresseurs
## §6, Dante (1) (JH-54), objets §7, scènes du sommet (§4, étapes 5 à 10), drapeaux §11,
## variantes du doyen, départs de débogage. Les grands registres écartent les fichiers `joh8_*`.

const J22Ids := preload("res://tests/helpers/j22_ids.gd")

const PREFIX := "joh8_"
const DOSSIER := "res://docs/design/dossier-joh-09-tour-carillon.md"
const MAPS: Array[StringName] = [&"bell_tower_woods", &"bell_tower_1f", &"bell_tower_2f",
	&"bell_tower_roof"]
## Dossier §6 : Dresseur → (carte, équipe).
const TRAINERS: Dictionary = {
	&"bell_tower_grunt_watch": [&"bell_tower_woods", [[&"weezing", 60], [&"arbok", 60]]],
	&"bell_tower_grunt_v": [&"bell_tower_1f", [[&"houndoom", 61], [&"golbat", 61]]],
	&"bell_tower_grunt_w": [&"bell_tower_2f",
		[[&"muk", 61], [&"noctowl", 61], [&"houndour", 60]]],
}
## JH-54 : Dante (1), cinq Pokémon (64–68), sans Tyranocif.
const DANTE_TEAM: Array = [[&"houndoom", 64], [&"magmar", 65], [&"scizor", 66], [&"sneasel", 66],
	[&"arcanine", 68]]
## Dossier §7 : objet visible → (carte, objet, nombre).
const ITEMS: Dictionary = {
	&"bell_tower_woods_hyper_potions": [&"hyper_potion", 2],
	&"bell_tower_1f_rappel_max": [&"max_revive", 1],
	&"bell_tower_2f_pp_plus": [&"pp_up", 1],
}
## Dossier §11.
const FLAGS: Array[StringName] = [&"johto_bell_tower_open", &"johto_dante_met",
	&"johto_dante_defeated_1", &"johto_ho_oh_seen", &"johto_dante_fled_1", &"johto_entei_done",
	&"johto_ho_oh_done", &"johto_act3"]
const DEBUG_STARTS: Array[String] = ["johto_bell_tower_rosalia", "johto_bell_tower_woods",
	"johto_bell_tower_woods_night", "johto_bell_tower_roof_night",
	"johto_bell_tower_1f", "johto_bell_tower_2f", "johto_bell_tower_roof", "johto_bell_tower_roof_autosave",
	"johto_bell_tower_entei", "johto_bell_tower_after"]

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _pokemon: PokemonData
var _items: ItemLibrary
var _trainers: TrainerLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_pokemon = PokemonData.new()
	_pokemon.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_trainers = TrainerLibrary.new(_pokemon)
	_trainers.load_dir()


func _ids(dir: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(J22Ids.in_dir(dir, PREFIX).keys())
	ids.sort()
	return ids


func _all_steps(scene: StringName) -> Array[CutsceneStep]:
	var steps: Array[CutsceneStep] = []
	var cutscene := _cutscenes.get_cutscene(scene)
	assert_not_null(cutscene, String(scene))
	if cutscene != null:
		for variant: CutsceneVariant in cutscene.variants:
			steps.append_array(variant.steps)
	return steps


func _first(steps: Array[CutsceneStep], kind: CutsceneStep.Kind,
		key: StringName = &"") -> CutsceneStep:
	for step: CutsceneStep in steps:
		if step.kind != kind:
			continue
		if key.is_empty() or step.species == key or step.trainer_id == key \
				or step.dialogue_id == key:
			return step
	return null


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_items.get_errors(), PackedStringArray())
	assert_gt(_ids("res://data/dialogues/").size(), 50)
	assert_gt(_ids("res://data/cutscenes/").size(), 8)


## Chaque réplique non marquée « draft » est dans le dossier joh-09 §15, mot pour mot.
func test_every_validated_line_is_in_dossier_joh_09() -> void:
	var dossier := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER))
	dossier = dossier.replace("{joueur}", "{player}")
	var checked := 0
	for id: StringName in _ids("res://data/dialogues/"):
		var dialogue := _dialogues.get_dialogue(id)
		if dialogue.draft:
			continue
		for variant: DialogueVariant in dialogue.variants:
			if variant.draft:
				continue
			for page: DialoguePage in variant.pages:
				checked += 1
				assert_true(dossier.contains(J22Ids.flat_text(page.text)),
					"%s : « %s » (dossier joh-09 §15)" % [id, page.text])
	assert_gt(checked, 75)


## Le doyen ouvre la tour (H-2, H-3) puis, après le sommet, annonce le Mont Argenté (H-34) ;
## ses variantes du JOH8 passent avant les autres (JOH2, JOH6).
func test_elder_variants_open_the_tower_and_raise_act3() -> void:
	if not _dialogues.has_dialogue(&"ecruteak_elders_house_doyen"):
		pending("Doyen du JOH2 pas encore fusionné")
		return
	var doyen := _dialogues.get_dialogue(&"ecruteak_elders_house_doyen")
	var after := doyen.variants[0]
	assert_eq(after.if_flags, [&"johto_ho_oh_done"] as Array[StringName])
	assert_true(after.set_flags.has(&"johto_act3"))
	var opening := doyen.variants[1]
	assert_eq(opening.if_flags, [&"johto_bell_tower_clue"] as Array[StringName])
	assert_eq(opening.unless_flags, [&"johto_bell_tower_open"] as Array[StringName])
	assert_true(opening.set_flags.has(&"johto_bell_tower_open"))
	assert_eq(opening.pages[0].text, "Te voilà enfin.")
	var city := NpcRoster.load_for_map(&"ecruteak_city")
	var sage := city.get_spec(&"sage_blesse")
	assert_not_null(sage, "sage blessé (H-1)")
	if sage != null:
		assert_eq(sage.cell, Vector2i(44, 13))
		assert_eq(sage.if_flags, [&"johto_bell_tower_clue"] as Array[StringName])
		assert_eq(sage.unless_flags, [&"johto_bell_tower_open"] as Array[StringName])
	var guard := city.get_spec(&"garde_carillon")
	assert_true(guard.unless_flags.has(&"johto_bell_tower_open"), "le garde s'efface")
	var orme := NpcRoster.load_for_map(&"ecruteak_center").get_spec(&"orme")
	assert_not_null(orme, "Orme au Centre (H-35)")


func test_every_scene_is_launched_and_every_dialogue_used() -> void:
	var launched: Dictionary = {}
	var used: Dictionary = {}
	for id: StringName in _dialogues.get_ids():
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				launched[variant.cutscene] = true
	for id: StringName in _cutscenes.get_dialogue_ids():
		used[id] = true
	for map_id: StringName in MAPS:
		var map := (load("res://game/world/maps/%s.tscn" % map_id) as PackedScene).instantiate()
		for point: Node in map.get_node(^"Triggers").get_children():
			launched[(point as EventTriggerPoint).cutscene_id] = true
		for point: Node in map.get_node(^"Interactables").get_children():
			var dialogue: StringName = point.get(&"dialogue_id")
			used[dialogue] = true
			assert_true(_dialogues.has_dialogue(dialogue), "%s : %s" % [map_id, dialogue])
		map.free()
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			if not spec.dialogue.is_empty():
				used[spec.dialogue] = true
				assert_true(_dialogues.has_dialogue(spec.dialogue), "%s : %s" % [map_id,
					spec.dialogue])
			if not spec.trainer_id.is_empty():
				used[spec.before_dialogue] = true
				used[spec.defeated_dialogue] = true
	# Rosalia (fichiers du JOH2) et Diane (JOH6) : voir test_elder_variants_… et le plan §2.7.
	for id: StringName in [&"joh8_sage_blesse", &"joh8_habitante_aube", &"joh8_orme",
			&"joh8_entei_return"]:
		used[id] = true
	for id: StringName in _ids("res://data/cutscenes/"):
		assert_true(launched.has(id), "scène « %s » lancée" % id)
	for id: StringName in _ids("res://data/dialogues/"):
		assert_true(used.has(id) or launched.has(id), "dialogue « %s » utilisé" % id)


func test_grunts_follow_dossier_6() -> void:
	for id: StringName in TRAINERS:
		var placed: NpcSpec = null
		for spec: NpcSpec in NpcRoster.load_for_map(TRAINERS[id][0]).get_all():
			if spec.trainer_id == id:
				placed = spec
		assert_not_null(placed, String(id))
		assert_true(_trainers.has_trainer(id), String(id))
		if not _trainers.has_trainer(id):
			continue
		var team: Array = []
		for member: TrainerSlot in _trainers.get_trainer(id).team:
			team.append([member.species, member.level])
		assert_eq(team, TRAINERS[id][1], String(id))
	# Sbire V : sa vue (1 case, vers l'ouest) couvre (20, 4), seul accès à l'escalier.
	var v := NpcRoster.load_for_map(&"bell_tower_1f").get_spec(&"sbire_v")
	assert_eq([v.cell, v.facing, v.sight], [Vector2i(21, 4), Vector2i.LEFT, 1])


func test_dante_team_follows_jh_54() -> void:
	assert_true(_trainers.has_trainer(&"bell_tower_dante_1"))
	var dante := _trainers.get_trainer(&"bell_tower_dante_1")
	var team: Array = []
	for member: TrainerSlot in dante.team:
		team.append([member.species, member.level])
		assert_eq(member.moves.size(), 4, "%s : quatre attaques choisies" % member.species)
	assert_eq(team, DANTE_TEAM)
	assert_false(team.has([&"tyranitar", 68]))
	assert_eq(dante.ai, BattleAI.SMART)
	assert_false(dante.can_lose)


func test_visible_items_and_the_rainbow_wing() -> void:
	for scene: StringName in ITEMS:
		var give := _first(_all_steps(scene), CutsceneStep.Kind.GIVE)
		assert_not_null(give, String(scene))
		if give != null:
			assert_eq([give.item_id, give.count, give.found], [ITEMS[scene][0], ITEMS[scene][1],
				true], String(scene))
	assert_true(_items.has_item(&"rainbow_wing"))
	assert_eq(_items.get_item(&"rainbow_wing").category, ItemData.Category.KEY)
	var wing := _first(_all_steps(&"bell_tower_wing"), CutsceneStep.Kind.GIVE)
	assert_eq(wing.item_id, &"rainbow_wing")


## Ordre du sommet (§4, étapes 5 à 10) : Dante, combat, cloche, refus, fuite, Entei, Ho-Oh, plume.
func test_summit_scene_order() -> void:
	var cutscene := _cutscenes.get_cutscene(&"bell_tower_summit")
	assert_eq(cutscene.variants.size(), 1)
	var variant: CutsceneVariant = cutscene.variants[0]
	assert_eq(variant.unless_flags, [&"johto_dante_defeated_1"] as Array[StringName])
	var order: Array[String] = []
	for step: CutsceneStep in variant.steps:
		match step.kind:
			CutsceneStep.Kind.BATTLE:
				order.append("battle:" + String(step.trainer_id))
			CutsceneStep.Kind.WILD_BATTLE:
				order.append("wild:" + String(step.species))
			CutsceneStep.Kind.SET_FLAGS:
				for flag: StringName in step.flags:
					order.append("set:" + String(flag))
			CutsceneStep.Kind.GIVE:
				order.append("give:" + String(step.item_id))
	assert_eq(order, ["set:johto_dante_met", "battle:bell_tower_dante_1", "set:johto_ho_oh_seen",
		"set:johto_dante_fled_1", "wild:entei", "wild:ho_oh", "give:rainbow_wing",
		"set:got_rainbow_wing"] as Array[String])
	var battle := _first(variant.steps, CutsceneStep.Kind.BATTLE)
	assert_eq(battle.win_flags, [&"johto_dante_defeated_1"] as Array[StringName])
	assert_eq(battle.lose_flags, [&"johto_dante_lost_1"] as Array[StringName])
	var wake := _first(variant.steps, CutsceneStep.Kind.WAKE_UP)
	assert_eq(wake.unless_flags, [&"johto_dante_defeated_1"] as Array[StringName])
	# H-17 au retour après une défaite, H-14 à H-16 la première fois.
	var resume := _first(variant.steps, CutsceneStep.Kind.DIALOGUE, &"bell_tower_dante_resume")
	assert_eq(resume.if_flags, [&"johto_dante_lost_1"] as Array[StringName])


func test_legendaries_are_fixed_encounters_at_their_levels() -> void:
	var entei := _first(_all_steps(&"bell_tower_entei"), CutsceneStep.Kind.WILD_BATTLE, &"entei")
	assert_eq([entei.level, entei.actor], [60, &"entei"])
	assert_not_null(entei.static_encounter)
	assert_true(entei.flee_flags.has(&"johto_entei_done"), "fuite : Entei disparaît (§6)")
	var ho_oh := _first(_all_steps(&"bell_tower_ho_oh"), CutsceneStep.Kind.WILD_BATTLE, &"ho_oh")
	assert_eq([ho_oh.level, ho_oh.actor], [65, &"ho_oh"])
	assert_true(ho_oh.flee_flags.has(&"johto_ho_oh_done"))
	var roof := NpcRoster.load_for_map(&"bell_tower_roof")
	assert_eq(roof.get_spec(&"entei").unless_flags, [&"johto_entei_done"] as Array[StringName])
	assert_eq(roof.get_spec(&"ho_oh").if_flags, [&"johto_entei_done"] as Array[StringName])
	assert_eq(roof.get_spec(&"ho_oh").unless_flags, [&"johto_ho_oh_done"] as Array[StringName])
	assert_eq(roof.get_spec(&"dante").unless_flags, [&"johto_dante_fled_1"] as Array[StringName])


func test_flags_of_dossier_11_are_raised_somewhere() -> void:
	var raised: Dictionary = {}
	for id: StringName in _cutscenes.get_ids():
		for step: CutsceneStep in _all_steps(id):
			for flag: StringName in step.flags:
				raised[flag] = true
			for flag: StringName in step.win_flags:
				raised[flag] = true
			for flag: StringName in step.flee_flags:
				raised[flag] = true
			if step.static_encounter != null:
				raised[step.static_encounter.done_flag] = true
	for id: StringName in _dialogues.get_ids():
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			for flag: StringName in variant.set_flags:
				raised[flag] = true
	for flag: StringName in FLAGS:
		if flag == &"johto_bell_tower_open" or flag == &"johto_act3":
			if not _dialogues.has_dialogue(&"ecruteak_elders_house_doyen"):
				continue
		assert_true(raised.has(flag), String(flag))


func test_debug_starts_parse() -> void:
	for name: String in DEBUG_STARTS:
		var path := "res://tools/debug_start/%s.json" % name
		assert_true(FileAccess.file_exists(path), path)
		var start := DebugStart.new()
		assert_true(start.load_file(path, _pokemon, _items), "%s : %s" % [name, start.get_errors()])
		assert_eq(start.party.size(), 6, name)
		assert_true(start.flags.has(&"johto_lugia_done"), name)


## QA A17 : le Menu disait encore « prendre la Route 39 » au sommet de la tour.
func test_objectives_follow_the_tower() -> void:
	var library := ObjectiveLibrary.new()
	assert_true(library.load_file())
	var flags := StoryFlags.new()
	flags.set_flag(&"johto_starter_chosen")
	var steps: Array = [
		[&"johto_bell_tower_clue", &"see_ecruteak_elder"],
		[&"johto_bell_tower_open", &"climb_bell_tower"],
		[&"johto_ho_oh_done", &"report_to_ecruteak_elder"],
	]
	for step: Array in steps:
		flags.set_flag(step[0])
		assert_eq(library.current_id(flags), step[1], String(step[0]))
	flags.set_flag(&"johto_act3")
	assert_ne(library.current_id(flags), &"report_to_ecruteak_elder", "le doyen a parlé (H-34)")


## H-38 (« en plus de C-46 ») : Diane, après le sommet, une fois son don fait (JOH6).
func test_diane_after_the_summit() -> void:
	var text := FileAccess.get_file_as_string("res://data/dialogues/joh6_week.json")
	var diane: Dictionary = JSON.parse_string(text)["week_sunday_diane"]
	var variants: Array = diane["variants"]
	assert_eq(variants[0]["unless"], ["week_sunday_gift"], "le don d'abord")
	assert_eq(variants[1]["if"], ["week_sunday_gift", "johto_ho_oh_seen"])
	assert_eq(variants[1]["pages"][1], "Je n'y ai même pas touché.")
	assert_eq(variants[-1]["if"], ["week_sunday_gift"], "la réplique de fin reste la dernière")


## Cadre §4.5 : Entei non capturé revient à la Tour Cendrée après le chapitre.
func test_entei_returns_to_the_burned_tower() -> void:
	var entei := NpcRoster.load_for_map(&"burned_tower_b1f").get_spec(&"entei_retour")
	assert_not_null(entei, "Entei à la Tour Cendrée")
	var scenes: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/cutscenes/joh8_ecruteak.json"))
	var step: Dictionary = scenes["joh8_entei_return"]["variants"][0]["steps"][0]
	assert_eq(step["wild_battle"], "entei")
	assert_eq(step["actor"], "entei_retour")
	assert_eq(step["static"]["caught"], "johto_entei_caught")
