extends GutTest
## Pose d'attente « pose » d'un PNJ (J21 : la prière de M. Fuji au 7F) : lecture par NpcRoster,
## jouée dans l'orientation de repos, attente debout dès qu'il se tourne.

const NPC_SCENE := preload("res://game/world/npc/npc.tscn")
const FUJI := {
	"cell": [10, 3], "facing": "up", "sprite": "mr_fuji", "dialogue": "tower_7f_fuji",
	"pose": "pray", "turn_to_player": false, "unless": ["fuji_rescued"],
}


func _parse(entry: Dictionary) -> Array:
	var errors := PackedStringArray()
	var spec := NpcRoster.parse_entry(entry, errors)
	return [spec, errors]


func _npc(entry: Dictionary) -> Npc:
	var parsed := _parse(entry)
	assert_eq(parsed[1], PackedStringArray())
	var npc := NPC_SCENE.instantiate() as Npc
	npc.setup(parsed[0])
	add_child_autofree(npc)
	return npc


func _sprite(npc: Npc) -> AnimatedSprite2D:
	return npc.get_node(^"%Sprite") as AnimatedSprite2D


func test_pose_is_read_and_optional() -> void:
	var spec: NpcSpec = _parse(FUJI)[0]
	assert_eq(spec.pose, &"pray")
	var without := FUJI.duplicate()
	without.erase("pose")
	assert_eq((_parse(without)[0] as NpcSpec).pose, &"")


func test_invalid_pose_is_refused() -> void:
	for value: Variant in ["", 3, true]:
		var entry := FUJI.duplicate()
		entry["pose"] = value
		assert_gt((_parse(entry)[1] as PackedStringArray).size(), 0, str(value))


func test_fuji_prays_facing_up_and_stands_when_turned() -> void:
	var npc := _npc(FUJI)
	assert_eq(_sprite(npc).animation, &"pray", "prière au repos (dos)")
	npc.face(Vector2i.DOWN)
	assert_eq(_sprite(npc).animation, &"idle_down", "il se relève, tourné vers le joueur")
	npc.face(Vector2i.UP)
	assert_eq(_sprite(npc).animation, &"pray")


func test_pose_missing_from_the_frames_falls_back_to_idle() -> void:
	var entry := FUJI.duplicate()
	entry["pose"] = "no_such_animation"
	assert_eq(_sprite(_npc(entry)).animation, &"idle_up")


func test_fuji_data_on_the_7f_prays_and_does_not_turn() -> void:
	var roster := NpcRoster.load_for_map(&"pokemon_tower_7f")
	assert_eq(roster.get_errors(), PackedStringArray())
	var fuji := roster.get_spec(&"mr_fuji")
	assert_not_null(fuji)
	assert_eq(fuji.pose, &"pray")
	assert_false(fuji.turn_to_player, "il prie pendant « … » ; la scène le relève (face)")
	var frames := load(Npc.frames_path(fuji.sprite)) as SpriteFrames
	assert_true(frames.has_animation(fuji.pose))
