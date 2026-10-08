extends GutTest
## Données de la Forêt de Jade (jalon 9 T18, jalon-09.md §2.7.6, §2.7.7) contre la grille
## fonctionnelle `tools/plans/viridian_forest.txt` (source unique des positions, T14), avant la
## carte (T19) : PNJ, Dresseurs, Pokémon d'ambiance et objets de `data/npcs/viridian_forest.json`
## aux cases et attributs de la grille ; scènes des 6 objets (`data/cutscenes/viridian_forest.json`)
## et leurs objets ; apparences ; objets cachés sur une case praticable libre.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLAN_PATH := "res://tools/plans/viridian_forest.txt"
const MAP_ID := &"viridian_forest"
## Types de la grille qui sont des PNJ du fichier (identifiant = clé du fichier).
const NPC_KINDS: Array[String] = ["dresseur", "pnj", "pokemon", "objet_visible"]
## Pokémon d'ambiance dont la planche peut encore manquer (Chenipan, refusé par Codex au T17,
## jalon-09.md §6.15) : la carte le saute sans erreur ([method GameMap.awaits_painted_look]).
const SHEET_PENDING: Array[StringName] = [&"pokemon/caterpie"]

var _plan := PlanGrid.new()
var _roster: NpcRoster
var _cutscenes := CutsceneLibrary.new()
var _dialogues := DialogueLibrary.new()
var _trainers: TrainerLibrary
var _items := ItemLibrary.new()


func before_all() -> void:
	assert_true(_plan.load_file(PLAN_PATH), _plan.error)
	_roster = NpcRoster.load_for_map(MAP_ID)
	_cutscenes.load_dir()
	_dialogues.load_dir()
	var data := PokemonData.new()
	data.load_dir()
	_trainers = TrainerLibrary.new(data)
	_trainers.load_dir()
	_items.load_dir()


func _ids_of(kind: String) -> Array[String]:
	var ids: Array[String] = []
	for id: String in _plan.positions:
		if _plan.positions[id]["kind"] == kind:
			ids.append(id)
	return ids


func test_roster_loads_and_holds_exactly_the_grid_people_and_things() -> void:
	assert_eq(_roster.get_errors().size(), 0, str(_roster.get_errors()))
	var expected: Array[StringName] = []
	for kind: String in NPC_KINDS:
		for id: String in _ids_of(kind):
			expected.append(StringName(id))
	assert_eq(expected.size(), 17, "5 Dresseurs, 2 PNJ, 7 Pokémon, 3 objets visibles")
	var actual: Array[StringName] = []
	for spec: NpcSpec in _roster.get_all():
		actual.append(spec.id)
	expected.sort()
	actual.sort()
	assert_eq(actual, expected)
	for spec: NpcSpec in _roster.get_all():
		assert_eq(spec.cell, _plan.cell_of(String(spec.id)), "%s : case de la grille" % spec.id)
		assert_true(spec.if_flags.is_empty(), "%s : aucune condition de présence" % spec.id)


func test_trainers_follow_the_grid() -> void:
	var ids := _ids_of("dresseur")
	assert_eq(ids.size(), 5)
	for id: String in ids:
		var spec := _roster.get_spec(StringName(id))
		if spec == null:
			continue
		assert_true(spec.is_trainer(), id)
		assert_eq(spec.facing, Grid.direction_from_name(_plan.attr(id, "facing")), id)
		assert_eq(spec.sight, int(_plan.attr(id, "sight")), id)
		assert_eq(spec.trainer_id, StringName(_plan.attr(id, "trainer")), id)
		assert_not_null(_trainers.get_trainer(spec.trainer_id), id)
		assert_eq(spec.before_dialogue, StringName(String(spec.trainer_id) + "_before"))
		assert_eq(spec.dialogue, StringName(String(spec.trainer_id) + "_after"))
		var look := &"youngster" if spec.trainer_id == &"forest_youngster_tom" else &"scout"
		assert_eq(spec.sprite, look, "%s : apparence (Scouts : « scout », Tom : « youngster »)"
			% id)
		assert_true(_plan.is_walkable(spec.cell), "%s : debout sur une case praticable" % id)


func test_naturalist_and_hiker_walk_their_grid_cells_out_of_the_grass() -> void:
	var expected: Dictionary[StringName, Array] = {
		&"naturalist": [&"naturalist", &"forest_naturalist"],
		&"hiker": [&"hiker", &"forest_hiker"],
	}
	for id: StringName in expected:
		var spec := _roster.get_spec(id)
		assert_not_null(spec, String(id))
		if spec == null:
			continue
		assert_eq([spec.sprite, spec.dialogue], expected[id], "%s : apparence, réplique" % id)
		assert_true(spec.has_route(), "%s : marche (dossier 10 §9)" % id)
		var allowed := _plan.cells_at(String(id))
		for cell: Vector2i in spec.route_cells:
			assert_true(allowed.has(cell), "%s : %s dans ses cases de la grille" % [id, cell])
			assert_true(_plan.is_walkable(cell) and _plan.at(cell) != "h",
				"%s : %s praticable, hors des hautes herbes" % [id, cell])
	# Le naturaliste revient à sa case ouest en marchant vers l'ouest : il regarde le tronc
	# du Chrysacier (19, 57).
	var naturalist := _roster.get_spec(&"naturalist")
	assert_eq(naturalist.route_cells[0], Vector2i(22, 57))
	assert_eq(naturalist.route_cells[naturalist.route_cells.size() - 1], Vector2i(23, 57))
	assert_eq(naturalist.facing, Vector2i.LEFT)
	assert_eq(_plan.cell_of("metapod").y, 57)
	assert_lt(_plan.cell_of("metapod").x, 22)


func test_ambient_pokemon_follow_the_grid_and_may_sit_on_forest_cells() -> void:
	var ids := _ids_of("pokemon")
	assert_eq(ids.size(), 7)
	var on_forest := 0
	for id: String in ids:
		var spec := _roster.get_spec(StringName(id))
		if spec == null:
			continue
		assert_eq(spec.shy_action, StringName(_plan.attr(id, "shy")), "%s : réaction" % id)
		assert_false(spec.is_interactive(), "%s : ni dialogue ni bouton" % id)
		assert_false(spec.has_route(), "%s : immobile" % id)
		assert_true(String(spec.sprite).begins_with(CharacterLook.POKEMON_PREFIX), id)
		if not _plan.is_walkable(spec.cell):
			on_forest += 1
			var beside := false
			for direction: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT,
					Vector2i.RIGHT]:
				beside = beside or _plan.is_walkable(spec.cell + direction)
			assert_true(beside, "%s : au bord d'une case praticable" % id)
		if SHEET_PENDING.has(spec.sprite):
			assert_eq(GameMap.awaits_painted_look(spec), not Npc.has_frames(spec.sprite), id)
		else:
			assert_true(Npc.has_frames(spec.sprite), "%s : planche %s" % [id, spec.sprite])
	assert_eq(on_forest, 5, "Chenipan 2, deux Aspicot, Chrysacier, Coconfort sur la forêt")
	# Dossier 10 §7 : Aspicot se rétracte à une case, Chenipan relève la tête, un seul Roucool.
	assert_eq(_roster.get_spec(&"weedle_1").shy_radius, 1)
	assert_eq(_roster.get_spec(&"weedle_2").shy_radius, 1)
	assert_eq(_roster.get_spec(&"pidgey").shy_action, &"fly")


func test_visible_items_are_take_npcs_whose_scene_gives_the_grid_item() -> void:
	var ids := _ids_of("objet_visible")
	assert_eq(ids, ["viridian_forest_item_1", "viridian_forest_item_2",
		"viridian_forest_item_5"] as Array[String])
	for id: String in ids:
		var spec := _roster.get_spec(StringName(id))
		if spec == null:
			continue
		var flag := StringName("got_" + id)
		assert_eq(spec.verb, Interaction.Kind.TAKE, "%s : PRENDRE" % id)
		assert_eq(spec.sprite, &"object/poke_ball_ground", "même aspect (dossier 11 §11)")
		assert_eq(spec.unless_flags, [flag] as Array[StringName], "%s : retiré ensuite" % id)
		assert_false(spec.turn_to_player)
		var dialogue := _dialogues.get_dialogue(spec.dialogue)
		assert_not_null(dialogue, id)
		if dialogue == null:
			continue
		assert_eq(dialogue.variants[0].cutscene, StringName(id), "%s : lance sa scène" % id)
		assert_true(dialogue.variants[0].pages.is_empty(), "aucune bulle avant le toast")
		_check_item_scene(id, &"despawn", StringName(id))


func test_hidden_items_play_their_line_on_a_free_walkable_cell() -> void:
	var expected: Dictionary[String, String] = {
		"viridian_forest_item_3": "Quelque chose est caché sous les feuilles.",
		"viridian_forest_item_4": "Quelque chose est coincé entre les racines.",
		"viridian_forest_item_6": "Quelque chose dépasse derrière cette souche.",
	}
	var keys: Array[String] = []
	keys.assign(expected.keys())
	assert_eq(_ids_of("objet_cache"), keys)
	var occupied: Array[Vector2i] = []
	for spec: NpcSpec in _roster.get_all():
		occupied.append(spec.cell)
		occupied.append_array(spec.route_cells)
	for id: String in expected:
		var cell := _plan.cell_of(id)
		assert_true(_plan.is_walkable(cell) and _plan.at(cell) != "h",
			"%s : %s sur herbe rase" % [id, cell])
		assert_false(occupied.has(cell), "%s : aucun PNJ sur la cache" % id)
		var line_id := StringName(id + "_found")
		var dialogue := _dialogues.get_dialogue(line_id)
		assert_not_null(dialogue, String(line_id))
		if dialogue == null:
			continue
		assert_true(dialogue.narration, "texte environnemental (arbitrage 8)")
		assert_eq(dialogue.variants[0].pages.size(), 1)
		assert_eq(dialogue.variants[0].pages[0].text, expected[id])
		_check_item_scene(id, &"dialogue", line_id)


## Scène de l'objet [param id] : une variante sous « unless got_<id> » : [param first] (retrait
## du PNJ ou narration), puis l'objet de la grille au Sac (trouvé), puis le drapeau.
func _check_item_scene(id: String, first: StringName, first_ref: StringName) -> void:
	var cutscene := _cutscenes.get_cutscene(StringName(id))
	assert_not_null(cutscene, id)
	if cutscene == null:
		return
	var flag := StringName("got_" + id)
	assert_eq(cutscene.variants.size(), 1, id)
	var variant := cutscene.variants[0]
	assert_eq(variant.unless_flags, [flag] as Array[StringName], "%s : une fois" % id)
	assert_eq(variant.steps.size(), 3, id)
	var step := variant.steps[0]
	assert_eq(CutsceneStep.kind_name(step.kind), first, id)
	assert_eq(step.actor if step.kind == CutsceneStep.Kind.DESPAWN else step.dialogue_id,
		first_ref, id)
	var give := variant.steps[1]
	var item := StringName(_plan.attr(id, "item"))
	assert_true(_items.has_item(item), "%s : objet « %s »" % [id, item])
	assert_eq([give.kind, give.item_id, give.count, give.found],
		[CutsceneStep.Kind.GIVE, item, 1, true], "%s : %s ×1, trouvé" % [id, item])
	assert_eq(variant.steps[2].flags, [flag] as Array[StringName], id)


func test_naturalist_and_hiker_say_the_locked_lines() -> void:
	var dossier := FileAccess.get_file_as_string("res://docs/design/dossier-10-foret-de-jade.md")
	var expected: Dictionary[StringName, Array] = {
		&"forest_naturalist": ["Naturaliste", &"forest_naturalist_talked",
			"Certains Pokémon changent très vite\nquand ils grandissent.",
			"J'aimerais les observer évoluer ici."],
		&"forest_hiker": ["Randonneuse", &"forest_hiker_talked",
			"Plus on avance, plus Jadielle\nparaît loin, pas vrai ?",
			"Je garde toujours de quoi soigner\nmon équipe avant de repartir."],
	}
	for id: StringName in expected:
		var row: Array = expected[id]
		var dialogue := _dialogues.get_dialogue(id)
		assert_not_null(dialogue, String(id))
		if dialogue == null:
			continue
		assert_eq(dialogue.speaker, row[0])
		assert_eq(dialogue.variants.size(), 2, "première fois, puis ensuite")
		var first := dialogue.variants[0]
		assert_eq(first.unless_flags, [row[1]] as Array[StringName])
		assert_eq(first.set_flags, [row[1]] as Array[StringName])
		assert_eq(first.pages.size(), 1)
		assert_eq(first.pages[0].text, row[2])
		assert_eq(dialogue.variants[1].pages.size(), 1)
		assert_eq(dialogue.variants[1].pages[0].text, row[3])
		for text: String in [row[2], row[3]]:
			var quoted := PackedStringArray()
			for line: String in text.split("\n"):
				quoted.append("« %s »" % line)
			assert_string_contains(dossier, " / ".join(quoted))
