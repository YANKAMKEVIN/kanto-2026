extends GutTest
## Données de dialogue du jalon 3A (jalon-03.md §3.3, §3.4, T4) : data/dialogues/*.json
## avec les vrais PNJ (data/npcs/*.json) et les vrais points d'examen des cartes.
## Chargement sans erreur, références (dialogues, react), drapeaux, textes du dossier 02
## repris mot pour mot, trois lignes au plus dans la vraie DialogueBox à 1920 × 1080,
## textes provisoires (draft) attendus.

const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const DOSSIER := "res://docs/design/dossier-02-prologue.md"
const MAPS: Array[StringName] = [
	&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab", &"pallet_town",
]
## Seuls textes provisoires : le panneau « BOURG PALETTE » (Q8).
const DRAFTS: Array[StringName] = [&"sign_pallet_town"]
## Identifiants attendus (3A) : Maman, table, rival, carte, Maya, 3 starters, 3 habitants,
## panneau.
const IDS: Array[StringName] = [
	&"aoki", &"breakfast_table", &"haru", &"leo", &"maya", &"mom", &"observe_bulbasaur",
	&"observe_charmander", &"observe_squirtle", &"rival", &"rival_kanto_map",
	&"sign_pallet_town",
]

var _library: DialogueLibrary
## Dialogue → cartes où il est utilisé (PNJ ou point d'examen).
var _used_on: Dictionary[StringName, Array] = {}
## Carte → identifiants de PNJ.
var _npc_ids: Dictionary[StringName, Array] = {}


func before_all() -> void:
	_library = DialogueLibrary.new()
	_library.load_dir()
	for map_id: StringName in MAPS:
		_npc_ids[map_id] = []
		for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_all():
			(_npc_ids[map_id] as Array).append(spec.id)
			if spec.is_interactive():
				_use(spec.dialogue, map_id)
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
		for point: Node in map.get_node(^"Interactables").get_children():
			_use((point as InteractPoint).dialogue_id, map_id)
		map.free()


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
	for id: StringName in _library.get_ids():
		assert_true(_used_on.has(id), "dialogue « %s » utilisé par un PNJ ou un point" % id)


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


func test_every_condition_flag_is_set_somewhere() -> void:
	var set_flags := _library.get_set_flags()
	for flag: StringName in _library.get_condition_flags():
		assert_true(set_flags.has(flag), "drapeau « %s » levé par un « set »" % flag)
	assert_eq(_library.get_set_flags(), [&"mom_greeted", &"rival_met"] as Array[StringName])


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
