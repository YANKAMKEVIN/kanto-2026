extends GutTest
## Surf peint (série 27 du J24, branché le 2026-11-04 à la demande de Kevin) : le héros, la joueuse
## et chaque costume ont `surf_walk_<dir>` et `surf_idle_<dir>` dans leurs animations du monde,
## tirées de leur planche de Surf ; le joueur les joue donc à la place de la monture provisoire
## dessinée en code ([MountPlaceholder]).

const DIRS: Array[String] = ["down", "left", "right", "up"]
const PAINTED := "res://assets/sprites/characters/painted/"


func _looks() -> Array[String]:
	var paths: Array[String] = [PAINTED + "player_frames.tres", PAINTED + "player_heroine_frames.tres"]
	var catalog := CostumeCatalog.shared()
	for id: StringName in catalog.ids():
		for look: StringName in [&"hero", &"heroine"]:
			paths.append(PAINTED + String(catalog.world_sprite(id, look)) + "_frames.tres")
	return paths


func test_every_player_look_has_painted_surf_animations() -> void:
	var looks := _looks()
	assert_eq(looks.size(), 2 + 2 * CostumeCatalog.shared().size(), "héros, joueuse, costumes")
	for path: String in looks:
		assert_true(ResourceLoader.exists(path), path)
		var frames := load(path) as SpriteFrames
		if frames == null:
			continue
		for dir: String in DIRS:
			var walk := StringName("surf_walk_" + dir)
			var idle := StringName("surf_idle_" + dir)
			assert_true(frames.has_animation(walk), "%s : %s" % [path.get_file(), walk])
			assert_true(frames.has_animation(idle), "%s : %s" % [path.get_file(), idle])
			if not frames.has_animation(walk) or not frames.has_animation(idle):
				continue
			assert_eq(frames.get_frame_count(walk), 4, "%s : cycle de 4 images" % walk)
			assert_eq(frames.get_frame_count(idle), 4, "%s : ondulation de 4 images" % idle)
			assert_true(frames.get_animation_loop(idle), "%s en boucle" % idle)
			var atlas := frames.get_frame_texture(walk, 0) as AtlasTexture
			assert_not_null(atlas)
			if atlas != null:
				assert_true(atlas.atlas.resource_path.ends_with("_surf_sheet.png"),
					"%s : tirée de la planche de Surf (%s)" % [walk, atlas.atlas.resource_path])
