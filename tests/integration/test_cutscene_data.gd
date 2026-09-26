extends GutTest
## Cohérence des scènes scriptées de data/cutscenes/ avec les vraies cartes, les vrais PNJ
## et les vrais dialogues (jalon 3B §3.6, T4) :
## - chargement sans erreur ; chaque déclencheur vise une scène existante, chaque scène est
##   visée ; chaque dialogue d'étape existe ; chaque change_map vise une carte et un point
##   d'apparition existants ;
## - simulation statique de chaque variante : départ sur la carte de son déclencheur, avec
##   les drapeaux qui la choisissent ; « set » et « spawn » au fil des étapes ; à chaque
##   change_map, PNJ **présents** de la carte cible pour les drapeaux du moment. Chaque
##   acteur (face, move, follower, near), chaque cible de face qui n'est pas une direction,
##   et chaque acteur ou cible de « turn » des dialogues joués existe à ce moment-là.

const MAPS: Array[StringName] = [
	&"player_house_2f", &"player_house_1f", &"rival_house", &"oak_lab", &"pallet_town",
]
## Scène → drapeaux qui choisissent chaque variante, dans l'ordre (§3.6).
const VARIANT_FLAGS: Dictionary = {
	&"route1_grass": [[], [&"oak_met"]],
}

var _cutscenes: CutsceneLibrary
var _dialogues: DialogueLibrary
## Scène → cartes de ses déclencheurs.
var _triggered_on: Dictionary[StringName, Array] = {}


func before_all() -> void:
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()
	_dialogues = DialogueLibrary.new()
	_dialogues.load_dir()
	for map_id: StringName in MAPS:
		var map := (load(MapCatalog.scene_path(map_id)) as PackedScene).instantiate()
		for point: Node in map.get_node(^"Triggers").get_children():
			var id := (point as EventTriggerPoint).cutscene_id
			if not _triggered_on.has(id):
				_triggered_on[id] = []
			(_triggered_on[id] as Array).append(map_id)
		map.free()


func _all_steps() -> Array[CutsceneStep]:
	var steps: Array[CutsceneStep] = []
	for id: StringName in _cutscenes.get_ids():
		for variant: CutsceneVariant in _cutscenes.get_cutscene(id).variants:
			steps.append_array(variant.steps)
	return steps


func test_library_loads_without_error() -> void:
	var library := CutsceneLibrary.new()
	assert_true(library.load_dir(), "data/cutscenes/ se charge")
	assert_eq(library.get_errors().size(), 0, str(library.get_errors()))
	assert_eq(library.get_ids(), [&"route1_grass"] as Array[StringName])


func test_every_trigger_targets_a_scene_and_every_scene_is_triggered() -> void:
	assert_false(_triggered_on.is_empty())
	for id: StringName in _triggered_on:
		assert_true(_cutscenes.has_cutscene(id), "scène « %s » définie" % id)
	for id: StringName in _cutscenes.get_ids():
		assert_true(_triggered_on.has(id), "scène « %s » visée par un déclencheur" % id)
	assert_eq(_triggered_on.get(&"route1_grass"), [&"pallet_town"])


func test_every_dialogue_step_exists() -> void:
	for id: StringName in _cutscenes.get_dialogue_ids():
		assert_true(_dialogues.has_dialogue(id), "dialogue « %s » défini" % id)


func test_every_change_map_targets_an_existing_map_and_spawn() -> void:
	var count := 0
	for step: CutsceneStep in _all_steps():
		if step.kind != CutsceneStep.Kind.CHANGE_MAP:
			continue
		count += 1
		assert_true(MapCatalog.has_map(step.map_id), "carte « %s »" % step.map_id)
		if not MapCatalog.has_map(step.map_id):
			continue
		var map := (load(MapCatalog.scene_path(step.map_id)) as PackedScene).instantiate() \
				as GameMap
		assert_true(map.has_spawn(step.spawn), "%s : point « %s »" % [step.map_id, step.spawn])
		map.free()
	assert_eq(count, 1, "le retour au labo")


func test_every_variant_is_chosen_by_its_flags() -> void:
	for id: StringName in _cutscenes.get_ids():
		assert_true(VARIANT_FLAGS.has(id), "%s : drapeaux des variantes écrits" % id)
		var cutscene := _cutscenes.get_cutscene(id)
		var rows: Array = VARIANT_FLAGS.get(id, [])
		assert_eq(rows.size(), cutscene.variants.size())
		for i: int in mini(rows.size(), cutscene.variants.size()):
			assert_same(cutscene.pick(_flags(rows[i])), cutscene.variants[i],
				"%s : variante %d" % [id, i + 1])


func test_static_simulation_of_every_variant() -> void:
	var checked := 0
	for id: StringName in _cutscenes.get_ids():
		var cutscene := _cutscenes.get_cutscene(id)
		var rows: Array = VARIANT_FLAGS.get(id, [])
		for i: int in mini(rows.size(), cutscene.variants.size()):
			for map_id: StringName in _triggered_on.get(id, []):
				checked += _simulate("%s/%d" % [id, i + 1], cutscene.variants[i], map_id,
					_flags(rows[i]))
	assert_gt(checked, 20, "acteurs vérifiés")


## Joue [param variant] « à blanc » : renvoie le nombre d'acteurs vérifiés.
func _simulate(label: String, variant: CutsceneVariant, start_map: StringName,
		flags: StoryFlags) -> int:
	var map_id := start_map
	var actors := _present(map_id, flags)
	var checked := 0
	for step: CutsceneStep in variant.steps:
		var where := "%s sur %s (%s)" % [label, map_id, CutsceneStep.kind_name(step.kind)]
		var needed: Array[StringName] = []
		match step.kind:
			CutsceneStep.Kind.SET_FLAGS:
				for flag: StringName in step.flags:
					flags.set_flag(flag)
			CutsceneStep.Kind.SPAWN:
				assert_false(actors.has(step.spec.id), "%s : « %s » déjà là" % [where,
					step.spec.id])
				actors.append(step.spec.id)
			CutsceneStep.Kind.CHANGE_MAP:
				map_id = step.map_id
				actors = _present(map_id, flags)
			CutsceneStep.Kind.FACE:
				needed.append(step.actor)
				if not Grid.is_direction_name(step.target):
					needed.append(step.target)
			CutsceneStep.Kind.MOVE:
				needed.append(step.actor)
				for other: StringName in [step.follower, step.near]:
					if not other.is_empty():
						needed.append(other)
			CutsceneStep.Kind.DIALOGUE:
				var dialogue := _dialogues.get_dialogue(step.dialogue_id)
				var picked: DialogueVariant = dialogue.pick(flags) if dialogue != null else null
				assert_not_null(picked, "%s : « %s » a une variante" % [where,
					step.dialogue_id])
				if picked != null:
					for page: DialoguePage in picked.pages:
						for actor: StringName in page.turn:
							needed.append(actor)
							if not Grid.is_direction_name(page.turn[actor]):
								needed.append(page.turn[actor])
		for who: StringName in needed:
			checked += 1
			assert_true(actors.has(who), "%s : « %s » présent" % [where, who])
	return checked


## Joueur et PNJ présents sur [param map_id] pour [param flags].
func _present(map_id: StringName, flags: StoryFlags) -> Array[StringName]:
	var ids: Array[StringName] = [NpcRoster.PLAYER_ID]
	for spec: NpcSpec in NpcRoster.load_for_map(map_id).get_present(flags):
		ids.append(spec.id)
	return ids


func _flags(names: Array) -> StoryFlags:
	var flags := StoryFlags.new()
	for flag: StringName in names:
		flags.set_flag(flag)
	return flags
