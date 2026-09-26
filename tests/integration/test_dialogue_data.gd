extends GutTest
## Données de dialogue du jalon 3A (jalon-03.md §3.3, §3.4, T4) : data/dialogues/*.json
## avec les vrais PNJ (data/npcs/*.json) et les vrais points d'examen des cartes.
## Chargement sans erreur, références (dialogues, react), drapeaux, textes du dossier 02
## repris mot pour mot, trois lignes au plus dans la vraie DialogueBox à 1920 × 1080,
## textes provisoires (draft) attendus.
## Jalon 3B (T2) : dialogues joués par les scènes de data/cutscenes/ (via les
## EventTriggerPoint des cartes), drapeaux lus et levés par dialogues, scènes et PNJ.
## T3 : répliques du Prof. Chen, acteurs et cibles des « turn » (PNJ de la carte ou créés
## par la scène qui joue le dialogue).
## T4 : retour au labo (change_map : les dialogues suivants sont joués sur la carte cible),
## « oak_lab_reunion », nouvelle variante de Maya (oak_met), drapeau oak_lab_reunion.
## Jalon 4 (T1) : « oak_starter_offer » (Chen propose, 4 pages, regard vers la table à la 3e)
## joué à la fin de la variante 1 de route1_grass, qui lève starter_offered.

const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const DOSSIER := "res://docs/design/dossier-02-prologue.md"
const MAPS: Array[StringName] = [
	&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab", &"pallet_town",
]
## Seuls textes provisoires : le panneau « BOURG PALETTE » (Q8).
const DRAFTS: Array[StringName] = [&"sign_pallet_town"]
## Identifiants attendus (3A) : Maman, table, rival, carte, Maya, 3 starters, 3 habitants,
## panneau ; (3B) « Hé ! Attends ! », les répliques du Prof. Chen et la pensée des herbes ;
## (4A, T1) la proposition du Prof. Chen.
const IDS: Array[StringName] = [
	&"aoki", &"breakfast_table", &"haru", &"leo", &"maya", &"mom", &"oak_lab_reunion",
	&"oak_lab_waiting", &"oak_route1_call", &"oak_route1_warning", &"oak_starter_offer",
	&"observe_bulbasaur", &"observe_charmander", &"observe_squirtle", &"rival",
	&"rival_kanto_map", &"rival_lab_waiting", &"route1_grass_thought", &"sign_pallet_town",
]
## Drapeaux lus mais levés par une tâche à venir : starter_chosen (lu par la pensée des
## herbes, variante 2 de route1_grass ; levé par la scène « starter_chosen », jalon 4 T3,
## jalon-04.md §13).
const FUTURE_FLAGS: Array[StringName] = [&"starter_chosen"]
## Drapeaux levés par les données mais lus seulement par le code : starter_offered (levé à la
## fin de la proposition de Chen, jalon 4 T1 ; lu par StarterChoice en T3, puis par la scène
## oak_lab_exit, jalon-04.md §13.3).
const CODE_READ_FLAGS: Array[StringName] = [&"starter_offered"]

var _library: DialogueLibrary
var _cutscenes: CutsceneLibrary
## Dialogue → cartes où il est utilisé (PNJ ou point d'examen).
var _used_on: Dictionary[StringName, Array] = {}
## Carte → identifiants de PNJ.
var _npc_ids: Dictionary[StringName, Array] = {}
## Dialogue joué par une scène → PNJ créés (« spawn ») par cette scène.
var _spawned_for: Dictionary[StringName, Array] = {}


func before_all() -> void:
	_library = DialogueLibrary.new()
	_library.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	for map_id: StringName in MAPS:
		_npc_ids[map_id] = []
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			(_npc_ids[map_id] as Array).append(spec.id)
			if spec.is_interactive():
				_use(spec.dialogue, map_id)
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
		for point: Node in map.get_node(^"Interactables").get_children():
			_use((point as InteractPoint).dialogue_id, map_id)
		for point: Node in map.get_node(^"Triggers").get_children():
			_use_cutscene((point as EventTriggerPoint).cutscene_id, map_id)
		map.free()


## Dialogues joués par les étapes de la scène [param cutscene_id], sur la carte de son
## déclencheur, puis sur la carte de chaque « change_map » (T4). Un PNJ créé par « spawn »
## disparaît avec sa carte.
func _use_cutscene(cutscene_id: StringName, trigger_map: StringName) -> void:
	var cutscene := _cutscenes.get_cutscene(cutscene_id)
	if cutscene == null:
		return
	for variant: CutsceneVariant in cutscene.variants:
		var spawned: Array[StringName] = []
		var map_id := trigger_map
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.CHANGE_MAP:
				map_id = step.map_id
				spawned = []
			if step.kind == CutsceneStep.Kind.SPAWN:
				spawned.append(step.spec.id)
			if step.kind == CutsceneStep.Kind.DIALOGUE:
				_use(step.dialogue_id, map_id)
				if not _spawned_for.has(step.dialogue_id):
					_spawned_for[step.dialogue_id] = []
				(_spawned_for[step.dialogue_id] as Array).append_array(spawned)


func _use(dialogue: StringName, map_id: StringName) -> void:
	if not _used_on.has(dialogue):
		_used_on[dialogue] = []
	(_used_on[dialogue] as Array).append(map_id)


## Toutes les pages de toutes les variantes : [id, texte, page].
func _pages() -> Array[Array]:
	var pages: Array[Array] = []
	for id: StringName in _library.get_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			for page: DialoguePage in variant.pages:
				pages.append([id, page.text, page])
	return pages


func test_library_loads_without_error() -> void:
	var library := DialogueLibrary.new()
	assert_true(library.load_dir(), "data/dialogues/ se charge")
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_eq(library.get_ids(), IDS)


func test_every_used_dialogue_exists() -> void:
	assert_gt(_used_on.size(), 0)
	for dialogue: StringName in _used_on:
		assert_true(_library.has_dialogue(dialogue), "dialogue « %s » défini" % dialogue)


func test_every_dialogue_is_used() -> void:
	var played := _cutscenes.get_dialogue_ids()
	for id: StringName in _library.get_ids():
		assert_true(_used_on.has(id) or played.has(id),
			"dialogue « %s » utilisé par un PNJ, un point ou une scène" % id)


func test_every_dialogue_played_by_a_cutscene_exists() -> void:
	assert_eq(_cutscenes.get_errors().size(), 0, str(_cutscenes.get_errors()))
	var played := _cutscenes.get_dialogue_ids()
	assert_eq(played, [&"oak_lab_reunion", &"oak_route1_call", &"oak_route1_warning",
		&"oak_starter_offer", &"route1_grass_thought"] as Array[StringName])
	for id: StringName in played:
		assert_true(_library.has_dialogue(id), "dialogue « %s » défini" % id)
		assert_true(_used_on.has(id), "« %s » joué depuis un déclencheur de carte" % id)


func test_every_react_targets_an_npc_of_the_map_where_it_is_used() -> void:
	for row: Array in _pages():
		var page: DialoguePage = row[2]
		if page.react.is_empty():
			continue
		var maps: Array = _used_on.get(row[0], [])
		assert_false(maps.is_empty(), "%s utilisé" % row[0])
		for map_id: StringName in maps:
			assert_true((_npc_ids[map_id] as Array).has(page.react),
				"%s : « react » %s sur %s" % [row[0], page.react, map_id])


func test_every_turn_actor_and_target_exists_where_the_dialogue_is_played() -> void:
	var turns := 0
	for row: Array in _pages():
		var page: DialoguePage = row[2]
		for actor: StringName in page.turn:
			turns += 1
			for who: StringName in [actor, page.turn[actor]]:
				if who == NpcRoster.PLAYER_ID or (who != actor and Grid.is_direction_name(who)):
					continue
				var maps: Array = _used_on.get(row[0], [])
				assert_false(maps.is_empty(), "%s utilisé" % row[0])
				for map_id: StringName in maps:
					var known: bool = (_npc_ids[map_id] as Array).has(who) or \
						(_spawned_for.get(row[0], []) as Array).has(who)
					assert_true(known, "%s : « turn » %s sur %s" % [row[0], who, map_id])
	assert_gt(turns, 0, "les répliques de Chen ont des « turn »")


func test_oak_looks_at_the_grass_on_his_second_line_and_thinks_before_the_last() -> void:
	var pages := _library.get_dialogue(&"oak_route1_warning").variants[0].pages
	assert_eq(pages.size(), 4)
	assert_eq(pages[0].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])
	assert_eq(pages[1].turn, {&"oak": &"up"} as Dictionary[StringName, StringName],
		"il regarde les hautes herbes (nord)")
	assert_eq(pages[2].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])
	assert_eq(pages[3].pause, 1.0, "il réfléchit une seconde")
	assert_eq(pages[3].text, "...Viens avec moi.")


func test_every_condition_flag_is_set_somewhere() -> void:
	var set_flags := _library.get_set_flags() + _cutscenes.get_set_flags()
	var read_flags := _library.get_condition_flags() + _cutscenes.get_condition_flags()
	for map_id: StringName in MAPS:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			read_flags.append_array(spec.if_flags + spec.unless_flags)
	for flag: StringName in read_flags:
		if FUTURE_FLAGS.has(flag):
			continue
		assert_true(set_flags.has(flag), "drapeau « %s » levé par un « set »" % flag)
	for flag: StringName in FUTURE_FLAGS:
		assert_false(set_flags.has(flag), "« %s » : levé par un jalon futur" % flag)
	assert_true(read_flags.has(&"starter_chosen"), "starter_chosen lu (pensée des herbes)")
	assert_eq(_library.get_set_flags(), [&"mom_greeted", &"rival_met"] as Array[StringName])
	assert_eq(_cutscenes.get_set_flags(), [&"oak_lab_reunion", &"oak_met", &"starter_offered"]
		as Array[StringName])
	assert_eq(_used_on.get(&"oak_lab_reunion"), [&"oak_lab"], "joué au labo, après le fondu")
	assert_eq(_used_on.get(&"oak_starter_offer"), [&"oak_lab"], "joué au labo")


## starter_offered est levé par la scène mais lu seulement par le code du choix (T3) : aucune
## donnée ne le lit encore (sinon il sort de CODE_READ_FLAGS).
func test_code_read_flags_are_set_by_data_and_not_read_by_data_yet() -> void:
	var set_flags := _library.get_set_flags() + _cutscenes.get_set_flags()
	var read_flags := _library.get_condition_flags() + _cutscenes.get_condition_flags()
	for map_id: StringName in MAPS:
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			read_flags.append_array(spec.if_flags + spec.unless_flags)
	for flag: StringName in CODE_READ_FLAGS:
		assert_true(set_flags.has(flag), "« %s » levé par les données" % flag)
		assert_false(read_flags.has(flag), "« %s » lu seulement par le code (T3)" % flag)


## Décision de Kevin (jalon-04.md §4.1, §13.5) : 4 répliques du Prof. Chen, mot pour mot ; il
## regarde les trois Pokémon (table à sa droite) à la 3e, puis revient vers le joueur.
func test_oak_starter_offer_four_lines_and_looks() -> void:
	var dialogue := _library.get_dialogue(&"oak_starter_offer")
	assert_eq(dialogue.speaker, "Prof. Chen")
	assert_false(dialogue.narration)
	assert_false(dialogue.draft)
	assert_eq(dialogue.variants.size(), 1)
	var pages := dialogue.variants[0].pages
	var texts: Array[String] = []
	for page: DialoguePage in pages:
		texts.append(page.text)
	assert_eq(texts, [
		"Vous voulez tous les deux découvrir Kanto.",
		"Mais découvrir ce monde seul serait une mauvaise idée.",
		"Eux aussi ont encore beaucoup à découvrir.",
		"Alors... pourquoi ne pas commencer ensemble ?",
	] as Array[String])
	assert_true(pages[0].turn.is_empty())
	assert_true(pages[1].turn.is_empty())
	assert_eq(pages[2].turn, {&"oak": &"right"} as Dictionary[StringName, StringName],
		"il regarde les trois Pokémon (table à sa droite)")
	assert_eq(pages[3].turn, {&"oak": &"player"} as Dictionary[StringName, StringName])


func test_mom_first_variant_is_automatic_and_only_hers() -> void:
	for id: StringName in _library.get_ids():
		for variant: DialogueVariant in _library.get_dialogue(id).variants:
			assert_eq(variant.auto, id == &"mom" and variant == \
				_library.get_dialogue(&"mom").variants[0], "%s : auto" % id)


func test_drafts_are_exactly_the_expected_ones() -> void:
	var drafts: Array[StringName] = []
	for id: StringName in _library.get_ids():
		if _library.get_dialogue(id).draft:
			drafts.append(id)
	assert_eq(drafts, DRAFTS)


func test_texts_are_the_dossier_02_texts_word_for_word() -> void:
	assert_true(FileAccess.file_exists(DOSSIER), DOSSIER)
	var dossier := FileAccess.get_file_as_string(DOSSIER)
	for row: Array in _pages():
		if _library.get_dialogue(row[0]).draft:
			continue
		assert_true(dossier.contains(row[1]), "%s : « %s » dans le dossier 02" % [row[0], row[1]])


func test_speakers_and_narration() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"mom": ["Maman", false], &"rival": ["Rival", false], &"maya": ["Maya", false],
		&"aoki": ["Mme Aoki", false], &"leo": ["Léo", false], &"haru": ["Haru", false],
		&"breakfast_table": ["", true], &"rival_kanto_map": ["", true],
		&"observe_bulbasaur": ["Bulbizarre", true], &"observe_charmander": ["Salamèche", true],
		&"observe_squirtle": ["Carapuce", true], &"sign_pallet_town": ["", false],
		&"oak_route1_call": ["???", false], &"route1_grass_thought": ["", true],
		&"oak_route1_warning": ["Prof. Chen", false], &"oak_lab_reunion": ["", false],
		&"oak_lab_waiting": ["Prof. Chen", false], &"rival_lab_waiting": ["Rival", false],
		&"oak_starter_offer": ["Prof. Chen", false],
	}
	for id: StringName in expected:
		var dialogue := _library.get_dialogue(id)
		assert_eq(dialogue.speaker, expected[id][0], "%s : locuteur" % id)
		assert_eq(dialogue.narration, expected[id][1], "%s : narration" % id)


func test_every_page_fits_in_three_lines_of_the_real_box() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var box := (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	viewport.add_child(box)
	box.open()
	var label := box.get_node(^"%Text") as Label
	for row: Array in _pages():
		var dialogue := _library.get_dialogue(row[0])
		box.show_page(dialogue.speaker, row[1], dialogue.narration)
		box.set_visible_characters(-1)
		await wait_process_frames(1)
		assert_lte(label.get_line_count(), UiTokens.DIALOG_MAX_LINES,
			"%s : « %s » en %d lignes" % [row[0], row[1], label.get_line_count()])
		assert_eq(box.get_panel().size.x, float(UiTokens.DIALOG_BOX_WIDTH))


## Décisions de Kevin 6, 7 et 9 : Maya a une variante « oak_met » placée en premier ; au
## labo, quatre répliques avec « Rival » et « Prof. Chen » page par page.
func test_maya_after_oak_returns_and_the_lab_reunion() -> void:
	var maya := _library.get_dialogue(&"maya")
	assert_eq(maya.variants.size(), 2)
	assert_eq(maya.variants[0].if_flags, [&"oak_met"] as Array[StringName], "variante en premier")
	var texts: Array[String] = []
	for page: DialoguePage in maya.variants[0].pages:
		texts.append(page.text)
	assert_eq(texts, ["Ah, le professeur est revenu.",
		"Et à voir son air, j'imagine qu'il a encore quelque chose en tête."] as Array[String])
	assert_eq(maya.variants[1].pages[0].text, "Bonjour ! Tu cherches le professeur Chen ?",
		"réplique de 3A inchangée")
	var flags := StoryFlags.new()
	assert_eq(maya.pick(flags), maya.variants[1])
	flags.set_flag(&"oak_met")
	assert_eq(maya.pick(flags), maya.variants[0])
	var reunion := _library.get_dialogue(&"oak_lab_reunion").variants[0].pages
	var lines: Array = []
	for page: DialoguePage in reunion:
		lines.append([page.speaker, page.text])
	assert_eq(lines, [
		["Rival", "Enfin."],
		["Prof. Chen", "Un peu de patience."],
		["Rival", "Ça fait une heure que tu dis ça."],
		["Prof. Chen", "Et pourtant, tu es toujours là."],
	])
	assert_eq(reunion[1].turn, {&"oak": &"rival"} as Dictionary[StringName, StringName])
	assert_eq(reunion[2].turn, {&"rival": &"oak"} as Dictionary[StringName, StringName])
