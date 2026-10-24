extends GutTest
## Acteur de décor (jalon 21, `jalon-21.md` §2.3, T19) : [PropActor] (groupe « scene_props » dès sa
## création, petit saut par Tween, bulle [EmoteBubble]), [method GameMap.get_scene_prop] et la page
## « react » d'un dialogue qui vise un acteur de décor.

const TweenClock := preload("res://tests/helpers/tween_clock.gd")


func _prop(parent: Node, prop_name: String = "Snorlax") -> PropActor:
	var prop := PropActor.new()
	prop.name = prop_name
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	prop.add_child(sprite)
	parent.add_child(prop)
	return prop


func test_in_the_group_even_outside_the_tree() -> void:
	var prop := PropActor.new()
	assert_true(prop.is_in_group(PropActor.GROUP))
	assert_eq(PropActor.GROUP, &"scene_props")
	prop.free()


func test_react_hops_the_sprite_and_comes_back() -> void:
	var prop := _prop(add_child_autofree(Node2D.new()))
	var sprite := prop.get_node(^"Sprite") as Sprite2D
	var rest := sprite.position
	var clock := TweenClock.new(get_tree())
	prop.react()
	assert_true(prop.is_reacting())
	clock.step(prop.hop_duration / 2.0)
	assert_almost_eq(sprite.position.y, rest.y - prop.hop_height, 0.5, "en haut du saut")
	assert_eq(prop.position, Vector2.ZERO, "le nœud ne bouge pas")
	clock.step(prop.hop_duration / 2.0)
	clock.step()
	assert_eq(sprite.position, rest, "retour au repos")
	assert_false(prop.is_reacting())
	clock.release()


func test_react_twice_keeps_the_rest_position() -> void:
	var prop := _prop(add_child_autofree(Node2D.new()))
	var sprite := prop.get_node(^"Sprite") as Sprite2D
	var clock := TweenClock.new(get_tree())
	prop.react()
	clock.step(prop.hop_duration / 4.0)
	prop.react()
	clock.run_until(func() -> bool: return not prop.is_reacting(), 2.0)
	assert_eq(sprite.position, Vector2.ZERO)
	clock.release()


func test_emote_shows_a_bubble_then_finishes() -> void:
	var prop := _prop(add_child_autofree(Node2D.new()))
	watch_signals(prop)
	prop.emote_height = 200.0
	var clock := TweenClock.new(get_tree())
	prop.show_emote(&"exclamation")
	assert_true(prop.is_emoting())
	var bubble := prop.get_node(^"PropEmote") as EmoteBubble
	assert_eq(bubble.get_icon(), EmoteBubble.ICONS[EmoteBubble.EXCLAIM], "« ! »")
	assert_eq(bubble.tip_height, 200.0)
	clock.run_until(func() -> bool: return not prop.is_emoting(), 5.0)
	assert_signal_emitted(prop, "emote_finished")
	clock.release()


func test_map_finds_a_prop_by_name_only_inside_itself() -> void:
	var map := GameMap.new()
	map.name = "PropMap"
	var entities := Node2D.new()
	entities.name = "Entities"
	map.add_child(entities)
	var prop := _prop(entities)
	var elsewhere := add_child_autofree(Node2D.new()) as Node2D
	_prop(elsewhere, "Other")
	assert_null(map.get_scene_prop(&"Snorlax"), "hors de l'arbre : rien")
	add_child_autofree(map)
	assert_same(map.get_scene_prop(&"Snorlax"), prop)
	assert_null(map.get_scene_prop(&"Other"), "pas celui d'une autre carte")
	assert_null(map.get_scene_prop(&"nobody"))
	assert_null(map.get_scene_prop(&""))


func test_a_dialogue_page_react_reaches_a_prop_actor() -> void:
	var map := GameMap.new()
	map.name = "PropMap"
	map.map_id = &"prop_map"
	map.npcs_dir = "res://tests/fixtures/npcs/"
	map.size = Vector2i(20, 18)
	for group: String in ["Entities", "Warps", "Interactables", "Spawns"]:
		var node := Node2D.new()
		node.name = group
		map.add_child(node)
	var prop := _prop(map.get_node(^"Entities"))
	add_child_autofree(map)
	var library := DialogueLibrary.new()
	assert_true(library.add_from_dict({"prop_react": {"pages": [
		{"text": "Ronflex bouge.", "react": "Snorlax"}]}}, "test"))
	var box := (load("res://game/ui/dialogue/dialogue_box.tscn") as PackedScene) \
		.instantiate() as DialogueBox
	add_child_autofree(box)
	var player := (load("res://game/player/player.tscn") as PackedScene).instantiate() as Player
	autofree(player)
	var runner := DialogueRunner.new()
	runner.chars_per_second = 0.0
	add_child_autofree(runner)
	runner.setup(library, StoryFlags.new(), box, player)
	assert_same(map.get_scene_prop(&"Snorlax"), prop, "trouvé")
	# La première page commence dans l'appel même : le saut est lancé tout de suite.
	assert_true(runner.play(&"prop_react", null, map))
	assert_true(prop.is_reacting(), "l'acteur de décor réagit")
	assert_push_warning_count(0)
