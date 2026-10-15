extends GutTest
## TrainerWatcher (jalon 9, jalon-09.md §2.4.6, T11) sur une mini-carte (PNJ de
## tests/fixtures/npcs/trainer_map.json : Théo (5, 2) tourné vers le bas, vision 4 ; Noé (9, 5)
## tourné vers la gauche, vision 4 ; un enfant ordinaire), avec un vrai joueur, un vrai
## CutsceneDirector, un vrai DialogueRunner (texte instantané), un faux combat de Dresseur (issue
## imposée), un faux réveil, et un vrai EncounterDirector branché APRÈS le watcher (ordre de
## Boot) avec des hautes herbes et un tirage toujours gagnant.
## Pas dans la vision → « ! », approche, regards, répliques, combat, drapeau « battu », réplique
## « après » ; défaite → réveil, pas de drapeau, redéfie ; joueur bloqué → rien ; battu → plus
## rien ; deux visions → le premier du fichier ; pas de rencontre sauvage sur le pas de la
## détection ; défi à la parole (ni « ! » ni approche).

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const BOX_SCENE := preload("res://game/ui/dialogue/dialogue_box.tscn")
const GameStateScript := preload("res://game/autoload/game_state.gd")
const ScriptedRng := preload("res://tests/helpers/scripted_rng.gd")
const NPCS := "res://tests/fixtures/npcs/"
const MAP_ID := &"trainer_map"
const TIMEOUT := 5.0
const START := Vector2i(5, 8)
const THEO_CELL := Vector2i(5, 2)
## Case vue par Théo à 4 cases (et case de hautes herbes).
const SEEN_CELL := Vector2i(5, 6)
## Case vue par Théo (3) et par Noé (4).
const CROSSED_CELL := Vector2i(5, 5)
const DIALOGUES := {
	"theo_before": {"speaker": "Scout Théo", "pages": ["Avant."]},
	"theo_after": {"speaker": "Scout Théo", "pages": ["Après."]},
	"noe_before": {"speaker": "Scout Noé", "pages": ["Avant."]},
	"noe_after": {"speaker": "Scout Noé", "pages": ["Après."]},
	"kid": {"speaker": "Enfant", "pages": ["Salut."]},
}
## Tirage de rencontre toujours gagnant (taux, poids, niveau, IV et sexe).
const WIN_ROLLS: Array[int] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]


## Faux combat de Dresseur : issue imposée, appels enregistrés, deux images de combat.
class StubRunner extends BattleDirector:
	var outcome_to_return: int = Battle.Outcome.WIN
	var calls: Array[StringName] = []

	func run(trainer_id: StringName, _map: GameMap,
			_world_actors: Dictionary[StringName, StringName]) -> int:
		calls.append(trainer_id)
		await get_tree().process_frame
		await get_tree().process_frame
		return outcome_to_return


## Faux combat sauvage (EncounterDirector) : compte les rencontres.
class FakeWildBattles extends BattleDirector:
	var runs: int = 0

	func run_request(_request: BattleRequest, _map: GameMap) -> int:
		runs += 1
		await get_tree().process_frame
		return Battle.Outcome.WIN


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
var _watcher: TrainerWatcher
var _wild: FakeWildBattles
var _encounters: EncounterDirector
var _state: Node
var _dialogues_played: Array[StringName] = []


func before_each() -> void:
	_dialogues_played.clear()
	var dialogues := DialogueLibrary.new()
	dialogues.add_from_dict(DIALOGUES, "test")
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
	_runner.dialogue_started.connect(func(id: StringName) -> void: _dialogues_played.append(id))
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(CutsceneLibrary.new(), _flags, _runner, _player, _router)
	_battles = StubRunner.new()
	add_child_autofree(_battles)
	_director.set_battle_runner(_battles)
	_recovery = StubRecovery.new()
	add_child_autofree(_recovery)
	_director.set_recovery(_recovery)
	# Ordre de Boot : directeur de scènes, Dresseurs, puis rencontres sauvages.
	_watcher = TrainerWatcher.new()
	add_child_autofree(_watcher)
	_watcher.setup(_player, _flags, _director)
	_setup_encounters()
	_router.setup(_world, _player, null)
	_router.map_changed.connect(_director.set_map)
	_router.map_changed.connect(_watcher.set_map)
	_router.map_changed.connect(_encounters.set_map)
	_map = _router.start(MAP_ID, &"start", Vector2i.UP)
	_map.get_grid().set_tall_grass(SEEN_CELL)
	_player.set_process(false)
	_player.set_input_enabled(true, &"transition")
	watch_signals(_watcher)


func _setup_encounters() -> void:
	var data := PokemonData.new()
	data.load_dir()
	var library := EncounterLibrary.new(data)
	library.add_from_dict({
		"test_trainer_grass": {
			"maps": [String(MAP_ID)], "terrain": "grass", "rate": 25,
			"slots": [{"species": "pidgey", "levels": [3, 3], "weight": 20}],
		},
	}, "test")
	_state = GameStateScript.new()
	add_child_autofree(_state)
	_state.party.add(PokemonFactory.create(data, &"charmander", 5, GameRng.new(1)))
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	_wild = FakeWildBattles.new()
	add_child_autofree(_wild)
	_encounters = EncounterDirector.new()
	add_child_autofree(_encounters)
	_encounters.setup(library, data, _state, _player, _wild, null, _director)


## Carte 20 × 18 sans tuiles, PNJ du fixture, départ (5, 8).
func _make_map(map_id: StringName) -> GameMap:
	var map := GameMap.new()
	map.name = "TrainerMap"
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


## Le joueur arrive (pas terminé) sur [param cell], tourné vers [param facing].
func _arrive(cell: Vector2i, facing: Vector2i = Vector2i.UP) -> void:
	_player.enter_map(_map.get_grid(), cell, facing, _map.get_pixel_rect())
	_player.moved.emit(cell)


## Joue la scène jusqu'au bout en fermant chaque dialogue (une image d'écart).
func _play_to_the_end() -> void:
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if _runner.is_running():
			_box.advance_requested.emit()
	assert_false(_director.is_running(), "séquence terminée")


func test_spotted_exclamation_approach_dialogues_battle_and_beaten() -> void:
	var theo := _map.get_npc(&"theo")
	watch_signals(theo)
	_arrive(SEEN_CELL)
	assert_true(_director.is_running(), "séquence lancée dans le pas même")
	assert_true(_player.is_blocked_by(CutsceneDirector.REASON), "joueur bloqué tout de suite")
	assert_eq(_director.get_cutscene_id(), &"trainer_forest_scout_theo")
	assert_signal_emitted_with_parameters(_watcher, "trainer_spotted",
		[&"theo", &"forest_scout_theo"])
	assert_true(theo.is_emoting(), "« ! » d'abord")
	await _play_to_the_end()
	assert_signal_emit_count(theo, "emote_finished", 1)
	assert_eq(theo.get_cell(), SEEN_CELL + Vector2i.UP, "il s'arrête sur la case voisine")
	assert_eq(theo.get_facing(), Vector2i.DOWN, "face au joueur")
	assert_eq(_player.get_facing(), Vector2i.UP, "le joueur lui fait face")
	assert_eq(_battles.calls, [&"forest_scout_theo"] as Array[StringName])
	assert_true(_flags.has_flag(&"beaten_forest_scout_theo"), "battu, mémorisé")
	assert_eq(_dialogues_played, [&"theo_before", &"theo_after"] as Array[StringName],
		"réplique « après » dite tout de suite (Q-3)")
	assert_eq(_recovery.calls, 0)
	assert_true(_player.is_input_enabled(), "joueur libre à la fin")
	# Battu : il ne regarde plus personne, il reste où il s'est arrêté.
	_arrive(SEEN_CELL + Vector2i.DOWN)
	_arrive(SEEN_CELL)
	assert_false(_director.is_running(), "plus de défi")
	assert_eq(theo.get_cell(), SEEN_CELL + Vector2i.UP)
	assert_push_error_count(0)


func test_defeat_wakes_up_without_flag_and_the_trainer_challenges_again() -> void:
	_battles.outcome_to_return = Battle.Outcome.LOSS
	_arrive(SEEN_CELL)
	await _play_to_the_end()
	assert_eq(_recovery.calls, 1, "réveil au point de repos")
	assert_false(_flags.has_flag(&"beaten_forest_scout_theo"), "pas battu")
	assert_eq(_dialogues_played, [&"theo_before"] as Array[StringName], "pas de réplique « après »")
	# (Le vrai réveil change de carte ; ici le joueur est resté.) Il redéfie.
	_battles.outcome_to_return = Battle.Outcome.WIN
	_arrive(SEEN_CELL)
	assert_true(_director.is_running(), "il redéfie")
	await _play_to_the_end()
	assert_true(_flags.has_flag(&"beaten_forest_scout_theo"))


func test_out_of_sight_nothing_happens() -> void:
	for cell: Vector2i in [START, SEEN_CELL + Vector2i.DOWN, SEEN_CELL + Vector2i.RIGHT,
			THEO_CELL + Vector2i.UP + Vector2i.LEFT]:
		_arrive(cell)
		assert_false(_director.is_running(), "pas vu en %s" % cell)
	assert_signal_not_emitted(_watcher, "trainer_spotted")


func test_blocked_player_or_running_scene_nothing_happens() -> void:
	_player.set_input_enabled(false, &"dialogue")
	_arrive(SEEN_CELL)
	assert_false(_director.is_running(), "joueur bloqué : rien")
	_player.set_input_enabled(true, &"dialogue")
	_arrive(SEEN_CELL)
	assert_true(_director.is_running(), "libre : il est vu")
	await _play_to_the_end()


func test_two_visions_the_first_in_the_file_challenges() -> void:
	_arrive(CROSSED_CELL, Vector2i.RIGHT)
	assert_eq(_director.get_cutscene_id(), &"trainer_forest_scout_theo", "Théo, premier du fichier")
	assert_signal_emit_count(_watcher, "trainer_spotted", 1, "un seul défi à la fois")
	await _play_to_the_end()
	assert_eq(_battles.calls, [&"forest_scout_theo"] as Array[StringName])
	# Théo battu : sur la même case, Noé voit le joueur à son tour.
	_arrive(CROSSED_CELL + Vector2i.LEFT)
	_arrive(CROSSED_CELL, Vector2i.RIGHT)
	assert_eq(_director.get_cutscene_id(), &"trainer_forest_scout_noe")
	await _play_to_the_end()
	assert_eq(_battles.calls, [&"forest_scout_theo", &"forest_scout_noe"] as Array[StringName])


func test_no_wild_encounter_on_the_step_of_the_detection() -> void:
	_arrive(SEEN_CELL)
	assert_true(_director.is_running())
	assert_false(_encounters.is_running(), "aucune rencontre sauvage")
	assert_eq(_wild.runs, 0)
	await _play_to_the_end()
	assert_eq(_wild.runs, 0)
	# Témoin : Théo battu, la même case d'herbe tire bien une rencontre.
	_state.rng = ScriptedRng.new(WIN_ROLLS.duplicate())
	_arrive(SEEN_CELL + Vector2i.DOWN)
	_arrive(SEEN_CELL)
	assert_true(_encounters.is_running(), "l'herbe déclenche quand aucun Dresseur ne voit")
	await wait_until(func() -> bool: return not _encounters.is_running(), TIMEOUT)
	assert_eq(_wild.runs, 1)


## J15 T24 (garde-fou) : équipe sans Pokémon valide → aucun Dresseur ne défie, ni à la vue ni
## à la parole ; aucun combat demandé ; un Pokémon de nouveau valide → le défi revient.
func test_no_challenge_while_the_whole_party_is_knocked_out() -> void:
	_watcher.setup(_player, _flags, _director, _state)
	var lead := _state.party.get_lead() as Pokemon
	lead.hp = 0
	_arrive(SEEN_CELL)
	assert_false(_director.is_running(), "vu, mais aucun Pokémon valide : rien")
	assert_signal_not_emitted(_watcher, "trainer_spotted")
	var theo := _map.get_npc(&"theo")
	assert_false(_watcher.challenge(theo), "pas de défi à la parole non plus")
	assert_false(_director.is_running())
	assert_eq(_battles.calls, [] as Array[StringName], "aucun combat demandé")
	assert_false(_flags.has_flag(&"beaten_forest_scout_theo"), "toujours à battre")
	# (Rebranché après l'EncounterDirector, le watcher passe ici après lui : défi à la parole.)
	lead.hp = lead.max_hp()
	assert_true(_watcher.challenge(theo), "soigné : il défie")
	await _play_to_the_end()
	assert_push_error_count(0)


func test_challenge_by_talking_no_exclamation_no_approach() -> void:
	var theo := _map.get_npc(&"theo")
	watch_signals(theo)
	_player.enter_map(_map.get_grid(), THEO_CELL + Vector2i.LEFT, Vector2i.RIGHT,
		_map.get_pixel_rect())
	assert_true(_watcher.challenge(theo))
	assert_true(_player.is_blocked_by(CutsceneDirector.REASON))
	assert_false(theo.is_emoting(), "pas de « ! »")
	await _play_to_the_end()
	assert_signal_not_emitted(theo, "emote_finished")
	assert_signal_not_emitted(_watcher, "trainer_spotted")
	assert_eq(theo.get_cell(), THEO_CELL, "pas d'approche")
	assert_eq(theo.get_facing(), Vector2i.LEFT, "il se tourne vers le joueur")
	assert_true(_flags.has_flag(&"beaten_forest_scout_theo"))
	assert_eq(_dialogues_played, [&"theo_before", &"theo_after"] as Array[StringName])
	assert_false(_watcher.challenge(theo), "battu : plus de défi")
	assert_false(_watcher.challenge(_map.get_npc(&"kid")), "pas un Dresseur")
