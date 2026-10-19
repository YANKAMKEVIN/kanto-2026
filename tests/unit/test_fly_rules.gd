extends GutTest
## FlyRules (passe systèmes 2, `systemes-2.md` §2.8) : conditions du Vol, destinations de
## `data/world/fly_points.json` (ordre de Rouge/Bleu, ouvertes quand la carte est découverte).

const READY := FieldMoves.State.READY

var _rules: FlyRules


func before_each() -> void:
	_rules = FlyRules.new()
	assert_true(_rules.load_file(), "\n".join(_rules.get_errors()))


func test_the_eleven_towns_in_red_blue_order() -> void:
	var zones: Array[StringName] = []
	for point: FlyRules.Point in _rules.get_points():
		zones.append(point.zone)
	assert_eq(zones, [&"pallet_town", &"viridian_city", &"pewter_city", &"cerulean_city",
		&"lavender_town", &"vermilion_city", &"celadon_city", &"fuchsia_city",
		&"cinnabar_island", &"indigo_plateau", &"saffron_city"] as Array[StringName])


func test_every_zone_exists() -> void:
	var zones := ZoneLibrary.new()
	assert_true(zones.load_file())
	for point: FlyRules.Point in _rules.get_points():
		assert_true(zones.has_zone(point.zone), String(point.zone))


func test_built_maps_have_the_arrival_spawn() -> void:
	var checked := 0
	for point: FlyRules.Point in _rules.get_points():
		var path := "res://game/world/maps/%s.tscn" % point.map
		if not ResourceLoader.exists(path):
			continue # Ville pas encore construite : son jalon confirme le point d'arrivée.
		var map := (load(path) as PackedScene).instantiate()
		assert_not_null(map.get_node_or_null(NodePath("Spawns/%s" % point.spawn)),
			"%s : point d'arrivée « %s »" % [point.map, point.spawn])
		map.free()
		checked += 1
	assert_gte(checked, 6, "les six villes déjà construites")


func test_destinations_open_with_discovered_maps() -> void:
	assert_eq(_rules.destinations({}).size(), 0)
	var open := _rules.destinations({&"pewter_city": "", &"pallet_town": "", &"route_1": ""})
	assert_eq(open.size(), 2)
	assert_eq(open[0].zone, &"pallet_town", "ordre des données")
	assert_eq(open[1].spawn, &"from_center")


func test_can_fly_order_of_refusals() -> void:
	var outdoors := MapTraits.new()
	assert_eq(FlyRules.can_fly(READY, outdoors), FlyRules.Check.OK)
	assert_eq(FlyRules.can_fly(READY, outdoors, true), FlyRules.Check.BUSY)
	assert_eq(FlyRules.can_fly(FieldMoves.State.NO_HM, outdoors), FlyRules.Check.NO_HM)
	assert_eq(FlyRules.can_fly(FieldMoves.State.NO_BADGE, MapTraits.new(true)),
		FlyRules.Check.NO_BADGE, "les conditions avant le lieu")
	assert_eq(FlyRules.can_fly(FieldMoves.State.NO_POKEMON, outdoors),
		FlyRules.Check.NO_POKEMON)
	assert_eq(FlyRules.can_fly(READY, MapTraits.new(true)), FlyRules.Check.INDOORS)
	var safari := MapTraits.new()
	safari.no_fly = true
	assert_eq(FlyRules.can_fly(READY, safari), FlyRules.Check.NO_FLY)


func test_bad_data_is_refused() -> void:
	var rules := FlyRules.new()
	assert_false(rules.add_points([{ "zone": "a", "map": "a" }], "test"))
	assert_push_error("zone")
	assert_false(rules.add_points([{ "zone": "a", "map": "a", "spawn": "s" },
		{ "zone": "a", "map": "b", "spawn": "s" }], "test"))
	assert_push_error("double")
	assert_eq(rules.get_points().size(), 1)
