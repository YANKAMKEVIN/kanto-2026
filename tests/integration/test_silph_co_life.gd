extends GutTest
## La vie de la Sylphe SARL, 1F à 6F et 8F à 10F (jalon 26 T9 et T13 ; `docs/tech/jalon-26.md` §2.2,
## §2.3, §3) sur les **vraies cartes et leurs PNJ** (`data/npcs/silph_co_<n>f.json`) ; le 7F et le
## 11F (rival, Lokhlass, Giovanni, président) sont à un autre agent :
## - PNJ, Dresseurs et objets sont ceux des grilles `sylphe_<n>f.txt` (cases, orientations,
##   conditions) ; les Dresseurs sont des **données** (bloc `trainer` : identifiant de
##   `data/trainers/silph_co.json`, vision et orientation de la grille) ;
## - occupation : sbires et scientifiques `unless [silph_giovanni_defeated]` ; employés présents des
##   deux côtés, avec une réplique libérée (variante `if`) ; hôtesse T26-04 puis T26-20 ;
## - objets au sol et cachés de la liste RB avec les `fallback` de la grille ; rapports du 5F ;
##   infirmière du 9F qui soigne ;
## - **la Carte Magnétique du 5F** : objet au sol, ramassée une fois (drapeau
##   `got_silph_co_5f_card_key`, toast T26-06), même après un redémarrage ;
## - aucune condition de Badge.
## Le drapeau de libération est posé à la main : la scène de Giovanni vient au T12.

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const FLAG := &"silph_giovanni_defeated"
const START := "res://tools/debug_start/silph_1f.json"
const SAVE_PATH := "user://test_silph_co_life.json"
const FLOORS: Array[int] = [1, 2, 3, 4, 5, 6, 8, 9, 10]
const TIMEOUT := 15.0
## Objets au sol / cachés (grille → objet) : l'objet de la liste RB, sinon son `fallback`.
const CARD := &"silph_co_5f_card_key"
const CARD_CELL := Vector2i(21, 16)

var _play: HideoutPlay
var _dialogues: DialogueLibrary
var _cutscenes: CutsceneLibrary
var _items: ItemLibrary
var _trainers: TrainerLibrary


func before_all() -> void:
	_dialogues = DialogueLibrary.new()
	assert_true(_dialogues.load_dir())
	_cutscenes = CutsceneLibrary.new()
	assert_true(_cutscenes.load_dir())
	_items = ItemLibrary.new()
	_items.load_dir()
	var pokemon := PokemonData.new()
	pokemon.load_dir()
	_trainers = TrainerLibrary.new(pokemon)
	_trainers.load_dir()


func before_each() -> void:
	_play = HideoutPlay.new(self, SAVE_PATH)
	_play.setup()


func after_each() -> void:
	_play.teardown()


func _flags(liberated: bool) -> StoryFlags:
	var flags := StoryFlags.new()
	if liberated:
		flags.set_flag(FLAG)
	return flags


func _map_id(n: int) -> StringName:
	return StringName("silph_co_%df" % n)


func _plan(n: int) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/sylphe_%df.txt" % n), plan.error)
	return plan


func _load_map(n: int) -> GameMap:
	var map := (load(MapCatalog.scene_path(_map_id(n))) as PackedScene).instantiate() as GameMap
	add_child_autofree(map)
	return map


func _spec_at(roster: NpcRoster, cell: Vector2i) -> NpcSpec:
	for spec: NpcSpec in roster.get_all():
		if spec.cell == cell:
			return spec
	return null


func _texts(id: StringName, variant: int) -> Array:
	var texts: Array = []
	for page: DialoguePage in _dialogues.get_dialogue(id).variants[variant].pages:
		texts.append(page.text)
	return texts


func _expected_item(plan: PlanGrid, id: String) -> StringName:
	var item := StringName(plan.attr(id, "item"))
	if _items.has_item(item):
		return item
	return StringName(plan.attr(id, "fallback"))


# --- Dresseurs, PNJ et objets : ceux des grilles ----------------------------------------------

func test_every_grid_trainer_is_data_with_the_grid_sight_and_facing() -> void:
	var total := 0
	for n: int in FLOORS:
		var plan := _plan(n)
		var roster := NpcRoster.load_for_map(_map_id(n))
		assert_eq(roster.get_errors().size(), 0, str(roster.get_errors()))
		for id: String in plan.positions:
			if plan.positions[id]["kind"] != "dresseur":
				continue
			total += 1
			var trainer := StringName(plan.attr(id, "trainer"))
			var spec := _spec_at(roster, plan.cells_at(id)[0])
			assert_not_null(spec, "%s %s posé" % [_map_id(n), id])
			if spec == null:
				continue
			assert_true(spec.is_trainer(), "%s : Dresseur en données" % trainer)
			assert_eq(spec.trainer_id, trainer)
			assert_true(_trainers.has_trainer(trainer), "%s : équipe de silph_co.json" % trainer)
			assert_eq(spec.sight, int(plan.attr(id, "sight")), "%s : vision" % trainer)
			assert_eq(spec.facing, Grid.direction_from_name(plan.attr(id, "facing")), trainer)
			assert_eq(spec.unless_flags, [FLAG] as Array[StringName], "%s : occupation" % trainer)
			assert_eq(spec.before_dialogue, StringName("%s_before" % trainer))
			assert_eq(spec.defeated_dialogue, StringName("%s_defeated" % trainer))
			assert_eq(spec.dialogue, StringName("%s_after" % trainer))
	# 30 Dresseurs au total (hors rival et Giovanni) : 4 au 7F et 2 au 11F sont à l'autre agent.
	assert_eq(total, 24, "24 Dresseurs sur les neuf étages de ce lot")


func test_npcs_and_objects_are_the_plan_ones() -> void:
	for n: int in FLOORS:
		var plan := _plan(n)
		var roster := NpcRoster.load_for_map(_map_id(n))
		var wanted := 0
		for id: String in plan.positions:
			var kind: String = plan.positions[id]["kind"]
			if not ["pnj", "dresseur", "objet_visible"].has(kind):
				continue
			wanted += 1
			var spec := _spec_at(roster, plan.cells_at(id)[0])
			assert_not_null(spec, "%s %s" % [_map_id(n), id])
			if spec == null:
				continue
			if kind == "pnj":
				assert_eq(spec.facing, Grid.direction_from_name(plan.attr(id, "facing")), id)
				assert_true(_dialogues.has_dialogue(spec.dialogue), "%s : dialogue" % id)
			if kind == "objet_visible":
				assert_eq(spec.sprite, &"object/poke_ball_ground", id)
				assert_eq(spec.verb, Interaction.Kind.TAKE, "%s : PRENDRE" % id)
				assert_eq(spec.unless_flags, [StringName("got_%s" % id)] as Array[StringName], id)
		assert_eq(roster.get_all().size(), wanted, "%s : aucun PNJ hors de la grille" % _map_id(n))


func test_occupied_then_liberated_presence() -> void:
	for n: int in FLOORS:
		var roster := NpcRoster.load_for_map(_map_id(n))
		for spec: NpcSpec in roster.get_all():
			var occupied := spec.is_present(_flags(false))
			var freed := spec.is_present(_flags(true))
			if spec.is_trainer():
				assert_true(occupied, "%s présent pendant l'occupation" % spec.id)
				assert_false(freed, "%s parti à la libération" % spec.id)
			elif spec.id == &"silph_co_porygon_giver":
				# Jalon 32 (N-13) : l'employé de Porygon n'arrive qu'après Giovanni.
				assert_false(occupied, "%s absent pendant l'occupation" % spec.id)
				assert_true(freed, "%s présent après Giovanni" % spec.id)
			else:
				assert_true(occupied and freed, "%s : présent des deux côtés" % spec.id)
	var map := _load_map(2)
	map.refresh_npcs(_flags(false))
	assert_not_null(map.get_npc(&"silph_co_2f_3"), "sbire en place")
	map.refresh_npcs(_flags(true))
	assert_null(map.get_npc(&"silph_co_2f_3"), "sbire parti")
	assert_not_null(map.get_npc(&"silph_co_2f_worker_1"), "employé resté")


# --- Textes ----------------------------------------------------------------------------------

func test_hostess_and_employees_change_their_line_when_liberated() -> void:
	assert_eq(_dialogues.get_dialogue(&"silph_co_1f_receptionist").speaker, "Hôtesse")
	assert_eq(_dialogues.get_dialogue(&"silph_co_1f_receptionist").variants[0].if_flags,
		[FLAG] as Array[StringName])
	assert_eq(_texts(&"silph_co_1f_receptionist", 0),
		["Bienvenue à la Sylphe SARL ! Grâce à toi, tout est rentré dans l'ordre."], "T26-20")
	assert_eq(_texts(&"silph_co_1f_receptionist", 1),
		["Je… je ne peux rien dire. Ils sont partout dans les étages."], "T26-04")
	var workers := 0
	for n: int in FLOORS:
		for spec: NpcSpec in NpcRoster.load_for_map(_map_id(n)).get_all():
			if not String(spec.dialogue).contains("_worker_"):
				continue
			workers += 1
			var dialogue := _dialogues.get_dialogue(spec.dialogue)
			assert_eq(dialogue.variants.size(), 2, "%s : libérée puis occupée" % spec.id)
			assert_eq(dialogue.variants[0].if_flags, [FLAG] as Array[StringName], spec.id)
			assert_true(dialogue.variants[1].if_flags.is_empty(), spec.id)
	assert_eq(workers, 11, "onze employés (2F, 3F, 4F, 5F, 6F ×5, 8F, 10F)")


func test_nurse_of_the_9f_heals() -> void:
	var nurse := _dialogues.get_dialogue(&"silph_co_9f_nurse")
	assert_eq(nurse.variants.size(), 1)
	assert_eq(nurse.variants[0].action, &"heal", "RB : l'infirmière du 9F soigne l'équipe")
	var spec := _spec_at(NpcRoster.load_for_map(&"silph_co_9f"), Vector2i(3, 14))
	assert_eq(spec.dialogue, &"silph_co_9f_nurse")
	assert_eq(spec.sprite, &"nurse")


func test_card_key_toast_and_reports_texts() -> void:
	assert_eq(_texts(&"silph_co_5f_card_key_got", 0), ["{player} obtient la Carte Magnétique !"],
		"T26-06")
	assert_true(_dialogues.get_dialogue(&"silph_co_5f_card_key_got").narration)
	var map := _load_map(5)
	var plan := _plan(5)
	for id: String in plan.positions:
		if plan.positions[id]["kind"] != "examen":
			continue
		var cell: Vector2i = plan.cells_at(id)[0]
		var point := map.get_interactions().find(cell, Vector2i.DOWN)
		assert_not_null(point, "%s : rapport lisible" % id)
		if point != null:
			assert_eq(String(point.dialogue_id), plan.attr(id, "texte"))
			assert_eq(_texts(point.dialogue_id, 0).size(), 1)


# --- Objets au sol et cachés ----------------------------------------------------------------

func test_ground_items_give_the_rb_object_or_its_fallback_once() -> void:
	var count := 0
	for n: int in FLOORS:
		var plan := _plan(n)
		for id: String in plan.positions:
			var kind: String = plan.positions[id]["kind"]
			if kind != "objet_visible" and kind != "objet_cache":
				continue
			count += 1
			var cutscene := _cutscenes.get_cutscene(StringName(id))
			assert_not_null(cutscene, "%s : scène" % id)
			if cutscene == null:
				continue
			assert_eq(cutscene.variants.size(), 1, "%s : une seule fois" % id)
			var variant: CutsceneVariant = cutscene.variants[0]
			assert_eq(variant.unless_flags, [StringName("got_%s" % id)] as Array[StringName])
			var gave := ""
			for step: CutsceneStep in variant.steps:
				if step.kind == CutsceneStep.Kind.GIVE:
					gave = String(step.item_id)
					assert_true(step.found, "%s : objet trouvé" % id)
			assert_eq(gave, String(_expected_item(plan, id)), "%s : objet ou repli" % id)
			assert_true(_items.has_item(StringName(gave)), "%s : objet connu" % id)
			assert_eq(_dialogues.get_dialogue(StringName(id)).variants[0].cutscene, StringName(id))
	assert_eq(count, 14, "douze objets au sol (dont la Carte) et deux cachés (liste RB)")


func test_hidden_items_are_examine_points_found_once() -> void:
	for pair: Array in [[5, "silph_co_5f_hidden_1", Vector2i(12, 3)],
			[9, "silph_co_9f_hidden_1", Vector2i(2, 15)]]:
		var map := _load_map(pair[0])
		var point := map.get_interactions().find(pair[2], Vector2i.UP)
		assert_not_null(point, "%s : lu depuis le sud, tourné vers le nord" % pair[1])
		if point != null:
			assert_eq(String(point.dialogue_id), pair[1])
			assert_eq(point.unless_flags, [StringName("got_%s" % pair[1])] as Array[StringName])


# --- La Carte Magnétique du 5F (Boot réel) -----------------------------------------------------

func test_card_key_is_on_the_floor_and_picked_up_once_even_after_a_restart() -> void:
	var spec := _spec_at(NpcRoster.load_for_map(&"silph_co_5f"), CARD_CELL)
	assert_not_null(spec, "Carte posée au 5F en (21, 16)")
	assert_eq(String(spec.id), String(CARD))
	assert_eq(spec.verb, Interaction.Kind.TAKE)
	assert_eq(spec.unless_flags, [&"got_silph_co_5f_card_key"] as Array[StringName])
	await _play.start(START, func() -> void:
		GameState.flags.set_flag(&"beaten_silph_co_5f_1")
		GameState.flags.set_flag(&"beaten_silph_co_5f_4"))
	assert_false(GameState.bag.has(&"card_key"), "départ sans Carte")
	# Arrivée sur la dalle du couloir sud (9, 15), un pas vers le bas, puis le couloir.
	await SceneRouter.change_map(&"silph_co_5f", &"tp_5", Vector2i.DOWN)
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	assert_not_null(_play.boot.get_map().get_npc(CARD), "la Carte est au sol")
	await _play.step(Vector2i.DOWN)
	await _play.walk_to(Vector2i(20, 16))
	assert_eq(_play.player.get_cell(), Vector2i(20, 16))
	_play.events.clear()
	await _play.interact(Vector2i.RIGHT)
	await wait_until(func() -> bool: return GameState.flags.has_flag(&"got_silph_co_5f_card_key"),
		TIMEOUT)
	await wait_until(func() -> bool: return _play.boot.is_stable(), TIMEOUT)
	assert_true(GameState.bag.has(&"card_key"), "Carte Magnétique obtenue")
	assert_eq(GameState.bag.count_of(&"card_key"), 1)
	assert_true(_play.pages().has("Kevin obtient la Carte Magnétique !"), "toast T26-06")
	assert_null(_play.boot.get_map().get_npc(CARD), "ramassée : elle disparaît")
	# Une seconde tentative ne donne rien.
	await _play.interact(Vector2i.RIGHT)
	assert_eq(GameState.bag.count_of(&"card_key"), 1, "une seule fois")
	# Application relancée : le drapeau est sauvegardé, la Carte reste ramassée.
	await _play.resume()
	assert_true(GameState.flags.has_flag(&"got_silph_co_5f_card_key"), "drapeau rechargé")
	assert_eq(GameState.bag.count_of(&"card_key"), 1)
	assert_eq(_play.map_id(), &"silph_co_5f")
	assert_null(_play.boot.get_map().get_npc(CARD), "toujours ramassée après rechargement")
	assert_push_error_count(0)


# --- Aucune condition de Badge ---------------------------------------------------------------

func test_no_badge_condition_in_the_life_data() -> void:
	var paths: Array[String] = ["res://data/dialogues/silph_co_life.json",
		"res://data/cutscenes/silph_co_life.json"]
	for n: int in FLOORS:
		paths.append("res://data/npcs/%s.json" % _map_id(n))
	for path: String in paths:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.is_empty(), path)
		assert_false(text.contains("badge"), "%s : aucune condition de Badge" % path)
