extends GutTest
## VolumeMath, SfxCatalog et CryCatalog (Son.0, T3 ; docs/tech/jalon-son.md §1.7–§1.9).

var _library: AudioLibrary


func before_all() -> void:
	_library = AudioLibrary.new()
	_library.load_dir()


func test_volume_zero_is_muted_and_full_is_zero_db() -> void:
	assert_true(VolumeMath.is_muted(0.0))
	assert_false(VolumeMath.is_muted(0.1))
	assert_eq(VolumeMath.to_db(0.0), VolumeMath.MUTED_DB)
	assert_almost_eq(VolumeMath.to_db(1.0), 0.0, 0.001)
	assert_almost_eq(VolumeMath.to_db(0.5), linear_to_db(0.25), 0.001, "courbe x²")


func test_volume_is_monotonic_and_clamped() -> void:
	var last := VolumeMath.MUTED_DB - 1.0
	for step: int in range(0, 11):
		var db := VolumeMath.to_db(step / 10.0)
		assert_gt(db, last, "cran %d" % step)
		last = db
	assert_almost_eq(VolumeMath.to_db(2.0), 0.0, 0.001)
	assert_eq(VolumeMath.to_db(-1.0), VolumeMath.MUTED_DB)


func test_sfx_variants_are_picked_among_the_files() -> void:
	var sfx := SfxCatalog.new(_library)
	var files := sfx.files(&"step_grass")
	assert_eq(files.size(), 4, "pas dans l'herbe : 4 variantes")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var seen: Dictionary = {}
	for i: int in 40:
		var file := sfx.pick_file(&"step_grass", rng)
		assert_true(files.has(file))
		seen[file] = true
	assert_gt(seen.size(), 1, "le hasard varie")
	assert_eq(sfx.pick_file(&"ui_confirm", rng), "res://assets/audio/sfx/ui_confirm.ogg")
	assert_eq(sfx.pick_file(&"unknown", rng), "")


func test_sfx_polyphony_limit() -> void:
	var sfx := SfxCatalog.new(_library)
	assert_eq(sfx.max_polyphony(&"step_grass"), 2)
	assert_true(sfx.can_play(&"step_grass"))
	sfx.started(&"step_grass")
	sfx.started(&"step_grass")
	assert_false(sfx.can_play(&"step_grass"), "pas de pas qui s'empilent")
	sfx.finished(&"step_grass")
	assert_true(sfx.can_play(&"step_grass"))
	sfx.finished(&"step_grass")
	sfx.finished(&"step_grass")
	assert_eq(sfx.playing_count(&"step_grass"), 0, "jamais en dessous de 0")
	assert_false(sfx.can_play(&"unknown"))


func test_sfx_bus_and_expected() -> void:
	var sfx := SfxCatalog.new(_library)
	assert_eq(sfx.bus(&"ui_confirm"), &"Sfx")
	assert_true(sfx.is_expected(&"ui_confirm"))


func test_move_sound_families() -> void:
	# SON-11 : exception par attaque → type × catégorie → catégorie.
	var sfx := SfxCatalog.new(_library)
	assert_eq(sfx.move_sfx(&"ember", &"fire", &"special"), &"move_fire")
	assert_eq(sfx.move_sfx(&"tackle", &"normal", &"physical"), &"move_hit")
	assert_eq(sfx.move_sfx(&"swift", &"normal", &"special"), &"move_beam")
	assert_eq(sfx.move_sfx(&"tail_whip", &"normal", &"status"), &"move_status")
	assert_eq(sfx.move_sfx(&"growl", &"normal", &"status"), &"move_sound")
	assert_eq(sfx.move_sfx(&"explosion", &"normal", &"physical"), &"move_explosion")
	assert_eq(sfx.move_sfx(&"rest", &"psychic", &"status"), &"move_heal")
	assert_eq(sfx.move_sfx(&"hypnosis", &"psychic", &"status"), &"move_status",
		"un type sans statut propre retombe sur la catégorie")


func test_every_move_has_a_sound() -> void:
	var sfx := SfxCatalog.new(_library)
	var data := PokemonData.new()
	data.load_dir()
	for move_id: StringName in data.get_move_ids():
		var move := data.get_move(move_id)
		var id := sfx.move_sfx(move_id, move.type, MoveData.Category.find_key(move.category)
			.to_lower())
		assert_true(sfx.has(id), String(move_id))


func test_151_cries_by_national_number() -> void:
	var cries := CryCatalog.new(_library)
	assert_eq(cries.count(), 151)
	var paths: Dictionary = {}
	for dex: int in range(1, 152):
		var path := cries.path_for(dex)
		assert_eq(path, "res://assets/audio/cries/%d.ogg" % dex)
		paths[path] = true
	assert_eq(paths.size(), 151, "un fichier par espèce")
	assert_eq(cries.path_for(0), "")
	assert_eq(cries.path_for(152), "")
	assert_true(cries.is_expected(), "SonB")


func test_every_species_has_a_cry() -> void:
	var cries := CryCatalog.new(_library)
	var data := PokemonData.new()
	data.load_dir()
	for species_id: StringName in data.get_species_ids():
		assert_ne(cries.path_for_species(data.get_species(species_id)), "", String(species_id))
	assert_eq(cries.path_for_species(null), "")


func test_faint_cry_is_lower() -> void:
	var cries := CryCatalog.new(_library)
	assert_eq(cries.pitch(), 1.0)
	assert_almost_eq(cries.pitch(true), 0.8, 0.001, "K.O. : plus grave, comme RB")
	assert_eq(cries.bus(), &"Cries")
