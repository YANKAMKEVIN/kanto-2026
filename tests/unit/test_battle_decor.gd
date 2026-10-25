extends GutTest
## Décors peints de combat (CB.3) : catalogue en données (data/battle/decors.json), choix du
## décor par le lieu (carte, variante locale par cases), repli sans décor, ligne de sol et
## placement (BattleDecor.fit : pieds sur le sol peint, écran toujours couvert).

const VIEWS: Array[Vector2] = [Vector2(2340, 1080), Vector2(1920, 1080), Vector2(2400, 1080)]


func _catalog() -> BattleDecorCatalog:
	return BattleDecorCatalog.load_file()


## Décor de test : master 2340 × 1080 peint pour les ancres (comme route_1_chemin).
func _decor_data(extra: Dictionary = {}) -> Dictionary:
	var data := {
		"zone": "route_1", "variant": "chemin", "back": "res://x_back.webp",
		"size": [2340, 1080], "foe_feet": [1559, 540], "player_feet": [716, 972],
	}
	data.merge(extra, true)
	return data


# --- Données réelles ------------------------------------------------------------------

func test_real_catalog_has_route_1() -> void:
	var catalog := _catalog()
	assert_has(catalog.get_ids(), &"route_1_chemin")
	assert_has(catalog.get_maps(), &"route_1")


func test_real_decors_are_valid_and_files_exist() -> void:
	var catalog := _catalog()
	for id: StringName in catalog.get_ids():
		var decor := catalog.get_decor(id)
		assert_true(decor.is_valid(), "%s : ligne de sol cohérente" % id)
		assert_true(ResourceLoader.exists(decor.back_path), "%s : fond présent" % id)
		var back := load(decor.back_path) as Texture2D
		assert_eq(back.get_size(), decor.size, "%s : taille du master = données" % id)
		assert_true(decor.size.x >= 2340.0 and decor.size.y >= 1080.0,
			"%s : master au moins 2340 × 1080" % id)
		if decor.front_path != "":
			var front := load(decor.front_path) as Texture2D
			assert_not_null(front, "%s : premier plan présent" % id)
			assert_eq(front.get_size(), decor.size, "%s : premier plan à la taille du fond" % id)


func test_route_1_decor_matches_its_zone() -> void:
	var decor := _catalog().pick(&"route_1", Vector2i(10, 30))
	assert_not_null(decor)
	assert_eq(decor.zone, &"route_1")
	assert_eq(decor.variant, &"chemin")


func test_places_without_decor_fall_back() -> void:
	var catalog := _catalog()
	for map_id: StringName in [&"oak_lab", &"player_house_2f", &"inconnue"]:
		assert_null(catalog.pick(map_id, Vector2i.ZERO), "%s : repli (pas de décor)" % map_id)


## DAF.2 : toute carte à combats (citée par une table de rencontres ou portant un PNJ Dresseur)
## a un fond peint ; plus aucune ne retombe sur la carte floutée.
func test_every_battle_map_has_a_decor() -> void:
	var maps := _catalog().get_maps()
	var battle_maps: Dictionary[StringName, bool] = {}
	for file: String in DirAccess.get_files_at("res://data/encounters"):
		if not file.ends_with(".json"):
			continue
		var tables: Variant = JSON.parse_string(FileAccess.get_file_as_string(
			"res://data/encounters/" + file))
		for table: Variant in (tables as Dictionary).values():
			if table is Dictionary:
				for map_id: Variant in (table as Dictionary).get("maps", []):
					battle_maps[StringName(map_id)] = true
	for file: String in DirAccess.get_files_at("res://data/npcs"):
		if file.ends_with(".json") and FileAccess.get_file_as_string(
				"res://data/npcs/" + file).contains("\"trainer\""):
			battle_maps[StringName(file.get_basename())] = true
	assert_gt(battle_maps.size(), 60, "cartes à combats trouvées")
	var missing: Array[StringName] = []
	for map_id: StringName in battle_maps:
		if not maps.has(map_id):
			missing.append(map_id)
	assert_eq(missing, [] as Array[StringName], "cartes à combats sans fond peint")


func test_real_route_1_painted_for_the_anchors() -> void:
	# Le master est peint pour le cadrage : à 2340 × 1080 il s'affiche à 1:1, sans décalage.
	var decor := _catalog().get_decor(&"route_1_chemin")
	var rect := decor.fit(Vector2(2340, 1080))
	assert_almost_eq(rect.size.x, 2340.0, 2.0)
	assert_almost_eq(rect.position.y, 0.0, 1.0)
	assert_true(decor.horizon > 0.0 and decor.horizon < decor.foe_feet.y,
		"horizon au-dessus des pieds de l'adversaire")


## Correctif QA S24 : les pieds de ton Pokémon reposent sur le sol visible, **au-dessus** du
## feuillage flou de premier plan (la bande du bas du calque avant), pas derrière lui.
func test_real_player_feet_above_the_foreground_band() -> void:
	var catalog := _catalog()
	for id: StringName in catalog.get_ids():
		var decor := catalog.get_decor(id)
		if decor.front_path == "":
			continue
		var image := (load(decor.front_path) as Texture2D).get_image()
		var feet := Vector2i(decor.player_feet)
		var around := _mean_alpha(image, feet.x - 150, feet.x + 150, feet.y - 8, feet.y)
		assert_lt(around, 0.1, "%s : sol dégagé sous les pieds (alpha %.2f)" % [id, around])
		var band := _mean_alpha(image, feet.x - 150, feet.x + 150, image.get_height() - 30,
			image.get_height() - 1)
		assert_gt(band, 0.5, "%s : la bande de premier plan reste sous les pieds" % id)
		assert_lt(decor.player_feet.y, decor.size.y * 0.93, "%s : pieds loin du bord bas" % id)


func test_default_decor_of_a_map() -> void:
	var catalog := _catalog()
	assert_eq(catalog.default_for(&"route_1").id, &"route_1_chemin")
	assert_null(catalog.default_for(&"oak_lab"), "pas de décor : rien à précharger")


func _mean_alpha(image: Image, x0: int, x1: int, y0: int, y1: int) -> float:
	var total := 0.0
	var count := 0
	for y: int in range(y0, y1 + 1):
		for x: int in range(x0, x1 + 1, 4):
			total += image.get_pixel(x, y).a
			count += 1
	return total / maxf(count, 1)


# --- Catalogue ------------------------------------------------------------------------

func test_local_variant_by_cells_then_default() -> void:
	var catalog := BattleDecorCatalog.new()
	catalog.read({
		"decors": {
			"foret_lisiere": _decor_data({"zone": "viridian_forest", "variant": "lisiere"}),
			"foret_clairiere": _decor_data({"zone": "viridian_forest", "variant": "clairiere"}),
		},
		"places": {
			"viridian_forest": [
				{"decor": "foret_clairiere", "cells": [10, 10, 5, 4]},
				{"decor": "foret_lisiere"},
			],
		},
	})
	assert_eq(catalog.pick(&"viridian_forest", Vector2i(12, 12)).id, &"foret_clairiere")
	assert_eq(catalog.pick(&"viridian_forest", Vector2i(14, 13)).id, &"foret_clairiere")
	assert_eq(catalog.pick(&"viridian_forest", Vector2i(15, 12)).id, &"foret_lisiere",
		"hors du rectangle : décor par défaut")
	assert_eq(catalog.pick(&"viridian_forest", Vector2i(0, 0)).id, &"foret_lisiere")


func test_variant_only_map_falls_back_outside_its_cells() -> void:
	var catalog := BattleDecorCatalog.new()
	catalog.read({
		"decors": {"pont": _decor_data()},
		"places": {"route_x": [{"decor": "pont", "cells": [0, 0, 3, 3]}]},
	})
	assert_eq(catalog.pick(&"route_x", Vector2i(1, 1)).id, &"pont")
	assert_null(catalog.pick(&"route_x", Vector2i(5, 5)), "pas de défaut : repli")


func test_unknown_decor_reference_is_ignored() -> void:
	var catalog := BattleDecorCatalog.new()
	catalog.read({"decors": {}, "places": {"route_x": [{"decor": "absent"}]}})
	assert_null(catalog.pick(&"route_x", Vector2i.ZERO))


func test_invalid_ground_line_is_rejected() -> void:
	# Joueur au-dessus de l'adversaire : incohérent.
	var decor := BattleDecor.from_dict(&"faux", _decor_data({"player_feet": [716, 300]}))
	assert_null(decor)
	assert_push_error("ligne de sol incohérente")
	assert_null(BattleDecor.from_dict(&"vide", {"zone": "route_1"}))
	assert_push_error("absente")


# --- Ligne de sol et placement --------------------------------------------------------

## Jusqu'à 2340 de large (S24) ; plus large, l'image grandit pour couvrir (test suivant).
func test_fit_puts_both_feet_on_the_painted_ground() -> void:
	var decor := BattleDecor.from_dict(&"d", _decor_data())
	for view: Vector2 in [Vector2(2340, 1080), Vector2(1920, 1080), Vector2(1440, 1080)]:
		var rect := decor.fit(view)
		var scale := rect.size.x / decor.size.x
		var a := BattleLayout.anchors(view)
		var foe := rect.position + decor.foe_feet * scale
		var mine := rect.position + decor.player_feet * scale
		assert_almost_eq(foe.distance_to(a["foe_feet"]), 0.0, 1.5, "%s : pieds adverses" % view)
		assert_almost_eq(mine.y, (a["player_feet"] as Vector2).y, 1.5, "%s : sol du joueur" % view)
		assert_almost_eq(mine.x, (a["player_feet"] as Vector2).x, 1.5, "%s : x du joueur" % view)


func test_fit_always_covers_the_screen() -> void:
	# Ligne de sol écrasée (décor « trop petit ») ou décentrée : l'image grandit / glisse.
	for data: Dictionary in [_decor_data(), _decor_data({"foe_feet": [1559, 700]}),
			_decor_data({"size": [1600, 900], "foe_feet": [1100, 420], "player_feet": [500, 880]}),
			_decor_data({"foe_feet": [2300, 540]})]:
		var decor := BattleDecor.from_dict(&"d", data)
		for view: Vector2 in VIEWS:
			var rect := decor.fit(view)
			assert_true(rect.encloses(Rect2(Vector2.ZERO, view)),
				"%s couvre %s (%s)" % [data["size"], view, rect])


func test_fit_scale_follows_ground_span() -> void:
	# Master deux fois plus grand, peint pour les mêmes proportions : affiché à ½.
	var decor := BattleDecor.from_dict(&"d", _decor_data({
		"size": [4680, 2160], "foe_feet": [3118, 1080], "player_feet": [1432, 1944]}))
	var rect := decor.fit(Vector2(2340, 1080))
	assert_almost_eq(rect.size.x / decor.size.x, 0.5, 0.002)


## Jalon 19 (T14) : le décor « tour_pokemon » sert les cinq étages (2F à 6F), partout dans la carte.
func test_tower_decor_serves_the_five_floors() -> void:
	var catalog := _catalog()
	for floor_name: String in ["2f", "3f", "4f", "5f", "6f"]:
		var map_id := StringName("pokemon_tower_%s" % floor_name)
		for cell: Vector2i in [Vector2i.ZERO, Vector2i(10, 9), Vector2i(19, 17)]:
			var decor := catalog.pick(map_id, cell)
			assert_not_null(decor, "%s %s : décor" % [map_id, cell])
			if decor != null:
				assert_eq(decor.id, &"tour_pokemon", "%s : décor de la Tour" % map_id)
		assert_eq(catalog.default_for(map_id).id, &"tour_pokemon", "%s : préchargé" % map_id)
