extends GutTest
## ZoneLibrary : zones du Kanto du projet (data/world/zones.json, jalon-06.md §3.2).

const AREAS_PATH := "res://assets/ui/map/kanto_placeholder_areas.json"
## Cartes rangées dans une zone avant d'être construites (jalon 10, T8 : données prêtes) : la Route
## 2 nord et Argenta (T11) et les intérieurs (T13) sont construits : liste vide. À retirer
## quand leur tâche est fusionnée ; leur existence est vérifiée dès que la scène existe.
const AWAITING_MAPS: Array[StringName] = []

var _zones: ZoneLibrary


func before_each() -> void:
	_zones = ZoneLibrary.new()


## Zones construites dont la description de la Carte attend la validation de Kevin (jalon 16 :
## annexe A du plan, T3 ; titre et sous-titre du S.S. Anne déjà validés, dossier 19 §0.5 n° 1).
const AWAITING_TEXTS: Array[StringName] = [&"ss_anne"]


## Identifiants des cartes existantes (une scène par carte, MapCatalog).
func _map_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for file: String in DirAccess.get_files_at(MapCatalog.MAPS_DIR):
		var name := file.trim_suffix(".remap")
		if name.get_extension() == "tscn" and not MapCatalog.is_qa_map(
				StringName(name.get_basename())):
			ids.append(StringName(name.get_basename()))
	return ids


## Propriété [param property] du nœud racine de la scène de la carte, sans l'instancier.
func _root_property(map_id: StringName, property: StringName) -> Variant:
	var state := (load(MapCatalog.scene_path(map_id)) as PackedScene).get_state()
	for i: int in state.get_node_property_count(0):
		if state.get_node_property_name(0, i) == property:
			return state.get_node_property_value(0, i)
	return null


# --- Données réelles -----------------------------------------------------------------------

func test_real_data_loads_without_error() -> void:
	assert_true(_zones.load_file(), "\n".join(_zones.get_errors()))
	assert_eq(_zones.get_errors().size(), 0)
	assert_eq(_zones.size(), 29, "Route 24 (jalon 13), Route 25 et Cap d'Azuria (jalon 14), "
		+ "passage souterrain (jalon 15 T18), Route 6 (jalon 15 T14), Route 5 (jalon 15 T13), "
		+ "S.S. Anne (jalon 16 T11)")


func test_every_map_belongs_to_exactly_one_zone() -> void:
	_zones.load_file()
	var maps := _map_ids()
	assert_gt(maps.size(), 5)
	for map_id: StringName in maps:
		assert_ne(_zones.zone_of(map_id), &"", "carte « %s » rangée dans une zone" % map_id)
	for map_id: StringName in _zones.get_maps():
		if AWAITING_MAPS.has(map_id) and not MapCatalog.has_map(map_id):
			continue
		assert_true(MapCatalog.has_map(map_id), "carte « %s » existante" % map_id)


func test_interiors_belong_to_their_town() -> void:
	_zones.load_file()
	for map_id: StringName in [&"pallet_town", &"player_house_1f", &"player_house_2f",
			&"rival_house", &"oak_lab"]:
		assert_eq(_zones.zone_of(map_id), &"pallet_town", map_id)
		assert_eq(_zones.zone_name_of(map_id), "Bourg Palette")
	assert_eq(_zones.zone_of(&"route_1"), &"route_1")
	assert_eq(_zones.zone_name_of(&"route_1"), "Route 1")
	assert_eq(_zones.zone_of(&"nowhere"), &"")
	assert_eq(_zones.zone_name_of(&"nowhere"), "")


func test_zone_names_match_the_map_titles() -> void:
	_zones.load_file()
	for map_id: StringName in _map_ids():
		assert_eq(_root_property(map_id, &"display_name"), _zones.zone_name_of(map_id),
			"titre de « %s » = nom de sa zone" % map_id)


func test_first_zones_of_the_journey() -> void:
	_zones.load_file()
	var expected := {
		&"pallet_town": ["Bourg Palette", ZoneData.KIND_TOWN],
		&"route_1": ["Route 1", ZoneData.KIND_ROUTE],
		&"viridian_city": ["Jadielle", ZoneData.KIND_TOWN],
		&"route_22": ["Route 22", ZoneData.KIND_ROUTE],
		&"route_2": ["Route 2", ZoneData.KIND_ROUTE],
		&"viridian_forest": ["Forêt de Jade", ZoneData.KIND_PLACE],
		&"pewter_city": ["Argenta", ZoneData.KIND_TOWN],
	}
	for id: StringName in expected:
		var zone := _zones.get_zone(id)
		assert_not_null(zone, id)
		assert_eq(zone.id, id)
		assert_eq(zone.name, expected[id][0])
		assert_eq(zone.kind, expected[id][1])
	assert_eq(_zones.get_ids().slice(0, 4), [&"pallet_town", &"route_1", &"viridian_city",
		&"route_22"] as Array[StringName], "ordre du fichier")
	assert_eq(_zones.get_zone(&"viridian_city").maps, [&"viridian_city", &"viridian_center",
		&"viridian_mart"] as Array[StringName], "jalon 7 T4 : la ville et ses deux intérieurs")
	assert_false(_zones.has_zone(&"route_16"), "Route 16 retirée (décision de Kevin)")


## Une seule source de vérité par fait : l'identité des zones dans zones.json, leur
## rectangle dans le fichier de l'illustration ; mêmes identifiants des deux côtés.
func test_same_zones_as_the_kanto_illustration() -> void:
	_zones.load_file()
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(AREAS_PATH))
	var area_ids: Array[StringName] = []
	for key: String in doc["zones"]:
		area_ids.append(StringName(key))
		var entry: Dictionary = doc["zones"][key]
		assert_eq(entry.keys(), ["area"], "%s : seulement la géométrie" % key)
	var ids := _zones.get_ids()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return a < b)
	area_ids.sort_custom(func(a: StringName, b: StringName) -> bool: return a < b)
	assert_eq(ids, area_ids)


## Carte (T18) : chaque zone construite a sa description (validée le 2026-10-06) ; la Route 1 annonce ses
## connexions comme son titre en jeu (Q-15).
func test_built_zones_have_their_map_texts() -> void:
	_zones.load_file()
	for id: StringName in _zones.get_ids():
		var zone := _zones.get_zone(id)
		if not zone.maps.is_empty():
			assert_false(zone.description.is_empty(), "%s : description" % id)
			assert_eq(zone.draft, AWAITING_TEXTS.has(id), "%s : textes validé par Kevin" % id)
		assert_false(zone.description.contains("???"), id)
		assert_false(zone.subtitle.contains("???"), id)
	assert_eq(_zones.get_zone(&"route_1").subtitle, "Bourg Palette — Jadielle")
	assert_eq(_zones.get_zone(&"route_1").subtitle, _root_property(&"route_1", &"region"),
		"même connexion que le titre de zone en jeu")
	assert_eq(_zones.get_zone(&"pallet_town").subtitle, "")
	# Jalon 8 (dossier 11, T1 et T14) : sous-titre = le panneau sud, comme la Route 1.
	var route_2 := _zones.get_zone(&"route_2")
	# Jalon 10 (Q-3) : la Route 2 nord est la 2e carte de la zone, textes inchangés.
	assert_eq(route_2.maps, [&"route_2", &"route_2_north"] as Array[StringName])
	assert_eq(route_2.subtitle, "Jadielle — Forêt de Jade")
	assert_eq(route_2.description,
		"Un chemin bordé de prairies qui s'enfonce peu à peu sous les arbres.")
	if MapCatalog.has_map(&"route_2"):
		assert_eq(route_2.subtitle, _root_property(&"route_2", &"region"),
			"même connexion que le titre de zone en jeu")
	# Jalon 9 (T18) : textes n° 51 et 52 du lot verrouillé (textes-brouillon-j9.md) ; les cartes
	# (forêt et ses deux postes, jalon-09.md §2.7.3) arrivent avec leurs scènes au T19.
	var forest := _zones.get_zone(&"viridian_forest")
	assert_eq(forest.subtitle, "Jadielle — Argenta")
	assert_eq(forest.description, "Une forêt profonde et fraîche, où la lumière perce à peine "
		+ "entre les cimes. Les Pokémon Insecte y foisonnent sous une végétation dense.")
	assert_false(forest.draft)
	if MapCatalog.has_map(&"viridian_forest"):
		assert_eq(forest.maps, [&"viridian_forest", &"viridian_forest_gate_south",
			&"viridian_forest_gate_north"] as Array[StringName], "les postes sont de la forêt")
		assert_eq(forest.subtitle, _root_property(&"viridian_forest", &"region"),
			"même connexion que le titre de zone en jeu")
	assert_false(_zones.get_zone(&"viridian_city").description.is_empty(), "jalon 7 T4")
	assert_eq(_zones.get_zone(&"viridian_city").subtitle, "", "aucun sous-titre (2026-10-03)")
	assert_true(_root_property(&"viridian_city", &"region") in [null, ""],
		"aucun sous-titre en jeu")


func test_service_catalog_and_the_services_of_viridian() -> void:
	_zones.load_file()
	assert_eq(_zones.get_service_ids(), [&"pokemon_center", &"poke_mart", &"gym", &"daycare"]
		as Array[StringName], "jalon 15 T13 : la Pension")
	assert_eq(_zones.service_name(&"daycare"), "Pension")
	assert_eq(_zones.service_name(&"pokemon_center"), "Centre Pokémon")
	assert_eq(_zones.service_name(&"poke_mart"), "Boutique")
	assert_eq(_zones.service_name(&"gym"), "Arène")
	assert_eq(_zones.service_name(&"casino"), "")
	# Jalon 7 T4 : seuls les services de Jadielle, découverts sur leur carte (l'Arène en
	# entrant dans la ville, le Centre et la Boutique en y entrant). Jalon 10 : ceux d'Argenta
	# (test_pewter_data). Jalon 12 T8 : le Centre du Mont Sélénite (zone `mt_moon`).
	# Jalon 13 T7 : Azuria. Jalon 15 T14 : Carmin-sur-Mer (test_vermilion_city).
	for id: StringName in _zones.get_ids():
		if not id in [&"viridian_city", &"pewter_city", &"mt_moon", &"cerulean_city",
				&"vermilion_city", &"route_5"]:
			assert_true(_zones.get_zone(id).services.is_empty(), "%s : aucun service" % id)
	var mt_moon := _zones.get_zone(&"mt_moon").services
	assert_eq(mt_moon.size(), 1, "Mont Sélénite : le Centre seul (sans Boutique)")
	if mt_moon.size() == 1:
		assert_eq([mt_moon[0].id, mt_moon[0].found_on], [&"pokemon_center", &"mt_moon_center"])
	var route_5 := _zones.get_zone(&"route_5").services
	assert_eq(route_5.size(), 1, "Route 5 : la Pension seule")
	if route_5.size() == 1:
		assert_eq([route_5[0].id, route_5[0].found_on], [&"daycare", &"route_5_daycare"])
	var found: Dictionary = {}
	for service: ZoneService in _zones.get_zone(&"viridian_city").services:
		found[service.id] = service.found_on
	assert_eq(found, {&"pokemon_center": &"viridian_center", &"poke_mart": &"viridian_mart",
		&"gym": &"viridian_city"})


# --- Règles --------------------------------------------------------------------------------

func test_map_texts_and_services_are_read() -> void:
	assert_true(_zones.add_from_dict({
		"services": {"pokemon_center": {"name": "Centre Pokémon"}},
		"zones": {"v": {"name": "Jadielle", "kind": "town", "maps": ["v", "v_center"],
			"subtitle": "Route 1 — Route 2", "description": "Une ville.", "draft": true,
			"services": [{"id": "pokemon_center", "found_on": "v_center"}]}},
	}, "t"), "\n".join(_zones.get_errors()))
	var zone := _zones.get_zone(&"v")
	assert_eq(zone.subtitle, "Route 1 — Route 2")
	assert_eq(zone.description, "Une ville.")
	assert_true(zone.draft)
	assert_eq(zone.services.size(), 1)
	assert_eq(zone.services[0].id, &"pokemon_center")
	assert_eq(zone.services[0].found_on, &"v_center")
	assert_true(_zones.add_from_dict({"zones": {"w": {"name": "W", "kind": "route"}}}, "t"))
	assert_eq(_zones.get_zone(&"w").subtitle, "")
	assert_false(_zones.get_zone(&"w").draft)


func test_invalid_map_texts_and_services_are_rejected() -> void:
	assert_false(_zones.add_from_dict({
		"services": {"pokemon_center": {"name": "Centre Pokémon"}, "bad": {"title": "X"},
			"empty": {"name": " "}},
		"zones": {
			"blank": {"name": "X", "kind": "town", "subtitle": ""},
			"number": {"name": "X", "kind": "town", "description": 3},
			"draft": {"name": "X", "kind": "town", "draft": "oui"},
			"unknown": {"name": "X", "kind": "town", "maps": ["u"],
				"services": [{"id": "casino", "found_on": "u"}]},
			"elsewhere": {"name": "X", "kind": "town", "maps": ["e"],
				"services": [{"id": "pokemon_center", "found_on": "other"}]},
			"twice": {"name": "X", "kind": "town", "maps": ["t"],
				"services": [{"id": "pokemon_center", "found_on": "t"},
					{"id": "pokemon_center", "found_on": "t"}]},
			"shape": {"name": "X", "kind": "town", "services": {"id": "pokemon_center"}},
			"typo": {"name": "X", "kind": "town", "maps": ["y"],
				"services": [{"id": "pokemon_center", "found_on": "y", "at": "y"}]},
		}}, "t"))
	assert_eq(_zones.get_ids(), [] as Array[StringName], "toutes écartées")
	assert_eq(_zones.get_service_ids(), [&"pokemon_center"] as Array[StringName])
	var errors := "\n".join(_zones.get_errors())
	assert_string_contains(errors, "« subtitle » est un texte non vide")
	assert_string_contains(errors, "« description » est un texte non vide")
	assert_string_contains(errors, "« draft » vaut true ou false")
	assert_string_contains(errors, "service « casino » absent du catalogue")
	assert_string_contains(errors, "« found_on » doit être une carte de la zone")
	assert_string_contains(errors, "service « pokemon_center » en double")
	assert_string_contains(errors, "clé inconnue « at »")
	assert_string_contains(errors, "clé inconnue « title »")
	assert_push_error_count(11)


func test_maps_default_to_empty() -> void:
	assert_true(_zones.add_from_dict({"zones": {"z": {"name": "Z", "kind": "place"}}}, "t"))
	assert_eq(_zones.get_zone(&"z").maps, [] as Array[StringName])
	assert_eq(_zones.get_zone(&"z").source, "t")
	assert_null(_zones.get_zone(&"missing"))


func test_invalid_zones_are_rejected() -> void:
	assert_false(_zones.add_from_dict({"zones": {
		"ok": {"name": "Bon", "kind": "town", "maps": ["a"]},
		"typo": {"name": "X", "kind": "town", "map": ["b"]},
		"no_name": {"kind": "town"},
		"bad_kind": {"name": "X", "kind": "city"},
		"bad_maps": {"name": "X", "kind": "route", "maps": "c"},
		"twice": {"name": "X", "kind": "route", "maps": ["d", "d"]},
		"stolen": {"name": "X", "kind": "route", "maps": ["a"]},
		"not_object": 3,
	}}, "t"))
	assert_eq(_zones.get_ids(), [&"ok"] as Array[StringName])
	assert_eq(_zones.zone_of(&"a"), &"ok", "une carte n'appartient qu'à une zone")
	assert_eq(_zones.zone_of(&"d"), &"", "zone écartée : ses cartes aussi")
	var errors := "\n".join(_zones.get_errors())
	assert_string_contains(errors, "clé inconnue « map »")
	assert_string_contains(errors, "carte « a » déjà rangée dans « ok »")
	assert_string_contains(errors, "carte « d » en double")
	assert_push_error_count(7)


func test_duplicate_zone_across_files_and_root_keys() -> void:
	_zones.add_from_dict({"zones": {"z": {"name": "Z", "kind": "town"}}}, "a.json")
	assert_false(_zones.add_from_dict({"zones": {"z": {"name": "Z2", "kind": "town"}}},
		"b.json"))
	assert_eq(_zones.get_zone(&"z").name, "Z")
	assert_false(_zones.add_from_dict({"zone": {}}, "c.json"))
	assert_false(_zones.add_from_dict({"zones": [], "extra": 1}, "d.json"))
	assert_push_error_count(5)


func test_missing_file() -> void:
	assert_false(_zones.load_file("res://tests/fixtures/absent_zones.json"))
	assert_push_error("fichier introuvable")
