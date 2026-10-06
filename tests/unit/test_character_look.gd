extends GutTest
## CharacterLook : apparence peinte d'abord (×1, LINEAR), provisoire ensuite (×2, NEAREST),
## générique en dernier (docs/tech/jalon-07.md §3.2, T2) ; T3 : planches peintes générées,
## branchées dans Npc et Player, Pokémon du monde peints sur demande (« pokemon/<espèce> »).

const NPC_SCENE := preload("res://game/world/npc/npc.tscn")
const FRAMES_TOOL := "res://tools/build_character_frames.gd"


## Faux système de fichiers : seuls les chemins de [param paths] existent.
func _exists_in(paths: Array[String]) -> Callable:
	return func(path: String) -> bool: return paths.has(path)


func test_painted_first() -> void:
	var look := CharacterLook.resolve(&"nurse", _exists_in([
		"res://assets/sprites/characters/painted/nurse_frames.tres",
		"res://assets/sprites/characters/placeholder/nurse_frames.tres",
	]))
	assert_eq(look.frames_path, "res://assets/sprites/characters/painted/nurse_frames.tres")
	assert_true(look.painted)
	assert_eq(look.scale, 1.0, "128 px affichés à 1:1")
	assert_eq(look.filter, CanvasItem.TEXTURE_FILTER_LINEAR)


func test_placeholder_when_no_painted_sheet() -> void:
	var look := CharacterLook.resolve(&"mom", _exists_in([
		"res://assets/sprites/characters/placeholder/mom_frames.tres",
	]))
	assert_eq(look.frames_path, "res://assets/sprites/characters/placeholder/mom_frames.tres")
	assert_false(look.painted)
	assert_eq(look.scale, 2.0, "pixel art ×2")
	assert_eq(look.filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_generic_look_last() -> void:
	for sprite: StringName in [&"stranger", &""]:
		var look := CharacterLook.resolve(sprite, _exists_in([]))
		assert_eq(look.frames_path,
			"res://assets/sprites/characters/placeholder/npc_frames.tres", str(sprite))
		assert_false(look.painted)
		assert_eq(look.scale, 2.0)
		assert_eq(look.filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_default_check_reads_the_real_resources() -> void:
	# Sans Callable : ResourceLoader.exists. La mère n'a que sa planche provisoire (phase DA),
	# l'apparence générique existe.
	var mom := CharacterLook.resolve(&"mom")
	assert_eq(mom.frames_path, CharacterLook.placeholder_frames_path(&"mom"))
	assert_true(ResourceLoader.exists(mom.frames_path))
	var nobody := CharacterLook.resolve(&"nobody_here")
	assert_eq(nobody.frames_path,
		CharacterLook.placeholder_frames_path(CharacterLook.FALLBACK_SPRITE))
	assert_true(ResourceLoader.exists(nobody.frames_path), "l'apparence générique existe")
	assert_eq(CharacterLook.FALLBACK_SPRITE, Npc.FALLBACK_SPRITE, "même générique que Npc")


func test_painted_pokemon_by_explicit_prefix() -> void:
	var look := CharacterLook.resolve(&"pokemon/pidgey", _exists_in([
		"res://assets/sprites/pokemon/painted/pidgey_frames.tres",
		"res://assets/sprites/characters/placeholder/pidgey_frames.tres",
	]))
	assert_eq(look.frames_path, "res://assets/sprites/pokemon/painted/pidgey_frames.tres")
	assert_true(look.painted)
	assert_eq(look.scale, 1.0)
	var fallback := CharacterLook.resolve(&"pokemon/charmander", _exists_in([
		"res://assets/sprites/characters/placeholder/charmander_frames.tres",
	]))
	assert_eq(fallback.frames_path,
		"res://assets/sprites/characters/placeholder/charmander_frames.tres",
		"sans planche peinte : le provisoire de l'espèce")
	assert_false(fallback.painted)


## Les vraies apparences générées par tools/build_character_frames.gd.
func test_real_painted_looks() -> void:
	for sprite: StringName in [&"player", &"rival", &"nurse", &"clerk", &"courier", &"lass",
			&"kid", &"old_man", &"traveler", &"youngster", &"pokemon/pidgey", &"pokemon/rattata",
			&"pokemon/spearow", &"pokemon/mankey", &"pokemon/nidoran_f", &"pokemon/nidoran_m"]:
		var look := CharacterLook.resolve(sprite)
		assert_true(look.painted, String(sprite))
		assert_eq(look.filter, CanvasItem.TEXTURE_FILTER_LINEAR)
	# Bourg Palette et la Route 1 gardent leurs Pokémon provisoires (Q-2, Q-3).
	for sprite: StringName in [&"pidgey", &"rattata", &"mom", &"oak"]:
		assert_false(CharacterLook.resolve(sprite).painted, String(sprite))


## Chaque planche du catalogue a sa correspondance et ses SpriteFrames.
func test_every_sheet_maps_to_generated_frames() -> void:
	var tool_script := load(FRAMES_TOOL) as Script
	var constants := tool_script.get_script_constant_map()
	var looks: Dictionary = constants["LOOKS"]
	var catalogue: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/world/catalogue.json"))
	var idle_suffix: String = constants["IDLE_SUFFIX"]
	for sheet: String in catalogue["personnages"]:
		var idle_of := sheet.trim_suffix(idle_suffix)
		var is_idle := idle_of != sheet and looks.has(idle_of)
		assert_true(looks.has(sheet) or (constants["RUN_ONLY"] as Array).has(sheet) or is_idle,
			sheet)
	for sheet: String in looks:
		var entry: Array = looks[sheet]
		var path := String(entry[0]) + String(entry[1]) + "_frames.tres"
		assert_true(ResourceLoader.exists(path), "%s → %s" % [sheet, path])
	assert_eq(looks["heros"][1], "player")
	assert_eq(looks["infirmiere"][1], "nurse")
	assert_eq(looks["roucool"][1], "pidgey")
	assert_eq(looks["piafabec"][1], "spearow")
	assert_eq(looks["ferosinge"][1], "mankey")


func test_painted_frames_cycle_two_tiles_per_walk_loop() -> void:
	var frames := load(CharacterLook.painted_frames_path(&"nurse")) as SpriteFrames
	for dir: String in ["down", "left", "right", "up"]:
		var idle := StringName("idle_" + dir)
		var walk := StringName("walk_" + dir)
		var run := StringName("run_" + dir)
		assert_eq(frames.get_frame_count(idle), 1, String(idle))
		assert_eq(frames.get_frame_count(walk), 4, String(walk))
		# Retours T5 : sans planche de course, aucune course (pas de marche jouée en accéléré).
		assert_false(frames.has_animation(run), "%s : pas de fausse course" % run)
		assert_true(frames.get_animation_loop(walk))
		assert_almost_eq(4.0 / frames.get_animation_speed(walk), 2.0 * Grid.WALK_STEP_DURATION,
			0.001, "un cycle = deux cases de marche")
		# Repos = planche d'attente pieds joints (une colonne par direction, décision de Kevin du
		# 2026-10-06 ; test_rest_pose) ; marche : colonnes 1, 2, 3, 0 de la ligne.
		var row: int = {"down": 0, "left": 1, "right": 2, "up": 3}[dir]
		var cell := Vector2(88, 134)
		var rest := frames.get_frame_texture(idle, 0) as AtlasTexture
		assert_eq(rest.atlas.resource_path,
			"res://assets/sprites/characters/painted/infirmiere_idle_sheet.png", "attente")
		assert_eq(rest.region.size.y, cell.y, "même hauteur que la marche (ancrage aux pieds)")
		assert_eq(rest.region.position, Vector2(row * rest.region.size.x, 0))
		var first_step := frames.get_frame_texture(walk, 0) as AtlasTexture
		assert_eq(first_step.region, Rect2(Vector2(1, row) * cell, cell))
	var hero := load(CharacterLook.painted_frames_path(&"player")) as SpriteFrames
	var run_frame := hero.get_frame_texture(&"run_down", 0) as AtlasTexture
	assert_eq(run_frame.atlas.resource_path,
		"res://assets/sprites/characters/painted/heros_run_sheet.png", "planche de course")
	for dir: String in ["down", "left", "right", "up"]:
		assert_almost_eq(4.0 / hero.get_animation_speed(StringName("run_" + dir)),
			2.0 * Grid.RUN_STEP_DURATION, 0.001, "un cycle = deux cases de course")


func _npc(sprite: StringName) -> Npc:
	var spec := NpcSpec.new()
	spec.id = &"test"
	spec.sprite = sprite
	var npc := NPC_SCENE.instantiate() as Npc
	npc.setup(spec)
	add_child_autofree(npc)
	return npc


func test_npc_painted_at_scale_one_linear() -> void:
	var npc := _npc(&"nurse")
	var sprite := npc.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(sprite.sprite_frames.resource_path, CharacterLook.painted_frames_path(&"nurse"))
	assert_eq(sprite.scale, Vector2.ONE)
	assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR)
	assert_eq(sprite.offset.y, -134.0 / 2.0, "pieds sur l'origine")
	assert_true(npc.is_tall())
	var pidgey := _npc(&"pokemon/pidgey")
	var bird := pidgey.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(bird.scale, Vector2.ONE)
	assert_false(pidgey.is_tall(), "un Pokémon peint tient dans une case")


func test_npc_placeholder_twice_nearest() -> void:
	var npc := _npc(&"mom")
	var sprite := npc.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(sprite.sprite_frames.resource_path, CharacterLook.placeholder_frames_path(&"mom"))
	assert_eq(sprite.scale, Vector2(2, 2))
	assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
	var unknown := _npc(&"villager")
	var generic := unknown.get_node(^"%Sprite") as AnimatedSprite2D
	assert_eq(generic.sprite_frames.resource_path,
		CharacterLook.placeholder_frames_path(CharacterLook.FALLBACK_SPRITE))
	assert_eq(generic.scale, Vector2(2, 2))


func test_npc_frames_helpers_follow_character_look() -> void:
	assert_eq(Npc.frames_path(&"rival"), CharacterLook.painted_frames_path(&"rival"))
	assert_true(Npc.has_frames(&"rival"))
	assert_true(Npc.has_frames(&"pokemon/rattata"))
	assert_true(Npc.has_frames(&"mom"))
	assert_false(Npc.has_frames(&"villager"))
	assert_true(Npc.has_frames(Npc.FALLBACK_SPRITE))
