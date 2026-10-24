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
	assert_gte(_files().size(), 77, "dos IA : 54 du lot 2 + 23 de battle_proto")


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
		# 072 (Tentacool) et 129 (Magicarpe) : dos prêts, espèces pas encore dans les données.
		if by_number.has(number):
			var image := _art.image(by_number[number], true)
			assert_eq((image["texture"] as Texture2D).resource_path, BattleArt.painted_back_path(number), f)


func test_a_species_without_painted_back_keeps_its_placeholder() -> void:
	var image := _art.image(&"blastoise", true)
	assert_false(image["official"])
	assert_eq((image["texture"] as Texture2D).resource_path, BattleArt.placeholder_path(&"blastoise", true))


## Salamèche (4) a un dos IA : il est peint, cadré dans la boîte, et prime sur son dos 3D.
func test_charmander_now_has_a_painted_back() -> void:
	var image := _art.image(&"charmander", true)
	assert_true(image["official"])
	assert_eq((image["texture"] as Texture2D).resource_path, BattleArt.painted_back_path(4))


## Priorité IA > 3D > provisoire : 001 a les deux (IA gagne), 050 n'a que le 3D, 009 aucun.
func test_ia_beats_3d_beats_placeholder() -> void:
	assert_true(FileAccess.file_exists(BattleArt.painted_back_3d_path(1)) or
		ResourceLoader.exists(BattleArt.painted_back_3d_path(1)), "001 a un dos 3D")
	assert_eq(BattleArt.best_painted_back_path(1), BattleArt.painted_back_path(1))
	assert_eq(BattleArt.best_painted_back_path(50), BattleArt.painted_back_3d_path(50))
	assert_eq(BattleArt.best_painted_back_path(9), "")
	var image := _art.image(&"diglett", true)
	assert_eq((image["texture"] as Texture2D).resource_path, BattleArt.painted_back_3d_path(50))
	assert_true(image["official"])


## Chaque dos 3D est lu quand l'espèce n'a pas de dos IA, jamais sinon.
func test_every_3d_file_is_used_only_without_ia() -> void:
	var n := 0
	for f: String in DirAccess.get_files_at("res://assets/sprites/pokemon/dos/"):
		if f.begins_with("dos3d_") and f.ends_with(".png"):
			n += 1
			var number := f.trim_prefix("dos3d_").trim_suffix(".png").to_int()
			var want := BattleArt.painted_back_path(number) \
				if ResourceLoader.exists(BattleArt.painted_back_path(number)) \
				else BattleArt.painted_back_3d_path(number)
			assert_eq(BattleArt.best_painted_back_path(number), want, f)
	assert_eq(n, 16, "16 dos 3D")
