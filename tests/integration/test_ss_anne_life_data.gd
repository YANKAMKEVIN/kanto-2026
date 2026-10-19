extends GutTest
## La vie du navire, côté données (jalon 16 T12 ; `jalon-16.md` §3 « T12 », dossier 19 §0.5, §3, §4) :
## chaque position `dresseur`, `pnj`, `objet` et `cache` des grilles validées
## (`tools/plans/ss_anne_*.txt`, qui font foi) a son pendant dans `data/npcs/<carte>.json`
## (case, orientation, vision, Dresseur) ou dans la vraie scène (objet caché : point EXAMINER
## tourné vers l'indice, levé par `got_<id>`) ; chaque Dresseur a ses trois répliques (avant, vaincu,
## après) au nom de sa fiche, sa récompense (dossier §4) ; chaque objet, visible ou caché, se
## ramasse **une seule fois** (variante `unless got_…`, `found`) et donne l'objet de la grille.
## Le rival n° 4 et le capitaine (T13) ne sont pas encore posés : leurs positions sont ignorées.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const PLANS := "res://tools/plans/"
const MAPS: Dictionary[StringName, String] = {
	&"ss_anne_main_deck": "ss_anne_pont_principal.txt",
	&"ss_anne_lower_deck": "ss_anne_pont_inferieur.txt",
	&"ss_anne_restaurant": "ss_anne_restaurant.txt",
	&"ss_anne_outer_deck": "ss_anne_pont_exterieur.txt",
	&"ss_anne_cabin_a": "ss_anne_cabine_a.txt",
	&"ss_anne_cabin_b": "ss_anne_cabine_b.txt",
	&"ss_anne_cabin_c": "ss_anne_cabine_c.txt",
}
const DIRECTIONS := {"up": Vector2i.UP, "down": Vector2i.DOWN, "left": Vector2i.LEFT,
	"right": Vector2i.RIGHT}
## Dresseur → nom affiché (dossier §4 + R-10 + Scout Oscar de Kevin), récompense.
const TRAINERS := {
	&"ss_anne_gentleman_armand": ["Gentleman Armand", 760],
	&"ss_anne_sailor_erwan": ["Marin Erwan", 360],
	&"ss_anne_sailor_loic": ["Marin Loïc", 360],
	&"ss_anne_gentleman_emile": ["Gentleman Émile", 720],
	&"ss_anne_sailor_yann": ["Marin Yann", 360],
	&"ss_anne_sailor_remi": ["Marin Rémi", 380],
	&"ss_anne_lass_lena": ["Fillette Léna", 180],
	&"ss_anne_scout_basile": ["Scout Oscar", 360],
	&"ss_anne_gentleman_victor": ["Gentleman Victor", 760],
	&"ss_anne_sailor_paul": ["Marin Paul", 380],
}

var _dialogues := DialogueLibrary.new()
var _cutscenes := CutsceneLibrary.new()
var _trainers: TrainerLibrary
var _items := ItemLibrary.new()


func before_all() -> void:
	_dialogues.load_dir()
	_cutscenes.load_dir()
	var data := PokemonData.new()
	data.load_dir()
	_trainers = TrainerLibrary.new(data)
	_trainers.load_dir()
	_items.load_dir()


func _plan(id: StringName) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file(PLANS + MAPS[id]), "grille %s" % id)
	return plan


func _roster(id: StringName) -> NpcRoster:
	var roster := NpcRoster.load_for_map(id)
	assert_eq(roster.get_errors().size(), 0, "\n".join(roster.get_errors()))
	return roster


func _pages(id: StringName) -> Array[String]:
	var lines: Array[String] = []
	var dialogue := _dialogues.get_dialogue(id)
	assert_not_null(dialogue, "dialogue %s" % id)
	if dialogue == null:
		return lines
	for variant: DialogueVariant in dialogue.variants:
		for page: DialoguePage in variant.pages:
			lines.append(page.text)
	return lines


func test_every_dresseur_pnj_and_object_of_the_grids_is_placed() -> void:
	var trainers := 0
	var objects := 0
	for id: StringName in MAPS:
		var plan := _plan(id)
		var roster := _roster(id)
		var by_cell: Dictionary[Vector2i, NpcSpec] = {}
		for spec: NpcSpec in roster.get_all():
			assert_false(by_cell.has(spec.cell), "%s : deux PNJ en %s" % [id, spec.cell])
			by_cell[spec.cell] = spec
		var expected_cells := 0
		for position: String in plan.positions:
			var kind: String = plan.positions[position]["kind"]
			if kind not in ["dresseur", "pnj", "objet"]:
				continue
			var cell := plan.cell_of(position)
			var spec: NpcSpec = by_cell.get(cell)
			assert_not_null(spec, "%s/%s : un PNJ en %s" % [id, position, cell])
			if spec == null:
				continue
			expected_cells += 1
			if kind == "dresseur":
				trainers += 1
				assert_eq(spec.facing, DIRECTIONS[plan.attr(position, "facing")],
					"%s/%s : orientation" % [id, position])
				assert_true(spec.is_trainer(), "%s/%s : Dresseur" % [id, position])
				assert_eq(String(spec.trainer_id), plan.attr(position, "trainer"),
					"%s/%s : identifiant" % [id, position])
				assert_eq(spec.sight, int(plan.attr(position, "sight")),
					"%s/%s : vision" % [id, position])
			elif kind == "pnj":
				assert_false(spec.is_trainer(), "%s/%s : pas Dresseur" % [id, position])
				if plan.attr(position, "facing") != "":
					assert_eq(spec.facing, DIRECTIONS[plan.attr(position, "facing")],
						"%s/%s : orientation" % [id, position])
			else:
				objects += 1
				assert_eq(spec.sprite, &"object/poke_ball_ground", "%s : objet visible" % position)
				_check_pickup(spec.dialogue, StringName(plan.attr(position, "item")))
		assert_eq(roster.size(), expected_cells,
			"%s : ni PNJ en trop, ni fantôme (le rival et le capitaine sont au T13)" % id)
	assert_eq(trainers, 10, "10 Dresseurs sur le navire")
	assert_eq(objects, 6, "6 objets visibles")


func test_trainer_lines_names_and_prizes() -> void:
	var seen: Array[StringName] = []
	for id: StringName in MAPS:
		for spec: NpcSpec in _roster(id).get_all():
			if not spec.is_trainer():
				continue
			seen.append(spec.trainer_id)
			var trainer := _trainers.get_trainer(spec.trainer_id)
			assert_not_null(trainer, "%s : Dresseur défini" % spec.trainer_id)
			var info: Array = TRAINERS[spec.trainer_id]
			assert_eq(trainer.name, info[0], "%s : nom de la fiche" % spec.trainer_id)
			assert_eq(trainer.prize_money, info[1], "%s : récompense" % spec.trainer_id)
			for dialogue_id: StringName in [spec.before_dialogue, spec.defeated_dialogue,
					spec.dialogue]:
				var dialogue := _dialogues.get_dialogue(dialogue_id)
				assert_not_null(dialogue, "%s : réplique %s" % [spec.trainer_id, dialogue_id])
				if dialogue != null:
					assert_eq(dialogue.speaker, info[0], "%s : locuteur" % dialogue_id)
					assert_false(dialogue.narration)
					assert_eq(_pages(dialogue_id).size(), 1, "%s : une bulle" % dialogue_id)
	seen.sort()
	var wanted: Array[StringName] = []
	wanted.assign(TRAINERS.keys())
	wanted.sort()
	assert_eq(seen, wanted, "les 10 Dresseurs du navire, un par carte de grille")


func test_hidden_items_are_examine_points_facing_the_clue_and_pickable_once() -> void:
	var count := 0
	for id: StringName in MAPS:
		var plan := _plan(id)
		var points: Dictionary[Vector2i, Node] = {}
		var scene := (load("res://game/world/maps/%s.tscn" % id) as PackedScene).instantiate()
		var interactables := scene.get_node_or_null(^"Interactables")
		if interactables != null:
			for point: Node in interactables.get_children():
				points[(point as InteractPoint).get_cell()] = point
		for position: String in plan.positions:
			if plan.positions[position]["kind"] != "cache":
				continue
			count += 1
			var clue := plan.cell_of(position)
			var point := points.get(clue) as InteractPoint
			assert_not_null(point, "%s/%s : point EXAMINER sur l'indice %s" % [id, position, clue])
			if point == null:
				continue
			assert_eq(point.kind, Interaction.Kind.EXAMINE)
			assert_ne(point.facing, Vector2i.ZERO, "de face seulement")
			assert_true(plan.is_walkable(clue - point.facing),
				"%s/%s : le joueur se tient en %s" % [id, position, clue - point.facing])
			var flag := StringName("got_" + String(point.dialogue_id))
			assert_eq(point.unless_flags, [flag] as Array[StringName], "levé par %s" % flag)
			_check_pickup(point.dialogue_id, StringName(plan.attr(position, "item")))
		scene.free()
	assert_eq(count, 3, "3 objets cachés")


## Dialogue [param dialogue_id] → scène unique : donne [param item] une fois (`unless got_…`).
func _check_pickup(dialogue_id: StringName, item: StringName) -> void:
	var dialogue := _dialogues.get_dialogue(dialogue_id)
	assert_not_null(dialogue, "dialogue %s" % dialogue_id)
	if dialogue == null:
		return
	assert_eq(dialogue.variants[0].cutscene, dialogue_id, "%s : la scène du même nom" % dialogue_id)
	assert_true(_cutscenes.has_cutscene(dialogue_id), "scène %s" % dialogue_id)
	assert_true(_items.has_item(item), "objet %s défini" % item)
	var raw := FileAccess.get_file_as_string("res://data/cutscenes/ss_anne_life.json")
	var data: Dictionary = JSON.parse_string(raw)
	var variants: Array = data[String(dialogue_id)]["variants"]
	assert_eq(variants.size(), 1, "%s : une variante" % dialogue_id)
	var flag := "got_" + String(dialogue_id)
	assert_eq(variants[0]["unless"], [flag], "%s : une seule fois" % dialogue_id)
	var gives: Array = []
	var sets: Array = []
	for step: Dictionary in variants[0]["steps"]:
		if step.has("give"):
			gives.append(step)
		if step.has("set"):
			sets.append_array(step["set"])
	assert_eq(gives.size(), 1)
	assert_eq(gives[0]["give"], String(item), "%s : objet de la grille" % dialogue_id)
	assert_eq(int(gives[0]["count"]), 1)
	assert_true(gives[0]["found"], "journal des objets trouvés")
	assert_eq(sets, [flag], "drapeau %s" % flag)
