extends GutTest
## Chapitre Johto, JOH7 (`docs/tech/jalon-joh7.md`) : données générées depuis les grilles
## (`tools/gen_joh7_data.py`) : textes M-1 à M-34 du dossier JOH-08 §16 **mot pour mot**,
## Dresseurs §6, objets §7, rencontres et pêche §5, légendaires (§6, §9, §10), Oliville (marin,
## enfant, Orme), départs de débogage. Les grands registres écartent les fichiers `joh7_*`
## (préfixe dans `j22_ids.gd`).

const J22Ids := preload("res://tests/helpers/j22_ids.gd")

const PREFIX := "joh7_"
const DOSSIER := "res://docs/design/dossier-joh-08-iles-tourbillon.md"
const MAPS: Array[StringName] = [&"route_40", &"route_41", &"whirl_islands_1f", &"whirl_islands_b1f",
	&"whirl_islands_b2f"]
## N° du dossier → [dialogue, variante] dont les pages, mises bout à bout, font le texte.
const TEXTS: Dictionary = {
	"M-1": [[&"olivine_beach_sailor", 1]], "M-2": [[&"route_40_sign", 0]],
	"M-3": [[&"route_41_sign", 0]], "M-4": [[&"whirlpool_examine", 0]],
	"M-8": [[&"whirl_islands_sign", 0]], "M-11": [[&"whirl_current", 0]],
	"M-12": [[&"whirl_suicune_seen", 0]], "M-13": [[&"whirl_suicune", 0]],
	"M-14": [[&"whirl_cenere_arrival", 0]], "M-15": [[&"whirl_cenere_before", 0]],
	"M-16": [[&"whirl_cenere_defeated", 0]],
	"M-17": [[&"whirl_cenere_after", 0], [&"whirl_cenere_leaves", 0]],
	"M-18": [[&"whirl_suicune_leap_1", 0], [&"whirl_suicune_leap_2", 0]],
	"M-19": [[&"whirl_suicune_after", 0]], "M-20": [[&"whirl_b2f_current_strong", 0]],
	"M-21": [[&"whirl_b2f_current_calm", 0]], "M-22": [[&"whirl_b2f_heart", 0]],
	"M-23": [[&"whirl_lugia_rise_1", 0], [&"whirl_lugia_rise_2", 0]],
	"M-24": [[&"whirl_lugia_rise_3", 0]], "M-25": [[&"whirl_lugia_gone", 0]],
	"M-26": [[&"whirl_cove", 1]], "M-27": [[&"whirl_cove", 2]], "M-28": [[&"whirl_dragon_scale_found", 0]],
	"M-29": [[&"olivine_beach_sailor", 0]], "M-30": [[&"olivine_kid_sea", 0]],
	"M-31": [[&"olivine_orme_bell_tower", 0]], "M-32": [[&"olivine_orme_bell_tower", 1]],
	"M-33": [[&"whirl_cove", 0]], "M-34": [[&"whirl_islands_waterfall", 0]],
}
## Répliques des Dresseurs (M-5, M-6, M-10) : n° → Dresseurs de la ligne.
const TRAINER_TEXTS: Dictionary = {
	"M-5": [&"route_40_swimmer_yanis", &"route_40_swimmer_elodie", &"route_40_swimmer_marius"],
	"M-6": [&"route_41_swimmer_lea", &"route_41_swimmer_gabin", &"route_41_fisher_noe"],
	"M-10": [&"whirl_islands_grunt_t", &"whirl_islands_grunt_u"],
}
## Dossier §6 : Dresseur → (nom, équipe, carte).
const TRAINERS: Dictionary = {
	&"route_40_swimmer_yanis": ["Nageur Yanis", [[&"tentacruel", 50], [&"staryu", 49]], &"route_40"],
	&"route_40_swimmer_elodie": ["Nageuse Élodie", [[&"azumarill", 51]], &"route_40"],
	&"route_40_swimmer_marius": ["Nageur Marius", [[&"kingler", 50], [&"seadra", 50]], &"route_40"],
	&"route_41_swimmer_lea": ["Nageuse Léa", [[&"dewgong", 52], [&"starmie", 52]], &"route_41"],
	&"route_41_swimmer_gabin": ["Nageur Gabin", [[&"tentacruel", 51], [&"gyarados", 53]], &"route_41"],
	&"route_41_fisher_noe": ["Pêcheur Noé", [[&"seadra", 52], [&"seaking", 52]], &"route_41"],
	&"whirl_islands_grunt_t": ["Sbire Rocket", [[&"muk", 58], [&"arbok", 58]], &"whirl_islands_1f"],
	&"whirl_islands_grunt_u": ["Sbire Rocket", [[&"houndoom", 59], [&"golbat", 58]], &"whirl_islands_1f"],
}
const CENERE_TEAM: Array = [[&"weezing", 64], [&"wobbuffet", 64], [&"noctowl", 65],
	[&"dewgong", 63], [&"sneasel", 64]]
## Dossier §7 : scène → (objet, nombre, drapeau, carte).
const ITEMS: Dictionary = {
	&"route_40_item_1": [&"ultra_ball", 2, &"route_40"],
	&"route_41_item_1": [&"max_potion", 1, &"route_41"],
	&"whirl_islands_1f_item_1": [&"max_revive", 1, &"whirl_islands_1f"],
	&"whirl_islands_b1f_dragon_scale": [&"dragon_scale", 1, &"whirl_islands_b1f"],
	&"whirl_islands_b1f_item_1": [&"pp_max", 1, &"whirl_islands_b1f"],
	&"whirl_islands_b2f_item_1": [&"rare_candy", 2, &"whirl_islands_b2f"],
}
## Dossier §5 : table → (terrain, moments, taux, niveaux, poids).
const ROUTE_WATER: Dictionary = {&"tentacool": 40, &"tentacruel": 25, &"staryu": 15, &"shellder": 10,
	&"krabby": 10}
const TABLES: Dictionary = {
	&"route_40_water": [&"water", [], [42, 48], ROUTE_WATER],
	&"route_41_water": [&"water", [], [42, 48], ROUTE_WATER],
	&"whirl_islands_1f_rubble_day": [&"rubble", [&"morning", &"day"], [46, 50],
		{&"golbat": 30, &"graveler": 20, &"geodude": 10, &"kingler": 20, &"dewgong": 20}],
	&"whirl_islands_1f_rubble_night": [&"rubble", [&"night"], [46, 50],
		{&"golbat": 40, &"graveler": 20, &"dewgong": 20, &"wobbuffet": 5, &"kingler": 15}],
	&"whirl_islands_b1f_rubble": [&"rubble", [], [48, 52],
		{&"golbat": 35, &"dewgong": 25, &"cloyster": 20, &"kingler": 15, &"wobbuffet": 5}],
	&"whirl_islands_b1f_water": [&"water", [], [48, 52],
		{&"tentacruel": 30, &"dewgong": 30, &"seadra": 25, &"seel": 15}],
}
const DEBUG_STARTS: Array[String] = ["johto_whirl_route_40", "johto_whirl_1f", "johto_whirl_b1f",
	"johto_whirl_suicune", "johto_whirl_lugia", "johto_whirl_friday"]

var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _pokemon: PokemonData
var _items: ItemLibrary
var _trainers: TrainerLibrary
var _encounters: EncounterLibrary
var _dossier: Dictionary = {}


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
	_encounters = EncounterLibrary.new(_pokemon)
	_encounters.load_dir()
	_dossier = _read_dossier()


## Tableau du §16 : « | M-n | où | texte | » → n° → texte (sans gras ni italique, `{joueur}` →
## `{player}`).
func _read_dossier() -> Dictionary:
	var texts: Dictionary = {}
	for line: String in FileAccess.get_file_as_string(DOSSIER).split("\n"):
		if not line.begins_with("| M-"):
			continue
		var cells := line.split("|")
		var text := cells[3].strip_edges().replace("**", "").replace("*", "")
		texts[cells[1].strip_edges()] = text.replace("{joueur}", "{player}")
	return texts


## Bulles du dossier (« / »), la ligne système de M-17 (« · (système) ») comprise.
func _bubbles(number: String) -> Array[String]:
	var bubbles: Array[String] = []
	for part: String in (_dossier[number] as String).replace(" · (système) ", " / ").split(" / "):
		bubbles.append(part.strip_edges())
	return bubbles


func _pages(id: StringName, variant: int = 0) -> Array[String]:
	var dialogue := _dialogues.get_dialogue(id)
	assert_not_null(dialogue, String(id))
	var pages: Array[String] = []
	if dialogue == null or variant >= dialogue.variants.size():
		return pages
	for page: DialoguePage in dialogue.variants[variant].pages:
		pages.append(page.text)
	return pages


func _ids(dir: String) -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.assign(J22Ids.in_dir(dir, PREFIX).keys())
	ids.sort()
	return ids


func _flags(raised: Array[StringName] = []) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in raised:
		flags.set_flag(flag)
	return flags


func _npc(map_id: StringName, id: StringName) -> NpcSpec:
	var spec := NpcRoster.load_for_map(map_id).get_spec(id)
	assert_not_null(spec, "%s / %s" % [map_id, id])
	return spec


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_encounters.get_errors(), PackedStringArray())
	assert_eq(_items.get_errors(), PackedStringArray())
	for map_id: StringName in MAPS:
		var roster := NpcRoster.load_for_map(map_id)
		assert_eq(roster.get_errors(), PackedStringArray(), String(map_id))
	assert_eq(_dossier.size(), 34, "M-1 à M-34")


func test_texts_m1_to_m34_word_for_word() -> void:
	for number: String in TEXTS:
		var pages: Array[String] = []
		for entry: Array in TEXTS[number]:
			pages.append_array(_pages(entry[0], entry[1]))
		assert_eq(pages, _bubbles(number), number)
	for number: String in TRAINER_TEXTS:
		var row: String = _dossier[number]
		for id: StringName in TRAINER_TEXTS[number]:
			for suffix: String in ["_before", "_defeated", "_after"]:
				var text: String = _pages(StringName(String(id) + suffix))[0]
				assert_true(row.contains(text), "%s : %s « %s »" % [number, id, text])
	# M-7, M-9 : descriptions de zone.
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	assert_true((_dossier["M-7"] as String).contains(zones.get_zone(&"route_40").description))
	assert_true((_dossier["M-7"] as String).contains(zones.get_zone(&"route_41").description))
	assert_eq(zones.get_zone(&"whirl_islands").description, _dossier["M-9"])


func test_every_scene_is_launched_and_every_dialogue_used() -> void:
	var launched: Dictionary = {}
	var used: Dictionary = {}
	for id: StringName in _dialogues.get_ids():
		for variant: DialogueVariant in _dialogues.get_dialogue(id).variants:
			if not variant.cutscene.is_empty():
				launched[variant.cutscene] = true
	for id: StringName in _cutscenes.get_dialogue_ids():
		used[id] = true
	for id: StringName in _ids("res://data/cutscenes/"):
		var next := _cutscenes.get_next(id)
		if not next.is_empty():
			launched[next] = true
	for map_id: StringName in MAPS + [&"olivine_city", &"olivine_center", &"olivine_house_2"]:
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
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
				assert_true(_dialogues.has_dialogue(spec.dialogue), "%s : %s" % [map_id, spec.dialogue])
			if not spec.trainer_id.is_empty():
				used[spec.before_dialogue] = true
				used[spec.defeated_dialogue] = true
	for id: StringName in _ids("res://data/cutscenes/"):
		assert_true(launched.has(id), "scène « %s » lancée" % id)
	for id: StringName in _ids("res://data/dialogues/"):
		assert_true(used.has(id) or launched.has(id), "dialogue « %s » utilisé" % id)


func test_trainers_follow_dossier_6() -> void:
	var placed: Dictionary = {}
	for map_id: StringName in MAPS:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			if not spec.trainer_id.is_empty():
				placed[spec.trainer_id] = map_id
	assert_eq(placed.size(), TRAINERS.size())
	for id: StringName in TRAINERS:
		assert_eq(placed.get(id), TRAINERS[id][2], String(id))
		var trainer := _trainers.get_trainer(id)
		assert_not_null(trainer, String(id))
		if trainer == null:
			continue
		assert_eq(trainer.name, TRAINERS[id][0])
		var team: Array = []
		for member: Variant in trainer.team:
			team.append([member.species, member.level])
		assert_eq(team, TRAINERS[id][1], String(id))
	# Noé garde la passe (15, 10) depuis son rocher plat (grille : vue d'une case, inévitable).
	var noe := _npc(&"route_41", &"noe")
	assert_eq([noe.cell, noe.facing, noe.sight], [Vector2i(16, 9), Vector2i.LEFT, 1])
	# Cenere : grand combat (IA, un changement), équipe du §6.
	var cenere := _trainers.get_trainer(&"whirl_islands_cenere")
	assert_not_null(cenere)
	var team: Array = []
	for member: Variant in cenere.team:
		team.append([member.species, member.level])
	assert_eq(team, CENERE_TEAM)
	assert_true(cenere.can_switch, "Cenere change de Pokémon")


func test_items_are_given_once() -> void:
	for id: StringName in ITEMS:
		var cutscene := _cutscenes.get_cutscene(id)
		assert_not_null(cutscene, String(id))
		if cutscene == null:
			continue
		var flag := StringName("got_" + String(id))
		assert_eq(cutscene.variants[0].unless_flags, [flag] as Array[StringName], String(id))
		var gives: Array = []
		for step: CutsceneStep in cutscene.variants[0].steps:
			if step.kind == CutsceneStep.Kind.GIVE:
				gives.append([step.item_id, step.count, step.found])
				assert_true(_items.has_item(step.item_id), String(step.item_id))
		assert_eq(gives, [[ITEMS[id][0], ITEMS[id][1], true]], String(id))
		assert_eq(_npc(ITEMS[id][2], id).unless_flags, [flag] as Array[StringName])
	# PP Max : porte la capacité à son plafond d'un coup.
	var pp_max := _items.get_item(&"pp_max")
	assert_eq(pp_max.field_use, ItemData.FIELD_USE_PP_UP)
	assert_true(pp_max.pp_up_max)
	var pokemon := PokemonFactory.create(_pokemon, &"lapras", 50, GameRng.new())
	var slot := pokemon.moves[0]
	var base := slot.max_pp
	assert_gt(PpItem.apply(pokemon, 0, pp_max, _pokemon), 0)
	assert_eq(slot.max_pp, PpItem.cap(slot, _pokemon))
	assert_eq(PpItem.check_move(pokemon, 0, pp_max, _pokemon), PpItem.Check.NO_EFFECT)
	assert_gt(slot.max_pp, base)


func test_encounter_and_fishing_tables() -> void:
	for id: StringName in TABLES:
		var table := _encounters.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		var spec: Array = TABLES[id]
		assert_eq(table.terrain, spec[0], String(id))
		assert_eq(table.periods, spec[1] as Array[StringName], String(id))
		var weights: Dictionary = spec[3]
		var seen: Dictionary = {}
		for slot: EncounterSlot in table.slots:
			assert_eq(slot.weight, weights.get(slot.species, 0), "%s : %s" % [id, slot.species])
			assert_eq([slot.min_level, slot.max_level], spec[2], "%s : %s" % [id, slot.species])
			seen[slot.species] = true
			for back: bool in [false, true]:
				assert_true(BattleArt.new().has_image(slot.species, back),
					"%s : sprite de combat" % slot.species)
		assert_eq(seen.size(), weights.size(), String(id))
	assert_eq(_encounters.get_table(&"whirl_islands_1f", &"rubble", &"night").id,
		&"whirl_islands_1f_rubble_night")
	assert_eq(_encounters.get_table(&"whirl_islands_1f", &"rubble", &"morning").id,
		&"whirl_islands_1f_rubble_day")
	assert_false(_encounters.has_table(&"whirl_islands_b2f", &"water"), "aucune rencontre au B2F")
	var fishing := WaterRodTables.new(_pokemon)
	assert_true(fishing.load_game_files())
	for map_id: StringName in [&"route_40", &"route_41"]:
		var old := fishing.get_table(&"old_rod", map_id)
		var species: Array = []
		for slot: EncounterSlot in old.slots:
			species.append(slot.species)
		assert_eq(species, [&"magikarp", &"tentacool"], "Canne, %s" % map_id)
		species.clear()
		for slot: EncounterSlot in fishing.get_table(&"good_rod", map_id).slots:
			species.append(slot.species)
		assert_eq(species, [&"krabby", &"horsea", &"staryu"], "Super Canne, %s" % map_id)


## Légendaires (§6, §9) : rencontres fixes ; fuite = K.O. ; progression et réapparition séparées.
func test_legendaries_are_static_encounters() -> void:
	var expected := {
		&"whirl_suicune_battle": [&"suicune", 60, &"johto_suicune_resolved", &"johto_suicune_caught"],
		&"whirl_lugia_battle": [&"lugia", 65, &"johto_lugia_resolved", &"johto_lugia_caught"],
		&"whirl_lapras_battle": [&"lapras", 50, &"week_friday_lapras", &"johto_lapras_caught"],
	}
	var statics := _cutscenes.get_static_encounters()
	for scene: StringName in expected:
		var found := false
		for step: CutsceneStep in _cutscenes.get_cutscene(scene).variants[0].steps:
			if step.kind != CutsceneStep.Kind.WILD_BATTLE:
				continue
			found = true
			assert_eq([step.species, step.level], expected[scene].slice(0, 2), String(scene))
			assert_not_null(step.static_encounter, String(scene))
			if step.static_encounter != null:
				assert_eq(step.static_encounter.done_flag, expected[scene][2], String(scene))
				assert_eq(step.static_encounter.caught_flag, expected[scene][3], String(scene))
			assert_eq(step.flee_flags, [expected[scene][2], &"johto_whirl_fled"] as Array[StringName],
				"%s : fuite" % scene)
		assert_true(found, String(scene))
		# QA A17 : après une fuite, l'acteur quitte la carte (despawn) et le drapeau passager est
		# baissé.
		var kinds: Array = []
		for step: CutsceneStep in _cutscenes.get_cutscene(scene).variants[0].steps:
			if step.if_flags.has(&"johto_whirl_fled"):
				kinds.append(step.kind)
		assert_eq(kinds, [CutsceneStep.Kind.DESPAWN, CutsceneStep.Kind.UNSET_FLAGS], String(scene))
		var listed := false
		for encounter: StaticEncounter in statics:
			listed = listed or encounter.done_flag == expected[scene][2]
		assert_true(listed, "%s : réapparition après la Ligue (StaticRespawn)" % scene)


func test_debug_starts_are_valid() -> void:
	for name: String in DEBUG_STARTS:
		var start := DebugStart.new()
		assert_true(start.load_file("res://tools/debug_start/%s.json" % name, _pokemon, _items),
			"%s : %s" % [name, start.get_errors()])
