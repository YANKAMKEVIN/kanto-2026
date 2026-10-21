extends GutTest
## La Tour Pokémon avec le Scope Sylphe dans une build du J20 sans J21 (jalon 20 T21,
## `jalon-20.md` §2.7.5 ; dossier 23 §14, §19 ; contrat du J19, `jalon-19.md` §9.3). Sauté si les
## cartes du J19 manquent. Vraie scène Boot, départ `tower_scope` (3F, Scope au Sac) :
## - une rencontre sauvage de la Tour est **identifiée** (pas de SPECTRE, Balls acceptées) ;
## - les tables de la Tour lisent le Sac (`ghost_unless_item: silph_scope`) ;
## - le SPECTRE du 6F reste `ghost: always` (le J21 l'ouvrira) ;
## - objectif « retourner à la Tour Pokémon. », plus « trouver un moyen de voir les spectres. »
##   (remplacé à l'obtention du Scope).

const HideoutPlay := preload("res://tests/helpers/hideout_play.gd")
const START := "res://tools/debug_start/tower_scope.json"
const SCOPE := &"silph_scope"

var _play: HideoutPlay


func before_each() -> void:
	_play = HideoutPlay.new(self, "user://test_tower_scope_j20.json")
	_play.setup()


func after_each() -> void:
	_play.teardown()


func _tower_ready() -> bool:
	if MapCatalog.has_map(&"pokemon_tower_3f") and MapCatalog.has_map(&"pokemon_tower_6f"):
		return true
	pending("cartes de la Tour (J19) absentes")
	return false


func test_tower_tables_read_the_bag_and_the_6f_ghost_stays_a_ghost() -> void:
	if not _tower_ready():
		return
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var library := EncounterLibrary.new(data)
	assert_true(library.load_file("res://data/encounters/pokemon_tower.json"))
	var bag := Bag.new()
	bag.add(SCOPE)
	assert_gt(library.get_ids().size(), 0)
	for id: StringName in library.get_ids():
		var table := library.get_table_by_id(id)
		assert_eq(table.ghost_unless_item, SCOPE, String(id))
		assert_false(GhostRule.is_ghost(table.ghost_unless_item, bag), "%s : identifié" % id)
	var cutscenes := CutsceneLibrary.new()
	assert_true(cutscenes.load_dir())
	var wild := 0
	for variant: CutsceneVariant in cutscenes.get_cutscene(&"tower_6f_ghost").variants:
		for step: CutsceneStep in variant.steps:
			if step.kind == CutsceneStep.Kind.WILD_BATTLE:
				wild += 1
				assert_eq(step.ghost_mode, GhostRule.ALWAYS, "6F : SPECTRE même avec le Scope")
	assert_gt(wild, 0, "le SPECTRE du 6F existe")


func test_a_wild_tower_encounter_is_identified_with_the_scope() -> void:
	if not _tower_ready():
		return
	await _play.start(START)
	assert_eq(_play.map_id(), &"pokemon_tower_3f")
	assert_eq(GameState.bag.count_of(SCOPE), 1)
	var objectives := ObjectiveLibrary.new()
	objectives.load_file()
	assert_eq(objectives.current_id(GameState.flags), &"back_to_tower",
		"« retourner à la Tour Pokémon. »")
	assert_true(GameState.flags.has_flag(&"tower_ghost_met"))
	GameState.party.get_lead().stats[&"spe"] = 999
	var battles := _play.boot.get_battle_director()
	assert_true(_play.boot.get_encounter_director().start_encounter(
		WildEncounter.new(&"gastly", 22)), "rencontre forcée")
	await wait_until(func() -> bool:
		return battles.get_battle() != null \
			and battles.get_battle().get_state() == Battle.State.CHOOSING, 15.0)
	var battle := battles.get_battle()
	assert_not_null(battle)
	if battle == null:
		return
	assert_false(battle.get_rules().ghost, "Scope en poche : pas de SPECTRE")
	assert_false(battle.refuses_balls(), "Balls acceptées")
	var hud := _play.boot.get_battle_hud()
	var box := _play.boot.get_dialogue_box()
	var deadline := Time.get_ticks_msec() + 60000
	while battles.is_running() and Time.get_ticks_msec() < deadline:
		var current := battles.get_battle()
		if current != null and current.get_state() == Battle.State.CHOOSING \
				and hud.get_zone() == BattleHud.Zone.ACTIONS:
			hud.action_selected.emit(ActionGrid.RUN)
		await wait_process_frames(1)
		if box.is_open():
			box.advance_requested.emit()
	assert_false(battles.is_running(), "fuite")
	assert_true(GameState.pokedex.is_seen(&"gastly"), "« vu » sous son vrai nom")
	assert_push_error_count(0)
