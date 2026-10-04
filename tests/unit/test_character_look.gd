extends GutTest
## CharacterLook : apparence peinte d'abord (×1, LINEAR), provisoire ensuite (×2, NEAREST),
## générique en dernier (docs/tech/jalon-07.md §3.2, T2).


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
	# Sans Callable : ResourceLoader.exists. Aucune planche peinte n'est encore importée (T3) ;
	# la mère a sa planche provisoire, l'apparence générique existe.
	var mom := CharacterLook.resolve(&"mom")
	assert_eq(mom.frames_path, CharacterLook.placeholder_frames_path(&"mom"))
	assert_true(ResourceLoader.exists(mom.frames_path))
	var nobody := CharacterLook.resolve(&"nobody_here")
	assert_eq(nobody.frames_path,
		CharacterLook.placeholder_frames_path(CharacterLook.FALLBACK_SPRITE))
	assert_true(ResourceLoader.exists(nobody.frames_path), "l'apparence générique existe")
	assert_eq(CharacterLook.FALLBACK_SPRITE, Npc.FALLBACK_SPRITE, "même générique que Npc")
