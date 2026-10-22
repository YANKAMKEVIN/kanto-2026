extends GutTest
## Jalon 21 (`jalon-21.md` §2.3, T10, T19) : le [CutsceneDirector] sur une mini-carte (PNJ de
## tests/fixtures/npcs/legend_map.json), avec un vrai joueur, un vrai DialogueRunner (texte
## instantané), un faux combat (issue imposée) et un faux réveil :
## - « wild_battle » : « flee » levés sur une fuite, « catch » sur une capture ; « clear » effacés
##   dans les quatre issues, **avant** le réveil d'une défaite ; « reveal » / « uncatchable »
##   arrivent au combat ([WildEncounter]) ; « reveal » ignorée quand le combat est un SPECTRE ;
## - « give » + « set » : drapeaux levés seulement si l'objet est entré au Sac ;
## - « animate » + « skip_reduced » : sautée avec « Réduire les animations » ;
## - variantes « if_items » / « unless_items » choisies avec le Sac du directeur ;
## - « flute » : notes au-dessus du joueur, la scène attend leur fin ; aucune note en animations
##   réduites ;
## - « react » / « emote » sur un acteur de décor ([PropActor]) qui n'est pas un PNJ.

const ROUTER_SCRIPT := preload("res://game/autoload/scene_router.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const BOX_SCENE := preload("res://game/ui/dialogue/dialogue_box.tscn")
const NPCS := "res://tests/fixtures/npcs/"
const MAP_ID := &"legend_map"
const START := Vector2i(5, 8)
const TIMEOUT := 5.0
const O := Battle.Outcome
const BUSY := &"j21_busy"
const SCOPE := &"silph_scope"
const DIALOGUES := {
	"j21_after": {"pages": ["Après."]},
	"j21_revealed": {"pages": ["Révélé."]},
	"j21_ghost": {"pages": ["Spectre."]},
}
const SCENES := {
	"j21_battle": {"steps": [
		{"set": ["j21_busy"]},
		{"wild_battle": "marowak", "level": 30, "ghost_unless_item": "silph_scope",
			"reveal": true, "uncatchable": true, "flee": ["j21_fled"], "catch": ["j21_caught"],
			"win": ["j21_won"], "lose": ["j21_lost"], "clear": ["j21_busy"]},
		{"set": ["j21_after"]},
	]},
	"j21_plain": {"steps": [{"wild_battle": "pidgey", "level": 5}]},
	"j21_give": {"steps": [{"give": "poke_flute", "set": ["got_poke_flute"]}]},
	"j21_give_unknown": {"steps": [{"give": "no_such_item", "set": ["got_nothing"]}]},
	"j21_animate": {"steps": [
		{"animate": "Light", "offset": [0, -1], "duration": 0.05, "skip_reduced": true},
		{"set": ["j21_animated"]},
	]},
	"j21_items": {"variants": [
		{"if_items": ["silph_scope"], "steps": [{"dialogue": "j21_revealed"}]},
		{"unless_items": ["silph_scope"], "steps": [{"dialogue": "j21_ghost"}]},
	]},
	"j21_flute": {"steps": [{"flute": true}, {"set": ["j21_fluted"]}]},
	"j21_prop": {"steps": [
		{"react": "Snorlax"},
		{"emote": "Snorlax", "kind": "exclamation"},
		{"set": ["j21_prop_done"]},
	]},
}


## Faux combat sauvage : issue imposée, rencontres notées.
class StubRunner extends BattleDirector:
	var outcome_to_return: int = Battle.Outcome.FLED
	var encounters: Array[WildEncounter] = []

	func run_wild(encounter: WildEncounter, _map: GameMap, _origin: Vector2i) -> int:
		encounters.append(encounter)
		await get_tree().process_frame
		return outcome_to_return


## Faux réveil : relève si le drapeau [member watched] est levé au moment du réveil (la
## sauvegarde « réveil » de Boot est écrite à ce moment-là).
class StubRecovery extends DefeatRecovery:
	var calls: int = 0
	var flags: StoryFlags
	var watched: StringName = &""
	var watched_was_set: bool = true

	func recover() -> void:
		calls += 1
		watched_was_set = flags.has_flag(watched)
		await get_tree().process_frame


var _router: Node
var _world: Node2D
var _player: Player
var _box: DialogueBox
var _runner: DialogueRunner
var _director: CutsceneDirector
var _flags: StoryFlags
var _map: GameMap
var _bag: Bag
var _battles: StubRunner
var _recovery: StubRecovery
var _played: Array[StringName] = []


func before_each() -> void:
	_played.clear()
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
	_runner.dialogue_started.connect(func(id: StringName) -> void: _played.append(id))
	_director = CutsceneDirector.new()
	add_child_autofree(_director)
	_director.setup(scenes, _flags, _runner, _player, _router)
	_battles = StubRunner.new()
	add_child_autofree(_battles)
	_director.set_battle_runner(_battles)
	_recovery = StubRecovery.new()
	_recovery.flags = _flags
	_recovery.watched = BUSY
	add_child_autofree(_recovery)
	_director.set_recovery(_recovery)
	_bag = Bag.new()
	var items := ItemLibrary.new()
	items.load_dir()
	_director.set_inventory(_bag, items)
	_router.setup(_world, _player, null)
	_router.map_changed.connect(_director.set_map)
	_map = _router.start(MAP_ID, &"start", Vector2i.UP)
	_map.refresh_npcs(_flags)
	_player.set_process(false)


## Carte 20 × 18 sans tuiles, PNJ du fixture, départ (5, 8) tourné vers le haut ; un nœud
## « Light » (animate) et un acteur de décor « Snorlax » ([PropActor]).
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
	var light := Node2D.new()
	light.name = "Light"
	map.add_child(light)
	var prop := PropActor.new()
	prop.name = "Snorlax"
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	prop.add_child(sprite)
	prop.position = Grid.cell_to_world(Vector2i(8, 4))
	map.get_node(^"Entities").add_child(prop)
	return map


## Joue la scène [param id] (issue [param outcome] pour un combat) jusqu'au bout, en fermant
## chaque dialogue.
func _play(id: StringName, outcome: int = O.FLED) -> void:
	_battles.outcome_to_return = outcome
	assert_true(_director.play(id), "scène lancée")
	var deadline := Time.get_ticks_msec() + int(TIMEOUT * 1000)
	while _director.is_running() and Time.get_ticks_msec() < deadline:
		await wait_process_frames(1)
		if _runner.is_running():
			_box.advance_requested.emit()
	assert_false(_director.is_running(), "scène terminée")


func _has(flag: String) -> bool:
	return _flags.has_flag(StringName(flag))


# --- wild_battle : flee, catch, clear ----------------------------------------------------

func test_flee_sets_flee_flags_and_clears() -> void:
	await _play(&"j21_battle", O.FLED)
	assert_true(_has("j21_fled"))
	assert_false(_has("j21_caught") or _has("j21_won") or _has("j21_lost"))
	assert_false(_has("j21_busy"), "« clear » effacé")
	assert_true(_has("j21_after"), "la scène continue")
	assert_push_error_count(0)


func test_catch_sets_catch_flags_and_clears() -> void:
	await _play(&"j21_battle", O.CAUGHT)
	assert_true(_has("j21_caught"))
	assert_false(_has("j21_fled") or _has("j21_won"))
	assert_false(_has("j21_busy"))
	assert_true(_has("j21_after"))


func test_win_clears() -> void:
	await _play(&"j21_battle", O.WIN)
	assert_true(_has("j21_won"))
	assert_false(_has("j21_fled") or _has("j21_caught"))
	assert_false(_has("j21_busy"))


func test_loss_clears_before_the_wake_up_then_stops() -> void:
	await _play(&"j21_battle", O.LOSS)
	assert_eq(_recovery.calls, 1, "réveil")
	assert_false(_recovery.watched_was_set, "« clear » effacé avant le réveil (sauvegarde)")
	assert_true(_has("j21_lost"))
	assert_false(_has("j21_busy"))
	assert_false(_has("j21_after"), "la scène s'arrête au réveil")


func test_foe_fled_clears_and_sets_nothing_else() -> void:
	await _play(&"j21_battle", O.FOE_FLED)
	assert_false(_has("j21_busy"))
	assert_false(_has("j21_fled") or _has("j21_caught") or _has("j21_won") or _has("j21_lost"))


# --- wild_battle : reveal, uncatchable ---------------------------------------------------

func test_with_the_scope_reveal_and_uncatchable_reach_the_encounter() -> void:
	_bag.add(SCOPE)
	await _play(&"j21_battle", O.FLED)
	var encounter := _battles.encounters[0]
	assert_false(encounter.ghost)
	assert_true(encounter.reveal)
	assert_true(encounter.uncatchable)


func test_without_the_scope_the_ghost_ignores_reveal() -> void:
	await _play(&"j21_battle", O.FLED)
	var encounter := _battles.encounters[0]
	assert_true(encounter.ghost, "SPECTRE sans le Scope")
	assert_false(encounter.reveal, "« reveal » ignorée")
	assert_true(encounter.uncatchable, "indépendante du mode spectre")


func test_plain_wild_battle_keeps_the_defaults() -> void:
	await _play(&"j21_plain", O.FLED)
	var encounter := _battles.encounters[0]
	assert_false(encounter.reveal)
	assert_false(encounter.uncatchable)


# --- give + set ----------------------------------------------------------------------------

func test_give_with_set_raises_the_flags_once_the_item_is_in_the_bag() -> void:
	watch_signals(_director)
	await _play(&"j21_give")
	assert_true(_bag.has(&"poke_flute"))
	assert_true(_has("got_poke_flute"))
	assert_signal_emitted(_director, "item_given")


func test_give_of_an_unknown_item_sets_nothing() -> void:
	await _play(&"j21_give_unknown")
	assert_false(_has("got_nothing"), "rien de levé")
	assert_push_error("objet inconnu")


func test_give_without_a_bag_sets_nothing() -> void:
	_director.set_inventory(null, null)
	await _play(&"j21_give")
	assert_false(_has("got_poke_flute"))
	assert_push_error("pas de Sac")


# --- animate.skip_reduced --------------------------------------------------------------------

func test_animate_skip_reduced_is_played_normally() -> void:
	var light := _map.get_node(^"Light") as Node2D
	var before := light.position
	await _play(&"j21_animate")
	assert_eq(light.position, before + Vector2(0, -Grid.TILE_SIZE), "déplacée")
	assert_true(_has("j21_animated"))


func test_animate_skip_reduced_is_skipped_with_reduced_motion() -> void:
	_director.reduce_motion = true
	var light := _map.get_node(^"Light") as Node2D
	var before := light.position
	await _play(&"j21_animate")
	assert_eq(light.position, before, "étape sautée")
	assert_true(light.visible, "ni fondu ni masquage")
	assert_eq(light.modulate.a, 1.0)
	assert_true(_has("j21_animated"), "la scène continue")


# --- Variantes selon le Sac ------------------------------------------------------------------

func test_variants_follow_the_bag() -> void:
	await _play(&"j21_items")
	assert_eq(_played, [&"j21_ghost"] as Array[StringName])
	_bag.add(SCOPE)
	await _play(&"j21_items")
	assert_eq(_played, [&"j21_ghost", &"j21_revealed"] as Array[StringName])


# --- flute --------------------------------------------------------------------------------

func test_flute_plays_notes_above_the_player_and_waits() -> void:
	var seen: Array[FluteNotes] = []
	var on_added := func(node: Node) -> void:
		if node is FluteNotes:
			seen.append(node)
	get_tree().node_added.connect(on_added)
	await _play(&"j21_flute")
	get_tree().node_added.disconnect(on_added)
	assert_eq(seen.size(), 1, "un jeu de notes")
	assert_true(_has("j21_fluted"))
	assert_true(not is_instance_valid(seen[0]) or seen[0].is_queued_for_deletion(),
		"la scène a attendu la fin des notes")
	await wait_process_frames(2)
	assert_false(is_instance_valid(seen[0]), "nœud libéré")


func test_flute_shows_no_note_with_reduced_motion() -> void:
	_director.reduce_motion = true
	var seen: Array[Node] = []
	var on_added := func(node: Node) -> void:
		if node is FluteNotes:
			seen.append(node)
	get_tree().node_added.connect(on_added)
	await _play(&"j21_flute")
	get_tree().node_added.disconnect(on_added)
	assert_eq(seen.size(), 0, "aucune note")
	assert_true(_has("j21_fluted"))


# --- Acteur de décor -------------------------------------------------------------------------

func test_react_and_emote_on_a_prop_actor() -> void:
	var prop := _map.get_scene_prop(&"Snorlax") as PropActor
	assert_not_null(prop)
	assert_null(_map.get_npc(&"Snorlax"), "pas un PNJ")
	watch_signals(prop)
	await _play(&"j21_prop")
	assert_signal_emitted(prop, "emote_finished", "la scène a attendu la bulle")
	assert_true(_has("j21_prop_done"))
	assert_push_error_count(0)
