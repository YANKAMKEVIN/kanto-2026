extends GutTest
## Rencontre légendaire fixe branchée sur l'étape de scène « wild_battle » (passe systèmes 2, T30,
## `systemes-2.md` §3.8 ; politique d'Artikodin, `jalon-24.md` §2.7), sur une mini-carte (PNJ de
## tests/fixtures/npcs/legend_map.json : le Pokémon « legend » (5, 6), caché par `legend_done`),
## avec un vrai joueur, un vrai CutsceneDirector, un vrai DialogueRunner (texte instantané), un
## faux combat (issue imposée), un faux réveil et un faux gestionnaire de sauvegarde :
## - capture → `done` + `caught` (+ « catch ») ; K.O. → `done` (+ « win ») ; fuite, fuite du
##   sauvage ou défaite → rien ;
## - une issue qui consomme la rencontre force la sauvegarde **après** le combat et **avant** le
##   premier texte qui suit ; jamais sinon ; une écriture en panne retient la scène ;
## - le Pokémon quitte la carte quand la rencontre est consommée, et n'y revient pas (présence
##   par drapeaux, « unless ») ; il reste après une fuite ;
## - « intro: legendary » arrive au combat ([member WildEncounter.legendary_intro]).

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const BOX_SCENE := preload("res://game/ui/dialogue/dialogue_box.tscn")
const NPCS := "res://tests/fixtures/npcs/"
const MAP_ID := &"legend_map"
const LEGEND := &"legend"
const LEGEND_CELL := Vector2i(5, 6)
const START := Vector2i(5, 8)
const TIMEOUT := 5.0
const DONE := &"legend_done"
const CAUGHT := &"legend_caught"
const CATCH_EXTRA := &"legend_catch_extra"
const KO_EXTRA := &"legend_ko"
const DIALOGUES := {
	"legend_observe": {"pages": ["Un Pokémon majestueux."]},
	"legend_cry": {"pages": ["Kyaaah !"]},
	"legend_after_ko": {"pages": ["Il s'est envolé."]},
	"legend_after_catch": {"pages": ["Capturé."]},
	"legend_still_there": {"pages": ["Il est toujours là."]},
}
const SCENES := {
	"legend": {"variants": [{"unless": ["legend_done"], "steps": [
		{"dialogue": "legend_cry"},
		{"wild_battle": "pidgey", "level": 50, "intro": "legendary", "actor": "legend",
			"static": {"done": "legend_done", "caught": "legend_caught"},
			"catch": ["legend_catch_extra"], "win": ["legend_ko"]},
		{"dialogue": "legend_after_ko", "if": ["legend_done"], "unless": ["legend_caught"]},
		{"dialogue": "legend_after_catch", "if": ["legend_caught"]},
		{"dialogue": "legend_still_there", "unless": ["legend_done"]},
	]}]},
	"plain": {"steps": [
		{"wild_battle": "pidgey", "level": 5},
		{"dialogue": "legend_still_there"},
	]},
}


## Faux combat sauvage : issue imposée, rencontre et ordre notés, deux images de combat.
class StubRunner extends BattleDirector:
	var outcome_to_return: int = Battle.Outcome.CAUGHT
	var encounters: Array[WildEncounter] = []
	var log: Array[String] = []

	func run_wild(encounter: WildEncounter, _map: GameMap, _origin: Vector2i) -> int:
		encounters.append(encounter)
		log.append("battle")
		await get_tree().process_frame
		await get_tree().process_frame
		return outcome_to_return


## Faux réveil après une défaite : compte les appels.
class StubRecovery extends DefeatRecovery:
	var calls: int = 0

	func recover() -> void:
		calls += 1
		await get_tree().process_frame


var _router: Node
var _world: Node2D
var _player: Player
var _box: DialogueBox
var _runner: DialogueRunner
var _director: CutsceneDirector
var _flags: StoryFlags
var _map: GameMap
var _battles: StubRunner
var _recovery: StubRecovery
## Ordre des événements : « dialogue:<id> », « battle », « save:<raison> ».
var _log: Array[String] = []
## Réponses successives du faux gestionnaire de sauvegarde (OK quand la liste est vide).
var _save_errors: Array[Error] = []


func before_each() -> void:
	_log.clear()
	_save_errors.clear()
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.add_from_dict(DIALOGUES, "test"))
	var scenes := CutsceneLibrary.new()
	assert_true(scenes.add_from_dict(SCENES, "test"), str(scenes.get_errors()))
	_flags = StoryFlags.new()
	_router = ROUTER_SCRIPT.new()
	add_child_autofree(_router)
	_router.map_factory = _make_map
	_world = Node2D.new()
	add_child_autofree(_world)
	_player = PLAYER_SCENE.instantiate() as Player
	autofree(_player)
	_box = BOX_SCENE.instantiate() as DialogueBox
	add_child_autofree(_box)
	_runner = DialogueRunner.new()
	_runner.chars_per_second = 0.0
	add_child_autofree(_runner)
	_runner.setup(dialogues, _flags, _box, _player)
	_runner.dialogue_started.connect(func(id: StringName) -> void: _log.append("dialogue:%s" % id))
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, _runner, _player, _router)
	_director.save_retry_delay = 0.0
	_director.save_handler = _fake_save
	_battles = StubRunner.new()
	_battles.log = _log
	add_child_autofree(_battles)
	_director.set_battle_runner(_battles)
	_recovery = StubRecovery.new()
	add_child_autofree(_recovery)
	_director.set_recovery(_recovery)
	_router.setup(_world, _player, null)
	_router.map_changed.connect(_director.set_map)
	_map = _router.start(MAP_ID, &"start", Vector2i.UP)
	_map.refresh_npcs(_flags)
	_player.set_process(false)


func _fake_save(reason: String) -> Error:
	_log.append("save:%s" % reason)
	return _save_errors.pop_front() if not _save_errors.is_empty() else OK


## Carte 20 × 18 sans tuiles, PNJ du fixture, départ (5, 8) tourné vers le haut.
func _make_map(map_id: StringName) -> GameMap:
	var map := GameMap.new()
	map.name = "LegendMap"
	map.map_id = map_id
	map.npcs_dir = NPCS
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns", "Triggers"]:
		var node := Node2D.new()
		node.name = group
		node.y_sort_enabled = group == "Entities"
		map.add_child(node)
	var marker := Marker2D.new()
	marker.name = "start"
	marker.position = Grid.cell_to_world(START)
	map.get_node(^"Spawns").add_child(marker)
	return map


## Joue la scène [param id] avec l'issue [param outcome] jusqu'au bout, en fermant chaque
## dialogue (une image d'écart).
func _play(id: StringName, outcome: int) -> void:
	_battles.outcome_to_return = outcome
	assert_true(_director.play(id), "scène lancée")
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if _runner.is_running():
			_box.advance_requested.emit()
	assert_false(_director.is_running(), "scène terminée")


func _save_entry() -> String:
	return "save:" + CutsceneDirector.STATIC_SAVE_REASON % LEGEND


func _flags_set() -> Array[StringName]:
	var found: Array[StringName] = []
	for flag: StringName in [DONE, CAUGHT, CATCH_EXTRA, KO_EXTRA]:
		if _flags.has_flag(flag):
			found.append(flag)
	return found


# --- Issues → drapeaux, sauvegarde, acteur ----------------------------------------------

func test_capture_sets_done_and_caught_saves_before_the_next_text_and_hides_the_actor() -> void:
	assert_not_null(_map.get_npc(LEGEND), "le Pokémon est là avant la rencontre")
	await _play(&"legend", Battle.Outcome.CAUGHT)
	assert_eq(_flags_set(), [DONE, CAUGHT, CATCH_EXTRA] as Array[StringName])
	assert_eq(_log, ["dialogue:legend_cry", "battle", _save_entry(),
		"dialogue:legend_after_catch"] as Array[String], "sauvegarde avant le premier texte")
	assert_null(_map.get_npc(LEGEND), "retiré de la carte")
	assert_null(_map.get_grid().get_occupant(LEGEND_CELL), "case libérée")
	assert_true(_player.is_input_enabled(), "contrôle rendu")
	assert_push_error_count(0)


func test_knock_out_sets_done_only_saves_and_hides_the_actor() -> void:
	await _play(&"legend", Battle.Outcome.WIN)
	assert_eq(_flags_set(), [DONE, KO_EXTRA] as Array[StringName])
	assert_eq(_log, ["dialogue:legend_cry", "battle", _save_entry(),
		"dialogue:legend_after_ko"] as Array[String])
	assert_null(_map.get_npc(LEGEND))
	assert_push_error_count(0)


func test_flee_changes_nothing_no_save_and_the_actor_stays() -> void:
	for outcome: int in [Battle.Outcome.FLED, Battle.Outcome.FOE_FLED]:
		_log.clear()
		await _play(&"legend", outcome)
		assert_eq(_flags_set(), [] as Array[StringName], str(outcome))
		assert_eq(_log, ["dialogue:legend_cry", "battle", "dialogue:legend_still_there"]
			as Array[String], "aucune sauvegarde forcée (%d)" % outcome)
		assert_not_null(_map.get_npc(LEGEND), "toujours là (%d)" % outcome)
	assert_push_error_count(0)


func test_defeat_changes_nothing_no_save_wakes_up_and_the_actor_stays() -> void:
	await _play(&"legend", Battle.Outcome.LOSS)
	assert_eq(_flags_set(), [] as Array[StringName])
	assert_eq(_log, ["dialogue:legend_cry", "battle"] as Array[String],
		"ni sauvegarde forcée ni texte : la scène s'arrête au réveil")
	assert_eq(_recovery.calls, 1, "réveil")
	assert_not_null(_map.get_npc(LEGEND))
	assert_push_error_count(0)


func test_a_failed_write_holds_the_scene_until_it_succeeds() -> void:
	_save_errors.assign([ERR_FILE_CANT_WRITE, ERR_FILE_CANT_WRITE])
	watch_signals(_director)
	await _play(&"legend", Battle.Outcome.CAUGHT)
	assert_signal_emit_count(_director, "save_failed", 2)
	assert_eq(_log, ["dialogue:legend_cry", "battle", _save_entry(), _save_entry(),
		_save_entry(), "dialogue:legend_after_catch"] as Array[String],
		"aucun texte avant l'écriture réussie")
	assert_null(_map.get_npc(LEGEND))
	assert_push_error_count(0)


# --- Présence par drapeaux, intro, combat ordinaire --------------------------------------

func test_a_consumed_encounter_never_comes_back_on_the_map() -> void:
	await _play(&"legend", Battle.Outcome.WIN)
	_map = _router.start(MAP_ID, &"start", Vector2i.UP)
	_map.refresh_npcs(_flags)
	assert_null(_map.get_npc(LEGEND), "caché par « unless » à la recharge de la carte")
	assert_false(_director.play(&"legend"), "plus aucune variante : la scène ne rejoue rien")


func test_legendary_intro_reaches_the_battle_and_the_plain_step_is_unchanged() -> void:
	await _play(&"legend", Battle.Outcome.FLED)
	await _play(&"plain", Battle.Outcome.WIN)
	assert_eq(_battles.encounters.size(), 2)
	assert_true(_battles.encounters[0].legendary_intro, "intro « legendary »")
	assert_eq(_battles.encounters[0].species, &"pidgey")
	assert_eq(_battles.encounters[0].level, 50)
	assert_false(_battles.encounters[1].legendary_intro, "entrée ordinaire par défaut")
	assert_false(_log.any(func(e: String) -> bool: return e.begins_with("save:")),
		"un combat ordinaire ne force jamais de sauvegarde")
	assert_push_error_count(0)


func test_the_request_carries_the_legendary_intro() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var encounter := WildEncounter.new(&"pidgey", 50, &"cutscene")
	assert_false(BattleRequest.wild(encounter, data, GameRng.new(1), Vector2i.ZERO)
		.legendary_intro)
	encounter.legendary_intro = true
	assert_true(BattleRequest.wild(encounter, data, GameRng.new(1), Vector2i.ZERO)
		.legendary_intro)
	assert_almost_eq(BattleStage.LEGENDARY_INTRO_SLOWDOWN, 1.5, 0.001)
