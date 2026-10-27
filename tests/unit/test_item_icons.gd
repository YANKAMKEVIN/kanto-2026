extends GutTest
## Couverture des icônes du Sac (DAF.5) : chaque objet de `data/items/*.json` a son icône peinte
## (`assets/ui/items/<id>.webp`, 256 × 256, lue par [method MenuArt.item_icon]).


func test_every_item_has_a_painted_icon() -> void:
	var library := ItemLibrary.new()
	assert_true(library.load_dir(), "data/items/ se charge")
	var missing: Array[StringName] = []
	for item_id: StringName in library.get_ids():
		if not ResourceLoader.exists(MenuArt.item_icon_path(item_id)):
			missing.append(item_id)
	assert_eq(missing, [] as Array[StringName], "objets sans icône : %s" % str(missing))


func test_icons_are_square_256() -> void:
	var library := ItemLibrary.new()
	library.load_dir()
	for item_id: StringName in library.get_ids():
		var icon := MenuArt.item_icon(item_id)
		if icon == null:
			continue
		assert_eq(icon.get_size(), Vector2(256, 256), "taille de l'icône de %s" % item_id)
