extends GutTest
## Pokémon d'ambiance de la Forêt de Jade (jalon 9 T18, dossier 10 §7, jalon-09.md §2.7.6) sur
## une petite carte construite en code (PNJ de tests/fixtures/npcs/forest_ambient.json) :
## - un Pokémon immobile et non interactif se pose sur une case de forêt (infranchissable) :
##   il l'occupe, elle reste solide, on ne peut pas lui parler ;
## - « notice » (Chenipan) : animation de réaction, il reste sur la carte, au plus une fois
##   toutes les 4 s (temps simulé) ;
## - « hide » (Aspicot) : recul vers le haut et fondu, puis retiré de la carte (case libérée,
##   toujours solide) ;
## - un Pokémon d'ambiance sans planche (Chenipan au T17) est sauté sans erreur.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")
const PLAYER_SCENE := preload("res://game/player/player.tscn")
const FIXTURES := "res://tests/fixtures/npcs/"
## Colonne de forêt (x = 8) : l'Aspicot sur un tronc, le Chrysacier accroché plus bas.
const FOREST_CELLS: Array[Vector2i] = [Vector2i(8, 1), Vector2i(8, 2), Vector2i(8, 3),
	Vector2i(8, 4), Vector2i(8, 5), Vector2i(8, 6)]

var _map: GameMap
var _player: Player
var _watcher: AmbientWatcher
var _reactions: Array[String] = []


func before_each() -> void:
	_reactions.clear()
	_map = GameMap.new()
	_map.name = "ForestAmbient"
	_map.map_id = &"forest_ambient"
	_map.npcs_dir = FIXTURES
	_map.size = Vector2i(10, 8)
	_map.blocked_cells = FOREST_CELLS
	for group: String in ["Entities", "Warps", "Interactables", "Spawns"]:
		var node := Node2D.new()
		node.name = group
		_map.add_child(node)
	(_map.get_node(^"Entities") as Node2D).y_sort_enabled = true
	add_child_autofree(_map)
	_player = PLAYER_SCENE.instantiate() as Player
	add_child_autofree(_player)
	_player.set_process(false)
	_watcher = AmbientWatcher.new()
	add_child_autofree(_watcher)
	_watcher.setup(_player)
	_watcher.set_map(_map)
	_watcher.reacted.connect(func(id: StringName, action: StringName) -> void:
		_reactions.append("%s:%s" % [id, action]))


## Le joueur « termine un pas » sur [param cell] (signal de [Player], seul lien du watcher).
func _step_to(cell: Vector2i) -> void:
	_player.moved.emit(cell)


func test_a_still_pokemon_sits_on_a_forest_cell_without_making_it_walkable() -> void:
	var grid := _map.get_grid()
	var metapod := _map.get_npc(&"metapod")
	assert_not_null(metapod, "posé sur une case de forêt")
	if metapod == null:
		return
	assert_true(grid.is_solid(Vector2i(8, 5)), "la case reste de la forêt")
	assert_same(grid.get_occupant(Vector2i(8, 5)), metapod)
	assert_null(metapod.get_interaction(), "ni dialogue ni bouton")
	assert_false(grid.can_enter(Vector2i(8, 5), Vector2i.RIGHT, _player))
	assert_eq((metapod.get_node(^"%Sprite") as Node2D).position.y, -40.0, "accroché (lift)")
	assert_push_error_count(0)


func test_a_pokemon_without_its_sheet_is_skipped_without_error() -> void:
	assert_null(_map.get_npc(&"no_sheet"), "pas d'humain générique à sa place")
	assert_false(_map.get_grid().is_occupied(Vector2i(1, 6)))
	var spec := NpcRoster.load_for_map(&"forest_ambient", FIXTURES).get_spec(&"no_sheet")
	assert_true(GameMap.awaits_painted_look(spec))
	_map.refresh_npcs(StoryFlags.new())
	assert_null(_map.get_npc(&"no_sheet"), "pas recréé par refresh_npcs")
	for id: StringName in [&"caterpie", &"weedle", &"metapod"]:
		assert_false(GameMap.awaits_painted_look(_map.get_npc(id).get_spec()), String(id))
	assert_push_error_count(0)


func test_notice_reacts_stays_and_waits_before_reacting_again() -> void:
	var caterpie := _map.get_npc(&"caterpie")
	var reacted := [0]
	caterpie.reacted.connect(func() -> void: reacted[0] += 1)
	var clock := TweenClock.new(get_tree())
	_step_to(Vector2i(3, 6))
	assert_eq(_reactions, [] as Array[String], "3 cases : rien")
	_step_to(Vector2i(3, 5))
	assert_eq(_reactions, ["caterpie:notice"] as Array[String], "2 cases : il relève la tête")
	assert_eq(reacted[0], 1)
	var sprite := caterpie.get_node(^"%Sprite") as AnimatedSprite2D
	assert_true(String(sprite.animation).begins_with("react"), "animation de réaction")
	_step_to(Vector2i(2, 4))
	assert_eq(_reactions.size(), 1, "pas deux fois de suite")
	var cooldown := roundi(AmbientWatcher.NOTICE_COOLDOWN / TweenClock.STEP)
	for i: int in cooldown - 1:
		clock.step()
	_step_to(Vector2i(3, 4))
	assert_eq(_reactions.size(), 1, "pas avant 4 s")
	clock.step()
	clock.step()
	_step_to(Vector2i(3, 5))
	assert_eq(_reactions, ["caterpie:notice", "caterpie:notice"] as Array[String],
		"de nouveau après 4 s")
	assert_same(_map.get_npc(&"caterpie"), caterpie, "il ne quitte jamais la carte")
	assert_same(_map.get_grid().get_occupant(Vector2i(3, 3)), caterpie)
	clock.release()


func test_hide_retreats_into_the_foliage_then_leaves_the_map() -> void:
	var weedle := _map.get_npc(&"weedle")
	var sprite := weedle.get_node(^"%Sprite") as Node2D
	var rest_y := sprite.position.y
	var clock := TweenClock.new(get_tree())
	_step_to(Vector2i(6, 2))
	assert_eq(_reactions, [] as Array[String], "2 cases : rien (rayon 1)")
	_step_to(Vector2i(7, 2))
	assert_eq(_reactions, ["weedle:hide"] as Array[String], "1 case : il se rétracte")
	assert_false(_map.get_grid().is_occupied(Vector2i(8, 2)), "case libérée tout de suite")
	assert_true(_map.get_grid().is_solid(Vector2i(8, 2)), "toujours un tronc")
	var steps := roundi(Npc.RETREAT_DURATION / TweenClock.STEP)
	for i: int in steps - 1:
		clock.step()
	assert_lt(sprite.position.y, rest_y, "il recule vers le haut")
	assert_not_null(_map.get_npc(&"weedle"), "pas fini avant la durée")
	clock.step()
	clock.step()
	assert_null(_map.get_npc(&"weedle"), "retiré de la carte, comme l'envol")
	clock.release()


func test_reactions_wait_while_the_player_is_locked() -> void:
	_player.set_input_enabled(false)
	_step_to(Vector2i(3, 5))
	_step_to(Vector2i(7, 2))
	assert_true(_reactions.is_empty(), "scène, dialogue ou transition : rien")


func test_scare_step_and_watcher_share_the_same_gesture() -> void:
	var caterpie := _map.get_npc(&"caterpie")
	assert_eq(AmbientWatcher.play_reaction(caterpie, _map.get_grid(), Vector2i(3, 5)),
		&"notice")
	assert_same(_map.get_npc(&"caterpie"), caterpie, "notice : reste")
	assert_true(AmbientRules.leaves_map(&"hide"))
	assert_false(AmbientRules.leaves_map(&"notice"))
