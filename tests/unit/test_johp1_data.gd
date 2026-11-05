extends GutTest
## Arc des Pierres, JOHP1 (`docs/tech/jalon-joh-pierres.md` §3) : données générées depuis les grilles
## (`tools/gen_johp1_data.py`) : textes P-1 à P-58 du dossier JOH-11 §17 mot pour mot, Dresseurs
## §10, rencontres §11, objets §12, drapeaux §7, capture à 6 (JH-71), départs de débogage. Les
## grands registres écartent les fichiers `johp1_*`.

const J22Ids := preload("res://tests/helpers/j22_ids.gd")

const PREFIX := "johp1_"
const DOSSIER := "res://docs/design/dossier-joh-11-arc-pierres.md"
## Dossier §10 : Dresseur → (nom, équipe).
const TRAINERS: Dictionary = {
	&"alph_researcher_agnes": ["Chercheuse Agnès", [[&"kadabra", 31], [&"golbat", 30]]],
	&"alph_nerd_remi": ["Intello Rémi", [[&"magneton", 31], [&"porygon", 30]]],
	&"alph_medium_solange": ["Médium Solange", [[&"haunter", 31], [&"kadabra", 31]]],
	&"alph_grunt_v": ["Sbire Rocket", [[&"koffing", 31], [&"raticate", 31]]],
	&"alph_grunt_w": ["Sbire Rocket", [[&"arbok", 32]]],
	&"alph_grunt_x": ["Sbire Rocket", [[&"houndour", 32], [&"murkrow", 32]]],
	&"alph_scientist": ["Scientifique Rocket", [[&"magneton", 33], [&"electrode", 33]]],
	&"alph_fake_archeologist": ["Faux archéologue", [[&"arbok", 34], [&"raticate", 34], [&"houndoom", 35]]],
}
## Dossier §12 : scène d'objet → (objet, nombre).
const ITEMS: Dictionary = {
	&"ruins_item_1": [&"super_potion", 2],
	&"ruins_hidden_1": [&"revive", 1],
	&"gallery_item_1": [&"hyper_potion", 1],
}
## Dossier §11 : table → (moments, niveaux, espèces et poids).
const ENCOUNTERS: Dictionary = {
	&"ruins_of_alph_grass_day": [[&"morning", &"day"], [27, 31], {&"abra": 25, &"kadabra": 15,
		&"psyduck": 20, &"geodude": 20, &"furret": 20}],
	&"ruins_of_alph_grass_night": [[&"night"], [27, 31], {&"hoothoot": 30, &"noctowl": 15,
		&"gastly": 25, &"zubat": 30}],
	&"alph_gallery_rubble": [[], [28, 32], {&"zubat": 35, &"golbat": 15, &"geodude": 25, &"onix": 10,
		&"gastly": 15}],
}
const DEBUG_STARTS: Array[String] = ["johto_stones_hall", "johto_alph_route_36", "johto_alph_ruins",
	"johto_alph_ruins_full", "johto_alph_tent", "johto_alph_gallery", "johto_alph_tiles",
	"johto_alph_chamber", "johto_alph_after"]

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


## Accords de la joueuse (JR-7) ramenés à leur forme masculine, celle du dossier.
func _masculine(text: String) -> String:
	var regex := RegEx.create_from_string("\\{g:([^|}]*)\\|[^}]*\\}")
	return regex.sub(text, "$1", true)


func _steps(scene: StringName) -> Array[CutsceneStep]:
	var steps: Array[CutsceneStep] = []
	var cutscene := _cutscenes.get_cutscene(scene)
	assert_not_null(cutscene, String(scene))
	if cutscene != null:
		for variant: CutsceneVariant in cutscene.variants:
			steps.append_array(variant.steps)
	return steps


func test_libraries_load_without_error() -> void:
	assert_eq(_dialogues.get_errors(), PackedStringArray())
	assert_eq(_cutscenes.get_errors(), PackedStringArray())
	assert_eq(_trainers.get_errors(), PackedStringArray())
	assert_eq(_items.get_errors(), PackedStringArray())
	assert_gt(_ids("res://data/dialogues/").size(), 30)
	assert_gt(_ids("res://data/cutscenes/").size(), 8)


## Chaque réplique est dans le dossier JOH-11 §17, mot pour mot ; aucun texte hors du lot validé.
func test_every_line_is_in_the_dossier() -> void:
	var dossier := J22Ids.flat_text(FileAccess.get_file_as_string(DOSSIER))
	dossier = dossier.replace("{joueur}", "{player}")
	var checked := 0
	for id: StringName in _ids("res://data/dialogues/"):
		var dialogue := _dialogues.get_dialogue(id)
		assert_false(dialogue.draft, "%s : aucun brouillon" % id)
		for variant: DialogueVariant in dialogue.variants:
			for page: DialoguePage in variant.pages:
				checked += 1
				assert_true(dossier.contains(J22Ids.flat_text(_masculine(page.text))),
					"%s : « %s » (dossier JOH-11 §17)" % [id, page.text])
	assert_gt(checked, 50)


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
		assert_eq(team, TRAINERS[id][1], "%s : équipe du §10" % id)


func test_items_follow_the_dossier() -> void:
	for scene: StringName in ITEMS:
		var found := false
		for step: CutsceneStep in _steps(scene):
			if step.kind == CutsceneStep.Kind.GIVE:
				found = true
				assert_eq(step.item_id, ITEMS[scene][0], String(scene))
				assert_eq(step.count, ITEMS[scene][1], String(scene))
		assert_true(found, "%s : un objet" % scene)


func test_the_three_stones_are_key_items() -> void:
	var texts: Dictionary = {
		&"stone_memory": "Une pierre grise, tiède, couverte de signes.",
		&"stone_tide": "Une pierre bleue, toujours humide.",
		&"stone_breath": "Une pierre blanche qui semble se soulever, très lentement.",
	}
	for id: StringName in texts:
		var item := _items.get_item(id)
		assert_not_null(item, String(id))
		assert_eq(item.category, ItemData.Category.KEY, String(id))
		assert_eq(item.description, texts[id], "%s : P-9" % id)
		assert_true(ResourceLoader.exists("res://assets/ui/items/%s.webp" % id), "%s : icône" % id)


func test_encounters_follow_the_dossier() -> void:
	var library := EncounterLibrary.new(_pokemon)
	assert_true(library.load_dir(), str(library.get_errors()))
	for id: StringName in ENCOUNTERS:
		var table := library.get_table_by_id(id)
		assert_not_null(table, String(id))
		if table == null:
			continue
		var spec: Array = ENCOUNTERS[id]
		assert_eq(Array(table.periods), spec[0], "%s : moments" % id)
		var slots: Dictionary = {}
		for slot: EncounterSlot in table.slots:
			slots[slot.species] = slot.weight
			assert_eq([slot.min_level, slot.max_level], spec[1], "%s : niveaux" % id)
		assert_eq(slots, spec[2], "%s : espèces et poids" % id)


## Héloïse : accueil (P-3, P-4), rappel (P-4), après la pierre (P-10), après l'arc (P-57).
func test_heloise_follows_the_quest() -> void:
	var heloise := _dialogues.get_dialogue(&"alph_tent_heloise")
	assert_not_null(heloise)
	assert_eq(heloise.variants[0].if_flags, [&"johto_stones_awakened"] as Array[StringName])
	assert_eq(heloise.variants[1].if_flags, [&"johto_stone_memory"] as Array[StringName])
	assert_eq(heloise.variants[2].if_flags, [&"johto_alph_met"] as Array[StringName])
	assert_true(heloise.variants[3].set_flags.has(&"johto_alph_met"))
	assert_eq(heloise.variants[3].pages[0].text, "Orme m'a prévenue. Ne touche à rien.")


## Rien hors des départs de débogage ne pose `johto_stones_quest` avant la bascule du JOHP3.
## JH-71 : la Ball n'est plus refusée à partir de la quête ; le texte P-58 tant que le Stockage est
## fermé ; le chemin de JOH0 est inchangé avant la quête et après le retour de l'équipe.
func test_capture_gate_during_the_arc() -> void:
	var party := Party.new()
	for i: int in Party.MAX_SIZE:
		var pokemon := Pokemon.new()
		pokemon.species_id = &"rattata"
		party.add(pokemon)
	var flags := StoryFlags.new()
	flags.set_flag(TeamConfiscation.STORAGE_OFFLINE)
	assert_true(CaptureGate.blocks(party, flags), "acte 1 : refusée à 6 (JH-23)")
	flags.set_flag(CaptureGate.STONES_QUEST)
	assert_false(CaptureGate.blocks(party, flags), "arc : la capture part au Stockage")
	assert_eq(CaptureGate.stored_key(flags), CaptureGate.SENT_TO_ORME_KEY, "P-58")
	flags.set_flag(TeamConfiscation.STORAGE_OFFLINE, false)
	assert_eq(CaptureGate.stored_key(flags), CaptureGate.SENT_TO_STORAGE_KEY, "après l'arc")
	assert_false(CaptureGate.blocks(party, flags))


func test_p58_is_the_validated_text() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BattleText.DATA_PATH))
	var line: String = doc["templates"]["sent_to_orme"]["text"]
	assert_eq(line, "Ton équipe est pleine. {pokemon} part au laboratoire d'Orme, qui s'en occupe en attendant.")
	assert_true(FileAccess.get_file_as_string(DOSSIER).contains(line), "P-58")


func test_debug_starts_are_valid() -> void:
	for name: String in DEBUG_STARTS:
		var start := DebugStart.new()
		var path := "res://tools/debug_start/%s.json" % name
		assert_true(FileAccess.file_exists(path), path)
		var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_true((doc["flags"] as Array).has("johto_stones_quest"), name)
		assert_false((doc["flags"] as Array).has("johto_team_returned"), "%s : équipe pas revenue" % name)
		assert_false((doc["flags"] as Array).has("johto_act2"), name)
		assert_false((doc["confiscated"]["party"] as Array).is_empty(), "%s : équipe de Kanto" % name)
		assert_not_null(start)
