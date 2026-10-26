extends GutTest
## Lecture des points d'origine par [FxAnchors] (chantier Combat vivant, CV.0 T6 ; CV-10) :
## paires, repli point demandé → bouche → tête → centre, conversion en px de l'image source.

func _anchors() -> FxAnchors:
	var anchors := FxAnchors.new()
	anchors.read({"species": {
		"025": {"id": "pikachu", "front": {"size": [400, 300], "box": [100, 50, 200, 100],
			"points": {"tete": [0.5, 0.2], "bouche": [0.5, 0.4],
			"joues": [[0.25, 0.5], [0.75, 0.5]], "centre": [0.5, 0.6]}},
			"back": {"size": [1024, 1024], "box": [0, 0, 1024, 1024],
			"points": {"tete": [0.4, 0.3], "centre": [0.5, 0.5]}}},
		"999": {"id": "", "front": {"box": [0, 0, 1, 1]}},
		"998": {"id": "nobox", "front": {"points": {"tete": [0.1, 0.1]}}},
	}})
	return anchors


func test_point_asked_is_used() -> void:
	var anchors := _anchors()
	assert_eq(anchors.resolve(&"pikachu", FxAnchors.FRONT, &"joues"), &"joues")
	assert_eq(anchors.point(&"pikachu", FxAnchors.FRONT, &"bouche"), Vector2(0.5, 0.4))


func test_pairs_give_two_points_and_their_middle() -> void:
	var anchors := _anchors()
	var cheeks := anchors.points(&"pikachu", FxAnchors.FRONT, &"joues")
	assert_eq(cheeks.size(), 2)
	assert_eq(cheeks[0], Vector2(0.25, 0.5), "gauche d'abord")
	assert_eq(anchors.point(&"pikachu", FxAnchors.FRONT, &"joues"), Vector2(0.5, 0.5))


func test_fallback_chain() -> void:
	var anchors := _anchors()
	assert_eq(anchors.resolve(&"pikachu", FxAnchors.FRONT, &"canons"), &"bouche", "→ bouche")
	assert_eq(anchors.resolve(&"pikachu", FxAnchors.BACK, &"joues"), &"tete", "→ tête")
	assert_eq(anchors.point(&"pikachu", FxAnchors.BACK, &"joues"), Vector2(0.4, 0.3))
	var only_centre := FxAnchors.new()
	only_centre.read({"species": {"001": {"id": "a", "front": {"box": [0, 0, 10, 10],
		"points": {"centre": [0.3, 0.7]}}}}})
	assert_eq(only_centre.resolve(&"a", FxAnchors.FRONT, &"queue"), &"centre", "→ centre")


func test_unknown_species_or_view_gives_the_middle() -> void:
	var anchors := _anchors()
	assert_false(anchors.has_species(&"mew"))
	assert_eq(anchors.resolve(&"mew", FxAnchors.FRONT, &"bouche"), &"")
	assert_eq(anchors.point(&"mew", FxAnchors.FRONT, &"bouche"), FxAnchors.MIDDLE)
	assert_false(anchors.has_species(&""), "entrée sans id ignorée")
	assert_eq(anchors.point(&"nobox", FxAnchors.FRONT, &"tete"), FxAnchors.MIDDLE,
		"vue sans boîte ignorée")


func test_box_size_and_pixels() -> void:
	var anchors := _anchors()
	var box := anchors.box(&"pikachu", FxAnchors.FRONT)
	assert_eq(box, Rect2i(100, 50, 200, 100), "box = [x, y, largeur, hauteur]")
	assert_eq(anchors.image_size(&"pikachu", FxAnchors.FRONT), Vector2i(400, 300))
	assert_eq(FxAnchors.to_image_pixels(Vector2(0.25, 0.5), box), Vector2(150, 100))
	assert_eq(anchors.box(&"mew", FxAnchors.BACK), Rect2i())


func test_real_file_pikachu_cheeks_and_every_species_resolves() -> void:
	var anchors := FxAnchors.load_file()
	assert_eq(anchors.resolve(&"pikachu", FxAnchors.FRONT, &"joues"), &"joues", "CV-10, §10")
	var data := PokemonData.new()
	data.load_dir()
	for species_id: StringName in data.get_species_ids():
		for view: StringName in [FxAnchors.FRONT, FxAnchors.BACK]:
			# Vue « null » dans le fichier : image pas encore peinte (dos de Ossatueur…), milieu.
			if anchors.box(species_id, view).has_area():
				assert_false(anchors.resolve(species_id, view, &"bouche").is_empty(),
					"%s %s : un point au moins" % [species_id, view])
			var p := anchors.point(species_id, view, &"joues")
			assert_true(p.x >= 0.0 and p.x <= 1.0 and p.y >= 0.0 and p.y <= 1.0,
				"%s %s : dans la boîte" % [species_id, view])
