extends GutTest
## Choix qui lance une scène (jalon 12, T23 ; `jalon-12.md` §2.13) : clé « confirm_cutscene » d'un
## choix ([DialogueChoice.confirm_cutscene]) lue et validée par [DialogueLibrary] (identifiant non
## vide, exclusive de « confirm_action ») ; le [DialogueRunner] émet `cutscene_requested` après
## la fermeture si le joueur a dit OUI (pages de confirmation comprises), rien s'il a dit NON.

const BOX_SCENE := "res://game/ui/dialogue/dialogue_box.tscn"
const PLAYER_SCENE := "res://game/player/player.tscn"
const TIMEOUT := 3.0
## Forme du dialogue du fossile (texte n° 23 du dossier 15, littéral par fossile).
const FOSSIL := {
	"fossil_test": {"narration": true, "pages": ["Prendre le Fossile Dôme ?"], "choice": {
		"confirm": "OUI", "cancel": "NON", "confirm_cutscene": "fossil_scene",
		"cancel_pages": []}},
	"fossil_with_pages": {"pages": ["Sûr ?"], "choice": {"confirm": "OUI", "cancel": "NON",
		"confirm_cutscene": "after_pages", "confirm_pages": ["Très bien."]}},
}

var _box: DialogueBox
var _runner: DialogueRunner
var _player: Player
var _map: GameMap
var _library: DialogueLibrary
var _order: Array[String] = []


func before_each() -> void:
	_order.clear()
	_library = DialogueLibrary.new()
	assert_true(_library.add_from_dict(FOSSIL, "test"), "\n".join(_library.get_errors()))
	_map = _make_map()
	add_child_autofree(_map)
	_player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	_map.spawn_player(_player, &"start", Vector2i.UP)
	_player.set_process(false)
	_box = (load(BOX_SCENE) as PackedScene).instantiate() as DialogueBox
	add_child_autofree(_box)
	_runner = DialogueRunner.new()
	_runner.chars_per_second = 0.0
	add_child_autofree(_runner)
	_runner.setup(_library, StoryFlags.new(), _box, _player)
	_runner.dialogue_finished.connect(func(_id: StringName) -> void: _order.append("finished"))
	_runner.cutscene_requested.connect(func(id: StringName) -> void:
		_order.append("cutscene:%s" % id))


func _make_map() -> GameMap:
	var map := GameMap.new()
	map.name = "ConfirmMap"
	map.map_id = &"confirm_map"
	map.size = Vector2i(10, 10)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns"]:
		var node := Node2D.new()
		node.name = group
		map.add_child(node)
	var marker := Marker2D.new()
	marker.name = "start"
	marker.position = Grid.cell_to_world(Vector2i(5, 5))
	map.get_node(^"Spawns").add_child(marker)
	return map


# --- Bibliothèque -------------------------------------------------------------------------

func test_library_reads_confirm_cutscene() -> void:
	var choice := _library.get_dialogue(&"fossil_test").variants[0].choice
	assert_eq(choice.confirm_cutscene, &"fossil_scene")
	assert_eq(choice.confirm_action, &"")
	assert_eq(choice.cancel_pages.size(), 0)
	assert_eq(_library.get_dialogue(&"fossil_with_pages").variants[0].choice.confirm_cutscene,
		&"after_pages")


func test_library_refuses_bad_confirm_cutscene() -> void:
	var library := DialogueLibrary.new()
	assert_false(library.add_from_dict({"both": {"pages": ["?"], "choice": {"confirm": "OUI",
		"cancel": "NON", "confirm_action": "center_heal", "confirm_cutscene": "x"}}}, "t"))
	assert_false(library.add_from_dict({"empty": {"pages": ["?"], "choice": {"confirm": "OUI",
		"cancel": "NON", "confirm_cutscene": ""}}}, "t"))
	assert_false(library.add_from_dict({"number": {"pages": ["?"], "choice": {"confirm": "OUI",
		"cancel": "NON", "confirm_cutscene": 3}}}, "t"))
	for id: StringName in [&"both", &"empty", &"number"]:
		assert_null(library.get_dialogue(id), "%s écarté" % id)
	assert_push_error_count(3)


# --- Lecteur ------------------------------------------------------------------------------

func test_yes_requests_the_cutscene_after_the_dialogue_closes() -> void:
	assert_true(_runner.play(&"fossil_test"))
	await wait_process_frames(1)
	_box.advance_requested.emit()
	assert_true(_runner.is_awaiting_choice())
	_runner.choose(true)
	await wait_for_signal(_runner.dialogue_finished, TIMEOUT)
	await wait_process_frames(1)
	assert_eq(_order, ["finished", "cutscene:fossil_scene"] as Array[String])
	assert_false(_runner.is_running())


func test_no_requests_nothing() -> void:
	_runner.play(&"fossil_test")
	await wait_process_frames(1)
	_box.advance_requested.emit()
	_runner.choose(false)
	await wait_for_signal(_runner.dialogue_finished, TIMEOUT)
	await wait_process_frames(1)
	assert_eq(_order, ["finished"] as Array[String], "NON : rien")
	assert_true(_player.is_input_enabled())
	# Rejouer puis OUI : la réponse précédente n'est pas gardée, la nouvelle compte.
	_runner.play(&"fossil_test")
	await wait_process_frames(1)
	_box.advance_requested.emit()
	_runner.choose(true)
	await wait_for_signal(_runner.dialogue_finished, TIMEOUT)
	await wait_process_frames(1)
	assert_eq(_order, ["finished", "finished", "cutscene:fossil_scene"] as Array[String])


func test_confirm_pages_are_played_before_the_cutscene() -> void:
	_runner.play(&"fossil_with_pages")
	await wait_process_frames(1)
	_box.advance_requested.emit()
	_runner.choose(true)
	await wait_process_frames(1)
	assert_eq(_box.get_text(), "Très bien.", "pages de confirmation d'abord")
	assert_eq(_order, [] as Array[String])
	_box.advance_requested.emit()
	await wait_for_signal(_runner.dialogue_finished, TIMEOUT)
	await wait_process_frames(1)
	assert_eq(_order, ["finished", "cutscene:after_pages"] as Array[String])
