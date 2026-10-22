extends GutTest
## Dos de combat peints (série dos, `assets/sprites/pokemon/dos/`) : lus par BattleArt pour les espèces
## qui en ont un ; les autres gardent leur sprite provisoire.

var _art := BattleArt.new()


func _files() -> Array[String]:
	var out: Array[String] = []
	for f: String in DirAccess.get_files_at("res://assets/sprites/pokemon/dos/"):
		if f.begins_with("dos_ia_") and f.ends_with(".png"):
			out.append(f)
	return out


func test_the_series_is_present() -> void:
	assert_gte(_files().size(), 50, "dos peints du lot")


func test_a_painted_back_is_read_for_rattata() -> void:
	var image := _art.image(&"rattata", true)
	assert_true(image["official"], "peint : filtre linéaire")
	assert_eq((image["texture"] as Texture2D).resource_path, BattleArt.painted_back_path(19))
	assert_eq((image["texture"] as Texture2D).get_size(), Vector2(1024, 1024))
	var box: Rect2 = image["box"]
	assert_lte(box.size.y, 870.0)
	assert_gt(box.size.y, 300.0)


func test_every_painted_file_is_read_for_its_species() -> void:
	var data := PokemonData.new()
	assert_true(data.load_dir())
	var by_number: Dictionary = {}
	for id: StringName in data.get_species_ids():
		by_number[data.get_species(id).dex] = id
	for f: String in _files():
		var number := f.trim_prefix("dos_ia_").trim_suffix(".png").to_int()
		assert_true(by_number.has(number), "%s : espèce des données" % f)
		if by_number.has(number):
			var image := _art.image(by_number[number], true)
			assert_eq((image["texture"] as Texture2D).resource_path, BattleArt.painted_back_path(number), f)


func test_a_species_without_painted_back_keeps_its_placeholder() -> void:
	var image := _art.image(&"charmander", true)
	assert_false(image["official"])
	assert_eq((image["texture"] as Texture2D).resource_path, BattleArt.placeholder_path(&"charmander", true))
