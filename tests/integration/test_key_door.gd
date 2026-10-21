extends GutTest
## Portes à carte (passe systèmes 2, `docs/tech/systemes-2.md` §2.10, T28) : [KeyDoor] (règle,
## drapeau, cases), verbe OUVRIR et [KeyDoorDirector] sur une mini-carte fabriquée en code
## (porte (3, 1), joueur en (3, 2) tourné vers le nord).

const PLAYER_SCENE := preload("res://game/player/player.tscn")
const DOOR_CELL := Vector2i(3, 1)
const PLAYER_CELL := Vector2i(3, 2)
const FLAG: StringName = &"door_qa_door_ab_open"


class FakeRunner:
	extends DialogueRunner
	var played: Array[StringName] = []

	func play(dialogue_id: StringName, _npc: Npc = null, _map: GameMap = null,
			_delay: float = 0.0) -> bool:
		played.append(dialogue_id)
		return true


var _map: GameMap
var _door: KeyDoor
var _player: Player
var _flags: StoryFlags
var _bag: Bag
var _runner: FakeRunner
var _director: KeyDoorDirector
var _saves: Array[String] = []


func before_each() -> void:
	_saves.clear()
	_flags = StoryFlags.new()
	_bag = Bag.new()
	_map = GameMap.new()
	_map.map_id = &"qa_door"
	_map.size = Vector2i(7, 5)
	for group: String in ["Entities", "Spawns", "Warps", "Interactables"]:
		var node := Node2D.new()
		node.name = group
		_map.add_child(node)
	var spawn := Marker2D.new()
	spawn.name = "start"
	spawn.position = Grid.cell_to_world(PLAYER_CELL)
	_map.get_node(^"Spawns").add_child(spawn)
	_door = KeyDoor.new()
	_door.door_id = &"ab"
	_door.unless_flags = [KeyDoor.open_flag(&"qa_door", &"ab")]
	_door.blocking_cells = [DOOR_CELL]
	_map.get_node(^"Entities").add_child(_door)
	var point := InteractPoint.new()
	point.position = Grid.cell_to_world(DOOR_CELL)
	point.kind = Interaction.Kind.OPEN
	point.dialogue_id = KeyDoor.LOCKED_DIALOGUE
	point.unless_flags = [FLAG]
	_map.get_node(^"Interactables").add_child(point)
	add_child_autofree(_map)
	_player = PLAYER_SCENE.instantiate() as Player
	_map.spawn_player(_player, &"start", Vector2i.UP)
	_player.set_process(false)
	_map.apply_flag_gates(_flags)
	_flags.flag_changed.connect(func(_f: StringName, _v: bool) -> void:
		_map.apply_flag_gates(_flags))
	_runner = FakeRunner.new()
	add_child_autofree(_runner)
	_director = KeyDoorDirector.new()
	add_child_autofree(_director)
	_director.setup(_flags, _bag, _player, _runner, func() -> GameMap: return _map,
		func(reason: String) -> void: _saves.append(reason))


# --- Règle et donnée --------------------------------------------------------------------

func test_open_flag_names_the_map_and_the_door() -> void:
	assert_eq(KeyDoor.open_flag(&"qa_door", &"ab"), FLAG)
	assert_eq(_door.get_open_flag(), FLAG)
	assert_eq(_door.key_item, &"card_key", "Carte Magnétique par défaut")


func test_decide() -> void:
	assert_eq(KeyDoor.decide(false, true), KeyDoor.Outcome.OPEN)
	assert_eq(KeyDoor.decide(false, false), KeyDoor.Outcome.LOCKED)
	assert_eq(KeyDoor.decide(true, false), KeyDoor.Outcome.NONE)
	assert_eq(KeyDoor.decide(true, true), KeyDoor.Outcome.NONE)


func test_open_verb_is_named_and_shown_as_ouvrir() -> void:
	assert_eq(Interaction.kind_name(Interaction.Kind.OPEN), &"open")
	assert_eq(Interaction.kind_from_name("open"), Interaction.Kind.OPEN)
	assert_eq(InteractButton.VERBS[&"open"]["label"], "OUVRIR")


func test_card_key_item_and_locked_text_exist() -> void:
	var items := ItemLibrary.new()
	assert_true(items.load_dir())
	assert_not_null(items.get_item(&"card_key"))
	var dialogues := DialogueLibrary.new()
	assert_true(dialogues.load_dir())
	assert_true(dialogues.has_dialogue(KeyDoor.LOCKED_DIALOGUE))


# --- Carte ----------------------------------------------------------------------------

func test_closed_door_blocks_its_cell_and_offers_open() -> void:
	assert_true(_door.visible)
	assert_false(_map.get_grid().is_free(DOOR_CELL), "case occupée")
	var targets := _map.get_interactions().get_at(DOOR_CELL)
	assert_eq(targets.size(), 1)
	assert_eq(targets[0].kind, Interaction.Kind.OPEN)
	assert_true(targets[0].is_available(_flags))


func test_find_door_by_cell() -> void:
	assert_eq(_director.find_door(DOOR_CELL), _door)
	assert_null(_director.find_door(PLAYER_CELL))


# --- Directeur ------------------------------------------------------------------------

func test_without_the_card_the_door_refuses_and_stays_closed() -> void:
	_director.on_door_requested(DOOR_CELL)
	assert_eq(_runner.played, [KeyDoor.LOCKED_DIALOGUE] as Array[StringName])
	assert_false(_flags.has_flag(FLAG))
	assert_false(_map.get_grid().is_free(DOOR_CELL))
	assert_eq(_saves.size(), 0)


func test_with_the_card_the_door_opens_for_good_and_a_save_is_requested() -> void:
	_bag.add(&"card_key")
	_director.on_door_requested(DOOR_CELL)
	assert_true(_director.is_busy())
	assert_false(_player.is_input_enabled(), "joueur bloqué pendant l'ouverture")
	await wait_for_signal(_director.door_opened, 2.0)
	assert_true(_flags.has_flag(FLAG))
	assert_false(_door.visible, "battant retiré")
	assert_true(_map.get_grid().is_free(DOOR_CELL), "case libérée")
	assert_false(_map.get_interactions().get_at(DOOR_CELL)[0].is_available(_flags),
		"OUVRIR retiré")
	assert_eq(_saves, ["porte à carte"] as Array[String])
	assert_true(_player.is_input_enabled())
	assert_true(_bag.has(&"card_key"), "la carte est gardée : elle ouvre toutes les portes")
	assert_eq(_runner.played.size(), 0)


func test_an_open_door_does_nothing() -> void:
	_flags.set_flag(FLAG)
	_director.on_door_requested(DOOR_CELL)
	assert_eq(_runner.played.size(), 0)
	assert_false(_director.is_busy())
	assert_eq(_saves.size(), 0)


func test_the_controller_signals_the_door_instead_of_playing_a_dialogue() -> void:
	var controller := InteractionController.new()
	add_child_autofree(controller)
	controller.setup(_player, _runner)
	controller.set_story_flags(_flags)
	controller.set_map(_map)
	watch_signals(controller)
	controller._interact(_map.get_interactions().get_at(DOOR_CELL)[0])
	assert_signal_emitted_with_parameters(controller, "door_requested", [DOOR_CELL])
	assert_eq(_runner.played.size(), 0, "aucun dialogue joué par le contrôleur")
