extends GutTest
## Icônes du Sac ajoutées après coup (QA du 2026-10-23) : fichier présent, 256 × 256.


func test_bag_icons_exist_and_are_256_squares() -> void:
	for id: StringName in [&"ultra_ball"]:
		var path := MenuArt.item_icon_path(id)
		assert_true(ResourceLoader.exists(path), String(id))
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		assert_not_null(image, String(id))
		if image != null:
			assert_eq(image.get_size(), Vector2i(256, 256), String(id))
