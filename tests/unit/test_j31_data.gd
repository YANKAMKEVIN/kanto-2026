extends GutTest
## Données du jalon 31 (T4 ; `docs/tech/jalon-31.md` §2.3 à §2.5, §5) : Mewtwo et Métamorph, tables
## de rencontres de RB par étage, Super Canne, objets historiques posés selon les grilles
## `tools/plans/cerulean_cave_*.txt`, rencontre fixe de Mewtwo sur la règle unique des légendaires
## ([StaticEncounter], celle d'Artikodin), aucun doublon après rechargement.

const PlanGrid := preload("res://tests/helpers/plan_grid.gd")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const O := Battle.Outcome
const FLOORS: Array[String] = ["1f", "2f", "b1f"]
## Taux RB par étage (`def_grass_wildmons` de pokered) et poids des dix emplacements de RB
## (51, 51, 39, 25, 25, 25, 13, 13, 11, 3 sur 256).
const RATES: Dictionary = {"1f": 10, "2f": 15, "b1f": 25}
const DONE := &"mewtwo_encounter_resolved"
const CAUGHT := &"mewtwo_caught"

var _data: PokemonData
var _items: ItemLibrary
var _cutscenes: CutsceneLibrary


func before_all() -> void:
	_data = PokemonData.new()
	_data.load_dir()
	_items = ItemLibrary.new()
	_items.load_dir()
	_cutscenes = CutsceneLibrary.new()
	_cutscenes.load_dir()


func _plan(floor_id: String) -> PlanGrid:
	var plan := PlanGrid.new()
	assert_true(plan.load_file("res://tools/plans/cerulean_cave_%s.txt" % floor_id), floor_id)
	return plan


func _mewtwo_step() -> CutsceneStep:
	for step: CutsceneStep in _cutscenes.get_cutscene(&"mewtwo").variants[0].steps:
		if step.kind == CutsceneStep.Kind.WILD_BATTLE:
			return step
	return null


# --- Espèces et capacités --------------------------------------------------------------------

func test_mewtwo_at_level_70_knows_the_red_blue_moves() -> void:
	var species := _data.get_species(&"mewtwo")
	assert_not_null(species)
	assert_eq(species.dex, 150)
	var mewtwo := PokemonFactory.create(_data, &"mewtwo", 70, GameRng.new(31))
	var moves: Array[String] = []
	for slot: MoveSlot in mewtwo.moves:
		moves.append(String(slot.move_id))
	moves.sort()
	assert_eq(moves, ["barrier", "psychic", "recover", "swift"] as Array[String],
		"Psyko, Soin, Météores, Bouclier (plan §2.5)")
	assert_eq(mewtwo.gender, Pokemon.Gender.NONE)


func test_every_learnset_move_of_the_new_species_exists() -> void:
	for id: StringName in [&"mewtwo", &"ditto", &"dodrio", &"venomoth", &"electrode", &"seaking",
			&"chansey", &"slowbro", &"kingler", &"seadra", &"rhydon"]:
		var species := _data.get_species(id)
		assert_not_null(species, String(id))
		if species == null:
			continue
		for move_id: StringName in species.moves_at(100):
			assert_true(_data.has_move(move_id), "%s : %s" % [id, move_id])


# --- Rencontres --------------------------------------------------------------------------------

func test_floor_tables_follow_red_blue() -> void:
	var library := EncounterLibrary.new(_data)
	assert_true(library.load_dir(), "tables de rencontres lues")
	for floor_id: String in FLOORS:
		var map := StringName("cerulean_cave_" + floor_id)
		var table := library.get_table(map, &"floor")
		assert_not_null(table, floor_id)
		if table == null:
			continue
		assert_eq(table.rate, RATES[floor_id], "%s : taux RB" % floor_id)
		assert_eq(table.total_weight(), 256, "%s : dix emplacements de RB" % floor_id)
		for slot: EncounterSlot in table.slots:
			assert_true(_data.has_species(slot.species), "%s : %s" % [floor_id, slot.species])
			assert_between(slot.min_level, 46, 67, "%s : haut niveau" % floor_id)
		assert_null(library.get_table(map, &"water"), "%s : aucune rencontre en Surf (RB)" % floor_id)


func test_super_rod_is_the_red_blue_group_9() -> void:
	# Sans données d'espèces : les tables communes de la passe systèmes 2 citent des espèces
	# (Magicarpe, Ptitard…) que cette base n'a pas encore ; les nôtres sont vérifiées ci-dessous.
	var tables := WaterRodTables.new()
	assert_true(tables.load_file(), "\n".join(tables.get_errors()))
	for floor_id: String in FLOORS:
		var table := tables.get_table(&"super_rod", StringName("cerulean_cave_" + floor_id))
		assert_not_null(table, floor_id)
		if table == null:
			continue
		assert_eq(table.id, &"super_rod_cerulean_cave", floor_id)
		var species: Array[String] = []
		for slot: EncounterSlot in table.slots:
			species.append(String(slot.species))
			assert_true(_data.has_species(slot.species), String(slot.species))
			assert_eq(slot.min_level, 23)
		species.sort()
		assert_eq(species, ["kingler", "seadra", "seaking", "slowbro"] as Array[String])


# --- Objets ----------------------------------------------------------------------------------

func test_items_of_the_grids_are_placed_and_given() -> void:
	var total := 0
	for floor_id: String in FLOORS:
		var plan := _plan(floor_id)
		var map := StringName("cerulean_cave_" + floor_id)
		var roster := NpcRoster.load_for_map(map)
		assert_eq(roster.get_errors().size(), 0, str(roster.get_errors()))
		for id: String in plan.positions:
			var kind: String = plan.positions[id]["kind"]
			if kind != "objet" and kind != "objet_cache":
				continue
			total += 1
			var item := StringName(plan.attr(id, "item"))
			assert_true(_items.has_item(item), "%s : %s existe" % [id, item])
			if kind == "objet":
				var spec := roster.get_spec(StringName(id))
				assert_not_null(spec, "%s : boule posée" % id)
				if spec != null:
					assert_eq(spec.cell, plan.cell_of(id), id)
					assert_eq(spec.unless_flags, [StringName("got_" + id)] as Array[StringName])
			var given: Array[StringName] = []
			for step: CutsceneStep in _cutscenes.get_cutscene(StringName(id)).variants[0].steps:
				if step.kind == CutsceneStep.Kind.GIVE:
					given.append(step.item_id)
			assert_eq(given, [item] as Array[StringName], "%s : donne %s" % [id, item])
	assert_eq(total, 10, "8 objets visibles et 2 cachés de RB")


func test_no_trainer_in_the_cave() -> void:
	for floor_id: String in FLOORS:
		for spec: NpcSpec in NpcRoster.load_for_map(StringName("cerulean_cave_" + floor_id)).get_all():
			assert_false(spec.is_trainer(), "%s : %s (plan §8.1, [D] aucun)" % [floor_id, spec.id])


# --- Mewtwo ------------------------------------------------------------------------------------

func test_mewtwo_is_a_static_legendary_encounter_at_70() -> void:
	var step := _mewtwo_step()
	assert_not_null(step)
	if step == null:
		return
	assert_eq([step.species, step.level, step.intro], [&"mewtwo", 70, CutsceneStep.INTRO_LEGENDARY])
	var fixed := step.static_encounter
	assert_not_null(fixed, "règle unique des légendaires")
	assert_eq([fixed.done_flag, fixed.caught_flag], [DONE, CAUGHT])
	assert_eq(step.actor, &"mewtwo")
	var plan := _plan("b1f")
	var spec := NpcRoster.load_for_map(&"cerulean_cave_b1f").get_spec(&"mewtwo")
	assert_not_null(spec)
	if spec != null:
		assert_eq(spec.cell, plan.cell_of("mewtwo"), "case de RB (27, 13)")
		assert_eq(spec.unless_flags, [DONE] as Array[StringName], "absent une fois résolu")


func test_outcomes_follow_the_articuno_policy_and_survive_a_reload() -> void:
	var step := _mewtwo_step()
	var roster := NpcRoster.load_for_map(&"cerulean_cave_b1f")
	var cases := {O.CAUGHT: [true, true], O.WIN: [true, false], O.FLED: [false, false],
		O.FOE_FLED: [false, false], O.LOSS: [false, false]}
	for outcome: int in cases:
		var flags := StoryFlags.new()
		for flag: StringName in step.outcome_flags(outcome):
			flags.set_flag(flag)
		assert_eq(step.static_encounter.needs_forced_save(outcome), cases[outcome][0],
			"issue %d : sauvegarde forcée" % outcome)
		var reloaded := StoryFlags.new()
		reloaded.load_array(JSON.parse_string(JSON.stringify(flags.to_array())))
		assert_eq([reloaded.has_flag(DONE), reloaded.has_flag(CAUGHT)], cases[outcome],
			"issue %d après rechargement" % outcome)
		var present := roster.get_present(reloaded).any(
			func(s: NpcSpec) -> bool: return s.id == &"mewtwo")
		assert_eq(present, not cases[outcome][0], "issue %d : Mewtwo %s" % [outcome,
			"reste" if not cases[outcome][0] else "absent"])


## Fermeture forcée pendant ou juste après le combat : la partie rechargée est soit celle d'avant
## (Mewtwo sur la carte, pas dans l'équipe), soit celle d'après (Mewtwo dans l'équipe, rencontre
## résolue), jamais les deux : la capture et le drapeau partent dans la même écriture.
func test_no_duplicate_whichever_save_survives() -> void:
	var state: Node = autofree(GameStateScript.new())
	state.new_game(31)
	state.party.add(PokemonFactory.create(_data, &"blastoise", 65, GameRng.new(1)))
	var before: Dictionary = state.to_dict()
	var mewtwo := PokemonFactory.create(_data, &"mewtwo", 70, GameRng.new(2))
	state.party.add(mewtwo)
	for flag: StringName in _mewtwo_step().outcome_flags(O.CAUGHT):
		state.flags.set_flag(flag)
	var after: Dictionary = state.to_dict()
	for snapshot: Dictionary in [before, after]:
		var loaded: Node = autofree(GameStateScript.new())
		assert_true(loaded.load_dict(JSON.parse_string(JSON.stringify(snapshot)), _data))
		var owned: int = loaded.party.get_all().filter(
			func(p: Pokemon) -> bool: return p.species_id == &"mewtwo").size()
		var on_map: bool = not loaded.flags.has_flag(DONE)
		assert_eq(owned + (1 if on_map else 0), 1, "un seul Mewtwo, sur la carte ou possédé")
